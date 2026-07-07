# Contract: Observable Behaviour (expansion delta — O11–O18)

**Consumers**: crawlers, ad-review bots, search-engine consoles, rank-tracking tools, and the humans/CI verifying an adopting app.
**Provider**: any application built under the adopted, expanded add-on.
**Base**: 003's O1–O10 stay in force. Every new clause is verifiable by fetching, traversing, or measuring the running app — no implementation access (FR-012, SC-004/SC-006).

| # | Given | When | Then | Rule |
|---|---|---|---|---|
| O11 | An indexable page and its inventory entry | fetched raw (no client scripting) | exactly one top-level heading; heading levels descend without skipping; title, slug, and top heading coherent with the recorded intent | R13 |
| O12 | The indexable surface | links traversed from indexable entry pages | every indexable page reached via at least one crawlable link with descriptive anchor text — sitemap-only pages are orphan defects | R14 |
| O13 | Any page URL | fetched with arbitrary advertising click parameters appended | content identical to the parameter-free page; declared canonical parameter-free; no parameterized variant in the sitemap | R15 |
| O14 | An ad landing destination (and any vanity alias) | fetched | destination answers success directly; the alias is at most one permanent redirect — never a chain | R16 |
| O15 | The production origin | its ownership-verification response fetched, then re-fetched after a redeploy | present both times, served from configuration; absent config → absent response | R17 |
| O16 | The route registry and intent records | the page↔intent inventory derived twice | machine-readable pairs of exactly the indexable URLs and their intents; regeneration produces no diff | R12, R18 |
| O17 | An indexable page | measured on the three loading-experience axes (main-content loading, input responsiveness, visual stability) | meets the search engines' currently published thresholds | R19 |
| O18 | An indexable page with media/embeds | loaded, and fetched raw | no visible layout shift (space reserved before arrival); primary content present without client scripting or interaction | R20 |

## Standing assertions (CI, in the adopting project — clarification 2)

- **G4**: every indexable route has an intent record.
- **G5**: no two same-locale indexable routes record the same normalized intent.
- **G6**: every indexable route's payload is within the declared budget.

O12 and O17 are deliberately **not** gated — they need a rendered, crawled, measured app (research D4).

## Non-clauses

Nothing here constrains ranking outcomes, traffic, which intents are worth targeting, campaign performance, conversion measurement, or the contents of rank reports — the ongoing practice of the four areas stays out of scope (spec *Scope*; research D1, D6, D7).
