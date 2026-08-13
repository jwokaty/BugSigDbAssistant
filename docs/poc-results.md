# BugSigAssistant — Viability Prototype Results

Two independent tests of the riskiest assumptions before committing to the full build.

```bash
# run inside the Docker container
docker compose exec -w /srv/shiny-server/BugSigAssistant app Rscript tests/test_snippets.R
docker compose exec -w /srv/shiny-server/BugSigAssistant app Rscript tests/test_data_discovery.R
```

## Part A — RCODE snippet retrieval: 15/15 (100%)

TF-IDF cosine similarity over a 15-snippet library of verified, verbatim code from
`bugsigdbr`, `bugSigSimple`, and `BugSigDBStats`. Tested against 15 hand-written
paraphrase queries scored against known correct snippet IDs.

One near-miss worth noting: one query won by a narrow margin (0.216 vs 0.203
runner-up) due to low vocabulary overlap with its target description. The other 14
won by wide margins (0.59–0.96).

**Read:** TF-IDF is sufficient for RCODE retrieval at this scale.

## Part B — DATA discovery: 10/10 final-answer accuracy

An LLM converts natural-language questions into structured filters (`condition`,
`body_site`, `taxon`, `direction`) applied to real BugSigDB release data. Tested
against 10 questions with hand-verified expected filters and match counts computed
directly from the data.

Tests run against the live `gpt-oss-120b` model on Jetstream2 via the Docker SSH
tunnel. Filter comparison is case-insensitive.

**Read:** the LLM reliably extracts structured filters from natural-language questions.
The full pipeline (question → filter → SQL → answer) is proven on real data.
