#!/bin/bash
# Git filter to redact secrets from chat history files

# Read from stdin and redact various secret patterns
sed -E \
  -e 's/github_pat_[A-Za-z0-9_]+/REDACTED_GITHUB_TOKEN/g' \
  -e 's/ghp_[A-Za-z0-9]{36}/REDACTED_GITHUB_TOKEN/g' \
  -e 's/ghs_[A-Za-z0-9]{36}/REDACTED_GITHUB_SECRET/g' \
  -e 's/sk-or-v1-[A-Za-z0-9]+/REDACTED_OPENROUTER_KEY/g' \
  -e 's/sk-ant-[A-Za-z0-9_-]+/REDACTED_ANTHROPIC_KEY/g' \
  -e 's/sentry_key=[A-Za-z0-9]+/sentry_key=REDACTED/g' \
  -e 's/SFMyNTY\.[A-Za-z0-9\._-]+/REDACTED_PHOENIX_SESSION/g' \
  -e 's/"api_key":\s*"[^"]+"/\"api_key\": \"REDACTED\"/g' \
  -e 's/"openrouter_key":\s*"[^"]+"/\"openrouter_key\": \"REDACTED\"/g' \
  -e 's/"token":\s*"[^"]+"/\"token\": \"REDACTED\"/g' \
  -e 's/"password":\s*"[^"]+"/\"password\": \"REDACTED\"/g' \
  -e 's/"secret":\s*"[^"]+"/\"secret\": \"REDACTED\"/g' \
  -e 's/([A-Z][A-Z0-9_]*_KEY)=([^ ]+)/\1=REDACTED/g' \
  -e 's/([A-Z][A-Z0-9_]*_TOKEN)=([^ ]+)/\1=REDACTED/g' \
  -e 's/([A-Z][A-Z0-9_]*_SECRET)=([^ ]+)/\1=REDACTED/g' \
  -e 's/([A-Z][A-Z0-9_]*_PASSWORD)=([^ ]+)/\1=REDACTED/g' \
  -e 's/(OPENROUTER_[A-Z0-9_]+)=([^ ]+)/\1=REDACTED/g' \
  -e 's/([A-Z][A-Z0-9_]+_API_KEY)=([^ ]+)/\1=REDACTED/g' \
  -e 's/([A-Z][A-Z0-9_]{3,})=([^ ]+)/\1=REDACTED_POSSIBLE_SECRET/g'
