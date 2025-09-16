#!/usr/bin/env bash
set -euo pipefail

# Target user (use current user from HOME)
TARGET_USER="$(basename "$HOME")"
BASHRC="${HOME}/.bashrc"

# Ensure file exists
if [[ ! -f "$BASHRC" ]]; then
  touch "$BASHRC"
fi

append_unique() {
  local line="$1"
  grep -qxF "$line" "$BASHRC" || echo "$line" >> "$BASHRC"
}

# Idempotent TERM export
append_unique 'export TERM=xterm-256color'

marker_begin="# >>> custom PS1 block >>>"
marker_end="# <<< custom PS1 block <<<"

# Remove any existing block first
sed -i "/$marker_begin/,/$marker_end/d" "$BASHRC"

# Add the complete block with PROMPTID initialization and fixed IP functions
cat >> "$BASHRC" << 'EOF'
# >>> custom PS1 block >>>
# Get PROMPTID once (IMDSv2 Name tag -> hostname fallback)
__set_prompt_id() {
  if [[ -n "${PROMPTID:-}" ]]; then return; fi
  local token name
  token=$(curl -s -X PUT -H "X-aws-ec2-metadata-token-ttl-seconds: 60" http://169.254.169.254/latest/api/token 2>/dev/null || true)
  if [[ -n "$token" ]]; then
    name=$(curl -s -H "X-aws-ec2-metadata-token: $token" http://169.254.169.254/latest/meta-data/tags/instance/Name 2>/dev/null || true)
  fi
  PROMPTID="${name:-$(hostname -s)}"
  export PROMPTID
}

# Lazy helpers so prompt stays current
__pri_ip() { ip -4 route get 1.1.1.1 2>/dev/null | awk '/src/ {print $7; exit}'; }
__pub_ip() { curl -s --connect-timeout 1 http://checkip.amazonaws.com 2>/dev/null || echo "-"; }

# Initialize PROMPTID
__set_prompt_id


PS1="\[\033[0;33m\](\$PROMPTID)[Int: \$(__pri_ip) / Ext: \$(__pub_ip)]\[\033[0m\]\n\[\033[01;32m\]\u\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "
# <<< custom PS1 block <<<
EOF

echo "[INFO] Applied updated PS1 block to $BASHRC."
