# Backend

The backend contract — read before touching anything under `apps/backend/`. Repo-wide rules (principles, workflow, cross-app standards) live in the root `CLAUDE.md`. Stack: not yet chosen (see the root `CLAUDE.md`). **If a stack pack is adopted (a single directory kept under `stacks/`), also read its `backend.md` appendix before working here** — it adds the concrete bindings, and its conflict register resolves any disagreement with this file, for that stack only. The examples below use JS-style filenames (`container.js`) and an Express/Fastify-style HTTP layer **illustratively**; treat file extensions and framework specifics as examples, not mandates — the same way `apps/frontend/CLAUDE.md` does.

The backend is an **onion**: a pure domain at the centre, wrapped by rings that depend inward toward it. Everything below follows from that.

## The dependency rule

**Dependencies point inward. Nothing in an inner ring knows anything about an outer ring.**

- The domain depends on nothing; each outer ring depends only on the rings inside it.
- When an inner ring needs an outer capability (load data, send mail), it defines the **contract** — a "port" — and an outer ring provides the implementation. A port is a documented set of method signatures: in a language with first-class interfaces (e.g. TypeScript) express it as an interface; in one without (e.g. plain JS) express it as an agreed shape honoured by duck typing and optionally pinned with a JSDoc `@typedef`. Either way the implementation is supplied from outside (see *Wiring*), so the dependency is inverted and the arrow still points inward.
- Data crosses in translated form: DTOs at the edge, domain objects inside. Outer-ring types — HTTP requests, database rows, SDK objects — never travel inward; the domain neither imports nor names them.

Test any boundary: can you swap what's outside (the database, the delivery mechanism) without touching what's inside? If not, something has leaked. If a change wants to point a dependency outward, reshape the change, not the rule.

## The four rings

From the centre out: **Domain → Service → Repo / Controller**. Repo and Controller are both outer adapters; neither depends on the other. The outer three keep the project's familiar controller / service / repo names; the domain at the centre is the DDD core they build on.

For each ring: what it holds, what it may depend on, what it must never do.

### Domain — the core

The business expressed in code: entities, value objects, domain services, and the invariants and rules true regardless of how the system is delivered or stored. It also defines the **ports** — the repository and gateway contracts the outer rings implement.

- **Depends on:** nothing. Pure and stateless — no I/O, no database handle, no clock, no network, no framework types.
- **Never:** performs I/O or names a specific technology. A rule that can only be tested by standing up a database is in the wrong shape — express it so it can be tested in isolation.

Keep this ring small, dense, and protected. It's the part worth defending.

### Service — use cases

Orchestrates one use case end to end: load through the domain's repository ports, invoke the domain, persist the result. Owns the transaction boundary — **one transaction per use case**.

- **Depends on:** the domain and the ports it defines — nothing concrete.
- **Never:** touches HTTP/web concepts, builds queries, or reaches for framework globals. Orchestration lives here; the *rules* live in the domain.

### Repo — adapters outward

Concrete implementations of the ports the inner rings define: repositories backed by the database, plus clients for external services (storage, mail/SMS, payments, translation). Each adapter carries a **mapper** that translates between the outside shape (a DB row, an external payload) and domain objects — so storage shapes stop at this boundary.

- **Depends on:** the inner rings, to *implement* their ports.
- **Never:** holds business rules or decisions. Adapters move and translate data across the boundary; branching beyond what a query or call needs means a rule has leaked out of the domain.

### Controller — delivery inward

The edge where the outside world meets the app: REST handlers, request/response DTOs, and the auth guards protecting them. A handler validates input, invokes **one** use case, and maps the result back out.

- **Depends on:** the service ring it invokes.
- **Never:** holds business logic, transactions, or queries, or reaches past the service into the repo ring.

## Folder layout

Organise **by feature first, layers within**: each domain area is a self-contained module owning its four rings, with shared building blocks and the wiring beside the modules. (A small module needn't use every folder — add a ring's folder when it earns one.)

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

A module never imports another module's inner rings — cross-module use goes through the other module's service or a shared port. Within a module, dependencies point inward: `controller/ → service/ → domain/`, and `repo/ → domain/` (implementing its ports). `shared/utils/` depends on nothing; `shared/aspects/` wrap a ring and depend inward only.

## Wiring

Ports are defined inside, implemented outside, and connected in one place — the **composition root** (`container.js`). This is how the backend does dependency inversion (see *The dependency rule* for the typed/untyped port forms): the contract is the agreed method shape, and the concrete implementation is supplied at boot.

- An inner ring receives its dependencies (a constructor argument or factory parameter); it never `import`s a concrete adapter directly.
- The composition root is the only place that knows both a port and its implementation. Swapping an adapter (real database → in-memory for a test) is a change there and nowhere else.
- Keep wiring out of the rings — it is glue, not logic. Manual constructor wiring is enough; reach for a DI container (e.g. Awilix) only once the graph grows unwieldy.

## Testing the rings

The architecture exists to make testing cheap — exploit it. Each ring maps to a kind of test; **most coverage sits in the fast inner rings**, thinning outward.

- **Domain — pure unit tests.** No mocks, no I/O (the ring forbids I/O, so its tests need none). Assert the invariants and rules directly.
- **Service — use-case tests.** Drive the use case with in-memory fakes of the ports (the composition-root swap described in *Wiring*); assert orchestration and transaction boundaries, not the database.
- **Repo — integration tests.** Run against a real database / external sandbox; assert the mapper round-trips and the queries behave.
- **Controller — contract tests.** Assert status codes, validation rejection, auth guards, and request/response schema (see *Endpoint contract* and *Status codes*).

## Verifying a change

Before calling a backend change done (the root's *verified means observed* gate):

- Run the test suite for the touched module.
- Exercise the actual endpoint over HTTP — the happy path plus at least one error path.
- Confirm the status code, error shape, and correlation id match the *Endpoint contract* and *Cross-cutting* error rules already defined here.

State what you observed (which paths you exercised, what you saw), not just that you ran it.

## RESTful conventions

These govern the **controller** ring — the default API contract; prefer a more specific project rule where one exists.

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
- **`message`** — human-readable and safe: no stack traces, SQL, or internal identifiers (what users actually read is governed by the frontend's error-copy rules).
- **`correlationId`** — the request's correlation id. It also travels as the **`x-correlation-id` response header on every response**, success or failure; the body field is the copy the frontend surfaces (see *Cross-app conventions* in `apps/frontend/CLAUDE.md`).
- Validation failures (`400`) may add `error.details`: a list of `{ "field": <name>, "message": <why> }` entries.

Success shapes for symmetry: a single resource is returned as the object itself (no wrapper); lists use the pagination envelope above.

### Endpoint contract

Each endpoint defines its required permissions, request schema, response schema, validation rules, and error behaviour. Each request field defines its name, type, required/optional status, description, and validation constraints.

## Cross-cutting concerns

Concerns that touch every request — auth, context, logging, transactions, error mapping — are implemented as **decorators / aspects (AOP)**: declared once and applied declaratively to the ring they wrap, so a handler or use case carries only its own logic. In Node this is the framework's middleware/plugin layer — Express middleware, or Fastify plugins plus lifecycle hooks and decorators. **Scope each aspect to the subtree that needs it** — register it on the plugin/router branch it applies to, not globally, so unrelated routes stay clean. Each aspect still obeys the dependency rule — it lives in its ring and passes data inward only as plain values.

- **Auth:** guards at the controller ring reject unauthenticated requests at the edge; rule-level authorisation that depends on domain state lives in the domain or use case.
- **Request context / identity:** established at the edge, passed inward as an argument — never read from a global by an inner ring.
- **Transactions:** the boundary wraps the use case (see Service).
- **Logging & audit:** one shared path carrying the request's correlation id, so a request traces end to end. Keep it out of the domain. Emit **structured records** (key/value fields, not concatenated strings) at meaningful **levels** — `error` for handled failures, `warn` for recoverable anomalies, `info` for state changes, `debug` behind a flag for diagnostics. **Never log secrets, tokens, credentials, auth headers, or PII; redact at the logging boundary** and log identifiers (e.g. a user id) rather than payloads. Log a failure **once**, where it is handled — not at every ring on the way out (re-logging the same error is the noise the root Principles forbid).
- **Audit trail:** when the app must answer *who changed what* (permission or role changes, contact-detail edits, moderation, money movement), that is a concern **distinct** from operational logging — logs rotate and aren't queryable as history. Record every meaningful state change through **one shared `record()` call** in the service ring — actor, action, target, and the before/after where it matters — to durable, queryable storage, carrying the request's correlation id. One call site per state change, invoked by the use case that owns the change; not scattered inserts, and not the log stream.
- **Errors:** the domain raises failures in domain terms; the controller ring is the single place that maps them onto transport responses, using the *Error responses* envelope — one shape app-wide.

## Standards reference

### Business rules

- Validate state transitions against the rules **before** applying a status or lifecycle change — never because an external request, callback, message, or event asked for it.

### Integrations

Treat every external API, callback, webhook, queue, and event as untrusted and unreliable. The integration code is a repo-ring adapter; the decisions it enforces belong to the domain.

- **Idempotency:** handle repeated requests, retries, and replays without duplicating actions or overwriting valid results. Use the primary business record id as the idempotency key unless a clearer business key exists.
- **Concurrency:** assume several workers may process the same record at once. Use conditional updates, locking, transactions, or version checks.
- **Validation:** validate structure, required fields, types, business rules, authenticity, and ownership before sending or applying anything.
- **Ordering:** where order matters, process by event time, sequence/version number, or business rule — not arrival order.
- **Failure handling:** classify failures as transient, permanent, invalid, unsupported, duplicate, or unknown. Retry only transient ones, with bounded retries and backoff, and a defined final-failure path.
- **Unclear outcomes:** never treat a timeout, transport error, malformed or unexpected response, or ambiguous result as success. Preserve existing valid data and route the outcome to reconciliation or manual recovery.
- **Gate a risky integration behind a default-off flag with a no-op sink.** An integration that spends money or reaches real users (SMS/email/payment/push) ships behind a **default-off** validated-config boolean (root *Configuration*), read in **one** place, that routes to a **stdout / no-op sink** when off. Exercise it against the sink until you flip the flag on per-environment; flipping it back off is the instant rollback. (This flag underpins the optional **test-mode** and **otp-auth** add-ons — see `add-ons/`.)

### Security baseline

The edge already validates input (the handler validates input; *Endpoint contract* defines validation rules) and places authorisation (edge guards reject unauthenticated requests; rule-level authz that depends on domain state lives in the domain / use case — see *Cross-cutting → Auth*). Add the rules that aren't yet stated:

- **Parameterised data access:** pass query parameters as bound values; never interpolate request data into a query/filter string.
- **Secrets from the environment:** secrets and config come from the environment, never hardcoded, committed, or echoed in errors/logs; inner rings receive config as injected values, not by reading globals.
- **Ownership:** verify ownership on every client-supplied id before acting on the record — make this explicit for ordinary requests, not just the webhooks the *Integrations* rules already cover.
- **Security response headers:** send the standard HTTP hardening headers — transport security, content-type and framing protections, a referrer policy, and (where the app serves HTML) a **Content-Security-Policy** — from one shared place. Roll out a new or tightened CSP in **report-only** mode first, then promote it to enforcing once the violation reports are clean; an enforcing CSP shipped blind breaks inline styles and third-party embeds. (Exact header set + mechanism: the active stack pack.)
- **Guard server-side requests to user-supplied URLs (SSRF):** when the app fetches a URL a user or admin configured (a webhook target, an import source), restrict it to allowed schemes and **public** hosts and reject internal targets (loopback, private, link-local, cloud-metadata) **before** the request leaves — validated when the URL is saved *and* re-checked at call time. (Concrete check: the active stack pack.)
- **Secrets stored through the API are write-only:** never return a stored secret on read — expose only a "configured" indicator — and treat a blank value on update as "keep the existing secret", so re-saving a form never clears one the user didn't retype. (Concrete masking/merge: the active stack pack.)

## Coding standards

- **Don't reinvent libraries** (full rule: root `CLAUDE.md` Principles, *Don't reinvent existing solutions*). Backend specifics worth repeating in-context: dates/timezones, phone canonicalisation, identifiers, CSV, and schema validation all use an established library and a single shared helper — never a hand-rolled one.
- **Schema changes are reversible migrations under `db/`** — never issue DDL or alter schema from application code; the repo ring's adapters read the schema, they don't mutate it. See `db/CLAUDE.md`.
