package services

import (
	"context"
	"encoding/base64"
	"fmt"
	"time"

	texttospeech "cloud.google.com/go/texttospeech/apiv1"
	"cloud.google.com/go/texttospeech/apiv1/texttospeechpb"
	"google.golang.org/api/option"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
)

// TTSService defines the interface for text-to-speech operations
type TTSService interface {
	SynthesizeText(ctx context.Context, req *dto.TTSSynthesizeRequest) (*dto.TTSSynthesizeResponse, error)
	GetAvailableVoices(ctx context.Context, languageCode string) (*dto.TTSVoicesResponse, error)
	PreviewVoice(ctx context.Context, req *dto.TTSPreviewRequest) (*dto.TTSPreviewResponse, error)
}

// ttsService implements TTSService
type ttsService struct {
	*BaseService
	client         *texttospeech.Client
	credentialsPath string
}

// NewTTSService creates a new TTS service
func NewTTSService(credentialsPath string, logger *logger.Logger) (TTSService, error) {
	ctx := context.Background()
	
	var client *texttospeech.Client
	var err error
	
	if credentialsPath != "" {
		client, err = texttospeech.NewClient(ctx, option.WithCredentialsFile(credentialsPath))
	} else {
		// Use default credentials (for production with service account)
		client, err = texttospeech.NewClient(ctx)
	}
	
	if err != nil {
		return nil, fmt.Errorf("failed to create TTS client: %w", err)
	}

	return &ttsService{
		BaseService:     NewBaseService(logger),
		client:         client,
		credentialsPath: credentialsPath,
	}, nil
}

// SynthesizeText synthesizes text to speech using Google Cloud TTS
func (s *ttsService) SynthesizeText(ctx context.Context, req *dto.TTSSynthesizeRequest) (*dto.TTSSynthesizeResponse, error) {
	s.logger.Info("Synthesizing text to speech")

	if err := s.ValidateStruct(req); err != nil {
		s.logger.Error("Validation failed")
		return nil, fmt.Errorf("validation failed: %w", err)
	}

	// Build the TTS request
	ttsReq := &texttospeechpb.SynthesizeSpeechRequest{
		Input: &texttospeechpb.SynthesisInput{
			InputSource: &texttospeechpb.SynthesisInput_Text{
				Text: req.Text,
			},
		},
		Voice: &texttospeechpb.VoiceSelectionParams{
			LanguageCode: req.Language,
			Name:         req.Voice,
		},
		AudioConfig: &texttospeechpb.AudioConfig{
			AudioEncoding:   texttospeechpb.AudioEncoding_MP3,
			SpeakingRate:    float64(req.Speed),
			Pitch:           float64(req.Pitch),
			VolumeGainDb:    float64(req.VolumeGain),
			SampleRateHertz: 22050,
		},
	}

	// Call Google Cloud TTS
	resp, err := s.client.SynthesizeSpeech(ctx, ttsReq)
	if err != nil {
		s.logger.Error("TTS synthesis failed")
		return nil, fmt.Errorf("TTS synthesis failed: %w", err)
	}

	// Encode audio data to base64
	audioContent := base64.StdEncoding.EncodeToString(resp.AudioContent)

	return &dto.TTSSynthesizeResponse{
		AudioContent: audioContent,
		ContentType:  "audio/mpeg",
		Duration:     s.estimateDuration(req.Text, req.Speed),
		Language:     req.Language,
		Voice:        req.Voice,
		CreatedAt:    time.Now(),
	}, nil
}

// GetAvailableVoices returns available voices for the specified language
func (s *ttsService) GetAvailableVoices(ctx context.Context, languageCode string) (*dto.TTSVoicesResponse, error) {
	s.logger.Info("Getting available voices")

	req := &texttospeechpb.ListVoicesRequest{
		LanguageCode: languageCode,
	}

	resp, err := s.client.ListVoices(ctx, req)
	if err != nil {
		s.logger.Error("Failed to get voices")
		return nil, fmt.Errorf("failed to get voices: %w", err)
	}

	var voices []dto.TTSVoice
	for _, voice := range resp.Voices {
		voices = append(voices, dto.TTSVoice{
			Name:         voice.Name,
			LanguageCodes: voice.LanguageCodes,
			Gender:       voice.SsmlGender.String(),
			NaturalSampleRateHertz: voice.NaturalSampleRateHertz,
		})
	}

	return &dto.TTSVoicesResponse{
		Voices: voices,
	}, nil
}

// PreviewVoice generates a short preview of the voice
func (s *ttsService) PreviewVoice(ctx context.Context, req *dto.TTSPreviewRequest) (*dto.TTSPreviewResponse, error) {
	s.logger.Info("Generating voice preview")

	// Use a standard preview text
	previewText := "こんにちは。これは音声のプレビューです。"
	if req.PreviewText != "" {
		previewText = req.PreviewText
	}

	synthesizeReq := &dto.TTSSynthesizeRequest{
		Text:       previewText,
		Language:   req.Language,
		Voice:      req.Voice,
		Speed:      req.Speed,
		Pitch:      req.Pitch,
		VolumeGain: req.VolumeGain,
	}

	result, err := s.SynthesizeText(ctx, synthesizeReq)
	if err != nil {
		return nil, fmt.Errorf("preview generation failed: %w", err)
	}

	return &dto.TTSPreviewResponse{
		AudioContent: result.AudioContent,
		ContentType:  result.ContentType,
		Duration:     result.Duration,
		PreviewText:  previewText,
	}, nil
}

// estimateDuration estimates audio duration based on text length and speed
func (s *ttsService) estimateDuration(text string, speed float32) int {
	// Rough estimation: 150 words per minute for Japanese at normal speed
	wordsPerMinute := 150.0 * float64(speed)
	wordCount := float64(len([]rune(text))) / 2.0 // Rough Japanese word count estimation
	durationMinutes := wordCount / wordsPerMinute
	return int(durationMinutes * 60) // Return duration in seconds
}