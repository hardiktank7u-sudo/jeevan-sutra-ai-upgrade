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

## Firebase App Check for Web

Chrome debug builds use Firebase App Check's web debug provider. Register the
debug token printed in the browser console in Firebase Console under
**App Check → Apps → Manage debug tokens** when App Check enforcement is enabled.

Production web builds require a reCAPTCHA v3 site key; supply it at build time
instead of committing it to source:

```bash
flutter build web --dart-define=APP_CHECK_RECAPTCHA_V3_SITE_KEY=<site-key>
```

Android continues to use the debug provider in debug builds and Play Integrity
in release builds. Production App Check is not disabled.
