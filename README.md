# Thorium iOS Build Helper & Configurations

An automated toolchain and build helper to compile an optimized Chromium browser for iOS (ARM64), leveraging compiler settings and performance configurations from the **Thorium Browser** project.

---

## 📂 Project Structure

*   **`setup_ios.sh`**: A shell script designed for macOS that automatically downloads `depot_tools`, fetches the Chromium iOS codebase, applies Thorium ARM64 compiler configurations, and generates the build directory.
*   **`ios_Release_args.gn`**: A GN build arguments template pre-configured with Thorium optimizations (ThinLTO, V8 engine performance tuning, disabled debug checks, and ARM NEON support).
*   **`thorium_ios_build_guide.md`**: A detailed, step-by-step compilation and installation guide (in Vietnamese).
*   **`thorium/`**: (Ignored by Git) A reference directory created dynamically by the setup script, containing patches and configurations from the original Thorium project.

---

## ⚡ Quick Start Guide (Perform on a Mac)

### 1. Prerequisites
Ensure your Mac has **Xcode** and **Xcode Command Line Tools** installed:
```bash
xcode-select --install
```

### 2. Run the Setup Script
Execute the script to clone the required toolchains, fetch the Chromium source code, and copy the Thorium optimization files:
```bash
./setup_ios.sh
```
> *Note: Fetching the Chromium iOS codebase (~100-120 GB) is very large and may take several hours depending on your network connection.*

### 3. Compile the Browser
Navigate to the Chromium source directory and build the browser using `autoninja`:
```bash
cd chromium/src
export PATH="$(pwd)/../../depot_tools:$PATH"
autoninja -C out/Release-iphoneos chrome
```

### 4. Sideload onto iPhone / iPad
Once the compilation is complete, the iOS app bundle will be located at `out/Release-iphoneos/chrome.app`. You can install it using one of these methods:
*   **Method 1 (Xcode - Recommended):** Open the generated workspace in Xcode, select your connected iPhone, configure your signing credentials, and click **Run** (resigned every 7 days for free accounts).
*   **Method 2 (AltStore / Sideloadly):** Package the bundle into a `.ipa` file and sideload it. AltStore supports automatic background renewals over local Wi-Fi.
*   **Method 3 (TrollStore):** If your iPhone runs iOS 16.6.1 or lower (or supported iOS 17.0 versions), you can install the `.ipa` permanently without ever revoking.

---

*For detailed compilation analytics, hardware optimization explanations, and step-by-step sideloading guides, please read **[thorium_ios_build_guide.md](./thorium_ios_build_guide.md)**.*
