#!/bin/bash

set -euo pipefail

echo
echo "🚀 === Git Credential Manager セットアップ開始 ==="

if ! command -v git-credential-manager &> /dev/null; then
  log_info "Git Credential Manager をインストール中..."
  sudo apt-get install -qq -y git-credential-manager
  log_success "Git Credential Manager がインストールされました: $(git-credential-manager --version)"
fi

log_info "Git Credential Manager を認証ヘルパーとして設定中..."
git config --global credential.helper manager
log_success "Git Credential Manager が認証ヘルパーとして設定されました"

log_success "Git Credential Manager セットアップが完了しました"
echo
