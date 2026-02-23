#!/bin/bash

set -euo pipefail

echo
echo "🚀 === GPG セットアップ開始 ==="

if ! command -v gpg &> /dev/null; then
  log_info "gnupg をインストール中..."
  sudo apt-get install -qq -y gnupg
  log_success "gnupg がインストールされました: $(gpg --version | head -n1)"
fi

if [ "$(gpg --list-secret-keys --with-colons 2>/dev/null | grep -c '^sec:')" -gt 0 ]; then
  log_info "GPG 秘密鍵が既に存在するため、セットアップをスキップします"
  echo
  exit 0
fi

mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

IMPORT_DIR="$BOOTSTRAP_HOME/.gnupg"
GENERATE_KEY=false

if [ -d "$IMPORT_DIR" ] && [ "$(find "$IMPORT_DIR" -type f -name '*.asc' 2>/dev/null | wc -l)" -gt 0 ]; then
  log_info "GPG キーの import ファイルが見つかりました"
  echo "  $(find "$IMPORT_DIR" -type f -name '*.asc' | sed 's|^|    - |')"
  echo
  read -p "  これらのキーを import しますか？ (y/n): " -r USE_IMPORT

  if [[ "$USE_IMPORT" =~ ^[Yy]$ ]]; then
    log_info "GPG キーを import 中..."

    for key_file in "$IMPORT_DIR"/*.asc; do
      if [ -f "$key_file" ]; then
        log_info "  import: $(basename "$key_file")"
        gpg --batch --yes --import "$key_file" 2>/dev/null || log_warn "    import に失敗しました"
      fi
    done

    for trust_file in "$IMPORT_DIR"/ownertrust*.txt; do
      if [ -f "$trust_file" ]; then
        log_info "  trust 設定を適用中..."
        gpg --import-ownertrust "$trust_file" 2>/dev/null || log_warn "    trust 設定に失敗しました"
        break
      fi
    done

    log_success "GPG キーの import が完了しました"
    echo
    exit 0
  else
    GENERATE_KEY=true
  fi
else
  GENERATE_KEY=true
fi

if [ "$GENERATE_KEY" = true ]; then
  read -p "  新しい GPG キーを生成しますか？ (y/n): " -r GEN_KEY

  if [[ ! "$GEN_KEY" =~ ^[Yy]$ ]]; then
    log_info "GPG セットアップをスキップします"
    echo
    exit 0
  fi

  log_info "新しい GPG キーを生成中..."
  echo

  if [ -z "${GIT_USER_EMAIL:-}" ] || [ -z "${GIT_USER_NAME:-}" ]; then
    log_error "GIT_USER_EMAIL または GIT_USER_NAME が設定されていません"
    exit 1
  fi

  log_info "メールアドレス: $GIT_USER_EMAIL"
  log_info "名前: $GIT_USER_NAME"
  echo

  cat > /tmp/gpg-gen-key << EOF
Key-Type: EDDSA
Key-Curve: Ed25519
Subkey-Type: ECDH
Subkey-Curve: Curve25519
Name-Real: $GIT_USER_NAME
Name-Email: $GIT_USER_EMAIL
Expire-Date: 0
%no-protection
%commit
EOF

  log_info "GPG キーを生成中（少し時間がかかります）..."
  gpg --batch --generate-key /tmp/gpg-gen-key 2>/dev/null

  rm -f /tmp/gpg-gen-key

  log_success "新しい GPG キーが生成されました"

  log_info "生成されたキーをエクスポート中..."
  EXPORT_DIR="$BOOTSTRAP_HOME/generated/.gnupg"
  mkdir -p "$EXPORT_DIR"

  gpg --armor --export-secret-keys "$GIT_USER_EMAIL" > "$EXPORT_DIR/private-key-${GIT_USER_EMAIL}.asc" 2>/dev/null
  log_success "秘密鍵をエクスポート: $EXPORT_DIR/private-key-${GIT_USER_EMAIL}.asc"

  gpg --armor --export "$GIT_USER_EMAIL" > "$EXPORT_DIR/public-key-${GIT_USER_EMAIL}.asc" 2>/dev/null
  log_success "公開鍵をエクスポート: $EXPORT_DIR/public-key-${GIT_USER_EMAIL}.asc"

  gpg --export-ownertrust > "$EXPORT_DIR/ownertrust-${GIT_USER_EMAIL}.txt" 2>/dev/null
  log_success "信頼度設定をエクスポート: $EXPORT_DIR/ownertrust-${GIT_USER_EMAIL}.txt"

  log_warn "秘密鍵ファイルはリポジトリにコミットしないでください"
fi

log_success "GPG セットアップが完了しました"
echo
