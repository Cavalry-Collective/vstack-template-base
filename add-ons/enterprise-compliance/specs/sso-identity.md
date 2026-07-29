# SSO & identity lifecycle — enterprise compliance controls

> Part of the enterprise-compliance program — shared conventions and phasing: program-index.md. Status: proposed.

## Goal

Let an organisation federate authentication to its own identity provider (SAML 2.0 or OIDC) and verify ownership of its email domains. Members are provisioned and deprovisioned from the IdP — JIT now, SCIM 2.0 next — so offboarded users lose access in minutes. Enforced SSO-only login ships with a safe break-glass path, and the whole surface meets enterprise auth review.

## Scope & ownership

- **Owns:** the IdP connection (config, certificates, tests), domain verification, JIT and SCIM provisioning, enforced-SSO mode with break-glass codes, group→role mapping, deprovisioning session revocation, and this spec's `SSO_*` / `BREAK_GLASS_*` / `USER_DEACTIVATED` error codes.
- **Consumes:** the MFA trust-IdP-claim decision (`mfa.md` owns it; this spec extracts the claim); field-level encryption for IdP secrets (`encryption.md`); roles for JIT defaults and group mapping (`rbac.md`); member deactivation (`members:remove`, existing member management).
- **Phases:** the whole area is **P2** — password + MFA is the P1 auth baseline, so this spec has no P1 stories. S1–S7 are P2; group→role mapping (S8) is P3.

## User stories & acceptance criteria

**S1 (P2)** — As an org admin, I want to configure and test our IdP (SAML 2.0 or OIDC), so that members can sign in with corporate credentials.
- [ ] POST then GET configuration round-trips for both protocols with secrets masked on read. *Verify: contract tests on POST/GET/PUT `…/sso/configuration` for `saml` and `oidc`, asserting `oidc_client_secret` absent from responses.*
- [ ] Invalid metadata is rejected with `400 IDP_METADATA_INVALID`. *Verify: POST with unparseable metadata document and with a private-host metadata URL; assert code and no row created.*
- [ ] Test flow records success with received claims, failure with the validation code. *Verify: integration test driving POST `…/tests` + stubbed IdP callback (test-mode stub), polling GET until `succeeded`, then a bad-signature run until `failed`; assert `auth.sso_config.tested` events.*

**S2 (P2)** — As an org admin, I want to verify our email domain, so that only domains we own can be federated.
- [ ] Domain verification passes only when the TXT record matches, and a domain claimed by another org is refused. *Verify: integration test with fake `DnsVerifier` (match → `verified`, mismatch → `failed`); POST same domain from a second org asserting `409 SSO_DOMAIN_ALREADY_CLAIMED`.*
- [ ] SSO login for an unverified domain is denied and audited. *Verify: callback integration test asserting `403 SSO_DOMAIN_UNVERIFIED` and an `auth.login.denied` event.*

**S3 (P2)** — As a member, I want SP- and IdP-initiated SSO login, so that I can sign in from either side.
- [ ] SP-initiated: email → redirect → callback → session, with `auth.login.succeeded`. *Verify: integration test through GET `/auth/sso/authorize` and stubbed callback; assert session cookie and audit row.*
- [ ] IdP-initiated unsolicited SAML response yields the same result under the same validations. *Verify: integration test posting an unsolicited valid response, then each of the six error-case assertions (signature, skew, audience, issuer, replay, deactivated) returning the mapped 401/403 code and `auth.login.failed`/`denied` events.*

**S4 (P2)** — As an org admin, I want JIT provisioning with a default role, so that new hires get access on first login without manual invites.
- [ ] First SSO login of an unknown, verified-domain user creates user + membership with the default role and emits `auth.user.jit_provisioned`. *Verify: integration test; also replay the callback concurrently twice and assert exactly one user row.*
- [ ] With JIT off, the same login is denied `403 SSO_JIT_DISABLED`. *Verify: same test with `jit_enabled: false`.*

**S5 (P2)** — As an org owner, I want enforced-SSO with break-glass codes, so that password login is closed off without locking us out.
- [ ] Enforcement requires preconditions and returns one-time owner codes. *Verify: PUT `…/sso/enforcement` before/after a successful test, asserting `409 SSO_ENFORCEMENT_PRECONDITION_FAILED` then `200` with codes; codes absent from any later GET.*
- [ ] Password login and reset are refused for org members while enforced. *Verify: contract tests on the password login/reset endpoints asserting `403 SSO_ENFORCED` and `auth.login.denied`.*
- [ ] A break-glass code grants one time-boxed session then becomes unusable. *Verify: POST `/auth/break-glass` twice with the same code — `200` then `401 BREAK_GLASS_CODE_INVALID`; assert `auth.break_glass.succeeded`/`failed` events and session expiry ≤ 1h.*

**S6 (P2)** — As an org admin, I want deprovisioning to revoke access within minutes, so that offboarded users can't use live sessions.
- [ ] Deactivating a member revokes all their sessions in the same transaction and blocks subsequent logins. *Verify: integration test — open two sessions, deactivate, assert both sessions rejected on next request and login returns `403 USER_DEACTIVATED`; assert `auth.member.deprovisioned` + `auth.sessions.revoked` events.*

**S7 (P2)** — As an IT admin, I want SCIM 2.0 provisioning, so that our directory drives membership automatically.
- [ ] SCIM create/update/deactivate work with bearer-token auth and SCIM-format errors; deactivate revokes sessions. *Verify: contract tests on `…/scim/v2/Users` (valid token, revoked token → 401, malformed payload → SCIM error shape); integration test asserting session revocation and `scim.member.*` events with actor `system`.*

**S8 (P3)** — As an org admin, I want IdP-group→role mapping, so that roles follow the directory.
- [ ] Mapped group claims set the member's role at login; unmapped users keep the default; changes audited. *Verify: integration test with claims containing a mapped and an unmapped group; assert role outcome and `auth.group_mapping.updated` on PUT.*

## Requirements

1. An org admin can configure exactly one active IdP connection per organisation, protocol SAML 2.0 or OIDC, via metadata URL or uploaded metadata/manual fields.
2. IdP signing-certificate rotation is zero-downtime: multiple verification certificates can be active at once, and metadata-URL configs are refreshed by a background job at least daily (OIDC key sets are fetched from the issuer's published key endpoint and cached).
3. SSO logins are accepted only for email domains the organisation has verified via a DNS TXT challenge; a domain can be verified by at most one organisation.
4. A test-connection flow lets the admin complete a full round-trip login against the draft config without affecting real sign-in; enforcement cannot be enabled until one test has succeeded.
5. Both SP-initiated login (user starts at our sign-in screen) and IdP-initiated login (SAML unsolicited response) work; IdP-initiated responses are subject to the same signature, audience, issuer, freshness, and replay checks.
6. JIT provisioning (per-config toggle, default off) creates a user + membership with the config's default role on first successful SSO login for a verified domain. JIT never elevates an existing member's role; only group mapping (P3, requirement 11) may change roles, and that is audited.
7. Enforced-SSO mode blocks password login **and password reset** for all members of the org except via break-glass — an open reset path would bypass enforcement. Enabling it requires a verified domain and a successful test.
8. Break-glass: enabling enforcement issues each org owner a set of one-time recovery codes (shown once, stored hashed); a code grants a single time-boxed password session and is heavily audited. Using one does not disable enforcement. Codes expire after 90 days and can be regenerated only via the enforcement screen.
9. Deprovisioning revokes access in minutes, not at token expiry: deactivating a member (by admin, or via SCIM) revokes all of that member's sessions in the same use case; sessions are server-revocable per the add-on SOP.
10. SCIM 2.0 (P2): per-org bearer-token-authenticated `Users` endpoint supporting create, update, and deactivate; deactivate triggers requirement 9.
11. IdP-group→role mapping (P3): admin-maintained mapping from IdP group/claim values to roles, applied at each SSO login; unmapped users keep the JIT default role.
12. Every assertion/token is validated for signature, audience, issuer, expiry with bounded clock skew (±5 minutes), and one-time use (replay cache) before any account lookup.
13. All configuration changes, logins (success, failure, denied), provisioning, and deprovisioning emit audit events per the table below.
14. The whole area ships behind a default-off platform flag per the program index; an org without an SSO config sees no behaviour change.

## User flows

### F1 — Configure an IdP (P2)
1. Admin opens Security settings → Single sign-on. 2. Chooses SAML 2.0 or OIDC; supplies metadata URL or upload (SAML) / issuer + client credentials (OIDC). 3. System validates and parses metadata, stores the config in status `draft`, shows our SP entity ID / ACS URL / redirect URI for the IdP side. 4. Admin runs the test flow (F3). 5. Config moves to `active`; SSO login becomes available (not yet enforced).

### F2 — Verify an email domain (P2)
1. Admin adds a domain. 2. System issues a DNS TXT challenge token. 3. Admin publishes the record and requests verification. 4. A background job checks DNS and marks the domain `verified` or `failed` (retryable). 5. Result is visible on the domain list and audited.

### F3 — Test connection (P2)
1. Admin starts a test; system creates a test record (`pending`) and returns a login URL bound to the draft config. 2. Admin completes the IdP round-trip in the browser. 3. Callback validates the assertion/token and records `succeeded` (with the received subject and claims for inspection) or `failed` (with the validation error). 4. No session is issued and no user is provisioned by a test.

### F4 — SP-initiated login (P2)
1. User enters email on the sign-in screen. 2. If the email's domain belongs to an org with an active config, they are redirected to the IdP (password field hidden when that org enforces SSO). 3. IdP authenticates and returns to our callback. 4. Assertion/token is validated (req. 12), domain checked against verified domains, user matched by external identity link or email. 5. Existing active member → session issued; unknown user with JIT on → provisioned then session issued; otherwise denied with the mapped error. 6. Outcome audited.

### F5 — IdP-initiated login, SAML (P2)
1. IdP posts an unsolicited response to the ACS URL. 2. Same validation and matching as F4 steps 4–6.

### F6 — Enforce SSO (P2)
1. Admin toggles enforcement. 2. System checks preconditions (verified domain, successful test) and warns that password login will be blocked. 3. On confirm, break-glass codes are generated for each org owner and displayed once. 4. Password logins for org members are refused from the next attempt; existing sessions are unaffected.

### F7 — Break-glass recovery (P2)
1. Org owner (IdP outage or misconfiguration) opens the break-glass screen. 2. Submits email + one-time code. 3. Code hash matched and consumed; a time-boxed session (max 1 hour) is issued via password-ring auth. 4. Owner fixes or disables the SSO config. 5. Both the code use and any enforcement change are audited.

### F8 — Deprovisioning (P2)
1. Admin deactivates a member (existing member management, `members:remove`) or SCIM sends `active: false`. 2. The use case deactivates the membership, revokes every session of that member, and disables their API keys' org access in one transaction. 3. Subsequent SSO or password logins for that membership are denied (`USER_DEACTIVATED`). 4. Audited with actor (`user` or `system`/SCIM).

## API & permissions

Admin resources under `/internal/v1/organisations/{organisationId}/…`; login/callback under `/internal/v1/auth/…`. Base pagination and error envelopes apply; async work returns a `pending` resource per the index.

- `sso_config:read` — view configuration, domains, test history, SCIM token status. Secrets (OIDC client secret, SCIM token) are never returned; only a configured indicator, per the backend write-only-secrets rule.
- `sso_config:manage` — create/update/delete the IdP config, upload/retire certificates, run tests, manage domains, toggle enforcement, manage group mappings (P3).
- `scim_tokens:manage` — issue and revoke SCIM tokens (P2). Deactivating a member uses the existing `members:remove`.
- Break-glass codes are visible once at enforcement time to org owners only — an owner-role gate, not a permission.

| Method & path | Purpose | Permission | Notable fields |
|---|---|---|---|
| GET `…/sso/configuration` | Read the org's config | `sso_config:read` | protocol, status, entity IDs, certificate list (fingerprints + validity), `jit_enabled`, `default_role_id`, `enforced`; secrets masked |
| POST `…/sso/configuration` | Create config (409 if one exists) | `sso_config:manage` | `protocol`, `metadata_url` or `metadata_document`, OIDC `issuer`/`client_id`/`client_secret` |
| PUT `…/sso/configuration` | Full-replace update (blank secret = keep) | `sso_config:manage` | as POST |
| DELETE `…/sso/configuration` | Remove config (409 while enforced) | `sso_config:manage` | — |
| POST `…/sso/configuration/certificates` | Upload an additional verification certificate | `sso_config:manage` | PEM; response adds fingerprint/validity |
| DELETE `…/sso/configuration/certificates/{certificateId}` | Retire a certificate (409 if last active) | `sso_config:manage` | — |
| POST `…/sso/configuration/tests` | Start test-connection → `201 pending` + `login_url` | `sso_config:manage` | client polls the test resource |
| GET `…/sso/configuration/tests/{testId}` | Poll test result | `sso_config:read` | `status`, received subject/claims or validation error |
| GET `…/sso/domains` | List domains (paginated) | `sso_config:read` | `domain`, `status`, `verified_at` |
| POST `…/sso/domains` | Add domain → `201 pending` + TXT challenge | `sso_config:manage` | `domain` |
| POST `…/sso/domains/{domainId}/verifications` | Request (re)verification → `201 pending`, job checks DNS | `sso_config:manage` | poll the domain resource |
| DELETE `…/sso/domains/{domainId}` | Remove domain (409 if enforcement depends on it) | `sso_config:manage` | — |
| PUT `…/sso/enforcement` | Enable/disable enforced-SSO | `sso_config:manage` | `{ enforced }`; enable response carries one-time break-glass codes for owners |
| GET/PUT `…/sso/group-mappings` (P3) | Read/replace IdP-group→role map | `sso_config:read` / `sso_config:manage` | list of `{ group_value, role_id }` |
| POST `…/scim-tokens` (P2) | Issue SCIM bearer token (plaintext once) | `scim_tokens:manage` | `token`, `last_used_at` on reads |
| DELETE `…/scim-tokens/{tokenId}` (P2) | Revoke token | `scim_tokens:manage` | — |
| GET `/internal/v1/auth/sso/authorize?email=` | SP-initiated start → redirect to IdP | unauthenticated | — |
| POST `/internal/v1/auth/sso/callback` | ACS / redirect-URI; handles SP- and IdP-initiated | unauthenticated | validated per req. 12; issues session or mapped error |
| POST `/internal/v1/auth/break-glass` | One-time-code owner recovery login | unauthenticated | `email`, `code`; time-boxed session |
| `…/scim/v2/Users` (+`/{id}`) (P2) | SCIM 2.0 create/update/deactivate | SCIM bearer token | RFC 7643/7644 schemas; **SCIM error format, not the base envelope** |

## Data model

All new tables carry `organisation_id` (indexed) except `external_identities`, which is user-keyed but still carries `organisation_id` via its config FK's org (denormalised column kept for scoped queries). Reversible migrations per `db/CLAUDE.md`; all tables get `created_at`/`updated_at`, UTC.

- **`sso_configurations`** — `organisation_id` (unique — one config per org), `protocol` (`saml`|`oidc`), `status` (`draft`|`active`), `metadata_url` (nullable), `metadata_document` (nullable, cached copy), `idp_entity_id` / `oidc_issuer`, `sso_url`, `oidc_client_id`, `oidc_client_secret` (**field-level encrypted**), `jit_enabled` (bool, default false), `default_role_id` (FK), `enforced` (bool, default false), `metadata_refreshed_at`, `last_test_succeeded_at`.
- **`sso_certificates`** — `organisation_id`, `sso_configuration_id` (FK, indexed), `fingerprint` (unique per config), `certificate_pem` (public material, not secret), `not_before`, `not_after`, `status` (`active`|`retired`), `source` (`metadata`|`upload`).
- **`sso_domains`** — `organisation_id`, `domain` (**unique across the instance** — one owning org), `challenge_token`, `status` (`pending`|`verified`|`failed`), `verified_at`, `last_checked_at`.
- **`sso_connection_tests`** — `organisation_id`, `sso_configuration_id`, `status` (`pending`|`succeeded`|`failed`), `initiated_by` (member FK), `result_subject`, `result_claims` (redacted), `failure_code`, `expires_at`.
- **`external_identities`** — `user_id` (FK, indexed), `organisation_id`, `sso_configuration_id`, `subject` (IdP NameID / `sub`; unique per config), `last_login_at` — links an IdP identity to a user.
- **`break_glass_codes`** — `organisation_id`, `user_id` (owner), `code_hash` (hashed with the platform password hasher; **plaintext never stored**), `used_at` (nullable), `expires_at`.
- **`scim_tokens`** (P2) — `organisation_id`, `token_hash` (hashed, plaintext never stored), `created_by`, `last_used_at`, `revoked_at` (nullable).
- **`sso_group_mappings`** (P3) — `organisation_id`, `sso_configuration_id`, `group_value`, `role_id` (FK), unique (`sso_configuration_id`, `group_value`).
- **Replay cache** for assertion/token IDs lives in the stack pack's rate-limit/session store with TTL, not a table.

## Audit events

| `action` | When emitted | Notable envelope fields |
|---|---|---|
| `auth.sso_config.created` / `auth.sso_config.updated` / `auth.sso_config.deleted` | Config lifecycle | before/after diff (secrets redacted) |
| `auth.sso_config.tested` | Test finishes | outcome `success`\|`failure`, failure code |
| `auth.sso_certificate.added` / `auth.sso_certificate.retired` | Cert change (admin or metadata refresh) | actor may be `system`; fingerprint |
| `auth.sso_domain.added` / `auth.sso_domain.verified` / `auth.sso_domain.verification_failed` / `auth.sso_domain.removed` | Domain lifecycle | domain, actor `system` for job outcomes |
| `auth.sso_enforcement.enabled` / `auth.sso_enforcement.disabled` | Enforcement toggled | count of break-glass codes issued (never the codes) |
| `auth.login.succeeded` | SSO login issues a session | `context` + `method: sso`, config id |
| `auth.login.failed` | Assertion/token validation failed | failure code (e.g. `SSO_ASSERTION_INVALID_SIGNATURE`), outcome `failure` |
| `auth.login.denied` | Valid assertion but access refused (unverified domain, deactivated user, JIT off, SSO enforced blocking password) | denial code, outcome `denied` |
| `auth.user.jit_provisioned` | JIT creates user + membership | target user, default role |
| `auth.member.deprovisioned` | Member deactivated (admin or SCIM) | actor type `user`/`system`, source |
| `auth.sessions.revoked` | Deprovisioning revokes sessions | session count |
| `auth.break_glass.succeeded` / `auth.break_glass.failed` | Break-glass attempt | outcome; code never logged |
| `scim.token.created` / `scim.token.revoked` | SCIM token lifecycle (P2) | token id only |
| `scim.member.provisioned` / `scim.member.updated` / `scim.member.deprovisioned` | SCIM writes (P2) | actor `system`, redacted diff |
| `auth.group_mapping.updated` | Mapping replaced (P3) | before/after mapping diff |

## Implementation notes

- New `identity` (or extended `auth`) module. **Domain** defines ports: `IdentityProviderVerifier` (validate assertion/token → normalised identity claims), `MetadataFetcher`, `DnsVerifier`, `SessionRevoker`, plus repositories; the SAML/OIDC libraries implementing them are supplied by the active stack pack, in the repo ring. Signature verification uses the stack pack's library — never hand-rolled XML/JWT crypto.
- **Service ring** use cases: configure/test/enforce, verify domain, complete SSO login (validation → matching → JIT → session), break-glass login, deprovision member. Each owns one transaction and calls `record()` inside it.
- **Controller ring**: guards check `sso_config:*` permissions at the edge; the login callback and break-glass endpoints are unauthenticated but rate-limited (stack pack store) against code/assertion stuffing. SCIM controllers translate to/from SCIM schemas and reuse the same member use cases — no forked provisioning logic.
- **Validation order (req. 12):** full assertion/token validation before any DB lookup — signature against active certs / fetched keys, audience, issuer, `NotBefore`/`NotOnOrAfter` (±5 min skew), one-time assertion-ID replay cache. Metadata URL fetches are server-side requests to admin-supplied URLs — apply the backend SSRF guard (scheme + public-host checks, at save and at fetch).
- **Idempotency/concurrency**: JIT provisioning is idempotent on (`sso_configuration_id`, `subject`) — a concurrent double-callback yields one user (unique constraint, `409` mapped to retry-read). SCIM operations key on `externalId`/`subject`. Assertion replay rejected via one-time-ID cache (req. 12). Domain verification job uses conditional update so concurrent checks don't flap status.
- **Background jobs** (stack pack runner): daily metadata refresh (req. 2), DNS verification checks, purge of expired connection tests and expired break-glass codes.
- Session revocation on deprovisioning is synchronous in the use case — not deferred to a job (req. 9).

## Edge cases & errors

| Scenario | HTTP | Code |
|---|---|---|
| Caller lacks the endpoint's permission | 403 | `PERMISSION_DENIED` |
| Metadata unfetchable / unparseable / fails SSRF guard | 400 | `IDP_METADATA_INVALID` |
| Second config for an org / config exists | 409 | `SSO_CONFIG_ALREADY_EXISTS` |
| No config where one is required | 404 | `SSO_CONFIG_NOT_FOUND` |
| Domain already verified by another organisation | 409 | `SSO_DOMAIN_ALREADY_CLAIMED` |
| Enforcement enable without verified domain / successful test | 409 | `SSO_ENFORCEMENT_PRECONDITION_FAILED` |
| Delete config or last certificate while enforced | 409 | `SSO_ENFORCEMENT_ACTIVE` |
| Assertion/token signature invalid | 401 | `SSO_ASSERTION_INVALID_SIGNATURE` |
| Assertion outside validity window beyond allowed skew | 401 | `SSO_CLOCK_SKEW_EXCEEDED` |
| Audience/recipient mismatch | 401 | `SSO_AUDIENCE_MISMATCH` |
| Issuer mismatch | 401 | `SSO_ISSUER_MISMATCH` |
| Assertion/token ID replayed | 401 | `SSO_REPLAYED_ASSERTION` |
| Login for a domain the org has not verified | 403 | `SSO_DOMAIN_UNVERIFIED` |
| Login by a deactivated user/membership | 403 | `USER_DEACTIVATED` |
| Unknown user and JIT disabled | 403 | `SSO_JIT_DISABLED` |
| Password login/reset while SSO enforced | 403 | `SSO_ENFORCED` |
| Break-glass code wrong, used, or expired | 401 | `BREAK_GLASS_CODE_INVALID` |
| SCIM endpoints (P2) | — | RFC 7644 error format (SCIM `status`/`scimType`), not the base envelope |

## Notes & decisions

- **Enforcement blocks password reset too (req. 7):** an open reset path would let a member set a password and bypass SSO, so reset is disabled for the org's members while enforced.
- UX: screens are **Security settings → Single sign-on** (config, certificates, test, domains, enforcement + break-glass code reveal), the **SCIM provisioning** panel (P2), and sign-in screen changes (email-first routing, break-glass entry link). Each list/detail handles loading / error / empty states; test and domain-verification statuses poll while `pending`.
- Performance: callback validation adds no perceptible login latency (< 500 ms budget excluding IdP time); metadata refresh and DNS checks run off the request path. Secrets and one-time codes render once, with copy affordance, and never re-render on refresh.

## Out of scope

- SAML Single Logout (SLO) and OIDC back-channel logout; front-channel session ends at our session revocation.
- Multiple simultaneous IdP connections per organisation.
- SCIM `Groups` resource beyond the group-values consumed by P3 mapping; entitlement sync.
- Per-IdP vendor certification checklists (index open question; product owns).
- MFA policy interaction details — this spec only consumes the "trust IdP MFA claim" switch defined in mfa.md.

## Open questions

- No `design/` mockup exists yet for the new screens (Security settings → Single sign-on, SCIM provisioning panel, break-glass recovery screen, email-first sign-in routing); required before initial build.
- Which IdPs must be certified for launch (inherited from the program index; owner: product, before S1–S6 start).
- Should break-glass code use notify all org owners by email? Owner: product, before S5 build.
