# Django 5 + DRF — backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Binds `apps/backend/CLAUDE.md` (the onion) and the root `CLAUDE.md` to **Django 5 + Django REST Framework, Python 3.12, managed with uv**. Read those first; this file does not restate them.

## Scope

This file owns the Django app layout, the DRF edge, config, cross-cutting aspects, and backend testing. Migrations, schema conventions, and query/transaction mechanics → `./db.md`. Rejected alternatives for the tool picks are in the pack README → *Pack decisions*.

## Stack binding at a glance

- **API layer: Django REST Framework** on Django 5 — views, routers, serializers, permissions, throttles.
- **Language: Python 3.12, dependencies via uv** (`uv sync`, `uv run`, committed `uv.lock`).
- **Lint: ruff (check + format). Typecheck: mypy with django-stubs + djangorestframework-stubs** — the root `typecheck` verb is real here, not a no-op.
- **Validation: DRF serializers at the API edge** — a module's serializers are its `dtos/` in Django form: request parsing/validation in, response shaping out. Business rules stay in services/models, never in a serializer's `validate_*`.

## Layout — Django apps are the feature modules

The base `modules/<feature>/{domain,service,repo,controller,dtos}` shape is **replaced** by the idiomatic layout real Django codebases use (see conflict register):

```
apps/backend/
├─ manage.py
├─ pyproject.toml / uv.lock
├─ config/                # the Django project: settings.py, urls.py, asgi.py
└─ <feature>/             # one Django app per domain area (e.g. users, billing)
   ├─ models.py           # ORM models + model-level invariants (constraints, clean())
   ├─ services.py         # write use cases — one function per use case; owns transaction.atomic
   ├─ selectors.py        # read paths — queries composed for the API, no side effects
   ├─ api/                # serializers.py, views.py, urls.py — the delivery edge
   ├─ migrations/         # this app's Django migrations (→ ./db.md)
   └─ tests/
```

- The dependency direction still points one way: `api/ → services.py / selectors.py → models.py`. A view never calls the ORM directly and never holds business logic — it validates with a serializer, invokes **one** service/selector, and shapes the response.
- Cross-app use goes through the other app's `services.py`/`selectors.py`, never its models or managers directly.
- **External gateways** (mail, SMS, payments) are adapter modules (`<feature>/gateway.py`, or a shared `gateways/` package) selected by the base default-off validated flags; services call the adapter, never an SDK. Tests swap the adapter at that seam.

## Cross-cutting — middleware + DRF hooks are the aspects

| Base concern | Binding |
|---|---|
| Config | all env reads live in `config/settings.py` via **django-environ**, validated at import: required keys declared with types and no production defaults, so a missing or malformed value fails at boot with a named error — the base *Configuration* rule, bound. App code reads `django.conf.settings` (see conflict register); `os.environ` appears **only** in `settings.py`; `.env.example` stays canonical |
| Errors | one custom DRF `EXCEPTION_HANDLER` mapping domain exceptions → the base envelope (`error.code`/`message`/`correlationId`); `IntegrityError` unique violations → `409` |
| Request context | one middleware seeds the correlation id per request, sets the `x-correlation-id` response header, and binds it into logging |
| Auth | Django **session auth** (signed HTTP-only cookies — the base default, unchanged) via DRF `SessionAuthentication` + permission classes; CSRF stays on (the SPA sends `X-CSRFToken` — `./frontend.md`) |
| Transactions | `transaction.atomic` wrapping each write use case in `services.py` — one per use case; **not** `ATOMIC_REQUESTS`, which moves the boundary to the view (wrong ring) |
| Logging | structured JSON logging (dictConfig or structlog) carrying the correlation id |
| Security headers | `SecurityMiddleware` settings (HSTS, nosniff, referrer policy, frame deny); CSP only where Django itself serves HTML |
| Rate limiting | DRF throttle classes on the views that need them, backed by Django's cache framework — **database cache backend** by default, no Redis until a limit must be globally exact and fast |

- **Routing:** each app's `api/urls.py` is included under one `internal/v1/` prefix in `config/urls.py`, plus one unauthenticated `/health` — the base visibility/versioning rule as URLconf structure. The browser reaches it as `/api/...` through the frontend proxy (`./frontend.md`).
- **SSRF guard** (base *Security baseline*) — one shared validator: resolve the host, reject loopback/private/link-local/metadata IPs. It runs at config-save *and* immediately before the outbound request.
- **Write-only secrets** (base *Security baseline*) — secret-bearing serializers mask on read (value → `…Set` flag) and preserve the stored value when the update field is blank.
- **Contract artifact:** **drf-spectacular** generates the OpenAPI schema from the serializers/views — the shared contract the frontend generates types from; never hand-copy shapes.

## Testing

- **Runner: pytest + pytest-django** (`uv run pytest`).
- Base per-ring kinds, bound: **model invariants + pure helpers** — plain units, no DB where possible; **services/selectors** — `pytest.mark.django_db` tests against real Postgres (the ORM *is* the persistence layer — faking it tests nothing); **API** — DRF `APIClient` contract tests asserting status codes, envelope shape, and auth guards. Gateways are faked at the adapter seam, never by patching ORM or framework internals.

## Add-on bindings (if adopted)

- **test-mode** (`add-ons/test-mode/`): one middleware resolves the mode signal from an inbound header onto the request — fail closed: missing or unknown means production. In test mode the flag-gated gateways (the base default-off booleans) route to their sinks — Django's `console.EmailBackend` is the canonical email sink; other gateways ship a structured-log/no-op adapter. The test-user picker is an unauthenticated DRF view gated on the same signal; it returns `[]` in production, and an `APIClient` test asserts that.
- **otp-auth** (`add-ons/otp-auth/`) — model A (self-managed):
  - **Storage** — an `OtpChallenge` model (hashed code, short TTL, `purpose` field) in its own Django app with its own migrations.
  - **Verify** — hashing in a shared util, with `django.utils.crypto.constant_time_compare` for the timing-safe verify; verify is never stubbed in test mode.
  - **Double-submit race** — a unique constraint on (target, purpose); `IntegrityError` → `409` through the shared exception handler.
  - **Delivery** — through the gateway adapters behind the default-off flags; in test mode delivery sinks to the structured log, where the tester reads the real code.
  - **Phone numbers** — canonicalised to E.164 with the **`phonenumbers`** library.
  - **Rate limits** — send/verify are DRF throttles on those views (database cache backend — no separate store on this pack); the per-challenge attempt cap lives on the challenge row.

## Conflict register

- **Base says:** each feature module holds four rings — `domain/`, `service/`, `repo/`, `controller/`, `dtos/` — with a pure, framework-free domain at the centre. **In this stack:** a feature is a **Django app** — `models.py` / `services.py` / `selectors.py` / `api/` — and the centre is not framework-free: invariants live on ORM models (constraints, `clean()`, model methods) and in service functions. **Because:** Django's app registry, ORM, admin, and migrations all key off the app layout; a parallel pure-domain layer over active-record models duplicates every entity and drifts — the services/selectors convention is how real Django shops keep the discipline without a fake hexagon. **Concretely:** DO put every write use case in `services.py` and every read composition in `selectors.py`; DON'T create `domain/`/`repo/` folders or entity classes that mirror models.
- **Base says:** inner rings define ports, the repo ring implements them, and the composition root (`container.js`) wires implementations at boot. **In this stack:** there is no repo ring and no container — the **ORM manager/QuerySet is the persistence API**, called directly from `services.py`/`selectors.py`; only external gateways keep a swap seam (an adapter module selected by validated flags, faked at that seam in tests). **Because:** the Django ORM is active record; wrapping managers in hand-rolled repositories plus a DI container re-implements what the framework already centralises, at a cost the base's YAGNI rule forbids. **Concretely:** DON'T add a `container.py` or `*Repository` classes that proxy managers; DO route every external side effect through a gateway module so tests swap one factory, not framework internals.
- **Base says:** no inner layer reads config directly — it is passed inward as values, read from the environment in one place (root *Configuration*; backend *Security baseline*). **In this stack:** the one place is `config/settings.py` (django-environ, validated at import), and code anywhere may read `django.conf.settings` — the framework-blessed global. **Because:** Django and every third-party app read `settings` by construction; threading values as parameters would fork a second config path alongside an unavoidable one. **Concretely:** DO read config only via `django.conf.settings`; an `os.environ` read anywhere outside `settings.py` is the greppable violation.
