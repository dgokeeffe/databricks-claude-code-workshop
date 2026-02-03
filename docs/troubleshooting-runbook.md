# Troubleshooting runbook

Quick reference for common issues during the workshop.

## Quick diagnostics

Run this script to diagnose common issues:

```bash
#!/bin/bash
echo "=== Diagnostic Report ==="

echo -e "\n--- Node.js ---"
node --version 2>&1 || echo "NOT INSTALLED"
npm --version 2>&1 || echo "NOT INSTALLED"

echo -e "\n--- Claude Code ---"
which claude 2>&1 || echo "NOT FOUND"
claude --version 2>&1 || echo "CANNOT RUN"

echo -e "\n--- Environment ---"
echo "HTTPS_PROXY: ${HTTPS_PROXY:-not set}"
echo "NODE_EXTRA_CA_CERTS: ${NODE_EXTRA_CA_CERTS:-not set}"
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:+SET (hidden)}"
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:-NOT SET}"

echo -e "\n--- Network ---"
curl -s -o /dev/null -w "api.anthropic.com: %{http_code}\n" https://api.anthropic.com --max-time 5 || echo "api.anthropic.com: TIMEOUT"

echo -e "\n--- Init Script Logs ---"
ls -la /databricks/driver/logs/init_scripts/ 2>/dev/null || echo "No init script logs found"

echo -e "\n=== End Diagnostic Report ==="
```

## Issue index

| Issue | Quick fix |
|-------|-----------|
| [claude: command not found](#claude-command-not-found) | `source /etc/profile.d/claude-code.sh` |
| [Node.js not installed](#nodejs-not-installed) | Re-run init script |
| [API connection failed](#api-connection-failed) | Check proxy settings |
| [Rate limit exceeded](#rate-limit-exceeded) | Wait 60 seconds, retry |
| [Web Terminal blank](#web-terminal-blank) | Refresh, try incognito |
| [Cluster won't start](#cluster-wont-start) | Check policy limits |

---

## claude: command not found

### Symptoms
```
bash: claude: command not found
```

### Quick fix
```bash
source /etc/profile.d/claude-code.sh
```

### If that doesn't work

1. Check if Node.js is installed:
```bash
node --version
```

2. If Node.js is missing, run the init script manually:
```bash
sudo bash /Volumes/main/default/init_scripts/install-claude-code.sh
```

3. Check init script logs for errors:
```bash
cat /databricks/driver/logs/init_scripts/*.log
```

### Root causes
- Init script failed during cluster startup
- Node.js installation failed (network issue)
- npm install failed (network/permission issue)

---

## Node.js not installed

### Symptoms
```
bash: node: command not found
```

### Quick fix

Install Node.js manually:
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs
```

### If curl fails (network blocked)

Use the offline installation method:
1. Download Node.js tarball from a machine with internet
2. Upload to Unity Catalog volume
3. Run offline init script

### Root causes
- Network blocked to `deb.nodesource.com`
- Proxy not configured correctly
- DNS resolution failed

---

## API connection failed

### Symptoms
```
Error: Failed to connect to api.anthropic.com
Error: ETIMEDOUT
Error: ECONNREFUSED
```

### Quick fix

1. Check proxy is set:
```bash
echo $HTTPS_PROXY
```

2. Set proxy if missing:
```bash
export HTTPS_PROXY="https://proxy.corp.com:8080"
```

3. Test connection:
```bash
curl -v https://api.anthropic.com/v1/messages
```

### If proxy is set but still fails

1. Check CA certificate:
```bash
export NODE_EXTRA_CA_CERTS="/path/to/ca-cert.pem"
```

2. Test with certificate:
```bash
curl --cacert /path/to/ca-cert.pem https://api.anthropic.com
```

### If all else fails

Contact IT to whitelist `api.anthropic.com` on port 443.

### Root causes
- Corporate proxy not configured
- SSL inspection without CA cert
- Firewall blocking outbound HTTPS
- api.anthropic.com not whitelisted

---

## Rate limit exceeded

### Symptoms
```
Error: 429 Too Many Requests
Error: Rate limit exceeded
```

### Quick fix

Wait 60 seconds and retry. Rate limits reset after a short period.

### If persistent

1. Check if API key is shared with too many users
2. Contact workshop facilitator for alternative key
3. Stagger requests (don't all send at once)

### For facilitators

- Contact Anthropic to request rate limit increase
- Distribute multiple API keys across groups
- Schedule workshop in smaller batches

---

## Web Terminal blank

### Symptoms
- Web Terminal shows blank white page
- Loading spinner never completes
- "Failed to load" error

### Quick fix

1. Refresh the page (F5 or Ctrl+R)
2. Try incognito/private browsing mode
3. Clear browser cache and cookies

### If refresh doesn't work

1. Check cluster is still running (may have auto-terminated)
2. Try a different browser (Chrome, Firefox, Edge)
3. Check browser console for errors (F12 > Console)

### Browser-specific issues

**Chrome**: Disable extensions, try incognito
**Firefox**: Check Enhanced Tracking Protection isn't blocking
**Edge**: Try Internet Explorer mode (last resort)

### Root causes
- Browser caching stale session
- Cluster terminated
- WebSocket connection blocked by proxy
- Browser extension interference

---

## Cluster won't start

### Symptoms
- Cluster stuck in "Pending" state
- "Failed to start cluster" error
- Timeout waiting for cluster

### Quick fix

1. Check if you already have a running cluster (policy may limit to 1):
```bash
databricks clusters list --output JSON | jq '.[] | select(.state == "RUNNING")'
```

2. Terminate existing cluster and retry

### If no existing cluster

1. Check instance pool has capacity
2. Try creating cluster without pool
3. Contact workspace admin

### For facilitators

1. Check Azure subscription quota
2. Increase instance pool max_capacity
3. Pre-provision clusters before workshop

### Root causes
- Cluster-per-user policy limit reached
- Instance pool at capacity
- Azure subscription quota exhausted
- Node type unavailable in region

---

## Authentication errors

### Symptoms
```
Error: Invalid API key
Error: Authentication failed
Error: 401 Unauthorized
```

### Quick fix

1. Check API key is set:
```bash
echo $ANTHROPIC_API_KEY
```

2. Set API key:
```bash
export ANTHROPIC_API_KEY="sk-ant-your-key-here"
```

3. Verify key format starts with `sk-ant-`

### If key is set but still fails

1. Check for trailing whitespace or newlines
2. Re-copy the key from source
3. Try a different API key

### Root causes
- API key not exported to environment
- API key copied incorrectly (extra whitespace)
- API key expired or revoked
- Wrong API key (test vs production)

---

## Permission denied errors

### Symptoms
```
Error: EACCES: permission denied
Error: Cannot write to /usr/local
sudo: command not found
```

### Quick fix

For npm global installs:
```bash
sudo npm install -g @anthropic-ai/claude-code
```

For file operations:
```bash
sudo chown -R $USER:$USER ~/.claude
```

### Root causes
- Running without sudo when needed
- File ownership issues
- Read-only filesystem (rare on Databricks)

---

## Slow performance

### Symptoms
- Claude responses take >30 seconds
- Terminal feels sluggish
- High latency

### Quick fix

1. Check cluster resources:
```bash
top -bn1 | head -20
```

2. If CPU/memory maxed, restart cluster

3. Check network latency:
```bash
time curl -s https://api.anthropic.com > /dev/null
```

### Root causes
- Cluster under-provisioned
- Network congestion through proxy
- Many concurrent users on same cluster
- Large context in Claude conversation

---

## Emergency contacts

| Issue type | Escalation |
|------------|------------|
| Network/Proxy | IT Security team |
| Databricks platform | Databricks support |
| Claude API | Anthropic support |
| Workshop logistics | Lead facilitator |
