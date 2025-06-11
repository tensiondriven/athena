#!/bin/bash
# Git filter to redact secrets from chat history files

# Read from stdin and redact various secret patterns
sed -E \
  -e 's/github_pat_[A-Za-z0-9_]{82}/REDACTED_GITHUB_TOKEN/g' \
  -e 's/ghp_[A-Za-z0-9]{36}/REDACTED_GITHUB_TOKEN/g' \
  -e 's/ghs_[A-Za-z0-9]{36}/REDACTED_GITHUB_SECRET/g' \
  -e 's/"api_key":\s*"[^"]+"/\"api_key\": \"REDACTED\"/g' \
  -e 's/"token":\s*"[^"]+"/\"token\": \"REDACTED\"/g' \
  -e 's/"password":\s*"[^"]+"/\"password\": \"REDACTED\"/g' \
  -e 's/"secret":\s*"[^"]+"/\"secret\": \"REDACTED\"/g'