# Add-on: test-mode

> Optional add-on. Opt in at Day-1, activate with `scripts/activate-addons.sh` (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the concrete signal, sinks, and picker.

A first-class runtime mode that stubs external side effects so the whole app runs end to end — locally, in CI/e2e, on staging — without hitting real providers. Adopt it when the app has side effects you can't fire freely: one-time codes, SMS/email, payments, push, third-party calls. Distinct from a feature flag (which gates *whether* an integration runs) and from seed data (which supplies *content*).

## Approach

- **Select the mode per request from an inbound signal, and fail closed to production.** The client presents the signal (a header, a signed cookie, a tenant); a request with no or unknown signal is production. Never infer test mode from a hostname or build flag, and never store it where a live request can pick it up.
- **Stub the side effect, don't skip the flow.** The code path still runs — the code is still issued and verified, the order still records — only the external step (send, charge) is replaced by a sink, and any value the user would need is made knowable (fixed or logged). Don't branch business logic on the mode past that boundary, or test mode stops testing the real path.
- **Select credentials by the record being acted on, not the caller's session.** When test and live data coexist, a test-flagged record uses the stub path even under a live session, and vice-versa.
- **Every test-only affordance is gated on the mode and fails closed** — unreachable and empty/denied in production. Test mode is never a way for a real client to skip verification or payment.

## Test-user picker

A one-tap login picker of seeded accounts so a tester or e2e run signs in as any role instantly.

- Feed it from a **test-mode-gated, unauthenticated** read that returns empty in production.
- Render it only on the login screen and only under the mode signal.
- Back it with realistic, named seed accounts, stable across runs (base `db/CLAUDE.md`).

## Verify it fails closed

"Returns empty in production" and "unreachable in production" are assertions in the test suite, not hopes — a test-only endpoint that succeeds in prod is the exact failure this add-on prevents.

## Binds to a stack

The active pack names: the mode signal and where it's resolved; the sink each integration falls back to in test mode; and the picker endpoint and its gate.

## Interactions

- **otp-auth** — test mode makes OTP walkable without a live provider; adopt both together.
- **Base default-off integration flag** — related but different: the flag turns an integration off for a whole environment; test mode stubs it per-request where it's otherwise on.
- **Base configuration** — the mode signal and any test credentials are validated config.
