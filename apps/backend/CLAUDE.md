# Backend

The backend contract — read before touching anything under `apps/backend/`. Repo-wide rules (principles, workflow, cross-app standards) live in the root `CLAUDE.md`. Stack pack adopted? Read its `backend.md` appendix first — precedence rules in `stacks/README.md`. Examples below (JS-style filenames such as `container.js`, an Express/Fastify-style HTTP layer) are illustrative, not mandates.

The backend is an **onion**: a pure domain at the centre, wrapped by rings that depend inward toward it.

## The dependency rule

**Dependencies point inward. Nothing in an inner ring knows anything about an outer ring.**

- The domain depends on nothing; each outer ring depends only on the rings inside it.
- When an inner ring needs an outer capability (load data, send mail), it defines a **port** — an interface in a typed language, or an agreed duck-typed shape (optionally pinned with a JSDoc `@typedef`) in an untyped one. The implementation is supplied from outside (see *Wiring*), so the arrow still points inward.
- Data crosses boundaries translated: DTOs at the edge, domain objects inside. HTTP requests, database rows, and SDK objects never travel inward; the domain neither imports nor names them.
- Boundary test: what's outside (the database, the delivery mechanism) must be swappable without touching what's inside. If a change wants to point a dependency outward, reshape the change, not the rule.

## The four rings

From the centre out: **Domain → Service → Repo / Controller**. Repo and Controller are peer outer adapters; neither depends on the other.

### Domain — the core

The business expressed in code: entities, value objects, domain services, and the invariants true regardless of how the system is delivered or stored. Defines the **ports** the outer rings implement.

- **Depends on:** nothing. Pure and stateless — no I/O, no database handle, no clock, no network, no framework types.
- **Never:** performs I/O or names a specific technology.
- Express rules so they test in isolation — a rule testable only by standing up a database is mis-shaped.
- Validate state transitions against the rules **before** applying a status or lifecycle change — never merely because an external request, callback, message, or event asked for it.

Keep this ring small, dense, and protected.

### Service — use cases

Orchestrates one use case end to end: load through the domain's ports, invoke the domain, persist the result. Owns the transaction boundary — **one transaction per use case**.

- **Depends on:** the domain and the ports it defines — nothing concrete.
- **Never:** touches HTTP concepts, builds queries, or reaches for framework globals. Orchestration lives here; the rules live in the domain.

### Repo — adapters outward

Implements the ports: repositories backed by the database, plus clients for external services (storage, mail/SMS, payments). Each adapter carries a **mapper**, so storage and external shapes stop at this boundary.

- **Depends on:** the inner rings, to implement their ports.
- **Never:** holds business rules or decisions. Branching beyond what a query or call needs means a rule has leaked out of the domain.

### Controller — delivery inward

The edge: REST handlers, request/response DTOs, and the auth guards protecting them. A handler validates input, invokes **one** use case, and maps the result back out.

- **Depends on:** the service ring it invokes.
- **Never:** holds business logic, transactions, or queries, or reaches past the service into the repo ring.

## Folder layout

Organise **by feature first, layers within**: each domain area is a self-contained module owning its rings; add a ring's folder only when it earns one.

```
apps/backend/
├─ src/
│  ├─ modules/
│  │  └─ <feature>/       # one self-contained domain area (e.g. user, billing)
│  │     ├─ domain/       # entities, value objects, domain services, ports (contracts)
│  │     ├─ service/      # use cases — one per use case; owns the transaction boundary
│  │     ├─ repo/         # outward adapters: db repositories + external clients + mappers
│  │     ├─ controller/   # REST handlers, route definitions, guards
│  │     └─ dtos/         # request/response shapes — the module's edge contracts
│  ├─ shared/             # cross-module building blocks
│  │  ├─ aspects/         # cross-cutting decorators/plugins (auth, logging, tx, errors)
│  │  └─ utils/           # pure, stateless helpers — no I/O, no framework
│  └─ container.js        # composition root: wire port implementations to consumers
└─ tests/                 # mirrors src/ (or co-locate per module)
```

- A module never imports another module's inner rings — cross-module use goes through the other module's service or a shared port.
- Within a module, dependencies point inward: `controller/ → service/ → domain/`, and `repo/ → domain/` (implementing its ports).
- `shared/utils/` is pure and stateless — no I/O, no framework. `shared/aspects/` wrap a ring and depend inward only.

## Wiring

Ports are defined inside, implemented outside, and connected in one place — the **composition root** (`container.js`).

- An inner ring receives its dependencies as constructor or factory arguments; it never imports a concrete adapter.
- The composition root is the only place that knows both a port and its implementation; adapter swaps (real database → in-memory for a test) happen there and nowhere else.
- Manual constructor wiring by default; adopt a DI container only once the graph grows unwieldy.

## Testing the rings

Each ring maps to a kind of test; **most coverage sits in the fast inner rings**, thinning outward.

- **Domain — pure unit tests.** No mocks, no I/O. Assert the invariants and rules directly.
- **Service — use-case tests.** Drive the use case with in-memory fakes of the ports; assert orchestration and transaction boundaries, not the database.
- **Repo — integration tests.** Run against a real database / external sandbox; assert the mapper round-trips and the queries behave.
- **Controller — contract tests.** Assert status codes, validation rejection, auth guards, and request/response schemas.

## Verifying a change

Before calling a backend change done (the root's *verified means observed* gate):

- Run the touched module's tests.
- Exercise the endpoint over HTTP — the happy path plus at least one error path.
- Confirm the status code, error shape, and correlation id match the *Endpoint contract* and *Error responses* rules.
- State what you observed (which paths, what you saw), not just that you ran it.

## RESTful conventions

These govern the **controller** ring.

### Resource naming

- Plural, lowercase resource nouns.
- Hyphens for multi-word names.
- Model parent–child relationships in path segments.

```text
/users
/users/{userId}/orders
/payment-methods
```

### Visibility and versioning

- `/internal/v1` for internal APIs, `/external/v1` for external APIs.
- Default to internal when visibility is unclear.
- Do not expose an endpoint externally until its consumers, permissions, and contract are clear.

### Methods

- `GET` retrieve · `POST` create · `PUT` update (full-resource replace) · `DELETE` remove.
- No `PATCH` by default — `PUT` replaces the whole resource. Introduce `PATCH` only as a project-wide decision with documented merge semantics, never per-endpoint.
- Flag method/intent mismatches — `GET` that mutates, `POST` for plain retrieval without a clear reason.

### Pagination

- List endpoints use `page`, `recordsPerPage`, `sortBy`, `sortOrder` (`sortOrder` is `asc` or `desc`).
- List responses use one envelope: `{ "data": [<items>], "page": <n>, "recordsPerPage": <n>, "totalRecords": <total matching the filters> }`. `data` is always an array — an empty result is `200` with `[]`, never `404`.
- Place pagination and sorting parameters after resource-specific filters.
- Flag any endpoint that can return an unbounded collection with no pagination.

### Status codes

Use standard codes: `200` retrieved/updated, `201` created, `204` deleted (no body), `400` invalid request, `401` unauthenticated, `403` unauthorized, `404` not found, `409` conflict, `429` rate-limited (where limiting exists), `500` unexpected server error. Flag unclear or misleading codes.

### Error responses

Every error response uses one envelope, produced only by the single error-mapping site (see *Cross-cutting → Errors*):

```json
{ "error": { "code": "ORDER_NOT_FOUND", "message": "Order 123 was not found.", "correlationId": "<id>" } }
```

- **`code`** — stable, machine-readable, `SCREAMING_SNAKE_CASE`, named in domain terms. Clients branch on `code`; they never parse `message`.
- **`message`** — human-readable and safe: no stack traces, SQL, or internal identifiers.
- **`correlationId`** — the request's correlation id. It also travels as the **`x-correlation-id` response header on every response**, success or failure.
- Validation failures (`400`) may add `error.details`: a list of `{ "field": <name>, "message": <why> }` entries.

Success shapes: a single resource is returned as the bare object (no wrapper); lists use the pagination envelope above.

### Endpoint contract

Each endpoint defines its required permissions, request schema, response schema, validation rules, and error behaviour. Each request field defines its name, type, required/optional status, description, and validation constraints.

## Cross-cutting concerns

Concerns that touch every request — auth, context, logging, transactions, error mapping — are **decorators / aspects**: declared once and applied declaratively to the ring they wrap, so a handler or use case carries only its own logic. Scope each aspect to the subtree that needs it, not globally. Each aspect obeys the dependency rule — it lives in its ring and passes data inward only as plain values.

- **Auth:** guards at the controller ring reject unauthenticated requests at the edge; authorisation that depends on domain state lives in the domain or use case.
- **Request context / identity:** established at the edge, passed inward as an argument — never read from a global by an inner ring.
- **Transactions:** the boundary wraps the use case (see *Service*).
- **Logging:** one shared path carrying the request's correlation id, so a request traces end to end. Emit structured key/value records at levels — `error` for handled failures, `warn` for recoverable anomalies, `info` for state changes, `debug` behind a flag. Never log secrets, tokens, credentials, auth headers, or PII — redact at the logging boundary and log identifiers (e.g. a user id), not payloads. Log a failure once, where it is handled.
- **Audit trail:** distinct from operational logging — logs rotate and aren't queryable as history. Record every meaningful state change (actor, action, target, and the before/after where it matters) through **one shared `record()` call** in the service ring, invoked by the use case that owns the change, to durable queryable storage, carrying the correlation id.
- **Errors:** the domain raises failures in domain terms; the controller ring is the single place that maps them onto the *Error responses* envelope — one shape app-wide.

## Integrations

Treat every external API, callback, webhook, queue, and event as untrusted and unreliable. The integration code is a repo-ring adapter; the decisions it enforces belong to the domain.

- **Idempotency:** handle repeated requests, retries, and replays without duplicating actions or overwriting valid results; key on the primary business record id unless a clearer business key exists.
- **Concurrency:** assume several workers may process the same record at once; use conditional updates, locking, transactions, or version checks.
- **Validation:** validate structure, required fields, types, business rules, authenticity, and ownership before sending or applying anything.
- **Ordering:** where order matters, process by event time, sequence/version number, or business rule — not arrival order.
- **Failure handling:** classify failures as transient, permanent, invalid, unsupported, duplicate, or unknown; retry only transient ones, with bounded retries, backoff, and a defined final-failure path.
- **Unclear outcomes:** never treat a timeout, transport error, or malformed/ambiguous response as success; preserve existing valid data and route the outcome to reconciliation or manual recovery.
- **Risky integrations** — anything that spends money or reaches real users (SMS/email/payment/push) — ship behind a **default-off** validated-config boolean (root *Configuration*), read in one place, routing to a no-op sink when off. Exercise against the sink until the flag flips on per environment; flipping it back off is the instant rollback. This flag underpins the **test-mode** and **otp-auth** add-ons (`add-ons/`).

## Security baseline

Beyond edge validation and the auth guards above:

- **Parameterised data access:** pass query parameters as bound values; never interpolate request data into a query or filter string.
- **Secrets from the environment:** never hardcoded, committed, or echoed in errors/logs; inner rings receive config as injected values, not by reading globals.
- **Ownership:** verify ownership on every client-supplied id before acting on the record — on ordinary requests, not just the webhooks *Integrations* covers.
- **Security response headers:** send the standard hardening headers — transport security, content-type and framing protections, a referrer policy, and (where the app serves HTML) a **Content-Security-Policy** — from one shared place. Roll out a new or tightened CSP **report-only** first; promote to enforcing once the violation reports are clean. Exact header set + mechanism: the active stack pack.
- **SSRF guard on user-supplied URLs:** when the app fetches a URL a user or admin configured (a webhook target, an import source), allow only permitted schemes and **public** hosts; reject loopback, private, link-local, and cloud-metadata targets before the request leaves — validated when the URL is saved *and* re-checked at call time. Concrete check: the active stack pack.
- **Secrets stored through the API are write-only:** never return a stored secret on read — expose only a "configured" indicator — and treat a blank value on update as "keep the existing secret". Concrete masking/merge: the active stack pack.

## Coding standards

- Dates/timezones, phone canonicalisation, identifiers, CSV, and schema validation use an established library via a single shared helper — never hand-rolled (root *Don't reinvent existing solutions*).
- Schema changes are reversible migrations under `db/` — never issue DDL or alter schema from application code; repo adapters read the schema, never mutate it. See `db/CLAUDE.md`.
