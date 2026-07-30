# Security policy

## Reporting a vulnerability

Email **adam@cavalry.sg** with the affected file or rule, the risk, and a reproduction if there is one. Do not open a public issue for a security report.

Expect an acknowledgement within five working days.

## Scope

This repository contains documentation and one CI workflow. It ships no application code and no runtime dependencies, so the realistic risks are:

- guidance that leads a project into an insecure default;
- a credential or private hostname committed by mistake;
- a workflow change that widens permissions or lets untrusted input reach a privileged step.

All three are in scope. A vulnerability in a project *generated* from this template is that project's to fix, unless a rule here caused it — in which case report it.

## Supported versions

`main` only. Fixes land there; there are no maintained release branches.
