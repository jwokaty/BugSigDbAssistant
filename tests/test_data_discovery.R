# Part B test harness: filter-extraction accuracy and final-answer accuracy,
# scored separately per the prototype brief. Runnable standalone:
#   Rscript tests/test_data_discovery.R
#
# Expected filters/counts below were computed by hand directly against
# data/bugsigdb_subset.csv (see docs/poc-results.md) - they are ground truth
# from the real data, not from either extraction backend.
#
# Backend selection: uses the mock backend by default, because this
# environment cannot install ellmer (no CRAN access) or reach a Jetstream2
# endpoint. Pass backend = "llm" (and have LLM_ENDPOINT/LLM_MODEL set) to
# score the real LLM path once run somewhere with that access - see
# docs/poc-results.md for what mock-mode numbers do and don't tell you.

this_dir <- tryCatch(dirname(sys.frame(1)$ofile), error = function(e) NULL)
root <- if (!is.null(this_dir)) dirname(this_dir) else "."
source(file.path(root, "R", "data_discovery.R"))

run_test_harness <- function(backend = "mock", chat = NULL) {
  data <- load_data_subset(file.path(root, "data", "bugsigdb_subset.csv"))
  cat(sprintf("Loaded %d taxon-level rows from data/bugsigdb_subset.csv\n", nrow(data)))
  cat(sprintf("Conditions: %s | Body sites: %s\n\n",
              paste(unique(data$condition), collapse = ", "),
              paste(unique(data$body_site), collapse = ", ")))

  test_cases <- list(
    list(q = "How many colorectal cancer studies show decreased Roseburia?",
         filter = list(condition = "Colorectal cancer", body_site = NA, taxon = "Roseburia", direction = "decreased"),
         expected_n = 4),
    list(q = "How many increased Faecalibacterium prausnitzii signatures are there in colorectal cancer?",
         filter = list(condition = "Colorectal cancer", body_site = NA, taxon = "Faecalibacterium prausnitzii", direction = "increased"),
         expected_n = 2),
    list(q = "How many obesity signatures report decreased taxa?",
         filter = list(condition = "Obesity", body_site = NA, taxon = NA, direction = "decreased"),
         expected_n = 16),
    list(q = "Is Mediterraneibacter gnavus decreased in colorectal cancer?",
         filter = list(condition = "Colorectal cancer", body_site = NA, taxon = "Mediterraneibacter gnavus", direction = "decreased"),
         expected_n = 3),
    list(q = "How many studies found decreased Prevotella in obesity?",
         filter = list(condition = "Obesity", body_site = NA, taxon = "Prevotella", direction = "decreased"),
         expected_n = 2),
    list(q = "How many irritable bowel syndrome signatures show increased Mediterraneibacter gnavus?",
         filter = list(condition = "Irritable bowel syndrome", body_site = NA, taxon = "Mediterraneibacter gnavus", direction = "increased"),
         expected_n = 4),
    list(q = "Is Helicobacter pylori reported in irritable bowel syndrome studies?",
         filter = list(condition = "Irritable bowel syndrome", body_site = NA, taxon = "Helicobacter pylori", direction = NA),
         expected_n = 0),
    list(q = "How many decreased Phocaeicola vulgatus signatures are in irritable bowel syndrome?",
         filter = list(condition = "Irritable bowel syndrome", body_site = NA, taxon = "Phocaeicola vulgatus", direction = "decreased"),
         expected_n = 5),
    list(q = "How many colorectal cancer studies show increased Muribaculaceae?",
         filter = list(condition = "Colorectal cancer", body_site = NA, taxon = "Muribaculaceae", direction = "increased"),
         expected_n = 4),
    list(q = "How many decreased Bacteroides intestinalis signatures are in irritable bowel syndrome?",
         filter = list(condition = "Irritable bowel syndrome", body_site = NA, taxon = "Bacteroides intestinalis", direction = "decreased"),
         expected_n = 4)
  )

  filter_hits <- 0
  answer_hits <- 0
  for (tc in test_cases) {
    result <- answer_question(tc$q, data, chat = chat, backend = backend)

    filter_match <- all(mapply(function(got, want) {
      (is.na(got) && is.na(want)) ||
      (!is.na(got) && !is.na(want) && tolower(got) == tolower(want))
    }, result$filter[FILTER_SCHEMA_FIELDS], tc$filter[FILTER_SCHEMA_FIELDS]))

    filter_hits <- filter_hits + filter_match
    answer_hits <- answer_hits + answer_match

    cat(sprintf("[filter %s | answer %s] %s\n",
                if (filter_match) "OK  " else "MISS", if (answer_match) "OK  " else "MISS", tc$q))
    cat(sprintf("   extracted: %s\n", paste(sprintf("%s=%s", names(result$filter), result$filter), collapse = ", ")))
    cat(sprintf("   expected:  %s\n", paste(sprintf("%s=%s", names(tc$filter), tc$filter), collapse = ", ")))
    cat(sprintf("   matches found: %d (expected %d)\n\n", result$n_matches, tc$expected_n))
  }

  n <- length(test_cases)
  cat(sprintf("=== Backend: %s ===\n", backend))
  cat(sprintf("Filter-extraction accuracy: %d/%d = %.1f%%\n", filter_hits, n, 100 * filter_hits / n))
  cat(sprintf("Final-answer accuracy:      %d/%d = %.1f%%\n", answer_hits, n, 100 * answer_hits / n))

  invisible(list(filter_accuracy = filter_hits / n, answer_accuracy = answer_hits / n))
}

if (identical(environment(), globalenv())) {
  backend <- if (nzchar(Sys.getenv("LLM_ENDPOINT")) && nzchar(Sys.getenv("LLM_MODEL"))) "llm" else "mock"
  if (backend == "mock") {
    cat(paste(
      "NOTE: LLM_ENDPOINT/LLM_MODEL not set - running the MOCK backend.\n",
      "Mock-mode numbers below test the pipeline plumbing only (data load ->",
      "filter -> apply -> count), using a hand-written keyword matcher, NOT",
      "an LLM. They are not a measurement of Part B's actual research",
      "question (can an LLM do this reliably). See docs/poc-results.md.\n\n"
    ))
  }
  run_test_harness(backend = backend)
}
