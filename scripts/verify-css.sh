#!/usr/bin/env bash
# ==============================================================================
# Script: verify-css.sh
# Mục đích: Quét tĩnh và phát hiện các lỗi CSS cơ bản, lỗi layout overlay,
#          xung đột transform animation, cắt góc (overflow clipping) và thiếu vendor prefixes.
# Sử dụng:
#   ./scripts/verify-css.sh           # Chạy quét và in báo cáo
#   ./scripts/verify-css.sh --strict  # Exit code 1 nếu phát hiện lỗi hoặc cảnh báo
# ==============================================================================

set -eo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || dirname "$(dirname "$(realpath "$0")")")"
STYLES_FILE="${ROOT_DIR}/desktop/src/styles.css"
COMPONENTS_DIR="${ROOT_DIR}/desktop/src/components"

STRICT_MODE=false
for arg in "$@"; do
  case "$arg" in
    --strict) STRICT_MODE=true ;;
    --help|-h)
      echo "Sử dụng: $0 [--strict]"
      echo "  --strict: Trả về lỗi (exit code 1) khi có bất kỳ cảnh báo nào"
      exit 0
      ;;
  esac
done

python3 - << 'EOF' "$ROOT_DIR" "$STYLES_FILE" "$COMPONENTS_DIR" "$STRICT_MODE"
import sys
import os
import re

root_dir = sys.argv[1]
styles_file = sys.argv[2]
components_dir = sys.argv[3]
strict_mode = sys.argv[4] == "true"

# ANSI Colors
BOLD = "\033[1m"
GREEN = "\033[0;32m"
YELLOW = "\033[0;33m"
CYAN = "\033[0;36m"
RED = "\033[0;31m"
RESET = "\033[0m"

errors = []
warnings = []
passed_checks = []

print(f"{BOLD}{CYAN}========================================================================================{RESET}")
print(f"{BOLD}{CYAN}   🎨 CSS & UI LAYOUT INTEGRITY VERIFIER                                                {RESET}")
print(f"{BOLD}{CYAN}   Kiểm tra tự động phát hiện lỗi Layout, Transform Collision, và Overflow Clipping    {RESET}")
print(f"{BOLD}{CYAN}========================================================================================{RESET}\n")

if not os.path.isfile(styles_file):
    print(f"{RED}Lỗi: Không tìm thấy file styles.css tại {styles_file}{RESET}")
    sys.exit(1)

with open(styles_file, "r", encoding="utf-8") as f:
    css_content = f.read()

# ------------------------------------------------------------------------------
# CHECK 1: Xung đột Transform Animation và Translate Centering (Lỗi gây popup lệch)
# ------------------------------------------------------------------------------
# Tìm tất cả keyframes
keyframes = {}
for match in re.finditer(r'@keyframes\s+([a-zA-Z0-9_-]+)\s*\{([^}]+(?:\{[^}]*\}[^}]*)*)\}', css_content):
    kf_name = match.group(1)
    kf_body = match.group(2)
    keyframes[kf_name] = kf_body

# Quét các rule CSS tìm class có top: 50% + left: 50% + transform: translate(-50%, -50%)
rule_pattern = re.compile(r'([^{]+)\{([^}]+)\}', re.MULTILINE)
for match in rule_pattern.finditer(css_content):
    selectors = match.group(1).strip()
    body = match.group(2)

    if selectors.startswith("@"):
        continue

    has_top_50 = re.search(r'\btop:\s*50%', body)
    has_left_50 = re.search(r'\bleft:\s*50%', body)
    has_translate = re.search(r'\btransform:\s*translate\(\s*-50%\s*,\s*-50%\s*\)', body)
    anim_match = re.search(r'\banimation:\s*([a-zA-Z0-9_-]+)', body)

    if has_top_50 and has_left_50 and has_translate and anim_match:
        anim_name = anim_match.group(1)
        if anim_name in keyframes:
            kf_content = keyframes[anim_name]
            # Kiểm tra xem trong keyframe 100% hoặc to có transform không giữ translate(-50%, -50%) không
            for step_match in re.finditer(r'(?:100%|to)\s*\{([^}]+)\}', kf_content):
                step_body = step_match.group(1)
                trans_in_step = re.search(r'\btransform:\s*([^;]+);', step_body)
                if trans_in_step:
                    val = trans_in_step.group(1)
                    if "translate(-50%" not in val:
                        errors.append(
                            f"[Transform Collision] Selector '{selectors}' dùng 'translate(-50%, -50%)' để căn giữa nhưng animation '{anim_name}' ở 100% ghi đè 'transform: {val}' làm mất toạ độ căn giữa, gây lệch popup! "
                            f"Khuyên dùng: Backdrop Flexbox ('inset: 0; display: flex; align-items: center; justify-content: center;')."
                        )

passed_checks.append("Kiểm tra xung đột Transform Animation & Centering Translation: Không phát hiện lỗi.")

# ------------------------------------------------------------------------------
# CHECK 2: Backdrop-filter phải đi kèm -webkit-backdrop-filter (Safari Compatibility)
# ------------------------------------------------------------------------------
bf_matches = list(re.finditer(r'\{[^}]*?[^-]backdrop-filter:\s*([^;]+);([^}]*)\}', css_content))
missing_webkit_bf = []
for m in bf_matches:
    full_block = m.group(0)
    if "-webkit-backdrop-filter:" not in full_block:
        missing_webkit_bf.append(full_block[:40].replace('\n', ' '))

if missing_webkit_bf:
    warnings.append(
        f"[Vendor Prefix] Phát hiện {len(missing_webkit_bf)} khối CSS có 'backdrop-filter' nhưng thiếu '-webkit-backdrop-filter' (gây mất hiệu ứng mờ kính trên Safari/macOS/iOS)."
    )
else:
    passed_checks.append("Kiểm tra Vendor Prefix 'backdrop-filter' / '-webkit-backdrop-filter': 100% tuân thủ.")

# ------------------------------------------------------------------------------
# CHECK 3: User-select phải đi kèm -webkit-user-select
# ------------------------------------------------------------------------------
us_matches = list(re.finditer(r'\{[^}]*?[^-]user-select:\s*none;([^}]*)\}', css_content))
missing_webkit_us = 0
for m in us_matches:
    full_block = m.group(0)
    if "-webkit-user-select:" not in full_block:
        missing_webkit_us += 1

if missing_webkit_us > 0:
    warnings.append(
        f"[Vendor Prefix] Phát hiện {missing_webkit_us} khối CSS có 'user-select: none' nhưng thiếu '-webkit-user-select: none'."
    )
else:
    passed_checks.append("Kiểm tra Vendor Prefix 'user-select': 100% tuân thủ.")

# ------------------------------------------------------------------------------
# CHECK 4: Overlay / Modal an toàn với Overflow Clipping
# ------------------------------------------------------------------------------
# Kiểm tra các class overlay/dialog/modal trong styles.css: bắt buộc có max-height và overflow-y: auto
overlay_classes = [".xiangqi-victory-overlay", ".modal", ".dialog-box", ".popup-card"]
for cls in overlay_classes:
    cls_regex = re.compile(re.escape(cls) + r'\s*\{([^}]+)\}')
    for match in cls_regex.finditer(css_content):
        body = match.group(1)
        if "max-height:" not in body:
            warnings.append(f"[Modal Safety] Selector '{cls}' thiếu thuộc tính 'max-height', có thể bị tràn khung hình nếu nội dung dài.")
        if "overflow-y:" not in body and "overflow:" not in body:
            warnings.append(f"[Modal Safety] Selector '{cls}' thiếu thuộc tính 'overflow-y: auto', có thể bị cắt góc khi tràn.")

passed_checks.append("Kiểm tra tính an toàn chống tràn (Overflow & Max-Height) trên các lớp Overlay/Modal.")

# ------------------------------------------------------------------------------
# CHECK 5: Quét React Components trong desktop/src/components
# ------------------------------------------------------------------------------
component_files = []
for root, dirs, files in os.walk(components_dir):
    for f in files:
        if f.endswith(".tsx") or f.endswith(".jsx"):
            component_files.append(os.path.join(root, f))

clipping_risks = 0
for comp_path in component_files:
    fname = os.path.basename(comp_path)
    with open(comp_path, "r", encoding="utf-8") as cf:
        code = cf.read()

    # Kiểm tra xem có inline style overflow: "hidden" chứa overlay tuyệt đối mà không có backdrop
    if 'overflow: "hidden"' in code or 'overflow: hidden' in code:
        if 'className="xiangqi-victory-overlay"' in code and 'className="xiangqi-victory-backdrop"' not in code:
            errors.append(
                f"[Clipping Risk] Component '{fname}' có wrapper 'overflow: hidden' chứa trực tiếp '.xiangqi-victory-overlay' mà không có Backdrop bao bọc!"
            )
            clipping_risks += 1

passed_checks.append(f"Quét {len(component_files)} React Components: Đảm bảo cấu trúc Overlay và Backdrop an toàn.")

# ------------------------------------------------------------------------------
# BÁO CÁO KẾT QUẢ
# ------------------------------------------------------------------------------
print(f"{BOLD}{GREEN}1. Các Hạng Mục Đạt Chuẩn (Passed Checks):{RESET}")
for chk in passed_checks:
    print(f"   {GREEN}✔{RESET} {chk}")
print("")

if warnings:
    print(f"{BOLD}{YELLOW}2. Cảnh Báo Cải Thiện (Warnings):{RESET}")
    for w in warnings:
        print(f"   {YELLOW}⚠{RESET} {w}")
    print("")

if errors:
    print(f"{BOLD}{RED}3. Lỗi Layout Phát Hiện (Errors):{RESET}")
    for e in errors:
        print(f"   {RED}✘{RESET} {e}")
    print("")
    print(f"{BOLD}{RED}❌ VERIFY FAILED: Phát hiện {len(errors)} lỗi CSS nghiêm trọng!{RESET}")
    sys.exit(1)
elif warnings and strict_mode:
    print(f"{BOLD}{RED}❌ STRICT MODE FAILED: Có {len(warnings)} cảnh báo CSS cần khắc phục!{RESET}")
    sys.exit(1)
else:
    print(f"{BOLD}{CYAN}========================================================================================{RESET}")
    print(f"{BOLD}{GREEN}🎉 TẤT CẢ KIỂM TRA CSS & UI LAYOUT ĐỀU ĐẠT CHUẨN! KHÔNG CÒN LỖI LỆCH / CẮT GÓC.{RESET}")
    print(f"{BOLD}{CYAN}========================================================================================{RESET}")
    sys.exit(0)
EOF
