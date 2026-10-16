# IoT (Broker, Topics, Security)

> Status: **Draft**. Matches `remote_architecture.md`.

## Broker setup (recommended: HiveMQ Cloud)

- [ ] Create free account at https://www.hivemq.com/mqtt-cloud-broker/
- [ ] Create cluster → get **host**, **port (TLS 8883)**, **WSS port (443)**.
- [ ] Create credentials (username/password). Treat as secrets.
- [ ] Configure per-device credentials and ACL (core topic ACL).
- [ ] Set **LWT** on device: publish `shutter/<deviceId>/status` `offline` on disconnect.

## Topics (snapshot)

| Topic | Use |
|---|---|
| `shutter/<deviceId>/cmd` | control (open/close/stop) |
| `shutter/<deviceId>/state` | live state |
| `shutter/<deviceId>/position` | 0..100 % |
| `shutter/<deviceId>/telemetry` | rssi/current/uptime/state/last_seen |
| `shutter/<deviceId>/event` | alerts |
| `shutter/<deviceId>/status` | online/offline |

## Firmware notes (`secrets.h`)

**Never commit `secrets.h`.** Create locally, add to `.gitignore`.

```cpp
#define WIFI_SSID     "..."
#define WIFI_PASS     "..."
#define MQTT_HOST     "..."
#define MQTT_PORT     8883
#define MQTT_USER     "..."
#define MQTT_PASS     "..."
#define DEVICE_ID     "..."
```

## ESP32 connectivity checklist
- [ ] Connects to broker over TLS (verify CA if self-hosted; cloud uses trusted CA).
- [ ] Publishes status online + boot event.
- [ ] Subscribes to cmd for this device only.
- [ ] LWT configured and working (drops to offline) → T10.
- [ ] Publishes real state from limit switches.

## Local fallback
- [ ] LAN: keep LAN-based control working if broker unreachable.
- [ ] Buttons: still functional independent of broker.
