# Pre-workshop validation checklist

Use this checklist to validate the environment before the workshop.

## Phase 1: Network validation

### Test 1.1: Web Terminal access

1. Create a test cluster
2. Navigate to Compute > [cluster] > Apps > Web Terminal
3. **Expected**: Terminal loads within 30 seconds

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 1.2: Outbound HTTPS to Anthropic

From Web Terminal:
```bash
curl -I https://api.anthropic.com
```

**Expected**: HTTP 200 or 401 (both indicate connectivity works)

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 1.3: Outbound HTTPS to Node.js repository

```bash
curl -I https://deb.nodesource.com
```

**Expected**: HTTP 200 or 301/302

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 1.4: npm registry access

```bash
curl -I https://registry.npmjs.org
```

**Expected**: HTTP 200

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

---

## Phase 2: Init script validation

### Test 2.1: Upload init script

```bash
databricks fs cp ./init-scripts/install-claude-code.sh \
    dbfs:/Volumes/main/default/init_scripts/install-claude-code.sh
```

**Expected**: Upload succeeds

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 2.2: Init script execution

1. Create cluster with init script attached
2. Wait for cluster to start
3. Open Web Terminal
4. Run: `claude --version`

**Expected**: Claude Code version displayed

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 2.3: Check init script logs

```bash
cat /databricks/driver/logs/init_scripts/*.log
```

**Expected**: "Claude Code installed successfully" message

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

---

## Phase 3: Claude Code validation

### Test 3.1: API authentication

```bash
export ANTHROPIC_API_KEY="sk-ant-test-key"
claude "Say hello"
```

**Expected**: Claude responds

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 3.2: Interactive session

```bash
claude
```

Then type: "What is 2+2?"

**Expected**: Claude responds with "4" or similar

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 3.3: File operations

```bash
claude "Create a file called test.py with a hello world function"
```

**Expected**: File created successfully

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

---

## Phase 4: Scale validation

### Test 4.1: Instance pool creation

```bash
databricks instance-pools create --json @cluster-config/instance-pool-config.json
```

**Expected**: Pool created successfully

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 4.2: Concurrent cluster startup (5 clusters)

1. Create 5 clusters using the workshop policy
2. Time how long until all are running

**Expected**: All clusters running within 5 minutes

**Actual time**: ___ minutes

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

### Test 4.3: Concurrent API calls (10 simultaneous)

Run from 10 different terminals:
```bash
claude "What is the capital of France?"
```

**Expected**: All respond within 30 seconds

**Result**: [ ] Pass  [ ] Fail

**Notes**: _______________

---

## Phase 5: Proxy/SSL validation (if applicable)

### Test 5.1: Proxy environment variables

```bash
echo "HTTPS_PROXY: $HTTPS_PROXY"
echo "HTTP_PROXY: $HTTP_PROXY"
```

**Expected**: Proxy URLs displayed (if proxy required)

**Result**: [ ] Pass  [ ] Fail  [ ] N/A

**Notes**: _______________

### Test 5.2: CA certificate configuration

```bash
echo "NODE_EXTRA_CA_CERTS: $NODE_EXTRA_CA_CERTS"
ls -la $NODE_EXTRA_CA_CERTS
```

**Expected**: Certificate file exists (if SSL inspection enabled)

**Result**: [ ] Pass  [ ] Fail  [ ] N/A

**Notes**: _______________

### Test 5.3: HTTPS through proxy

```bash
curl --proxy $HTTPS_PROXY https://api.anthropic.com
```

**Expected**: Connection succeeds

**Result**: [ ] Pass  [ ] Fail  [ ] N/A

**Notes**: _______________

---

## Validation summary

| Phase | Tests passed | Tests failed |
|-------|--------------|--------------|
| 1. Network | /4 | /4 |
| 2. Init script | /3 | /3 |
| 3. Claude Code | /3 | /3 |
| 4. Scale | /3 | /3 |
| 5. Proxy/SSL | /3 | /3 |

**Overall status**: [ ] Ready for workshop  [ ] Blockers identified

## Blockers identified

| Blocker | Severity | Owner | ETA |
|---------|----------|-------|-----|
| | | | |
| | | | |
| | | | |

## Sign-off

| Role | Name | Date | Signature |
|------|------|------|-----------|
| Technical lead | | | |
| IT/Network | | | |
| Workshop lead | | | |

---

## Fallback decision matrix

If validation fails, use this matrix to decide on fallback approach:

| Failure | Fallback approach |
|---------|-------------------|
| Web Terminal doesn't work | SSH tunnel (if port 22 open) or notebooks only |
| API blocked | Use Databricks Assistant, no Claude Code |
| Init script fails | Manual installation instructions |
| Scale issues | Stagger workshop groups, pair programming |
| Proxy issues | Work with IT for exceptions |
