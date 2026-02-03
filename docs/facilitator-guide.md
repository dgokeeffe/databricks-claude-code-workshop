# Databricks Apps vibe coding workshop - facilitator guide

## Architecture overview

```
140 Developers                         Databricks Workspace
┌──────────────┐                      ┌─────────────────────┐
│ Dev laptop   │                      │ 140 Single-User     │
│ + VSCode     │──databricks ssh──────▶│ Clusters            │
│ + DB CLI     │   (HTTPS/443)        │ (1 per attendee)    │
└──────────────┘                      │                     │
                                      │ Model Serving       │
                                      │ (anthropic endpoint)│
                                      └─────────────────────┘
```

**Key constraints**:
- Remote SSH requires dedicated single-user clusters (no sharing)
- Each attendee gets their own VM
- 140 clusters total for full workshop

## Pre-workshop checklist

### 2 weeks before

- [ ] Confirm `databricks ssh setup` works through corporate proxy
- [ ] Test Model Serving endpoint (`/serving-endpoints/anthropic`)
- [ ] Upload init script to Unity Catalog volume
- [ ] Create cluster policy
- [ ] Create instance pool (for faster cluster startup)
- [ ] Test end-to-end: CLI → SSH → Claude Code → Model Serving

### 1 week before

- [ ] Send pre-workshop instructions to attendees (install CLI, VSCode)
- [ ] Confirm all 140 attendees have workspace access
- [ ] Pre-provision clusters (optional - reduces day-of startup time)
- [ ] Set up support Slack/Teams channel

### Day before

- [ ] Warm up instance pool
- [ ] Verify Model Serving endpoint is responsive
- [ ] Test from a Windows machine with ZScaler

### Day of

- [ ] Start instance pool early (30 min before)
- [ ] Have support staff ready for setup issues

---

## Infrastructure setup

### 1. Upload init script to Unity Catalog

```bash
# Create volume if needed
databricks volumes create \
    --catalog-name main \
    --schema-name default \
    --name init_scripts \
    --volume-type MANAGED

# Upload script
databricks fs cp ./init-scripts/install-claude-code.sh \
    dbfs:/Volumes/main/default/init_scripts/install-claude-code.sh
```

### 2. Create cluster policy

```bash
databricks cluster-policies create --json-file ./cluster-config/cluster-policy.json
```

### 3. Create instance pool

Pre-warmed instances reduce cluster startup from ~5 min to ~1 min.

```bash
databricks instance-pools create --json-file ./cluster-config/instance-pool-config.json
```

### 4. Pre-provision clusters (optional)

Create a file `attendees.txt` with one email per line:

```
user1@company.com
user2@company.com
...
```

Then run:
```bash
./scripts/provision-clusters.sh attendees.txt
```

---

## Cost estimation

### Per-cluster cost

| VM Type | vCPUs | RAM | Cost/hr (Azure) |
|---------|-------|-----|-----------------|
| Standard_DS3_v2 | 4 | 14 GB | ~$0.20 |
| Standard_DS4_v2 | 8 | 28 GB | ~$0.40 |
| Standard_E4ds_v4 | 4 | 32 GB | ~$0.30 |

### Workshop cost (140 attendees)

| Scenario | Duration | Clusters | Est. cost |
|----------|----------|----------|-----------|
| Half-day (4 hrs) | 4 hrs | 140 | ~$112 - $224 |
| Full-day (8 hrs) | 8 hrs | 140 | ~$224 - $448 |

Plus:
- Instance pool idle costs (minimal)
- Model Serving tokens (depends on usage)

### Cost controls

1. **Auto-termination**: Set to 60 min in cluster policy
2. **Max clusters per user**: 1 (enforced by policy)
3. **Instance pool**: Only pay for running instances
4. **Cleanup script**: Run after workshop

---

## Workshop flow

### Pre-workshop (async)

Send attendees:
1. Install Databricks CLI
2. Install VSCode + Remote SSH extension
3. Test CLI authentication: `databricks auth login`

### Opening (15 min)

1. Welcome, introductions
2. Verify everyone has CLI installed
3. Walk through SSH setup

### Setup (20 min)

1. Run `databricks ssh setup`
2. Test SSH connection
3. Connect VSCode
4. Run `check-claude` to verify installation

### Hands-on (2-3 hrs)

1. **Guided exercise**: Build a simple Dash app
2. **Free build**: Create your own app
3. Facilitators circulate for support

### Wrap-up (15 min)

1. Showcase interesting apps
2. Share resources
3. Collect feedback

---

## Helper commands reference

The init script provides these commands on the cluster:

| Command | Purpose |
|---------|---------|
| `check-claude` | Full diagnostic check |
| `claude-debug` | Show config and env vars |
| `claude-refresh-token` | Regenerate auth from DATABRICKS_TOKEN |
| `claude-token-status` | Check token freshness |
| `claude-vscode-setup` | VSCode Remote SSH guide |
| `claude-vscode-env` | Get Python interpreter path |
| `claude-vscode-check` | Verify VSCode setup |
| `claude-tracing-enable` | Enable MLflow tracing |

---

## Troubleshooting

### "databricks: command not found"

CLI not installed or not in PATH.

```bash
# macOS
brew install databricks

# Windows
winget install Databricks.DatabricksCLI

# Verify
databricks --version
```

### SSH connection fails

```bash
# Check authentication
databricks auth describe --profile <profile>

# Re-run SSH setup
databricks ssh setup --profile <profile> --name <alias> --cluster <id>

# Test with verbose output
ssh -v <alias>
```

### "claude: command not found" on cluster

```bash
# Source environment
source ~/.bashrc

# Run diagnostic
check-claude

# If init script failed, check logs
cat /tmp/init-script-claude.log
```

### Claude authentication errors

```bash
# Check token status
claude-token-status

# Refresh token
claude-refresh-token

# Debug config
claude-debug
```

### Model Serving not responding

```bash
# Test endpoint
curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    "${DATABRICKS_HOST}/serving-endpoints/anthropic/invocations"
```

Expected: 200 or 400 (not 403/404/timeout)

### Cluster won't start

1. Check instance pool capacity
2. Check cluster policy limits
3. Check Azure subscription quota
4. Contact workspace admin

---

## Post-workshop cleanup

```bash
# Dry run (see what would be deleted)
./scripts/cleanup-workshop.sh --dry-run

# Actually delete
./scripts/cleanup-workshop.sh --execute
```

This removes:
- All clusters matching `claude-code-workshop-*`
- Instance pool (optional)

Does NOT remove:
- Cluster policy (reusable)
- Init scripts (reusable)
- Files created by attendees

---

## Support contacts

| Role | Name | Contact |
|------|------|---------|
| Lead facilitator | | |
| Databricks admin | | |
| IT/Network support | | |
