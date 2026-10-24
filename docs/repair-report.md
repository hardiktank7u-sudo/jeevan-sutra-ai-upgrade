# Jeevan Sutra stability repairs

Work is isolated on `repair/jeevan-sutra-stability`, based on original commit
`f31f455cc5e7ace41f37b267c44e2a4d16cc54b5`. The original branch remains unchanged.
No deployment or merge was performed.

## Environment and configuration

- Flutter **3.47.2**, framework revision `d3b14c876900e553bc736ca19295fc09e3853e8e`.
- Dart **3.13.2**; Node **24.19.0** for the existing functions scaffold.
- Installed Flutter from its official Git repository at the pinned revision after
  the release-manifest endpoint returned HTTP 404. SDK downloads retain TLS
  verification. Dependencies were restored using `flutter pub get
  --enforce-lockfile` and `npm ci`; dependency declarations and lockfiles are unchanged.
- Recovered genuine Firebase web metadata from this project's public Hosting
  initialization endpoint. Its legacy response omits `appId`, so the web app ID
  recorded in `firebase.json` was used after validating the project and sender ID.
  Generated `lib/firebase_options.dart` stays ignored and uncommitted. No invented
  production credentials or service-account keys were used.
- Chromium's trust store was refreshed with the environment-provided public proxy
  CA. Browser validation retained TLS verification.
- Reusable installation/startup instructions are saved in the environment draft.
  Saving a draft does not publish it or deploy the application.

## Confirmed problems repaired

| Area | Cause and repair |
| --- | --- |
| Health Profile | Persisted quiz values were absent from dropdown items, triggering an assertion. All quiz values and existing saved values remain selectable. |
| Profile and Settings exceptions | Flutter 3.47 rejects ListTiles whose background/ink is hidden by decorated ancestors. Transparent Material now provides the correct paint layer while preserving card appearance. |
| Profile persistence | Results from callback-free assessment entry points were not saved; retained profile tabs and drawer data became stale. Results now persist and refresh on activation/return. |
| Navigation | Drawer selection remained on a pushed route after Back. Selection now returns to the active tab; asynchronous callbacks guard the route they dismiss. |
| Hidden animations | The inactive scanner's repeating ticker continued running in the IndexedStack. Inactive tab tickers now pause without discarding state. |
| Black backgrounds | Transparent page Scaffolds and translucent botanical artwork could expose the empty navigator canvas. Pages and artwork now paint the existing theme canvas. Botanical artwork, layouts, gradients, and features remain. |
| Plant detail | Corrected two malformed UTF-8 bullet bytes and fixed dark surfaces/text contrast using the active theme. |
| AI conversation | History roles did not match the keys produced by the screen. User/model roles now remain correct, including stored history. |
| Chat reset and lifecycle | Late stream chunks could write into cleared messages. Reset/disposal cancel obsolete responses; ordered storage writes recover from failures. |
| AI request failures | Added bounded waits and useful error categories without displaying raw backend diagnostics. The original model remains configurable through `FIREBASE_AI_MODEL`. |
| Plant scanner | Uploaded images were always labeled JPEG. Actual image formats are detected, structured JSON is validated, and confidence values are normalized. Empty names no longer match the first local herb. |
| Scanner races | A delayed sample scan could overwrite a real upload. Request generations and timer cancellation prevent stale results; failed local history saving no longer prevents analysis. |

## Validation

| Check | Result |
| --- | --- |
| `flutter analyze --no-pub` | Passed: no issues. |
| `flutter test --no-pub --concurrency=2 --reporter expanded` | Passed: **30 tests**, including 29 new regression cases. No skipped or disabled tests. |
| `flutter build web --debug --no-pub --no-web-resources-cdn` | Passed. |
| `flutter build web --no-pub --no-web-resources-cdn --output=build/web-release` | Passed: release compilation. |
| Backend dependencies | Locked install and Firebase/Admin/GenAI module loading passed. The functions entry exports no active functions. |
| Chromium, real application startup | Firebase initialization and splash-to-Home passed; no JavaScript or Flutter framework exceptions in the final functional run. |
| Chromium, navigation and themes | Profile, Explore, drawer, Diet route/back, theme toggle, dark Profile, and scanner sample flow passed. |
| Live AI chat and PNG upload | Both reached Firebase App Check and received **403 PERMISSION_DENIED: App attestation failed**. Both displayed the verification error without crashing. Live generated answers/plant identifications are not verified. |

The first regression run exposed the ListTile assertions and a test-harness
stream-close wait; both were corrected before the complete passing run. No
compilation errors or analyzer findings remain in the final checks.

## Manual configuration still required

1. **Debug AI and scanner access:** in Firebase Console for `jeevan-b390e`, open
   **App Check → Apps → the web app → Manage debug tokens** and register the debug
   token from the browser that will run the application. Debug tokens belong to
   that browser/storage profile. Do not paste tokens into chat or commit them.
   App Check remains enabled. Retry both chat and a real plant photo after enrollment.
2. **Model/project access:** App Check currently prevents validation of the model
   and downstream AI access. Verify that Firebase AI Logic is enabled, API-key
   restrictions permit the intended web origin, and the configured model is
   available to this project. The existing default is `gemini-3.8-flash`; select a
   project-supported model with `--dart-define=FIREBASE_AI_MODEL=<model>` if needed.
   No unsupported default replacement was guessed.
3. **Release web startup:** supply the genuine reCAPTCHA v3 site key through
   `--dart-define=APP_CHECK_RECAPTCHA_V3_SITE_KEY=<site-key>`. Release compilation
   succeeds without it, but `main()` intentionally throws before startup when
   the key is missing. Configure the correct web origin in Firebase/reCAPTCHA.
4. **Native platforms:** authentic native Firebase files and Android/iOS
   toolchains are still required for native builds. Only the web configuration
   was generated here. Hardware camera and native notifications were not tested.

No successful live AI generation, plant-identification accuracy, deployment,
merge, publication, or restoration in a new cloud task is claimed.
