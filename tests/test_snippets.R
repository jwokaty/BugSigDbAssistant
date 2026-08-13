# Part A test harness: hit-rate evaluation for TF-IDF snippet retrieval.
# Runnable standalone: Rscript tests/test_snippets.R
#
# Each test query is a paraphrase of a snippet's task, written independently
# of the task description text, with a hand-assigned "correct" snippet_id.
# Includes two explicit paraphrase pairs (2a/2b, 9a/9b) that should both
# retrieve the same snippet, as called for in the prototype brief.

this_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) NULL)
root <- if (!is.null(this_dir)) dirname(this_dir) else "."
source(file.path(root, "R", "snippets.R"))

test_queries <- list(
  list(query = "How do I import all the signatures from BugSigDB into R?",
       expected = "import_bugsigdb"),
  list(query = "How do I filter signatures by condition and body site?",
       expected = "subset_condition_bodysite"),
  list(query = "How do I get only obesity signatures from feces samples?",
       expected = "subset_condition_bodysite"),
  list(query = "How do I extract the taxa in each signature as NCBI taxonomy IDs?",
       expected = "get_signatures_ncbi"),
  list(query = "How do I get signatures restricted to the genus level?",
       expected = "get_signatures_genus"),
  list(query = "How do I subset signatures by an EFO ontology term like cancer?",
       expected = "subset_by_ontology_efo"),
  list(query = "How do I subset signatures by a UBERON body site term?",
       expected = "subset_by_ontology_uberon"),
  list(query = "How do I write signatures out to a GMT file?",
       expected = "write_gmt"),
  list(query = "How do I create a summary table of the studies in BugSigDB?",
       expected = "create_study_table"),
  list(query = "How do I make a table of the most common taxa?",
       expected = "create_taxon_table"),
  list(query = "How do I count signatures with increased abundance for the top taxa?",
       expected = "frequency_sigs"),
  list(query = "How do I subset the data to signatures added by one curator?",
       expected = "subset_by_curator"),
  list(query = "How do I calculate Jaccard similarity between signatures?",
       expected = "calc_jaccard_similarity"),
  list(query = "How do I compute pairwise overlaps between several signatures?",
       expected = "calc_pairwise_overlaps"),
  list(query = "How do I look up the publication year for a study's PMID?",
       expected = "pmid_to_pubyear")
)

snippets <- build_snippet_library()
index <- build_tfidf_index(snippets)

cat(sprintf("Snippet library: %d snippets across %s\n\n",
            nrow(snippets), paste(unique(snippets$package), collapse = ", ")))

hits <- 0
results <- data.frame()
for (tq in test_queries) {
  top <- retrieve_snippets(tq$query, index, top_n = 3)
  top1 <- top$snippet_id[1]
  hit <- identical(top1, tq$expected)
  hits <- hits + hit

  cat(sprintf("[%s] %s\n", if (hit) "HIT " else "MISS", tq$query))
  cat(sprintf("     expected: %-28s top-1: %-28s score: %.3f\n",
              tq$expected, top1, top$score[1]))
  if (!hit) {
    cat(sprintf("     (top-3 was: %s)\n", paste(top$snippet_id, collapse = ", ")))
  }
  cat("\n")

  results <- rbind(results, data.frame(
    query = tq$query, expected = tq$expected, retrieved = top1,
    score = top$score[1], hit = hit
  ))
}

hit_rate <- hits / length(test_queries)
cat(sprintf("=== Hit rate: %d/%d = %.1f%% ===\n\n",
            hits, length(test_queries), 100 * hit_rate))

cat("--- Sample query -> retrieved snippet (for eyeballing quality) ---\n")
for (i in c(1, 3, 9, 13)) {
  tq <- test_queries[[i]]
  top <- retrieve_snippets(tq$query, index, top_n = 3)
  cat(sprintf("\nQuery: %s\n", tq$query))
  for (j in seq_len(nrow(top))) {
    snip <- snippets[snippets$snippet_id == top$snippet_id[j], ]
    cat(sprintf("  #%d [%.3f] %s (%s): %s\n",
                j, top$score[j], snip$snippet_id, snip$package, snip$task))
  }
}

invisible(results)
