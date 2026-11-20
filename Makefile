# Go Chat: build cả server (kèm giao diện web) và app desktop.
#
#   make server    giao diện web + server Go -> ./go-chat (mở http://<ip>:4000 trên trình duyệt)
#   make desktop   bộ cài app desktop (.deb, AppImage) -> desktop/src-tauri/target/release/bundle/
#   make run       build server rồi chạy
#   make test      chạy test Go
#   make check-spec kiểm tra tiến độ SPEC và backlog

export PATH := $(HOME)/.cargo/bin:$(PATH)

.PHONY: all web server desktop run test check-spec icons clean giphy-key ai-key install-service install-tunnel route-dns deploy logs status start stop stop-tunnel disable enable

all: server desktop

# Giao diện (React) -> web/ui/dist, dùng chung cho cả server và app desktop.
web:
	cd desktop && pnpm install --frozen-lockfile && pnpm build

# Server Go, nhúng sẵn giao diện web.
server: web
	go build -o go-chat .

# App desktop. Tauri tự chạy `pnpm build` trước khi đóng gói.
desktop:
	cd desktop && pnpm install --frozen-lockfile && pnpm tauri build

run: server
	./go-chat

# Cài server thành dịch vụ systemd của user: tự chạy lại khi lỗi và khi máy khởi động.
SERVICE_DIR := $(HOME)/.config/systemd/user
install-service: server
	mkdir -p $(SERVICE_DIR)
	sed 's#__DIR__#$(CURDIR)#g' deploy/go-chat.service > $(SERVICE_DIR)/go-chat.service
	systemctl --user daemon-reload
	systemctl --user enable --now go-chat.service
	systemctl --user restart go-chat.service
	@loginctl show-user "$$USER" -p Linger | grep -q yes || \
		echo "Chưa bật linger: chạy 'sudo loginctl enable-linger $$USER' để dịch vụ tự chạy khi máy khởi động mà không cần đăng nhập."

# Bật tìm GIF: make giphy-key KEY=<API key GIPHY> (lấy miễn phí tại https://developers.giphy.com).
# Key lưu ở ~/.config/go-chat/env (chỉ mình bạn đọc được), không nằm trong repo.
ENV_FILE := $(HOME)/.config/go-chat/env
giphy-key:
	@test -n "$(KEY)" || { echo "Dùng: make giphy-key KEY=<api key>"; exit 1; }
	@mkdir -p $(dir $(ENV_FILE))
	@touch $(ENV_FILE) && chmod 600 $(ENV_FILE)
	@grep -v '^GIPHY_API_KEY=' $(ENV_FILE) > $(ENV_FILE).tmp || true
	@echo 'GIPHY_API_KEY=$(KEY)' >> $(ENV_FILE).tmp && mv $(ENV_FILE).tmp $(ENV_FILE) && chmod 600 $(ENV_FILE)
	systemctl --user restart go-chat.service
	@echo "Đã bật tìm GIF."

# Trợ lý AI (@ai): không cần làm gì vẫn chạy được (Pollinations miễn phí). Có key thì tốt hơn:
#   make ai-key PROVIDER=gemini KEY=...        chat, lấy key miễn phí: https://aistudio.google.com/apikey
#   make ai-key PROVIDER=groq KEY=...          chat nhanh, miễn phí: https://console.groq.com/keys
#   make ai-key PROVIDER=openrouter KEY=...    chat bằng model free: https://openrouter.ai/keys
#   make ai-key PROVIDER=together KEY=...      vẽ ảnh FLUX miễn phí: https://api.together.ai/settings/api-keys
#   make ai-key PROVIDER=cloudflare KEY=<api token> ACCOUNT=<account id>   vẽ ảnh, Workers AI
#   make ai-key PROVIDER=pollinations KEY=...  model mạnh, ngữ cảnh dài, đọc ảnh, vẽ lại từ ảnh gốc: https://enter.pollinations.ai
#   make ai-key PROVIDER=tavily KEY=...        tìm web tốt hơn (1000 lần/tháng miễn phí): https://app.tavily.com
#   make ai-key PROVIDER=brave KEY=...         tìm web (2000 lần/tháng miễn phí): https://brave.com/search/api
# Bên nào có key thì dùng trước, lỗi thì tự chuyển sang bên khác. Key lưu ở ENV_FILE như trên.
AI_VAR_gemini := GEMINI_API_KEY
AI_VAR_groq := GROQ_API_KEY
AI_VAR_openrouter := OPENROUTER_API_KEY
AI_VAR_together := TOGETHER_API_KEY
AI_VAR_cloudflare := CF_API_TOKEN
AI_VAR_pollinations := POLLINATIONS_API_KEY
AI_VAR_tavily := TAVILY_API_KEY
AI_VAR_brave := BRAVE_API_KEY
ai-key:
	@test -n "$(AI_VAR_$(PROVIDER))" -a -n "$(KEY)" || { echo "Dùng: make ai-key PROVIDER=gemini|groq|openrouter|together|cloudflare|pollinations|tavily|brave KEY=<key> [ACCOUNT=<cloudflare account id>]"; exit 1; }
	@test "$(PROVIDER)" != cloudflare -o -n "$(ACCOUNT)" || { echo "Cloudflare cần thêm ACCOUNT=<account id>"; exit 1; }
	@mkdir -p $(dir $(ENV_FILE))
	@touch $(ENV_FILE) && chmod 600 $(ENV_FILE)
	@grep -v -e '^$(AI_VAR_$(PROVIDER))=' $(if $(ACCOUNT),-e '^CF_ACCOUNT_ID=') $(ENV_FILE) > $(ENV_FILE).tmp || true
	@echo '$(AI_VAR_$(PROVIDER))=$(KEY)' >> $(ENV_FILE).tmp
	@$(if $(ACCOUNT),echo 'CF_ACCOUNT_ID=$(ACCOUNT)' >> $(ENV_FILE).tmp,true)
	@mv $(ENV_FILE).tmp $(ENV_FILE) && chmod 600 $(ENV_FILE)
	systemctl --user restart go-chat.service
	@echo "Đã lưu key $(PROVIDER) cho Trợ lý AI."

# Đưa chat ra internet qua Cloudflare Tunnel. Tunnel phải được tạo và route DNS trước:
#   cloudflared tunnel create <tên-tunnel>
#   cloudflared tunnel route dns <tên-tunnel> <tên-miền>
#   make install-tunnel TUNNEL_NAME=<tên-tunnel> TUNNEL_HOST=<tên-miền>
TUNNEL_NAME ?= go-chat
TUNNEL_HOST ?= gochat.quyenpv.site
CLOUDFLARED ?= $(shell command -v cloudflared)
TUNNEL_ID = $(shell $(CLOUDFLARED) tunnel list 2>/dev/null | awk '$$2=="$(TUNNEL_NAME)"{print $$1}')
# Trỏ DNS TUNNEL_HOST về đúng tunnel của chat (ghi đè bản ghi cũ nếu có).
# Luôn truyền --config riêng + id tunnel: nếu không, cloudflared đọc ~/.cloudflared/config.yml
# (đang có "tunnel: agent-review") và trỏ nhầm sang tunnel đó.
route-dns:
	@test -n "$(TUNNEL_ID)" || { echo "Chưa có tunnel '$(TUNNEL_NAME)'."; exit 1; }
	$(CLOUDFLARED) --config $(HOME)/.cloudflared/go-chat.yml tunnel route dns --overwrite-dns $(TUNNEL_ID) $(TUNNEL_HOST)
	@sleep 5; curl -sf -m 10 https://$(TUNNEL_HOST)/api/health && echo "  <- https://$(TUNNEL_HOST) đã chạy" || \
		echo "DNS có thể cần vài chục giây để cập nhật, thử lại: curl https://$(TUNNEL_HOST)/api/health"

install-tunnel:
	@test -n "$(TUNNEL_ID)" || { echo "Chưa có tunnel '$(TUNNEL_NAME)'. Chạy: cloudflared tunnel create $(TUNNEL_NAME)"; exit 1; }
	sed -e 's#__TUNNEL_ID__#$(TUNNEL_ID)#g' -e 's#__HOME__#$(HOME)#g' -e 's#__HOST__#$(TUNNEL_HOST)#g' \
		deploy/cloudflared-go-chat.yml > $(HOME)/.cloudflared/go-chat.yml
	mkdir -p $(SERVICE_DIR)
	sed -e 's#__CLOUDFLARED__#$(CLOUDFLARED)#g' -e 's#__HOME__#$(HOME)#g' \
		deploy/go-chat-tunnel.service > $(SERVICE_DIR)/go-chat-tunnel.service
	systemctl --user daemon-reload
	systemctl --user enable --now go-chat-tunnel.service
	@echo "Đợi tunnel kết nối..."; sleep 8
	@curl -sf -m 10 https://$(TUNNEL_HOST)/api/health && echo "  <- https://$(TUNNEL_HOST) đã chạy" || \
		echo "Chưa truy cập được, xem log: journalctl --user -u go-chat-tunnel -n 30"

# Build bản mới rồi khởi động lại dịch vụ (người dùng chỉ cần tải lại trang).
deploy: server
	systemctl --user restart go-chat.service
	@sleep 1; systemctl --user --no-pager --lines=0 status go-chat.service | head -3

logs:
	journalctl --user -u go-chat.service -f

# Điều khiển dịch vụ. Đừng dùng `kill`: systemd sẽ chạy lại ngay (Restart=always).
SERVICES := go-chat.service go-chat-tunnel.service
status:
	@systemctl --user --no-pager status $(SERVICES) | grep -E "●|Active:"
start:
	systemctl --user start $(SERVICES)
# Tắt ngay, nhưng khởi động máy lần sau vẫn tự chạy.
stop:
	systemctl --user stop $(SERVICES)
# Chỉ đóng truy cập từ internet, trong LAN vẫn dùng được.
stop-tunnel:
	systemctl --user stop go-chat-tunnel.service
# Tắt hẳn và bỏ tự chạy khi khởi động (bật lại: make enable).
disable:
	systemctl --user disable --now $(SERVICES)
enable:
	systemctl --user enable --now $(SERVICES)

test:
	go test ./...

check-spec:
	@./scripts/check-specs-backlog.sh

# Tạo lại bộ icon app từ desktop/public/favicon.svg
icons:
	cd desktop && pnpm tauri icon public/favicon.svg

clean:
	rm -rf go-chat web/ui/dist desktop/src-tauri/target/release/bundle
