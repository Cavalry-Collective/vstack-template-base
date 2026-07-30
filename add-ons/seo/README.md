# Add-on: SEO

This add-on covers the product structure required for public pages to be crawled, indexed, shared, and measured correctly. It includes route classification, canonical URLs, server-rendered content, metadata, structured data, search intent, internal links, landing-page behaviour, and loading experience.

It does not cover ongoing keyword research, advertising campaign management, rank-report analysis, performance tuning, or conversion analytics.

## Prerequisites

Indexable routes must return their complete primary content without client-side JavaScript.

Of the current stack packs, `vercel-ssr` and `enterprise` meet this requirement. The `vercel-csr`, `mern`, `django`, and `wechat` packs do not.

For a client-rendered application, either:

- serve the public search surface from a separate server-rendered origin and apply this add-on there; or
- do not adopt this add-on and make every reachable route non-indexable.

## When to adopt

| Public surface | Decision |
|---|---|
| Marketing pages, listings, articles, or profiles are part of the product | Adopt and classify routes from Day 1 |
| The product is mostly private but has a public shell | Adopt and classify every private route as non-indexable |
| The product is entirely login-walled | Do not adopt; still return a no-index response from every publicly reachable origin |

## Implementation areas

Rule identifiers are stable references for requirement specs, stack bindings, and tests.

### Routes and URLs

- **R1: Classify every route.** Record whether each route or URL space is indexable in the route registry. Reject an unclassified route.
- **R2: Bound URL variants.** Make parameter, filter, sorting, and pagination variants non-indexable and canonical to the base page unless the registry explicitly classifies them.
- **R4: Publish one canonical URL.** Permanently redirect casing, trailing-slash, and host variants. Put one absolute, parameter-free canonical on every indexable page.
- **R5: Preserve published URLs.** Keep indexable slugs stable. When a slug changes, retain a permanent redirect from every previously published URL.
- **R6: Return honest status codes.** Return not-found or gone for a missing entity. Return server-side permanent redirects for moved pages.

Build canonical URLs from a validated production-origin setting. Do not derive the origin from the incoming request.

### Rendering and metadata

- **R3: Return complete content.** Include the page's primary content in the raw response before client-side JavaScript runs.
- **R7: Use one metadata helper.** Set a unique title, description, canonical, share tags, and share image for every indexable page through one shared helper.
- **R8: Match structured data to visible content.** Generate structured data from the same entity data rendered on the page. Do not describe content the page does not show.
- **R9: Derive sitemap and robots output.** Generate both from the route registry and entity data. List exactly the indexable URLs in the sitemap and exclude non-indexable spaces through robots policy.
- **R10: Prevent non-production indexing.** Return a no-index directive unless the configured origin is the production origin.
- **R11: Serve the same content to crawlers and users.** Do not branch page content on the user agent.
- **R17: Configure ownership verification.** Serve search-console verification from validated configuration. Return no verification response when the setting is absent.

Keep titles and descriptions in the frontend's central copy location.

### Search intent and internal links

- **R12: Record one search intent per locale.** Store the target query beside each indexable route's classification. Reject missing and duplicate same-locale intents.
- **R13: Write the page for its intent.** Align the title, description, slug, and single top-level heading with the recorded intent. Do not skip heading levels.
- **R14: Link every indexable page.** Make each indexable page reachable from another indexable page through a crawlable link with descriptive anchor text.
- **R18: Derive the tracking inventory.** Generate a machine-readable URL-to-intent inventory from the route registry. Preserve tracking continuity through the redirects required by R5.

Update the intent record in the same change as copy or positioning that changes the query a page targets.

### Paid landing pages

- **R15: Ignore advertising parameters when rendering.** Keep page content unchanged when click-tracking parameters are present. Exclude those parameters from canonical URLs and the sitemap.
- **R16: Avoid redirect chains.** Make an advertising destination return success directly. Allow a vanity alias at most one permanent redirect.

Classify dedicated landing-page routes through R1 like any other route.

### Loading experience

- **R19: Meet current published search thresholds.** Measure primary-content loading, interaction responsiveness, and visual stability on the running page. Use the search engines' current published thresholds rather than values copied into this document.
- **R20: Prevent structural performance failures.** Reserve space for media and embeds. Keep primary content out of interaction-gated or client-only loading. Enforce the project's payload budget for every indexable route.

## Verify

Add these automated gates when the add-on is adopted:

| Gate | Assertion |
|---|---|
| G1 | Every route or URL space has an indexability classification |
| G2 | Regenerating sitemap and robots output produces no diff |
| G3 | Every non-production configuration returns a no-index directive |
| G4 | Every indexable route has an intent for each supported locale |
| G5 | No two indexable routes in one locale target the same intent |
| G6 | No indexable route exceeds the declared payload budget |

Also verify the running application:

- Fetch an indexable page without running scripts. Confirm full content, unique metadata, share image, and one absolute canonical.
- Fetch URL variants. Confirm a permanent redirect or canonical to the base page.
- Fetch an old slug and a missing entity. Confirm a permanent redirect and a not-found or gone response.
- Compare structured data with visible content. Confirm it describes only content on the page.
- Fetch the sitemap and robots output. Confirm they match the route registry.
- Fetch a non-production page. Confirm the no-index directive.
- Fetch as a crawler and a normal browser. Confirm the content is the same.
- Inspect an indexable page's headings and metadata. Confirm they match its recorded intent.
- Crawl links from the public entry pages. Confirm every indexable page is reachable.
- Add arbitrary advertising parameters. Confirm unchanged content, a clean canonical, and no parameterized sitemap entry.
- Fetch an advertising destination. Confirm direct success or one permanent redirect from its alias.
- Fetch ownership verification before and after a deployment. Confirm the configured response persists.
- Regenerate the URL-to-intent inventory. Confirm it matches the registry.
- Measure loading, responsiveness, and visual stability. Confirm the page meets current published thresholds.

After release, register the production origin with the relevant search-console products and monitor index coverage.

## Binds to a stack

Record each binding in the requirement spec:

- **S1:** server-rendering mechanism used by R3;
- **S2:** metadata helper and its location;
- **S3:** canonical-origin configuration and permanent-redirect mechanism;
- **S4:** sitemap and robots generation and serving;
- **S5:** not-found response mechanism;
- **S6:** structured-data helper and its location;
- **S7:** locale-alternate mechanism, or an explicit not-applicable decision;
- **S8:** route-intent storage and URL-to-intent inventory generation;
- **S9:** ownership-verification response mechanism;
- **S10:** payload-budget assertion and loading-experience measurement.

## Interactions

- **Frontend URL routing:** extend the route registry with indexability and intent. Use registry-built URLs for canonicals, sitemap entries, and internal links.
- **Base configuration:** keep the production origin and ownership-verification value in validated configuration.
- **Frontend internationalisation:** derive locale alternates and per-locale intent checks from the supported locale set.
- **Frontend copy:** keep titles and descriptions in the central copy location.
- **Frontend performance:** use the base performance rules for the application as a whole. This add-on adds the ranking-related requirements for indexable pages.
- **test-mode:** keep the two fail-closed rules separate. Test mode controls side effects per request; SEO indexing is controlled per environment.
