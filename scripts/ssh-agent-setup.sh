#!/bin/bash

set -euo pipefail

echo
echo "🚀 === SSH エージェント自動起動セットアップ開始 ==="

BASH_PROFILE="$HOME/.bash_profile"

if grep -q "SSH_AUTH_SOCK" "$BASH_PROFILE" 2>/dev/null; then
  log_info "ssh-agent の設定は既に $BASH_PROFILE に存在します"
  echo
  exit 0
fi

BASH_PROFILE_EXISTS=false

if [ -f "$BASH_PROFILE" ]; then
  BASH_PROFILE_EXISTS=true
  log_warn "$BASH_PROFILE が既に存在しています"
  log_warn "既存設定(.profile, .bash_profile, .bashrc, etc.)との競合や本追記の影響がないか確認してください"
fi

log_info "$BASH_PROFILE に ssh-agent 自動起動設定を追記中..."

cat >> "$BASH_PROFILE" << 'EOF'

# Auto-start ssh-agent and add keys on login (for VS Code Dev Containers SSH forwarding)
# Reference: https://code.visualstudio.com/remote/advancedcontainers/sharing-git-credentials#_using-ssh-keys
if [ -z "$SSH_AUTH_SOCK" ]; then
  RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
  if [ "$RUNNING_AGENT" = "0" ]; then
    ssh-agent -s &> $HOME/.ssh/ssh-agent
  fi
  eval `cat $HOME/.ssh/ssh-agent` > /dev/null
  ssh-add $HOME/.ssh/id_ed25519 2> /dev/null
  ssh-add $HOME/.ssh/id_rsa 2> /dev/null
fi
EOF

if [ "$BASH_PROFILE_EXISTS" = false ]; then
  echo >> "$BASH_PROFILE"
  echo "source \$HOME/.profile" >> "$BASH_PROFILE"
fi

log_success "$BASH_PROFILE に ssh-agent 設定を追加しました"
echo
