#!/usr/bin/env bash
# ==============================================================================
# Script: check-specs-backlog.sh
# Mục đích: Tự động kiểm tra tiến độ triển khai các tài liệu đặc tả kỹ thuật (SPEC),
#          danh mục tồn đọng (Backlog), nợ kỹ thuật và TODOs trong mã nguồn.
# Sử dụng:
#   ./scripts/check-specs-backlog.sh           # Hiển thị báo cáo tóm tắt
#   ./scripts/check-specs-backlog.sh --details # Hiển thị chi tiết từng task pending
#   ./scripts/check-specs-backlog.sh --json    # Xuất định dạng JSON cho CI/Agent
#   ./scripts/check-specs-backlog.sh --strict  # Exit code 1 nếu còn task chưa hoàn thành
# ==============================================================================

set -eo pipefail

# Định vị thư mục gốc của dự án
ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(realpath "$0")")")"
SPECS_DIR="${ROOT_DIR}/specs"
BACKLOG_FILE="${SPECS_DIR}/BACKLOG.md"

# Tham số dòng lệnh
SHOW_DETAILS=false
OUTPUT_JSON=false
STRICT_MODE=false

for arg in "$@"; do
  case "$arg" in
    --details|-d|-v)
      SHOW_DETAILS=true
      ;;
    --json)
      OUTPUT_JSON=true
      ;;
    --strict)
      STRICT_MODE=true
      ;;
    --help|-h)
      echo "Sử dụng: $0 [tuỳ chọn]"
      echo ""
      echo "Tuỳ chọn:"
      echo "  --details, -d, -v   Hiển thị chi tiết từng task pending và TODOs"
      echo "  --json              Xuất kết quả dạng JSON"
      echo "  --strict            Trả về exit code 1 nếu còn task chưa xong"
      echo "  --help, -h          Hiển thị trợ giúp này"
      exit 0
      ;;
    *)
      echo "Lỗi: Tuỳ chọn không hợp lệ '$arg'. Dùng --help để xem hướng dẫn." >&2
      exit 1
      ;;
  esac
done

# ANSI Colors (chỉ dùng khi không xuất JSON và terminal hỗ trợ)
if [ "$OUTPUT_JSON" = false ] && [ -t 1 ]; then
  BOLD="\033[1m"
  GREEN="\033[0;32m"
  YELLOW="\033[0;33m"
  BLUE="\033[0;34m"
  CYAN="\033[0;36m"
  RED="\033[0;31m"
  PURPLE="\033[0;35m"
  RESET="\033[0m"
else
  BOLD=""
  GREEN=""
  YELLOW=""
  BLUE=""
  CYAN=""
  RED=""
  PURPLE=""
  RESET=""
fi

# Hàm vẽ thanh tiến độ (Progress Bar)
render_progress_bar() {
  local percent=$1
  local width=15
  local filled=$(( (percent * width) / 100 ))
  local empty=$(( width - filled ))
  local bar=""
  for ((i=0; i<filled; i++)); do bar="${bar}█"; done
  for ((i=0; i<empty; i++)); do bar="${bar}░"; done
  echo "$bar"
}

# Kiểm tra thư mục specs
if [ ! -d "$SPECS_DIR" ]; then
  if [ "$OUTPUT_JSON" = true ]; then
    echo "{\"error\": \"Không tìm thấy thư mục specs/ tại ${SPECS_DIR}\"}"
  else
    echo -e "${RED}Lỗi: Thư mục ${SPECS_DIR} không tồn tại!${RESET}" >&2
  fi
  exit 1
fi

# Biến đếm tổng hợp
TOTAL_SPECS=0
COMPLETED_SPECS=0
IN_PROGRESS_SPECS=0
TOTAL_TASKS=0
COMPLETED_TASKS=0
PENDING_TASKS=0

# Mảng lưu trữ kết quả cho JSON
JSON_SPECS_DATA="[]"
JSON_PENDING_TASKS="[]"

# Danh sách chi tiết task pending (dạng text)
DETAILS_OUTPUT=""

# ------------------------------------------------------------------------------
# 1. QUÉT TOÀN BỘ FILE SPEC TRONG specs/
# ------------------------------------------------------------------------------
shopt -s nullglob
SPEC_FILES=("${SPECS_DIR}"/*_SPEC.md)
shopt -u nullglob

declare -a REPORT_ROWS=()

for spec_file in "${SPEC_FILES[@]}"; do
  TOTAL_SPECS=$((TOTAL_SPECS + 1))
  filename="$(basename "$spec_file")"
  
  # Lấy tiêu đề SPEC từ dòng đầu tiên có '# '
  title="$(grep -m 1 -E '^#[[:space:]]+' "$spec_file" | sed -E 's/^#[[:space:]]+//' || echo "$filename")"
  # Rút gọn tiêu đề nếu quá dài
  if [ ${#title} -gt 55 ]; then
    short_title="${title:0:52}..."
  else
    short_title="$title"
  fi

  # Đếm checklist
  done_cnt="$(grep -c -E '^[[:space:]]*[-*][[:space:]]+\[[xX]\]' "$spec_file" || true)"
  pending_cnt="$(grep -c -E '^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\]' "$spec_file" || true)"
  tasks_in_spec=$((done_cnt + pending_cnt))

  TOTAL_TASKS=$((TOTAL_TASKS + tasks_in_spec))
  COMPLETED_TASKS=$((COMPLETED_TASKS + done_cnt))
  PENDING_TASKS=$((PENDING_TASKS + pending_cnt))

  status_str=""
  percent=100
  if [ "$tasks_in_spec" -gt 0 ]; then
    percent=$(( (done_cnt * 100) / tasks_in_spec ))
    if [ "$pending_cnt" -eq 0 ]; then
      status_str="HOÀN THÀNH"
      COMPLETED_SPECS=$((COMPLETED_SPECS + 1))
    else
      status_str="ĐANG LÀM"
      IN_PROGRESS_SPECS=$((IN_PROGRESS_SPECS + 1))
    fi
  else
    # Không có checklist định dạng - [ ], kiểm tra xem đã triển khai (ví dụ CHESS, NOTIFICATION)
    percent=100
    status_str="HOÀN THÀNH"
    COMPLETED_SPECS=$((COMPLETED_SPECS + 1))
  fi

  # Thu thập các task pending nếu có
  if [ "$pending_cnt" -gt 0 ]; then
    DETAILS_OUTPUT="${DETAILS_OUTPUT}\n${BOLD}${CYAN}📄 ${filename}${RESET} (${pending_cnt} task tồn đọng):\n"
    while IFS= read -r line; do
      task_text="$(echo "$line" | sed -E 's/^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\][[:space:]]*//')"
      DETAILS_OUTPUT="${DETAILS_OUTPUT}   ${YELLOW}⏳ ${task_text}${RESET}\n"
    done < <(grep -E '^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\]' "$spec_file" || true)
  fi

  REPORT_ROWS+=("${filename}|${short_title}|${done_cnt}/${tasks_in_spec}|${percent}%|${status_str}")
done

# ------------------------------------------------------------------------------
# 2. QUÉT BACKLOG (specs/BACKLOG.md)
# ------------------------------------------------------------------------------
BACKLOG_COUNT=0
BACKLOG_PENDING_TASKS=0
TECH_DEBT_COUNT=0

if [ -f "$BACKLOG_FILE" ]; then
  # Đếm các dòng bảng BL-xx
  BACKLOG_COUNT="$(grep -c -E '\|\s*\*\*BL-[0-9]+\*\*' "$BACKLOG_FILE" || true)"
  BACKLOG_PENDING_TASKS="$(grep -c -E '^[[:space:]]*[-*][[:space:]]+\[[[:space:]]\]' "$BACKLOG_FILE" || true)"
  TECH_DEBT_COUNT="$(grep -c -E '\*\*TD-[0-9]+\*\*' "$BACKLOG_FILE" || true)"
fi

# ------------------------------------------------------------------------------
# 3. QUÉT CODEBASE TÌM TODO / FIXME
# ------------------------------------------------------------------------------
CODE_TODOS_COUNT=0
TODO_DETAILS=""

SCAN_DIRS=("controller" "game" "store" "desktop/src")
for sdir in "${SCAN_DIRS[@]}"; do
  full_sdir="${ROOT_DIR}/${sdir}"
  if [ -d "$full_sdir" ]; then
    while IFS= read -r match; do
      if [ -n "$match" ]; then
        CODE_TODOS_COUNT=$((CODE_TODOS_COUNT + 1))
        TODO_DETAILS="${TODO_DETAILS}   ${PURPLE}📌 ${match}${RESET}\n"
      fi
    done < <(grep -rn -E '\b(TODO|FIXME|HACK|BUG):' "$full_sdir" 2>/dev/null || true)
  fi
done

# ------------------------------------------------------------------------------
# 4. XUẤT ĐỊNH DẠNG JSON (nếu có cờ --json)
# ------------------------------------------------------------------------------
if [ "$OUTPUT_JSON" = true ]; then
  python3 -c "
import json

specs = []
for row in '''$(printf '%s\n' "${REPORT_ROWS[@]}")'''.strip().split('\n'):
    if not row: continue
    parts = row.split('|')
    specs.append({
        'file': parts[0],
        'title': parts[1],
        'progress': parts[2],
        'percentage': parts[3],
        'status': parts[4]
    })

data = {
    'summary': {
        'total_specs': $TOTAL_SPECS,
        'completed_specs': $COMPLETED_SPECS,
        'in_progress_specs': $IN_PROGRESS_SPECS,
        'total_checklist_tasks': $TOTAL_TASKS,
        'completed_tasks': $COMPLETED_TASKS,
        'pending_tasks': $PENDING_TASKS,
        'backlog_items_count': $BACKLOG_COUNT,
        'backlog_tasks_pending': $BACKLOG_PENDING_TASKS,
        'tech_debts_count': $TECH_DEBT_COUNT,
        'code_todos_count': $CODE_TODOS_COUNT
    },
    'specs': specs
}
print(json.dumps(data, ensure_ascii=False, indent=2))
"
  if [ "$STRICT_MODE" = true ] && [ "$PENDING_TASKS" -gt 0 ]; then
    exit 1
  fi
  exit 0
fi

# ------------------------------------------------------------------------------
# 5. HIỂN THỊ BÁO CÁO DẠNG CLI
# ------------------------------------------------------------------------------
echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
echo -e "${BOLD}${CYAN}   📊 BÁO CÁO TIẾN ĐỘ ĐẶC TẢ KỸ THUẬT (SPEC) & DANH MỤC TỒN ĐỌNG (BACKLOG)              ${RESET}"
echo -e "${BOLD}${CYAN}   Dự án: tidebird/chat | Thời gian: $(date '+%Y-%m-%d %H:%M:%S')                        ${RESET}"
echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
echo ""

echo -e "${BOLD}${BLUE}1. Danh Mục Các Đặc Tả Kỹ Thuật (Specifications):${RESET}"
printf " %-30s | %-10s | %-16s | %-12s | %s\n" "Tên File SPEC" "Tiến độ" "Thanh tiến độ" "Trạng thái" "Tiêu đề"
echo "----------------------------------------------------------------------------------------"

for row in "${REPORT_ROWS[@]}"; do
  IFS='|' read -r r_file r_title r_prog r_pct r_stat <<< "$row"
  pct_num="${r_pct//%/}"
  bar="$(render_progress_bar "$pct_num")"

  if [ "$r_stat" = "HOÀN THÀNH" ]; then
    stat_colored="${GREEN}✔ Hoàn tất${RESET}"
    prog_colored="${GREEN}${r_prog}${RESET}"
  else
    stat_colored="${YELLOW}⏳ Đang làm${RESET}"
    prog_colored="${YELLOW}${r_prog}${RESET}"
  fi

  printf " %-30s | %-10s | [${CYAN}%s${RESET}] %3s | %-20b | %s\n" \
    "$r_file" "$r_prog" "$bar" "$r_pct" "$stat_colored" "$r_title"
done
echo "----------------------------------------------------------------------------------------"
echo ""

echo -e "${BOLD}${BLUE}2. Tình Trạng Backlog & Nợ Kỹ Thuật (Backlog & Technical Debt):${RESET}"
if [ -f "$BACKLOG_FILE" ]; then
  echo -e "   • File Backlog: ${GREEN}specs/BACKLOG.md${RESET} (Đã thiết lập)"
  echo -e "   • Tính năng sắp triển khai (Upcoming Features): ${BOLD}${CYAN}${BACKLOG_COUNT} tính năng${RESET} (P1: BL-01 Tournaments, BL-02 Cờ Úp...)"
  echo -e "   • Nhiệm vụ chi tiết trong Backlog: ${BOLD}${YELLOW}${BACKLOG_PENDING_TASKS} tasks pending${RESET}"
  echo -e "   • Nợ kỹ thuật cần xử lý (Tech Debt): ${BOLD}${PURPLE}${TECH_DEBT_COUNT} mục${RESET} (TD-01, TD-02, TD-03...)"
else
  echo -e "   • File Backlog: ${RED}Chưa tìm thấy specs/BACKLOG.md${RESET}"
fi
echo ""

echo -e "${BOLD}${BLUE}3. Quét Codebase TODO / FIXME:${RESET}"
if [ "$CODE_TODOS_COUNT" -eq 0 ]; then
  echo -e "   • ${GREEN}✔ Tuyệt vời! Codebase hoàn toàn sạch sẽ (0 TODO / FIXME tồn đọng).${RESET}"
else
  echo -e "   • ${YELLOW}⚠️ Phát hiện ${CODE_TODOS_COUNT} ghi chú TODO/FIXME trong mã nguồn:${RESET}"
  if [ "$SHOW_DETAILS" = true ]; then
    echo -e "$TODO_DETAILS"
  else
    echo -e "     (Chạy với cờ ${BOLD}--details${RESET} để xem danh sách chi tiết các dòng TODO)"
  fi
fi
echo ""

# Hiển thị chi tiết task pending nếu có
if [ -n "$DETAILS_OUTPUT" ]; then
  if [ "$SHOW_DETAILS" = true ]; then
    echo -e "${BOLD}${YELLOW}4. Chi Tiết Các Nhiệm Vụ Chưa Hoàn Thành:${RESET}"
    echo -e "$DETAILS_OUTPUT"
  else
    echo -e "${YELLOW}💡 Có ${PENDING_TASKS} task chưa hoàn thành trong SPEC. Chạy '${BOLD}$0 --details${RESET}${YELLOW}' để xem chi tiết.${RESET}"
    echo ""
  fi
fi

# Tổng kết
OVERALL_PCT=100
if [ "$TOTAL_TASKS" -gt 0 ]; then
  OVERALL_PCT=$(( (COMPLETED_TASKS * 100) / TOTAL_TASKS ))
fi

echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
echo -e "${BOLD}📌 TỔNG KẾT:${RESET}"
echo -e "   • Tổng số SPEC: ${BOLD}${TOTAL_SPECS}${RESET} (Hoàn tất: ${GREEN}${COMPLETED_SPECS}${RESET} | Đang thực hiện: ${YELLOW}${IN_PROGRESS_SPECS}${RESET})"
echo -e "   • Tổng Checklist Tasks: ${BOLD}${TOTAL_TASKS}${RESET} (Xong: ${GREEN}${COMPLETED_TASKS}${RESET} | Còn lại: ${YELLOW}${PENDING_TASKS}${RESET})"
echo -e "   • Tỷ lệ hoàn thành tổng thể: ${BOLD}${GREEN}${OVERALL_PCT}%${RESET} [$(render_progress_bar "$OVERALL_PCT")]"
echo -e "${BOLD}${CYAN}========================================================================================${RESET}"

if [ "$STRICT_MODE" = true ] && [ "$PENDING_TASKS" -gt 0 ]; then
  echo -e "\n${RED}[STRICT FAIL] Vẫn còn ${PENDING_TASKS} task chưa hoàn thành trong các tài liệu SPEC.${RESET}" >&2
  exit 1
fi

exit 0
