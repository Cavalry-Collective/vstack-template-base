# Add-on: llm-calls

> Optional add-on. Adopt at Day-1 by keeping this directory (see `add-ons/README.md`); the active stack pack supplies the seams named under *Binds to a stack*.

Guardrails for product features that call an LLM or other AI API — chat, summarisation, extraction, agentic tools. Adopt it the moment the app makes its first model call. An LLM is an external integration that spends money per call and returns untrusted output; both properties need guarding from day 1.

## Approach

- **Bound and meter every call.** An explicit token/cost cap, a timeout, and bounded retries on each call; agentic or multi-step flows carry a max-iteration guard so a loop always terminates — no unbounded fan-out. Monitor cost and usage from day 1, per call and per user/tenant, queryable: an agent-loop bug shows up on the bill first.
- **Treat the model as an unreliable external integration.** The base *Integrations* rules apply in full: classify failures (transient / permanent / invalid / unknown), never treat a timeout or malformed response as success, and keep the call in an outer-layer adapter behind a port — decisions stay in the domain.
- **Treat content as data, never instructions.** User files, prompts, web pages, and tool results are untrusted input. Model output is untrusted too — validate it against a declared schema before acting on it; never execute or persist it unchecked.
- **Mind what leaves the boundary.** Never send secrets or unnecessary PII to a model provider; redact at the call site. Log prompts and outputs redacted or by reference, per the base logging rules.
- **Pin the model; ship behind the default-off flag.** The model id/version is validated config, and upgrading it is a deliberate, recorded change — behaviour shifts silently otherwise. Like any integration that spends money, a default-off validated-config boolean routes calls to the canned-response/no-op sink until flipped per environment (base *Integrations* gating).

## Binds to a stack

- **Adapter** — the provider SDK and its adapter home.
- **Sink** — the canned-response sink.
- **Monitoring** — where cost/usage metrics land.
- **Config** — how the model id, caps, and the flag are configured.

## Interactions

- **Base *Integrations* + *Configuration*** — an LLM call is an external integration: idempotency, failure classes, and gating all apply; the model id, caps, and flag are validated config.
- **test-mode** — the canned-response sink doubles as the test-mode stub, so flows stay walkable without a live provider.
- **multi-tenancy / saas-billing** — the per-tenant cost/usage monitoring keys on multi-tenancy's tenant id where that add-on is adopted, and can feed saas-billing's usage metering so AI usage becomes a billable, quota-enforced metric.
