# Operations

## Jetstream2 SSH Tunnel

The LLM inference service runs via an SSH tunnel to pons1, a Jetstream2 instance
that relays traffic to `llm.jetstream-cloud.org`. The tunnel runs as a Docker service
and starts automatically with `docker compose up`.

**Setup requirements for each developer:**

1. Your SSH public key must be in pons1's `~/.ssh/authorized_keys` — contact a team
   member to add it
2. Create a passphrase-free SSH key for the tunnel:
   ```bash
   ssh-keygen -t ed25519 -f ~/.ssh/bugsigassistant_tunnel -N ""
   ```
3. Create a `.env` file in the project root (never committed):
   ```bash
   PONS1_IP=           # ask a team member
   SSH_KEY_PATH=       # full path to your passphrase-free key
   ```

**Verify the tunnel is working:**
```bash
docker compose exec tunnel wget -q -O- \
  --header="Authorization: bearer placeholder" \
  https://llm.jetstream-cloud.org:11435/gpt-oss-120b/v1/models
```

## Running Tests

```bash
# Part A — RCODE snippet retrieval
docker compose exec -w /srv/shiny-server/BugSigAssistant app Rscript tests/test_snippets.R

# Part B — DATA discovery (runs against live LLM via tunnel)
docker compose exec -w /srv/shiny-server/BugSigAssistant app Rscript tests/test_data_discovery.R
```

Part B auto-detects `LLM_ENDPOINT` and `LLM_MODEL` from the Docker environment and
runs against the live Jetstream2 endpoint automatically.
