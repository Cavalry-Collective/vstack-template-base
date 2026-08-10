# Add-on: LLM calls

Use this add-on when a product feature calls an LLM or another generative AI API. Model calls spend money, may expose sensitive data, and return untrusted output.

## Requirements

- Set input and output token limits on every call.
- Execute every call by the rules in *Inference execution* below.
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

## Inference execution

There are three ways to run an inference call:

- **Regular:** one request, response returned whole.
- **Streaming:** one streamed request held open until the model finishes. The caller waits on the connection and sees tokens as they arrive.
- **Asynchronous:** a background job. The caller gets a job id immediately; a worker makes the call and stores the result, and the caller reads job state later.

Pick by how long the call can run and who is waiting:

- Use regular for short calls whose worst case completes within about 30 seconds.
- Use streaming for anything longer, and whenever a person watches the output. A streamed call can safely run for minutes, up to the platform's request duration ceiling.
- Use asynchronous when streaming cannot work: the call can outlast the ceiling, no client is waiting for the result, or the client may disconnect and return later.

### Rules for every mode

Never wrap an inference call in a timeout-and-retry loop: a retried call re-runs work the provider may already have completed and billed.

- Set one explicit per-call timeout above the model's worst-case completion time, and turn off the SDK's automatic retry of timeouts.
- Never retry after the model has started generating. The outcome is unknown: the provider may have completed and billed the call. Route it to the base unclear-outcome path.
- Retry only failures that occur before generation starts: connection errors, rate limits, and overload responses. Bound the attempts at two or three, with backoff.

### Regular inference

- Keep it short. Past about 30 seconds, idle timers in proxies and load balancers cut a buffered response before it arrives; when in doubt, stream.

### Streaming inference

- Consume the stream even when only the final result matters. Streamed tokens reset the idle timers along the path, so the connection stays open for the whole generation.
- When a person is waiting, stream end to end: provider to backend to client. Send the first byte immediately, and send a heartbeat event while the model is silent.
- When a stream drops after partial output, store the partial response and continue from it where the provider supports continuation.

### Asynchronous inference

Run the call as a job: record it, hand it to a worker, and let the caller observe the job.

- Persist a job record before any model call: id, input reference, status, attempt count, and result location. Return the job id to the caller immediately.
- Per delivery, the worker makes one streamed call under the streaming rules, stores the result, and marks the job terminal.
- Assume at-least-once delivery. Load the job record before calling the model; if the job already succeeded or is still running, acknowledge without calling the model.
- Bound job retries in the consumer. Retry only jobs whose call failed before generation started; never leave inference retries to the queue's default policy.
- A client disconnect must not cancel or restart the job. The client re-reads job state (poll or subscribe) when it returns.

## Verify

Test limits, timeouts, malformed output, tool authorisation, safe logging, and routing to the canned-response sink. Prove that a pre-generation failure retries with a bound, that a mid-generation failure is classified and not retried, and that a redelivered job does not call the model twice.

## Binds to a stack

The active stack pack identifies:

- the provider SDK and adapter location;
- the streaming transport from backend to client, and the platform's request duration ceiling;
- the queue or job runner for asynchronous inference, and where its retry bound lives;
- the canned-response sink and schema validator;
- configuration for model, limits, and rollout;
- cost, usage, latency, and failure monitoring.

## Interactions

- **Base integrations and configuration:** apply their idempotency, failure-classification, rollout, and validation rules. This add-on narrows the base transient-retry rule for inference calls: transient failures are retried only before generation starts.
- **test-mode:** use the canned-response sink.
- **multi-tenancy:** attach usage and cost to the active tenant.
- **saas-billing:** send eligible AI usage to the billing meter.
