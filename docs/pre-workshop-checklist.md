# Pre-workshop checklist

Validation steps to confirm the environment works before the workshop.

## Network validation

### Check 1: Databricks CLI reaches workspace

```bash
databricks clusters list --profile <profile>
```

**Expected**: List of clusters returned
**Status**: [ ] Pass  [ ] Fail

---

### Check 2: SSH ProxyCommand works

```bash
# Setup SSH
databricks ssh setup --profile <profile> --name test-cluster --cluster <cluster-id>

# Test connection
ssh test-cluster
```

**Expected**: SSH session opens on cluster
**Status**: [ ] Pass  [ ] Fail

---

### Check 3: Cluster can reach Model Serving endpoint

From the cluster (via SSH):
```bash
curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    "https://<workspace>.azuredatabricks.net/serving-endpoints/<endpoint>/invocations"
```

**Expected**: 200 or 400 (not 403/404/timeout)
**Status**: [ ] Pass  [ ] Fail

---

## Claude Code validation

### Check 4: Claude Code installed on cluster

SSH into cluster, then:
```bash
claude --version
```

**Expected**: Version number displayed
**Status**: [ ] Pass  [ ] Fail

---

### Check 5: Claude Code connects to Model Serving

```bash
# Set endpoint
export ANTHROPIC_BASE_URL="https://<workspace>.azuredatabricks.net/serving-endpoints/<endpoint>"

# Test
claude "Say hello"
```

**Expected**: Claude responds
**Status**: [ ] Pass  [ ] Fail

---

## VSCode Remote SSH validation

### Check 6: VSCode connects to cluster

1. Open VSCode
2. Cmd+Shift+P → "Remote-SSH: Connect to Host"
3. Select the SSH alias

**Expected**: VSCode opens remote session
**Status**: [ ] Pass  [ ] Fail

---

### Check 7: Claude Code works in VSCode terminal

In VSCode remote terminal:
```bash
claude --version
claude "What files are in the current directory?"
```

**Expected**: Claude responds and can see files
**Status**: [ ] Pass  [ ] Fail

---

## Windows-specific validation

### Check 8: Databricks CLI on Windows

```powershell
databricks --version
databricks auth describe --profile <profile>
```

**Expected**: Version shown, auth valid
**Status**: [ ] Pass  [ ] Fail

---

### Check 9: SSH from Windows

```powershell
ssh <alias>
```

**Expected**: Connects to cluster
**Status**: [ ] Pass  [ ] Fail

---

### Check 10: VSCode Remote SSH on Windows

Same as Check 6, from Windows machine.

**Expected**: VSCode connects
**Status**: [ ] Pass  [ ] Fail

---

## Summary

| Check | Description | Status |
|-------|-------------|--------|
| 1 | CLI reaches workspace | |
| 2 | SSH ProxyCommand works | |
| 3 | Cluster reaches Model Serving | |
| 4 | Claude Code installed | |
| 5 | Claude Code + Model Serving | |
| 6 | VSCode connects | |
| 7 | Claude Code in VSCode | |
| 8 | Windows CLI | |
| 9 | Windows SSH | |
| 10 | Windows VSCode | |

**Overall**: [ ] Ready  [ ] Blockers identified

## Blockers

| Issue | Severity | Owner | Resolution |
|-------|----------|-------|------------|
| | | | |
