#!/bin/bash

set -euo pipefail

echo
echo "🚀 === Git LFS セットアップ開始 ==="

if ! command -v git-lfs &> /dev/null; then
  log_info "Git LFS をインストール中..."
  sudo apt-get install -qq -y git-lfs
  log_success "Git LFS がインストールされました: $(git-lfs --version)"
fi

log_info "Git LFS を初期化中..."
git lfs install

log_success "Git LFS セットアップが完了しました"
echo
