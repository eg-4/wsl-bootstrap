#!/bin/bash

set -euo pipefail

echo
echo "🚀 === Docker Engine セットアップ開始 ==="

log_info "Docker Engine をインストール中..."

log_info "旧バージョン・競合パッケージを削除中..."
sudo apt-get remove -qq -y \
  docker.io \
  docker-doc \
  docker-compose \
  docker-compose-v2 \
  podman-docker \
  containerd \
  runc \
  2>/dev/null || true

sudo rm -rf /var/lib/docker
sudo rm -rf /var/lib/containerd

sudo rm -f /etc/apt/sources.list.d/docker.sources
sudo rm -f /etc/apt/keyrings/docker.asc

log_info "事前必要パッケージをインストール中..."
sudo apt-get update -qq
sudo apt-get install -qq -y \
  ca-certificates \
  curl

log_info "Docker 公式 GPG キーを取得中..."
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

log_info "Docker リポジトリを追加中..."
# shellcheck source=/dev/null
sudo tee /etc/apt/sources.list.d/docker.sources > /dev/null <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")
Components: stable
Signed-By: /etc/apt/keyrings/docker.asc
EOF

log_info "パッケージインデックスを更新中..."
sudo apt-get update -qq

log_info "Docker Engine と関連パッケージをインストール中..."
sudo apt-get install -qq -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

log_info "インストールを検証中..."

if ! command -v docker &> /dev/null; then
  log_error "docker コマンドが見つかりません"
  exit 1
fi

log_success "Docker がインストールされました: $(docker --version)"
log_success "docker buildx: $(docker buildx version)"
log_success "docker compose: $(docker compose version)"

log_info "Docker サービス状態を確認中..."
if sudo systemctl is-active --quiet docker; then
  log_success "Docker サービスは起動しています"
else
  log_info "Docker サービスを起動中..."
  sudo systemctl start docker || log_warn "Docker サービスの起動に失敗しました"
fi

if getent group docker > /dev/null 2>&1; then
  if ! id -nG "$USER" | grep -qw "docker"; then
    log_info "$USER を docker グループに追加中..."
    sudo usermod -aG docker "$USER" || log_warn "docker グループへの追加に失敗しました（sudo が必要な場合があります）"
  else
    log_info "$USER は既に docker グループのメンバーです。"
  fi
else
  log_warn "docker グループが見つかりません、$USER の追加をスキップします"
fi

log_success "Docker Engine セットアップが完了しました"
echo
