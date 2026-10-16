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
