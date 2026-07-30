# Add-on: LLM calls

Use this add-on when a product feature calls an LLM or another generative AI API. Model calls spend money, may expose sensitive data, and return untrusted output.

## Requirements

- Set input and output token limits, a timeout, and bounded retries on every call.
- Set a maximum step count for agentic flows and prevent unbounded parallel calls.
- Put the provider SDK in an outer-layer adapter behind a port. Keep product decisions in the domain or use case.
- Classify failures with the base integration rules. Never treat a timeout, malformed response, or unknown outcome as success.
- Treat prompts, files, retrieved pages, tool results, and model output as untrusted data.
- Do not let retrieved content override system rules or tool permissions.
- Validate structured output and tool arguments against declared schemas.
- Apply normal authorisation to every tool action.
- Never execute generated code unless the product explicitly provides a sandbox for it.
- Send only the data the feature needs. Remove secrets and unnecessary personal data at the call site.
- Apply the project's retention policy to stored prompts and responses.
- Redact prompts and responses in logs, or log a reference instead.
- Pin the model identifier or version in validated configuration. Treat a model change as a behaviour change and test it before rollout.
- Put live calls behind the base default-off integration flag. Use a canned response that follows the same output schema while the flag is off.

Record feature, model, tenant or user, tokens, cost, duration, outcome, failure class, and correlation ID for every call. Make usage queryable by feature and tenant or user.

## Verify

Test limits, timeouts, retries, malformed output, tool authorisation, safe logging, and routing to the canned-response sink.

## Binds to a stack

The active stack pack identifies:

- the provider SDK and adapter location;
- the canned-response sink and schema validator;
- configuration for model, limits, and rollout;
- cost, usage, latency, and failure monitoring.

## Interactions

- **Base integrations and configuration:** apply their retry, idempotency, failure, rollout, and validation rules.
- **test-mode:** use the canned-response sink.
- **multi-tenancy:** attach usage and cost to the active tenant.
- **saas-billing:** send eligible AI usage to the billing meter.
