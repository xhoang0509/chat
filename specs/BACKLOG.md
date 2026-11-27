# Danh Mục Tồn Đọng & Kế Hoạch Tính Năng (Backlog)

Tài liệu này lưu trữ tập trung các tính năng dự kiến, ý tưởng phát triển (v2+), và các nợ kỹ thuật (Tech Debt) cần giải quyết cho dự án `tidebird/chat`.

---

## 1. Tính Năng Đang Lên Kế Hoạch / Sắp Triển Khai (Upcoming Features)

| Ưu tiên | Mã ID | Tên tính năng | Loại | SPEC Dự kiến | Trạng thái |
|:---:|:---|:---|:---:|:---|:---:|
| **P1** | **BL-01** | **Giải đấu Loại Trực Tiếp (Game Tournaments)** | Game | `TOURNAMENT_SPEC.md` | 💡 Ý tưởng |
| **P1** | **BL-02** | **Cờ Tướng Úp (Blind Xiangqi)** | Game | `BLIND_XIANGQI_SPEC.md` | 💡 Ý tưởng |
| **P2** | **BL-03** | **Biên bản ván cờ & Xem lại (Game Replay / PGN)** | Feature | `GAME_REPLAY_SPEC.md` | 💡 Ý tưởng |
| **P2** | **BL-04** | **Mini Floating Window (Picture-in-Picture bàn cờ)** | UI/UX | `LIVE_GAMES_PIP_SPEC.md` | 💡 Ý tưởng |
| **P2** | **BL-05** | **Bình chọn Dự đoán Người Thắng (Game Prediction)** | Social | `PREDICTION_POLL_SPEC.md` | 💡 Ý tưởng |
| **P3** | **BL-06** | **AI Phân Tích Thế Cờ Thời Gian Thực (AI Commentary)** | AI | `AI_GAME_COMMENTARY_SPEC.md` | 💡 Ý tưởng |
| **P3** | **BL-07** | **Âm thanh nước đi tuỳ chỉnh (Custom Soundboard)** | Audio | `CUSTOM_SOUNDBOARD_SPEC.md` | 💡 Ý tưởng |
| **P1** | **BL-08** | **Nông trại: Người làm thuê (tự động khi tắt app)** | Feature | `FARM_HIRED_HELPER_SPEC.md` | 📝 Đã đặc tả |
| **P1** | **BL-09** | **Nông trại: Thời tiết & Mùa vụ** | Feature | `FARM_WEATHER_SEASONS_SPEC.md` | 📝 Đã đặc tả |
| **P2** | **BL-10** | **Nông trại: Hàng xóm & Vườn cây, Đơn hàng đôi** | Social | `FARM_ORCHARD_SOCIAL_SPEC.md` | 📝 Đã đặc tả |
| **P2** | **BL-11** | **Nông trại: Thành tích & Trang trí** | Feature | `FARM_ACHIEVEMENTS_DECOR_SPEC.md` | 📝 Đã đặc tả |
| **P2** | **BL-12** | **Nông trại: Sự kiện tuần & Bảng xếp hạng** | Feature | `FARM_WEEKLY_EVENTS_SPEC.md` | 📝 Đã đặc tả |

---

> **Ghi chú BL-08..12 (nông trại):** thứ tự làm đề xuất là BL-08 → BL-09 → BL-10 → BL-11 → BL-12.
> Số migration trong các spec chỉ là dự kiến, lúc làm lấy số kế tiếp. BL-12 dùng các khoá bump mà
> BL-11 thêm vào, nên làm BL-11 trước. Nếu làm BL-12 trước thì nó tự thêm các khoá đó.

---

## 2. Chi Tiết Kế Hoạch Từng Tính Năng

### BL-01: Giải đấu Loại Trực Tiếp (Tournament Brackets)
- **Mục tiêu**: Cho phép tạo giải đấu nội bộ cho Cờ Caro, Cờ Vua, Cờ Tướng trong kênh chat.
- **Phạm vi**:
  - [ ] Bảng đấu 4 / 8 / 16 người (Single Elimination).
  - [ ] Tự động chia cặp đấu ngẫu nhiên hoặc xếp hạt giống.
  - [ ] Tự động chuyển người thắng vào vòng trong.
  - [ ] Vinh danh người vô địch trên kênh và bảng xếp hạng huy chương.

### BL-02: Cờ Tướng Úp (Blind Xiangqi)
- **Mục tiêu**: Mở rộng trò chơi Cờ Tướng với thể thức Cờ Úp quen thuộc của Việt Nam.
- **Phạm vi**:
  - [ ] Giữ nguyên 2 quân Tướng mở, úp ngẫu nhiên 30 quân còn lại.
  - [ ] Nước đi đầu tiên của quân úp tuân theo vị trí ô hiện tại của quân cờ chuẩn.
  - [ ] Lật quân khi thực hiện nước đi đầu tiên.

### BL-03: Biên bản ván cờ & Xem lại (Game Replay)
- **Mục tiêu**: Lưu lại toàn bộ nước đi của ván cờ để kỳ thủ và khán giả xem lại diễn biến.
- **Phạm vi**:
  - [ ] Xuất biên bản cờ chuẩn PGN / WXF.
  - [ ] Giao diện xem lại nước đi từng bước (`<`, `>`, `<<`, `>>`).
  - [ ] Chia sẻ biên bản trận đấu đẹp mắt vào kênh chat.

### BL-04: Mini Floating Window (Picture-in-Picture)
- **Mục tiêu**: Kỳ thủ vừa theo dõi bàn cờ vừa đọc các tin nhắn khác trong kênh.
- **Phạm vi**:
  - [ ] Cửa sổ mini nổi góc dưới phải màn hình.
  - [ ] Cho phép thu nhỏ / phóng to bàn cờ khi cuộn tin nhắn đi xa.

---

## 3. Nợ Kỹ Thuật & Cải Thiện Hệ Thống (Technical Debt & Maintenance)

- [ ] **TD-01**: Tối ưu hoá bundle size của frontend Vite (tách `libsodium-wrappers` sang lazy-loading chunk).
- [ ] **TD-02**: Thêm kiểm tra tự động chiếu lặp (perpetual check 3 lần xử hoà) cho động cơ Cờ Vua và Cờ Tướng.
- [ ] **TD-03**: Nâng cấp kết nối WebSocket tự động đồng bộ lại state phòng game khi mất mạng tạm thời.
