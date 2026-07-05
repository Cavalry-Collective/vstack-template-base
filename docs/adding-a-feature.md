# Adding a feature — the full slice

What one feature touches, end to end. This is the extension guide: follow it and a new capability lands as a coherent, removable slice instead of scattered edits. The example is "invoices"; substitute your feature.

## 0. Spec

Write the spec first (`specs/README.md`; Spec Kit: `/speckit-specify`). Priority-tagged stories, acceptance criteria with named verification steps, out-of-scope list, open questions. New screens name their `design/` mockup — or the spec sketches the screen and gets it approved; never invent UI silently.

## 1. Schema (if the feature stores data)

- New migration under `db/migrations/`: `<timestamp>_add_invoices_table` — reversible, or carrying an explicit irreversible justification.
- Follow the schema conventions (`db/CLAUDE.md`): snake_case, `created_at`/`updated_at`, UTC timestamps, indexed FKs, exact types for money.
- Prove it on a scratch DB before merge (round-trip, or the pack's bound gate).
- Realistic seed data for the new tables so every screen/flow is exercisable.

## 2. Backend module

Create `apps/backend/src/modules/invoice/` with the rings it earns (a small module needn't use every folder):

| Ring | You write | Never here |
|---|---|---|
| `domain/` | `Invoice` entity, invariants, the `InvoiceRepository` port | I/O, framework types, DB shapes |
| `service/` | one file per use case (`issue-invoice`, `list-invoices`), transaction boundary | HTTP concepts, query building |
| `repo/` | the port's DB implementation + mapper (row ↔ domain), external clients | business rules, branching beyond the query |
| `controller/` | REST handlers on `/internal/v1/invoices`, guards, validation | logic, transactions, reaching past the service |
| `dtos/` | request/response shapes — the module's edge contract | domain or DB types |

Wire ports to implementations in the composition root only. Follow the REST conventions (plural nouns, pagination envelope, one error envelope, status-code table) — they're the public contract the frontend mirrors.

Tests per ring as you go (`docs/testing.md`): domain unit, service with port fakes, repo integration, controller contract.

## 3. Frontend slice

The vertical slice is `store/invoice` + `services/invoice` + `components/organisms/invoice/` + a page:

1. **Service** mirrors the backend endpoint contract — shapes validated, never invented.
2. **Store slice** if the domain needs client state (the pack may narrow this — e.g. server-first packs keep server data out of the store).
3. **Organisms** (`InvoiceTable`, `InvoiceForm`) composed from existing atoms/molecules — search the shared tiers first; a second variant of an existing primitive is the canonical failure.
4. **Page** composes organisms, holds no business logic, registers its route in the central registry the moment it exists.
5. **All four states** — loading / error / empty / success — designed and forced during verification; empty states say why and offer the next action.
6. **Copy** through i18n (every key in every locale, same change) or the strings module; tokens for every visual value.

## 4. Cross-cutting hooks

- Correlation id, auth interceptor, error envelope: already shared — don't re-implement, just don't bypass.
- Audit trail: if the feature changes who-did-what state (money, permissions, contacts), record it through the shared audit call in the use case.
- New config keys: schema + `.env.example` + environments, per `docs/configuration.md`. Risky integrations behind the default-off flag with a sink.
- Adopted add-ons that cover the capability (e.g. `test-mode` for a new side effect) bind here too.

## 5. Verify and merge

- Run the area *Definition of done* checklists: endpoint exercised over HTTP (happy + one error path), screen forced through four states, keyboard pass, 320 px + 200 % zoom, migration proven.
- CI green on the rebased branch, PR template filled with the observed evidence, then the merge-back gate (root contract).

## Removing a feature

The slice property is the point: delete the backend module, the frontend slice (store + services + organisms + page + route entry + i18n keys), a contract-checked migration for its tables, and its spec stays as history. If deletion requires edits in *other* features' code, the slice leaked — flag it.
