package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"os"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ponyo877/roudoku/server/internal/config"
	"github.com/ponyo877/roudoku/server/internal/database"
)

type AozoraBook struct {
	ID                  int64
	Title              string
	TitleReading       string
	Author             string
	AuthorReading      string
	Genre              string
	WordCount          int
	TextFileURL        string
	PublicationDate    time.Time
	LastUpdated        time.Time
}

func parseCSVRow(record []string) (*AozoraBook, error) {
	if len(record) < 50 {
		return nil, fmt.Errorf("insufficient columns in CSV row: got %d", len(record))
	}

	// CSVのカラム定義に基づいてパース（0ベースインデックス）
	workID := strings.Trim(record[0], `"`)
	title := strings.Trim(record[1], `"`)
	titleReading := strings.Trim(record[2], `"`)
	author := strings.Trim(record[15], `"`) // 姓（16番目カラム）
	authorName := strings.Trim(record[16], `"`) // 名（17番目カラム）
	authorReading := strings.Trim(record[17], `"`) + strings.Trim(record[18], `"`) // 姓読み + 名読み
	genre := strings.Trim(record[8], `"`) // 分類番号
	textFileURL := strings.Trim(record[45], `"`) // テキストファイルURL（46番目カラム）
	publicationDateStr := strings.Trim(record[11], `"`) // 公開日
	lastUpdatedStr := strings.Trim(record[12], `"`) // 最終更新日

	// 作品IDをint64に変換
	id, err := strconv.ParseInt(workID, 10, 64)
	if err != nil {
		return nil, fmt.Errorf("failed to parse work ID: %v", err)
	}

	// 著者名を結合（姓+名の順番で）
	fullAuthor := author
	if authorName != "" {
		fullAuthor = author + authorName
	}

	// 日付をパース
	var publicationDate, lastUpdated time.Time
	if publicationDateStr != "" {
		publicationDate, _ = time.Parse("2006-01-02", publicationDateStr)
	}
	if lastUpdatedStr != "" {
		lastUpdated, _ = time.Parse("2006-01-02", lastUpdatedStr)
	}

	return &AozoraBook{
		ID:              id,
		Title:           title,
		TitleReading:    titleReading,
		Author:          fullAuthor,
		AuthorReading:   authorReading,
		Genre:           genre,
		WordCount:       0, // CSVには含まれていないためデフォルト値
		TextFileURL:     textFileURL,
		PublicationDate: publicationDate,
		LastUpdated:     lastUpdated,
	}, nil
}

func insertBookToDB(db *pgxpool.Pool, book *AozoraBook) error {
	query := `
		INSERT INTO books (
			id, title, author, epoch, word_count, content_url, 
			summary, genre, difficulty_level, estimated_reading_minutes,
			download_count, rating_average, rating_count, is_premium, is_active,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
		) ON CONFLICT (id) DO NOTHING`

	_, err := db.Exec(context.Background(), query,
		book.ID,
		book.Title,
		book.Author,
		nil, // epoch
		book.WordCount,
		book.TextFileURL,
		fmt.Sprintf("青空文庫の作品「%s」by %s", book.Title, book.Author), // summary
		book.Genre,
		1, // difficulty_level
		0, // estimated_reading_minutes
		0, // download_count
		0.0, // rating_average
		0,   // rating_count
		false, // is_premium
		true,  // is_active
		time.Now(),
		time.Now(),
	)

	return err
}

func main() {
	log.Println("青空文庫データベース投入スクリプトを開始します...")

	// 設定を読み込み
	cfg := config.Load()

	// データベースに接続
	db, err := database.Connect(cfg.Database)
	if err != nil {
		log.Fatalf("データベース接続エラー: %v", err)
	}
	defer db.Close()

	// CSVファイルを開く
	file, err := os.Open("list_person_all_extended_utf8.csv")
	if err != nil {
		log.Fatalf("CSVファイルを開けません: %v", err)
	}
	defer file.Close()

	reader := csv.NewReader(file)
	reader.Comma = ','
	reader.LazyQuotes = true

	// ヘッダー行をスキップ
	_, err = reader.Read()
	if err != nil {
		log.Fatalf("ヘッダー行の読み取りエラー: %v", err)
	}

	// 著名作家の作品を選択して投入
	famousAuthors := map[string]bool{
		"夏目漱石":   true,
		"太宰治":    true,
		"芥川竜之介": true,
		"宮沢賢治":   true,
		"中島敦":    true,
		"森鴎外":    true,
		"森外":     true,
		"樋口一葉":   true,
		"与謝野晶子": true,
		"坂口安吾":   true,
		"梶井基次郎": true,
	}

	insertedCount := 0
	targetCount := 10

	log.Println("CSVファイルを読み込み中...")

	lineCount := 0
	for {
		record, err := reader.Read()
		if err == io.EOF {
			break
		}
		if err != nil {
			log.Printf("CSV読み取りエラー: %v", err)
			continue
		}
		
		lineCount++
		if lineCount%1000 == 0 {
			log.Printf("処理済み行数: %d", lineCount)
		}

		// 最初の10行については詳細情報を出力
		if lineCount <= 10 {
			log.Printf("行 %d: カラム数 %d", lineCount, len(record))
			if len(record) > 16 {
				log.Printf("  著者データ: 姓='%s', 名='%s'", record[15], record[16])
			}
		}

		book, err := parseCSVRow(record)
		if err != nil {
			// 最初の3行のエラーをログに出力
			if lineCount <= 3 {
				log.Printf("CSV解析エラー: %v", err)
			}
			continue // エラー行はスキップ
		}
		
		// デバッグ用：夏目漱石を探す
		if strings.Contains(book.Author, "夏目") {
			log.Printf("夏目関連著者発見: '%s', 作品: '%s', URL: '%s'", book.Author, book.Title, book.TextFileURL)
		}

		// 著名作家の作品のみを投入
		if famousAuthors[book.Author] && book.TextFileURL != "" {
			log.Printf("マッチした著者: %s, 作品: %s", book.Author, book.Title)
			err = insertBookToDB(db, book)
			if err != nil {
				if strings.Contains(err.Error(), "duplicate key") {
					// 重複エラーは無視
					continue
				}
				log.Printf("データベース投入エラー (ID: %d, Title: %s): %v", book.ID, book.Title, err)
				continue
			}

			log.Printf("投入完了: [%d] %s by %s", book.ID, book.Title, book.Author)
			insertedCount++

			if insertedCount >= targetCount {
				break
			}
		}
	}

	log.Printf("青空文庫データ投入完了: %d件の作品を投入しました", insertedCount)
}