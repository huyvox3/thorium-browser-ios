# Thorium iOS Build Helper & Configurations

Công cụ và tài liệu hướng dẫn hỗ trợ chuẩn bị môi trường, áp dụng cấu hình tối ưu hóa từ **Thorium Browser** và biên dịch trình duyệt **Chromium cho iOS (ARM64)**.

---

## 📂 Danh sách các file trong dự án

*   **`setup_ios.sh`**: Script chạy trên macOS để tự động tải `depot_tools`, tải mã nguồn Chromium iOS, áp dụng cấu hình tối ưu hóa ARM64 của Thorium và sinh file build.
*   **`ios_Release_args.gn`**: File cấu hình GN Arguments mẫu chứa các flag tối ưu hiệu năng cao (ThinLTO, V8 optimizations, disable debug, ARM NEON).
*   **`thorium_ios_build_guide.md`**: Tài liệu hướng dẫn biên dịch và sideload chi tiết bằng tiếng Việt.
*   **`thorium/`**: Thư mục tham chiếu chứa các patch và file tối ưu hóa của dự án Thorium gốc.

---

## ⚡ Hướng dẫn nhanh (Thực hiện trên máy Mac)

### 1. Chuẩn bị
Đảm bảo máy Mac của bạn đã cài đặt **Xcode** và **Xcode Command Line Tools** (`xcode-select --install`).

### 2. Chạy Script chuẩn bị
Chạy script để tự động tải công cụ và mã nguồn:
```bash
./setup_ios.sh
```
> *Lưu ý: Quá trình này sẽ tải hơn 100GB dữ liệu mã nguồn Chromium iOS nên cần kết nối mạng tốc độ cao và mất vài giờ.*

### 3. Tiến hành Biên dịch
Di chuyển vào thư mục code và bắt đầu build bằng `autoninja`:
```bash
cd chromium/src
export PATH="$(pwd)/../../depot_tools:$PATH"
autoninja -C out/Release-iphoneos chrome
```

### 4. Cài đặt lên iPhone / iPad
File chạy trên iOS nằm ở `out/Release-iphoneos/chrome.app`. Bạn có thể cài đặt bằng 3 cách:
*   **Cách 1 (Xcode - Khuyên dùng):** Mở project bằng Xcode, chọn thiết bị iPhone của bạn và nhấn nút **Run** (Gia hạn sau 7 ngày bằng cách cắm máy nhấn Run lại).
*   **Cách 2 (AltStore / Sideloadly):** Đóng gói thành file `.ipa` rồi cài đặt qua AltStore. AltStore hỗ trợ tự động gia hạn chứng chỉ 7 ngày qua mạng Wi-Fi.
*   **Cách 3 (TrollStore):** Nếu iOS của bạn từ 16.6.1 trở xuống, bạn có thể cài vĩnh viễn qua TrollStore không bao giờ hết hạn.

---

*Để biết chi tiết từng bước thực hiện và phân tích chuyên sâu về tối ưu hóa phần cứng, vui lòng đọc file **[thorium_ios_build_guide.md](./thorium_ios_build_guide.md)**.*
