# Design & Development of Voice-Assisted Autonomous Shutter using FDM and IoT

**Detailed Phase-by-Phase Development Plan**

| Field | Detail |
|---|---|
| Project | Voice-Assisted Autonomous Shutter using FDM & IoT |
| Students | Joy Kiruban J (712523114302), Mahaprabu P (712523114303) |
| Guide | Dr. S. Balakrishnan, M.E., Ph.D., HoD – Mechanical Engineering |
| Institution | PPG Institute of Technology |
| Duration | 8 weeks (prototype + validation) |

> **Update (rev 2):** The shutter must also be controllable from a **mobile app in a remote
> location** (not just the local Wi-Fi network). This makes internet-facing connectivity, a
> backend, authentication, and a cross-platform app first-class deliverables. See
> **Section 0.1 – Remote Control Architecture** and the expanded **Phase 5**.

---

## 0. How to Use This Plan

This plan converts the 8-week timeline in the review deck into **7 execution phases** with clear
**gates**. Each phase lists: objective, tasks, deliverables, verification (how you prove it works),
and the risks to close before moving on.

**Rule:** do not start a phase until the previous phase's *Gate* is passed. If a gate fails, fix it
inside the phase — do not carry debt forward.

```
Phase 1  Requirements & Design Freeze        (Week 1–2)
Phase 2  Engineering Calculations & CAD       (Week 2–4)
Phase 3  FDM Fabrication & Trial/Error        (Week 4–6)
Phase 4  Electrical & Firmware Core           (Week 5–7)
Phase 5  Voice, IoT Backend & Mobile App      (Week 6–8)
Phase 6  Assembly & System Testing            (Week 7–8)
Phase 7  Validation, Documentation & Demo     (Week 8)
```

---

## 0.1 Remote Control Architecture (mobile app from anywhere)

**Goal:** Control the shutter and see its live state from a phone on a *different network* (e.g.,
from college while the shutter sits at home), over the internet.

### Architecture options

| Option | How it works | Pros | Cons | Verdict |
|---|---|---|---|---|
| **A. MQTT over TLS to a cloud broker** (HiveMQ Cloud / EMQX Cloud) | ESP32 ↔ broker (TLS 8883) ↔ Flutter app (MQTT/WSS) | Lightweight, bidirectional, low latency, free tiers, works remotely | App needs broker creds; push notifications need extra | **Recommended** |
| **B. Firebase Realtime DB / Firestore** | ESP32 → HTTPS REST ↔ Firebase ↔ Flutter (Firebase SDK) | Built-in auth + **push notifications**, easy real-time sync | Vendor lock-in; device auth keys must be protected | Strong alternative (best if push needed) |
| **C. Custom REST + WebSocket backend** (FastAPI/Node on VPS) | ESP32 ↔ API ↔ app | Full control, REST history | Most work to build/host/secure | Stretch only |

**Recommended stack:** **MQTT over TLS (HiveMQ Cloud free tier)** for control/telemetry +
**Flutter** app. Add **Firebase Cloud Messaging (FCM)** later for push alerts (obstruction/fault).

### Data flow (remote)

```
 [ Mobile App ]                         [ Cloud Broker ]                      [ Shutter Unit ]
   Flutter (MQTT/WSS)  ──publish cmd──►  HiveMQ Cloud  ──deliver──►  ESP32 (MQTT/TLS) ─► motor
        ▲                                (TLS, auth)                              │
        └──────subscribe state/telemetry◄────────publish state────────────────────┘
```

### Topic namespace (one per device)

```
shutter/<deviceId>/cmd        (app → device)   "open" | "close" | "stop"
shutter/<deviceId>/state      (device → app)   OPEN | CLOSED | OPENING | CLOSING | FAULT
shutter/<deviceId>/position   (device → app)   0–100 (%)
shutter/<deviceId>/telemetry  (device → app)   {rssi, current, uptime, last_seen}
shutter/<deviceId>/event      (device → app)   {"type":"obstruction"|"boot"|...}
```

### Security must-haves (do not skip)

- **TLS everywhere** (MQTT over TLS 8883 or WSS 443) — never plain MQTT on the public internet.
- **Per-device credentials** + **unique topic namespace** — one compromised device can't touch others.
- **App user authentication** (Firebase Auth or backend login) so only you control your shutter.
- **No secrets in the repo** — broker passwords / API keys in `secrets.h` and app config, both git-ignored.
- **Command hardening** — per-device ACL on the broker, optional token/HMAC in the payload, rate limiting.
- **Last Will & Testament (LWT)** — broker marks device `offline` if it drops; app shows connectivity.
- **Do not expose raw GPIO/HTTP** directly on the internet.

> **Local fallback:** if the internet/broker is down, local Wi-Fi control (button + LAN MQTT/web)
> must still work. The app should show an explicit "offline / unreachable" state rather than hang.

---

## Phase 1 — Requirements, Scope & Design Freeze (Week 1–2)

**Objective:** Remove ambiguity before any CAD or printing. Every undefined item in the review
deck must become a concrete decision.

### Tasks
1. **Numbered requirements table** (functional + non-functional). Minimum set:
   - FR-1: Open shutter via voice command.
   - FR-2: Close shutter via voice command.
   - FR-3: Stop/pause at any time (voice + hardware).
   - FR-4: Remote control + status over Wi-Fi (IoT).
   - FR-5: Automatic stop at fully-open / fully-closed via limit switches.
   - FR-6: Manual push-button override (OPEN / CLOSE / STOP).
   - **FR-7: Control open/close/stop from a mobile app running on a remote network (internet).**
   - **FR-8: Mobile app displays live shutter state (open/closed/moving/fault) and device online/offline.**
   - **FR-9: Only authenticated users can issue commands; unauthenticated commands are rejected.**
   - **FR-10: Mobile app raises an alert/notification on obstruction or fault events.**
   - NFR-1: Full travel time ≤ 10 s (prototype target).
   - NFR-2: Command recognition accuracy ≥ 90%.
   - NFR-3: Safe on obstruction (stop within ≤ 0.5 s).
   - NFR-4: Runs on 12 V, ≤ 3 A.
   - **NFR-5: Remote command round-trip (app → shutter action start) ≤ 2 s on a normal connection.**
   - **NFR-6: All remote traffic encrypted (TLS); no plaintext control over the internet.**
   - **NFR-7: Mobile app works on Android (iOS optional) — define minimum OS versions.**
2. **Voice-stack decision (critical).** Choose ONE and document why:

   | Option | Pros | Cons | Verdict |
   |---|---|---|---|
   | A. Offline wake word + commands on **ESP32-S3** (ESP-SR / WakeNet + MultiNet) | Private, demo-safe (no internet), impressive | Requires board swap from WROOM-32 | **Recommended if offline required** |
   | B. Cloud ASR via phone/PC app → HTTP/MQTT to ESP32 | Easy, accurate, uses existing WROOM-32 | Needs internet + a phone/PC in the loop | Best fallback |
   | C. Alexa/Google bridge (e.g., Sinric/Home Assistant) | Nice UX | Heavy setup, account dependency | Stretch goal only |

   > The current deck's "voice interfaced software" is the weakest spec — **freeze this now.**
   > If offline is non-negotiable, budget for an **ESP32-S3** (WROOM-32 RAM is too tight for
   > reliable offline ASR).

3. **Remote control stack decision (critical).** Choose the backend + app framework (see Section 0.1):

   | Decision | Options | Recommended |
   |---|---|---|
   | Remote transport | MQTT-over-TLS (HiveMQ/EMQX) · Firebase · custom REST/WS | **MQTT over TLS** |
   | App framework | **Flutter** · React Native · Android native (Kotlin) · MIT App Inventor | **Flutter** |
   | Auth | Firebase Auth · custom backend login · device token only | Firebase Auth or backend login |
   | Push alerts | Firebase Cloud Messaging · none (in-app only) | FCM as Stretch |

   > **Freeze the app framework and broker here** — the app, firmware topics, and security model
   > all depend on it. Prefer a stack you can demonstrate live without an emulator.

4. **Scope cut line.** Mark features as **Core**, **Should**, **Stretch**:
   - Core: open/close/stop, limit switches, Wi-Fi status, voice command, **remote app control +
     live state over the internet, authenticated access**.
   - Should: manual buttons, in-app alerts on fault, command history.
   - Stretch: push notifications (FCM), Alexa, scheduling/automation, current sensing, user accounts
     with multiple devices.
5. **Obstacle-safety policy:** define what "safe stop" means (see Phase 4).
6. **Remote-security policy:** TLS-only, per-device creds, topic ACL, secrets never committed.

### Deliverables
- `docs/requirements.md` — numbered FR/NFR table.
- `docs/decisions.md` — voice stack, remote stack (broker + app framework), board choice, scope tiers.
- `docs/remote_architecture.md` — data flow, topics, security model (from Section 0.1).

### Gate 1
- [ ] Voice stack chosen and board finalized.
- [ ] Remote stack chosen (broker + app framework + auth) and board finalized.
- [ ] All requirements numbered and testable (incl. FR-7…FR-10).
- [ ] Guide sign-off on scope (Core vs Stretch).

---

## Phase 2 — Engineering Calculations & CAD (Week 2–4)

**Objective:** Size the drivetrain from physics (not guesswork) and produce manufacturable CAD.

### 2.1 Torque & Motor Sizing (must appear in Review 2)
Derive required motor torque for winding the shutter:

```
W            = m · g                         (shutter weight → N)
T_load       = W · r_eff                     (r_eff = effective roll radius)
T_friction   = T_load · k_f                  (k_f ≈ 0.2–0.3 friction/inefficiency)
T_required   = (T_load + T_friction) · SF    (SF ≈ 2 safety factor)
```

Worked example to replace with **your measured values**:

```
m = 2 kg           → W = 2 × 9.81 = 19.6 N
r_eff = 15 mm      → T_load = 19.6 × 0.015 = 0.294 N·m
k_f = 0.25         → T_friction ≈ 0.074 N·m
SF = 2             → T_required ≈ 0.74 N·m  (≈ 7.5 kg·cm)
```

Then check speed and power:

```
ω = 2πN/60            (N = motor RPM)
P = T_required · ω    (verify < motor rated power)
```

**Deliverable:** a one-slide torque/rpm/power calculation with the final motor + gear ratio,
plus required RPM back-calculated from travel time:
`N = (linear speed) / (roll circumference)`.

### 2.2 Component BOM & Selection
- Confirm motor torque/RPM against Phase 2.1 result.
- **Motor driver:** re-evaluate L298N (max ~2 A/ch, large voltage drop). If stall current
  approaches the limit, switch to **TB6612FNG** (cleaner, lower drop) or add a fuse + current sense.
- Shaft/roller, bearings/bushings, gears/pulleys, guide rails, mounting frame.

### 2.3 CAD Modelling
- Full assembly: shaft, slats, rails, frame, motor mount, gear/pulley train, limit-switch mounts.
- Parametric so print tolerance fixes are cheap.
- Draft angles / clearances for FDM (`≈ 0.2–0.3 mm` clearance on mating fits).
- Generate STLs for each printed part; note print orientation (layer lines carry load).

### 2.4 FDM Material Decision
- **PETG** for load-bearing/heat-exposed parts (lower creep, better toughness than PLA).
- **CF-PLA** (per literature ref #3) for parts needing stiffness — but note it's abrasive to nozzles.
- PLA only for non-structural covers/brackets.
- Document layer height, walls, infill (structural parts ≥ 40% infill, ≥ 4 walls).

### Deliverables
- `docs/calculations.md` (torque, RPM, power, travel time).
- CAD assembly + individual STLs.
- `docs/BOM.md` with selected parts and justification.

### Gate 2
- [ ] Torque calc shows chosen motor has ≥ 2× margin.
- [ ] All printed parts modelled and print-oriented.
- [ ] Material per part justified (PETG/CF-PLA/PLA).

---

## Phase 3 — FDM Fabrication & Trial/Error (Week 4–6)

**Objective:** Print, fit, iterate. Expect multiple print cycles — failure is part of the method.

### Tasks
1. Slicing: layer height 0.2 mm (0.16 fine on fits), walls 4, infill 40–60% structural.
2. Print in order: mounting frame → rails → shaft/roller → gears/pulleys → slats → brackets.
3. **First-article inspection** per part: dimensional check against CAD (calipers), fit test.
4. Address the already-noted issue from the deck: **brim supports** for warp-prone parts;
   document each failure mode and fix (warping, elephant foot, layer delamination).
5. Mechanical sub-assembly: shaft spins freely in bearings; gears mesh without binding;
   limit switches trigger at correct travel extremes.
6. Record a **print log** (date, part, settings, result, reprint count).

### Deliverables
- Printed part set + assemblies.
- `docs/print_log.md` (trial-and-error table with before/after photos).
- Photos: drafting, printing, failed print, corrected print.

### Gate 3
- [ ] Shaft rotates freely by hand through full travel.
- [ ] Gears/pulleys transmit smoothly with no binding.
- [ ] Limit switches actuate at both extremes.
- [ ] At least one documented failure→fix cycle (this is a deliverable, not a mistake).

---

## Phase 4 — Electrical Wiring & Firmware Core (Week 5–7)

**Objective:** Make the shutter move reliably under local control **before** adding voice/IoT.

### 4.1 Wiring
- 12 V supply → motor driver → motor; buck 12 V→5 V → ESP32.
- Limit switches (NO/NC) → ESP32 GPIO with pull-ups; define active logic.
- Push buttons OPEN/CLOSE/STOP → ESP32 (debounced in firmware).
- Common ground across ESP32, driver, supply.

### 4.2 Firmware state machine
```
IDLE ──cmd OPEN──► OPENING ──openLimit──► OPEN
            │                     │
            ├──cmd STOP───────────┤
            ▼                     ▼
         STOPPED ◄──────────── CLOSING ──cmd CLOSE──┐
                                        └──closeLimit──► CLOSED
```
- Direction control via H-bridge pins; PWM for soft start/stop (reduces inrush).
- Limit switches force transition to end state and cut motor drive.
- Debounce buttons and limit inputs (10–20 ms).
- Non-blocking loop (`millis()`-based), no `delay()` in the control path.

### 4.3 Safety features
- **Stall/overcurrent protection:** sense motor current (INA219 / ACS712 / shunt) or
  time-limit each travel; on stall → stop + report fault.
- **Obstruction handling:** if current spikes mid-travel → stop/reverse (per FR/safety policy).
- **Power-loss behavior:** define safe default (e.g., hold position; no auto-move on boot).
- **Watchdog timer** enabled to recover from firmware hang.

### Deliverables
- Wiring diagram (Fritzing/KiCad) + breadboard → soldered/perfboard version.
- `firmware/main/` — state machine, drivers, safety, serial debug/telemetry.

### Gate 4
- [ ] Shutter performs full open→stop→close→stop via push buttons.
- [ ] Limit switches stop travel at both ends every time.
- [ ] Stall/overcurrent test triggers safe stop.
- [ ] Non-blocking loop verified (Serial heartbeat stays steady during motion).

---

## Phase 5 — Voice, IoT Backend & Mobile App (Week 6–8)

**Objective:** Add the headline features — voice, **internet-based remote control**, and a
**mobile app** — on top of a proven local system. Extend this phase into Week 8 to absorb app
development.

### 5.1 Voice (per Phase 1 decision)
- **If ESP32-S3 offline:** flash ESP-SR; configure wake word + command set
  (`open`, `close`, `stop`). Tune mic gain and test at 0.5 m / 2 m / with background noise.
- **If cloud path:** ESP32 exposes an HTTP/MQTT command endpoint; phone/PC ASR posts commands.
- Define a single command layer so voice, buttons, IoT, and the app all call the **same** functions —
  never duplicate motion logic.

### 5.2 Backend & remote connectivity (internet-facing)
- Set up the chosen broker/backend from Phase 1 (recommended: **HiveMQ Cloud, MQTT over TLS**).
- Firmware: connect ESP32 to the broker over **TLS (8883)** using Wi-Fi credentials + per-device creds.
- **Publish** real state (from limit switches, not assumptions) + telemetry:
  `state`, `position`, `telemetry`, `event`.
- **Subscribe** to `shutter/<deviceId>/cmd` and route to the shared command layer.
- **Last Will & Testament (LWT):** publish `offline` if the device drops; app reflects connectivity.
- Periodic telemetry heartbeat (e.g., every 30 s) so the app shows `last_seen`.
- Optional OTA firmware updates.
- **Local fallback:** keep LAN/button control working if the broker is unreachable.

### 5.3 Mobile app (Flutter recommended)
- **Screens / features:**
  - Connection/login screen (auth).
  - Main screen: device list (or single device), **live state** (OPEN/CLOSED/OPENING/CLOSING/FAULT),
    position %, **online/offline** badge, connectivity to broker.
  - Controls: **Open / Stop / Close** buttons (disabled when offline or when command not allowed).
  - Event/alerts view (obstruction, boot, faults) + optional push (FCM).
  - Settings: device ID, broker/server config, notifications toggle.
- **Networking:** MQTT over TLS/WSS (`mqtt_client` package) — subscribe to `state`/`telemetry`,
  publish to `cmd`. Handle reconnect and show explicit offline state.
- **Security:** authenticate the user (Firebase Auth or backend login); do not ship broker
  passwords in plaintext form beyond the device-scoped credential; store tokens securely.
- **UX for remote use:** optimistic "command sent → awaiting state" indicator that resolves when the
  real state arrives (avoids lying to the user).
- **Build/distribution:** Android APK for the demo (sideload); note iOS needs Apple tooling.

### 5.4 End-to-end wiring of the three input paths
```
voice ─┐
button ┼─► single command layer ─► state machine ─► motor
app ───┘            ▲                                   │
                    └────────── state/telemetry ◄────────┘
```

### Deliverables
- Voice command set working (accuracy measured).
- Broker/backend configured with TLS + per-device credentials; topics documented in `docs/iot.md`.
- **Mobile app** (source in `app/`) — signed demo APK + screenshots.
- `docs/mobile_app.md` — screens, MQTT topics used, auth model, setup steps.

### Gate 5
- [ ] ≥ 90% voice recognition on the defined command set (log 20 trials).
- [ ] Remote open/close/stop works from a **different network** with correct state feedback.
- [ ] App shows live state and online/offline correctly; reconnects after network drop.
- [ ] Unauthenticated commands are rejected (FR-9).
- [ ] All input paths (voice/button/app) share one control layer.
- [ ] Command rejected gracefully on obstruction/fault.

---

## Phase 6 — Final Assembly & System Testing (Week 7–8)

**Objective:** Integrate everything into one unit and test as a system, not as parts.

### Tasks
1. Final mechanical + electrical assembly; cable management; mount controller enclosure.
2. **Test matrix** (record pass/fail + evidence):

   | # | Test | Criterion |
   |---|---|---|
   | T1 | Voice open/close/stop | ≥ 90% success, 20 trials |
   | T2 | Local buttons | 100% functional |
   | T3 | IoT control + state sync | State matches physical within 1 s |
   | T4 | Limit switch stop | 100% at both ends |
   | T5 | Obstruction safety | Stops ≤ 0.5 s, no damage |
   | T6 | Travel time | ≤ 10 s full travel |
   | T7 | Continuous cycling (e.g., 100 cycles) | No binding, no overheat, no drift |
   | T8 | Power-loss / reboot | Safe state, no unintended motion |
   | **T9** | **Remote app control from a different network** (e.g., mobile data) | Open/close/stop + live state within 2 s |
   | **T10** | **App offline/reconnect behavior** | Shows offline; auto-recovers on reconnect |
   | **T11** | **Auth: unauthenticated command rejected** | Broker/app rejects, no motion |
   | **T12** | **Concurrent commands (app + voice)** | Deterministic, no conflicting motion |

3. Measure motor current during normal + stall; confirm within driver limits.
4. Thermal check on motor driver and motor after sustained cycling.
5. Fix and re-test any failures; log modifications.

### Deliverables
- Integrated working prototype.
- `docs/test_results.md` — filled test matrix with measurements + photo/video evidence.

### Gate 6
- [ ] All T1–T12 pass or have documented acceptable deviation.
- [ ] 100-cycle endurance run completed without mechanical failure.
- [ ] Safety tests (T5, T8) pass.
- [ ] Remote tests (T9–T11) pass from an off-network connection.

---

## Phase 7 — Validation, Documentation & Final Presentation (Week 8)

**Objective:** Convert the prototype into a defensible engineering outcome and a strong demo.

### Tasks
1. Consolidate: requirements → design calc → CAD → fabrication → firmware → test results
   (traceability: each requirement maps to a test).
2. Performance evaluation vs objectives; state limitations honestly (as future work).
3. **Final report** structure: Abstract, Lit Review, Methodology, Design & Calc, Fabrication,
   Electronics/Firmware, **Remote Backend & Mobile App**, IoT/Voice, Results & Discussion,
   Conclusion & Future Scope.
4. Final presentation deck: fix the four weak slides identified in review 1:
   - Replace the vague "voice interfaced software" cell with the chosen stack.
   - Add a torque/rpm/power calculation slide.
   - Replace the placeholder IoT flow chart (slide 13) with a real architecture block diagram
     (device ↔ cloud broker ↔ mobile app).
   - Add a results slide (test matrix summary + metrics).
   - **Add an app screenshots slide + the remote data-flow diagram.**
5. **Live demo script** (with offline fallback if internet fails):
   - Voice open → voice stop → **operate from the app on the phone** → obstruction safety →
     show live state and event alert on the app.
6. Prepare a 1–2 min demo video as backup if live demo fails.

### Deliverables
- Final report, final PPT, demo video, repository of CAD/firmware/docs.

### Gate 7 (Project Complete)
- [ ] Report + PPT submitted.
- [ ] Live demo rehearsed with fallback.
- [ ] Every requirement traced to a test result.

---

## Cross-Cutting Risks & Mitigations

| Risk | Impact | Mitigation |
|---|---|---|
| Offline ASR won't fit WROOM-32 | Blocks voice feature | Decide in Phase 1; use ESP32-S3 or cloud fallback |
| Motor under-torqued / stalls | Can't move shutter | Phase 2 torque calc with 2× margin; current-sense stall cutoff |
| PLA creep/heat deformation | Long-term failure | PETG for structural parts |
| L298N current/thermal limits | Driver damage | Re-evaluate vs stall current; add fuse/current sense; consider TB6612FNG |
| Print warping / fit errors | Time loss | Brim supports (already found), parametric CAD, print log |
| Scope creep (Alexa, scheduling) | Miss core deadline | Core/Should/Stretch tiers; freeze in Phase 1 |
| IoT/voice desync | Wrong state shown | Publish real limit-switch state, single control layer |
| Demo internet failure | Bad presentation | Offline voice option + LAN fallback + recorded video backup |
| **Remote security breach** (broker creds leak, open topics) | Unauthorized control of shutter | TLS-only, per-device creds, topic ACL, secrets git-ignored, auth in app |
| **Broker/cloud outage or blocked network** | Remote control unavailable | LWT/offline state in app; keep LAN + button fallback |
| **App build/distribution friction** (iOS tooling, signing) | Can't demo app | Target Android APK for demo; distribute APK directly |
| **App/firmware topic mismatch** | Commands silently ignored | Freeze topic contract in Phase 1; document in `docs/mobile_app.md`; integration test (T9) |

---

## Repository Layout (suggested)

```
autonomousShutter/
├─ DEVELOPMENT_PLAN.md
├─ docs/
│  ├─ requirements.md      # Phase 1
│  ├─ decisions.md         # Phase 1
│  ├─ remote_architecture.md  # Phase 1 (Section 0.1)
│  ├─ calculations.md      # Phase 2
│  ├─ BOM.md               # Phase 2
│  ├─ print_log.md         # Phase 3
│  ├─ iot.md               # Phase 5 (broker + topics)
│  ├─ mobile_app.md        # Phase 5 (screens, auth, setup)
│  └─ test_results.md      # Phase 6
├─ cad/                    # assemblies + STLs
├─ firmware/main/          # ESP32 state machine, voice, MQTT/TLS, safety
│  └─ secrets.h            # git-ignored (Wi-Fi + broker creds)
├─ app/                    # Flutter mobile app
└─ hardware/               # wiring diagrams, pin map
```

## Immediate Next Actions
1. Hold the Phase 1 voice-stack decision (ESP32-S3 offline vs cloud) — biggest fork in the plan.
2. Hold the Phase 1 **remote stack decision** (broker + app framework) — see Section 0.1.
3. Build the numbered requirements table (now incl. FR-7…FR-10) and get guide sign-off.
4. Run the torque calculation with your real shutter weight and roll radius.
5. Register a free **HiveMQ Cloud** (or EMQX) instance and confirm ESP32 TLS MQTT connectivity
   early — this de-risks the whole remote-control feature.
