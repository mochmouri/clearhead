# ClearHead — initial build

## What was done

Built the complete Xcode project from scratch on Windows (WSL), structured for Mac handoff.

### Targets

- **ClearHead** — SwiftUI main app. Single `ContentView` with a grouped list: SecureField for the Gemini API key (stored in App Group UserDefaults), a link to aistudio.google.com, and a history section showing the last 20 analyses with date, truncated text, and score.
- **ShareExtension** — UIKit share extension. Programmatic `UIViewController` presented as a `UISheetPresentationController` with `.medium` and `.large` detents. Extracts `public.text` from `NSExtensionItem`, calls the Gemini API, renders score + fallacy rows inline.

### Shared code

- `GeminiService.swift` — async/await, 10-second timeout, parses Gemini's wrapper JSON then decodes the inner `FallacyAnalysis` struct.
- `Models.swift` — `FallacyAnalysis`, `Fallacy`, `AnalysisRecord` (all `Codable`).

Both files compile into both targets directly (no Swift package/framework) to keep the project structure flat and dependency-free.

### Project file

Hand-written `project.pbxproj` with systematic UUIDs (prefix `A1000…`). Both targets have `CODE_SIGN_ENTITLEMENTS` wired, `INFOPLIST_FILE` set, and the App Group entitlement in both `.entitlements` files. The main app has a `PBXCopyFilesBuildPhase` (`dstSubfolderSpec = 13`) embedding the extension `.appex`.

## What was considered but rejected

- **Swift Package for shared code** — would require the Mac user to resolve the package on first open, adding a setup step. Flat file inclusion is simpler for a two-file shared surface.
- **SwiftUI for the extension** — `UISheetPresentationController` requires a `UIViewController` host in a share extension context. SwiftUI sheets work fine in apps but extensions need the UIKit presentation bridge, so UIKit was the right choice.
- **Storyboard for the extension** — programmatic layout is portable (no Xcode needed to edit) and avoids binary XML merge conflicts.
- **`NSExtensionActivationSupportsText` dict** — replaced with the SUBQUERY predicate string, which is more reliably evaluated across iOS versions and third-party apps.
