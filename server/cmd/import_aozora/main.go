package main

import (
	"context"
	"encoding/csv"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/jackc/pgx/v5/pgxpool"
	"github.com/ponyo877/roudoku/server/internal/config"
	"github.com/ponyo877/roudoku/server/internal/database"
	"golang.org/x/text/encoding/japanese"
	"golang.org/x/text/transform"
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

func downloadTextFile(url string) (string, error) {
	resp, err := http.Get(url)
	if err != nil {
		return "", fmt.Errorf("failed to download file: %v", err)
	}
	defer resp.Body.Close()

	// Shift_JISからUTF-8に変換
	reader := transform.NewReader(resp.Body, japanese.ShiftJIS.NewDecoder())
	
	content, err := io.ReadAll(reader)
	if err != nil {
		return "", fmt.Errorf("failed to read file: %v", err)
	}

	text := string(content)
	
	// 青空文庫のフォーマットから本文を抽出
	// ヘッダーとフッターを除去
	lines := strings.Split(text, "\n")
	var startIdx, endIdx int
	
	// 本文開始位置を探す
	for i, line := range lines {
		if strings.Contains(line, "-------------------------------------------------------") {
			startIdx = i + 1
			break
		}
	}
	
	// 本文終了位置を探す（底本情報の開始）
	for i := len(lines) - 1; i >= 0; i-- {
		if strings.Contains(lines[i], "底本：") || strings.Contains(lines[i], "※") {
			endIdx = i
			break
		}
	}
	
	if endIdx == 0 {
		endIdx = len(lines)
	}
	
	// 本文を結合
	if startIdx < endIdx {
		contentLines := lines[startIdx:endIdx]
		text = strings.Join(contentLines, "\n")
	}
	
	// null文字を除去
	text = strings.ReplaceAll(text, "\x00", "")
	
	// ルビや注釈の除去（簡易版）
	text = strings.ReplaceAll(text, "｜", "")
	// 《》内のルビを除去
	for strings.Contains(text, "《") && strings.Contains(text, "》") {
		start := strings.Index(text, "《")
		end := strings.Index(text, "》")
		if start != -1 && end != -1 && end > start {
			text = text[:start] + text[end+len("》"):]
		} else {
			break
		}
	}
	
	// 【】内の注釈を除去
	for strings.Contains(text, "【") && strings.Contains(text, "】") {
		start := strings.Index(text, "【")
		end := strings.Index(text, "】")
		if start != -1 && end != -1 && end > start {
			text = text[:start] + text[end+len("】"):]
		} else {
			break
		}
	}
	
	// ［］内の注釈を除去
	for strings.Contains(text, "［") && strings.Contains(text, "］") {
		start := strings.Index(text, "［")
		end := strings.Index(text, "］")
		if start != -1 && end != -1 && end > start {
			text = text[:start] + text[end+len("］"):]
		} else {
			break
		}
	}
	
	// その他の制御文字を除去
	text = strings.ReplaceAll(text, "\r", "")
	text = strings.ReplaceAll(text, "\f", "")
	text = strings.ReplaceAll(text, "\v", "")
	
	// 空行を整理
	lines = strings.Split(text, "\n")
	var cleanedLines []string
	for _, line := range lines {
		trimmed := strings.TrimSpace(line)
		if trimmed != "" && utf8.ValidString(trimmed) {
			cleanedLines = append(cleanedLines, trimmed)
		}
	}
	
	return strings.Join(cleanedLines, "\n\n"), nil
}

func splitIntoChapters(content string, maxChapterLength int) []struct {
	Title   string
	Content string
} {
	// 章を分割（約5000文字ごと）
	var chapters []struct {
		Title   string
		Content string
	}
	
	lines := strings.Split(content, "\n\n")
	currentChapter := ""
	chapterNum := 1
	
	for _, line := range lines {
		if utf8.RuneCountInString(currentChapter)+utf8.RuneCountInString(line) > maxChapterLength && currentChapter != "" {
			chapters = append(chapters, struct {
				Title   string
				Content string
			}{
				Title:   fmt.Sprintf("第%d章", chapterNum),
				Content: strings.TrimSpace(currentChapter),
			})
			currentChapter = line
			chapterNum++
		} else {
			if currentChapter != "" {
				currentChapter += "\n\n"
			}
			currentChapter += line
		}
	}
	
	// 最後の章を追加
	if currentChapter != "" {
		chapters = append(chapters, struct {
			Title   string
			Content string
		}{
			Title:   fmt.Sprintf("第%d章", chapterNum),
			Content: strings.TrimSpace(currentChapter),
		})
	}
	
	return chapters
}

func insertBookWithChaptersToDB(db *pgxpool.Pool, book *AozoraBook, content string) error {
	// トランザクション開始
	tx, err := db.Begin(context.Background())
	if err != nil {
		return fmt.Errorf("failed to begin transaction: %v", err)
	}
	defer tx.Rollback(context.Background())

	// 文字数を計算
	wordCount := utf8.RuneCountInString(content)
	estimatedReadingMinutes := wordCount / 400 // 日本語の平均読書速度は400文字/分

	// まず書籍情報を挿入
	bookQuery := `
		INSERT INTO books (
			id, title, author, epoch, word_count, content_url, 
			summary, genre, difficulty_level, estimated_reading_minutes,
			download_count, rating_average, rating_count, is_premium, is_active,
			created_at, updated_at
		) VALUES (
			$1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17
		) ON CONFLICT (id) DO UPDATE SET
			word_count = EXCLUDED.word_count,
			estimated_reading_minutes = EXCLUDED.estimated_reading_minutes,
			updated_at = EXCLUDED.updated_at`

	_, err = tx.Exec(context.Background(), bookQuery,
		book.ID,
		book.Title,
		book.Author,
		nil, // epoch
		wordCount,
		book.TextFileURL,
		fmt.Sprintf("青空文庫の作品「%s」by %s", book.Title, book.Author),
		book.Genre,
		1, // difficulty_level
		estimatedReadingMinutes,
		0,     // download_count
		0.0,   // rating_average
		0,     // rating_count
		false, // is_premium
		true,  // is_active
		time.Now(),
		time.Now(),
	)
	if err != nil {
		return fmt.Errorf("failed to insert book: %v", err)
	}

	// 既存の章を削除
	_, err = tx.Exec(context.Background(), "DELETE FROM chapters WHERE book_id = $1", book.ID)
	if err != nil {
		return fmt.Errorf("failed to delete existing chapters: %v", err)
	}

	// 章に分割して挿入
	chapters := splitIntoChapters(content, 5000)
	for i, chapter := range chapters {
		chapterWordCount := utf8.RuneCountInString(chapter.Content)
		chapterQuery := `
			INSERT INTO chapters (
				id, book_id, title, content, position, word_count, created_at
			) VALUES (gen_random_uuid(), $1, $2, $3, $4, $5, $6)`
		
		_, err = tx.Exec(context.Background(), chapterQuery,
			book.ID,
			chapter.Title,
			chapter.Content,
			i+1,
			chapterWordCount,
			time.Now(),
		)
		if err != nil {
			return fmt.Errorf("failed to insert chapter %d: %v", i+1, err)
		}
	}

	// コミット
	if err = tx.Commit(context.Background()); err != nil {
		return fmt.Errorf("failed to commit transaction: %v", err)
	}

	return nil
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
		"島崎藤村":   true,
		"志賀直哉":   true,
		"谷崎潤一郎": true,
		"川端康成":   true,
		"三島由紀夫": true,
		"堀辰雄":    true,
		"有島武郎":   true,
		"石川啄木":   true,
		"正岡子規":   true,
		"北原白秋":   true,
		"萩原朔太郎": true,
		"中原中也":   true,
		"小林多喜二": true,
		"横光利一":   true,
		"武者小路実篤": true,
		"菊池寛":    true,
		"江戸川乱歩": true,
		"葉山嘉樹":   true,
		"小川未明":   true,
	}

	insertedCount := 0
	targetCount := 100

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
			log.Printf("マッチした著者: %s, 作品: %s, URL: %s", book.Author, book.Title, book.TextFileURL)
			
			// テキストファイルをダウンロード
			content, err := downloadTextFile(book.TextFileURL)
			if err != nil {
				log.Printf("テキストダウンロードエラー (ID: %d, Title: %s): %v", book.ID, book.Title, err)
				continue
			}
			
			// 内容が短すぎる場合はスキップ
			if utf8.RuneCountInString(content) < 1000 {
				log.Printf("スキップ: 内容が短すぎます (ID: %d, Title: %s, 文字数: %d)", book.ID, book.Title, utf8.RuneCountInString(content))
				continue
			}
			
			// データベースに投入
			err = insertBookWithChaptersToDB(db, book, content)
			if err != nil {
				if strings.Contains(err.Error(), "duplicate key") {
					// 重複エラーは無視
					log.Printf("既に存在: [%d] %s by %s", book.ID, book.Title, book.Author)
					continue
				}
				log.Printf("データベース投入エラー (ID: %d, Title: %s): %v", book.ID, book.Title, err)
				continue
			}

			log.Printf("投入完了: [%d] %s by %s (文字数: %d)", book.ID, book.Title, book.Author, utf8.RuneCountInString(content))
			insertedCount++

			if insertedCount >= targetCount {
				break
			}
		}
	}

	log.Printf("青空文庫データ投入完了: %d件の作品を投入しました", insertedCount)
}