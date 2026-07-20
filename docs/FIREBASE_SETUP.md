# Firebase setup (e-mail + Google sign-in)

F1 Vision runs perfectly **without** Firebase — you'll just see
"Sign-in is not configured" under Settings → Account, and no login screen.
Follow this guide to switch authentication on.

## 1. Create the Firebase project

1. Go to <https://console.firebase.google.com> → **Add project** (any name,
   e.g. `f1-vision`). Google Analytics is optional.
2. In **Build → Authentication → Sign-in method**, enable:
   - **Email/Password**
   - **Google** (pick a support e-mail when prompted)

## 2. Connect the Flutter app (FlutterFire CLI — recommended)

```bash
# one-time installs
npm install -g firebase-tools        # or: curl -sL https://firebase.tools | bash
firebase login
dart pub global activate flutterfire_cli

# from the project root (after `flutter create .` has generated the platform folders)
flutterfire configure
```

Pick your Firebase project and the platforms you build for. The CLI drops the
right config into each platform **and** generates `lib/firebase_options.dart`.

> `lib/firebase_options.dart`, `google-services.json` and
> `GoogleService-Info.plist` are in `.gitignore` on purpose — they identify
> *your* Firebase project. Each contributor runs `flutterfire configure` once.

### Use the generated options in `main.dart`

`main.dart` currently calls `Firebase.initializeApp()` with no arguments,
which works on Android/iOS (native config files) but not on web/desktop.
After running the CLI, switch to the generated options:

```dart
import 'firebase_options.dart';
// …
await Firebase.initializeApp(
  options: DefaultFirebaseOptions.currentPlatform,
);
```

## 3. Google Sign-In platform extras

### Android
Google Sign-In on Android requires your app's SHA-1 fingerprint:

```bash
cd android && ./gradlew signingReport      # copy the debug SHA-1
```

Firebase console → Project settings → Your Android app → **Add fingerprint**,
then re-download `google-services.json` (or re-run `flutterfire configure`).

### iOS
Add the reversed client ID as a URL scheme: open
`ios/Runner/Info.plist` and add the `REVERSED_CLIENT_ID` value from
`GoogleService-Info.plist` under `CFBundleURLTypes`. (The google_sign_in
package README shows the exact plist snippet.)

### Web
The app already uses the Firebase popup flow on web
(`signInWithPopup`), so no extra meta tag is required — just make sure your
domain (and `localhost`) is listed under
**Authentication → Settings → Authorized domains**.

## 4. Verify

```bash
flutter run
```

You should land on the F1 Vision login screen. Create an account with e-mail,
sign out from Settings, then try **Continue with Google**.

## Troubleshooting

| Symptom | Likely fix |
|---|---|
| App skips login entirely | Firebase didn't initialise — check step 2 and the debug console for the "Firebase not configured" log line. |
| Google button does nothing on Android | Missing SHA-1 fingerprint (step 3). |
| `operation-not-allowed` error | Enable the provider in Authentication → Sign-in method. |
| Web popup closes instantly | Domain not in Authorized domains. |
