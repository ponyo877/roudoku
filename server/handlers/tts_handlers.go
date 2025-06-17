package handlers

import (
	"context"
	"encoding/base64"
	"net/http"
	"sync"

	texttospeech "cloud.google.com/go/texttospeech/apiv1"
	"cloud.google.com/go/texttospeech/apiv1/texttospeechpb"

	"github.com/ponyo877/roudoku/server/handlers/utils"
)

// TTSHandler handles text-to-speech requests
type TTSHandler struct {
	client *texttospeech.Client
	mu     sync.RWMutex
}

// NewTTSHandler creates a new TTS handler with connection pooling
func NewTTSHandler() *TTSHandler {
	return &TTSHandler{}
}

// getClient returns a TTS client, creating one if necessary (thread-safe)
func (h *TTSHandler) getClient(ctx context.Context) (*texttospeech.Client, error) {
	h.mu.RLock()
	if h.client != nil {
		client := h.client
		h.mu.RUnlock()
		return client, nil
	}
	h.mu.RUnlock()

	h.mu.Lock()
	defer h.mu.Unlock()

	// Double-check pattern
	if h.client != nil {
		return h.client, nil
	}

	client, err := texttospeech.NewClient(ctx)
	if err != nil {
		return nil, err
	}

	h.client = client
	return client, nil
}

// TTSRequest represents the request payload for text-to-speech
type TTSRequest struct {
	Text     string  `json:"text"`
	Language string  `json:"language,omitempty"`
	Voice    string  `json:"voice,omitempty"`
	Speed    float64 `json:"speed,omitempty"`
}

// TTSResponse represents the response from text-to-speech
type TTSResponse struct {
	AudioContent string `json:"audio_content"` // Base64 encoded audio
	AudioFormat  string `json:"audio_format"`
}

// SynthesizeSpeech handles text-to-speech synthesis using Google Cloud TTS
func (h *TTSHandler) SynthesizeSpeech(w http.ResponseWriter, r *http.Request) {
	var req TTSRequest
	if err := utils.DecodeJSONBody(r, &req); err != nil {
		utils.WriteJSONError(w, "Invalid request format", utils.CodeInvalidFormat, http.StatusBadRequest)
		return
	}

	// Validate required fields
	if req.Text == "" {
		utils.WriteJSONError(w, "Text field is required", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	// Set defaults
	if req.Language == "" {
		req.Language = "ja-JP"
	}
	if req.Voice == "" {
		req.Voice = "ja-JP-Wavenet-A"
	}
	if req.Speed == 0 {
		req.Speed = 1.0
	}

	// Get TTS client
	client, err := h.getClient(r.Context())
	if err != nil {
		utils.WriteJSONError(w, "Failed to create TTS client", utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	// Build the voice selection parameters
	voice := &texttospeechpb.VoiceSelectionParams{
		LanguageCode: req.Language,
		Name:         req.Voice,
	}

	// Build the audio configuration
	audioConfig := &texttospeechpb.AudioConfig{
		AudioEncoding:   texttospeechpb.AudioEncoding_MP3,
		SpeakingRate:    req.Speed,
		Pitch:           0.0,
		VolumeGainDb:    0.0,
		SampleRateHertz: 24000,
	}

	// Build the TTS request
	ttsReq := &texttospeechpb.SynthesizeSpeechRequest{
		Input: &texttospeechpb.SynthesisInput{
			InputSource: &texttospeechpb.SynthesisInput_Text{
				Text: req.Text,
			},
		},
		Voice:       voice,
		AudioConfig: audioConfig,
	}

	// Perform the text-to-speech request
	resp, err := client.SynthesizeSpeech(r.Context(), ttsReq)
	if err != nil {
		utils.WriteJSONError(w, "Failed to synthesize speech", utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	// Encode audio content as base64
	audioBase64 := base64.StdEncoding.EncodeToString(resp.AudioContent)

	// Return the audio content as JSON
	response := TTSResponse{
		AudioContent: audioBase64,
		AudioFormat:  "mp3",
	}

	utils.WriteJSONSuccess(w, response, "Speech synthesized successfully", http.StatusOK)
}

// Voice represents a TTS voice option
type Voice struct {
	Name         string  `json:"name"`
	LanguageCode string  `json:"language_code"`
	Gender       string  `json:"gender"`
	NaturalRate  float64 `json:"natural_sample_rate_hertz"`
}

// GetAvailableVoices returns list of available voices for TTS
func (h *TTSHandler) GetAvailableVoices(w http.ResponseWriter, r *http.Request) {
	// Get TTS client
	client, err := h.getClient(r.Context())
	if err != nil {
		utils.WriteJSONError(w, "Failed to create TTS client", utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	// Request list of voices
	voicesReq := &texttospeechpb.ListVoicesRequest{
		LanguageCode: "ja-JP", // Focus on Japanese voices
	}

	voicesResp, err := client.ListVoices(r.Context(), voicesReq)
	if err != nil {
		utils.WriteJSONError(w, "Failed to list voices", utils.CodeInternal, http.StatusInternalServerError)
		return
	}

	// Format voices for response
	var voices []Voice
	for _, voice := range voicesResp.Voices {
		genderStr := "UNKNOWN"
		switch voice.SsmlGender {
		case texttospeechpb.SsmlVoiceGender_MALE:
			genderStr = "MALE"
		case texttospeechpb.SsmlVoiceGender_FEMALE:
			genderStr = "FEMALE"
		case texttospeechpb.SsmlVoiceGender_NEUTRAL:
			genderStr = "NEUTRAL"
		}

		for _, langCode := range voice.LanguageCodes {
			voices = append(voices, Voice{
				Name:         voice.Name,
				LanguageCode: langCode,
				Gender:       genderStr,
				NaturalRate:  float64(voice.NaturalSampleRateHertz),
			})
		}
	}

	response := map[string]interface{}{
		"voices": voices,
		"total":  len(voices),
	}

	utils.WriteJSONSuccess(w, response, "", http.StatusOK)
}

// Close closes the TTS client connection
func (h *TTSHandler) Close() error {
	h.mu.Lock()
	defer h.mu.Unlock()

	if h.client != nil {
		err := h.client.Close()
		h.client = nil
		return err
	}
	return nil
}