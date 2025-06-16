# MyCap Active Task WebView Integration

This project enables seamless integration of custom web‑based Active Tasks into the MyCap app using a ZIP‑packed website and an embedded WebView. It provides:

* **StartScreen**: Pick or download a ZIP archive containing your task’s static website.
* **WebViewScreen**: Extracts and displays the `index.html` from the ZIP, sets up a JavaScript bridge to receive JSON data via `window.flutter_inappwebview.callHandler('returnData', ...)`.
* **ResultsScreen**: Presents received data—rendering images, flagging large text, and expanding nested structures.

This repository is framework‑agnostic: you do not need Flutter installed to understand how your web task should be built and packaged.

---

## Purpose

MyCap allows researchers to embed custom Active Tasks—interactive, offline‑capable web apps—into their study apps. When the user completes an activity on the webpage, your code calls:

```js
window.flutter_inappwebview.callHandler('returnData', JSON.stringify({ /* structured payload */ }));
```

The host app intercepts this handler, parses the JSON, and navigates to a native results display.

---

## Reading Parameters in Your JS

Your Flutter host injects two objects into the page after load:

1. **URL Parameters** via `window.searchParams`:

   ```js
   // Already injected by host
   const urlParams = window.searchParams || new URLSearchParams(window.location.search);
   console.log(Object.fromEntries(urlParams.entries()));
   ```

2. **Flutter Map** via `window.flutterQueryParams`:

   ```js
   // Injected JSON from Dart side
   const injected = window.flutterQueryParams || {};
   console.log(injected);
   ```

Merge them into your config:

```js
const config = {
  identifier: injected.identifier || urlParams.get('identifier') || 'defaultIdentifier',
  lengthOfTest: parseInt(injected.length_of_test)
                || parseInt(urlParams.get('length_of_test'))
                || 3,
  intendedUseDescription: injected.intendedUseDescription
                        || urlParams.get('intendedUseDescription')
                        || 'Welcome to the Custom Active Task Demo.'
};
```

---

## Building Your Custom Active Task Website

1. **No External Network Calls**

    * Bundle all scripts, styles, fonts, and media. No CDNs.

2. **Entry Point**

    * Include an `index.html` (root or subfolder). The app finds the first one (ignoring `__MACOSX`).

3. **JavaScript Data Return**

   ```js
   function submitText(text) {
     const payload = JSON.stringify({ text });
     window.flutter_inappwebview.callHandler('returnData', payload);
   }
   ```

4. **File Uploads & Media**

   ```js
   canvas.toBlob(blob => {
     const reader = new FileReader();
     reader.onloadend = () => {
       const payload = JSON.stringify({ image: reader.result });
       window.flutter_inappwebview.callHandler('returnData', payload);
     };
     reader.readAsDataURL(blob);
   }, 'image/png');
   ```

5. **Offline Capability**

    * All assets load from relative paths inside the ZIP.

6. **Error Handling**

   ```js
   const payload = JSON.stringify({ error: true, message: '...'});
   window.flutter_inappwebview.callHandler('returnData', payload);
   ```

---

## Usage (App Integration)

1. **Select or Download ZIP** → copy into app docs.
2. **Extract & Locate** → unzip and find `index.html`.
3. **WebView Load** with file:// URL and file-access permissions.
4. **Inject Parameters** via `evaluateJavascript` (handled in host).
5. **Receive Data** in your Dart `addJavaScriptHandler('returnData', ...)`.
6. **Display Results** natively.

---

## Directory Overview

```
lib/
├─ StartScreen     # ZIP selection or download
├─ WebViewScreen   # Extraction, WebView load, JS↔native bridge
└─ ResultsScreen   # Native rendering of returned JSON data
```

---

## Reserved Keywords

* `__MACOSX` — ignore.
* `index.html` — entry point.
* `returnData` — JS channel name.
* `file://` — protocol for local assets.
* `data:` — Base64 data URIs.
* `logs` — captured console messages.
* `error` — boolean flag in payload.

---

## FAQ

**How is my task installed?**
Host unzips and loads offline.

**Why local?**
Offline support and performance.

**What can I send back?**
Any JSON‑serializable structure; Base64 for binaries.

**Languages Supported**

| Code    | Native Name    | English Name   |
| ------- | -------------- | -------------- |
| en      | English        | English        |
| bn      | বাংলা          | Bengali        |
| pt      | Português      | Portuguese     |
| fr      | Français       | French         |
| de      | Deutsch        | German         |
| ht      | Kreyòl Ayisyen | Haitian Creole |
| hi      | हिन्दी         | Hindi          |
| it      | Italiano       | Italian        |
| ja      | 日本語            | Japanese       |
| ko      | 한국어            | Korean         |
| pa      | ਪੰਜਾਬੀ         | Punjabi        |
| zh      | 中文             | Chinese        |
| es      | Español        | Spanish        |
| ar      | العربية        | Arabic         |
| fil     | Tagalog        | Filipino       |
| uk      | Українська     | Ukrainian      |
| ur      | اردو           | Urdu           |
| vi      | Tiếng Việt     | Vietnamese     |
| default | English        | English        |

---

## Flutter Setup (Optional)

1. Install Flutter SDK (Windows/macOS).
2. Configure Android (SDK, licenses) or iOS (Xcode, CocoaPods).
3. Clone repo and run:

   ```bash
   flutter pub get
   cd ios && pod install && cd ..
   flutter run
   ```

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

This app was tested successfully on:
 - Flutter 3.32.2
 - Xcode 16.2
---

With this setup, you can craft rich, interactive tasks in any web framework and integrate them seamlessly into MyCap. We have included a sample ZIP file in the `assets` directory to demonstrate the expected structure and functionality, feel free to study this working example in order to build your own custom Active Tasks.
