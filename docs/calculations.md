# Engineering Calculations

> Fill with **measured** values before Phase 2 gate. Show units.

## 1. Motor torque sizing

| Symbol | Meaning | Value | Unit |
|---|---|---|---|
| m | shutter mass | | kg |
| g | gravity | 9.81 | m/s² |
| W | weight = m·g | | N |
| r_eff | effective roll radius | | m |
| k_f | friction/inefficiency factor | 0.25 | – |
| SF | safety factor | 2 | – |

```
T_load     = W · r_eff
T_friction = T_load · k_f
T_required = (T_load + T_friction) · SF
```

**T_required = ________ N·m  (________ kg·cm)**

## 2. Speed & travel time

| Symbol | Meaning | Value | Unit |
|---|---|---|---|
| linear speed | shutter travel speed | | m/s |
| circumference | 2π·r_eff | | m |
| N | motor RPM = linear speed / circumference | | rpm |
| ω | 2πN/60 | | rad/s |

**Travel time = travel distance / linear speed = ________ s** (`≤ 10 s` NFR-1)

## 3. Power check

**P = T_required · ω = ________ W**  (must be < motor rated power)

## 4. Gearing / pulley ratio
- Motor RPM: ____ · Target shaft RPM: ____ · Ratio: ____
- Output torque after gearing: ____ N·m (must be ≥ T_required with margin)

## 5. Motor selection result
- Chosen motor: ____________________ (rated torque ____ N·m, rated RPM ____)
- Margin: T_motor / T_required = ____  (target ≥ 2×)
