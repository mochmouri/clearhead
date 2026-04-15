# ClearHead

A native iOS Share Extension that detects logical fallacies in any text you share from WhatsApp, Safari, Notes, or any other app.

Select text → Share → ClearHead → get an instant reasoning score and a breakdown of every fallacy found.

## How it works

ClearHead sends the shared text to the [Gemini Flash API](https://aistudio.google.com) and displays:

- A reasoning score out of 100
- A one-sentence verdict
- Each logical fallacy (name, plain-English explanation, severity: High / Medium / Low)

The analysis runs inside a native iOS bottom sheet — you never leave the app you were using.

---

## Setup (Mac with Xcode)

**Prerequisites:** Xcode 15 or later, an iPhone or iPad running iOS 16+, and a free Gemini API key from [aistudio.google.com](https://aistudio.google.com).

### Step 1 — Clone the repo

```bash
git clone https://github.com/YOUR_USERNAME/clearhead.git
cd clearhead
open ClearHead.xcodeproj
```

### Step 2 — Set your Apple ID team

In Xcode, select the `ClearHead` project in the navigator. For **both** targets (`ClearHead` and `ShareExtension`):

1. Click the target name
2. Go to **Signing & Capabilities**
3. Under **Team**, choose your personal Apple ID (or your organisation's team)

Xcode will automatically provision the App Group (`group.com.clearhead.shared`) when you sign in.

### Step 3 — Add your Gemini API key

1. Plug in your iPhone and select it as the run destination
2. Press **Run** (⌘R) to build and install
3. Open the **ClearHead** app on your iPhone
4. Paste your Gemini API key into the field at the top and tap away to save

### Step 4 — Trust the developer certificate

On your iPhone, go to **Settings → General → VPN & Device Management**, find your Apple ID under Developer App, and tap **Trust**.

You only need to do this once when sideloading with a free developer account.

---

## Using the extension

1. In any app (WhatsApp, Safari, Notes…), select or copy the text you want to analyse
2. Tap **Share** (or **Forward** in WhatsApp)
3. Scroll across the share sheet and tap **ClearHead**
4. The panel slides up and analyses the text in a few seconds
5. Tap **Done** to dismiss

Past analyses are saved in the ClearHead app under **Recent Analyses**.

---

## Architecture

```
ClearHead/          Main app — SwiftUI settings screen + history
ShareExtension/     Share Extension — UIKit bottom sheet
Shared/             Code shared between both targets
  GeminiService.swift   Gemini API call (async/await, 10s timeout)
  Models.swift          FallacyAnalysis, Fallacy, AnalysisRecord
```

Both targets share a UserDefaults App Group (`group.com.clearhead.shared`) for the API key and analysis history.

## Privacy

Your API key and analysis history are stored on-device only. Text is sent directly from your device to the Gemini API — no intermediate server.
