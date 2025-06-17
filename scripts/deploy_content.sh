#!/bin/bash

# CloudRunで動作中のサーバーに小説テキストと音声データを生成させるスクリプト

set -e

# 設定
SERVER_URL="https://roudoku-api-1083612487436.asia-northeast1.run.app"
API_BASE="$SERVER_URL/api/v1"

echo "🚀 CloudRunサーバーでコンテンツ生成を開始します..."
echo "サーバーURL: $SERVER_URL"
echo ""

# サーバーのヘルスチェック
echo "📡 サーバーの状態を確認中..."
if ! curl -s "$API_BASE/health" > /dev/null; then
    echo "❌ サーバーに接続できません。URLを確認してください。"
    exit 1
fi
echo "✅ サーバーは正常に動作しています"
echo ""

# 現在のコンテンツ状況を確認
echo "📋 現在のコンテンツ状況を確認中..."
CONTENT_STATUS=$(curl -s "$API_BASE/content/status")
echo "現在の状況:"
echo "$CONTENT_STATUS" | jq '.'
echo ""

# コンテンツ初期化を実行
echo "🎭 書籍コンテンツと音声ファイルの生成を開始..."
echo "⚠️  この処理には数分かかる場合があります（TTS API使用のため）"
echo ""

INIT_RESPONSE=$(curl -s -X POST \
    -H "Content-Type: application/json" \
    -d '{"force": true}' \
    "$API_BASE/content/initialize")

echo "📊 生成結果:"
echo "$INIT_RESPONSE" | jq '.'

# 生成後の状況確認
echo ""
echo "🔍 生成後のコンテンツ状況を確認中..."
FINAL_STATUS=$(curl -s "$API_BASE/content/status")
echo "最終状況:"
echo "$FINAL_STATUS" | jq '.'

echo ""
echo "☁️  Cloud Storageに音声ファイルを同期中..."
SYNC_RESPONSE=$(curl -s -X POST "$API_BASE/storage/sync")
echo "同期結果:"
echo "$SYNC_RESPONSE" | jq '.'

echo ""
echo "📊 Cloud Storage状況確認..."
STORAGE_STATUS=$(curl -s "$API_BASE/storage/status")
echo "Cloud Storage状況:"
echo "$STORAGE_STATUS" | jq '.total_files, .total_size_mb'

echo ""
echo "🎉 コンテンツ生成と同期が完了しました！"
echo ""
echo "📱 モバイルアプリでPlayerScreenを開いて音声再生をテストしてください"
echo "☁️  音声ファイルはCloud Storageに永続化されました"