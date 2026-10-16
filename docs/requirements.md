# Requirements — Voice-Assisted Autonomous Shutter (FDM + IoT + Remote App)

> Status: **Draft** · Owner: (Joy / Mahaprabu) · Last updated: (date)
> Rule: every requirement must be **testable** and **traced to a test** in `test_results.md`.

## Functional Requirements

| ID | Requirement | Priority | Test | Status |
|---|---|---|---|---|
| FR-1 | Open shutter via voice command | Core | T1 | ☐ |
| FR-2 | Close shutter via voice command | Core | T1 | ☐ |
| FR-3 | Stop/pause at any time (voice + hardware) | Core | T1, T2 | ☐ |
| FR-4 | Local IoT status over Wi-Fi | Core | T3 | ☐ |
| FR-5 | Auto-stop at fully-open / fully-closed via limit switches | Core | T4 | ☐ |
| FR-6 | Manual push-button override (OPEN / CLOSE / STOP) | Should | T2 | ☐ |
| FR-7 | Control open/close/stop from the mobile app over the internet | Core | T9 | ☐ |
| FR-8 | App shows live state (open/closed/moving/fault) + online/offline | Core | T3, T9, T10 | ☐ |
| FR-9 | Only authenticated users may command; unauthenticated rejected | Core | T11 | ☐ |
| FR-10 | App raises an alert/notification on obstruction or fault | Should | T5, T9 | ☐ |

## Non-Functional Requirements

| ID | Requirement | Target | Test | Status |
|---|---|---|---|---|
| NFR-1 | Full travel time | ≤ 10 s | T6 | ☐ |
| NFR-2 | Voice recognition accuracy | ≥ 90% (20 trials) | T1 | ☐ |
| NFR-3 | Safe on obstruction | stop ≤ 0.5 s | T5 | ☐ |
| NFR-4 | Electrical supply | 12 V, ≤ 3 A | T7 | ☐ |
| NFR-5 | Remote command round-trip (app → action start) | ≤ 2 s | T9 | ☐ |
| NFR-6 | Remote traffic encryption | TLS-only, no plaintext | inspect/audit | ☐ |
| NFR-7 | Mobile app platform | Android (min OS: ____); iOS optional | manual | ☐ |

## Out of Scope (this revision)
- Multi-user roles, scheduling/automation, Alexa/Google — tracked as Stretch in the plan.

## Sign-off
- Guide approval: ____________  Date: ________
