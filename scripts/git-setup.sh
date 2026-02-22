#!/bin/bash

set -euo pipefail

echo
echo "🚀 === Git セットアップ開始 ==="

if ! command -v git &> /dev/null; then
  log_info "Git をインストール中..."
  sudo apt-get install -qq -y git
  log_success "Git がインストールされました: $(git --version)"
fi

log_info "Git グローバル設定を適用中..."

if [ -z "${GIT_USER_EMAIL:-}" ] || [ -z "${GIT_USER_NAME:-}" ]; then
  log_error "GIT_USER_EMAIL または GIT_USER_NAME が設定されていません"
  exit 1
fi

git config --global core.autocrlf false
git config --global core.editor "code --wait"
git config --global core.fscache true
git config --global core.quotepath false
git config --global core.symlinks false
git config --global fetch.prune true
git config --global fetch.pruneTags true
git config --global init.defaultBranch main
git config --global pull.rebase true
git config --global user.email "$GIT_USER_EMAIL"
git config --global user.name "$GIT_USER_NAME"

log_success "Git グローバル設定が完了しました"

if [ "$USE_GPG" = true ] && [ -d ~/.gnupg ]; then
  log_info "GPG 署名キーを設定中..."

  # GPG秘密鍵のIDをコロン区切りフォーマットから抽出（フィールド5）
  GPG_KEY_ID=$(gpg --list-secret-keys --keyid-format=long --with-colons 2>/dev/null | grep '^sec:' | head -n1 | cut -d':' -f5)

  if [ -n "$GPG_KEY_ID" ]; then
    git config --global commit.gpgsign true
    git config --global user.signingkey "$GPG_KEY_ID"
    log_success "Git 署名キーを設定しました: $GPG_KEY_ID"
  else
    log_warn "GPG キーが見つかりませんでした、GPG セットアップを確認してください"
  fi
else
  log_info "GPG がセットアップされていないため、Git 署名キーの設定をスキップします"
fi

log_success "Git セットアップが完了しました"
echo
