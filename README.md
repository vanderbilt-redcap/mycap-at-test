# MyCap Active Task WebView Integration

This project enables seamless integration of custom web‐based Active Tasks into the MyCap app using a ZIP‑packed website and an embedded WebView. It provides:

* **StartScreen**: Pick or download a ZIP archive containing your task’s static website.
* **WebViewScreen**: Extracts and displays the `index.html` from the ZIP, sets up a JavaScript channel to receive JSON data via `window.returnData.postMessage(...)`.
* **ResultsScreen**: Presents received data—rendering images, flagging large text, and expanding nested structures.

This repository is framework‑agnostic: you do not need Flutter installed to understand how your web task should be built and packaged.

---

## Purpose

MyCap allows researchers to embed custom Active Tasks—interactive, offline‐capable web apps—into their study apps. When the user completes an Activity on the webpage, your code calls:

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
2. Loads `index.html` in a WebView with file‐URL permissions.
3. Listens on a JS channel named `returnData`.
4. Parses the JSON string and drives native navigation or data handling.

### Typical Flow

1. **Download or Select ZIP**: Your app copies the `.zip` into its documents directory (e.g. `appDocDir/test.zip`).
2. **Extract & Locate**: Unzip into a folder (e.g. `appDocDir/website_test/`) and search for `index.html`.
3. **WebView Load**: Point the WebView at `file://.../index.html` and allow universal file access:

   ```
   webview.settings.allowFileAccessFromFileURLs = true;
   webview.settings.allowUniversalAccessFromFileURLs = true;
   ```
4. **JavaScript Hook**: Inject or register a handler so that:

   ```js
   window.returnData.postMessage(dataString);
   ```

   calls the native callback.
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
  To support offline use and avoid network delays.  Any missing asset will break your task.

* **What formats can I send back?**
  Any JSON‐serializable structure. Base64 strings for binary data. Nested objects or arrays are supported.

* **Can I include large files?**
  Yes—your ZIP can contain large media—but remember mobile storage and memory limits. The native results screen flags oversized strings.

---

With this setup, you can craft rich, interactive tasks in any web framework and integrate them seamlessly into MyCap or any similar native host.
