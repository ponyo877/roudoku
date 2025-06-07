# 青空 StoryWalk 要件定義書

## プロジェクト概要

青空文庫の作品から **「そのとき・その人に “ぴったり” 合う本を見つけて朗読してくれる** モバイル読書アプリを開発する。

* **多様なコンテキスト**（位置・天気・気分・空き時間・スワイプ評価 など）を AI エージェントが統合しレコメンド
* **最適な声色・速度** で TTS 朗読し、散歩・通勤・就寝前などシーンに合わせた音声体験を提供
* **フロント**: Flutter（iOS / Android 両対応）
* **バックエンド**: Go（REST + gRPC）＋ PostgreSQL
* **インフラ**: Terraform

---

## 技術スタック

| レイヤ            | 技術                                                                                                                                                                                                 |
| -------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Mobile アプリ** | Flutter 3.32.0 / Dart                                                                                                                                                                                 |
| **バックエンド API** | Go 1.24.4, net/http, gRPC — デプロイ先：Cloud Run                                                                                                                                                   |
| **AI 推薦エンジン**  | Go + Python microservices (Cloud Run)<br> - Embedding: Vertex AI Text Embedding API<br> - Vector Search: Vertex AI Vector Search<br> - Collaborative Filtering: BigQuery ML (Matrix Factorization) |
| **TTS**        | Google Cloud Text-to-Speech (WaveNet) + on-device fallback                                                                                                                                         |
| **DB**         | Cloud SQL (PostgreSQL) + BigQuery (分析) + Cloud Firestore (リアルタイム)                                                                                                                                  |
| **メッセージング**    | Cloud Pub/Sub (リアルタイムストリーム) + Cloud Tasks (非同期ジョブ)                                                                                                                                                 |
| **インフラ**       | Cloud Run, Cloud Storage, Vertex AI, Cloud Scheduler + Cloud Functions (ETL)                                                                                      |
| **認証**         | Firebase Auth（匿名→メール/Google/Twitter 連携）                                                                                                                                                            |
| **CI/CD**      | Cloud Build + GitHub Actions (trigger) + Cloud Deploy                                                                                                                                              |

---

## 機能要件

### 1. 認証・ユーザープロファイル

* 匿名利用 → 任意タイミングでアカウント連携
* プロフィール編集（ペンネーム、好みタグ、音声プリセット）

### 2. 作品カタログ & 検索

* 青空文庫 EPUB / XHTML インポート + メタデータ閲覧
* タグ／著者／長さ／時代などでフィルタリング
* 作品詳細に試し読み（最初の数段落）

### 3. 推薦エンジン

| ソース                 | 具体内容                                                                 |
| ------------------- | -------------------------------------------------------------------- |
| **a. エンタメ風フィードバック** | - *Tinder mode*: 1 つの引用を右 or 左スワイプ<br>- *Facemash mode*: 2 つの引用を比較選択 |
| **b. モバイルコンテキスト**   | GPS・季節・天気 API・時間帯                                                    |
| **c. 状況 & 気分入力**    | 空き時間(5/15/30/60 分)・今の/なりたい気分・体調選択                                    |
| **d. 協調フィルタ**       | Embedding + ユーザ / 類似ユーザ評価                                            |

> 推薦ロジックは Weighted Hybrid:
> `Score = w1*SwipePref + w2*ContextMatch + w3*MoodMatch + w4*CFScore`

### 4. 音声朗読

* 朗読前に **「声色×速度」** プレビュー
* BGM / 環境音 オプション（シーン解析による自動フェード）
* オフラインキャッシュ（EPUB + TTS 音声ファイル）

### 5. 読書セッション管理

* 再開位置の自動保存
* 「今日の読書ログ」通知（読了率）

### 6. フィードバック & 学習

* 本 / 朗読の 5 段階評価 + コメント
* AI エージェントが翌日の推薦に反映し、理由を自然文で説明

### 7. 管理者向け

* 作品メタデータ編集 UI
* 推薦モデル再学習ジョブのトリガー／モニタリング

---

## 画面構成

1. **ホーム** – 推薦カード（Swipe / Pair 比較切替）
2. **検索 & カタログ** – フィルタ＋全文検索
3. **作品詳細** – あらすじ / 試し読み / スタート朗読
4. **朗読プレイヤー** – 再生・速度・声色・BGM
5. **コンテキスト設定** – 気分・空き時間・体調入力
6. **読書ログ** – 統計・履歴・評価
7. **プロフィール** – 音声プリセット / 好みタグ
8. **管理者ダッシュボード**（Web）

---

## データベース設計

### 1. users

| 列                         | 型         | 備考                     |
| ------------------------- | --------- | ---------------------- |
| id                        | UUID      | PK / Firebase UID      |
| display\_name             | TEXT      |                        |
| email                     | TEXT      | nullable               |
| voice\_preset             | JSONB     | {gender, pitch, speed} |
| created\_at / updated\_at | TIMESTAMP |                        |

### 2. books

| 列           | 型      | 備考      |
| ----------- | ------ | ------- |
| id          | BIGINT | 青空文庫 ID |
| title       | TEXT   |         |
| author      | TEXT   |         |
| epoch       | TEXT   | 明治/大正…  |
| word\_count | INT    |         |
| embedding   | VECTOR | 768-dim |

### 3. quotes

| 列        | 型      | 備考       |
| -------- | ------ | -------- |
| id       | UUID   | PK       |
| book\_id | BIGINT | FK books |
| text     | TEXT   |          |
| position | INT    | 段落インデックス |

### 4. swipe\_logs

| 列           | 型                         | 備考                           |
| ----------- | ------------------------- | ---------------------------- |
| id          | UUID                      | PK                           |
| user\_id    | UUID                      |                              |
| quote\_id   | UUID                      |                              |
| mode        | ENUM('tinder','facemash') |                              |
| choice      | INT                       | 1=like / 0=dislike / -1=left |
| created\_at | TIMESTAMP                 |                              |

### 5. reading\_sessions

| 列             | 型         | 備考 |
| ------------- | --------- | -- |
| id            | UUID      | PK |
| user\_id      | UUID      |    |
| book\_id      | BIGINT    |    |
| start\_pos    | INT       |    |
| current\_pos  | INT       |    |
| duration\_sec | INT       |    |
| mood          | TEXT      |    |
| weather       | TEXT      |    |
| created\_at   | TIMESTAMP |    |

### 6. ratings

| 列        | 型      | 備考   |
| -------- | ------ | ---- |
| user\_id | UUID   | PK複合 |
| book\_id | BIGINT |      |
| rating   | INT    | 1–5  |
| comment  | TEXT   |      |

---

## 非機能要件

| 項目           | 要件                           |
| ------------ | ---------------------------- |
| **オフライン対応**  | 朗読データ・作品本文をローカルキャッシュ。圏外でも再生可 |
| **プライバシー**   | 位置データはローカル暗号化、個別 OPT-IN   |
| **パフォーマンス**  | 推薦 API < 300 ms / 作品検索 < 1 s |
| **アクセシビリティ** | 文字サイズ調整・ダークモード・スクリーンリーダー対応   |
| **拡張性**      | 推薦ロジックはマイクロサービス分割、AB テスト可能   |
| **国際化準備**    | UI 文言 i18n、TTS 言語切替を考慮       |

---

## 開発フェーズ

| フェーズ        | 内容                                   |
| ----------- | ------------------------------------ |
| **Phase 1** | リポジトリ & CI/CD 基盤構築、PostgreSQL スキーマ作成 |
| **Phase 2** | 認証・ユーザープロファイル CRUD                   |
| **Phase 3** | 青空文庫 ETL / 検索 API / カタログ画面           |
| **Phase 4** | TTS 朗読プレイヤー MVP（固定声色）                |
| **Phase 5** | Swipe / Pair UI + ログテーブル実装           |
| **Phase 6** | 推薦エンジン v1（協調 + コンテキスト）               |
| **Phase 7** | 音声プリセット最適化 + BGM ミキサー                |
| **Phase 8** | 読書ログ & 通知、管理ダッシュボード                  |
| **Phase 9** | 非機能要件チューニング、βテスト & ストア申請             |

※ MVP（最小機能リリース）はPhase 9まで全て含む

---

## ビジネスモデル

### 収益モデル
* **無料版**: AdMob広告（章の切れ目、スキップ可能）+ 作品数制限（20作品）
* **サブスク版**: 月額300円、広告なし、全作品アクセス（200作品〜）、オフライン再生可能
* **無料トライアル**: なし

### 初期コンテンツ戦略
* ローンチ時: 200作品（知名度の高い作品を優先）
* 無料版: 20作品まで
* 知名度判定: ダウンロード数・アクセス数、データがない場合は人力選定

---

## 実装詳細

### データ取得
* **青空文庫データソース**: GitHub版（aozorabunko/aozorabunko_text）
* **更新頻度**: 月1回の自動更新

### キャッシュ戦略
* **音声ファイル**: 端末ローカルに最大10作品分
* **キャッシュ管理**: 10作品を超えたら最も古いものから自動削除
* **オフライン再生**: サブスク限定機能

### TTS設定
* **音声品質**: Google Cloud Text-to-Speech (WaveNet)
* **読書速度**: 0.5x〜2.0xで調整可能
* **BGM/環境音**: 無料素材を使用

### 推薦エンジン初期実装
* **MVP版**: ランダム推薦（知名度の高い作品プール から）
* **将来的拡張**: Phase 6で高度な推薦アルゴリズムに移行

### 運用設定
* **Cloud Run設定**: 最小/最大インスタンス数 = 1（初期）
* **モニタリング**: Firebase Analytics
* **フィードバック収集**: アプリ内フィードバック機能

### コンテンツポリシー
* **初回リリース**: 成人向け（青空文庫の全作品対象）
* **将来的拡張**: キッズ向けフィルタリングモード追加

---

## 付録：AI 推薦アルゴリズム概要

1. **Embedding 準備**

   * X HTML → 文書単位 & 引用単位で 768 次元ベクトル化
2. **ユーザモデリング**

   * Swipe / Rating → ユーザベクトル更新 (LightFM)
3. **コンテキストマッチ**

   * `ContextVec = f(weather, location, mood)` を時系列 DeBERTa で 256 次元化
4. **スコア統合**
   * 重み α–δ はオンライン学習で動的最適化
