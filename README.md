# MyCap Active Task WebView Integration

This project enables seamless integration of custom web‑based Active Tasks into the MyCap app using a ZIP‑packed website and an embedded WebView. It provides:

* **StartScreen**: Pick or download a ZIP archive containing your task’s static website.
* **WebViewScreen**: Extracts and displays the `index.html` from the ZIP, sets up a JavaScript channel to receive JSON data via `window.returnData.postMessage(...)`.
* **ResultsScreen**: Presents received data—rendering images, flagging large text, and expanding nested structures.

This repository is framework‑agnostic: you do not need Flutter installed to understand how your web task should be built and packaged.

---

## Purpose

MyCap allows researchers to embed custom Active Tasks—interactive, offline‑capable web apps—into their study apps. When the user completes an activity on the webpage, your code calls:

```js
window.returnData.postMessage(JSON.stringify({ /* structured payload */ }));
```

The host app intercepts this message, parses it, and navigates to a native results display.

---

## Building Your Custom Active Task Website

Your task is delivered as a ZIP archive containing all static assets. Follow these guidelines:

1. **No External Network Calls**

    * Bundle all scripts, styles, fonts, and media into your archive. Do not reference CDN or external resources.

2. **Entry Point**

    * Include an `index.html` at the root or a subfolder. The app will locate the first `index.html` found (excluding any `__MACOSX` directories).

3. **JavaScript Data Return**

    * Use the provided JavaScript channel `returnData`:

      ```js
      // Example: submitting simple text data
      function submitText(text) {
        const payload = JSON.stringify({ text });
        if (window.returnData && window.returnData.postMessage) {
          window.returnData.postMessage(payload);
        }
      }
      ```

4. **File Uploads & Media**

    * To return images, audio, or other binary data, encode as Base64:

      ```js
      // Example: capturing canvas image
      canvas.toBlob(blob => {
        const reader = new FileReader();
        reader.onloadend = () => {
          const payload = JSON.stringify({
            image: reader.result // data:image/png;base64,...
          });
          window.returnData.postMessage(payload);
        };
        reader.readAsDataURL(blob);
      }, 'image/png');
      ```

5. **Offline Capability**

    * All assets must load from relative paths inside the ZIP. No network dependency ensures tasks work offline once downloaded.

6. **Error Handling**

    * Gracefully show error messages in the UI if `returnData` is unavailable or payload JSON is invalid.

---

## Usage (App Integration)

Although this sample uses Flutter, the concepts apply to any native container that:

1. Unpacks a ZIP into a local folder.
2. Loads `index.html` in a WebView with file‑URL permissions.
3. Listens on a JS channel named `returnData`.
4. Parses the JSON string and drives native navigation or data handling.

### Typical Flow

1. **Download or Select ZIP**: Your app copies the `.zip` into its documents directory (e.g., `appDocDir/test.zip`).
2. **Extract & Locate**: Unzip into a folder (e.g., `appDocDir/website_test/`) and search for `index.html`.
3. **WebView Load**: Point the WebView at `file://.../index.html` and enable file access:

   ```java
   webview.getSettings().setAllowFileAccessFromFileURLs(true);
   webview.getSettings().setAllowUniversalAccessFromFileURLs(true);
   ```
4. **JavaScript Hook**: Ensure that:

   ```js
   window.returnData.postMessage(dataString);
   ```

   invokes the native callback.
5. **Receive Data**: On the native side, decode `dataString` into a JSON object/map.
6. **Display Results**: Render key/value pairs natively, with images, expandable JSON, and indicators for large text.

---

## Directory Overview

```
lib/ (or analogous in your platform)
├─ StartScreen     # ZIP selection or download
├─ WebViewScreen   # Extraction, WebView load, JS↔native bridge
└─ ResultsScreen   # Native rendering of returned JSON data
```

---

## FAQ

* **How is my task installed?**
  The host app downloads or accepts your ZIP, unpacks it locally, and loads it offline from the file system.

* **Why must everything be local?**
  To support offline use and avoid network delays. Any missing asset will break your task.

* **What formats can I send back?**
  Any JSON‑serializable structure. Base64 strings for binary data. Nested objects or arrays are supported.

* **Can I include large files?**
  Yes—your ZIP can contain large media—but remember mobile storage and memory limits. The native results screen flags oversized strings.

---

## How to Install and Run with Flutter

If you want to build and test the host integration using Flutter, follow these steps for Windows and macOS. This assumes you have administrator or sudo privileges.

### Prerequisites

* Git installed on your machine.
* An IDE such as VS Code, Android Studio, or IntelliJ with Flutter plugins.
* For Android: Android SDK, Android Studio, and an Android device/emulator.
* For iOS (macOS only): Xcode and an iOS device/simulator.

### 1. Install Flutter SDK

#### Windows

1. Download the Flutter SDK ZIP from [https://docs.flutter.dev/get-started/install/windows](https://docs.flutter.dev/get-started/install/windows).
2. Extract the ZIP to `C:\src\flutter` (avoid paths with spaces).
3. Add `C:\src\flutter\bin` to your PATH environment variable.
4. Run in PowerShell:

   ```powershell
   flutter doctor
   ```

#### macOS

1. Download the Flutter SDK ZIP from [https://docs.flutter.dev/get-started/install/macos](https://docs.flutter.dev/get-started/install/macos).
2. Extract the ZIP:

   ```bash
   cd ~/Downloads
   unzip flutter_macos_*.zip
   mv flutter ~/flutter
   ```
3. Add to your PATH in `~/.zshrc` or `~/.bash_profile`:

   ```bash
   export PATH="$PATH:$HOME/flutter/bin"
   ```
4. Run:

   ```bash
   flutter doctor
   ```

Resolve any issues reported by `flutter doctor` (missing dependencies, license agreements, etc.).

### 2. Android Setup

1. In Android Studio, open SDK Manager: install SDK Platform (latest stable), Android SDK Tools, and Android Emulator.
2. Accept all licenses:

   ```bash
   flutter doctor --android-licenses
   ```
3. Start an emulator or connect a physical device.

### 3. iOS Setup (macOS only)

1. Open Xcode and install any additional components if prompted.
2. In a terminal, run:

   ```bash
   sudo gem install cocoapods
   flutter doctor
   ```
3. If using a simulator, start it from Xcode → Devices & Simulators.

### 4. Clone & Run the Sample App

```bash
# Clone the repo
git clone git@github.com:vanderbilt-redcap/mycap-at-test.git
cd mycap-at-test

# Get dependencies
flutter pub get

# For iOS (macOS only)
cd ios
pod install
cd ..

# Run on Android emulator or device\ flutter run -d chrome     # for webview testing in browser
flutter run              # default device
# Or run on iOS simulator (macOS only)
flutter run -d ios
```

Your Flutter app will launch, showing the StartScreen. From there, you can select or download a ZIP and test your Active Task integration end‑to‑end.

---

With this setup, you can craft rich, interactive tasks in any web framework and integrate them seamlessly into MyCap or any similar native host. We have included a sample ZIP file in the `assets` directory to demonstrate the expected structure and functionality.
