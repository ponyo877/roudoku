# Roudoku Flutter App - アーキテクチャガイド

## 📁 プロジェクト構造

```
lib/
├── core/                              # コア機能とユーティリティ
│   ├── config/
│   │   ├── app_config.dart           # アプリケーション設定
│   │   └── app_settings.dart         # ユーザー設定管理
│   ├── error/
│   │   ├── app_exceptions.dart       # カスタム例外クラス
│   │   └── error_handler.dart        # エラーハンドリング
│   ├── logging/
│   │   └── logger.dart               # 統一ログシステム
│   ├── network/
│   │   └── dio_client.dart           # HTTP通信クライアント
│   ├── providers/
│   │   └── base_provider.dart        # ベースプロバイダー
│   ├── state/
│   │   └── base_state.dart           # 状態管理基底クラス
│   ├── theme/
│   │   └── app_theme.dart            # アプリテーマ
│   └── widgets/
│       ├── error_widgets.dart        # エラー表示ウィジェット
│       ├── loading_widgets.dart      # ローディングウィジェット
│       └── state_builder.dart        # 状態ビルダー
├── features/                          # 機能別モジュール
│   ├── auth/                         # 認証機能
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   └── auth_remote_datasource.dart
│   │   │   ├── models/
│   │   │   │   └── auth_models.dart
│   │   │   └── repositories/
│   │   │       └── auth_repository.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository_interface.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_usecase.dart
│   │   │       ├── sign_up_usecase.dart
│   │   │       └── sign_out_usecase.dart
│   │   └── presentation/
│   │       └── providers/
│   │           └── auth_provider_new.dart
│   └── books/                        # 書籍機能
│       ├── data/
│       │   ├── datasources/
│       │   │   └── book_remote_datasource.dart
│       │   ├── models/
│       │   │   └── book_models.dart
│       │   └── repositories/
│       │       └── book_repository.dart
│       ├── domain/
│       │   ├── entities/
│       │   │   ├── book_entity.dart
│       │   │   └── chapter_entity.dart
│       │   ├── repositories/
│       │   │   └── book_repository_interface.dart
│       │   └── usecases/
│       │       └── get_books_usecase.dart
│       └── presentation/
│           └── providers/
│               └── books_provider.dart
├── services/                          # 統合サービス
│   ├── unified_tts_service.dart      # 統合TTS
│   └── unified_swipe_service.dart    # 統合Swipe
└── ... (既存ファイル)
```

## 🏗 アーキテクチャ原則

### 1. Clean Architecture
- **Domain Layer**: ビジネスロジックとエンティティ
- **Data Layer**: データソースとリポジトリ実装
- **Presentation Layer**: UIとプレゼンテーションロジック

### 2. 機能別モジュール化
- 各機能は独立したモジュールとして構成
- 機能間の依存関係を最小化
- テストとメンテナンスの容易性向上

### 3. 統一状態管理
- `BaseProvider`と`BaseState`による一貫した状態管理
- `DataState`と`ListState`でデータタイプ別の状態処理
- エラーハンドリングの統一化

## 🔄 データフロー

```
UI Widget
    ↓
Provider (Presentation Layer)
    ↓
UseCase (Domain Layer)
    ↓
Repository Interface (Domain Layer)
    ↓
Repository Implementation (Data Layer)
    ↓
DataSource (Data Layer)
    ↓
External API/Database
```

## 🎯 主要コンポーネント

### Core Components

#### 1. DioClient (`core/network/dio_client.dart`)
```dart
// 統一HTTPクライアント
final response = await DioClient.instance.dio.get('/api/endpoint');
```

#### 2. Logger (`core/logging/logger.dart`)
```dart
// 構造化ログ
Logger.info('一般情報');
Logger.error('エラーメッセージ', errorObject);
Logger.network('API呼び出し');
Logger.audio('音声処理');
```

#### 3. BaseProvider (`core/providers/base_provider.dart`)
```dart
// 統一状態管理
class MyProvider extends BaseProvider<MyData> {
  MyProvider() : super(DataState<MyData>.initial());
  
  Future<void> loadData() async {
    await executeAsync(
      () => dataSource.getData(),
      onSuccess: (data) => DataState<MyData>.success(data),
    );
  }
}
```

#### 4. StateBuilder (`core/widgets/state_builder.dart`)
```dart
// 状態に応じたUI構築
StateBuilder<Book>(
  state: provider.state,
  builder: (context, book) => BookWidget(book),
  onRetry: () => provider.loadBook(),
)
```

### Service Components

#### 1. UnifiedTtsService (`services/unified_tts_service.dart`)
```dart
// ローカル/クラウドTTS
final tts = UnifiedTtsService();
await tts.initialize(mode: TtsMode.cloud);
await tts.speak('テキストを読み上げます');
```

#### 2. UnifiedSwipeService (`services/unified_swipe_service.dart`)
```dart
// フル/シンプルSwipe
final swipe = UnifiedSwipeService.full(prefs);
final quotes = await swipe.getSwipeQuotes(
  userId: 'user123',
  mode: SwipeMode.tinder,
);
```

## 🛠 開発ガイドライン

### 1. 新機能の追加

1. **Domain Layer**を最初に作成
   ```dart
   // entities/new_entity.dart
   // repositories/new_repository_interface.dart
   // usecases/new_usecase.dart
   ```

2. **Data Layer**を実装
   ```dart
   // models/new_models.dart
   // datasources/new_remote_datasource.dart
   // repositories/new_repository.dart
   ```

3. **Presentation Layer**を構築
   ```dart
   // providers/new_provider.dart
   // screens/new_screen.dart
   ```

### 2. エラーハンドリング

```dart
try {
  final result = await operation();
  return DataState.success(result);
} catch (e) {
  final exception = ErrorHandler.handleError(e);
  return DataState.error(ErrorHandler.getDisplayMessage(exception));
}
```

### 3. ログ記録

```dart
// 機能別ログ
Logger.auth('ユーザーログイン成功');
Logger.book('書籍データ取得完了');
Logger.network('API呼び出し開始');
Logger.error('エラーが発生', exception);
```

### 4. 設定管理

```dart
// アプリ設定
AppConfig.instance.apiBaseUrl
AppConfig.instance.isFeatureEnabled('cloud_tts')

// ユーザー設定
AppSettings.instance.volume = 0.8;
AppSettings.instance.darkMode = true;
```

## 🧪 テスト戦略

### 1. Unit Tests
- UseCase のビジネスロジック
- Repository の実装
- Utility 関数

### 2. Widget Tests
- StateBuilder の動作
- カスタムウィジェット
- Provider の状態変化

### 3. Integration Tests
- API 通信
- データフロー全体
- ユーザーシナリオ

## 📊 パフォーマンス考慮事項

### 1. メモリ管理
- シングルトンパターンの適切な使用
- リソースの適切な解放
- 大きなリストのページネーション

### 2. ネットワーク最適化
- HTTP接続プールの共有
- キャッシュ戦略
- オフライン対応

### 3. UI最適化
- 状態更新の最小化
- ウィジェットの再構築最適化
- 画像キャッシュ

## 🔒 セキュリティ

### 1. データ保護
- 機密データの暗号化
- セキュアストレージの使用
- APIキーの適切な管理

### 2. ネットワークセキュリティ
- HTTPS通信の強制
- 証明書ピニング
- タイムアウト設定

## 🚀 デプロイ

### 1. 環境設定
```dart
// 環境別設定
AppConfig.initialize(
  environment: Environment.production,
  apiBaseUrl: 'https://api.roudoku.com',
);
```

### 2. フィーチャーフラグ
```dart
// 機能の制御
if (FeatureFlags.cloudTts) {
  // クラウドTTS機能を有効化
}
```

このアーキテクチャにより、スケーラブルで保守しやすいFlutterアプリケーションが実現されます。