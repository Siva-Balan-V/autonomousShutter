# Remote Control Architecture

> Status: **Draft** · See plan Section 0.1.

## Data flow

```
 [ Mobile App ]                    [ Cloud Broker ]                 [ Shutter Unit ]
  Flutter (MQTT/WSS) ──publish──►  HiveMQ Cloud  ──deliver──►  ESP32 (MQTT/TLS) ─► motor
        ▲                          (TLS, auth, ACL)                    │
        └──── subscribe state/telemetry ◄──── publish state ──────────┘
```

## MQTT topic contract  (freeze before coding)

Namespaces use one `deviceId` per shutter unit.

| Topic | Direction | Payload | QoS |
|---|---|---|---|
| `shutter/<deviceId>/cmd` | app → device | `"open"` \| `"close"` \| `"stop"` | 1 |
| `shutter/<deviceId>/state` | device → app | `OPEN` \| `CLOSED` \| `OPENING` \| `CLOSING` \| `STOPPED` \| `FAULT` | 1 |
| `shutter/<deviceId>/position` | device → app | `0..100` (int, %) | 0 |
| `shutter/<deviceId>/telemetry` | device → app | see JSON below | 0 |
| `shutter/<deviceId>/event` | device → app | see JSON below | 1 |
| `shutter/<deviceId>/status` | device → app (LWT) | `"online"` \| `"offline"` | 1 |

### Telemetry JSON
```json
{ "rssi": -63, "current_mA": 480, "uptime_s": 12345, "state": "OPEN", "last_seen": 1712345678 }
```

### Event JSON
```json
{ "type": "obstruction", "ts": 1712345678, "detail": "current spike, stopped" }
```
Event types: `obstruction` | `boot` | `limit_open` | `limit_close` | `fault` | `reconnect`.

## Security model (must-have)

- [ ] TLS only (MQTT 8883 or WSS 443). No plaintext MQTT on the internet.
- [ ] Per-device credentials; unique `deviceId`.
- [ ] Broker ACL: device can publish only its own `state/position/telemetry/event/status`,
      and subscribe only to its own `cmd`.
- [ ] App users authenticate (Firebase Auth or backend login) before publishing `cmd`.
- [ ] Secrets (`secrets.h`, app config) git-ignored; rotate if leaked.
- [ ] Optional: token/HMAC in command payload + broker rate limiting.
- [ ] LWT configured so app sees `offline` when device drops.

## Provisioning (how a device is onboarded)
1. Generate `deviceId` (e.g., MAC-based).
2. Create broker credential + ACL for that ID.
3. Flash `secrets.h` (Wi-Fi SSID/pass, broker host/port, user/pass).
4. Verify device publishes `status=online` and `state`.

## Verification checklist
- [ ] Works from a different network (mobile data) → T9.
- [ ] App shows offline when device loses power → T10.
- [ ] Unauthenticated `cmd` is rejected → T11.
