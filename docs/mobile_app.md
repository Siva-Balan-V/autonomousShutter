# Mobile App — Specification & Setup

> Framework: **Flutter** (see `decisions.md` D-05) · Status: **Draft**

## Screens

| # | Screen | Purpose | Key elements |
|---|---|---|---|
| S1 | Login / Connect | Authenticate user | email+password / token, "connect" |
| S2 | Home / Control | Operate + monitor | Open · Stop · Close buttons; live state badge; position bar; online/offline; last_seen |
| S3 | Events | History/alerts | list of `event` messages; unread badge |
| S4 | Settings | Config | deviceId, broker/server URL, notifications toggle, sign out |

## Behaviour

- Subscribe on connect to: `state`, `position`, `telemetry`, `event`, `status`.
- Publish to `cmd` on button press; disable buttons while `offline` or a command is in flight.
- **Optimistic UI:** show "command sent → awaiting state", resolve when real state arrives.
- Auto-reconnect with backoff; show explicit `offline` state (never fake success).
- Store auth token securely (secure storage, not plaintext prefs).

## MQTT integration

- Package: `mqtt_client`.
- Transport: TLS (`mqtts`) or WebSocket secure (`wss`) — match broker config.
- Client ID per installation: `app-<random>`.
- Keep-alive + clean-session settings documented here.

| Setting | Value |
|---|---|
| Broker host | (fill) |
| Port (TLS) | 8883 / (WSS) 443 |
| Username | (fill — git-ignored config) |
| Base topic | `shutter/<deviceId>/` |

## Build & run

```bash
# prerequisites: Flutter SDK, Android SDK
flutter create .            # if starting fresh
flutter pub get
flutter run                 # debug on device
flutter build apk --release # demo APK
```

> Do not commit `*.keystore`, tokens, or broker passwords. Use `--dart-define` or a
> git-ignored config for credentials.

## Status checklist
- [ ] S1–S4 implemented
- [ ] Live state + offline handling (FR-8)
- [ ] Auth enforced (FR-9)
- [ ] Alert on event (FR-10)
- [ ] Demo APK built & sideloaded

---

## Implementation Status (source scaffolded)

> Flutter SDK is required to build. The Dart source is in `app/lib/`.

### Project structure
```
app/
├─ pubspec.yaml                 # dependencies
├─ analysis_options.yaml
├─ .gitignore
├─ lib/
│  ├─ main.dart                 # app entry (Riverpod ProviderScope)
│  ├─ config/
│  │  ├─ app_config.dart        # MQTT host/topics + voice keywords
│  │  └─ secrets.dart.example   # copy to secrets.dart (git-ignored)
│  ├─ models/
│  │  └─ shutter_state.dart     # state + position + canOpen/canClose/canStop
│  ├─ services/
│  │  ├─ voice_service.dart     # speech_to_text + command parsing
│  │  └─ mqtt_service.dart      # MQTT over TLS, pub/sub, LWT
│  ├─ providers/
│  │  └─ shutter_provider.dart  # state + position-gated command logic
│  └─ screens/
│     └─ home_screen.dart       # UI: status, state, voice button, manual controls
└─ test/
   └─ shutter_state_test.dart   # unit tests for state logic
```

### Position-aware command logic (core requirement)
Voice/listening produces a command; the provider checks current state/position before
publishing to `shutter/<id>/cmd`:
- `open` → only if not moving and not already open.
- `close` → only if not moving and not already closed.
- `stop` → only if currently moving.
Otherwise the command is ignored with feedback.

### First-time setup (Flutter SDK required)
```bash
cd app
flutter create .          # generate android/ ios/ platform folders
cp lib/config/secrets.dart.example lib/config/secrets.dart
# edit secrets.dart with your HiveMQ host/user/pass/deviceId
flutter pub get
flutter run               # debug on a connected device
flutter build apk --release
```

### Android permissions (added by `flutter create`, verify present in manifest)
- `android.permission.RECORD_AUDIO` (voice)
- `android.permission.INTERNET` (MQTT)
- `android.permission.ACCESS_NETWORK_STATE`

### Remaining work
- [ ] Run `flutter create .` to generate platform scaffolding
- [ ] Copy/fill `secrets.dart`
- [ ] `flutter pub get` + resolve any package version bumps
- [ ] Test voice recognition on a real device (FR-1..FR-3, NFR-2)
- [ ] Verify MQTT TLS connect + state/position updates (FR-7, FR-8)
- [ ] Auth gate before commands (FR-9) — currently open; add Firebase/backend login
- [ ] Event alerts (FR-10)
