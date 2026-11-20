# Thư Mục Đặc Tả Kỹ Thuật (Specifications - Specs)

Thư mục này là nơi lưu trữ tập trung toàn bộ các tài liệu **Đặc tả kỹ thuật (Technical Specifications - SPEC.md)** của dự án `tidebird/chat`.

Mọi tính năng mới, trò chơi tương tác hoặc module kiến trúc phức tạp bắt buộc phải có tài liệu đặc tả tại đây trước khi bắt đầu triển khai code (theo quy trình của skill `feature-brainstorm`).

---

## 1. Danh Mục Các Đặc Tả Hiện Tại (Specifications Index)

| STT | Tài liệu SPEC | Loại | Trạng thái | Mô tả tóm tắt |
|:---:|:---|:---:|:---:|:---|
| 1 | [XIANGQI_GAME_SPEC.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/XIANGQI_GAME_SPEC.md) | Game | ✅ Đã triển khai | Trò chơi Cờ Tướng 9×10 chuẩn WXF, luật cản mã, tượng, chiếu bí, hết nước đi thua. |
| 2 | [CHESS_GAME_SPEC.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/CHESS_GAME_SPEC.md) | Game | ✅ Đã triển khai | Trò chơi Cờ Vua 8×8 quốc tế FIDE, nhập thành, phong cấp, bắt tốt qua đường. |
| 3 | [NOTIFICATION_SOUND_SPEC.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/NOTIFICATION_SOUND_SPEC.md) | Audio | ✅ Đã triển khai | Hệ thống âm thanh thông báo @mention và tin nhắn mới bằng Web Audio API. |
| 4 | [GAME_VIEWER_THREAD_SPEC.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/GAME_VIEWER_THREAD_SPEC.md) | Feature | ✅ Đã triển khai | Luồng bình luận riêng cho ván cờ (Thread) và định danh Khán giả (`[Viewer]`). |
| 5 | [LIVE_GAMES_TOPBAR_SPEC.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/LIVE_GAMES_TOPBAR_SPEC.md) | Feature | ✅ Đã triển khai | Ghim thanh các ván cờ đang live ở Topbar và điều hướng cuộn `jumpToMessage`. |
| 6 | [BACKLOG.md](file:///Users/hoang.nguyen3/tidebird/chat/specs/BACKLOG.md) | Backlog | 📋 Đang theo dõi | Danh mục tính năng dự kiến (v2+), ý tưởng phát triển và nợ kỹ thuật (Tech Debt). |

---

## 2. Quy Chuẩn Đặt Tên & Cấu Trúc File SPEC

- **Vị trí bắt buộc**: `specs/<TÊN_TÍNH_NĂNG>_SPEC.md`
- **Quy tắc đặt tên file**: Dùng chữ IN HOA, nối nhau bằng dấu gạch dưới `_`, kết thúc bằng `_SPEC.md`.
  - Ví dụ hợp lệ: `CARO_TOURNAMENT_SPEC.md`, `VOICE_ROOM_SPEC.md`, `GIPHY_PICKER_SPEC.md`.
- **Cấu trúc 7 phần tiêu chuẩn của mỗi SPEC**:
  1. `Mục tiêu & Phạm vi (Goals & Scope)`: Bối cảnh, mục tiêu cốt lõi, ngoài phạm vi (Non-goals v1/v2).
  2. `Kiến trúc & Luồng hoạt động (Architecture & Flow)`: Biểu đồ Mermaid sequence diagram, state machine.
  3. `Mô hình dữ liệu & API Contracts`: Go structs, REST endpoints, WebSocket events, SQLite schema.
  4. `Quy tắc nghiệp vụ & Trường hợp biên (Domain Rules & Edge Cases)`: Bảng ma trận các ca biên.
  5. `Thiết kế Giao diện Người dùng (UI / UX)`: Cấu trúc component, mockup, audio feedback, responsive.
  6. `Tích hợp Thống kê / Bảng xếp hạng` (nếu có).
  7. `Kế hoạch triển khai từng bước (Implementation Plan)`: Checklist `[ ]` để theo dõi tiến độ.

---

## 3. Lệnh Tạo Nhanh SPEC Mới Bằng Script

Sử dụng script tiện ích có sẵn trong dự án:

```bash
# Cú pháp:
./scripts/create-spec.sh <feature_name> ["Tiêu đề tính năng tiếng Việt"]

# Ví dụ tạo SPEC cho giải đấu cờ Caro:
./scripts/create-spec.sh caro-tournament "Hệ Thống Giải Đấu Cờ Caro"

# Ví dụ tạo SPEC cho phòng đàm thoại:
./scripts/create-spec.sh voice-room "Phòng Voice WebRTC Đa Điểm"
```

Script sẽ tự động:
1. Chuẩn hoá tên file thành `specs/<FEATURE_NAME>_SPEC.md`.
2. Khởi tạo sẵn toàn bộ 7 phần cấu trúc theo chuẩn `feature-brainstorm`.
3. Điền sẵn các Mermaid diagram mẫu, bảng edge cases và checklist triển khai.

---

## 4. Lệnh Kiểm Tra Tiến Độ SPEC & Backlog Tự Động

Kiểm tra tiến độ thực hiện tất cả các SPEC, thống kê Backlog và quét TODO trong mã nguồn:

```bash
# Báo cáo trực quan kèm thanh tiến độ:
make check-spec
# hoặc chạy trực tiếp script:
./scripts/check-specs-backlog.sh

# Xem chi tiết các task còn tồn đọng:
./scripts/check-specs-backlog.sh --details

# Xuất định dạng JSON (cho CI hoặc AI Assistant):
./scripts/check-specs-backlog.sh --json

# Chế độ Strict (exit code 1 nếu còn task chưa hoàn thành - dùng cho CI):
./scripts/check-specs-backlog.sh --strict
```
