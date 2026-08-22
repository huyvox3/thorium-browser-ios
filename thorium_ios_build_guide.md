# Hướng dẫn Tìm hiểu Source Code và Build Thorium Browser cho iOS

Tài liệu này hướng dẫn chi tiết cách tìm hiểu cấu trúc tối ưu hóa của **Thorium Browser**, phân tích tính khả thi và cung cấp quy trình biên dịch phiên bản tối ưu hóa cho **iOS (ARM64)** sử dụng các thiết lập hiệu năng cao từ Thorium.

---

## 1. Tổng quan về Thorium Browser & Các Tối ưu hóa Cốt lõi

**Thorium** là một bản phân phối (fork) hiệu năng cao của Chromium. Các cải tiến cốt lõi của Thorium nằm ở khâu **biên dịch (compiler & linker configurations)** chứ không chỉ là giao diện hay tính năng:

*   **Tối ưu hóa tập lệnh SIMD:** Sử dụng các tập lệnh chuyên dụng như AVX, AVX2, FMA3 trên x86-64 để xử lý song song dữ liệu lớn.
*   **Cờ biên dịch hung hãn:** Sử dụng mức tối ưu hóa cao nhất `-O3` (thay vì `-O2` mặc định của Chromium) kết hợp với các cờ loop optimization của LLVM/Clang.
*   **ThinLTO (Link-Time Optimization):** Cho phép tối ưu hóa xuyên suốt các file mã nguồn khác nhau trong quá trình liên kết (link), giúp giảm thời gian khởi động và tăng tốc độ xử lý tổng thể.
*   **PGO (Profile-Guided Optimization):** Sử dụng dữ liệu đo đạc thực tế (speedometer) để định hình luồng xử lý tối ưu nhất trong nhân trình duyệt.
*   **V8 Engine Tuning:** Kích hoạt các cỗ máy tối ưu hóa của Javascript engine (như Maglev, Turbofan, Fast Torque).

---

## 2. Khả thi & Thách thức khi Build cho iOS

> [!IMPORTANT]
> **Yêu cầu môi trường macOS và Xcode:**
> Bạn **không thể** trực tiếp biên dịch Chromium/Thorium cho iOS trên máy chạy hệ điều hành **Linux Mint** hiện tại. Quá trình liên kết và ký ứng dụng (code signing) bắt buộc phải thực hiện trên máy chạy **macOS** có cài đặt **Xcode**.

### So sánh tối ưu hóa x86-64 vs ARM64 (iOS)
*   **Không dùng AVX/AVX2:** Thiết bị iOS (iPhone/iPad) chạy chip Apple Silicon (ARM64). Các cờ biên dịch x86 như `-mavx` sẽ không hoạt động.
*   **Thay thế bằng ARM NEON & Vector:** Chúng ta sẽ tận dụng khả năng tăng tốc phần cứng của kiến trúc **ARMv8.3-A** trở lên (hỗ trợ bởi các dòng chip Apple A12, A13, A14, A15, A16, A17 Pro và dòng chip M).
*   **Thay đổi build/config/arm.gni:** Ta sẽ ghi đè cấu hình ARM mặc định của Chromium bằng file tối ưu hóa `mac_arm.gni` từ Thorium (kích hoạt `arm_arch = "armv8.3-a"`, `arm_tune = "generic-armv8.3-a"`, `arm_use_neon = true`).

### Rendering Engine: WebKit vs Blink trên iOS
*   **Mặc định (WebKit):** Apple yêu cầu tất cả trình duyệt phát hành trên App Store toàn cầu phải dùng engine WebKit (`WKWebView`). Bản build mặc định của Chrome iOS là WebKit wrapper.
*   **Thử nghiệm (Blink):** Google có dự án thử nghiệm đưa engine Blink gốc lên iOS (bật bằng flag `use_blink = true`). Bạn có thể tự build phiên bản Blink này nhưng chỉ có thể sideload lên thiết bị cá nhân chứ không thể tải lên App Store thông thường.

---

## 3. Các File Cấu hình Đã chuẩn bị trong Workspace

Trong thư mục workspace `/home/nvpa/thorium_ios`, chúng tôi đã chuẩn bị sẵn 2 file cốt lõi để bạn copy sang máy Mac:

1.  **[ios_Release_args.gn](file:///home/nvpa/thorium_ios/ios_Release_args.gn):** File chứa toàn bộ các flag cấu hình tối ưu hóa của Thorium thích ứng cho iOS (ThinLTO, V8 optimizations, disable symbols & debug checks, v.v.).
2.  **[setup_ios.sh](file:///home/nvpa/thorium_ios/setup_ios.sh):** Script tự động trên macOS để tải `depot_tools`, tải mã nguồn Chromium iOS (khoảng ~100GB+), áp dụng cấu hình tối ưu hóa ARM64 của Thorium và sinh file build Ninja.

---

## 4. Quy trình Biên dịch Từng bước (Thực hiện trên máy Mac)

Hãy copy thư mục `/home/nvpa/thorium_ios` sang máy Mac của bạn và làm theo các bước sau:

### Bước 1: Chuẩn bị môi trường trên macOS
1.  Cài đặt **Xcode** từ Mac App Store.
2.  Mở Terminal và cài đặt Xcode Command Line Tools:
    ```bash
    xcode-select --install
    ```
3.  Cài đặt iOS Simulator thông qua Xcode (Xcode -> Settings -> Platforms -> Download iOS Simulator).

### Bước 2: Chạy Script chuẩn bị
Di chuyển vào thư mục workspace đã copy trên máy Mac và thực thi script:
```bash
./setup_ios.sh
```
> [!NOTE]
> Script này sẽ mất vài giờ ở bước `fetch ios` vì dung lượng mã nguồn Chromium cực kỳ lớn (~100-120 GB).

### Bước 3: Biên dịch trình duyệt bằng Ninja
Sau khi script chạy hoàn tất, bạn chuyển vào thư mục mã nguồn và bắt đầu build:
```bash
cd chromium/src
# Thêm depot_tools vào PATH nếu chưa có
export PATH="$(pwd)/../../depot_tools:$PATH"

# Biên dịch ứng dụng Chrome iOS (sử dụng autoninja để tận dụng tối đa CPU của máy Mac)
autoninja -C out/Release-iphoneos chrome
```

### Bước 4: Cài đặt ứng dụng lên iPhone / iPad (Sideloading)

Sau khi quá trình biên dịch hoàn tất, file ứng dụng chạy trên iOS thực tế của bạn sẽ được lưu dưới dạng thư mục Bundle: `out/Release-iphoneos/chrome.app`. Bạn có thể cài đặt thư mục ứng dụng này lên iPhone bằng 3 phương pháp chính sau:

#### Phương pháp 1: Cài đặt trực tiếp qua Xcode (Khuyên dùng khi phát triển)
Đây là cách nhanh nhất và chính thống nhất khi bạn tự biên dịch ứng dụng từ mã nguồn bằng máy Mac:

1. Kết nối iPhone với máy Mac của bạn bằng cáp Lightning/USB-C.
2. Trên iPhone: Kích hoạt **Chế độ nhà phát triển (Developer Mode)** bằng cách vào *Cài đặt (Settings) -> Quyền riêng tư & Bảo mật (Privacy & Security) -> Developer Mode* -> Bật và khởi động lại thiết bị theo yêu cầu.
3. Trên máy Mac: Mở dự án bằng Xcode thông qua file dự án được tạo tự động:
   ```bash
   open out/Release-iphoneos/all.xcodeproj
   ```
4. Trong thanh điều hướng của Xcode, chọn thiết bị iPhone của bạn làm thiết bị mục tiêu (Target Device).
5. Vào cài đặt dự án (Project Settings) -> thẻ **Signing & Capabilities**:
   * Chọn **Team** (đăng nhập Apple ID miễn phí của bạn hoặc tài khoản trả phí).
   * Xcode sẽ tự động tạo cấu hình Provisioning Profile để ký số cho ứng dụng.
6. Nhấn nút **Run** (hình tam giác ở góc trên bên trái Xcode) để Xcode tự ký số, truyền file và cài đặt trực tiếp lên iPhone của bạn.
7. **Xác minh nhà phát triển trên iPhone:** Khi ứng dụng xuất hiện trên màn hình chính, bạn chưa mở được ngay. Hãy vào *Cài đặt -> Cài đặt chung -> Quản lý thiết bị & VPN (VPN & Device Management)* -> Chọn Apple ID của bạn -> Nhấn **Tin cậy (Trust)**. Bây giờ bạn đã có thể mở trình duyệt trên điện thoại.

---

#### Phương pháp 2: Đóng gói thành `.ipa` và cài qua AltStore / Sideloadly
Phương pháp này giúp bạn tạo ra 1 file cài đặt độc lập (`.ipa`) để chia sẻ hoặc tự cài mà không cần mở Xcode dự án:

1. **Đóng gói file `.ipa` từ thư mục `.app`:**
   Trên Terminal của máy Mac, thực thi các lệnh sau để tạo cấu trúc gói iOS tiêu chuẩn:
   ```bash
   cd out/Release-iphoneos/
   mkdir Payload
   cp -r chrome.app Payload/
   zip -vr Thorium.ipa Payload/
   rm -rf Payload
   ```
   Lúc này bạn sẽ thu được file `Thorium.ipa` trong thư mục `out/Release-iphoneos/`.
2. **Cài đặt qua Sideloadly hoặc AltStore:**
   * Tải và cài đặt **Sideloadly** hoặc **AltStore** lên máy tính của bạn.
   * Kéo thả file `Thorium.ipa` vào công cụ.
   * Nhập Apple ID để ký ứng dụng và nhấn **Start/Install** để tải app lên điện thoại.
   * *Lưu ý:* Với tài khoản Apple ID miễn phí, ứng dụng sẽ hết hạn sau **7 ngày**. Bạn cần cắm máy tính để gia hạn (refresh) chứng chỉ qua AltStore/Sideloadly.

---

#### Phương pháp 3: Cài đặt vĩnh viễn không bị thu hồi qua TrollStore (Tốt nhất)
Nếu iPhone của bạn đang chạy phiên bản iOS được hỗ trợ bởi lỗ hổng CoreTrust (từ iOS 14.0 đến 16.6.1, và một số phiên bản iOS 17.0 tùy dòng máy):

1. Thực hiện các bước đóng gói file `Thorium.ipa` như ở **Phương pháp 2**.
2. Gửi file `Thorium.ipa` sang iPhone của bạn (qua AirDrop, iCloud Drive hoặc ứng dụng nhắn tin).
3. Mở ứng dụng **TrollStore** trên iPhone.
4. Chọn nút **+** ở góc phải màn hình TrollStore -> chọn **Install IPA File** -> chọn file `Thorium.ipa` vừa tải về.
5. TrollStore sẽ tiến hành bypass chứng chỉ hệ thống của Apple và cài đặt ứng dụng trực tiếp. 
6. *Ưu điểm:* Ứng dụng được cài qua TrollStore sẽ **không bao giờ bị hết hạn 7 ngày**, không cần máy tính để gia hạn lại, chạy với đầy đủ đặc quyền tối ưu hóa phần cứng và hỗ trợ cài nhiều hơn 3 ứng dụng sideload cùng lúc.

