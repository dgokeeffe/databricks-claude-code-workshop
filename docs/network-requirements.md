# Network requirements

Complete list of network dependencies for the Claude Code workshop.

## Cluster outbound requirements

The init script requires outbound HTTPS (443) access to these domains:

| Domain | Purpose |
|--------|---------|
| `claude.ai` | Claude CLI installer script |
| `storage.googleapis.com` | Claude CLI binaries (GCS bucket) |
| `deb.nodesource.com` | Node.js repository |
| `archive.ubuntu.com` | APT packages (x86_64) |
| `ports.ubuntu.com` | APT packages (ARM64) |
| `registry.npmjs.org` | NPM packages |
| `pypi.org` | Python package index |
| `files.pythonhosted.org` | Python package downloads |
| `raw.githubusercontent.com` | Databricks skills |
| `${DATABRICKS_HOST}` | Databricks Model Serving (Claude API) |

## Developer laptop requirements

For `databricks ssh setup` and CLI operations:

| Domain | Purpose |
|--------|---------|
| `*.azuredatabricks.net` | Databricks workspace API |
| `login.microsoftonline.com` | Azure AD OAuth (if using OAuth) |
| `github.com` | CLI download (manual install) |

## Firewall configuration

All traffic uses HTTPS (port 443). HTTP (port 80) may be needed for some package repositories.

### Minimal whitelist for init script

If you can only whitelist specific domains, these are the critical ones:

```
claude.ai
storage.googleapis.com
deb.nodesource.com
pypi.org
files.pythonhosted.org
```

### Full whitelist

```
claude.ai
storage.googleapis.com
deb.nodesource.com
archive.ubuntu.com
ports.ubuntu.com
registry.npmjs.org
pypi.org
files.pythonhosted.org
raw.githubusercontent.com
```

## Verifying network access

### From cluster (via SSH or Web Terminal)

Run this script to check all dependencies:

```bash
#!/bin/bash
echo "=== Network Dependency Check ==="

domains=(
    "claude.ai"
    "storage.googleapis.com"
    "deb.nodesource.com"
    "archive.ubuntu.com"
    "registry.npmjs.org"
    "pypi.org"
    "files.pythonhosted.org"
    "raw.githubusercontent.com"
)

pass=0
fail=0

for domain in "${domains[@]}"; do
    if curl -s --max-time 10 -o /dev/null -w "%{http_code}" "https://$domain" | grep -qE "^[23]"; then
        echo "[OK] $domain"
        ((pass++))
    else
        echo "[FAIL] $domain"
        ((fail++))
    fi
done

echo ""
echo "Result: $pass passed, $fail failed"
```

### From developer laptop

```bash
# Test Databricks API access
databricks clusters list --profile workshop

# Test GitHub access (for manual CLI download)
curl -I https://github.com/databricks/cli/releases
```

## Proxy configuration

If clusters go through a proxy, set these environment variables in the cluster configuration:

```
HTTPS_PROXY=https://proxy.corp.com:8080
HTTP_PROXY=http://proxy.corp.com:8080
NO_PROXY=localhost,127.0.0.1,.azuredatabricks.net
```

For SSL inspection (ZScaler, etc.), also set:

```
NODE_EXTRA_CA_CERTS=/path/to/corporate-ca.pem
REQUESTS_CA_BUNDLE=/path/to/corporate-ca.pem
```

## Offline installation

If network access cannot be enabled, use the offline installation module which pre-packages all dependencies. See the `adb-coding-assistants-cluster-offline` module in the terraform-databricks-examples repo.

## Troubleshooting

### Init script fails with network errors

Check `/tmp/init-script-claude.log` on the cluster for specific failures.

Common issues:
- **Connection timeout**: Domain not whitelisted in firewall
- **SSL errors**: Missing corporate CA certificate
- **403 Forbidden**: Proxy blocking the request

### CLI works but Claude fails

The Claude CLI needs to reach Model Serving:

```bash
curl -s -w "%{http_code}" \
    -H "Authorization: Bearer $DATABRICKS_TOKEN" \
    "${DATABRICKS_HOST}/serving-endpoints/anthropic/invocations"
```

Expected: 200 or 400 (not 403/404/timeout)
