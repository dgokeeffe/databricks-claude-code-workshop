# Databricks Apps vibe coding workshop

Workshop materials for building Databricks Apps with Claude Code.

## Architecture

```
Developer laptop                      Databricks
┌─────────────────┐                  ┌──────────────────┐
│ VSCode          │                  │ Dedicated Cluster│
│ + Remote SSH    │──ProxyCommand───▶│ (1 per user)     │
│                 │   (HTTPS/443)    │ + Claude Code    │
└─────────────────┘                  │ + Model Serving  │
                                     └──────────────────┘
```

**Key insight**: `databricks ssh setup` uses ProxyCommand to tunnel SSH through the Databricks CLI over HTTPS (port 443). This bypasses port 22 restrictions and works through corporate proxies.

**Important**: Remote SSH requires a dedicated single-user cluster per attendee. Each user gets their own VM.

**Cluster config**: DBR 17.3 ML (`17.3.x-cpu-ml-scala2.13`), Single Node, Dedicated (SINGLE_USER)

## Quick start

```bash
# 1. Install Databricks CLI
brew install databricks  # macOS
# or: winget install Databricks.DatabricksCLI  # Windows

# 2. Authenticate
databricks auth login --host https://<workspace>.azuredatabricks.net --profile workshop

# 3. Setup SSH to cluster
databricks ssh setup --profile workshop --name my-cluster --cluster <cluster-id>

# 4. Connect
ssh my-cluster

# 5. Use Claude Code
claude
```

## Directory structure

```
databricks-workshop/
├── init-scripts/
│   ├── install-claude-code.sh          # Install Claude Code on cluster startup
│   └── install-claude-code-offline.sh  # Offline variant for restricted VNets
├── cluster-config/
│   ├── cluster-policy.json             # Cluster policy
│   ├── cluster-config.json             # Sample cluster configuration
│   └── instance-pool-config.json       # Instance pool for pre-warming
├── scripts/
│   ├── setup-workshop.sh               # Automated infrastructure setup
│   ├── provision-clusters.sh           # Provision clusters for attendees
│   └── cleanup-workshop.sh             # Post-workshop cleanup
└── docs/
    ├── attendee-guide.md               # Step-by-step for attendees
    ├── facilitator-guide.md            # Setup and troubleshooting for facilitators
    ├── ssh-setup-guide.md              # Detailed SSH configuration guide
    ├── pre-workshop-checklist.md       # Validation checklist
    └── troubleshooting-runbook.md      # Common issues and fixes
```

## How SSH ProxyCommand works

The `databricks ssh setup` command creates an SSH config entry like:

```
Host my-cluster
    User root
    ProxyCommand "databricks" ssh connect --proxy --cluster=<id> --profile=<profile>
```

When you run `ssh my-cluster`:
1. SSH invokes the ProxyCommand
2. Databricks CLI establishes an HTTPS connection to the workspace
3. The CLI proxies the SSH traffic through this HTTPS tunnel
4. You get a shell on the cluster

Benefits:
- Uses HTTPS (443) not SSH (22) - works through corporate firewalls
- Authenticates via Databricks CLI profile - no separate SSH keys to manage
- Auto-starts clusters with `--auto-start-cluster=true`

## Workshop flow

1. **Pre-workshop**: Attendees install Databricks CLI and VSCode Remote SSH extension
2. **Setup (15 min)**: Configure CLI profile, run `databricks ssh setup`
3. **Coding (2-3 hours)**: Build Databricks Apps with Claude Code
4. **Showcase**: Share interesting apps built during the workshop

## Support

See `docs/troubleshooting-runbook.md` for common issues.
