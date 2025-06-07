# Roudoku デプロイメントガイド

## 概要

このガイドでは、Roudokuアプリの本番環境への完全なデプロイメント手順を説明します。インフラストラクチャはTerraformで管理され、Google Cloud Platform上にデプロイされます。

## 前提条件

### 必要なツール

- **Terraform**: >= 1.0
- **Google Cloud SDK**: 最新版
- **Docker**: 最新版
- **Git**: 最新版
- **Go**: >= 1.19（ローカル開発用）
- **Flutter**: >= 3.32.0（モバイルアプリ用）

### インストール手順

#### macOS

```bash
# Homebrew経由でインストール
brew install terraform
brew install --cask google-cloud-sdk
brew install --cask docker
brew install go
brew install --cask flutter

# Flutter設定
flutter doctor
flutter config --enable-web
```

#### Linux/Ubuntu

```bash
# Terraform
wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
unzip terraform_1.6.0_linux_amd64.zip
sudo mv terraform /usr/local/bin/

# Google Cloud SDK
curl https://sdk.cloud.google.com | bash
exec -l $SHELL

# Docker
sudo apt update
sudo apt install docker.io
sudo usermod -aG docker $USER

# Go
wget https://go.dev/dl/go1.21.0.linux-amd64.tar.gz
sudo tar -C /usr/local -xzf go1.21.0.linux-amd64.tar.gz
echo 'export PATH=$PATH:/usr/local/go/bin' >> ~/.bashrc

# Flutter
git clone https://github.com/flutter/flutter.git -b stable
echo 'export PATH="$PATH:`pwd`/flutter/bin"' >> ~/.bashrc
```

## Google Cloud Platform セットアップ

### 1. プロジェクト作成

```bash
# 新しいプロジェクトを作成
gcloud projects create roudoku-prod --name="Roudoku Production"

# プロジェクトを選択
gcloud config set project roudoku-prod

# 課金アカウントの設定（事前に課金アカウントを作成してください）
gcloud billing projects link roudoku-prod --billing-account=XXXXXX-XXXXXX-XXXXXX
```

### 2. 認証設定

```bash
# Google Cloudにログイン
gcloud auth login

# Application Default Credentials設定
gcloud auth application-default login

# Terraformで使用するサービスアカウントを作成（オプション）
gcloud iam service-accounts create terraform-sa \
    --display-name="Terraform Service Account"

# サービスアカウントに必要な権限を付与
gcloud projects add-iam-policy-binding roudoku-prod \
    --member="serviceAccount:terraform-sa@roudoku-prod.iam.gserviceaccount.com" \
    --role="roles/editor"

# サービスアカウントキーを作成
gcloud iam service-accounts keys create terraform-key.json \
    --iam-account=terraform-sa@roudoku-prod.iam.gserviceaccount.com

# 環境変数設定
export GOOGLE_APPLICATION_CREDENTIALS="./terraform-key.json"
```

### 3. プロジェクト設定

```bash
# デフォルトリージョン設定
gcloud config set compute/region asia-northeast1
gcloud config set compute/zone asia-northeast1-a
```

## デプロイメント手順

### 1. リポジトリクローン

```bash
git clone https://github.com/your-org/roudoku.git
cd roudoku
```

### 2. 環境変数設定

```bash
# 環境変数ファイルを作成
cp .env.example .env

# 必要な値を設定
cat > .env << EOF
GOOGLE_CLOUD_PROJECT=roudoku-prod
GOOGLE_CLOUD_REGION=asia-northeast1
FIREBASE_PROJECT_ID=roudoku-prod
ENVIRONMENT=production
EOF

# 環境変数を読み込み
source .env
```

### 3. Terraformによるインフラ構築

```bash
# 実行権限を付与
chmod +x scripts/terraform_deploy.sh

# Terraformの初期化と完全デプロイ
./scripts/terraform_deploy.sh deploy
```

#### ステップバイステップでの実行

```bash
# 1. Terraform初期化
./scripts/terraform_deploy.sh init

# 2. 計画確認
./scripts/terraform_deploy.sh plan

# 3. インフラ構築
./scripts/terraform_deploy.sh apply

# 4. アプリケーションデプロイ
./scripts/terraform_deploy.sh update
```

### 4. DNS設定

デプロイ完了後、以下のDNS設定を行ってください：

```bash
# Load BalancerのIPアドレスを取得
cd infrastructure/terraform
LB_IP=$(terraform output -raw load_balancer_ip)
echo "Configure DNS A record: api.roudoku.app -> $LB_IP"
```

**DNS設定例**（お使いのDNSプロバイダーで設定）：
```
Type: A
Name: api.roudoku.app
Value: 34.102.136.180
TTL: 300
```

### 5. SSL証明書の確認

```bash
# SSL証明書のプロビジョニング状況確認
gcloud compute ssl-certificates describe roudoku-ssl --global
```

通常10-20分でSSL証明書がプロビジョニングされます。

### 6. 動作確認

```bash
# API健康状態チェック
curl https://api.roudoku.app/health

# 期待される結果
{
  "status": "ok",
  "timestamp": "2024-01-01T00:00:00Z",
  "version": "1.0.0",
  "services": {
    "database": "ok",
    "redis": "ok",
    "storage": "ok"
  }
}
```

## モバイルアプリデプロイ

### Android

```bash
cd mobile

# リリースビルド作成
flutter build appbundle --release

# Play Console にアップロード
# build/app/outputs/bundle/release/app-release.aab をアップロード
```

### iOS

```bash
cd mobile

# リリースビルド作成
flutter build ios --release

# Xcode でアーカイブとApp Store Connect へのアップロード
open ios/Runner.xcworkspace
```

## 運用・メンテナンス

### ログ監視

```bash
# アプリケーションログ確認
./scripts/terraform_deploy.sh logs

# 特定の時間範囲のログ
gcloud logging read "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"roudoku-api\"" \
    --format="table(timestamp,severity,textPayload)" \
    --limit=100

# エラーログのみ
gcloud logging read "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"roudoku-api\" AND severity>=ERROR" \
    --limit=50
```

### メトリクス監視

```bash
# CPU使用率確認
gcloud monitoring metrics list --filter="metric.type=run.googleapis.com/container/cpu/utilizations"

# メモリ使用率確認
gcloud monitoring metrics list --filter="metric.type=run.googleapis.com/container/memory/utilizations"

# リクエスト数確認
gcloud monitoring metrics list --filter="metric.type=run.googleapis.com/request_count"
```

### バックアップ

#### データベースバックアップ

```bash
# 手動バックアップ
gcloud sql export sql roudoku-postgres gs://roudoku-backups/backup-$(date +%Y%m%d-%H%M%S).sql \
    --database=roudoku_production

# 自動バックアップ設定確認
gcloud sql instances describe roudoku-postgres --format="value(settings.backupConfiguration)"
```

#### ストレージバックアップ

```bash
# TTS キャッシュバックアップ
gsutil -m rsync -r gs://roudoku-tts-cache gs://roudoku-backups/tts-cache/

# 静的アセットバックアップ
gsutil -m rsync -r gs://roudoku-static-assets gs://roudoku-backups/static-assets/
```

### アップデート

#### アプリケーションアップデート

```bash
# 最新コードをプル
git pull origin main

# アプリケーションのみアップデート
./scripts/terraform_deploy.sh update

# ロールバック（必要に応じて）
gcloud run services update-traffic roudoku-api \
    --to-revisions=roudoku-api-00002-xyz=100 \
    --region=asia-northeast1
```

#### インフラアップデート

```bash
# Terraform計画確認
./scripts/terraform_deploy.sh plan

# インフラアップデート適用
./scripts/terraform_deploy.sh apply
```

### スケーリング設定

#### Cloud Run自動スケーリング

```yaml
# infrastructure/terraform/main.tf で設定
metadata {
  annotations = {
    "autoscaling.knative.dev/minScale" = "1"
    "autoscaling.knative.dev/maxScale" = "10"
  }
}
```

#### データベースリソース調整

```bash
# Cloud SQLインスタンスのスケールアップ
gcloud sql instances patch roudoku-postgres \
    --tier=db-n1-standard-1

# ストレージ拡張
gcloud sql instances patch roudoku-postgres \
    --storage-size=50GB
```

## トラブルシューティング

### よくある問題と解決方法

#### 1. SSL証明書エラー

```bash
# 証明書状態確認
gcloud compute ssl-certificates describe roudoku-ssl --global

# 問題: FAILED_NOT_VISIBLE
# 解決: DNS設定を確認し、A レコードが正しく設定されているか確認

# 問題: PROVISIONING が長時間続く
# 解決: DNS伝播を待つ（最大48時間）
```

#### 2. Cloud Run起動エラー

```bash
# サービスログ確認
gcloud run services logs read roudoku-api --region=asia-northeast1

# よくあるエラー:
# - Database connection failed -> Secret Manager の設定確認
# - Port binding error -> PORT環境変数の確認
# - Permission denied -> Service Account権限確認
```

#### 3. データベース接続エラー

```bash
# Cloud SQL Proxy経由でのローカル接続テスト
cloud_sql_proxy -instances=roudoku-prod:asia-northeast1:roudoku-postgres=tcp:5432

# 別ターミナルで接続テスト
psql "host=127.0.0.1 port=5432 sslmode=require user=roudoku-api dbname=roudoku_production"
```

#### 4. デプロイ失敗

```bash
# Terraform状態確認
cd infrastructure/terraform
terraform show

# 状態リフレッシュ
terraform refresh

# 特定リソースの再作成
terraform taint google_cloud_run_service.roudoku_api
terraform apply
```

### ログレベル別対応

#### ERROR レベル

- 即座に対応が必要
- アラート設定推奨
- 根本原因の調査と修正

#### WARN レベル

- 監視が必要
- 傾向分析で対応計画

#### INFO レベル

- 正常な動作ログ
- パフォーマンス分析に使用

### 緊急時対応

#### サービス停止

```bash
# Cloud Run サービス停止
gcloud run services update roudoku-api \
    --region=asia-northeast1 \
    --min-instances=0 \
    --max-instances=0

# サービス再開
gcloud run services update roudoku-api \
    --region=asia-northeast1 \
    --min-instances=1 \
    --max-instances=10
```

#### 緊急メンテナンスモード

```bash
# メンテナンスページの表示
gcloud run services update roudoku-api \
    --region=asia-northeast1 \
    --set-env-vars=MAINTENANCE_MODE=true
```

## セキュリティ

### 定期的セキュリティチェック

```bash
# 脆弱性スキャン実行
./scripts/quality_check.sh

# 依存関係の脆弱性チェック
go mod audit

# Dockerイメージの脆弱性スキャン
gcloud container images scan gcr.io/roudoku-prod/roudoku-api:latest
```

### アクセス制御

```bash
# サービスアカウントの権限確認
gcloud projects get-iam-policy roudoku-prod

# 不要な権限の削除
gcloud projects remove-iam-policy-binding roudoku-prod \
    --member="serviceAccount:unused-sa@roudoku-prod.iam.gserviceaccount.com" \
    --role="roles/editor"
```

## コスト最適化

### リソース使用量監視

```bash
# 課金レポート確認
gcloud billing accounts list
gcloud billing projects describe roudoku-prod

# コスト予測
gcloud compute instances list --format="table(name,machineType,status,zone)"
```

### 最適化施策

1. **Cloud Run**: 最小インスタンス数の調整
2. **Cloud SQL**: 使用率に応じたマシンタイプ変更
3. **Cloud Storage**: ライフサイクル管理の設定
4. **Cloud CDN**: キャッシュ最適化

## サポート・連絡先

### 開発チーム

- **テクニカルリード**: tech-lead@roudoku.app
- **DevOps**: devops@roudoku.app
- **緊急時**: emergency@roudoku.app

### 外部サポート

- **Google Cloud Support**: サポートケースを作成
- **Terraform**: GitHub Issues または公式フォーラム
- **Flutter**: Flutter公式コミュニティ

---

このガイドに従って、Roudokuアプリの安全で確実なデプロイメントを実現してください。不明な点がある場合は、開発チームまでお問い合わせください。