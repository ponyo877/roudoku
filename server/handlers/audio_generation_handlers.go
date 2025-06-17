package handlers

import (
	"context"
	"encoding/json"
	"fmt"
	"net/http"
	"os"
	"path/filepath"
	"strconv"

	texttospeech "cloud.google.com/go/texttospeech/apiv1"
	"cloud.google.com/go/texttospeech/apiv1/texttospeechpb"
)

// AudioGenerationRequest represents a request to generate audio for a book chapter
type AudioGenerationRequest struct {
	BookID    int    `json:"book_id"`
	ChapterID int    `json:"chapter_id"`
	Text      string `json:"text"`
	Voice     string `json:"voice,omitempty"`
	Speed     float64 `json:"speed,omitempty"`
}

// AudioGenerationResponse represents the response containing the generated audio file URL
type AudioGenerationResponse struct {
	AudioURL  string `json:"audio_url"`
	Duration  int    `json:"duration"` // in seconds
	FileSize  int64  `json:"file_size"` // in bytes
	Generated bool   `json:"generated"`
}

// BookContent represents the structure of book content JSON files
type BookContent struct {
	ID          string           `json:"id"`
	Title       string           `json:"title"`
	Author      string           `json:"author"`
	Description string           `json:"description"`
	Chapters    []ChapterContent `json:"chapters"`
}

type ChapterContent struct {
	ID       string `json:"id"`
	Title    string `json:"title"`
	Content  string `json:"content"`
	Duration int    `json:"duration"`
}

// GenerateBookAudio generates audio files for an entire book
func GenerateBookAudio(w http.ResponseWriter, r *http.Request) {
	var req AudioGenerationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, fmt.Sprintf("Invalid request format: %v", err), http.StatusBadRequest)
		return
	}

	// Load book content
	bookContent, err := loadBookContent(req.BookID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load book content: %v", err), http.StatusNotFound)
		return
	}

	// Generate audio for the specific chapter
	if req.ChapterID < 0 || req.ChapterID >= len(bookContent.Chapters) {
		http.Error(w, "Invalid chapter ID", http.StatusBadRequest)
		return
	}

	chapter := bookContent.Chapters[req.ChapterID]
	audioURL, err := generateChapterAudio(req.BookID, req.ChapterID, chapter, req.Voice, req.Speed)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to generate audio: %v", err), http.StatusInternalServerError)
		return
	}

	// Get file info
	filePath := getAudioFilePath(req.BookID, req.ChapterID)
	fileInfo, err := os.Stat(filePath)
	var fileSize int64 = 0
	if err == nil {
		fileSize = fileInfo.Size()
	}

	response := AudioGenerationResponse{
		AudioURL:  audioURL,
		Duration:  chapter.Duration * 60, // convert minutes to seconds (rough estimate)
		FileSize:  fileSize,
		Generated: true,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetBookAudio returns the audio file URL for a book chapter
func GetBookAudio(w http.ResponseWriter, r *http.Request) {
	// Extract book ID and chapter ID from URL parameters
	bookIDStr := r.URL.Query().Get("book_id")
	chapterIDStr := r.URL.Query().Get("chapter_id")

	bookID, err := strconv.Atoi(bookIDStr)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	chapterID, err := strconv.Atoi(chapterIDStr)
	if err != nil {
		http.Error(w, "Invalid chapter ID", http.StatusBadRequest)
		return
	}

	// Check if audio file already exists
	filePath := getAudioFilePath(bookID, chapterID)
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		// Generate audio if it doesn't exist
		bookContent, err := loadBookContent(bookID)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to load book content: %v", err), http.StatusNotFound)
			return
		}

		if chapterID < 0 || chapterID >= len(bookContent.Chapters) {
			http.Error(w, "Invalid chapter ID", http.StatusBadRequest)
			return
		}

		chapter := bookContent.Chapters[chapterID]
		_, err = generateChapterAudio(bookID, chapterID, chapter, "", 1.0)
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to generate audio: %v", err), http.StatusInternalServerError)
			return
		}
	}

	// Serve the audio file
	http.ServeFile(w, r, filePath)
}

// generateChapterAudio generates an audio file for a specific chapter
func generateChapterAudio(bookID, chapterID int, chapter ChapterContent, voice string, speed float64) (string, error) {
	// Set defaults
	if voice == "" {
		voice = "ja-JP-Wavenet-A"
	}
	if speed == 0 {
		speed = 1.0
	}

	// Create TTS client
	ctx := context.Background()
	client, err := texttospeech.NewClient(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to create TTS client: %v", err)
	}
	defer client.Close()

	// Prepare the text (chapter title + content)
	fullText := fmt.Sprintf("%s。\n\n%s", chapter.Title, chapter.Content)

	// Build the voice selection parameters
	voiceParams := &texttospeechpb.VoiceSelectionParams{
		LanguageCode: "ja-JP",
		Name:         voice,
	}

	// Build the audio configuration
	audioConfig := &texttospeechpb.AudioConfig{
		AudioEncoding:   texttospeechpb.AudioEncoding_MP3,
		SpeakingRate:    speed,
		Pitch:           0.0,
		VolumeGainDb:    0.0,
		SampleRateHertz: 24000,
	}

	// Build the TTS request
	ttsReq := &texttospeechpb.SynthesizeSpeechRequest{
		Input: &texttospeechpb.SynthesisInput{
			InputSource: &texttospeechpb.SynthesisInput_Text{
				Text: fullText,
			},
		},
		Voice:       voiceParams,
		AudioConfig: audioConfig,
	}

	// Perform the text-to-speech request
	resp, err := client.SynthesizeSpeech(ctx, ttsReq)
	if err != nil {
		return "", fmt.Errorf("failed to synthesize speech: %v", err)
	}

	// Save audio to file
	filePath := getAudioFilePath(bookID, chapterID)
	audioDir := filepath.Dir(filePath)
	
	// Create directory if it doesn't exist
	if err := os.MkdirAll(audioDir, 0755); err != nil {
		return "", fmt.Errorf("failed to create audio directory: %v", err)
	}

	// Write audio file
	if err := os.WriteFile(filePath, resp.AudioContent, 0644); err != nil {
		return "", fmt.Errorf("failed to write audio file: %v", err)
	}

	// Return the URL path for the audio file
	audioURL := fmt.Sprintf("/api/v1/audio/files/book_%d_chapter_%d.mp3", bookID, chapterID)
	return audioURL, nil
}

// loadBookContent loads book content from database
func loadBookContent(bookID int) (*BookContent, error) {
	// Note: This function would need access to the database connection
	// For now, returning an error to indicate that the implementation needs to be updated
	return nil, fmt.Errorf("loadBookContent needs to be updated to use database instead of JSON files")
}

// getAudioFilePath returns the file path for storing audio files
func getAudioFilePath(bookID, chapterID int) string {
	audioDir := "audio_files"
	filename := fmt.Sprintf("book_%d_chapter_%d.mp3", bookID, chapterID)
	return filepath.Join(audioDir, filename)
}

// ServeAudioFile serves audio files from the file system
func ServeAudioFile(w http.ResponseWriter, r *http.Request) {
	// Extract filename from URL path
	filename := filepath.Base(r.URL.Path)
	filePath := filepath.Join("audio_files", filename)

	// Check if file exists
	if _, err := os.Stat(filePath); os.IsNotExist(err) {
		http.Error(w, "Audio file not found", http.StatusNotFound)
		return
	}

	// Set appropriate headers
	w.Header().Set("Content-Type", "audio/mpeg")
	w.Header().Set("Content-Disposition", fmt.Sprintf("inline; filename=\"%s\"", filename))

	// Serve the file
	http.ServeFile(w, r, filePath)
}

// RegenerateAllBookAudio regenerates audio for all chapters of a book
func RegenerateAllBookAudio(w http.ResponseWriter, r *http.Request) {
	bookIDStr := r.URL.Query().Get("book_id")
	bookID, err := strconv.Atoi(bookIDStr)
	if err != nil {
		http.Error(w, "Invalid book ID", http.StatusBadRequest)
		return
	}

	// Load book content
	bookContent, err := loadBookContent(bookID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to load book content: %v", err), http.StatusNotFound)
		return
	}

	// Generate audio for all chapters
	var results []AudioGenerationResponse
	for i, chapter := range bookContent.Chapters {
		audioURL, err := generateChapterAudio(bookID, i, chapter, "", 1.0)
		if err != nil {
			fmt.Printf("Failed to generate audio for chapter %d: %v\n", i, err)
			continue
		}

		// Get file info
		filePath := getAudioFilePath(bookID, i)
		fileInfo, err := os.Stat(filePath)
		var fileSize int64 = 0
		if err == nil {
			fileSize = fileInfo.Size()
		}

		results = append(results, AudioGenerationResponse{
			AudioURL:  audioURL,
			Duration:  chapter.Duration * 60,
			FileSize:  fileSize,
			Generated: true,
		})
	}

	response := map[string]interface{}{
		"book_id":        bookID,
		"total_chapters": len(bookContent.Chapters),
		"generated":      len(results),
		"results":        results,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}