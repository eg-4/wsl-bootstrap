#!/bin/bash

set -euo pipefail

echo
echo "🚀 === Git Credential Manager セットアップ開始 ==="

if ! command -v git-credential-manager &> /dev/null; then
  log_info "Git Credential Manager をインストール中..."

  GCM_TMP_DIR=$(mktemp -d)

  LATEST_VERSION=$(curl -s https://api.github.com/repos/git-ecosystem/git-credential-manager/releases/latest | grep -o '"tag_name": "v[^"]*' | cut -d'"' -f4 | sed 's/v//' || echo "2.7.0")

  log_info "Git Credential Manager v$LATEST_VERSION をダウンロード中..."
  wget -q -O "$GCM_TMP_DIR/gcm-linux-x64-$LATEST_VERSION.deb" "https://github.com/git-ecosystem/git-credential-manager/releases/download/v$LATEST_VERSION/gcm-linux-x64-$LATEST_VERSION.deb"
  sudo dpkg -i "$GCM_TMP_DIR/gcm-linux-x64-$LATEST_VERSION.deb"
  rm -rf "$GCM_TMP_DIR"

  log_success "Git Credential Manager がインストールされました: $(git-credential-manager --version)"
fi

log_info "Git Credential Manager を認証ヘルパーとして設定中..."
git-credential-manager configure
git config --global credential.cacheOptions "--timeout 43200"
git config --global credential.credentialStore cache
log_success "Git Credential Manager が認証ヘルパーとして設定されました"

log_success "Git Credential Manager セットアップが完了しました"
echo
