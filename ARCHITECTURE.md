# ClearHead — Architecture

## Overview
ClearHead is an iOS app that analyses text for logical fallacies using the Gemini API. Text can be submitted manually within the app or shared from any other app via the iOS Share Sheet.

---

## Project Structure

```
ClearHead/
├── ClearHead/              # Main app target
│   ├── ClearHeadApp.swift  # App entry point
│   └── ContentView.swift   # All main app UI
├── ShareExtension/         # Share Sheet extension target
│   └── ShareViewController.swift
├── Shared/                 # Code compiled into both targets
│   ├── GeminiService.swift # Gemini API client
│   └── Models.swift        # Shared data models
```

---

## Data Models (`Shared/Models.swift`)

- **`FallacyAnalysis`** — the result returned by Gemini: score (0–100), verdict, list of fallacies, and a suggestion.
- **`Fallacy`** — a single detected fallacy: name, explanation, severity (high/medium/low), and an optional verbatim quote from the original text.
- **`AnalysisRecord`** — a persisted history entry: the original text, its analysis, timestamp, and source (`"manual"` or `"shared"`).

---

## Gemini API (`Shared/GeminiService.swift`)

- Sends text to `gemini-2.5-flash` with a structured JSON prompt.
- Accepts a `source` parameter (`"manual"` or `"shared"`) that changes the suggestion instruction:
  - `"manual"` → asks Gemini how to fix or strengthen the argument.
  - `"shared"` → asks Gemini for a thoughtful reply direction.
- API key is read from `UserDefaults.standard` (keyed `"apiKey"`).
- Network timeout is 30 seconds.

---

## Main App (`ClearHead/ContentView.swift`)

Three sections:

1. **API Key** — secure text field with an explicit Save button. Stores the key in `UserDefaults.standard`.
2. **Analyse Text** — multi-line text editor for manually pasting or typing text. Tapping Analyse calls Gemini with `source: "manual"` and presents results in a sheet.
3. **Recent Analyses** — scrollable history (last 20 records), each row showing a text preview, score, date, and source tag. Tapping a row navigates to the full detail view.

**`AnalysisDetailView`** shows:
- Score and verdict
- Full original text
- Each fallacy with name, severity pill, explanation, and quoted excerpt
- A suggestion section labelled "How to Improve" (manual) or "Reply Direction" (shared)

---

## Share Extension (`ShareExtension/ShareViewController.swift`)

- Activated from the iOS Share Sheet in any app (e.g. WhatsApp, Safari).
- Extracts plain text from the shared content.
- If no API key is stored in the extension's `UserDefaults.standard`, shows an inline key entry field (see note below).
- Calls Gemini with `source: "shared"` and renders results (score, fallacies with quotes, reply direction) in a bottom sheet.
- Saves results to the extension's own history store.

---

## Storage

`UserDefaults.standard` is used for both the API key and analysis history. 

**Note:** The main app and the Share Extension run in separate sandboxes and do not share storage. This means:
- The API key must be entered separately in the extension the first time it is used.
- History recorded in the extension does not appear in the main app and vice versa.

This is a limitation of the free Apple Developer account. With a paid account ($99/year), App Groups can be re-enabled to share a single `UserDefaults` suite (`group.com.clearhead.shared`) across both targets, resolving both issues. See the four marked spots in `GeminiService.swift`, `ContentView.swift`, and `ShareViewController.swift`.
