# Tidebird Chat - Project Rules & Context

Dự án **Go Chat (Tidebird Chat)**: Hệ thống chat theo kênh cho mạng nội bộ gồm server Go + SQLite, giao diện Web (React) và ứng dụng Desktop (Tauri), tích hợp gọi thoại/video WebRTC và các mini game (Cờ tướng, Cờ vua).

---

## 1. Cấu Trúc Dự Án (Architecture & Directory Map)

- `main.go`: Entry point khởi chạy HTTP server, WebSocket hub, và static file serving.
- `controller/`: Handlers xử lý HTTP API và WebSocket routing (auth, message, channel, uploads, game).
- `game/`: Logic các bàn cờ và luật chơi (Xiangqi - Cờ tướng, Chess - Cờ vua).
- `rtc/`: Peer-to-peer WebRTC signaling và room management.
- `store/` & `database/`: Tương tác cơ sở dữ liệu SQLite (`chat.db`) và quản lý schema.
- `web/`: Mã nguồn frontend React + Vite + Tailwind CSS.
- `desktop/`: Mã nguồn ứng dụng desktop Tauri (Rust backend + web assets).
- `specs/`: Thư mục lưu trữ tập trung các tài liệu đặc tả kỹ thuật (`*_SPEC.md`) và chỉ mục `specs/README.md`.
- `Makefile`: Các lệnh build và deploy (`make server`, `make desktop`, `make test`, `make deploy`).

---

## 2. Quy Trình Khởi Động Session Mới (Session Startup Protocol)

Mỗi khi bắt đầu một session mới hoặc ở turn đầu tiên:
1. **Kiểm tra ngữ cảnh**: Tự động nhận diện nhánh Git hiện tại và trạng thái các file đang sửa đổi (`git status`).
2. **Quy chuẩn trao đổi**: Trả lời ngắn gọn, súc tích, bằng tiếng Việt. Luôn đính kèm đường dẫn dạng clickable link `[tên_file](file:///đường/dẫn)` khi nhắc đến file.
3. **Đọc Spec trước khi sửa**: Nếu làm việc liên quan đến Game hoặc Tính năng mới, luôn đọc các file đặc tả trong thư mục `specs/` (ví dụ: `specs/XIANGQI_GAME_SPEC.md`, `specs/CHESS_GAME_SPEC.md`, `specs/LIVE_GAMES_TOPBAR_SPEC.md`, `specs/GAME_VIEWER_THREAD_SPEC.md`, `specs/BACKLOG.md`). Khi tạo spec mới, bắt buộc lưu vào `specs/` và dùng script `./scripts/create-spec.sh <name>`. Kiểm tra tiến độ và backlog bất cứ lúc nào bằng `make check-spec` (hoặc `./scripts/check-specs-backlog.sh`).

---

## 3. Quy Chuẩn Kỹ Thuật (Development Guidelines)

- **Backend**: Go (tuân thủ `go fmt`, kiểm tra lỗi cẩn thận, không nuốt error).
- **Kiểm thử**: Mọi logic game hoặc hàm xử lý dữ liệu mới bắt buộc có unit test (`*_test.go`). Chạy `go test ./...` để kiểm tra.
- **Build**:
  - Build server duy nhất: `make server` (tạo binary `./go-chat`).
  - Build desktop: `make desktop`.
