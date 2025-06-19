package dto

import "time"

// TTSSynthesizeRequest represents a text-to-speech synthesis request
type TTSSynthesizeRequest struct {
	Text       string  `json:"text" validate:"required,min=1,max=5000"`
	Language   string  `json:"language" validate:"required"`
	Voice      string  `json:"voice" validate:"required"`
	Speed      float32 `json:"speed" validate:"omitempty,min=0.25,max=4.0"`
	Pitch      float32 `json:"pitch" validate:"omitempty,min=-20.0,max=20.0"`
	VolumeGain float32 `json:"volume_gain" validate:"omitempty,min=-96.0,max=16.0"`
}

// TTSSynthesizeResponse represents a text-to-speech synthesis response
type TTSSynthesizeResponse struct {
	AudioContent string    `json:"audio_content"`
	ContentType  string    `json:"content_type"`
	Duration     int       `json:"duration"` // Duration in seconds
	Language     string    `json:"language"`
	Voice        string    `json:"voice"`
	CreatedAt    time.Time `json:"created_at"`
}

// TTSVoicesResponse represents available voices response
type TTSVoicesResponse struct {
	Voices []TTSVoice `json:"voices"`
}

// TTSVoice represents a single voice option
type TTSVoice struct {
	Name                   string   `json:"name"`
	LanguageCodes          []string `json:"language_codes"`
	Gender                 string   `json:"gender"`
	NaturalSampleRateHertz int32    `json:"natural_sample_rate_hertz"`
}

// TTSPreviewRequest represents a voice preview request
type TTSPreviewRequest struct {
	Language    string  `json:"language" validate:"required"`
	Voice       string  `json:"voice" validate:"required"`
	PreviewText string  `json:"preview_text,omitempty"`
	Speed       float32 `json:"speed" validate:"omitempty,min=0.25,max=4.0"`
	Pitch       float32 `json:"pitch" validate:"omitempty,min=-20.0,max=20.0"`
	VolumeGain  float32 `json:"volume_gain" validate:"omitempty,min=-96.0,max=16.0"`
}

// TTSPreviewResponse represents a voice preview response
type TTSPreviewResponse struct {
	AudioContent string `json:"audio_content"`
	ContentType  string `json:"content_type"`
	Duration     int    `json:"duration"`
	PreviewText  string `json:"preview_text"`
}

// AudioFileUploadRequest represents an audio file upload request
type AudioFileUploadRequest struct {
	FileName    string `json:"file_name" validate:"required"`
	ContentType string `json:"content_type" validate:"required"`
	FileSize    int64  `json:"file_size" validate:"required,min=1"`
	AudioData   string `json:"audio_data" validate:"required"` // Base64 encoded
}

// AudioFileUploadResponse represents an audio file upload response
type AudioFileUploadResponse struct {
	FileID      string    `json:"file_id"`
	DownloadURL string    `json:"download_url"`
	FileName    string    `json:"file_name"`
	ContentType string    `json:"content_type"`
	FileSize    int64     `json:"file_size"`
	UploadedAt  time.Time `json:"uploaded_at"`
}

// AudioFileResponse represents an audio file info response
type AudioFileResponse struct {
	FileID      string    `json:"file_id"`
	FileName    string    `json:"file_name"`
	ContentType string    `json:"content_type"`
	FileSize    int64     `json:"file_size"`
	DownloadURL string    `json:"download_url"`
	CreatedAt   time.Time `json:"created_at"`
	UpdatedAt   time.Time `json:"updated_at"`
}