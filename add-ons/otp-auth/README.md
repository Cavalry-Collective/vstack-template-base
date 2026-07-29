# Add-on: otp-auth

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

One-time-code auth: a user proves control of a phone or email by entering a code sent to it. Use it for passwordless login, signup verification, and adding or changing a contact method. Pick the challenge model first — it decides what you build and what you still own.

## Choose a model

| | A · self-managed | B · provider-owned |
|---|---|---|
| You store | a hashed code + short TTL + purpose | nothing — the provider owns the code |
| Choose when | you need purpose-scoping, both channels, no per-code cost | you want minimal code + no code-at-rest and accept vendor cost/lock-in |
| You still own | hashing, TTL, timing-safe verify, rate-limit, idempotency | rate-limit, idempotency, the test bypass, delivery-failure handling |

## Approach

- **One purpose-scoped flow.** Login, signup, and contact-change share a single challenge mechanism with a `purpose` discriminator; a code minted for one purpose never satisfies another. Add a purpose rather than fork a second flow.
- **Phone and email are interchangeable proofs of one account** — model both from the start even if you launch with one.
- **Canonicalise the target before storing or sending** (phone → E.164 via a library, never hand-rolled); reject unsupported regions with a clear error and store the canonical form.
- **Issue a session only after a successful verify;** from there the session is the base auth concern.

## Make it robust

- **Idempotent verify.** A retry or double-submit must never create a second account or double-consume. Put a unique constraint on the natural key (target + purpose) so the race resolves to `409`, and have the client treat `409` as "already done, proceed".
- **Codes are single-use, attempt-capped, and rate-limited.** A code is consumed on first successful verify and never verifies again. Cap failed attempts per challenge (a small fixed number), then invalidate the challenge — per-target rate limits alone don't stop brute-forcing one code. Rate-limit send and verify per target and per challenge; answer `429` with a retry hint.
- **Log every send and verify, and surface delivery failures.** Log `{purpose, masked target, test-mode, provider status, correlation id}` — never the code or full contact. "Provider accepted" is not "user received": classify transient failures (resend) vs permanent (terminal error); never swallow a failed send.
- **Offer an admin-issued fallback** — a per-account, hashed, short-lived, revocable code behind its own flag — for users who genuinely can't receive one.

## Verify

Assert in the suite: a verified code never verifies again; the attempt cap invalidates the challenge; a double-submit resolves to `409` and the client proceeds; sends and verifies past the limit answer `429`; the knowable test code verifies only under the test-mode signal.

## Binds to a stack

The active pack names: model A or B and the concrete store/provider; the hashing + TTL utilities; the phone-canonicalisation library; the rate-limit store; and how the test-mode code is produced.

## Interactions

- **test-mode** — adopt both: gate a knowable code behind the mode (a logged real code, or a fixed code valid *only* in test mode) so the flow is walkable without a live provider; the verify path still runs, only delivery is stubbed. Credentials follow the record's mode, not the caller's session (test-mode's rule); live credentials never fall back to a test default.
- **Base default-off integration flag** — the real sender ships behind it, routed to a no-op sink until configured per environment.
- **Base security-baseline + audit-trail** — this instantiates them (hashing, ownership, idempotency; record sensitive auth events).
