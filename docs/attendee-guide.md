# Databricks Apps vibe coding workshop - attendee guide

## Overview

In this workshop, you'll use Claude Code to build Databricks Apps. You'll connect to a Databricks cluster via SSH (tunneled over HTTPS) and use Claude Code with Databricks Model Serving.

## Prerequisites

Before the workshop, ensure you have:

1. **Databricks CLI** installed
2. **VSCode** with Remote SSH extension
3. **Databricks workspace access** (you should be able to log in)

---

## Part 1: Install Databricks CLI

### macOS

```bash
brew install databricks
```

### Windows (PowerShell as Administrator)

```powershell
winget install Databricks.DatabricksCLI
```

### Verify installation

```bash
databricks --version
```

---

## Part 2: Authenticate to Databricks

### Option A: OAuth (recommended)

```bash
databricks auth login \
    --host https://<workspace>.azuredatabricks.net \
    --profile workshop
```

This opens a browser for authentication. After completing, verify:

```bash
databricks auth describe --profile workshop
```

### Option B: Personal Access Token

```bash
databricks configure --profile workshop
```

Enter:
- Host: `https://<workspace>.azuredatabricks.net`
- Token: Your personal access token (generate from User Settings → Developer → Access Tokens)

---

## Part 3: Set up SSH connection

### Get your cluster ID

Your facilitator will provide cluster details, or find it in the Databricks UI:
- Navigate to Compute
- Click on your cluster
- The URL contains the cluster ID: `.../clusters/<cluster-id>/...`

### Run SSH setup

```bash
databricks ssh setup \
    --profile workshop \
    --name my-workshop-cluster \
    --cluster <your-cluster-id>
```

You'll see output like:
```
Updated SSH config file at ~/.ssh/config with 'my-workshop-cluster' host
```

### Test the connection

```bash
ssh my-workshop-cluster
```

If the cluster is stopped, it will auto-start (wait 2-3 minutes).

Once connected, you should see a prompt like:
```
root@0203-041738-q4p5oucf-10-139-64-4:~#
```

Type `exit` to disconnect for now.

---

## Part 4: Connect with VSCode

### Install Remote SSH extension

1. Open VSCode
2. Go to Extensions (Cmd+Shift+X / Ctrl+Shift+X)
3. Search for "Remote - SSH"
4. Install "Remote - SSH" by Microsoft

### Connect to cluster

1. Press Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
2. Type "Remote-SSH: Connect to Host"
3. Select `my-workshop-cluster`
4. Wait for VSCode to connect and set up

### Open a workspace folder

1. Click "Open Folder"
2. Navigate to `/home/ubuntu/` or create a new folder
3. Click OK

You now have a full VSCode environment on the Databricks cluster.

---

## Part 5: Use Claude Code

### Verify installation

In the VSCode terminal (Terminal → New Terminal):

```bash
# Source environment (if needed)
source ~/.bashrc

# Run diagnostic check
check-claude
```

This shows:
- Claude Code installation status
- Environment variables (ANTHROPIC_BASE_URL, ANTHROPIC_AUTH_TOKEN, etc.)
- Model Serving configuration

### Start Claude Code

```bash
claude
```

### Try your first prompt

```
Create a simple Python Databricks App that displays "Hello World"
```

Claude will generate the code. You can:
- Ask follow-up questions
- Request modifications
- Have Claude explain what it created

---

## Part 6: Build a Databricks App

### Create app structure

Ask Claude:
```
Create a Databricks App with:
- A Dash dashboard
- A simple chart showing sample data
- An input field to filter the data
```

### Deploy the app

```bash
databricks apps deploy my-first-app --source-code-path ./my-app
```

### View the app

Get the app URL:
```bash
databricks apps get my-first-app
```

Open the URL in your browser.

---

## Troubleshooting

### "databricks: command not found"

The CLI isn't in your PATH. Try:
```bash
# macOS - restart terminal or run:
eval "$(/opt/homebrew/bin/brew shellenv)"

# Windows - restart PowerShell
```

### SSH connection times out

1. Check your cluster is running:
   ```bash
   databricks clusters get --cluster-id <id> --profile workshop
   ```

2. Try starting it manually:
   ```bash
   databricks clusters start --cluster-id <id> --profile workshop
   ```

### "Permission denied (publickey)"

Re-run the SSH setup:
```bash
databricks ssh setup --profile workshop --name my-workshop-cluster --cluster <id>
```

### VSCode can't connect

1. Try SSH from terminal first: `ssh my-workshop-cluster`
2. If terminal works but VSCode doesn't, reload VSCode window
3. Check `~/.ssh/config` has the host entry

### "claude: command not found"

```bash
# Source the environment
source ~/.bashrc

# If still not found, check installation
check-claude
```

### Authentication issues

```bash
# Check token status
claude-token-status

# Refresh token if needed
claude-refresh-token

# Debug configuration
claude-debug
```

---

## Tips for effective vibe coding

1. **Be specific** - "Add a dropdown to filter by date range" is better than "make it filterable"

2. **Iterate** - Start simple, then add features one at a time

3. **Review the code** - Ask Claude to explain what it generated

4. **Use the context** - Claude can see your files, so reference them: "Update the chart in app.py"

5. **Ask for help** - "What's wrong with this error: [paste error]"

---

## Getting help

- Raise your hand for in-person assistance
- Post in the workshop Slack/Teams channel
- Ask Claude: `claude "How do I deploy a Databricks App?"`

---

## Quick reference

| Task | Command |
|------|---------|
| Connect to cluster | `ssh my-workshop-cluster` |
| Start Claude Code | `claude` |
| Check installation | `check-claude` |
| Refresh auth token | `claude-refresh-token` |
| Debug config | `claude-debug` |
| Deploy app | `databricks apps deploy <name> --source-code-path <path>` |
| Check app status | `databricks apps get <name>` |
| View app logs | `databricks apps logs <name>` |

## Helper commands reference

The init script provides these helper commands:

| Command | Purpose |
|---------|---------|
| `check-claude` | Full diagnostic - installation, env vars, auth |
| `claude-debug` | Show settings.json and environment |
| `claude-refresh-token` | Regenerate auth from DATABRICKS_TOKEN |
| `claude-token-status` | Check if token is current |
| `claude-vscode-setup` | VSCode/Cursor Remote SSH guide |
| `claude-vscode-env` | Get Python interpreter path |
| `claude-tracing-enable` | Enable MLflow tracing |
| `claude-tracing-status` | Check tracing status |
