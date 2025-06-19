package handlers

import (
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// TTSHandler handles text-to-speech related HTTP requests
type TTSHandler struct {
	*BaseHandler
	ttsService services.TTSService
}

// NewTTSHandler creates a new TTS handler
func NewTTSHandler(ttsService services.TTSService, log *logger.Logger) *TTSHandler {
	return &TTSHandler{
		BaseHandler: NewBaseHandler(log),
		ttsService:  ttsService,
	}
}

// SynthesizeText handles POST /tts/synthesize
func (h *TTSHandler) SynthesizeText(w http.ResponseWriter, r *http.Request) {
	var req dto.TTSSynthesizeRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	// Set default values if not provided
	if req.Speed == 0 {
		req.Speed = 1.0
	}
	if req.Pitch == 0 {
		req.Pitch = 0.0
	}
	if req.VolumeGain == 0 {
		req.VolumeGain = 0.0
	}

	response, err := h.ttsService.SynthesizeText(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, response)
}

// GetVoices handles GET /tts/voices
func (h *TTSHandler) GetVoices(w http.ResponseWriter, r *http.Request) {
	languageCode := r.URL.Query().Get("language")
	if languageCode == "" {
		languageCode = "ja-JP" // Default to Japanese
	}

	response, err := h.ttsService.GetAvailableVoices(r.Context(), languageCode)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, response)
}

// PreviewVoice handles POST /tts/preview
func (h *TTSHandler) PreviewVoice(w http.ResponseWriter, r *http.Request) {
	var req dto.TTSPreviewRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	// Set default values if not provided
	if req.Speed == 0 {
		req.Speed = 1.0
	}
	if req.Pitch == 0 {
		req.Pitch = 0.0
	}
	if req.VolumeGain == 0 {
		req.VolumeGain = 0.0
	}

	response, err := h.ttsService.PreviewVoice(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, response)
}