# Multi-factor authentication — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Give every user a second authentication factor: TOTP (RFC 6238) now, WebAuthn/passkeys next, with hashed one-time recovery codes. Each organisation sets its own enforcement policy. A reusable step-up verification mechanism lets other compliance areas demand a fresh factor before sensitive actions.

## Scope & ownership

- **Owns:** factor enrollment and challenges, recovery codes, trusted devices, the MFA org-policy keys (table below), admin MFA reset, and the **step-up contract** — a fresh challenge marks the session verified for 10 minutes; guarded endpoints otherwise return `403 STEP_UP_REQUIRED`. Any spec that marks a route step-up-guarded (e.g. `export-bulk-controls.md`) references this contract rather than redefining it.
- **Consumes:** field-level encryption for TOTP seeds (`encryption.md`); the shared approval flow for guarded resets (`maker-checker.md`); the SSO callback's normalised MFA/AMR claim (`sso-identity.md` owns claim extraction, this spec owns the trust decision).
- **Phases:** P1 = TOTP, recovery codes, policy, lockout, step-up, admin reset (S1–S6). P2 = trusted devices, WebAuthn, IdP-claim trust (S7–S9).

## User stories & acceptance criteria

**S1 (P1)** — As a user, I want to enroll a TOTP authenticator and be challenged at login, so that my account isn't compromised by a stolen password.
- [ ] Enrollment activates only with a valid code; the secret is never readable after issuance. *Verify: contract tests on POST `…/totp/enrollments` + verification (valid code → active, invalid → `400 MFA_ENROLLMENT_CODE_INVALID`); assert GET factors omits the seed.*
- [ ] Login becomes two-phase for the enrolled user; a valid code yields a session, an invalid one doesn't. *Verify: integration test — login returns `401 MFA_CHALLENGE_REQUIRED`, then POST `…/challenge` with valid and invalid codes; assert session cookie only on success and `auth.mfa_challenge.succeeded`/`failed` events.*
- [ ] A TOTP code cannot be replayed within its timestep. *Verify: integration test submitting the same code twice; second attempt returns `401 MFA_CODE_INVALID`.*

**S2 (P1)** — As a user, I want one-time recovery codes, so that a lost authenticator doesn't lock me out.
- [ ] First activation returns 10 codes, shown once, stored hashed. *Verify: integration test asserting response contains 10 codes, DB rows are hashes, and no later endpoint returns them.*
- [ ] A code passes the challenge once; regeneration invalidates old codes. *Verify: challenge with a code twice (`200` then `401 RECOVERY_CODE_INVALID`); regenerate, then challenge with an old unused code asserting `401`; assert `auth.recovery_code.used` and `auth.recovery_codes.generated` events.*

**S3 (P1)** — As an org admin, I want an MFA policy (off/optional/required with a grace period), so that I can enforce MFA for my organisation.
- [ ] Policy round-trips within bounds and rejects out-of-bounds values. *Verify: contract tests on PUT `…/policies/mfa` (valid, `mfa_grace_period_days: 99` → `400 MFA_POLICY_OUT_OF_BOUNDS`, missing permission → `403`); assert `auth.mfa_policy.updated` with before/after.*
- [ ] In `required` mode an unenrolled member is funneled to enrollment during grace and blocked after it. *Verify: integration test with grace anchor in the past — CRM endpoint returns `403 MFA_ENROLLMENT_REQUIRED` and emits `auth.login.denied`; enrollment endpoints still work; after enrolling, access restored.*

**S4 (P1)** — As a user, I want attempt limits on MFA, so that codes can't be brute-forced.
- [ ] 5 consecutive failures lock verification for 15 minutes with a uniform response. *Verify: integration test — 5 bad codes then a correct one returns `429 MFA_LOCKED_OUT`; assert `auth.mfa_lockout.triggered`; after the window (clock-controlled test), the correct code succeeds.*

**S5 (P1)** — As a compliance-sensitive product, I want a reusable step-up verification, so that other areas can guard sensitive actions.
- [ ] A guarded endpoint returns `403 STEP_UP_REQUIRED` until POST `/auth/step-up` succeeds, then passes for 10 minutes. *Verify: integration test on a sample guarded route — denied (assert `auth.step_up.denied`), step-up with valid code, retried call succeeds, and after expiry it is denied again.*
- [ ] A trusted-device token does not satisfy step-up. *Verify: same test with a valid device token present; step-up still demands a code.*

**S6 (P1)** — As an org admin, I want to reset a member's MFA, so that a locked-out member can re-enroll safely.
- [ ] Reset removes factors, recovery codes, and trusted devices, forces re-enrollment, requires `members:mfa_reset` and a reason, and is audited. *Verify: contract + integration tests on POST `…/members/{memberId}/mfa-reset` (missing permission → `403`, missing reason → `400`); assert rows gone, next login challenges enrollment, and `auth.mfa_reset.performed` event.*
- [ ] When org policy marks the reset approval-required it routes via maker-checker. *Verify: integration test with the approval policy on — response `202` with an approval request; reset effects absent until approved (full flow per the maker-checker spec's tests).*

**S7 (P2)** — As a user, I want to remember trusted devices, so that I'm not challenged on every login from my own machine.
- [ ] With policy > 0 days, opting in skips the next login's challenge until expiry or revocation. *Verify: integration test — challenge with `remember_device: true`, re-login without challenge, DELETE the device, re-login challenges again; assert `auth.trusted_device.registered`/`revoked` events; with policy 0, no token is offered.*

**S8 (P2)** — As a user, I want WebAuthn/passkeys, so that I have a phishing-resistant factor.
- [ ] Registration and challenge ceremonies work alongside TOTP; sign-count regression is rejected. *Verify: integration tests with a software authenticator fake via the `WebAuthnVerifier` port — register, challenge succeeds, replay with regressed sign count returns `401 MFA_CODE_INVALID` and a failure event.*

**S9 (P2)** — As an org admin using SSO, I want to trust the IdP's MFA claim, so that SSO users aren't double-challenged.
- [ ] With `mfa_trust_idp_claim` on, an SSO login carrying a verified MFA claim skips the challenge; without the claim (or with the switch off) the challenge applies. *Verify: SSO-callback integration tests (per sso-identity.md stubs) across the four claim×switch combinations, asserting challenge vs. direct session.*

## Requirements

1. A user can enroll a TOTP authenticator (RFC 6238; parameters supplied by the active stack pack's library): the server issues a secret + provisioning URI, and enrollment activates only after the user proves possession with a valid code.
2. A user can enroll WebAuthn/passkey credentials (P2), keep several, and label them; TOTP and WebAuthn factors coexist.
3. Completing first enrollment issues 10 single-use recovery codes, shown once and stored hashed with the platform password hasher; regenerating invalidates all previous codes; a recovery code satisfies any MFA challenge and is consumed on use.
4. Login for an MFA-enrolled user is two phases: primary credential → pending-MFA state (no authenticated session yet) → factor challenge → session issued.
5. Org policy is per-org data, validated against declared bounds, audited on change — never env config. Keys, defaults, and bounds: see *Policy keys & bounds* below.
6. In `required` mode, an unenrolled member may only reach the enrollment screen until enrolled; after the grace period (counted from when the policy became required or the member joined, whichever is later) all other API access returns `403 MFA_ENROLLMENT_REQUIRED`.
7. Remember-this-device: after a successful challenge the user may opt in; the server issues a revocable device token (hashed server-side, HTTP-only secure cookie client-side, scoped per organisation) valid for the org-policy duration; a valid token skips the login challenge but **never** satisfies step-up; users and the server can revoke tokens at any time.
8. Step-up verification: a reusable mechanism (shared controller guard + service check) other specs reference for sensitive actions — a fresh factor challenge marks the session step-up-verified for 10 minutes; guarded endpoints otherwise return `403 STEP_UP_REQUIRED`. Removing a factor, regenerating recovery codes, and revoking devices are themselves step-up-guarded.
9. An org admin can reset a member's MFA (removes the user's factors, recovery codes, and trusted devices, forcing re-enrollment at next login); the action is audited and maker-checker eligible — when org policy marks it approval-required it routes through the shared approval flow (maker-checker.md) instead of executing directly.
10. SSO interaction: when `mfa_trust_idp_claim` is on, an SSO login whose assertion/token carries a verified MFA/AMR claim skips our challenge; without the claim, or with the switch off, SSO users are challenged like everyone else. See sso-identity.md.
11. Challenge attempts are rate-limited: 5 consecutive failures across factors/recovery codes lock MFA verification for that user for 15 minutes (counters in the stack pack's rate-limit store). Lockout is audited and the response is uniform — identical whether the code was wrong, the factor mismatched, or the account was locked, so failures give no oracle.
12. TOTP seeds are stored field-level encrypted (see encryption.md); recovery codes and device tokens are stored hashed; enrollment secrets and recovery codes are returned exactly once and never readable again (backend write-only-secrets rule); no secret ever appears in logs, audit payloads, or API reads.
13. Enrollment, challenge outcomes (success/failure), lockout, resets, policy changes, and device-token lifecycle emit audit events per the table below.
14. Ships behind a default-off platform flag per the index; the org policy switch governs tenant-visible enforcement so the flag flip alone never changes a tenant's posture.

Policy keys & bounds (org policy store, requirement 5):

| Key | Default | Values / bounds |
|---|---|---|
| `mfa_mode` | `optional` | `off` \| `optional` \| `required` |
| `mfa_grace_period_days` | 7 | 0–30 |
| `mfa_remember_device_days` | 0 (disabled) | 0–30 |
| `mfa_trust_idp_claim` | `false` | boolean |

## User flows

### F1 — Enroll TOTP (P1)
1. User opens Account security → Two-factor authentication. 2. Requests enrollment; server creates a `pending` factor and returns the secret/provisioning URI (rendered as QR + manual code). 3. User scans and submits a current code. 4. Server verifies, activates the factor, and (on first factor) returns recovery codes shown once. 5. Audited.

### F2 — Login with challenge (P1; trusted-device skip P2)
1. User passes the primary credential (password, or SSO without a trusted MFA claim). 2. Server answers with pending-MFA (`401 MFA_CHALLENGE_REQUIRED` + challenge token). 3. User submits a TOTP/WebAuthn/recovery code, optionally "remember this device" where policy allows; a consumed recovery code prompts the user to re-enroll and regenerate codes. 4. On success: session issued, optional device token set, audit event; on failure: attempt counted toward lockout. 5. (P2) A valid device token at step 1 skips the challenge; a revoked/expired token falls back to the normal challenge with no error surfaced.

### F3 — Step-up for a sensitive action (P1)
1. User invokes a step-up-guarded endpoint (e.g. an export per export-bulk-controls.md). 2. If the session's step-up window is stale, the API returns `403 STEP_UP_REQUIRED`; the frontend opens the shared re-verification dialog. 3. User completes a factor challenge at the step-up endpoint; the session is marked verified for 10 minutes. 4. Original call is retried and proceeds.

### F4 — Admin resets a member's MFA (P1)
1. Admin opens the member's page → Reset MFA, states a reason. 2. If org policy requires approval, a maker-checker request is created and the reset executes only on approval; otherwise it executes immediately. 3. Factors, recovery codes, and trusted devices are removed in one transaction; the member re-enrolls at next login (grace rules apply). 4. Audited with reason.

### F5 — Org admin sets MFA policy (P1)
1. Admin opens Security settings → MFA policy. 2. Sets mode, grace period, remember-device duration, trust-IdP-claim. 3. Out-of-bounds values rejected; change audited with before/after.

## API & permissions

Self-service under `/internal/v1/auth/…`; org administration under `/internal/v1/organisations/{organisationId}/…`. Base envelopes apply. Challenge and step-up endpoints are rate-limited per requirement 11.

- `mfa_policy:read` — view MFA policy and members' enrollment status (enrolled yes/no + factor types, never secrets; status surfaces on the existing member list). `mfa_policy:update` — change the policy. `members:mfa_reset` — reset a member's MFA, a separate verb from `members:update`/`members:remove` per the index's destructive-verb rule; maker-checker eligible.
- Self-service enrollment/challenge/devices need no admin permission — only an authenticated (or pending-MFA) user.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| GET `/auth/mfa/factors` | List own factors | authenticated | type, label, `last_used_at`; no secrets |
| POST `/auth/mfa/totp/enrollments` | Start TOTP enrollment → `201 pending` | authenticated | `secret`, `provisioning_uri` (returned once) |
| POST `/auth/mfa/totp/enrollments/{enrollmentId}/verification` | Prove possession, activate factor | authenticated | `code`; first activation returns `recovery_codes` (once) |
| POST `/auth/mfa/webauthn/registrations` (P2) | Begin WebAuthn registration → `201` + creation options | authenticated | challenge/options per WebAuthn |
| PUT `/auth/mfa/webauthn/registrations/{registrationId}` (P2) | Complete registration with attestation response | authenticated | `label` |
| DELETE `/auth/mfa/factors/{factorId}` | Remove a factor | authenticated + step-up | 409 if last factor while org requires MFA |
| POST `/auth/mfa/recovery-codes` | Regenerate recovery codes (invalidates old) | authenticated + step-up | returns codes once |
| POST `/auth/mfa/challenge` | Complete login challenge from pending-MFA state | pending-MFA challenge token | `factor_type`, `code`/assertion, `remember_device` |
| POST `/auth/step-up` | Re-verify current session for sensitive actions | authenticated | `factor_type`, `code`/assertion → `step_up_expires_at` |
| GET `/auth/trusted-devices` | List own device tokens | authenticated | display name, `expires_at`, `last_used_at` |
| DELETE `/auth/trusted-devices/{deviceId}` | Revoke a device token | authenticated | — |
| GET `…/policies/mfa` | Read org MFA policy | `mfa_policy:read` | mode, grace, remember-device days, trust-IdP-claim |
| PUT `…/policies/mfa` | Replace org MFA policy | `mfa_policy:update` | bounds-validated; audited before/after |
| POST `…/members/{memberId}/mfa-reset` | Admin-initiated MFA reset | `members:mfa_reset` | `reason` (required); `202` + approval request when maker-checker applies, else `200` |

## Data model

Reversible migrations per `db/CLAUDE.md`; snake_case, `created_at`/`updated_at`, UTC, indexed FKs. `mfa_factors` and `mfa_recovery_codes` are **user-scoped, not org-scoped** — a stated exception to the org-scoping rule: factors attach to the user credential shared across organisations, while *enforcement* is per-org policy.

- **`mfa_factors`** — `user_id` (FK, indexed), `type` (`totp`|`webauthn`), `status` (`pending`|`active`), `label`, `totp_secret` (**field-level encrypted**, nullable), `webauthn_credential_id` (unique, nullable), `webauthn_public_key`, `webauthn_sign_count` (replay guard), `last_used_at`.
- **`mfa_recovery_codes`** — `user_id` (FK, indexed), `code_hash` (platform password hasher; plaintext never stored), `used_at` (nullable), `generation` (int — regenerating bumps it and invalidates prior rows).
- **`mfa_trusted_devices`** — `organisation_id` (indexed — duration is org policy), `user_id` (FK, indexed), `token_hash` (hashed; plaintext only in the HTTP-only cookie), `display_name` (derived from user agent), `expires_at`, `revoked_at` (nullable), `last_used_at`.
- **Org policy store (existing)** gains the validated keys in *Policy keys & bounds*, plus `mfa_required_since` recorded when mode becomes `required` (grace anchor). Pending-MFA state, step-up expiry (`step_up_verified_until`), and challenge attempt counters live in the stack pack's session and rate-limit stores — no new tables.

## Audit events

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `auth.mfa_factor.enrolled` | Factor activated | factor type, label; never the seed |
| `auth.mfa_factor.removed` | Factor removed (self or via reset) | factor type |
| `auth.mfa_challenge.succeeded` | Login challenge passed | factor type (`totp`\|`webauthn`\|`recovery_code`), remember-device chosen |
| `auth.mfa_challenge.failed` | Login challenge failed | outcome `failure`; attempt count; code never logged |
| `auth.mfa_lockout.triggered` | Threshold reached | lockout duration |
| `auth.recovery_codes.generated` | Codes (re)generated | generation number, count |
| `auth.recovery_code.used` | A code consumed at challenge | codes remaining |
| `auth.step_up.succeeded` / `auth.step_up.failed` | Step-up verification attempt | factor type, guarded action path in `context.request_path` |
| `auth.step_up.denied` | Guarded endpoint refused (`STEP_UP_REQUIRED`) | outcome `denied` |
| `auth.trusted_device.registered` / `auth.trusted_device.revoked` | Device token lifecycle | device display name; revoker (self, admin reset, expiry job → `system`) |
| `auth.mfa_policy.updated` | Org policy changed | before/after diff |
| `auth.mfa_reset.performed` | Admin reset executed (directly or post-approval) | target member, reason, approval request id when maker-checker applied |
| `auth.login.denied` | Access blocked by `MFA_ENROLLMENT_REQUIRED` after grace | denial code, outcome `denied` |

## Implementation notes

- Lives in the `auth`/`identity` module. **Domain** defines ports: `TotpVerifier` (seed generation + code check with bounded step skew), `WebAuthnVerifier` (registration + assertion ceremonies), `CodeHasher`, `AttemptLimiter`, plus factor/device/recovery-code repositories; concrete crypto/WebAuthn libraries are supplied by the active stack pack in the repo ring — never hand-rolled (root *Don't reinvent*).
- **Service ring** use cases: enroll/activate factor, complete challenge, step-up verify, regenerate recovery codes, trust/revoke device, update policy, admin reset. Each owns one transaction and emits `record()` within it; the policy-evaluation helper (mode + grace + trust-IdP-claim) is one shared domain service consumed by login, SSO callback, and the enrollment gate — not re-derived per caller.
- **Controller ring**: a shared `step-up` guard wraps sensitive routes (this spec's own, plus routes other area specs mark step-up-guarded); the pending-MFA challenge endpoint authenticates via the short-lived challenge token — pending-MFA is not an authenticated session, and the token authorises only the challenge endpoint and expires in minutes.
- **Idempotency/concurrency**: recovery-code and TOTP consumption use conditional updates (`used_at IS NULL`; a code/window accepted at most once — store the last accepted TOTP timestep on the factor to block immediate replay). Concurrent enrollment activations resolve via unique constraint on active factor per (`user_id`, `type`, credential). Admin reset is idempotent — resetting an unenrolled member is a no-op `200`. WebAuthn sign-count regression is treated as possible credential cloning: reject and audit as `auth.mfa_challenge.failed`.
- **Background jobs** (stack pack runner): purge expired/revoked device tokens and stale `pending` enrollments. SSO trust interaction: the SSO callback use case passes the normalised MFA/AMR claim into the shared policy evaluation; this spec owns the decision, the SSO spec owns claim extraction.

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Caller lacks the endpoint's permission | 403 | `PERMISSION_DENIED` |
| Primary credential OK, factor challenge outstanding | 401 | `MFA_CHALLENGE_REQUIRED` |
| Wrong/expired TOTP, replayed timestep, or bad WebAuthn assertion | 401 | `MFA_CODE_INVALID` |
| Recovery code wrong, used, or from an old generation | 401 | `RECOVERY_CODE_INVALID` |
| Challenge/step-up attempted while locked out | 429 | `MFA_LOCKED_OUT` |
| Required-mode grace expired, member unenrolled, non-enrollment API called | 403 | `MFA_ENROLLMENT_REQUIRED` |
| Step-up-guarded endpoint with a stale step-up window | 403 | `STEP_UP_REQUIRED` |
| Enrollment verification with wrong code | 400 | `MFA_ENROLLMENT_CODE_INVALID` |
| Duplicate active factor of the same credential | 409 | `MFA_ALREADY_ENROLLED` |
| Factor/device id not found or not the caller's | 404 | `MFA_FACTOR_NOT_FOUND` / `TRUSTED_DEVICE_NOT_FOUND` |
| Removing the last active factor while org mode is `required` | 409 | `LAST_FACTOR_REMOVAL_BLOCKED` |
| Policy value outside declared bounds | 400 | `MFA_POLICY_OUT_OF_BOUNDS` |
| MFA reset requiring approval (maker-checker) | 202 | not an error — approval-request envelope per maker-checker.md |

## Notes & decisions

- **OTP over email/SMS is deliberately not a factor** — a weak channel; the recommendation is TOTP/WebAuthn only. If it is ever added, delivery goes through the `otp-auth` add-on's channel, and the decision needs its own spec revision.
- **Admin MFA reset has cross-organisation blast radius** (factors are user-level). Mitigations: the separate `members:mfa_reset` permission, mandatory reason, maker-checker eligibility, and audit. A scoping restriction is an open question below.
- UX: screens are **Account security → Two-factor authentication** (enrollment QR, factor list, recovery codes, trusted devices), the **login challenge step**, the shared **step-up dialog**, **Security settings → MFA policy**, and a Reset-MFA action on the member page. All handle loading / error / empty (no factors yet) states; QR/secret and recovery codes render once with copy affordance and never re-render on refresh. Challenge verification budget < 200 ms server-side; rate-limit counters must not add a DB write per request (stack pack store).

## Out of scope

- OTP over email/SMS as an MFA factor — excluded; see Notes & decisions.
- Admin session controls beyond MFA (session lifetime, IP allowlists) — admin-security.md.
- The approval workflow mechanics — maker-checker.md.
- Field-level encryption mechanics and key rotation — encryption.md.
- Passwordless login (passkey as the *only* factor).

## Open questions

- No `design/` mockup exists yet for the new screens (Account security → Two-factor authentication, login challenge step, step-up dialog, Security settings → MFA policy, member Reset-MFA action); required before initial build.
- Should admin MFA reset be restricted to members whose email domain the org has verified (limiting the cross-org blast radius noted in Notes & decisions)? Owner: product, before S6 build.
- Is 10 minutes the right step-up window for all guarded actions, or does export need a shorter one? Owner: product, before the export spec's guarded routes ship.
