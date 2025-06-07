# ローカル開発環境セットアップガイド

## 概要

このガイドでは、Roudokuアプリをローカル環境で動作させる手順を説明します。

## 前提条件

✅ Xcode（最新版）
✅ Android Studio（最新版）
- Go 1.19以上
- Flutter 3.32.0以上
- PostgreSQL
- Redis
- Docker（推奨）

## 1. 開発環境セットアップ

### Go環境確認

```bash
go version  # Go 1.19以上が必要
```

### Flutter環境確認

```bash
flutter doctor
```

期待される出力:
```
Doctor summary (to see all details, run flutter doctor -v):
[✓] Flutter (Channel stable, 3.32.0, on macOS 14.x.x)
[✓] Android toolchain - develop for Android devices
[✓] Xcode - develop for iOS and macOS
[✓] Chrome - develop for the web
[✓] Android Studio
[✓] VS Code
[✓] Connected device
```

## 2. データベースセットアップ

### Option A: Docker使用（推奨）

```bash
# Docker Compose で PostgreSQL + Redis を起動
cat > docker compose.dev.yml << 'EOF'
version: '3.8'
services:
  postgres:
    image: postgres:13
    environment:
      POSTGRES_DB: roudoku_dev
      POSTGRES_USER: roudoku
      POSTGRES_PASSWORD: dev_password
    ports:
      - "5432:5432"
    volumes:
      - postgres_data:/var/lib/postgresql/data
  
  redis:
    image: redis:6-alpine
    ports:
      - "6379:6379"
    command: redis-server --appendonly yes
    volumes:
      - redis_data:/data

volumes:
  postgres_data:
  redis_data:
EOF

# サービス起動
docker compose -f docker compose.dev.yml up -d

# 動作確認
docker compose -f docker compose.dev.yml ps
```

### Option B: ローカルインストール

#### PostgreSQL

```bash
# macOS (Homebrew)
brew install postgresql
brew services start postgresql

# データベース作成
createdb roudoku_dev
psql roudoku_dev -c "CREATE USER roudoku WITH PASSWORD 'dev_password';"
psql roudoku_dev -c "GRANT ALL PRIVILEGES ON DATABASE roudoku_dev TO roudoku;"
```

#### Redis

```bash
# macOS (Homebrew)
brew install redis
brew services start redis

# 動作確認
redis-cli ping  # PONG が返ってくればOK
```

## 3. バックエンドサーバーセットアップ

### 環境変数設定

```bash
# .env.local ファイルを作成
cat > .env.local << 'EOF'
# アプリケーション設定
APP_ENV=development
APP_NAME=roudoku-api-dev
PORT=8080

# データベース設定
DB_HOST=localhost
DB_PORT=5432
DB_NAME=roudoku_dev
DB_USER=roudoku
DB_PASSWORD=dev_password
DB_SSL_MODE=disable

# Redis設定
REDIS_HOST=localhost
REDIS_PORT=6379
REDIS_DB=0

# 認証設定（開発用）
JWT_SECRET=dev_jwt_secret_key_change_in_production
ENCRYPTION_KEY=dev_encryption_key_change_in_production

# Firebase設定（後で設定）
FIREBASE_PROJECT_ID=roudoku-dev

# TTS設定（開発時は無効化可能）
TTS_ENABLED=false
TTS_CACHE_BUCKET=roudoku-dev-tts-cache

# CORS設定
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000

# ログレベル
LOG_LEVEL=debug

# レート制限（開発時は緩く）
RATE_LIMIT_RPS=1000
EOF
```

### 依存関係インストール

```bash
# Go mod依存関係を取得
go mod download

# 必要に応じてモジュール更新
go mod tidy
```

### データベースマイグレーション

```bash
# マイグレーションツールインストール（まだの場合）
go install -tags 'postgres' github.com/golang-migrate/migrate/v4/cmd/migrate@latest

# マイグレーション実行
migrate -path migrations -database "postgres://roudoku:dev_password@localhost:5432/roudoku_dev?sslmode=disable" up

# 確認
psql -U roudoku -d roudoku_dev -c "\dt"
```

### サーバー起動

```bash
# 環境変数読み込み
export $(cat .env.local | xargs)

# サーバー起動（ホットリロード付き）
# Airをインストール（まだの場合）
go install github.com/cosmtrek/air@latest

# Air設定ファイル作成
cat > .air.toml << 'EOF'
root = "."
testdata_dir = "testdata"
tmp_dir = "tmp"

[build]
  args_bin = []
  bin = "./tmp/main"
  cmd = "go build -o ./tmp/main ./cmd/api"
  delay = 1000
  exclude_dir = ["assets", "tmp", "vendor", "testdata", "mobile"]
  exclude_file = []
  exclude_regex = ["_test.go"]
  exclude_unchanged = false
  follow_symlink = false
  full_bin = ""
  include_dir = []
  include_ext = ["go", "tpl", "tmpl", "html"]
  kill_delay = "0s"
  log = "build-errors.log"
  send_interrupt = false
  stop_on_root = false

[color]
  app = ""
  build = "yellow"
  main = "magenta"
  runner = "green"
  watcher = "cyan"

[log]
  time = false

[misc]
  clean_on_exit = false

[screen]
  clear_on_rebuild = false
EOF

# サーバー起動
air

# または、通常の起動
# go run cmd/api/main.go
```

サーバーが正常に起動すると以下が表示されます:
```
2024/01/01 10:00:00 Starting Roudoku API server on :8080
2024/01/01 10:00:00 Environment: development
2024/01/01 10:00:00 Database connection established
2024/01/01 10:00:00 Redis connection established
```

### 動作確認

```bash
# ヘルスチェック
curl http://localhost:8080/health

# 期待されるレスポンス
{
  "status": "ok",
  "timestamp": "2024-01-01T10:00:00Z",
  "version": "1.0.0-dev",
  "services": {
    "database": "ok",
    "redis": "ok"
  }
}
```

## 4. Firebase セットアップ（認証用）

### Firebase プロジェクト作成

1. [Firebase Console](https://console.firebase.google.com/) にアクセス
2. 「プロジェクトを作成」→「roudoku-dev」
3. 認証機能を有効化

### Firebase設定ファイル取得

#### Android用

1. Firebase Console → プロジェクト設定 → アプリを追加 → Android
2. パッケージ名: `com.example.roudoku`
3. `google-services.json` をダウンロード
4. `mobile/android/app/google-services.json` に配置

#### iOS用

1. Firebase Console → プロジェクト設定 → アプリを追加 → iOS
2. バンドルID: `com.example.roudoku`
3. `GoogleService-Info.plist` をダウンロード
4. `mobile/ios/Runner/GoogleService-Info.plist` に配置

### Web設定

```bash
# Firebase CLI インストール
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクト初期化
cd mobile
firebase init

# Web app設定を取得してFlutterに設定
```

## 5. モバイルアプリセットアップ

### 依存関係インストール

```bash
cd mobile

# Pub dependencies取得
flutter pub get

# iOS Pods インストール
cd ios
pod install
cd ..

# Android gradle同期
flutter build apk --debug
```

### 開発用設定

```dart
// mobile/lib/utils/constants.dart を作成/編集
class Constants {
  static const String baseUrl = 'http://localhost:8080'; // iOS Simulatorの場合
  // static const String baseUrl = 'http://10.0.2.2:8080'; // Android Emulatorの場合
  
  static const bool isProduction = false;
  static const bool enableLogging = true;
}
```

### ネットワーク権限設定

#### Android

```xml
<!-- mobile/android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <!-- 既存の設定 -->
    
    <!-- ローカル開発用権限 -->
    <uses-permission android:name="android.permission.INTERNET" />
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE" />
    
    <!-- HTTP通信許可（開発時のみ） -->
    <application
        android:usesCleartextTraffic="true"
        ... >
        <!-- 既存の設定 -->
    </application>
</manifest>
```

#### iOS

```xml
<!-- mobile/ios/Runner/Info.plist -->
<dict>
    <!-- 既存の設定 -->
    
    <!-- HTTP通信許可（開発時のみ） -->
    <key>NSAppTransportSecurity</key>
    <dict>
        <key>NSAllowsArbitraryLoads</key>
        <true/>
    </dict>
</dict>
```

## 6. アプリ起動

### バックエンドサーバー起動

```bash
# ターミナル1: データベース起動（Dockerの場合）
docker compose -f docker compose.dev.yml up

# ターミナル2: APIサーバー起動
export $(cat .env.local | xargs)
air
```

### モバイルアプリ起動

```bash
cd mobile

# デバイス確認
flutter devices

# iOS Simulator起動
flutter run -d "iPhone 15 Pro"

# Android Emulator起動
flutter run -d "Pixel 7"

# ホットリロード有効で起動
flutter run --hot
```

## 7. 開発用データ投入

### サンプルデータ投入

```bash
# サンプルデータ投入スクリプト作成
cat > scripts/seed_dev_data.sql << 'EOF'
-- ユーザーサンプルデータ
INSERT INTO users (id, display_name, email, voice_preset, created_at, updated_at) VALUES
('dev-user-1', 'テストユーザー1', 'test1@example.com', '{"gender": "female", "pitch": 0.5, "speed": 1.0}', NOW(), NOW()),
('dev-user-2', 'テストユーザー2', 'test2@example.com', '{"gender": "male", "pitch": 0.3, "speed": 1.2}', NOW(), NOW());

-- 作品サンプルデータ
INSERT INTO books (id, title, author, epoch, word_count, created_at, updated_at) VALUES
(1, '坊っちゃん', '夏目漱石', '明治', 45000, NOW(), NOW()),
(2, '走れメロス', '太宰治', '昭和', 8000, NOW(), NOW()),
(3, '蜘蛛の糸', '芥川龍之介', '大正', 2000, NOW(), NOW());

-- 引用文サンプルデータ
INSERT INTO quotes (id, book_id, text, position, created_at) VALUES
(gen_random_uuid(), 1, '親譲りの無鉄砲で小供の時から損ばかりしている。', 1, NOW()),
(gen_random_uuid(), 2, 'メロスは激怒した。必ず、かの邪智暴虐の王を除かなければならぬと決意した。', 1, NOW()),
(gen_random_uuid(), 3, 'ある日の事でございます。お釈迦様は極楽の蓮池のふちを、独りでぶらぶら御歩きになっていらっしゃいました。', 1, NOW());
EOF

# データ投入
psql -U roudoku -d roudoku_dev -f scripts/seed_dev_data.sql
```

## 8. 動作確認

### API動作確認

```bash
# ユーザー一覧取得（認証なしでテスト）
curl http://localhost:8080/api/v1/books

# 作品一覧取得
curl http://localhost:8080/api/v1/books

# ヘルスチェック
curl http://localhost:8080/health
```

### モバイルアプリ動作確認

1. **起動画面**: アプリが正常に起動することを確認
2. **API通信**: 作品一覧が表示されることを確認
3. **認証**: Firebase認証が動作することを確認
4. **ナビゲーション**: 画面間の遷移が正常に動作することを確認

## 9. デバッグとログ

### バックエンドログ

```bash
# ログレベル調整
export LOG_LEVEL=debug

# 詳細ログ確認
tail -f build-errors.log
```

### Flutter開発者ツール

```bash
# Flutter Inspector起動
flutter inspector

# パフォーマンス監視
flutter run --profile
```

### ネットワークデバッグ

```bash
# Charles Proxy または Wireshark でHTTP通信監視
# Android: プロキシ設定
# iOS: WiFi設定でプロキシ設定
```

## 10. よくある問題と解決方法

### データベース接続エラー

```bash
# PostgreSQL起動確認
pg_ctl status

# 接続テスト
psql -U roudoku -d roudoku_dev -c "SELECT 1;"
```

### Redis接続エラー

```bash
# Redis起動確認
redis-cli ping

# 設定確認
redis-cli info server
```

### Flutter ビルドエラー

```bash
# キャッシュクリア
flutter clean
flutter pub get

# iOS
cd ios && pod install && cd ..

# Android
flutter build apk --debug
```

### CORS エラー

```bash
# .env.local でCORS設定確認
CORS_ALLOWED_ORIGINS=http://localhost:3000,http://127.0.0.1:3000
```

## 11. 本番環境との差異

| 項目 | ローカル開発 | 本番環境 |
|------|-------------|----------|
| データベース | PostgreSQL (local) | Cloud SQL |
| 認証 | Firebase (dev project) | Firebase (prod project) |
| TTS | 無効化可能 | Google Cloud TTS |
| ストレージ | ローカルファイル | Cloud Storage |
| ログ | stdout | Cloud Logging |
| 監視 | なし | Cloud Monitoring |

開発完了後は本番環境設定に切り替えてデプロイしてください。

## 12. 次のステップ

1. **機能開発**: 新機能の実装
2. **テスト作成**: ユニット・統合テスト
3. **パフォーマンス最適化**: プロファイリングと改善
4. **本番デプロイ**: Terraformでの本番環境構築

開発中に問題が発生した場合は、このガイドの「よくある問題と解決方法」を参照するか、開発チームまでお問い合わせください。