# Decision Log (ADR-style)

> One row per frozen decision. Update **Status** to `Decided` with a date and rationale.
> These decisions are inputs to firmware, app, and CAD — freeze before building.

| ID | Decision | Options | Chosen | Rationale | Status | Date |
|---|---|---|---|---|---|---|
| D-01 | MCU board | ESP32-WROOM-32 · ESP32-S3 | (pending) | offline ASR needs S3; else WROOM-32 | Open | |
| D-02 | Voice stack | offline (ESP-SR) · cloud ASR · Alexa bridge | (pending) | see plan Phase 1 | Open | |
| D-03 | Remote transport | MQTT-TLS · Firebase · custom REST/WS | **MQTT over TLS** (recommended) | lightweight, bidirectional, free tier | Open | |
| D-04 | Broker | HiveMQ Cloud · EMQX Cloud · Mosquitto VPS | HiveMQ Cloud (recommended) | free tier, managed TLS | Open | |
| D-05 | App framework | **Flutter** · React Native · Android native · App Inventor | **Flutter** (recommended) | cross-platform, great MQTT support, fast demo | Open | |
| D-06 | App auth | Firebase Auth · custom backend login · device token | (pending) | FR-9 | Open | |
| D-07 | Push alerts | FCM · in-app only | in-app now, FCM stretch | FR-10, NFR time budget | Open | |
| D-08 | Motor driver | L298N · TB6612FNG · MOSFET H-bridge | (pending) | depends on stall current | Open | |
| D-09 | Structural material | PLA · PETG · CF-PLA | PETG for structural | creep/toughness | Open | |
| D-10 | Local fallback | LAN control · buttons only | buttons + LAN | cloud outage resilience | Open | |

## Decision template (copy for new entries)

```
### D-XX — <title>
- Date:
- Context:
- Options considered:
- Decision:
- Consequences / trade-offs:
- Revisit if:
```

## Flutter vs React Native (rationale for D-05)

| Criterion | Flutter | React Native |
|---|---|---|
| MQTT/TLS support | `mqtt_client`, well-used | packages exist but more native config friction |
| Cross-platform | Android + iOS + web from one codebase | Android + iOS |
| Dev speed / demo | hot reload, strong UI toolkit | fast if team knows JS/TS |
| Background/reconnect handling | straightforward | needs extra native setup |
| Pick when | **recommended** for this project | pick if team already writes JS/TS |
