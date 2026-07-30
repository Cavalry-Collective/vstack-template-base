# Add-on: OTP authentication

OTP authentication proves control of a phone number or email address with a one-time code. Use it for passwordless login, signup verification, and changes to a verified contact method.

## Prerequisites

Adopt `test-mode` so the full issue and verify flow can run without a live email or SMS provider.

## Choose the challenge owner

Choose one model in the requirement spec:

| Model | The app stores | Use when |
|---|---|---|
| Self-managed | hashed code, expiry, purpose, attempts | the product needs control, several channels, or provider independence |
| Provider-owned | provider challenge identifier | minimal local code matters more than provider cost and portability |

In both models, the app owns rate limits, idempotency, test behaviour, account creation, and delivery-failure handling.

## Requirements

- Use one purpose-scoped challenge flow for login, signup, and contact changes. A code must work only for the purpose that issued it.
- Support phone and email as alternative proofs, even if the first release enables only one.
- Canonicalise the destination before storage, lookup, or delivery. Use an established library for E.164 phone formatting.
- Give each code a short expiry, cap failed attempts, and consume it after the first successful verification.
- Compare self-managed codes with a timing-safe operation.
- Issue a session only after verification succeeds.
- Make send and verify idempotent. A retry must not create another account or apply a contact change twice.
- Enforce account and contact uniqueness in the database.
- Rate-limit sends by destination and verification by destination and challenge. Return `429` with a retry hint.
- Use uniform errors where a difference would disclose whether an account exists.
- Classify delivery failures as transient or permanent. Do not report provider acceptance as successful delivery.
- Log purpose, masked destination, mode, provider status, and correlation ID. Never log the code or full destination.

### Account recovery

Provide an admin-issued recovery code for users who cannot receive an OTP.

- Put recovery behind a separate default-off flag.
- Scope the code to one account and store it hashed.
- Make it short-lived, single-use, revocable, and audited.

## Verify

Test purpose scope, expiry, single use, attempt caps, retries, rate limits, and safe logging. Test that a knowable code works only in test mode and production never exposes one.

## Binds to a stack

The active stack pack identifies:

- the challenge model and store or provider;
- email and SMS delivery adapters;
- hashing, expiry, canonicalisation, and rate-limit utilities;
- the test-mode sink and knowable-code mechanism.

## Interactions

- **test-mode:** replace delivery only; keep normal issue and verify logic.
- **Base integration flag:** keep real delivery behind the default-off environment flag.
- **Base security and audit:** apply ownership, validation, safe logging, idempotency, and sensitive-auth-event auditing.
