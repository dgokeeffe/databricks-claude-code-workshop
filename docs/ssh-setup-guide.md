# SSH setup guide for Claude Code workshop

This guide walks through setting up SSH access to Databricks clusters using the Databricks CLI's ProxyCommand approach. This tunnels SSH over HTTPS (port 443), bypassing port 22 restrictions.

## How it works

```
Local machine → Databricks CLI (HTTPS/443) → Cluster SSH
                      ↓
              ProxyCommand tunnels SSH
              through Databricks API
```

Unlike direct SSH (port 22), this approach:
- Uses HTTPS (port 443) which passes through corporate proxies
- Authenticates via Databricks CLI profile
- Auto-starts clusters on connection
- Works with VSCode Remote SSH extension

## Prerequisites

### 1. Databricks CLI installed

```bash
# macOS
brew install databricks

# Windows (PowerShell)
winget install Databricks.DatabricksCLI

# Or via pip
pip install databricks-cli
```

Verify installation:
```bash
databricks --version
```

### 2. Databricks CLI profile configured

```bash
# Interactive setup
databricks configure --profile <profile-name>

# Or using OAuth (recommended)
databricks auth login --host https://<workspace>.azuredatabricks.net --profile <profile-name>
```

Verify authentication:
```bash
databricks clusters list --profile <profile-name>
```

### 3. Cluster running (or will auto-start)

You need a cluster ID. Get it from the Databricks UI (Compute → Cluster → URL contains cluster ID) or:

```bash
databricks clusters list --profile <profile-name> --output JSON | jq '.[] | {name: .cluster_name, id: .cluster_id, state: .state}'
```

---

## Step-by-step setup

### Step 1: Run SSH setup command

```bash
databricks ssh setup \
    --profile <your-profile> \
    --name <ssh-host-alias> \
    --cluster <cluster-id>
```

**Example:**
```bash
databricks ssh setup \
    --profile az-field-east \
    --name claude-az-field-east \
    --cluster 0203-041738-q4p5oucf
```

**Output:**
```
Created backup of existing SSH config at /Users/<user>/.ssh/config.bak
Adding new entry to the SSH config:

Host claude-az-field-east
    User root
    ConnectTimeout 360
    StrictHostKeyChecking accept-new
    IdentitiesOnly yes
    IdentityFile "/Users/<user>/.databricks/ssh-tunnel-keys/<cluster-id>"
    ProxyCommand "/opt/homebrew/bin/databricks" ssh connect --proxy --cluster=<cluster-id> --auto-start-cluster=true --shutdown-delay=10m0s --profile=<profile>

Updated SSH config file at /Users/<user>/.ssh/config with '<alias>' host
```

### Step 2: Test SSH connection

```bash
ssh <ssh-host-alias>
```

**Example:**
```bash
ssh claude-az-field-east
```

If the cluster is stopped, it will auto-start (may take 2-3 minutes).

### Step 3: Verify you're on the cluster

Once connected:
```bash
hostname
# Should show something like: 0203-041738-q4p5oucf-10-139-64-4

whoami
# root
```

---

## Using with VSCode Remote SSH

### Step 1: Install Remote SSH extension

In VSCode, install the "Remote - SSH" extension (ms-vscode-remote.remote-ssh).

### Step 2: Connect to cluster

1. Press `Cmd+Shift+P` (Mac) or `Ctrl+Shift+P` (Windows)
2. Type "Remote-SSH: Connect to Host"
3. Select the SSH alias you created (e.g., `claude-az-field-east`)
4. VSCode will connect and install the server component

### Step 3: Open workspace

Once connected:
1. Click "Open Folder"
2. Navigate to your working directory (e.g., `/home/ubuntu/` or `/databricks/driver/`)
3. Start coding with full VSCode features

---

## Using Claude Code on the cluster

### Step 1: Connect via SSH

```bash
ssh <ssh-host-alias>
```

### Step 2: Verify Claude Code is installed

```bash
claude --version
```

If not installed, run the init script or install manually:
```bash
# Install Node.js
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# Install Claude Code
sudo npm install -g @anthropic-ai/claude-code
```

### Step 3: Configure authentication

For Databricks Model Serving endpoint:
```bash
# Set the endpoint (get from your workspace admin)
export ANTHROPIC_BASE_URL="https://<workspace>.azuredatabricks.net/serving-endpoints/<endpoint-name>/invocations"

# Authentication uses Databricks token
export DATABRICKS_TOKEN="<your-token>"
```

### Step 4: Start Claude Code

```bash
claude
```

---

## Troubleshooting

### "Connection refused" or timeout

1. Check cluster is running:
   ```bash
   databricks clusters get --cluster-id <cluster-id> --profile <profile>
   ```

2. Check CLI authentication:
   ```bash
   databricks auth describe --profile <profile>
   ```

3. Try connecting with verbose output:
   ```bash
   ssh -v <ssh-host-alias>
   ```

### "Permission denied (publickey)"

The SSH key may not have been set up correctly. Re-run:
```bash
databricks ssh setup --profile <profile> --name <alias> --cluster <cluster-id>
```

### Cluster auto-terminates during session

The `--shutdown-delay` flag in the ProxyCommand controls this. Default is 10 minutes after disconnect. To change:

1. Edit `~/.ssh/config`
2. Find your host entry
3. Modify `--shutdown-delay=30m0s` (or desired duration)

### VSCode can't find the host

1. Check `~/.ssh/config` has the entry
2. Reload VSCode window
3. Try connecting from terminal first to verify

### Proxy/corporate network issues

If connection fails through corporate proxy:

1. Ensure Databricks CLI proxy is configured:
   ```bash
   export HTTPS_PROXY=https://proxy.corp.com:8080
   databricks auth login --profile <profile>
   ```

2. Check if the CLI can reach Databricks:
   ```bash
   databricks clusters list --profile <profile>
   ```

---

## Windows-specific notes

### PowerShell setup

```powershell
# Install Databricks CLI
winget install Databricks.DatabricksCLI

# Configure profile
databricks auth login --host https://<workspace>.azuredatabricks.net --profile <profile-name>

# Setup SSH
databricks ssh setup --profile <profile-name> --name <alias> --cluster <cluster-id>
```

### SSH config location

On Windows, the SSH config is at:
```
C:\Users\<username>\.ssh\config
```

### VSCode on Windows

The Remote SSH extension works the same way. Ensure OpenSSH client is installed:
```powershell
# Check if installed
ssh -V

# If not, install via Settings > Apps > Optional Features > OpenSSH Client
```

---

## Quick reference

| Command | Purpose |
|---------|---------|
| `databricks ssh setup --profile P --name N --cluster C` | Configure SSH host |
| `ssh <alias>` | Connect to cluster |
| `databricks clusters start --cluster-id C --profile P` | Start cluster manually |
| `databricks clusters get --cluster-id C --profile P` | Check cluster status |
| `cat ~/.ssh/config` | View SSH configuration |

---

## Next steps

After connecting:
1. Verify Claude Code works: `claude --version`
2. Configure Model Serving endpoint
3. Start building Databricks Apps with Claude Code
