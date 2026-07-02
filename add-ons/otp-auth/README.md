# Add-on: otp-auth

> Optional add-on. Opt in at Day-1 by keeping this directory (see `add-ons/README.md`). Agnostic approach; the active stack pack supplies the concrete store/provider, SDK, and canonicalisation.

One-time-code auth: a user proves control of a phone or email by entering a code sent to it. Use for passwordless login, signup verification, and adding/changing a contact method.

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
- **A knowable test code.** Gate a knowable code behind **test mode** (a logged real code, or a fixed code valid *only* in test mode) so the flow is walkable without a live provider. The verify path still runs — only delivery is stubbed.
- **Log every send and verify** with `{purpose, masked target, test-mode, provider status, correlation id}` — never the code or full contact.
- **Rate-limit send and verify** (per target, per challenge); answer `429` with a retry hint.
- **Surface delivery failures** — "provider accepted" is not "user received". Classify transient (resend) vs permanent (terminal error); never swallow a failed send.
- **Offer an admin-issued fallback** — a per-account, hashed, short-lived, revocable code behind its own flag — for users who genuinely can't receive one.
- **Select credentials by the record's mode, not the caller's session;** live credentials never fall back to a test default.

## Binds to a stack

The active pack names: model A or B and the concrete store/provider; the hashing + TTL utilities; the phone-canonicalisation library; the rate-limit store; and how the test-mode code is produced.

## Interactions

- **test-mode** — required to stay walkable without a live provider; adopt both.
- **Base default-off integration flag** — the real sender ships behind it, routed to a no-op sink until configured per environment.
- **Base security-baseline + audit-trail** — this instantiates them (hashing, ownership, idempotency; record sensitive auth events).
