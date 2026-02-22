#!/bin/bash

set -euo pipefail

BOOTSTRAP_HOME="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export BOOTSTRAP_HOME

# shellcheck source=/dev/null
source "$BOOTSTRAP_HOME/scripts/logging.sh"

trap 'log_error "セットアップ中にエラーが発生しました"; exit 1' ERR
echo
log_info "=== Bootstrap セットアップ開始 ==="
echo

log_info "必須ツールを検証中..."
echo

if [ -z "${BASH_VERSION:-}" ]; then
  log_error "このスクリプトは bash で実行してください"
  exit 1
fi
log_success "bash が確認されました: $BASH_VERSION"
echo
log_info "管理者権限が必要です"
echo
echo "  このスクリプトは以下の操作を行うため、sudo 権限が必要です："
echo "   • システムパッケージの更新・インストール"
echo "   • Git および Git LFS のインストール"
echo "   • Docker Engine のインストール"
echo "   • docker グループへのユーザー追加"
echo
read -p "  続行しますか？ (y/n): " -r CONTINUE_SETUP

if [[ ! "$CONTINUE_SETUP" =~ ^[Yy]$ ]]; then
  log_info "セットアップをキャンセルしました"
  exit 0
fi

echo
log_info "管理者権限を確認中..."
if ! sudo -v; then
  log_error "sudo 権限の取得に失敗しました"
  exit 1
fi
log_success "管理者権限が確認されました"

echo
if [ ! -f /etc/os-release ]; then
  log_error "このスクリプトは Ubuntu/Debian 系の Linux でのみ実行可能です"
  exit 1
fi

# shellcheck source=/dev/null
source /etc/os-release

if [[ ! "$ID" =~ ^(ubuntu|debian)$ ]]; then
  log_error "このスクリプトは Ubuntu/Debian 系の Linux でのみ実行可能です"
  echo "検出された OS: $ID"
  exit 1
fi

log_success "検出された OS: $PRETTY_NAME"
echo

log_info "セットアップに必要な情報を入力してください"
echo

while true; do
  read -p "  Git メールアドレス: " -r GIT_USER_EMAIL
  # RFC 5322準拠の簡易的なメールアドレスバリデーション
  if [[ "$GIT_USER_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    break
  else
    log_warn "メールアドレス形式が正しくありません"
  fi
done

while true; do
  read -p "  Git ユーザー名: " -r GIT_USER_NAME
  if [ -n "$GIT_USER_NAME" ]; then
    break
  else
    log_warn "ユーザー名を入力してください"
  fi
done

read -p "  GPG を使用して commit に署名しますか？ (y/n): " -r USE_GPG_INPUT

if [[ "$USE_GPG_INPUT" =~ ^[Yy]$ ]]; then
  USE_GPG=true
  log_info "GPG を使用して commit に署名することを選択しました"
else
  USE_GPG=false
  log_info "GPG を使用しないことを選択しました"
fi

echo
log_info "Git のアクセス方法を選択してください"
echo "  1) SSH（推奨）"
echo "  2) HTTPS (Git Credential Manager)"
echo
read -p "  アクセス方法を選択してください (1 or 2) [デフォルト: 1]: " -r GIT_AUTH_METHOD_INPUT

GIT_AUTH_METHOD_INPUT=${GIT_AUTH_METHOD_INPUT:-1}

case "$GIT_AUTH_METHOD_INPUT" in
  1)
    GIT_AUTH_METHOD="ssh"
    log_info "Git アクセス方法: SSH を選択しました"
    ;;
  2)
    GIT_AUTH_METHOD="https"
    log_info "Git アクセス方法: HTTPS (Git Credential Manager) を選択しました"
    ;;
  *)
    log_warn "入力値が無効です、デフォルトの SSH を使用します"
    GIT_AUTH_METHOD="ssh"
    ;;
esac

export GIT_USER_EMAIL
export GIT_USER_NAME
export USE_GPG
export GIT_AUTH_METHOD

log_success "ユーザー情報を設定しました"
echo

log_info "ホスト環境セットアップを開始します..."
echo

log_info "システムパッケージを更新中..."
sudo apt-get update -qq
sudo apt-get upgrade -y -qq
sudo apt-get autoremove -y -qq
log_success "システムパッケージの更新が完了しました"
echo

if [ "$USE_GPG" = true ]; then
  log_info "【1/5】GPG をセットアップ中..."
  bash "$BOOTSTRAP_HOME/scripts/gpg-setup.sh" || log_error "GPG セットアップに失敗しました"
else
  log_info "【1/5】GPG セットアップをスキップしました"
fi

log_info "【2/5】Git をセットアップ中..."
bash "$BOOTSTRAP_HOME/scripts/git-setup.sh" || log_error "Git セットアップに失敗しました"

log_info "【3/5】Git LFS をセットアップ中..."
bash "$BOOTSTRAP_HOME/scripts/git-lfs-setup.sh" || log_error "Git LFS セットアップに失敗しました"

if [ "$GIT_AUTH_METHOD" = "ssh" ]; then
  log_info "【4/5】SSH をセットアップ中..."
  bash "$BOOTSTRAP_HOME/scripts/ssh-setup.sh" || log_error "SSH セットアップに失敗しました"
  bash "$BOOTSTRAP_HOME/scripts/ssh-agent-setup.sh" || log_error "SSH エージェントセットアップに失敗しました"
else
  log_info "【4/5】Git Credential Manager をセットアップ中..."
  bash "$BOOTSTRAP_HOME/scripts/credential-manager-setup.sh" || log_error "Git Credential Manager セットアップに失敗しました"
fi

log_info "【5/5】Docker Engine をセットアップ中..."
bash "$BOOTSTRAP_HOME/scripts/docker-setup.sh" || log_error "Docker セットアップに失敗しました"

echo

log_success "=== Bootstrap ホスト環境セットアップが完了しました ==="
echo
log_info "✨ ホスト環境は以下のツールで構成されています:"
echo "   • Docker (コンテナエンジン)"
echo "   • Git & Git LFS (リポジトリ操作)"
echo "   • GPG (暗号化署名・オプション)"
echo "   • SSH (リモートアクセス・オプション)"
echo
log_info "📚 次のステップ:"
echo
echo "  1. プロジェクトをクローンする:"
echo "     git clone <repository-url> <destination>"
echo
echo "  2. クローンしたプロジェクトに移動:"
echo "     cd <destination>"
echo
echo "  3. Dev Container を起動する:"
echo "     • VS Code: Command Palette で 'Dev Containers: Reopen in Container'"
echo "     • Docker Compose: docker compose up -d && docker compose exec <service> bash"
echo
echo "  📖 詳細は README.md を参照してください"
echo
