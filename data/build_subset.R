# Reproducible derivation of data/bugsigdb_subset.csv, the small real-data
# subset used by Part B of the viability prototype (R/data_discovery.R).
#
# Why this script exists instead of calling bugsigdbr::importBugSigDB()
# directly: the production design (see project summary) uses
# bugsigdbr::importBugSigDB(), which is the right call for the real system.
# This prototype was built in a sandbox with no CRAN/Bioconductor network
# access, so it reads the same underlying data bugsigdbr itself pulls from -
# the release CSV export published at waldronlab/BugSigDBExports
# (full_dump.csv, CC-BY 4.0, https://bugsigdb.org) - and reshapes it the same
# way bugsigdbr does. Swap this for importBugSigDB() once running somewhere
# with Bioconductor access; the row shape below matches the "signatures"
# table in the project's DuckDB schema, so downstream code does not need to
# change.
#
# Not run automatically - this is a one-time/occasional data-refresh script.
# Run manually with the path to a checkout of waldronlab/BugSigDBExports:
#   Rscript data/build_subset.R /path/to/BugSigDBExports/full_dump.csv

args <- commandArgs(trailingOnly = TRUE)
full_dump_path <- if (length(args)) args[1] else stop(
  "usage: Rscript data/build_subset.R /path/to/full_dump.csv"
)

df <- read.csv(full_dump_path, skip = 1, stringsAsFactors = FALSE, check.names = FALSE)

# A handful of well-populated conditions/body site, chosen so the subset is
# small enough to hand-verify (see docs/poc-results.md for the worked
# ground-truth counts used in tests/test_data_discovery.R).
conditions <- c("Colorectal cancer", "Obesity", "Irritable bowel syndrome")
bodysites  <- c("Feces")

sub <- df[df$Condition %in% conditions & df$"Body site" %in% bodysites, ]
sub <- sub[!is.na(sub$"MetaPhlAn taxon names") & nzchar(sub$"MetaPhlAn taxon names") &
             sub$"MetaPhlAn taxon names" != "NA", ]
sub <- sub[order(sub$Condition, sub$"BSDB ID"), ]

# Cap to a fixed number of signatures per condition (deterministic: first N
# after sorting by BSDB ID) so the subset stays small enough to bundle in
# the repo and hand-verify, while remaining a real, unmodified cross-section
# of BugSigDB rather than a hand-picked one.
signatures_per_condition <- 15
sub <- do.call(rbind, lapply(split(sub, sub$Condition), head, n = signatures_per_condition))

# Each row in full_dump.csv is one signature, with all of its taxa packed
# into one comma-separated "MetaPhlAn taxon names" field (each taxon itself
# pipe-delimited by rank, e.g. "g__Bacteroides|s__Bacteroides fragilis").
# "NCBI Taxonomy IDs" mirrors that structure with ";" between taxa. Explode
# to one row per taxon, matching the taxon-level "signatures" table in the
# project's DuckDB schema.
last_rank_name <- function(lineage) {
  parts <- strsplit(lineage, "\\|")[[1]]
  parts <- parts[nzchar(parts)]
  if (!length(parts)) return(NA_character_)
  sub("^[a-z]__", "", parts[length(parts)])
}

last_id <- function(id_lineage) {
  parts <- strsplit(trimws(id_lineage), "\\|")[[1]]
  parts <- parts[nzchar(parts)]
  if (!length(parts)) return(NA_integer_)
  suppressWarnings(as.integer(parts[length(parts)]))
}

rows <- vector("list", 0)
for (i in seq_len(nrow(sub))) {
  taxa_lineages <- strsplit(sub$"MetaPhlAn taxon names"[i], ",")[[1]]
  id_lineages   <- strsplit(sub$"NCBI Taxonomy IDs"[i], ";")[[1]]
  for (j in seq_along(taxa_lineages)) {
    rows[[length(rows) + 1]] <- data.frame(
      study_id         = sub$"BSDB ID"[i],
      pmid             = sub$PMID[i],
      condition        = sub$Condition[i],
      body_site        = sub$"Body site"[i],
      taxon            = last_rank_name(taxa_lineages[j]),
      ncbi_id          = if (j <= length(id_lineages)) last_id(id_lineages[j]) else NA_integer_,
      direction        = sub$"Abundance in Group 1"[i],
      sequencing_type  = sub$"Sequencing type"[i],
      statistical_test = sub$"Statistical test"[i],
      host_species     = sub$"Host species"[i],
      country          = sub$"Location of subjects"[i],
      study_design     = sub$"Study design"[i],
      stringsAsFactors = FALSE
    )
  }
}
long <- do.call(rbind, rows)

# Privacy principle (see project summary): curator/editor columns are never
# retained past ingestion. full_dump.csv has Curator/Revision editor/Reviewer
# columns; they are intentionally excluded from the row shape above rather
# than dropped after the fact, so they never touch this file.

out_path <- "data/bugsigdb_subset.csv"
write.csv(long, out_path, row.names = FALSE)
cat(sprintf("Wrote %d taxon-level rows (%d signatures) to %s\n",
            nrow(long), nrow(sub), out_path))
