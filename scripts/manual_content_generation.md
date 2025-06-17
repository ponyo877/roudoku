# CloudRunサーバーでのコンテンツ生成マニュアル

## 概要
CloudRunで動作中のサーバーに小説テキストと音声データを生成させる方法

## 前提条件
- サーバーがCloudRunで起動済み
- Google Cloud TTS APIが有効化済み
- 適切な認証情報が設定済み

## 方法1: 自動スクリプトを使用

```bash
# scriptsディレクトリに移動
cd /Users/ponyo877/Documents/workspace/roudoku/scripts

# スクリプトを実行
./deploy_content.sh
```

## 方法2: cURLコマンドで手動実行

### 1. サーバーの状態確認
```bash
curl -X GET https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/health
```

### 2. 現在のコンテンツ状況確認
```bash
curl -X GET https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/content/status
```

### 3. コンテンツと音声ファイルの一括生成
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{"force": true}' \
  https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/content/initialize
```

### 4. 生成後の状況確認
```bash
curl -X GET https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/content/status
```

## 方法3: 個別に音声ファイルを生成

### 特定の章の音声ファイルを生成
```bash
curl -X POST \
  -H "Content-Type: application/json" \
  -d '{
    "book_id": 1,
    "chapter_id": 0,
    "voice": "ja-JP-Wavenet-A",
    "speed": 1.0
  }' \
  https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/audio/generate
```

### 特定の書籍の全章音声を一括生成
```bash
curl -X POST \
  https://roudoku-api-1083612487436.asia-northeast1.run.app/api/v1/audio/regenerate?book_id=1
```

## APIレスポンス例

### 初期化成功時のレスポンス
```json
{
  "message": "Content initialization completed",
  "books_created": 2,
  "audio_generated": 5,
  "books": [
    {
      "book_id": 1,
      "title": "吾輩は猫である",
      "chapters_text": 3,
      "chapters_audio": 3,
      "status": "completed"
    },
    {
      "book_id": 2,
      "title": "坊ちゃん",
      "chapters_text": 2,
      "chapters_audio": 2,
      "status": "completed"
    }
  ]
}
```

### 状況確認時のレスポンス
```json
{
  "books": [
    {
      "book_id": 1,
      "title": "吾輩は猫である",
      "chapters_text": 3,
      "chapters_audio": 3,
      "status": "complete"
    }
  ],
  "total_books": 2
}
```

## 生成されるコンテンツ

### 書籍一覧
1. **吾輩は猫である** (夏目漱石)
   - 第一章、第二章、第三章
   - 各章約5-7分の音声

2. **坊ちゃん** (夏目漱石) 
   - 第一章、第二章
   - 各章約8-9分の音声

### ファイル構造
```
CloudRunコンテナ内:
├── book_content/
│   ├── book_1.json  # 吾輩は猫である
│   └── book_2.json  # 坊ちゃん
└── audio_files/
    ├── book_1_chapter_0.mp3
    ├── book_1_chapter_1.mp3
    ├── book_1_chapter_2.mp3
    ├── book_2_chapter_0.mp3
    └── book_2_chapter_1.mp3
```

## トラブルシューティング

### エラー: "TTS client creation failed"
- Google Cloud TTS APIの認証情報を確認
- サービスアカウントキーが正しく設定されているか確認

### エラー: "Book content not found"
- 先に `/content/initialize` を実行してコンテンツを生成

### 音声ファイルが再生されない
- `/content/status` で音声ファイルが正常に生成されているか確認
- CloudRunのログを確認してTTSエラーがないかチェック

## 注意事項

1. **コスト**: Google Cloud TTS APIの利用料金が発生します
2. **時間**: 全音声ファイル生成には数分かかります
3. **容量**: CloudRunのディスク容量制限に注意
4. **永続化**: CloudRunは一時的なファイルシステムのため、コンテナ再起動時にファイルが失われます

## Cloud Storage連携（推奨）

永続的な音声ファイル保存のため、Cloud Storageとの連携をお勧めします：
```bash
# Cloud Storage連携は別途実装が必要
# 詳細は開発チームにお問い合わせください
```