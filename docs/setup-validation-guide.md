# Setup validation guide

Step-by-step guide to validate the workshop setup works end-to-end.

---

## Prerequisites

### Windows users - critical note

> **If using Windows VSCode**: Run `databricks ssh setup` from Windows CMD/PowerShell, NOT from WSL.
>
> The SSH config must be on the same side as your IDE. If you set up SSH in WSL but use Windows VSCode, it won't work.

See `windows-setup-guide.md` for detailed Windows instructions.

---

### 1. Databricks CLI

The Databricks CLI is required for:
- SSH tunneling to clusters (via `databricks ssh setup`)
- Deploying Databricks Apps (via `databricks apps deploy`)
- Managing clusters and authentication

#### macOS

```bash
brew install databricks
```

#### Windows (PowerShell as Administrator)

```powershell
winget install Databricks.DatabricksCLI
```

#### Linux

```bash
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
```

#### Verify installation

```bash
databricks --version
```

**Expected**: Version 0.200+ (e.g., `Databricks CLI v0.218.0`)

---

### 2. VSCode with Remote SSH extension

Required for the full IDE experience on the cluster.

1. Install [VSCode](https://code.visualstudio.com/download)
2. Install the "Remote - SSH" extension:
   - Open VSCode
   - Go to Extensions (Cmd+Shift+X / Ctrl+Shift+X)
   - Search "Remote - SSH"
   - Install "Remote - SSH" by Microsoft

---

### 3. Databricks workspace access

You need:
- Access to the Databricks workspace
- Permission to create clusters (or a pre-provisioned cluster)
- Model Serving endpoint `anthropic` available

---

## Validation steps

### Step 1: Authenticate Databricks CLI

```bash
databricks auth login \
    --host https://<workspace>.azuredatabricks.net \
    --profile workshop
```

This opens a browser for OAuth authentication.

**Verify:**
```bash
databricks auth describe --profile workshop
```

**Expected output:**
```
Host: https://<workspace>.azuredatabricks.net
User: your.email@company.com
Authenticated: yes
```

**Pass criteria**: `Authenticated: yes`

---

### Step 2: List clusters

```bash
databricks clusters list --profile workshop
```

**Expected**: List of clusters in the workspace (may be empty)

**Pass criteria**: Command succeeds without authentication errors

---

### Step 3: Create or identify a test cluster

If you have an existing cluster with the init script, note its ID.

Otherwise, create a test cluster:

```bash
databricks clusters create --profile workshop --json '{
  "cluster_name": "claude-code-test",
  "spark_version": "14.3.x-scala2.12",
  "node_type_id": "Standard_DS3_v2",
  "num_workers": 0,
  "autotermination_minutes": 60,
  "data_security_mode": "SINGLE_USER",
  "single_user_name": "your.email@company.com",
  "init_scripts": [
    {
      "volumes": {
        "destination": "/Volumes/main/default/init_scripts/install-claude-code.sh"
      }
    }
  ]
}'
```

**Note the cluster ID** from the output (e.g., `0203-041738-q4p5oucf`)

---

### Step 4: Start the cluster

```bash
databricks clusters start --cluster-id <cluster-id> --profile workshop
```

Wait for cluster to be running:

```bash
databricks clusters get --cluster-id <cluster-id> --profile workshop | grep state
```

**Expected**: `"state": "RUNNING"`

**Pass criteria**: Cluster reaches RUNNING state

---

### Step 5: Set up SSH connection

```bash
databricks ssh setup \
    --profile workshop \
    --name test-cluster \
    --cluster <cluster-id>
```

**Expected output:**
```
Created backup of existing SSH config at ~/.ssh/config.bak
Adding new entry to the SSH config:

Host test-cluster
    User root
    ConnectTimeout 360
    StrictHostKeyChecking accept-new
    IdentitiesOnly yes
    IdentityFile "~/.databricks/ssh-tunnel-keys/<cluster-id>"
    ProxyCommand "databricks" ssh connect --proxy --cluster=<cluster-id> --auto-start-cluster=true --profile=workshop

Updated SSH config file at ~/.ssh/config with 'test-cluster' host
```

**Pass criteria**: SSH config entry created

---

### Step 6: Test SSH connection

```bash
ssh test-cluster
```

**Expected**: Shell prompt on the cluster (e.g., `root@0203-041738-q4p5oucf:~#`)

**Pass criteria**: SSH session opens successfully

---

### Step 7: Verify Claude Code installation

On the cluster (via SSH):

```bash
source ~/.bashrc
check-claude
```

**Expected output includes:**
```
[OK] Claude Code CLI: /root/.claude/bin/claude
[OK] DATABRICKS_HOST: https://<workspace>.azuredatabricks.net
[OK] DATABRICKS_TOKEN: dapi...
[OK] ANTHROPIC_AUTH_TOKEN: dapi...
[OK] ANTHROPIC_BASE_URL: https://<workspace>.azuredatabricks.net/serving-endpoints/anthropic
[OK] ANTHROPIC_MODEL: databricks-claude-sonnet-4-5
```

**Pass criteria**: All environment variables show `[OK]`

If Claude Code is not installed, check init script logs:
```bash
cat /tmp/init-script-claude.log
```

---

### Step 8: Test Claude Code with Model Serving

On the cluster:

```bash
echo "What is 2+2?" | claude --print
```

**Expected**: Claude responds with "4" (or similar)

**Pass criteria**: Claude responds without authentication errors

If this fails, check:
```bash
claude-debug
```

---

### Step 9: Test VSCode Remote SSH

1. Open VSCode
2. Press Cmd+Shift+P (Mac) / Ctrl+Shift+P (Windows)
3. Type "Remote-SSH: Connect to Host"
4. Select `test-cluster`
5. Wait for VSCode to connect

**Expected**: VSCode opens with remote connection to cluster

**Pass criteria**: VSCode shows "SSH: test-cluster" in bottom-left corner

---

### Step 10: Test Claude Code in VSCode terminal

In VSCode (connected to cluster):

1. Open terminal: Terminal → New Terminal
2. Run:
   ```bash
   source ~/.bashrc
   claude --version
   ```

**Expected**: Claude Code version displayed

**Pass criteria**: Claude Code accessible from VSCode terminal

---

### Step 11: Test Databricks Apps deployment

On the cluster, create a simple test app:

```bash
mkdir -p ~/test-app
cat > ~/test-app/app.py << 'EOF'
import gradio as gr

def greet(name):
    return f"Hello, {name}!"

demo = gr.Interface(fn=greet, inputs="text", outputs="text")
demo.launch(server_name="0.0.0.0", server_port=8080)
EOF

cat > ~/test-app/app.yaml << 'EOF'
command:
  - python
  - app.py
EOF
```

Deploy the app (from local machine or cluster):

```bash
databricks apps deploy test-app-validation \
    --source-code-path ~/test-app \
    --profile workshop
```

**Expected**: App deploys successfully

Check status:
```bash
databricks apps get test-app-validation --profile workshop
```

**Pass criteria**: App shows `RUNNING` state

Clean up:
```bash
databricks apps delete test-app-validation --profile workshop
```

---

## Validation summary

| Step | Test | Status |
|------|------|--------|
| 1 | CLI authentication | [ ] Pass  [ ] Fail |
| 2 | List clusters | [ ] Pass  [ ] Fail |
| 3 | Create/identify cluster | [ ] Pass  [ ] Fail |
| 4 | Start cluster | [ ] Pass  [ ] Fail |
| 5 | SSH setup | [ ] Pass  [ ] Fail |
| 6 | SSH connection | [ ] Pass  [ ] Fail |
| 7 | Claude Code installed | [ ] Pass  [ ] Fail |
| 8 | Claude + Model Serving | [ ] Pass  [ ] Fail |
| 9 | VSCode Remote SSH | [ ] Pass  [ ] Fail |
| 10 | Claude in VSCode | [ ] Pass  [ ] Fail |
| 11 | App deployment | [ ] Pass  [ ] Fail |

**Overall result**: [ ] Ready for workshop  [ ] Blockers identified

---

## Common issues

### CLI authentication fails

```
Error: cannot get access token
```

**Fix**: Re-run `databricks auth login` and complete browser authentication

---

### SSH connection times out

```
ssh: connect to host test-cluster: Connection timed out
```

**Possible causes:**
1. Cluster not running - start it with `databricks clusters start`
2. Proxy blocking - check if corporate proxy allows the connection
3. CLI not authenticated - re-run `databricks auth login`

**Debug:**
```bash
ssh -v test-cluster
```

---

### "claude: command not found"

**Fix:**
```bash
source ~/.bashrc
```

If still not found, init script may have failed:
```bash
cat /tmp/init-script-claude.log
```

---

### Claude authentication error

```
Error: 401 Unauthorized
```

**Fix:**
```bash
claude-refresh-token
```

If still failing, check Model Serving endpoint:
```bash
curl -s -w "\n%{http_code}" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    "${DATABRICKS_HOST}/serving-endpoints/anthropic/invocations" \
    -d '{"messages":[{"role":"user","content":"hi"}],"model":"claude-sonnet-4-5-20250514"}'
```

---

### VSCode can't connect

1. Test SSH from terminal first: `ssh test-cluster`
2. If terminal works, reload VSCode window
3. Check `~/.ssh/config` has the host entry

---

### App deployment fails

```
Error: permission denied
```

**Check:**
- Do you have permission to deploy apps?
- Is the source path correct?
- Is there a valid `app.yaml`?

---

## Next steps after validation

1. **Upload init script** to Unity Catalog volume
2. **Create cluster policy** for workshop
3. **Create instance pool** for faster startup
4. **Test from Windows machine** with ZScaler
5. **Document any workarounds** needed for your environment
