# Bootstrap ガイド

## 概要

WSL/Linux ホスト環境の開発環境セットアップスクリプトです。

このスクリプトは、ホスト環境に以下のツールを**自動インストール**し、開発の準備を整えます：

- **Docker Engine** (コンテナエンジン)
- **Git & Git LFS** (バージョン管理)
- **GPG** (コミット署名・オプション)
- **SSH** または **Git Credential Manager** (Git 認証・選択制)

セットアップ後、プロジェクトをクローンして Dev Container での開発を開始できます。

## 📋 前提条件

### 対応OS

- **Ubuntu 22.04 以降**
- **Debian 11 以降**

**注意**: このスクリプトは Ubuntu/Debian 専用です。macOS や CentOS/RHEL では動作しません。

## 🚀 セットアップ手順

### Step 0: Windows WSL 2 の準備（Windows ユーザー向け）

**WSL 2 がまだセットアップされていない場合:**

```powershell
# PowerShell (管理者実行)
wsl --install -d Ubuntu
```

[WSL 2 インストールガイド](https://learn.microsoft.com/ja-jp/windows/wsl/install)を参照してください。

セットアップ後、**WSL のターミナルで以下の Step 1 を実行してください。**

### Step 1: Bootstrap スクリプトの実行

```bash
bash ./bootstrap.sh
```

**既存の GPG/SSH 鍵をインポートする場合:**

`.gnupg/` または `.ssh/` ディレクトリに鍵ファイルを配置してからスクリプト実行します。  
詳細は [既存の鍵をインポートする場合](#既存の鍵をインポートする場合) を参照してください。

**スクリプトの処理内容：**

1. 🔐 **sudo 権限の確認**（パッケージインストールに必要）
2. 💻 **OS検証**（Ubuntu/Debian のみ対応）
3. 📝 **ユーザー情報の入力**
   - Git メールアドレス
   - Git ユーザー名
   - GPG 署名の使用有無
   - Git 認証方法の選択（SSH または HTTPS）
4. 📦 **システムパッケージの更新**
5. 🛠️ **開発ツールのインストール**（順次実行）
   - GPG (オプション: 使用する場合のみ)
   - Git + Git LFS
   - SSH または Git Credential Manager
   - Docker Engine
6. ⚙️ **自動設定**
   - Git グローバル設定
   - GPG 署名キー設定（使用する場合）
   - Git Credential Manager の設定（HTTPS 認証方法を選択した場合）
   - docker グループへのユーザー追加

### Step 2: プロジェクトをクローン

```bash
# リポジトリをクローン
git clone <repository-url> <destination>
cd <destination>
```

### Step 3: Dev Container を起動

**VS Code の場合:**

```bash
code .
# Command Palette (Ctrl+Shift+P) → "Dev Containers: Reopen in Container"
```

**Docker Compose の場合:**

```bash
docker compose up -d
docker compose exec <service-name> bash
```

## 🔑 Git 認証方法の選択

以下の 2 つの認証方法から選択できます：

### SSH（推奨）

**特徴**:

- 鍵ベースの認証
- より安全（パスフレーズ保護）
- GitHub CLI など多くのツールと互換性が高い

**セットアップ**: 既存の SSH キーがない場合は自動生成

### HTTPS (Git Credential Manager)

**特徴**:

- パスワードまたは Personal Access Token による認証
- ファイアウォール環境での利用が容易
- GUI ポップアップで認証情報を管理

**セットアップ**: Git Credential Manager を自動インストール・設定

---

## 🔑 GPG/SSH 鍵の管理

### 既存の鍵をインポートする場合

スクリプト実行時に、ファイルが検出されると**インポート確認**が表示されます。

以下のディレクトリに鍵ファイルを配置してください：

#### GPG 鍵のインポート

```text
.gnupg/
  ownertrust-*.txt
  private-key-*.asc
  public-key-*.asc
```

#### SSH 鍵のインポート（SSH 認証方法を選択する場合）

```text
.ssh/
  id_ed25519
  id_ed25519.pub
  (または id_rsa, id_rsa.pub)
```

### 新規に鍵を生成する場合

スクリプト実行時に対話形式で生成確認が表示されます。

#### 生成される鍵

- GPG: EdDSA/Ed25519 (署名用)
- SSH: Ed25519

#### 鍵のエクスポート先

- GPG: `generated/.gnupg`
- SSH: `generated/.ssh`

## 📚 参考リンク

- **Docker**
  - [Docker 公式ドキュメント](https://docs.docker.com/)
  - [Docker Compose Documentation](https://docs.docker.com/compose/)
- **Git**
  - [Git 公式ドキュメント](https://git-scm.com/doc)
- **GPG/SSH**
  - [GPG 署名の設定](https://docs.github.com/ja/authentication/managing-commit-signature-verification)
  - [SSH キーの生成](https://docs.github.com/ja/authentication/connecting-to-github-with-ssh)
- **Dev Container**
  - [VS Code Dev Containers](https://code.visualstudio.com/docs/devcontainers/containers)
