# Part A of the BugSigDB chatbot viability prototype: RCODE snippet retrieval.
#
# Tests whether simple TF-IDF cosine similarity, computed over each snippet's
# short natural-language task description, can reliably find the right
# verified R code example for a natural-language question. Base R only, no
# external NLP packages (tm, ellmer, etc.) so this runs anywhere.
#
# Every snippet below is verbatim, verified-runnable code taken from
# \examples{} blocks or vignettes in waldronlab/bugsigdbr, waldronlab/bugSigSimple,
# and waldronlab/BugSigDBStats. One snippet (subset_by_curator) replaces a real
# curator's name from the source example with a placeholder, consistent with
# the project's privacy principle that curator usernames are never surfaced.

build_snippet_library <- function() {
  snippets <- list(
    list(
      snippet_id = "import_bugsigdb",
      package = "bugsigdbr",
      task = "import all signatures from BugSigDB into R",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'library(bugsigdbr)\nbsdb <- importBugSigDB()\ndim(bsdb)\ncolnames(bsdb)'
    ),
    list(
      snippet_id = "subset_condition_bodysite",
      package = "bugsigdbr",
      task = "filter signatures by condition and body site",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'us.obesity.feces <- subset(bsdb,\n                           `Location of subjects` == "United States of America" &\n                           Condition == "obesity" &\n                           `Body site` == "feces")'
    ),
    list(
      snippet_id = "get_signatures_ncbi",
      package = "bugsigdbr",
      task = "extract microbe signatures as NCBI taxonomy IDs",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'sigs <- getSignatures(bsdb)\nlength(sigs)\nsigs[1:3]'
    ),
    list(
      snippet_id = "get_signatures_genus",
      package = "bugsigdbr",
      task = "get signatures restricted to the genus level taxonomic rank",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'gn.sigs <- getSignatures(bsdb, \n                         tax.id.type = "taxname",\n                         tax.level = "genus")\ngn.sigs[1:3]'
    ),
    list(
      snippet_id = "subset_by_ontology_efo",
      package = "bugsigdbr",
      task = "subset signatures by an EFO ontology term for condition, such as cancer",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'efo <- getOntology("efo")\nsdf <- subsetByOntology(bsdb,\n                        column = "Condition",\n                        term = "cancer",\n                        ontology = efo)\ndim(sdf)\ntable(sdf[,"Condition"])'
    ),
    list(
      snippet_id = "subset_by_ontology_uberon",
      package = "bugsigdbr",
      task = "subset signatures by a UBERON body site ontology term",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'uberon <- getOntology("uberon")\nsdf <- subsetByOntology(bsdb,\n                        column = "Body site",\n                        term = "digestive system",\n                        ontology = uberon)\ndim(sdf)\ntable(sdf[,"Body site"])'
    ),
    list(
      snippet_id = "write_gmt",
      package = "bugsigdbr",
      task = "write extracted signatures to a GMT file",
      source = "vignettes/bugsigdbr.Rmd",
      code = 'writeGMT(sigs, gmt.file = "bugsigdb_signatures.gmt")'
    ),
    list(
      snippet_id = "create_study_table",
      package = "bugSigSimple",
      task = "create a summary table of the studies in BugSigDB",
      source = "man/createStudyTable.Rd",
      code = 'full.dat <- bugsigdbr::importBugSigDB()\ncreateStudyTable(full.dat)'
    ),
    list(
      snippet_id = "create_taxon_table",
      package = "bugSigSimple",
      task = "create a formatted summary table of the most frequent taxa",
      source = "man/createTaxonTable.Rd",
      code = 'full.dat <- bugsigdbr::importBugSigDB()\ncreateTaxonTable(full.dat, n=20)'
    ),
    list(
      snippet_id = "get_most_frequent_taxa",
      package = "bugSigSimple",
      task = "get a ranked list of the most frequently reported taxa",
      source = "man/getMostFrequentTaxa.Rd",
      code = 'full.dat <- bugsigdbr::importBugSigDB()\ngetMostFrequentTaxa(full.dat)'
    ),
    list(
      snippet_id = "frequency_sigs",
      package = "bugSigSimple",
      task = "count how many signatures report increased abundance for the top taxa",
      source = "man/frequencySigs.Rd",
      code = 'dat <- bugsigdbr::importBugSigDB()\ndat.select <- bugsigdbr::getSignatures(dat, tax.level = "genus", exact.tax.level=TRUE)\ndat.select <- dat.select[grep("UP", names(dat.select))] #only "UP" signatures\nfrequencySigs(sigs=dat.select, n = 10)'
    ),
    list(
      snippet_id = "subset_by_curator",
      package = "bugSigSimple",
      task = "subset signatures to those added by a specific curator",
      source = "man/subsetByCurator.Rd",
      # NOTE: the real curator name from the man page example is replaced with a
      # placeholder here, per the chatbot's privacy principle that curator
      # usernames are never surfaced in retrieved/displayed content.
      code = 'full.dat <- bugsigdbr::importBugSigDB()\ncurator.dat <- subsetByCurator(full.dat, curator = "curator_name")'
    ),
    list(
      snippet_id = "calc_jaccard_similarity",
      package = "BugSigDBStats",
      task = "calculate Jaccard similarity between a list of signatures",
      source = "man/calcJaccardSimilarity.Rd",
      code = 'testlist <- list(a = 1:3, b = 3, c = 3:4)\njsim <- calcJaccardSimilarity(testlist)'
    ),
    list(
      snippet_id = "calc_pairwise_overlaps",
      package = "BugSigDBStats",
      task = "calculate pairwise overlaps between multiple signatures",
      source = "man/calcPairwiseOverlaps.Rd",
      code = 'testlist <- list(a = 1:3, b = 3, c = 3:4)\n(all <- calcPairwiseOverlaps(testlist))\ncalcPairwiseOverlaps(testlist, targetset = "b")'
    ),
    list(
      snippet_id = "pmid_to_pubyear",
      package = "BugSigDBStats",
      task = "get the publication year for a study from its PMID",
      source = "man/pmid2pubyear.Rd",
      code = 'pmid2pubyear("32026945")'
    )
  )
  do.call(rbind, lapply(snippets, as.data.frame, stringsAsFactors = FALSE))
}

# ---- TF-IDF + cosine similarity, hand-rolled in base R ------------------

.stopwords <- c(
  "a", "an", "the", "of", "to", "in", "on", "for", "and", "or", "is", "are",
  "how", "do", "i", "can", "get", "with", "from", "by", "at", "as", "into",
  "that", "this", "it", "be", "me", "my"
)

tokenize <- function(text) {
  text <- tolower(text)
  text <- gsub("[^a-z0-9]+", " ", text)
  tokens <- strsplit(trimws(text), "\\s+")[[1]]
  tokens[nzchar(tokens) & !(tokens %in% .stopwords)]
}

build_tfidf_index <- function(snippets, text_field = "task") {
  docs <- paste(snippets[[text_field]], snippets$package)
  doc_tokens <- lapply(docs, tokenize)

  vocab <- sort(unique(unlist(doc_tokens)))
  n_docs <- length(doc_tokens)

  tf <- matrix(0, nrow = n_docs, ncol = length(vocab),
               dimnames = list(snippets$snippet_id, vocab))
  for (i in seq_len(n_docs)) {
    counts <- table(doc_tokens[[i]])
    tf[i, names(counts)] <- as.numeric(counts) / length(doc_tokens[[i]])
  }

  df <- colSums(tf > 0)
  idf <- log((n_docs + 1) / (df + 1)) + 1

  tfidf <- sweep(tf, 2, idf, `*`)

  list(vocab = vocab, idf = idf, tfidf = tfidf, snippet_ids = snippets$snippet_id)
}

.vectorize_query <- function(query, index) {
  tokens <- tokenize(query)
  vec <- setNames(numeric(length(index$vocab)), index$vocab)
  if (!length(tokens)) return(vec)
  counts <- table(tokens)
  counts <- counts[names(counts) %in% index$vocab]
  if (!length(counts)) return(vec)
  tf <- as.numeric(counts) / length(tokens)
  vec[names(counts)] <- tf * index$idf[names(counts)]
  vec
}

.cosine_sim <- function(a, b) {
  denom <- sqrt(sum(a^2)) * sqrt(sum(b^2))
  if (denom == 0) return(0)
  sum(a * b) / denom
}

# Given a natural-language query, return the top_n snippets ranked by
# TF-IDF cosine similarity, most similar first.
retrieve_snippets <- function(query, index, top_n = 3) {
  qvec <- .vectorize_query(query, index)
  scores <- apply(index$tfidf, 1, .cosine_sim, b = qvec)
  ord <- order(scores, decreasing = TRUE)[seq_len(min(top_n, length(scores)))]
  data.frame(
    snippet_id = index$snippet_ids[ord],
    score = round(unname(scores[ord]), 4),
    row.names = NULL
  )
}

# ---- Optional comparison: "stuff everything into context" -----------------
#
# Alternative to TF-IDF retrieval: send the full snippet library (task +
# code) to the LLM in one prompt and ask it to pick the best-matching
# snippet_id. Legitimate at this corpus size (~15 snippets easily fits in
# context). Requires ellmer + a reachable LLM endpoint (see R/data_discovery.R
# for the same Jetstream2 connection pattern) - NOT executed as part of this
# sandbox's test run because this environment cannot install ellmer (no CRAN
# access) or reach Jetstream2. Included for completeness / to run on a
# machine with real LLM access.
retrieve_snippet_llm <- function(query, snippets, chat) {
  if (missing(chat) || is.null(chat)) {
    stop("retrieve_snippet_llm() requires an ellmer chat object connected to ",
         "an LLM endpoint (see R/data_discovery.R::make_llm_chat()). Not run ",
         "in this sandbox - no LLM endpoint reachable.")
  }
  catalog <- paste(sprintf(
    "- id: %s | package: %s | task: %s\n  code:\n%s",
    snippets$snippet_id, snippets$package, snippets$task, snippets$code
  ), collapse = "\n\n")

  prompt <- sprintf(paste(
    "You are matching a user question to the single best-matching code",
    "snippet from the catalog below. Reply with ONLY the snippet_id, nothing",
    "else.\n\nCatalog:\n%s\n\nQuestion: %s\n\nsnippet_id:"
  ), catalog, query)

  trimws(chat$chat(prompt))
}
