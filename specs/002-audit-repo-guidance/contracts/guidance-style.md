# Contract: Guidance Style & Voice

Every streamlined guidance file must satisfy this contract (FR-014, SC-010). It is deliberately one page: a style guide longer than the files it governs fails its own standard.

## Voice

- **Imperative, present tense.** "Keep business logic out of controllers." Not "we decided that business logic should be kept…".
- **Opinionated default + explicit escape hatch.** State the rule as the way things are done; when an exception is legitimate, name its trigger: "Do X. If Y, do Z instead."
- **One rule, one statement.** A rule appears once, in the file that owns it; elsewhere, point to it rather than restate it.
- **Confident, not hedged.** No "consider possibly", "it might be good to", "generally try to". If the team believes it, say it plainly; if the team doesn't believe it, cut it.

## Prohibited content

- **Historical narrative** — how a rule came to be, what it replaced, references to past refactors or renamed concepts. If a past decision is load-bearing, keep the decision as a one-line rule; cut the story.
- **Meta-commentary** — text about the document itself ("this section was added to clarify…", "as mentioned above").
- **Tool-generated filler** — restating the obvious, summarizing what the reader just read, enumerating what a section is about to say.
- **Duplication across tiers** — generic guidance states the contract; stack packs state the concrete binding; neither repeats the other.

## Shape

- Open each file with one or two sentences: who reads this and when it applies.
- Prefer short lists of rules over paragraphs of prose; prefer a table only for genuinely enumerable facts.
- Intentional placeholders are framed as deliberate instantiation points ("filled at instantiation — see the Day-1 checklist"), never left looking abandoned.

## Check

Sample any three guidance files: same voice, no prohibited content, rules stated once. That sampling is the SC-010 acceptance test.
