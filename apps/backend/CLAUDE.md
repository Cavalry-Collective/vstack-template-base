# Backend contract

Binding for everything under `apps/backend/`. Read with it: the root `CLAUDE.md` (cross-cutting rules) and — if a stack pack is adopted (a single directory under `stacks/`) — its `backend.md` appendix, whose conflict register wins over this file for that stack only. Examples below use JS-style filenames and an Express/Fastify-style HTTP layer **illustratively**; extensions and framework specifics are examples, not mandates, until a pack binds them.

The backend is an **onion**: a pure domain at the centre, wrapped by rings that depend inward. Everything below follows from that.

## Never violate

1. **Dependencies point inward.** No inner ring knows anything about an outer ring; outer-ring types (HTTP requests, DB rows, SDK objects) never travel inward.
2. **The domain is pure** — no I/O, no clock, no network, no framework or DB types, ever.
3. **Business rules live in the domain**, not in controllers, repos, jobs, or utils. Branching in an adapter beyond what a query/call needs means a rule leaked.
4. **One transaction per use case**, owned by the service ring.
5. **One error envelope, one mapping site.** Domain raises failures in domain terms; only the controller-ring error mapper turns them into transport responses.
6. **Schema changes are migrations under `db/`** — never DDL from application code.
7. **No secrets or PII in logs; no secrets outside validated config.**

## The dependency rule

**Dependencies point inward. Nothing in an inner ring knows anything about an outer ring.**

- The domain depends on nothing; each outer ring depends only on rings inside it.
- When an inner ring needs an outer capability (load data, send mail), it defines the **contract** — a "port" — and an outer ring implements it. A port is a documented set of method signatures: an interface where the language has them (TypeScript), an agreed duck-typed shape (optionally pinned with a JSDoc `@typedef`) where it doesn't. The implementation is supplied from outside (see *Wiring*), so the arrow still points inward.
- Data crosses in translated form: DTOs at the edge, domain objects inside.

Test any boundary: can you swap what's outside (database, delivery mechanism) without touching what's inside? If not, something leaked. If a change wants to point a dependency outward, reshape the change, not the rule.

## The four rings

From the centre out: **Domain → Service → Repo / Controller**. Repo and Controller are both outer adapters; neither depends on the other.

| Ring | Holds | Depends on | Never |
|---|---|---|---|
| **Domain** | entities, value objects, domain services, invariants; defines the ports | nothing — pure, stateless | I/O; naming a technology. A rule testable only with a database is mis-shaped |
| **Service** | one use case per file, orchestrated end to end; the transaction boundary | domain + its ports, nothing concrete | HTTP/web concepts, query building, framework globals |
| **Repo** | port implementations: DB repositories, external clients; each with a **mapper** (outside shape ↔ domain object) | inner rings, to implement their ports | business rules or decisions |
| **Controller** | REST handlers, request/response DTOs, auth guards; validates input, invokes **one** use case, maps the result out | the service ring | logic, transactions, queries, reaching past service into repo |

Keep the domain small, dense, and protected — it's the part worth defending.

## Folder layout

Organise **by feature first, rings within**: each domain area is a self-contained module owning its rings; shared building blocks and wiring sit beside the modules. A small module adds a ring's folder only when it earns one.

```
apps/backend/
├─ src/
│  ├─ modules/
│  │  └─ <feature>/       # one self-contained domain area (user, billing, order)
│  │     ├─ domain/       # entities, value objects, domain services, ports
│  │     ├─ service/      # use cases — one per file; owns the transaction boundary
│  │     ├─ repo/         # adapters: db repositories + external clients + mappers
│  │     ├─ controller/   # REST handlers, routes, guards
│  │     └─ dtos/         # request/response shapes — the module's edge contract
│  ├─ shared/
│  │  ├─ aspects/         # cross-cutting decorators/plugins (auth, logging, tx, errors)
│  │  └─ utils/           # pure, stateless helpers — no I/O, no framework
│  └─ container.js        # composition root: wire port implementations to consumers
└─ tests/                 # mirrors src/ (or co-locate per module)
```

- Modules never import another module's inner rings — cross-module use goes through the other module's service or a shared port.
- `shared/utils/` depends on nothing; `shared/aspects/` wrap a ring and depend inward only.
- Name modules by business capability (`billing`, not `helpers`); name use cases by the use case (`issue-invoice`, not `invoice-utils`).

## Wiring

Ports are defined inside, implemented outside, connected in one place — the **composition root** (`container.js`).

- An inner ring receives its dependencies (constructor argument or factory parameter); it never imports a concrete adapter.
- The composition root is the only place that knows both a port and its implementation; swapping an adapter (real DB → in-memory fake) is a change there and nowhere else.
- Manual constructor wiring is enough; reach for a DI container only once the graph genuinely grows unwieldy. Wiring is glue, not logic.

## RESTful conventions

The controller ring's default API contract; a more specific project rule wins where one exists.

### Resource naming

Plural, lowercase nouns; hyphens for multi-word names; parent–child in path segments:

```text
/users
/users/{userId}/orders
/payment-methods
```

### Visibility and versioning

- `/internal/v1` for internal APIs, `/external/v1` for external. Default to internal; expose nothing externally until its consumers, permissions, and contract are clear.
- One unauthenticated, unversioned **`/health`** route answers liveness (no dependency fan-out, no auth). Anything deeper is a separate, authenticated route added only when needed.

### Methods

- `GET` retrieve · `POST` create · `PUT` full-resource replace · `DELETE` remove.
- No `PATCH` by default; introduce it only as a project-wide decision with documented merge semantics.
- Flag method/intent mismatches — a `GET` that mutates, a `POST` for plain retrieval.

### Pagination

- List endpoints take `page`, `recordsPerPage`, `sortBy`, `sortOrder` (`asc`|`desc`), placed after resource-specific filters.
- One list envelope: `{ "data": [...], "page": n, "recordsPerPage": n, "totalRecords": n }`. `data` is always an array — an empty result is `200` with `[]`, never `404`.
- Where COUNT-per-request or deep offsets are impractical, an endpoint may adopt **cursor pagination** (same envelope minus `page`/`totalRecords`, plus `nextCursor`, `null` when exhausted) — a documented per-endpoint decision, never silent.
- Flag any endpoint that can return an unbounded collection.

### Status codes

`200` retrieved/updated · `201` created · `204` deleted (no body) · `400` invalid request · `401` unauthenticated · `403` unauthorized · `404` not found · `409` conflict · `429` rate-limited · `500` unexpected. Flag unclear or misleading codes.

### Error responses

Every error uses one envelope, produced only by the single error-mapping site (*Cross-cutting → Errors*):

```json
{ "error": { "code": "ORDER_NOT_FOUND", "message": "Order 123 was not found.", "correlationId": "<id>" } }
```

- **`code`** — stable, machine-readable, `SCREAMING_SNAKE_CASE`, domain-termed. Clients branch on `code`, never parse `message`.
- **`message`** — human-readable and safe: no stack traces, SQL, or internal identifiers.
- **`correlationId`** — the request's correlation id; it also travels as the **`x-correlation-id` response header on every response**, success or failure (frontend counterpart: `apps/frontend/CLAUDE.md` → *Cross-app conventions*).
- Validation failures (`400`) may add `error.details`: `[{ "field": ..., "message": ... }]`.

Success shapes for symmetry: a single resource is the object itself (no wrapper); lists use the pagination envelope.

### Endpoint contract

Each endpoint defines its required permissions, request schema, response schema, validation rules, and error behaviour; each request field defines name, type, required/optional, description, and constraints. This contract is **public** (root contract → *Public contracts*): the frontend mirrors it, so changes are extend/version/deprecate — never silent breaks.

## Cross-cutting concerns

Concerns touching every request are **decorators/aspects** — declared once, applied to the ring they wrap, so handlers and use cases carry only their own logic. In Node that's the framework's middleware/plugin layer. **Scope each aspect to the subtree that needs it**, not globally. Every aspect obeys the dependency rule: it lives in its ring and passes data inward as plain values.

- **Auth:** edge guards reject unauthenticated requests at the controller ring; rule-level authorisation that depends on domain state lives in the domain or use case.
- **Rate limiting (where it exists):** an edge aspect at the controller ring — reject with `429` plus a retry hint; thresholds come from validated config; the key (per user, per target, per route) is defined by the owning feature or add-on.
- **Request context / identity:** established at the edge, passed inward as an argument — never read from a global by an inner ring.
- **Transactions:** the boundary wraps the use case (service ring).
- **Logging & audit:** one shared path carrying the request's correlation id. Structured records (key/value, not concatenated strings) at meaningful levels — `error` handled failures, `warn` recoverable anomalies, `info` state changes, `debug` behind a flag. **Never log secrets, tokens, credentials, auth headers, or PII — redact at the logging boundary**; log identifiers, not payloads. Log a failure **once**, where handled.
- **Audit trail:** when the app must answer *who changed what* (permissions, contact edits, moderation, money), that is distinct from logging — logs rotate; audit is durable, queryable history. One shared `record()` call in the service ring per meaningful state change — actor, action, target, before/after where it matters, correlation id. Invoked by the owning use case; never scattered inserts, never the log stream.
- **Errors:** the domain raises failures in domain terms; the controller ring's single mapper produces the *Error responses* envelope — one shape app-wide.

## Business rules

- Validate state transitions against the rules **before** applying a status or lifecycle change — never because an external request, callback, message, or event asked for it.

## Integrations

Every external API, callback, webhook, queue, and event is untrusted and unreliable. Integration code is a repo-ring adapter; the decisions it enforces belong to the domain.

- **Idempotency:** repeated requests, retries, and replays must not duplicate actions or overwrite valid results. Default idempotency key: the primary business record id, unless a clearer business key exists.
- **Concurrency:** assume parallel workers on the same record — conditional updates, locking, transactions, or version checks.
- **Validation:** structure, required fields, types, business rules, authenticity, and ownership — before sending or applying anything.
- **Ordering:** where order matters, process by event time / sequence / business rule, not arrival order.
- **Failure handling:** classify transient / permanent / invalid / unsupported / duplicate / unknown. Retry only transient, bounded with backoff, with a defined final-failure path.
- **Unclear outcomes:** never treat a timeout, transport error, malformed response, or ambiguous result as success. Preserve valid data; route to reconciliation or manual recovery.
- **Money/user-reaching integrations ship behind a default-off flag with a no-op sink.** SMS/email/payment/push: a default-off validated-config boolean, read in one place, routing to a stdout/no-op sink when off. Exercise against the sink; flip on per environment; flipping off is the instant rollback. (This flag underpins the `test-mode` and `otp-auth` add-ons.)

## Security baseline

The edge already validates input and places authorisation (see *Cross-cutting → Auth* and *Endpoint contract*). Additionally:

- **Parameterised data access:** query parameters as bound values, never interpolated request data.
- **Secrets from the environment** (root contract → *Configuration*): never hardcoded, committed, or echoed; inner rings receive config as injected values.
- **Ownership:** verify ownership of every client-supplied id before acting on the record — for ordinary requests, not just webhooks.
- **Security response headers** from one shared place: transport security, content-type/framing protections, referrer policy, and (where HTML is served) a **Content-Security-Policy** — rolled out report-only first, promoted once violation reports are clean. (Exact set + mechanism: the active pack.)
- **SSRF guard:** app-fetched, user-configured URLs (webhook targets, import sources) restricted to allowed schemes and **public** hosts; loopback/private/link-local/cloud-metadata targets rejected — validated at save *and* re-checked at call time.
- **Stored secrets are write-only:** reads expose only a "configured" indicator; a blank value on update means "keep existing".
- **Same-origin first; CORS is opt-in:** one origin for frontend and API where possible; a genuine cross-origin consumer gets an exact-origin allowlist in validated config — never `*` with credentials.
- **Sessions in HTTP-only cookies by default:** signed, secure, HTTP-only — never a session token for the SPA to keep in `localStorage`, unless the active pack registers otherwise.

## Coding standards

- **Don't reinvent libraries** (canonical rule: root contract). Worth repeating here: dates/timezones, phone canonicalisation, identifiers, CSV, and schema validation all use an established library behind one shared helper.
- **DTOs at the edge are explicit.** Map domain objects to response DTOs field by field — never spread an entity or return a storage row (over-fetch leaks sensitive fields).

## Testing the rings

The architecture exists to make testing cheap — exploit it. Most coverage sits in the fast inner rings, thinning outward:

- **Domain — pure unit tests.** No mocks, no I/O (the ring forbids both). Assert invariants directly.
- **Service — use-case tests.** In-memory fakes of the ports (the composition-root swap); assert orchestration and transaction boundaries, not the database.
- **Repo — integration tests.** Real database / sandbox; assert mappers round-trip and queries behave.
- **Controller — contract tests.** Status codes, validation rejection, auth guards, request/response schema per the *Endpoint contract*.

## Definition of done — verify a change

Before calling a backend change done (root gate: *verified means observed*):

- [ ] Test suite for the touched module passes.
- [ ] The endpoint was exercised over HTTP — happy path plus at least one error path.
- [ ] Status code, error shape, and correlation id observed to match the *Endpoint contract* and *Error responses* rules.
- [ ] No inner ring imports an outer concern (spot-check the diff against *Never violate*).
- [ ] Evidence stated: which paths you exercised and what you saw — not just "ran it".
