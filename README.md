# BugSigDbAssistant
An LLM- and RAG-based assistant for BugSigDB

## Demo

Make an `.env` and `.Renviron`. You should make a key and put it on pons1.

    docker compose up

## Testing

    docker compose exec -w /srv/shiny-server/BugSigDbAssistant app Rscript tests/test_snippets.R
