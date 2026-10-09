# 🖥️ Hướng Dẫn Kết Nối Windows RDP Vào App 'Windows App' Trên Điện Thoại

Hệ thống máy ảo **Windows 64-bit Desktop** miễn phí 100% chạy trên hạ tầng Microsoft Azure thông qua GitHub Actions.

---

### 🔑 BƯỚC 1: LẤY MÃ NGROK TOKEN (Miễn phí - chỉ mất 10 giây)
1. Mở trình duyệt vào trang: **https://dashboard.ngrok.com/signup**
2. Bấm nút **'Continue with Google'** (đăng nhập bằng tài khoản Google của anh).
3. Đăng nhập xong, vào trang: **https://dashboard.ngrok.com/get-started/your-authtoken**
4. Bấm nút **Copy** dòng token của anh (có dạng kiểu: `2tXXXXXXXXXXXX_YYYYYYYYYYYYYY`).

---

### 🚀 BƯỚC 2: KHỞI ĐỘNG MÁY ẢO TRÊN GITHUB
1. Truy cập vào mục Actions: **https://github.com/khang26042012/windows-rdp-free/actions**
2. Ở cột bên trái, bấm vào **'Windows RDP Free'**.
3. Nhìn sang bên phải, bấm vào nút **'Run workflow'**.
4. Dán mã Ngrok Token ở Bước 1 vào ô trống ➔ Bấm nút **Run workflow** màu xanh.
5. Đợi khoảng 30 - 45 giây cho máy khởi động, bấm vào job đang chạy và xem mục **'4. Khoi Chay Tunnel va Lay Dia Chi Ket Noi'**.
6. Màn hình sẽ hiện ra thông tin:
   * **PC Name (Địa chỉ kết nối):** Ví dụ `0.tcp.ap.ngrok.io:14523`
   * **Username:** `khang`
   * **Password:** `KhangSMP@2026`

---

### 📱 BƯỚC 3: DÁN VÀO APP TRÊN ĐIỆN THOẠI (Windows App / Remote Desktop)
1. Mở app **Windows App** (hoặc **Remote Desktop**) của Microsoft trên điện thoại.
2. Bấm dấu **`+`** ở góc trên ➔ Chọn **Add PC**.
3. Mục **PC Name:** Dán địa chỉ ở Bước 2 vào (ví dụ: `0.tcp.ap.ngrok.io:14523`).
4. Mục **User Account:** Bấm Add User Account ➔ Nhập:
   * Username: `khang`
   * Password: `KhangSMP@2026`
5. Bấm **Save**.
6. Nhấp vào chiếc máy tính vừa hiện trên màn hình app để kết nối ➔ **Màn hình Windows 11 Desktop thật 100% sẽ hiện ra ngay trên điện thoại của anh!**
