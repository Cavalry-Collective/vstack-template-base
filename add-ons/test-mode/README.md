# Add-on: test mode

Test mode lets the complete application run without contacting real external providers. Use it for side effects that cannot be exercised freely, such as SMS, email, payments, push notifications, and third-party APIs.

It replaces external side effects. It does not skip application flows or replace an environment-level integration flag.

## Requirements

- Resolve test mode once at the request boundary from a trusted signal. Treat a missing, invalid, or unknown signal as production.
- Pass the resolved mode inward as request context. Do not infer it from a hostname or build flag, or keep it in global state.
- Run the same business flow in both modes. Replace only the adapter that performs the external side effect.
- Make values needed by a tester available through the test sink. For example, log an OTP code or return a fixed test value.
- Do not branch domain logic on test mode.
- When test and production records coexist, select the adapter from the record being acted on rather than the caller's session.
- Gate every test-only endpoint and UI control on the resolved mode. Return no test data when the mode is absent or invalid.
- Never let test mode bypass verification, authorisation, or payment rules.
- Exclude test records from production lists, reports, dashboards, and analytics by default.

### Test-user picker

Provide a one-action login picker when testers need to exercise several roles.

- Show it only on the login screen in test mode.
- Read accounts from a test-mode-gated endpoint that returns an empty result in production.
- Back it with realistic named seed accounts that remain stable across runs.

## Verify

Test that production cannot reach test-only endpoints or UI. Test that test mode executes the normal business flow through the sink and that production surfaces exclude test records.

## Binds to a stack

The active stack pack identifies:

- the mode signal and where it is resolved;
- the sink for each integration;
- the test-user endpoint, gate, and seed mechanism.

## Interactions

- **otp-auth:** expose a knowable code through the delivery sink while retaining normal issue and verify logic.
- **Base integration flag:** keep the default-off environment flag. It controls whether the real integration is enabled; test mode selects the adapter for a request or record.
- **Base configuration:** validate test-mode settings and credentials through the normal configuration path.
