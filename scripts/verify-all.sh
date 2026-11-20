#!/usr/bin/env bash
# ==============================================================================
# Script: verify-all.sh
# Mục đích: Bộ xác thực toàn diện (Full Verification Suite) trước khi tạo PR hoặc bàn giao.
# Các bước xác thực:
#   1. Kiểm tra Đặc tả SPEC & Danh mục tồn đọng Backlog (scripts/check-specs-backlog.sh)
#   2. Kiểm tra tĩnh CSS & tính toàn vẹn UI Layout (scripts/verify-css.sh --strict)
#   3. Kiểm thử Backend Go & Unit Tests (go test ./...)
#   4. Kiểm tra Type safety & Production Build Frontend (pnpm -C desktop build)
#   5. Biên dịch Server Go binary (go build -o go-chat .)
# ==============================================================================

set -eo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(realpath "$0")")")"
cd "$ROOT_DIR"

BOLD="\033[1m"
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
CYAN="\033[0;36m"
RED="\033[0;31m"
RESET="\033[0m"

echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
echo -e "${BOLD}${CYAN}   🚀 FULL SYSTEM VERIFICATION SUITE - TIDEBIRD CHAT                                    ${RESET}"
echo -e "${BOLD}${CYAN}   Thời gian: $(date '+%Y-%m-%d %H:%M:%S')                                              ${RESET}"
echo -e "${BOLD}${CYAN}========================================================================================${RESET}\n"

# 1. Check SPEC & Backlog
echo -e "${BOLD}${CYAN}>>> [1/5] Kiểm tra tiến độ SPEC & Backlog...${RESET}"
./scripts/check-specs-backlog.sh
echo -e "${GREEN}✔ [1/5] SPEC & Backlog kiểm tra hoàn tất.${RESET}\n"

# 2. Check CSS & UI Layout
echo -e "${BOLD}${CYAN}>>> [2/5] Kiểm tra tĩnh CSS & UI Layout Integrity...${RESET}"
./scripts/verify-css.sh --strict
echo -e "${GREEN}✔ [2/5] CSS & UI Layout đạt 100% tiêu chuẩn.${RESET}\n"

# 3. Backend Unit & Integration Tests
echo -e "${BOLD}${CYAN}>>> [3/5] Chạy Backend Go Tests (go test ./...)...${RESET}"
go test ./...
echo -e "${GREEN}✔ [3/5] Toàn bộ Go test suites PASS 100%.${RESET}\n"

# 4. Frontend Type Check & Build
echo -e "${BOLD}${CYAN}>>> [4/5] Chạy Frontend Typecheck & Production Build...${RESET}"
(cd desktop && pnpm build)
echo -e "${GREEN}✔ [4/5] Frontend build thành công 0 lỗi.${RESET}\n"

# 5. Build Server Binary
echo -e "${BOLD}${CYAN}>>> [5/5] Build Server Binary (./go-chat)...${RESET}"
go build -o go-chat .
echo -e "${GREEN}✔ [5/5] Server binary ./go-chat sẵn sàng.${RESET}\n"

echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
echo -e "${BOLD}${GREEN}🎉 CHÚC MỪNG: HỆ THỐNG ĐÃ VƯỢT QUA TOÀN BỘ 5 BƯỚC XÁC THỰC! SẴN SÀNG MERGE VÀO MAIN.   ${RESET}"
echo -e "${BOLD}${CYAN}========================================================================================${RESET}"
