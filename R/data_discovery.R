# Part B of the BugSigDB chatbot viability prototype: DATA intent, i.e. can
# an LLM reliably turn a natural-language question into a structured filter
# applied to real BugSigDB data - not RAG, not free-text generation.
#
# Data: data/bugsigdb_subset.csv - a small real subset of BugSigDB release
# data (Colorectal cancer / Obesity / Irritable bowel syndrome, Feces only),
# derived from the real waldronlab/BugSigDBExports release CSV. See
# data/build_subset.R for provenance. Production code should load via
# bugsigdbr::importBugSigDB() per the project design (see below).
#
# LLM backend: this is written against ellmer + an OpenAI-compatible endpoint
# (Jetstream2), exactly as specified in the project summary's Infrastructure
# section. IMPORTANT SANDBOX CAVEAT: this prototype was built in an
# environment with no CRAN access (so ellmer/jsonlite cannot be installed)
# and no route to a Jetstream2 tunnel, so the live LLM path below has NOT
# been executed or validated here. A minimal rule-based "mock" backend is
# included ONLY so the pipeline (load -> extract filter -> apply filter ->
# answer) can be demonstrated end-to-end today. Mock-mode accuracy is NOT a
# measurement of LLM viability - see docs/poc-results.md for what it does
# and doesn't tell you, and how to re-run this against a real LLM.

load_data_subset <- function(path = "data/bugsigdb_subset.csv") {
  df <- read.csv(path, stringsAsFactors = FALSE)
  # Privacy principle: no curator/editor columns are ever loaded (they were
  # excluded when data/bugsigdb_subset.csv was built - see build_subset.R).
  stopifnot(!any(c("Curator", "Revision.editor", "Reviewer") %in% names(df)))
  df
}

# ---- Structured filter extraction (production path: ellmer + Jetstream2) --

FILTER_SCHEMA_FIELDS <- c("condition", "body_site", "taxon", "direction")

`%||%` <- function(a, b) if (is.null(a)) b else a

filter_extraction_prompt <- function(question) {
  sprintf(paste(
    "Extract a structured filter from the user's question about microbial",
    "signature data. Return ONLY a JSON object with exactly these keys:",
    '"condition", "body_site", "taxon", "direction". Use the value null for',
    "any field the question does not mention. direction must be one of",
    '"increased", "decreased", or null. Do not return any text other than',
    "the JSON object - no explanation, no markdown code fence.\n\n",
    "Question: %s\n\nJSON:"
  ), question)
}

# Builds an ellmer chat object pointed at the Jetstream2 endpoint, following
# the .Renviron pattern from the project summary (LLM_ENDPOINT, LLM_MODEL,
# LLM_API_KEY). Requires the ellmer package and a reachable endpoint - errors
# clearly if either is missing rather than silently falling back, so a real
# run against Jetstream2 is unambiguous about whether it used the real LLM.
make_llm_chat <- function() {
  if (!requireNamespace("ellmer", quietly = TRUE)) {
    stop("ellmer is not installed. Install it (install.packages(\"ellmer\")) ",
         "to use the live LLM path; see project summary Infrastructure ",
         "section for the Jetstream2 endpoint setup.")
  }
  endpoint <- Sys.getenv("LLM_ENDPOINT")
  model <- Sys.getenv("LLM_MODEL")
  api_key <- "placeholder"
  if (!nzchar(endpoint) || !nzchar(model)) {
    stop("LLM_ENDPOINT and LLM_MODEL must be set (see .Renviron.example). ",
         "These point at the Jetstream2 SSH tunnel per the project summary.")
  }
  ellmer::chat_openai_compatible(base_url = endpoint, model = model, api_key = api_key)
}

# Minimal, dependency-free JSON object parser for the fixed 4-field schema
# above. Not a general JSON parser - jsonlite (already in renv.lock) should
# be used in production; this exists so the prototype runs without CRAN
# access to install it here.
.parse_filter_json <- function(text) {
  text <- trimws(gsub("```json|```", "", text))
  result <- setNames(as.list(rep(NA_character_, length(FILTER_SCHEMA_FIELDS))),
                      FILTER_SCHEMA_FIELDS)
  for (field in FILTER_SCHEMA_FIELDS) {
    pattern <- sprintf('"%s"\\s*:\\s*(null|"([^"]*)")', field)
    m <- regmatches(text, regexec(pattern, text))[[1]]
    if (length(m) == 3 && m[1] != "") {
      result[[field]] <- if (m[2] == "null") NA_character_ else m[3]
    }
  }
  result
}

# Live path: ask the LLM to extract a structured filter. Returns a named
# list with condition/body_site/taxon/direction (NA where not mentioned).
extract_filter_llm <- function(question, chat = NULL) {
  chat <- chat %||% make_llm_chat()
  raw <- chat$chat(filter_extraction_prompt(question))
  .parse_filter_json(raw)
}

# ---- Mock backend (sandbox-only stand-in, see caveat above) ---------------
#
# A small rule-based extractor used ONLY to demonstrate the pipeline
# mechanics when no LLM is reachable. It matches literal condition/taxon
# names present in the loaded data subset and the two known direction words -
# it is not a general NL understanding system and its accuracy says nothing
# about whether a real LLM would perform well on the same questions.
extract_filter_mock <- function(question, data) {
  q <- tolower(question)
  result <- setNames(as.list(rep(NA_character_, length(FILTER_SCHEMA_FIELDS))),
                      FILTER_SCHEMA_FIELDS)

  for (cond in unique(data$condition)) {
    if (grepl(tolower(cond), q, fixed = TRUE)) { result$condition <- cond; break }
  }
  for (site in unique(data$body_site)) {
    if (grepl(tolower(site), q, fixed = TRUE)) { result$body_site <- site; break }
  }
  taxa <- unique(data$taxon)
  taxa <- taxa[!is.na(taxa)]
  taxa_by_len <- taxa[order(-nchar(taxa))]
  for (taxon in taxa_by_len) {
    if (grepl(tolower(taxon), q, fixed = TRUE)) { result$taxon <- taxon; break }
  }
  if (grepl("increas", q)) result$direction <- "increased"
  else if (grepl("decreas", q)) result$direction <- "decreased"

  result
}

# ---- Apply filter to data --------------------------------------------------

apply_filter <- function(filter, data) {
  keep <- rep(TRUE, nrow(data))
  if (!is.na(filter$condition))
    keep <- keep & (tolower(data$condition) == tolower(filter$condition))
  if (!is.na(filter$body_site))
    keep <- keep & (tolower(data$body_site) == tolower(filter$body_site))
  if (!is.na(filter$taxon))
    keep <- keep & (tolower(data$taxon) == tolower(filter$taxon))
  if (!is.na(filter$direction))
    keep <- keep & (tolower(data$direction) == tolower(filter$direction))
  data[keep & !is.na(keep), ]
}

answer_question <- function(question, data, chat = NULL, backend = c("llm", "mock")) {
  backend <- match.arg(backend)
  filter <- if (backend == "llm") {
    extract_filter_llm(question, chat)
  } else {
    extract_filter_mock(question, data)
  }
  matches <- apply_filter(filter, data)
  list(filter = filter, n_matches = nrow(matches), matches = matches)
}
