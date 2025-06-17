# バックエンドサーバ リファクタリング マイグレーションガイド

## 🎯 このガイドについて

このドキュメントは、リファクタリング後のバックエンドサーバへの移行手順と、新しいアーキテクチャの使い方を説明します。

---

## 🚀 クイックスタート

### **1. 依存関係の更新**
```bash
# 新しい依存関係を取得
go mod tidy

# 設定ファイルをコピー
cp configs/config.local.yaml configs/config.yaml
```

### **2. 環境変数の設定**
```bash
# 環境変数ファイル (.env) の例
export GO_ENV=local
export PORT=8080
export DB_HOST=localhost
export DB_PORT=5432
export DB_NAME=roudoku
export DB_USER=roudoku
export DB_PASSWORD=roudoku_local_password
export LOG_LEVEL=debug
```

### **3. サーバーの起動**
```bash
# 開発環境
go run cmd/server/main.go

# 本番環境
GO_ENV=production go run cmd/server/main.go
```

---

## 📁 新しいディレクトリ構造

### **変更前後の対応表**
| 変更前 | 変更後 | 説明 |
|---------|---------|---------|
| `main.go` | `cmd/server/main.go` | メインエントリーポイント |
| `import_aozora.go` | `cmd/import_aozora/main.go` | データインポートツール |
| `internal/config/` | `pkg/config/` | 設定管理（機能拡張） |
| `internal/middleware/` | `pkg/middleware/` | ミドルウェア（機能拡張） |
| - | `pkg/logger/` | 新規: 構造化ログ |
| - | `pkg/errors/` | 新規: 統一エラー処理 |
| - | `pkg/utils/` | 新規: 共通ユーティリティ |
| - | `configs/` | 新規: 環境別設定ファイル |

---

## 🔧 主要な変更点と移行方法

### **1. 設定管理の変更**

#### **変更前**
```go
// internal/config/config.go
cfg := config.Load() // 環境変数のみ
```

#### **変更後** 
```go
// pkg/config/config.go
cfg, err := config.Load() // YAML + 環境変数
if err != nil {
    log.Fatal(err)
}
```

#### **設定ファイルの作成**
```yaml
# configs/config.local.yaml
server:
  port: "8080"
  timeout: 30s
  shutdown_timeout: 10s

database:
  host: "localhost"
  port: 5432
  name: "roudoku"
  user: "roudoku"
  password: "roudoku_local_password"
  ssl_mode: "disable"
  max_open_conns: 25
  max_idle_conns: 5
  conn_max_lifetime: "1h"

logging:
  level: "debug"
  format: "text"
  output: "stdout"
```

### **2. ログ機能の強化**

#### **変更前**
```go
log.Printf("Creating user: %s", userID)
```

#### **変更後**
```go
import "github.com/ponyo877/roudoku/server/pkg/logger"

logger.Info("Creating user", 
    zap.String("user_id", userID),
    zap.String("action", "create_user"),
)
```

### **3. エラーハンドリングの統一**

#### **変更前**
```go
if err != nil {
    http.Error(w, "Internal server error", 500)
    return
}
```

#### **変更後**
```go
import "github.com/ponyo877/roudoku/server/pkg/utils"

if err != nil {
    utils.WriteError(w, r, logger, err)
    return
}
```

### **4. ハンドラーの新しいパターン**

#### **変更前**
```go
func CreateUser(w http.ResponseWriter, r *http.Request) {
    // バリデーション、ログ、エラーハンドリングを手動実装
}
```

#### **変更後**
```go
type UserHandler struct {
    *BaseHandler
    userService services.UserService
}

func NewUserHandler(userService services.UserService, log *logger.Logger) *UserHandler {
    return &UserHandler{
        BaseHandler: NewBaseHandler(log),
        userService: userService,
    }
}

func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
    var req dto.CreateUserRequest
    if err := utils.DecodeJSON(r, &req); err != nil {
        utils.WriteError(w, r, h.logger, err)
        return
    }

    if err := h.validator.ValidateStruct(&req); err != nil {
        utils.WriteError(w, r, h.logger, err)
        return
    }

    user, err := h.userService.CreateUser(r.Context(), &req)
    if err != nil {
        utils.WriteError(w, r, h.logger, err)
        return
    }

    utils.WriteCreated(w, user)
}
```

---

## 🛠️ 開発時の新しいワークフロー

### **1. 新しいハンドラーの作成**
```go
// 1. BaseHandlerを埋め込み
type NewHandler struct {
    *BaseHandler
    newService services.NewService
}

// 2. コンストラクタでloggerを注入
func NewNewHandler(service services.NewService, log *logger.Logger) *NewHandler {
    return &NewHandler{
        BaseHandler: NewBaseHandler(log),
        newService: service,
    }
}

// 3. 統一されたパターンでハンドラー実装
func (h *NewHandler) HandleRequest(w http.ResponseWriter, r *http.Request) {
    // 自動バリデーション、ログ、エラーハンドリングを活用
}
```

### **2. 新しいサービスの作成**
```go
type NewService struct {
    *BaseService
    newRepo repository.NewRepository
}

func NewNewService(repo repository.NewRepository, log *logger.Logger) *NewService {
    return &NewService{
        BaseService: NewBaseService(log),
        newRepo: repo,
    }
}
```

### **3. 新しいリポジトリの作成**
```go
type NewRepository struct {
    *BaseRepository
}

func NewNewRepository(db *pgxpool.Pool) *NewRepository {
    return &NewRepository{
        BaseRepository: NewBaseRepository(db),
    }
}

func (r *NewRepository) Create(ctx context.Context, entity *Entity) error {
    _, err := r.GetConnection().Exec(ctx, query, params...)
    return r.HandleError(err, "create entity")
}
```

---

## 🔍 トラブルシューティング

### **よくある問題と解決方法**

#### **1. ビルドエラー: 型の不一致**
```bash
# エラー例
cannot use logger (variable of type *zap.Logger) as *logger.Logger
```
**解決方法**: pkg/loggerの Logger型を使用
```go
import "github.com/ponyo877/roudoku/server/pkg/logger"

func NewService(log *logger.Logger) // ✅ 正しい
func NewService(log *zap.Logger)    // ❌ 古い方法
```

#### **2. 設定ファイルが見つからない**
```bash
# エラー例
failed to read config file configs/config.local.yaml
```
**解決方法**: 設定ファイルを作成
```bash
cp configs/config.yaml configs/config.local.yaml
# または環境変数で設定
export GO_ENV=production
```

#### **3. データベース接続エラー**
```bash
# エラー例
failed to connect to database
```
**解決方法**: 設定確認
```yaml
database:
  host: "localhost"     # ✅ 正しいホスト
  port: 5432           # ✅ 正しいポート
  name: "roudoku"      # ✅ データベース名
```

---

## 🎁 新機能の活用方法

### **1. 構造化ログの活用**
```go
// リクエスト処理のログ
logger.Info("Processing request",
    zap.String("method", r.Method),
    zap.String("path", r.URL.Path),
    zap.String("user_id", userID),
)

// エラーログ
logger.Error("Database operation failed",
    zap.Error(err),
    zap.String("operation", "create_user"),
    zap.String("table", "users"),
)
```

### **2. ヘルスチェックの活用**
```bash
# 基本ヘルスチェック
curl http://localhost:8080/api/v1/health

# Kubernetes Liveness
curl http://localhost:8080/healthz

# Kubernetes Readiness  
curl http://localhost:8080/ready
```

### **3. メトリクス監視**
```go
// 自動的に記録される情報
- リクエスト数
- レスポンス時間
- エラー率
- データベース接続数
```

---

## 📚 詳細ドキュメント

### **追加リソース**
- `REFACTORING_SUMMARY.md` - 完全なリファクタリング概要
- `pkg/*/README.md` - 各パッケージの詳細説明
- `configs/config.yaml` - 設定ファイルのサンプル

### **コード例**
- `handlers/` - 新しいハンドラーパターンの実例
- `services/` - BaseServiceパターンの実例
- `repository/` - BaseRepositoryパターンの実例

---

## 🚀 次のステップ

1. **既存機能の動作確認** - 全APIエンドポイントのテスト
2. **新しいパターンでの機能追加** - BasePatternを活用した開発
3. **監視設定** - ログ・メトリクスの監視システム統合
4. **デプロイ準備** - 本番環境設定の調整

---

*移行に関する質問や問題がある場合は、リファクタリング担当者にお気軽にお声がけください。*