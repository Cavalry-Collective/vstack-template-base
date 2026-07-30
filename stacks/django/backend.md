# Django and DRF: backend appendix

> Rides on top of the base contract; this file only adds stack bindings and resolves conflicts. Where this appendix and a base file disagree, the conflict register below wins — for this stack only.

Bind the backend to Django 5, Django REST Framework, Python 3.12, and uv.

## Bindings

| Concern | Binding |
|---|---|
| HTTP | DRF views, serializers, permissions, throttles |
| Dependencies | uv with committed `uv.lock` |
| Quality | ruff, mypy, django-stubs, DRF stubs |
| Validation | DRF serializers at the API edge |
| Contract | drf-spectacular OpenAPI |
| Tests | pytest and pytest-django |

## Application structure

Use one Django app per feature:

```text
<feature>/
├── models.py
├── services.py
├── selectors.py
├── api/
│   ├── serializers.py
│   ├── views.py
│   └── urls.py
├── migrations/
└── tests/
```

- Put write use cases and transaction boundaries in `services.py`.
- Put side-effect-free read compositions in `selectors.py`.
- Keep views thin: validate, call one service or selector, and shape the response.
- Access another app through its services or selectors rather than its models.
- Put external providers behind gateway modules selected by validated integration flags.

## Framework bindings

| Base concern | Django binding |
|---|---|
| Configuration | django-environ in `config/settings.py`; no other `os.environ` reads |
| Errors | one DRF exception handler producing the base envelope; unique `IntegrityError` becomes the domain conflict response |
| Request context | middleware for correlation ID, header, and logging |
| Authentication | Django sessions, DRF `SessionAuthentication`, CSRF enabled |
| Transactions | `transaction.atomic` inside write services |
| Logging | structured logging carrying the correlation ID |
| Security headers | Django `SecurityMiddleware` settings |
| Rate limiting | DRF throttles backed by Django's cache framework |

- Do not enable `ATOMIC_REQUESTS`.
- Use a database cache by default. Add Redis only when a global limit needs it.
- Include each app's API URLs under `/internal/v1` and keep `/health` unversioned.
- Keep CSRF on and let the frontend send `X-CSRFToken`.
- Generate OpenAPI from DRF and never hand-copy the frontend contract.

## Testing

- Test model invariants and pure helpers without a database where possible.
- Test services and selectors against real Postgres with `pytest.mark.django_db`.
- Test the API with DRF `APIClient`.
- Fake external providers at the gateway seam.

## Conflict register

- **Base says:** every feature uses framework-free domain, service, repository, controller, and DTO rings. **In this stack:** one Django app uses models, services, selectors, and `api/`; model invariants may use the ORM. **Because:** Django's registry, ORM, admin, and migrations are organised around apps and active-record models. **Concretely:** DO put writes in `services.py` and reads in `selectors.py`; DON'T mirror models into a separate domain or repository layer.
- **Base says:** domain ports and a composition root isolate persistence. **In this stack:** services and selectors call the Django ORM directly; only external providers retain gateway seams. **Because:** repository wrappers and a second DI container would duplicate the active-record API. **Concretely:** DON'T add `container.py` or repository proxies; DO isolate every external side effect behind a gateway module.
- **Base says:** inner layers receive configuration as values. **In this stack:** `config/settings.py` is the only environment reader and application code may read `django.conf.settings`. **Because:** Django and its extensions use the settings object by design. **Concretely:** DO read configuration through `django.conf.settings`; DON'T read `os.environ` outside `settings.py`.
