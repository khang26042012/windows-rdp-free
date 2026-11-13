# 🖥️ Windows RDP Free Node (Auto-Login & Pre-loaded Golden Pack 8.5 GB)

Repository máy ảo Windows miễn phí với tính năng **Auto-Login** và tự động nạp sẵn **Golden Pack 8.5 GB (kèm session Antigravity)** từ GitHub Release `v1.0.0`. Không còn phải đợi load profile khi đăng nhập RDP!

---

### 🚀 CÁCH KHỞI CHẠY MÁY ẢO

1. Truy cập vào mục Actions: **https://github.com/khang26042012/windows-rdp-free/actions**
2. Ở cột bên trái, bấm vào **'Windows RDP Free'**.
3. Bấm vào nút **'Run workflow'** bên phải:
   - **`tailscale_key`**: Dán mã Tailscale Auth Key (hoặc để trống nếu đã cấu hình trong GitHub Secrets).
   - **`rdp_pass`**: Mật khẩu máy ảo (mặc định: `KhangSMP@2026`).
   - **`hostname`**: Tên máy Tailscale (mặc định: `windows-khang`).
4. Bấm nút màu xanh **'Run workflow'**.

---

### 📱 KẾT NỐI RDP

- Sau khi khởi động xong (khoảng 30-45 giây), thông tin kết nối sẽ tự động cập nhật vào file [`RDP_ACTIVE.txt`](./RDP_ACTIVE.txt).
- **PC Name (Địa chỉ kết nối):**
  - Khuyên dùng: Nhập trực tiếp **IP Tailscale** hiển thị trong `RDP_ACTIVE.txt`.
  - Dự phòng: `bore.pub:<port>` (khi không dùng Tailscale).
- **Username:** `khangmc` *(hoặc dự phòng: `runneradmin`)*.
- **Password:** Mật khẩu đã đặt (mặc định: `KhangSMP@2026`).
- **Giao diện & Ứng dụng:** Đã nạp sẵn 100% ngay từ đầu (Desktop, Antigravity, Windhawk, Discord, Chrome, Firefox...) mà không cần chờ đợi.
