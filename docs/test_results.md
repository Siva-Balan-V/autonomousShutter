# Test Results

> Fill after Phase 6. Each row needs **evidence** (photo/video/log). A requirement without a
> passing (or documented-deviation) test is not complete.

## System test matrix

| # | Test | Criterion | Result | Measured | Evidence | Notes |
|---|---|---|---|---|---|---|
| T1 | Voice open/close/stop | ≥ 90% success, 20 trials | ☐ Pass ☐ Fail | __/20 | | |
| T2 | Local buttons | 100% functional | ☐ Pass ☐ Fail | | | |
| T3 | IoT control + state sync | state matches within 1 s | ☐ Pass ☐ Fail | ___ ms | | |
| T4 | Limit switch stop | 100% at both ends | ☐ Pass ☐ Fail | | | |
| T5 | Obstruction safety | stops ≤ 0.5 s, no damage | ☐ Pass ☐ Fail | ___ ms | | |
| T6 | Travel time | ≤ 10 s full travel | ☐ Pass ☐ Fail | ___ s | | |
| T7 | Cycling (100×) | no binding/overheat/drift | ☐ Pass ☐ Fail | | | |
| T8 | Power-loss / reboot | safe state, no unintended motion | ☐ Pass ☐ Fail | | | |
| T9 | Remote app control, different network | open/close/stop + state ≤ 2 s | ☐ Pass ☐ Fail | ___ ms | | |
| T10 | App offline / reconnect | shows offline; auto-recovers | ☐ Pass ☐ Fail | | | |
| T11 | Auth: unauthenticated cmd rejected | broker/app reject, no motion | ☐ Pass ☐ Fail | | | |
| T12 | Concurrent commands (app + voice) | deterministic, no conflict | ☐ Pass ☐ Fail | | | |

## Measurements to record
- Normal motor current: ____ mA · Stall current: ____ mA · Driver rating: ____ A
- Motor / driver temperature after 100 cycles: ____ °C
- Voice trials log (command, distance, noise, correct?): attach in `evidence/`.

## Deviations / known issues
| Test | Deviation | Accepted? | Justification |
|---|---|---|---|
| | | | |

## Conclusion
- Requirements passed: ___ / ___
- Outstanding issues → future work: ______________________________
