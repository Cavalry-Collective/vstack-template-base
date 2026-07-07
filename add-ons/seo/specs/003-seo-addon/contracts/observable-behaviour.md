# Contract: Observable Behaviour (adopting application ⇄ the outside world)

**Consumers**: crawlers, link-preview bots, and the humans/CI verifying an adopting app.
**Provider**: any application built under the adopted add-on.
**Nature**: every clause is verifiable by fetching URLs and inspecting responses — no implementation access needed (FR-011, SC-004/SC-005). This is the acceptance surface `/speckit-tasks` should turn into verification steps for instantiated projects.

| # | Given | When fetched (no client scripting) | Then | Rule |
|---|---|---|---|---|
| O1 | An indexable page | its canonical URL | full content, unique title + description, one absolute canonical, share tags + image present in the raw response | R3, R4, R7 |
| O2 | A URL variant (params, casing, host alias, trailing slash) | the variant | permanent redirect to the canonical URL | R4 |
| O3 | A parameter/filter/pagination variant of a page | the variant | non-indexable: canonical points at the base page (or noindex), and it is absent from the sitemap | R2 |
| O4 | A renamed slug | the previously published URL | permanent redirect to the new URL | R5 |
| O5 | A nonexistent entity | its would-be URL | not-found (or gone) status — never success + error screen | R6 |
| O6 | Entity markup on a page | the page | markup content is a subset of visible page content | R8 |
| O7 | The sitemap | its URL | exactly the indexable routes per the registry classification — no more, no less | R9 |
| O8 | The robots file | its URL | disallows the non-indexable surface; never disallows indexable routes | R9 |
| O9 | Any page on a non-production origin | any URL there | a noindex directive (header or markup), fail-closed | R10 |
| O10 | Any indexable page | as bot UA and as browser UA | same content both ways | R11 |

## Standing assertions (CI, in the adopting project)

- **G1**: registry contains no unclassified route/URL space.
- **G2**: sitemap is derived from the registry — regeneration produces no diff (or generation is the only writer).
- **G3**: non-production configuration yields the O9 response; the assertion runs against every non-production environment config.

## Non-clauses

Nothing here constrains ranking outcomes, traffic, keyword coverage, or page-speed metrics — out of scope per the spec's assumptions and research D8.
