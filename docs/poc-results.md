# BugSigDB Chatbot — Viability Prototype Results

Built per the viability prototype brief: two independent, cheap tests of the
riskiest assumptions behind the planned BugSigDB chatbot, before committing
to the full Phase 1 build (Shiny, DuckDB, Ollama, router, etc. - none of
that is here on purpose). Pure R, runnable from the console.

```
Rscript tests/test_snippets.R          # Part A
Rscript tests/test_data_discovery.R    # Part B
```

## Part A — RCODE snippet retrieval: **15/15 (100%) hit rate**

**Question:** can TF-IDF cosine similarity, computed over a short
human-written task description per snippet, reliably find the right verified
R code example for a natural-language question?

- `R/snippets.R` — a 15-snippet library and a hand-rolled TF-IDF + cosine
  similarity retriever, base R only, no NLP dependencies.
- Every snippet is **verbatim, verified-runnable code** pulled from real
  `\examples{}` blocks and vignettes in `waldronlab/bugsigdbr`,
  `waldronlab/bugSigSimple`, and `waldronlab/BugSigDBStats` — nothing was
  invented. One example (`subset_by_curator`) has its source's real curator
  name replaced with a placeholder, consistent with the chatbot's privacy
  principle that curator usernames are never surfaced.
- `tests/test_snippets.R` — 15 hand-written paraphrase queries (written
  independently of the stored task descriptions), including two explicit
  paraphrase pairs mapping to the same snippet, scored against a known
  correct `snippet_id`.

**Result: 15/15.** Worth reporting honestly rather than just touting the
number: one query — *"How do I get only obesity signatures from feces
samples?"* — only won by a narrow margin (score 0.216 vs. 0.203 runner-up)
because it shares almost no vocabulary with its target snippet's task
description ("filter signatures by condition and body site"). A slightly
different paraphrase could plausibly flip that one. That's a real,
if narrow, signal about TF-IDF's limits at this corpus size — not a reason
to distrust the other 14, which won by wide margins (0.59–0.96).

**Read:** strong support for TF-IDF as sufficient for the RCODE snippet
library at this scale (~15 real snippets today, low tens expected at
production scale), matching the project summary's design bet.

## Part B — DATA discovery: pipeline verified, **LLM path not yet tested**

**Question:** can an LLM reliably convert a natural-language question into a
structured filter (`condition` / `body_site` / `taxon` / `direction`)
applied to real BugSigDB data?

- `data/bugsigdb_subset.csv` — 324 real taxon-level rows (45 signatures, 15
  per condition) from actual BugSigDB release data, covering Colorectal
  cancer / Obesity / Irritable bowel syndrome in Feces. Derived from the real
  CSV export at `waldronlab/BugSigDBExports` (`data/build_subset.R`
  documents exactly how, and is how to regenerate it - it started as an
  unfiltered 7,155-row/737-signature pull, capped down to keep the file
  small enough to bundle in the repo). Curator/editor columns were never
  loaded, per the chatbot's privacy principle.
- `R/data_discovery.R` — data loading, a JSON-structured-output prompt, an
  `ellmer`-based extraction function wired for the project's real Jetstream2
  endpoint (`make_llm_chat()`, reads `LLM_ENDPOINT`/`LLM_MODEL` from
  `.Renviron` exactly as designed), and filter application against the data.
- `tests/test_data_discovery.R` — 10 questions against the real subset, each
  with a hand-verified expected filter *and* expected match count, computed
  directly against the data (shown in the test output), scoring
  filter-extraction accuracy and final-answer accuracy separately as the
  brief asks.

**Important caveat — read before showing this number to anyone:** this
sandbox has no route to CRAN/Bioconductor (so `ellmer` can't be installed
here) and no route to the Jetstream2 tunnel, so **the actual LLM call has
not been run or validated.** The harness runs today in a **mock mode** — a
hand-written keyword matcher standing in for the LLM, only so the full
pipeline (load → extract filter → apply filter → count) can be demonstrated
end-to-end. Mock mode scores 9/10 filter-extraction and 9/10 final-answer —
**that number describes my keyword matcher, not an LLM's language
understanding**, and shouldn't be repeated as if it were. Its one miss is
actually the most useful result in this whole prototype: asked about
"Helicobacter pylori" (a taxon genuinely absent from the subset), the mock
matcher can only recognize taxon names that already exist in the loaded
data, so it fails to extract any taxon at all and silently falls back to
matching every row for the condition alone - returning a confident-looking
but wrong answer (152 matches instead of 0), not a visible error. That's
exactly the failure mode worth catching before trusting this pattern in
front of real users: a wrong non-zero answer is worse than an obvious one.
A real LLM extracting from the question text alone doesn't share this
specific limitation (it isn't constrained to a fixed vocabulary drawn from
the dataset), but it will have its own failure modes - which is exactly
what running this harness against Jetstream2 would surface.

**What this means for viability:** the *plumbing* is proven — real data,
real schema, a prompt that matches the project's structured-output design,
and a test harness with ground truth computed straight from the data. The
part the brief actually asks to validate — can an LLM do the extraction
reliably — needs one real run against Jetstream2. That's a same-day task
once the tunnel is up (see `.Renviron.example`); nothing in the code needs
to change, just: set `LLM_ENDPOINT`/`LLM_MODEL`, install `ellmer`, and
re-run `Rscript tests/test_data_discovery.R` (it auto-detects those env vars
and switches from mock to the real LLM path).

## Recommendation

Part A clears its success bar outright. Part B's harness and data are ready
but its actual research question is still open — pending one real run
against Jetstream2 outside this sandbox. Suggest treating that as the
immediate next step before green-lighting full Phase 1 infrastructure.
