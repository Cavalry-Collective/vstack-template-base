# Admin security controls — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Give org admins a security-settings surface — session policy and management, password policy, IP allowlisting, API-key management, security notifications, and a per-member security view — so a tenant can enforce its own security posture as validated, audited org policy.

## Product requirements

1. An org security policy exists per organisation, stored as data (never env config), readable with `org_policy:read` and changed only with `org_policy:update`. Every change validates against declared bounds and is audited; changes are maker-checker eligible per `maker-checker.md`.
2. **Session policy**: idle timeout (bounds 5 min–24 h, default 30 min) and absolute lifetime (bounds 1 h–30 days, default 12 h). Out-of-bounds values are rejected (`400 POLICY_OUT_OF_BOUNDS`); an expired session's next request gets `401 SESSION_EXPIRED`. Interactions with SSO-driven session semantics and MFA step-up lifetimes are defined in `sso-identity.md` and `mfa.md`; where an IdP mandates a shorter lifetime, the shorter value wins.
3. **Session management**: sessions are server-side records. A member lists and revokes their own; an admin lists and revokes any member's. Revocation is server-side and immediate — the next request on a revoked session gets `401 SESSION_REVOKED`, regardless of token expiry.
4. **Password policy** (password-auth orgs only): minimum length configurable ≥ 12 (default 12, upper bound 128); candidate passwords are rejected if found in a breach corpus via a k-anonymity-style check (concrete check supplied by the active stack pack, degradable to allow-with-warning if the corpus is unreachable — never a hard login outage); **no composition rules** (no mandatory symbol/case classes). Login attempts are throttled per account + IP with a temporary lockout after repeated failures (defaults: 10 failures / 15-min lockout, bounds validated).
5. **IP allowlisting** (P2): a per-org list of CIDR entries applying to interactive sessions *and* API-key traffic. Modes: `off` (default) → `report_only` → `enforced`; an org must be able to observe report-only results before enforcing. Self-lockout guard: saving an enforced list (or switching to `enforced`) whose entries do not match the saving admin's current IP is rejected unless the request carries an explicit confirmation flag. Break-glass: an org Owner recovery path (defined with auth flows in `sso-identity.md`) bypasses the allowlist to repair it.
6. **API keys**: org-scoped, permission scopes a subset of the creator's effective permissions at creation (same rule as RBAC's `GRANT_EXCEEDS_ACTOR`), optional expiry, `last_used_at` tracking, secret shown exactly once at creation/rotation, rotation issues a new secret and retires the old after a stated overlap, revocation is immediate. The secret is stored hashed; the stored prefix is the only recoverable fragment.
7. **Security notification emails**: sent to the affected member on new-device login, password change, MFA change (enrolment/removal), and to admins on org policy change. Delivery goes through the mail port and is stubbed under the test-mode add-on; the control logic is never stubbed.
8. **Members-security view**: admins see, per member: MFA enrolled?, last login at, active session count, SSO-linked?.
9. Every denied or blocked outcome above (revoked session use, IP block, lockout) is audited, not only successes.

## User flows

**F1 — Tighten session policy (P1).** 1. Admin opens Security settings. 2. Edits idle timeout / absolute lifetime; UI shows bounds. 3. Save → backend validates bounds, applies (or routes to approval), audits. 4. Existing sessions adopt the new limits at their next request evaluation.

**F2 — Revoke a session (P1).** 1. A member (own sessions) or admin (any member, via the members-security view) lists active sessions — device/user-agent, IP, created, last seen. 2. Picks one (or "all others") and revokes. 3. Backend marks the session revoked and audits; the revoked session's next request gets `401 SESSION_REVOKED`.

**F3 — Roll out an IP allowlist (P2).** 1. Admin adds CIDR entries with labels. 2. Sets mode `report_only`; traffic proceeds while would-block events accumulate. 3. Admin reviews the report (audit-log query, `audit-logs.md`). 4. Switches to `enforced`; if the admin's own IP doesn't match, the save is rejected until re-submitted with explicit confirmation. 5. Non-matching requests now get `403 IP_NOT_ALLOWED`; lockout recovery goes through the Owner break-glass path.

**F4 — Create and rotate an API key (P2).** 1. Admin creates a key: name, scopes (UI offers only the creator's own permissions), optional expiry. 2. Secret displayed once with a copy control and a "you won't see this again" notice. 3. Later: rotate → new secret shown once, old secret valid for the overlap window, then rejected. 4. Revoke → key rejected immediately.

**F5 — Lockout after repeated failures (P2).** 1. Repeated failed logins hit the throttle. 2. Further attempts get `429 LOGIN_TEMPORARILY_LOCKED` until the lockout lapses. 3. The lockout is audited; the member gets a security notification.

## Admin capabilities

- Read the org security policy — `org_policy:read`; edit session policy, password policy, notification toggles, IP allowlist and its mode — `org_policy:update`.
- List any member's sessions and revoke them — `members:read` to view, `members:update` to revoke.
- Members-security view (req. 8) — `members:read`.
- Manage API keys — `api_keys:read` / `api_keys:create` / `api_keys:update` (rename, scopes within own set, expiry, rotation) / `api_keys:revoke`.
- Members need no extra permission for their own sessions/notifications.

## API behavior

All under `/internal/v1/organisations/{organisationId}/…`; base pagination and error envelopes apply. All operations here are synchronous small writes — nothing long-running.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| `GET …/security-policy` | Read policy | `org_policy:read` | `{ session: { idleTimeoutMinutes, absoluteLifetimeMinutes }, password: { minLength, lockout: { maxFailures, lockoutMinutes } }, ipAllowlist: { mode, entries: [{ cidr, label }] }, notifications: { … } }` |
| `PUT …/security-policy` | Replace policy (full resource) | `org_policy:update` | same shape; bounds-validated; `ipAllowlist` saves accept `confirmCurrentIpMismatch: true` (req. 5) |
| `GET …/members/me/sessions` | Own sessions | authenticated member | items: `{ id, createdAt, lastSeenAt, ip, userAgent, current }` |
| `DELETE …/members/me/sessions/{sessionId}` | Revoke own session | authenticated member | `204` |
| `GET …/members/{memberId}/sessions` | A member's sessions | `members:read` | same item shape |
| `DELETE …/members/{memberId}/sessions/{sessionId}` | Admin revoke | `members:update` | `204` |
| `GET …/members/security-overview` | Members-security view | `members:read` | items: `{ memberId, display, mfaEnrolled, lastLoginAt, activeSessionCount, ssoLinked }`; paginated |
| `GET …/api-keys` | List keys | `api_keys:read` | items: `{ id, name, keyPrefix, scopes[], expiresAt, lastUsedAt, revokedAt }` — never the secret |
| `POST …/api-keys` | Create key | `api_keys:create` | req: `{ name, scopes[], expiresAt? }`; `201` with `secret` (only response ever containing it) |
| `PUT …/api-keys/{apiKeyId}` | Update name/scopes/expiry | `api_keys:update` | scopes re-checked against the actor (req. 6) |
| `POST …/api-keys/{apiKeyId}/rotations` | Rotate secret | `api_keys:update` | `201` with new `secret` (one-time) + `overlapExpiresAt` |
| `DELETE …/api-keys/{apiKeyId}` | Revoke key | `api_keys:revoke` | `204`; immediate |

## Data model changes

New tables (snake_case; reversible up/down migrations per `db/CLAUDE.md`; all FKs indexed; every table org-scoped):

- **`org_security_policies`** — one row per org. `id` (PK); `organisation_id` (FK, unique, indexed); `session_idle_timeout_minutes`; `session_absolute_lifetime_minutes`; `password_min_length`; `login_max_failures`; `login_lockout_minutes`; `ip_allowlist_mode` (`off` | `report_only` | `enforced`); `notify_new_device` / `notify_credential_change` / `notify_policy_change` (booleans, default true); `created_at`; `updated_at`. All bounds enforced in the policy schema (validation), defaults per req. 2/4.
- **`ip_allowlist_entries`** — `id` (PK); `organisation_id` (FK, indexed); `cidr` (validated CIDR text); `label`; `created_by` (member FK); `created_at`; `updated_at`. Unique `(organisation_id, cidr)`.
- **`member_sessions`** — `id` (PK); `organisation_id` (FK, indexed); `member_id` (FK, indexed); `token_hash` (**hashed** — the session token is never stored in clear); `created_at`; `last_seen_at`; `absolute_expires_at`; `revoked_at` (nullable); `revoked_by` (member FK, nullable); `ip`; `user_agent`; `updated_at`. Indexed on `(member_id, revoked_at)` for active-session listings.
- **`api_keys`** — `id` (PK); `organisation_id` (FK, indexed); `name`; `key_prefix` (short recoverable prefix for display); `secret_hash` (**hashed**, strong KDF via the stack pack); `scopes` (validated catalog permission keys); `created_by` (member FK); `expires_at` (nullable); `last_used_at` (nullable, coarse-grained — see Backend); `rotated_from_api_key_id` (nullable self-FK); `revoked_at` (nullable); `created_at`; `updated_at`. Unique `(organisation_id, name)` among non-revoked keys.

No new instance-global tables. `mfa_enrolled` / `sso_linked` for the security overview are read from the MFA and SSO specs' tables, not duplicated here.

## Backend implementation requirements

- Lives in a `security` module; policy entity + bounds rules in the domain, use cases in the service ring, session/key stores as repo adapters, routes + guards in the controller ring.
- **Guards + rule checks**: each endpoint's permission is a controller-ring guard; state-dependent rules (scope-subset, self-lockout confirmation, own-vs-other session) re-checked in the use case.
- **Session enforcement** is a controller-ring aspect on all authenticated routes: resolve the session record, reject if revoked or past idle/absolute limits, update `last_seen_at` (write-behind/coarsened to avoid a hot write per request; supplied store per the stack pack). Policy values are read through a cached org-policy port, invalidated synchronously on policy update (same strategy as the RBAC permission cache).
- **IP allowlist evaluation** sits in the same edge aspect, after authentication resolves the org: `enforced` blocks with `403 IP_NOT_ALLOWED`; `report_only` records the would-block observation and proceeds. Applies to session and API-key traffic alike. CIDR parsing/matching uses an established library (never hand-rolled).
- **Self-lockout guard** is a use-case rule: on saving `enforced` mode or editing entries while enforced, match the request's IP against the resulting list; mismatch without `confirmCurrentIpMismatch` → `409 IP_SELF_LOCKOUT_UNCONFIRMED`.
- **API keys**: secret generated server-side, returned once, stored only as `secret_hash`; lookup by `key_prefix` then constant-time hash compare. Rotation creates a successor row linked via `rotated_from_api_key_id`; the predecessor's `expires_at` is set to the overlap end. Scope-subset check runs against the *creator's* effective permissions via the RBAC `PermissionChecker` port at create/update time (not re-evaluated per request — the key's own scopes are authoritative afterwards).
- **Throttle/lockout** state lives in the rate-limit store named by the stack pack; counting is per `(account, ip)`; concurrency-safe increments (atomic ops, not read-modify-write).
- **Concurrency/idempotency**: `PUT …/security-policy` is a full replace — replays are no-ops and no-op saves emit no audit event; session revocation is idempotent (`204` on already-revoked).
- **Background jobs**: one sweep job deleting expired/revoked session rows past a grace window and flipping expired API keys — housekeeping only, no policy decisions in the job.

## Audit log events

Emitted via the shared `record()` in the service ring, same transaction as the change.

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `security.policy.updated` | Session/password/notification policy changed | `before`/`after`: changed fields (values only — never secrets) |
| `security.policy.change_denied` | Policy change blocked (permission, bounds, approval pending) | `outcome: denied`; violated rule in `context` |
| `security.ip_allowlist.updated` | Entries or mode changed | `before`/`after`: entries diff, mode |
| `security.ip.blocked` | Request denied in `enforced` mode | `outcome: denied`; source IP, matched-nothing note |
| `security.ip.flagged` | Would-block in `report_only` (deduplicated per actor+IP per hour to bound volume) | `outcome: failure`; source IP |
| `security.session.revoked` | Session revoked (self or admin) | target = session; actor vs. session owner distinguishes admin revocation |
| `security.session.rejected` | A revoked/expired session presented | `outcome: denied`; reason (`revoked` \| `idle` \| `absolute`) |
| `security.login.locked_out` | Throttle lockout engaged | `outcome: denied`; failure count |
| `security.password.rejected` | Candidate password refused (length/breached) | `outcome: failure`; reason class only — never the candidate |
| `security.api_key.created` | Key created | `after`: name, prefix, scopes, expiry |
| `security.api_key.updated` | Name/scopes/expiry changed | `before`/`after` diff |
| `security.api_key.rotated` | Secret rotated | target = key; overlap end |
| `security.api_key.revoked` | Key revoked | target = key |
| `security.api_key.change_denied` | Key mutation blocked (permission, scope-subset) | `outcome: denied` |

## Security considerations

- Session tokens and API-key secrets never appear in responses (beyond one-time display), logs, or audit payloads; storage is hash-only per the data model.
- Revocation is authoritative server-side state — no reliance on client-side token expiry (add-on principle: sessions are server-revocable).
- The breached-password check must be k-anonymity-style: the full candidate never leaves the backend, and its failure mode is availability-safe (req. 4).
- IP allowlisting always ships through `report_only` first; the self-lockout guard plus Owner break-glass bound the blast radius of a bad rule.
- API-key scopes cap at the creator's permissions, closing the escalate-via-key hole; revoking the creator does not silently widen or invalidate existing keys (their scopes stand until reviewed — surfaced in the members-security view work).
- All tables and queries org-scoped; other orgs' sessions/keys are `404`s.

## Error cases

| Scenario | HTTP | Code |
|---|---|---|
| Missing the endpoint's permission | 403 | `PERMISSION_DENIED` |
| Session past idle/absolute limits | 401 | `SESSION_EXPIRED` |
| Revoked session presented | 401 | `SESSION_REVOKED` |
| Policy value outside declared bounds | 400 | `POLICY_OUT_OF_BOUNDS` |
| Malformed CIDR entry | 400 | `INVALID_CIDR` |
| Enforced allowlist excludes the saving admin's IP, unconfirmed | 409 | `IP_SELF_LOCKOUT_UNCONFIRMED` |
| Request from a non-allowlisted IP (enforced) | 403 | `IP_NOT_ALLOWED` |
| Password shorter than the org minimum | 400 | `PASSWORD_TOO_SHORT` |
| Password found in the breach corpus | 400 | `PASSWORD_BREACHED` |
| Login throttle lockout active | 429 | `LOGIN_TEMPORARILY_LOCKED` |
| API-key scopes exceed the actor's permissions | 403 | `API_KEY_SCOPE_EXCEEDS_ACTOR` |
| Expired API key presented | 401 | `API_KEY_EXPIRED` |
| Revoked API key presented | 401 | `API_KEY_REVOKED` |
| Session/key id not found (or other org's) | 404 | `SESSION_NOT_FOUND` / `API_KEY_NOT_FOUND` |

## User stories & acceptance criteria

**S1 (P1)** — As an org admin, I want to set session idle and absolute lifetimes within safe bounds, so that stale sessions can't linger.

- [ ] Policy read/write works with defaults per req. 2. *Verify: `GET`/`PUT …/security-policy` contract tests, including a fresh org returning the defaults.*
- [ ] Out-of-bounds values are rejected. *Verify: unit tests on the policy schema + `PUT` with 3-minute idle timeout returning `400 POLICY_OUT_OF_BOUNDS`.*
- [ ] An idle or over-lifetime session is rejected on its next request. *Verify: integration test with clock control — advance past idle timeout, next call returns `401 SESSION_EXPIRED` and a `security.session.rejected` event exists.*
- [ ] Policy changes are audited and permission-gated. *Verify: `PUT` as Manager returns `403 PERMISSION_DENIED` with a denied event; as Admin succeeds and a `security.policy.updated` event carries the before/after diff.*

**S2 (P1)** — As a member, I want to see and revoke my sessions — and as an admin, any member's — so that a lost device or offboarded laptop loses access immediately.

- [ ] A member lists their sessions with device/IP/last-seen and the current one marked. *Verify: contract test on `GET …/members/me/sessions` with two live sessions.*
- [ ] Self and admin revocation take effect immediately. *Verify: integration test — revoke via both `DELETE` routes, then a request on the revoked session returns `401 SESSION_REVOKED`.*
- [ ] Admin routes are permission-gated and everything is audited. *Verify: `GET …/members/{id}/sessions` as Member returns `403 PERMISSION_DENIED`; revocations produce `security.session.revoked` events naming actor and session owner.*
- [ ] Sessions screen shows list/revoke with loading/error/empty states. *Verify: screen check — empty state with no other sessions, list state, confirm-and-revoke flow.*

**S3 (P2)** — As an org admin on password auth, I want a modern password policy, so that weak and breached passwords are kept out without composition theater.

- [ ] Minimum length ≥ 12 enforced and configurable. *Verify: unit test rejecting `minLength: 8` config; signup/password-change with an 11-char password returns `400 PASSWORD_TOO_SHORT`.*
- [ ] Breached passwords rejected via the k-anonymity check; corpus outage degrades safely. *Verify: integration test with the stack-pack check stubbed — a known-breached password returns `400 PASSWORD_BREACHED`; with the stub erroring, the change succeeds and a `security.password.rejected`-free warning path is observed.*
- [ ] Throttling locks out after repeated failures, temporarily. *Verify: integration test — 10 failed logins, next attempt returns `429 LOGIN_TEMPORARILY_LOCKED`, a `security.login.locked_out` event exists, and login succeeds after the window (clock control).*

**S4 (P2)** — As an org admin, I want IP allowlisting with a report-only rollout and self-lockout guard, so that I can restrict network origin without locking my org out.

- [ ] Report-only mode records would-blocks without blocking. *Verify: integration test — non-matching request succeeds and a `security.ip.flagged` event exists.*
- [ ] Enforced mode blocks interactive and API-key traffic. *Verify: integration tests — non-matching session request and API-key request both return `403 IP_NOT_ALLOWED` with `security.ip.blocked` events.*
- [ ] Self-lockout guard requires explicit confirmation. *Verify: `PUT …/security-policy` enforcing a list excluding the caller's IP returns `409 IP_SELF_LOCKOUT_UNCONFIRMED`; retry with `confirmCurrentIpMismatch: true` succeeds.*
- [ ] Malformed CIDRs rejected. *Verify: contract test — `PUT` with `10.0.0.0/40` returns `400 INVALID_CIDR`.*

**S5 (P2)** — As an org admin, I want scoped, expiring, rotatable API keys, so that programmatic access is least-privilege and recoverable.

- [ ] Creation returns the secret exactly once; listings never include it. *Verify: contract tests on `POST`/`GET …/api-keys` asserting `secret` present only in the create response and `secret_hash` never serialised.*
- [ ] Scopes must be a subset of the creator's permissions. *Verify: create as Manager with `org_policy:update` scope returns `403 API_KEY_SCOPE_EXCEEDS_ACTOR`.*
- [ ] Expiry, rotation overlap, and revocation behave per req. 6. *Verify: integration tests with clock control — expired key returns `401 API_KEY_EXPIRED`; after rotation the old secret works until `overlapExpiresAt` then fails; after `DELETE` the key returns `401 API_KEY_REVOKED` immediately.*
- [ ] `last_used_at` updates on use. *Verify: call an endpoint with the key, then `GET …/api-keys` shows a fresh `lastUsedAt`.*

**S6 (P2)** — As a member, I want security notification emails, so that I learn of account changes I didn't make.

- [ ] New-device login, password change, and MFA change each notify the affected member; policy changes notify admins. *Verify: integration tests asserting one message per event through the mail port's test-mode sink, with no secrets in the payload.*
- [ ] Delivery is stubbed under test mode; control logic is not. *Verify: with test-mode on, the flow test asserts the sink received the message and no real send occurred.*

**S7 (P2)** — As an org admin, I want a members-security view, so that I can spot weak accounts at a glance.

- [ ] The overview lists MFA enrolled, last login, active session count, SSO-linked per member, paginated. *Verify: contract test on `GET …/members/security-overview` against seeded members in known states.*
- [ ] Gated by `members:read`. *Verify: call as Member returns `403 PERMISSION_DENIED`.*
- [ ] Screen renders with loading/error/empty states. *Verify: screen check on the members-security view in all three states plus populated.*

## UX & non-functional notes

- Screens: Security settings (session policy, password policy, IP allowlist with mode switch + confirmation dialog, notification toggles), My sessions (under account settings), Members-security view, API keys (list, create with one-time secret modal, rotate, revoke). All need loading/error/empty states; destructive actions (revoke, enforce allowlist) need confirmation.
- Session and IP checks run on every request — the edge aspect must stay cache-backed and O(1)-ish; no per-request policy-table scan.
- One-time secret display must be copyable and never re-fetchable; the UI states this explicitly.
- Everything ships behind the program's default-off rollout flag; org-visible enforcement additionally follows the org's own policy values (safe defaults).

## Out of scope

- MFA factor enrolment/enforcement mechanics — `mfa.md` (this spec only reads enrolment status).
- SSO/SCIM configuration and the Owner break-glass recovery mechanics — `sso-identity.md`.
- Export/bulk rate bounds — `export-bulk-controls.md`.
- Audit-log storage/query/export semantics — `audit-logs.md`.
- Per-key IP pinning, key usage analytics, and anomaly detection (revisit post-GA).

## Open questions

- No `design/` mockup exists yet for the new screens (Security settings, My sessions, Members-security view, API keys); required before initial build.
- API-key rotation overlap default (proposal: 24 h, bounds 0–72 h) — owner: product, before S5 starts.
- Should `report_only` IP findings get a digest email to admins, or is the audit view enough for v1? Owner: product; default is audit-view-only (YAGNI).
- Does the new-device notion need a device-fingerprint heuristic beyond (user-agent, IP) novelty? Owner: engineering with the stack pack, before S6.
