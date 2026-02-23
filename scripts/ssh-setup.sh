#!/bin/bash

set -euo pipefail

echo
echo "🚀 === SSH セットアップ開始 ==="

HAS_ED25519=false
HAS_RSA=false

if [ -f ~/.ssh/id_ed25519 ]; then
  HAS_ED25519=true
  log_info "Ed25519 キーが見つかりました: ~/.ssh/id_ed25519"
fi

if [ -f ~/.ssh/id_rsa ]; then
  HAS_RSA=true
  log_info "RSA キーが見つかりました: ~/.ssh/id_rsa"
fi

if [ "$HAS_ED25519" = true ] || [ "$HAS_RSA" = true ]; then
  log_info "SSH キーが存在するため、セットアップをスキップします"
  echo
  exit 0
fi

mkdir -p ~/.ssh
chmod 700 ~/.ssh

IMPORT_DIR="$BOOTSTRAP_HOME/.ssh"

if [ -d "$IMPORT_DIR" ] && [ -n "$(find "$IMPORT_DIR" -name 'id_*' -type f 2>/dev/null)" ]; then
  log_info "import ファイルから SSH キーが見つかりました"
  echo
  read -p "  これらのキーを import しますか？ (y/n): " -r USE_IMPORT

  if [[ "$USE_IMPORT" =~ ^[Yy]$ ]]; then
    log_info "SSH キーをコピー中..."
    if cp "$IMPORT_DIR"/id_* ~/.ssh/ 2>/dev/null; then
      chmod 600 ~/.ssh/id_*
      log_success "SSH キーがコピーされました"
      echo
      exit 0
    else
      log_warn "SSH キーのコピーに失敗しました"
    fi
  fi
fi

echo
read -p "  新しい Ed25519 SSH キーを生成しますか？ (y/n): " -r GEN_SSH

if [[ ! "$GEN_SSH" =~ ^[Yy]$ ]]; then
  log_info "SSH セットアップをスキップします"
  echo
  exit 0
fi

log_info "SSH キーを生成中..."
echo

if [ -z "${GIT_USER_EMAIL:-}" ]; then
  log_error "GIT_USER_EMAIL が設定されていません"
  exit 1
fi

log_info "メールアドレス: $GIT_USER_EMAIL"
echo

ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f ~/.ssh/id_ed25519 -N "" -q

log_success "Ed25519 SSH キーが生成されました"

log_info "生成されたキーをエクスポート中..."
EXPORT_DIR="$BOOTSTRAP_HOME/generated/.ssh"
mkdir -p "$EXPORT_DIR"

cp ~/.ssh/id_ed25519* "$EXPORT_DIR/"

log_success "SSH キーをエクスポート: $EXPORT_DIR/"
log_info "公開鍵の内容："
cat "$EXPORT_DIR/id_ed25519.pub"

log_warn "秘密鍵ファイルはリポジトリにコミットしないでください"

log_success "SSH セットアップが完了しました"
echo
