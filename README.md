# MindMap Youth

Privacy-first teen mental health navigator for Washington State (Congressional App Challenge, WA-08).
No account, no tracking, nothing leaves the phone.

## What's in this build (MVP tier)

- **Crisis Hub**: one-tap call/text to 988 and other lines, reachable from the "Need help now?" bar on every screen.
- **Quick Exit**: the Exit button (or optional triple-tap) swaps the app for a working calculator and clears the navigation stack. Press and hold the calculator display to come back.
- **Find Help**: bundled resource list with filters, county picker, optional on-device distance sort, and an OpenStreetMap view.
- **Check-in** and **Thought record** (six steps), with a history list.
- **PIN lock**: 4 digits, locks when the app is backgrounded, 30-second lockout after 5 wrong tries.
- **Erase everything** in Settings.

## Run it

```bash
flutter pub get
flutter test
flutter run            # debug, includes sample listings
flutter build apk --release
```

Screenshots are blocked on Android (`FLAG_SECURE`), so record demos from a second device or temporarily comment the flag out in `MainActivity.kt`.

## Layout

```
lib/
  app/        app.dart (Exit, crisis bar, lock and cover overlays), router, theme, state (Riverpod)
  core/       secure_key_store, pin_hasher (PBKDF2), launch (tel:/sms:/maps)
  data/       app_database (SQLCipher), resource_repository (bundled JSON)
  domain/     pure Dart: risk_signal_detector, resource_ranker (haversine), resource
  features/   crisis_hub, locator, mood, onboarding, lock, exit, settings, home
assets/wa_resources.json
test/         domain and widget tests
```

## Privacy design

- Entries live in a SQLCipher-encrypted SQLite file; the key is generated on first run and kept in the Keystore/Keychain.
- The PIN is stored only as a salted PBKDF2-HMAC-SHA256 hash.
- No analytics, crash reporting, or ads. Android permissions: `INTERNET` (map tiles and links the user taps) and approximate location (optional, used in memory only).
- `allowBackup=false`; `FLAG_SECURE` blanks the app-switcher preview; a cover is also drawn whenever the app is inactive.
- Risk-signal prompts are computed on the spot and never stored. The app cannot monitor users or notify anyone, by design.

## Differences from the blueprint

- Storage uses `sqflite_sqlcipher` with hand-written SQL instead of drift (same schema, no code generation).
- Not built yet: shake-to-exit, biometric unlock, disguise icons, "open now" filter (hours are free text), offline map tiles, insights charts, coping toolbox, safety plan, counselor export.
- iOS has not been compiled (this machine has no Xcode).

## Before shipping

- Verify every crisis number and hours in `lib/features/crisis_hub/crisis_lines.dart` and `assets/wa_resources.json`, then fill in `verified_on`.
- Replace the `"sample": true` placeholder listings with real, verified ones. Samples are hidden in release builds.
- Set `reportEmail` in `resource_detail_screen.dart` to enable "Report a problem".
- Have a counselor review the crisis and support wording.
- Set up release signing (the release build currently uses the debug key).
