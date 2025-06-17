package handlers

import (
	"context"
	"fmt"
	"io"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"time"

	"cloud.google.com/go/storage"
	"encoding/json"
	"google.golang.org/api/iterator"
)

const (
	bucketName = "roudoku-audio-files" // Cloud Storage bucket name
	audioPrefix = "audio/"              // Prefix for audio files in bucket
)

// CloudStorageConfig represents Cloud Storage configuration
type CloudStorageConfig struct {
	BucketName string `json:"bucket_name"`
	ProjectID  string `json:"project_id"`
}

// UploadAudioToCloudStorage uploads a local audio file to Cloud Storage
func UploadAudioToCloudStorage(w http.ResponseWriter, r *http.Request) {
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

	// Check if local audio file exists
	localPath := getAudioFilePath(bookID, chapterID)
	if _, err := os.Stat(localPath); os.IsNotExist(err) {
		http.Error(w, "Audio file not found locally", http.StatusNotFound)
		return
	}

	// Upload to Cloud Storage
	cloudURL, err := uploadFileToCloudStorage(localPath, bookID, chapterID)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to upload to Cloud Storage: %v", err), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"message": "Audio file uploaded successfully",
		"book_id": bookID,
		"chapter_id": chapterID,
		"cloud_url": cloudURL,
		"local_path": localPath,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// SyncAllAudioToCloudStorage uploads all local audio files to Cloud Storage
func SyncAllAudioToCloudStorage(w http.ResponseWriter, r *http.Request) {
	audioDir := "audio_files"
	
	// Check if audio directory exists
	if _, err := os.Stat(audioDir); os.IsNotExist(err) {
		http.Error(w, "No audio files found", http.StatusNotFound)
		return
	}

	// Get all audio files
	files, err := os.ReadDir(audioDir)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to read audio directory: %v", err), http.StatusInternalServerError)
		return
	}

	var results []map[string]interface{}
	successCount := 0

	for _, file := range files {
		if !file.IsDir() && filepath.Ext(file.Name()) == ".mp3" {
			localPath := filepath.Join(audioDir, file.Name())
			
			// Parse book and chapter ID from filename (book_X_chapter_Y.mp3)
			bookID, chapterID, err := parseAudioFilename(file.Name())
			if err != nil {
				results = append(results, map[string]interface{}{
					"file": file.Name(),
					"status": "error",
					"error": fmt.Sprintf("Failed to parse filename: %v", err),
				})
				continue
			}

			cloudURL, err := uploadFileToCloudStorage(localPath, bookID, chapterID)
			if err != nil {
				results = append(results, map[string]interface{}{
					"file": file.Name(),
					"book_id": bookID,
					"chapter_id": chapterID,
					"status": "error",
					"error": err.Error(),
				})
			} else {
				results = append(results, map[string]interface{}{
					"file": file.Name(),
					"book_id": bookID,
					"chapter_id": chapterID,
					"status": "success",
					"cloud_url": cloudURL,
				})
				successCount++
			}
		}
	}

	response := map[string]interface{}{
		"message": "Audio sync completed",
		"total_files": len(results),
		"successful_uploads": successCount,
		"results": results,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// GetAudioFromCloudStorage retrieves audio file from Cloud Storage
func GetAudioFromCloudStorage(w http.ResponseWriter, r *http.Request) {
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

	// Create Cloud Storage client
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create Cloud Storage client: %v", err), http.StatusInternalServerError)
		return
	}
	defer client.Close()

	// Get object from Cloud Storage
	objectName := fmt.Sprintf("%sbook_%d_chapter_%d.mp3", audioPrefix, bookID, chapterID)
	bucket := client.Bucket(bucketName)
	obj := bucket.Object(objectName)

	reader, err := obj.NewReader(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("Audio file not found in Cloud Storage: %v", err), http.StatusNotFound)
		return
	}
	defer reader.Close()

	// Set appropriate headers
	w.Header().Set("Content-Type", "audio/mpeg")
	w.Header().Set("Content-Disposition", fmt.Sprintf("inline; filename=\"book_%d_chapter_%d.mp3\"", bookID, chapterID))

	// Stream the file content
	if _, err := io.Copy(w, reader); err != nil {
		http.Error(w, fmt.Sprintf("Failed to stream audio: %v", err), http.StatusInternalServerError)
		return
	}
}

// uploadFileToCloudStorage uploads a local file to Cloud Storage
func uploadFileToCloudStorage(localPath string, bookID, chapterID int) (string, error) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		return "", fmt.Errorf("failed to create Cloud Storage client: %v", err)
	}
	defer client.Close()

	// Open local file
	file, err := os.Open(localPath)
	if err != nil {
		return "", fmt.Errorf("failed to open local file: %v", err)
	}
	defer file.Close()

	// Create object in Cloud Storage
	objectName := fmt.Sprintf("%sbook_%d_chapter_%d.mp3", audioPrefix, bookID, chapterID)
	bucket := client.Bucket(bucketName)
	obj := bucket.Object(objectName)

	// Create writer
	writer := obj.NewWriter(ctx)
	writer.ContentType = "audio/mpeg"
	writer.CacheControl = "public, max-age=86400" // Cache for 24 hours

	// Copy file content
	if _, err := io.Copy(writer, file); err != nil {
		writer.Close()
		return "", fmt.Errorf("failed to copy file content: %v", err)
	}

	if err := writer.Close(); err != nil {
		return "", fmt.Errorf("failed to close writer: %v", err)
	}

	// Generate public URL
	cloudURL := fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, objectName)
	return cloudURL, nil
}

// parseAudioFilename parses book and chapter ID from audio filename
func parseAudioFilename(filename string) (bookID, chapterID int, err error) {
	// Expected format: book_X_chapter_Y.mp3
	var book, chapter int
	n, err := fmt.Sscanf(filename, "book_%d_chapter_%d.mp3", &book, &chapter)
	if err != nil || n != 2 {
		return 0, 0, fmt.Errorf("invalid filename format: %s", filename)
	}
	return book, chapter, nil
}

// GetCloudStorageStatus returns the status of files in Cloud Storage
func GetCloudStorageStatus(w http.ResponseWriter, r *http.Request) {
	ctx := context.Background()
	client, err := storage.NewClient(ctx)
	if err != nil {
		http.Error(w, fmt.Sprintf("Failed to create Cloud Storage client: %v", err), http.StatusInternalServerError)
		return
	}
	defer client.Close()

	bucket := client.Bucket(bucketName)
	
	// List all audio files in the bucket
	query := &storage.Query{Prefix: audioPrefix}
	it := bucket.Objects(ctx, query)

	var files []map[string]interface{}
	totalSize := int64(0)

	for {
		objAttrs, err := it.Next()
		if err == iterator.Done {
			break
		}
		if err != nil {
			http.Error(w, fmt.Sprintf("Failed to list objects: %v", err), http.StatusInternalServerError)
			return
		}

		// Parse book and chapter ID from object name
		filename := filepath.Base(objAttrs.Name)
		bookID, chapterID, err := parseAudioFilename(filename)
		
		fileInfo := map[string]interface{}{
			"name": objAttrs.Name,
			"size": objAttrs.Size,
			"created": objAttrs.Created.Format(time.RFC3339),
			"content_type": objAttrs.ContentType,
			"public_url": fmt.Sprintf("https://storage.googleapis.com/%s/%s", bucketName, objAttrs.Name),
		}

		if err == nil {
			fileInfo["book_id"] = bookID
			fileInfo["chapter_id"] = chapterID
		} else {
			fileInfo["parse_error"] = err.Error()
		}

		files = append(files, fileInfo)
		totalSize += objAttrs.Size
	}

	response := map[string]interface{}{
		"bucket_name": bucketName,
		"total_files": len(files),
		"total_size_bytes": totalSize,
		"total_size_mb": float64(totalSize) / (1024 * 1024),
		"files": files,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}