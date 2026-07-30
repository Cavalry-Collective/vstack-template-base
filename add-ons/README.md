# Optional add-ons

Add-ons provide opinionated guidance for capabilities that do not belong in every project, such as multi-tenancy, billing, and OTP authentication. Each add-on is documentation only and remains independent of frameworks, providers, and cloud services.

## Adoption

Choose add-ons during Day-1 setup:

1. Keep each add-on the project needs.
2. Delete the directories it does not need.
3. Read every retained add-on before planning or changing the capability it covers.

Every directory retained under `add-ons/` is adopted.

## Add-ons and stack packs

A project may adopt zero or more add-ons and exactly one stack pack.

- An add-on defines what the capability must do.
- The active stack pack defines how the chosen stack implements it.
- **Binds to a stack** lists the concrete answers the stack must provide.

Record those answers in the requirement spec for the feature. Do not put framework-specific instructions or per-stack appendices in an add-on.

## Requirement specs

Add-ons are guidance, not project requirements. Before implementing a non-trivial area, write a spec under `specs/` that:

- defines what the project will build;
- covers the relevant implementation areas;
- records the active stack bindings;
- follows `specs/README.md`.

## Authoring rules

Every add-on states its purpose, implementation rules, verification, stack bindings, and interactions. It states prerequisites when another capability is required.

- State the default implementation rather than listing common alternatives.
- Use direct instructions and one rule per bullet.
- Include the safeguards needed to avoid predictable security, data, and operational failures.
- Put concrete stack choices in the active stack pack.
- State each rule once.
- Keep the document easy to scan and under about 150 lines.

## Available add-ons

| Add-on | Capability | Stack pack supplies |
|---|---|---|
| [`test-mode/`](test-mode/README.md) | Replace external side effects with safe test sinks | mode signal, sinks, gated test-user read |
| [`otp-auth/`](otp-auth/README.md) | Passwordless login and contact verification by code | challenge store or provider, delivery, canonicalisation |
| [`llm-calls/`](llm-calls/README.md) | Guard product features that call an LLM | provider adapter, response sink, usage monitoring |
| [`premium-design/`](premium-design/README.md) | Add art direction, motion, and a higher craft bar | motion, fonts, asset pipeline |
| [`enterprise-compliance/`](enterprise-compliance/README.md) | Add enterprise security, privacy, recovery, and governance controls | identity, KMS, audit storage, jobs, backups |
| [`multi-tenancy/`](multi-tenancy/README.md) | Isolate organisations within one deployment | tenant guard, scoped data access, storage, client context |
| [`saas-billing/`](saas-billing/README.md) | Add plans, subscriptions, entitlements, seats, and usage | payment adapter, webhooks, jobs, test sink |
| [`seo/`](seo/README.md) | Make public pages crawlable and indexable | server rendering, metadata, redirects, sitemap |

## Add an add-on

1. Create `add-ons/<capability>/README.md`.
2. Follow the structure and authoring rules above.
3. Add the capability to the table in this file.

Use a lowercase, hyphenated name such as `test-mode`.
