# Roudoku API Documentation

## 概要

Roudoku APIは、青空StoryWalkアプリのバックエンドサービスです。RESTful APIとして設計され、ユーザー管理、作品カタログ、推薦エンジン、読書ログなどの機能を提供します。

## Base URL

- **Production**: `https://api.roudoku.app`
- **Staging**: `https://staging-api.roudoku.app`

## 認証

### Firebase Authentication

すべてのAPIエンドポイント（パブリックエンドポイントを除く）は、Firebase IDトークンによる認証が必要です。

```http
Authorization: Bearer <firebase_id_token>
```

### 認証フロー

1. Firebaseで認証（匿名またはメール/ソーシャル）
2. IDトークンを取得
3. APIリクエストのヘッダーに含める

## レスポンス形式

### 成功レスポンス

```json
{
  "success": true,
  "data": {
    // レスポンスデータ
  },
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 100
  }
}
```

### エラーレスポンス

```json
{
  "success": false,
  "error": {
    "code": "INVALID_REQUEST",
    "message": "リクエストが無効です",
    "details": "validation error details"
  }
}
```

## ステータスコード

| コード | 説明 |
|--------|------|
| 200 | 成功 |
| 201 | 作成成功 |
| 400 | バリデーションエラー |
| 401 | 認証エラー |
| 403 | 権限エラー |
| 404 | リソースが見つからない |
| 409 | 競合エラー |
| 429 | レート制限 |
| 500 | サーバーエラー |

---

## エンドポイント一覧

### 健康状態チェック

#### GET /health
システムの健康状態を確認

**認証**: 不要

```http
GET /health
```

**レスポンス**:
```json
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

---

### ユーザー管理

#### POST /api/v1/users
新規ユーザー作成（初回ログイン時）

**認証**: 必要

```http
POST /api/v1/users
Content-Type: application/json

{
  "display_name": "ユーザー名",
  "email": "user@example.com",
  "voice_preset": {
    "gender": "female",
    "pitch": 0.5,
    "speed": 1.0
  }
}
```

#### GET /api/v1/users/me
現在のユーザー情報取得

**認証**: 必要

```http
GET /api/v1/users/me
```

#### PUT /api/v1/users/me
ユーザー情報更新

**認証**: 必要

```http
PUT /api/v1/users/me
Content-Type: application/json

{
  "display_name": "新しいユーザー名",
  "voice_preset": {
    "gender": "male",
    "pitch": 0.3,
    "speed": 1.2
  }
}
```

---

### 作品カタログ

#### GET /api/v1/books
作品一覧取得

**認証**: 必要

**クエリパラメータ**:
- `page`: ページ番号（デフォルト: 1）
- `limit`: 1ページあたりの件数（デフォルト: 20、最大: 100）
- `search`: 検索キーワード
- `author`: 著者名
- `epoch`: 時代（明治、大正、昭和など）
- `min_length`: 最小文字数
- `max_length`: 最大文字数
- `sort`: ソート順（`title`, `author`, `created_at`, `popularity`）

```http
GET /api/v1/books?search=夏目漱石&epoch=明治&sort=popularity
```

#### GET /api/v1/books/:id
作品詳細取得

**認証**: 必要

```http
GET /api/v1/books/123
```

#### GET /api/v1/books/:id/chapters
作品の章一覧取得

**認証**: 必要

```http
GET /api/v1/books/123/chapters
```

#### GET /api/v1/books/:id/preview
作品のプレビュー（冒頭部分）取得

**認証**: 不要

```http
GET /api/v1/books/123/preview
```

---

### 推薦エンジン

#### GET /api/v1/recommendations
パーソナライズされた推薦作品取得

**認証**: 必要

**クエリパラメータ**:
- `limit`: 推薦件数（デフォルト: 10、最大: 50）
- `context`: コンテキスト情報（JSON文字列）

```http
GET /api/v1/recommendations?limit=5&context={"mood":"relaxed","available_time":30,"weather":"sunny"}
```

#### GET /api/v1/recommendations/quotes
引用文の推薦（スワイプ用）

**認証**: 必要

```http
GET /api/v1/recommendations/quotes?count=10
```

#### POST /api/v1/swipes
スワイプ結果の記録

**認証**: 必要

```http
POST /api/v1/swipes
Content-Type: application/json

{
  "quote_id": "quote-uuid",
  "mode": "tinder",
  "choice": 1,
  "context": {
    "weather": "rainy",
    "location": "home",
    "time_of_day": "evening"
  }
}
```

---

### 読書セッション

#### POST /api/v1/sessions
読書セッション開始

**認証**: 必要

```http
POST /api/v1/sessions
Content-Type: application/json

{
  "book_id": 123,
  "voice_preset": {
    "gender": "female",
    "pitch": 0.5,
    "speed": 1.0
  },
  "bgm_enabled": true,
  "context": {
    "mood": "relaxed",
    "available_time": 30
  }
}
```

#### PUT /api/v1/sessions/:id/progress
読書進捗更新

**認証**: 必要

```http
PUT /api/v1/sessions/session-uuid/progress
Content-Type: application/json

{
  "current_position": 1250,
  "duration_seconds": 300
}
```

#### POST /api/v1/sessions/:id/complete
読書セッション完了

**認証**: 必要

```http
POST /api/v1/sessions/session-uuid/complete
Content-Type: application/json

{
  "final_position": 2500,
  "total_duration": 1800,
  "rating": 5,
  "comment": "とても良い作品でした"
}
```

---

### 音声・TTS

#### POST /api/v1/tts/generate
TTS音声生成

**認証**: 必要

```http
POST /api/v1/tts/generate
Content-Type: application/json

{
  "text": "読み上げるテキスト",
  "voice_preset": {
    "gender": "female",
    "pitch": 0.5,
    "speed": 1.0
  }
}
```

**レスポンス**:
```json
{
  "success": true,
  "data": {
    "audio_url": "https://storage.googleapis.com/bucket/audio.mp3",
    "duration": 30.5,
    "cache_key": "tts-cache-key"
  }
}
```

#### GET /api/v1/audio/scenes
音響シーン一覧取得

**認証**: 必要

```http
GET /api/v1/audio/scenes
```

---

### 読書ログ・分析

#### GET /api/v1/analytics/reading-stats
読書統計取得

**認証**: 必要

**クエリパラメータ**:
- `period`: 期間（`daily`, `weekly`, `monthly`, `yearly`）
- `start_date`: 開始日（YYYY-MM-DD）
- `end_date`: 終了日（YYYY-MM-DD）

```http
GET /api/v1/analytics/reading-stats?period=weekly&start_date=2024-01-01&end_date=2024-01-07
```

#### GET /api/v1/analytics/preferences
読書嗜好分析

**認証**: 必要

```http
GET /api/v1/analytics/preferences
```

#### POST /api/v1/ratings
作品評価の記録

**認証**: 必要

```http
POST /api/v1/ratings
Content-Type: application/json

{
  "book_id": 123,
  "rating": 5,
  "comment": "素晴らしい作品でした",
  "aspects": {
    "story": 5,
    "narration": 4,
    "recommendation": 5
  }
}
```

---

### 通知

#### GET /api/v1/notifications
通知一覧取得

**認証**: 必要

```http
GET /api/v1/notifications?unread_only=true
```

#### PUT /api/v1/notifications/:id/read
通知既読化

**認証**: 必要

```http
PUT /api/v1/notifications/notification-uuid/read
```

#### POST /api/v1/notifications/settings
通知設定更新

**認証**: 必要

```http
POST /api/v1/notifications/settings
Content-Type: application/json

{
  "reading_reminders": true,
  "recommendation_updates": true,
  "achievement_notifications": false,
  "quiet_hours": {
    "start": "22:00",
    "end": "08:00"
  }
}
```

---

### 管理者機能

#### POST /admin/migrate
データベースマイグレーション実行

**認証**: 管理者権限必要

```http
POST /admin/migrate
Authorization: Bearer <admin_token>
```

#### GET /admin/metrics
システムメトリクス取得

**認証**: 管理者権限必要

```http
GET /admin/metrics
```

---

## エラーコード一覧

| コード | 説明 |
|--------|------|
| `INVALID_REQUEST` | リクエスト形式が無効 |
| `AUTHENTICATION_REQUIRED` | 認証が必要 |
| `PERMISSION_DENIED` | 権限不足 |
| `USER_NOT_FOUND` | ユーザーが見つからない |
| `BOOK_NOT_FOUND` | 作品が見つからない |
| `SESSION_NOT_FOUND` | セッションが見つからない |
| `QUOTA_EXCEEDED` | 利用制限超過 |
| `TTS_GENERATION_FAILED` | TTS生成失敗 |
| `INVALID_VOICE_PRESET` | 音声設定が無効 |
| `RATE_LIMIT_EXCEEDED` | レート制限超過 |

## レート制限

- **認証済みユーザー**: 100 requests/minute
- **匿名ユーザー**: 20 requests/minute
- **TTS生成**: 10 requests/minute

レート制限に達した場合、429ステータスコードが返されます。

## SDKとサンプルコード

### Dart/Flutter

```dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class RoudokuApiClient {
  final String baseUrl;
  final String? idToken;

  RoudokuApiClient({
    required this.baseUrl,
    this.idToken,
  });

  Future<Map<String, dynamic>> getBooks({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final uri = Uri.parse('$baseUrl/api/v1/books').replace(
      queryParameters: {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null) 'search': search,
      },
    );

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to fetch books');
    }
  }
}
```

### Go

```go
package main

import (
    "bytes"
    "encoding/json"
    "fmt"
    "net/http"
)

type RoudokuClient struct {
    BaseURL string
    IDToken string
}

func (c *RoudokuClient) CreateUser(user User) (*User, error) {
    jsonData, _ := json.Marshal(user)
    
    req, _ := http.NewRequest("POST", c.BaseURL+"/api/v1/users", bytes.NewBuffer(jsonData))
    req.Header.Set("Authorization", "Bearer "+c.IDToken)
    req.Header.Set("Content-Type", "application/json")
    
    client := &http.Client{}
    resp, err := client.Do(req)
    if err != nil {
        return nil, err
    }
    defer resp.Body.Close()
    
    var result struct {
        Success bool `json:"success"`
        Data    User `json:"data"`
    }
    
    if err := json.NewDecoder(resp.Body).Decode(&result); err != nil {
        return nil, err
    }
    
    return &result.Data, nil
}
```

## 変更履歴

### v1.0.0 (2024-01-01)
- 初期リリース
- 基本的なCRUD操作
- Firebase認証統合
- TTS機能

### v1.1.0 (2024-02-01)
- 推薦エンジンAPI追加
- 読書ログ機能
- 通知システム

### v1.2.0 (2024-03-01)
- 音響シーン機能
- 高度な分析API
- 管理者ダッシュボード

## サポート

- **開発者ドキュメント**: https://docs.roudoku.app
- **GitHub**: https://github.com/roudoku/api
- **技術サポート**: api-support@roudoku.app
- **Slack**: #roudoku-api (開発者向け)