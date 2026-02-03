# Windows setup guide

Detailed instructions for setting up the workshop environment on Windows.

---

## Critical: WSL vs Windows

> **Important**: If you use Windows VSCode, you MUST run `databricks ssh setup` from Windows (CMD or PowerShell), NOT from WSL.

The SSH config must be on the same side as your IDE:

| Setup location | IDE location | Works? |
|----------------|--------------|--------|
| Windows CMD/PowerShell | Windows VSCode | ✅ Yes |
| WSL | WSL-based VSCode | ✅ Yes |
| WSL | Windows VSCode | ❌ No |

This is a known issue documented by Databricks. If you set up SSH in WSL but use Windows VSCode, VSCode won't find the SSH config.

---

## Prerequisites check

### 1. Check Windows version

```powershell
winver
```

**Required**: Windows 10 version 1809+ or Windows 11

OpenSSH client is built into these versions but may need to be enabled.

---

### 2. Check if OpenSSH client is installed

```powershell
ssh -V
```

**Expected**: `OpenSSH_for_Windows_8.x` or similar

If not found, see [Installing OpenSSH](#installing-openssh) below.

---

### 3. Check if OpenSSH is blocked

Some corporate environments block OpenSSH. Test:

```powershell
Get-WindowsCapability -Online | Where-Object Name -like 'OpenSSH.Client*'
```

**Expected**: `State: Installed`

If `State: NotPresent` or blocked, you may need IT assistance.

---

## Installing OpenSSH

### Option A: Via Windows Settings (recommended)

1. Open **Settings** → **Apps** → **Optional Features**
2. Click **Add a feature**
3. Search for "OpenSSH Client"
4. Click **Install**

### Option B: Via PowerShell (as Administrator)

```powershell
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

### Option C: Via Git for Windows

If OpenSSH is blocked, Git for Windows includes its own SSH client:

1. Download [Git for Windows](https://gitforwindows.org/)
2. During install, select "Use OpenSSH"
3. Use Git Bash instead of PowerShell

---

## Installing Databricks CLI

Corporate Windows environments often block `winget` and `chocolatey`. Use the manual download method.

### Option A: Manual ZIP download (recommended for corporate Windows)

This works even when package managers are blocked by IT.

**Step 1: Check your CPU architecture**

```powershell
echo $env:PROCESSOR_ARCHITECTURE
```

- `AMD64` = 64-bit Intel/AMD (most common)
- `ARM64` = ARM processor
- `x86` = 32-bit (rare)

**Step 2: Download the ZIP file**

Go to: **https://github.com/databricks/cli/releases**

Find the latest release (has "Latest" label) and download:
- `databricks_cli_X.Y.Z_windows_amd64.zip` for AMD64
- `databricks_cli_X.Y.Z_windows_arm64.zip` for ARM64
- `databricks_cli_X.Y.Z_windows_386.zip` for x86

**Step 3: Extract the ZIP**

1. Right-click the downloaded ZIP → **Extract All**
2. Extract to a folder like `C:\databricks-cli\`

**Step 4: Add to PATH**

1. Press Windows key, search "Environment Variables"
2. Click "Edit the system environment variables"
3. Click **Environment Variables** button
4. Under "User variables", select **Path** → **Edit**
5. Click **New** and add: `C:\databricks-cli\`
6. Click **OK** on all dialogs

**Step 5: Restart PowerShell and verify**

```powershell
databricks --version
```

---

### Option B: Via curl (if available)

Windows 10+ has curl built-in. Run as Administrator:

```powershell
curl -fsSL https://raw.githubusercontent.com/databricks/setup-cli/main/install.sh | sh
```

Installs to `C:\Windows\databricks.exe`.

---

### Option C: Via winget (if IT allows)

```powershell
winget install Databricks.DatabricksCLI
```

Restart PowerShell after installation.

---

### Option D: Via Chocolatey (if IT allows)

```powershell
choco install databricks-cli
```

---

### Verify installation

```powershell
databricks --version
```

**Required**: Version `0.269.0` or higher (SSH tunnel requires this version)

---

## Authenticating to Databricks

```powershell
databricks auth login --host https://<workspace>.azuredatabricks.net --profile workshop
```

This opens a browser for OAuth authentication.

Verify:

```powershell
databricks auth describe --profile workshop
```

---

## Setting up SSH

### Run SSH setup

```powershell
databricks ssh setup --profile workshop --name my-cluster --cluster <cluster-id>
```

**Expected output:**

```
Updated SSH config file at C:\Users\<username>\.ssh\config with 'my-cluster' host
```

### Check SSH config was created

```powershell
Get-Content $env:USERPROFILE\.ssh\config
```

Should contain an entry like:

```
Host my-cluster
    User root
    ConnectTimeout 360
    StrictHostKeyChecking accept-new
    IdentitiesOnly yes
    IdentityFile "C:\Users\<username>\.databricks\ssh-tunnel-keys\<cluster-id>"
    ProxyCommand "C:\Program Files\Databricks\CLI\databricks.exe" ssh connect --proxy --cluster=<cluster-id> --auto-start-cluster=true --profile=workshop
```

---

## Testing SSH connection

### From PowerShell

```powershell
ssh my-cluster
```

**Expected**: Shell prompt on the cluster

### If SSH fails

1. **Check OpenSSH is working:**
   ```powershell
   ssh -V
   ```

2. **Test with verbose output:**
   ```powershell
   ssh -v my-cluster
   ```

3. **Check the ProxyCommand path:**
   - Look at the SSH config
   - Verify the `databricks.exe` path exists

---

## Known Windows issues

### Issue 1: "ssh: command not found"

**Cause**: OpenSSH not installed or not in PATH

**Fix**: Install OpenSSH (see above) or use Git Bash

---

### Issue 2: ProxyCommand fails with path error

**Cause**: Spaces in Windows paths can cause issues

**Symptoms:**
```
CreateProcessW failed error:2
ssh: Could not resolve hostname my-cluster
```

**Fix**: Edit `~/.ssh/config` and ensure the ProxyCommand path is quoted:

```
ProxyCommand "C:\Program Files\Databricks\CLI\databricks.exe" ssh connect ...
```

---

### Issue 3: "Permission denied (publickey)"

**Cause**: SSH key not generated or wrong permissions

**Fix**: Re-run SSH setup:
```powershell
databricks ssh setup --profile workshop --name my-cluster --cluster <cluster-id>
```

---

### Issue 4: Connection timeout

**Cause**: Cluster not running or network issue

**Fix**:
1. Check cluster is running:
   ```powershell
   databricks clusters get --cluster-id <id> --profile workshop
   ```

2. Start if needed:
   ```powershell
   databricks clusters start --cluster-id <id> --profile workshop
   ```

---

### Issue 5: Corporate proxy blocks connection

**Symptoms**: Connection hangs or times out

**Check**: Can you reach Databricks?
```powershell
databricks clusters list --profile workshop
```

If CLI works but SSH doesn't, the ProxyCommand should still work since it tunnels over HTTPS.

**Debug**: Try with verbose:
```powershell
ssh -v my-cluster
```

Look for where it gets stuck.

---

## Alternative: Git Bash

If PowerShell SSH doesn't work, try Git Bash:

1. Install [Git for Windows](https://gitforwindows.org/)
2. Open Git Bash
3. Run the same commands:
   ```bash
   databricks auth login --host https://<workspace>.azuredatabricks.net --profile workshop
   databricks ssh setup --profile workshop --name my-cluster --cluster <cluster-id>
   ssh my-cluster
   ```

Git Bash uses its own SSH implementation which may work better in some environments.

---

## VSCode Remote SSH on Windows

### Setup

1. Install VSCode
2. Install "Remote - SSH" extension
3. Ensure SSH works from command line first

### Connect

1. Press Ctrl+Shift+P
2. Type "Remote-SSH: Connect to Host"
3. Select your cluster alias (e.g., `my-cluster`)

### If VSCode can't find the host

1. Check `C:\Users\<username>\.ssh\config` has the entry
2. Reload VSCode window (Ctrl+Shift+P → "Reload Window")
3. Try SSH from terminal first to verify it works

---

## Quick validation checklist for Windows

Run these commands to verify setup:

```powershell
# 1. Check OpenSSH
ssh -V

# 2. Check Databricks CLI
databricks --version

# 3. Check authentication
databricks auth describe --profile workshop

# 4. Check SSH config exists
Test-Path $env:USERPROFILE\.ssh\config

# 5. Test SSH connection
ssh my-cluster
```

All should pass before the workshop.

---

## Fallback options

If `databricks ssh` doesn't work on Windows:

### Option 1: WSL (Windows Subsystem for Linux)

1. Install WSL: `wsl --install`
2. Open Ubuntu/WSL terminal
3. Install Databricks CLI in WSL
4. Run all commands from WSL

### Option 2: Git Bash

Use Git Bash instead of PowerShell (see above)

### Option 3: VirtualBox

If data engineers already use VirtualBox:
1. Use existing Linux VM
2. Install Databricks CLI in VM
3. Run SSH from VM

---

## Pre-workshop Windows testing

**Critical**: Test `databricks ssh` on a Windows machine with the same corporate environment as attendees BEFORE the workshop.

Test checklist:
- [ ] OpenSSH available
- [ ] Databricks CLI installs
- [ ] OAuth authentication works
- [ ] `databricks ssh setup` creates config
- [ ] `ssh <alias>` connects to cluster
- [ ] VSCode Remote SSH connects

If any step fails, document the workaround or escalate to IT.
