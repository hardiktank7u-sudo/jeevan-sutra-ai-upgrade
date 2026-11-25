# jeevan_sutra

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Offline botanical tools

The AI Assistant reads the 92 bundled records in
`assets/knowledge/plants.json`; its plant answers do not call Gemini and its
conversation history is stored locally. Responses distinguish recorded
traditional uses from scientific evidence and report when safety information
is missing.

The plant camera supports camera and gallery photos. No visual recognition
model is bundled, so photos use guided trait selection and catalogue matching.
Candidate scores are the fraction of selected traits mentioned in a record's
identification text—not visual similarity or identification probabilities.
Image color measurements are descriptive only.

## Firebase App Check for Web

Chrome debug builds use Firebase App Check's web debug provider. Register the
debug token printed in the browser console in Firebase Console under
**App Check → Apps → Manage debug tokens** when App Check enforcement is enabled.

Production web builds require a reCAPTCHA v3 site key; supply it at build time
instead of committing it to source. Release builds must also receive the
deployed Gemini Worker URL; it is not injected by the project build settings:

```bash
flutter build web --release --dart-define=APP_CHECK_RECAPTCHA_V3_SITE_KEY=<site-key> --dart-define=GEMINI_BACKEND_BASE_URL=https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev
```

For Android release builds, pass the Worker URL explicitly:

```bash
flutter build apk --release --dart-define=GEMINI_BACKEND_BASE_URL=https://jeevan-sutra-gemini-api.jeevan-sutra-ai.workers.dev
```

Android continues to use the debug provider in debug builds and Play Integrity
in release builds. Production App Check is not disabled.
