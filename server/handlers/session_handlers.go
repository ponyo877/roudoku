package handlers

import (
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// SessionHandler handles reading session-related HTTP requests
type SessionHandler struct {
	*BaseHandler
	sessionService services.SessionService
}

// NewSessionHandler creates a new session handler
func NewSessionHandler(sessionService services.SessionService, log *logger.Logger) *SessionHandler {
	return &SessionHandler{
		BaseHandler:    NewBaseHandler(log),
		sessionService: sessionService,
	}
}

// CreateReadingSession handles POST /users/{user_id}/sessions
func (h *SessionHandler) CreateReadingSession(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	var req dto.CreateReadingSessionRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	session, err := h.sessionService.CreateReadingSession(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, session)
}

// GetUserReadingSessions handles GET /users/{user_id}/sessions
func (h *SessionHandler) GetUserReadingSessions(w http.ResponseWriter, r *http.Request) {
	userID, err := utils.ParseUUIDParam(r, "user_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	limit := utils.ParseQueryInt(r, "limit", 20)

	sessions, err := h.sessionService.GetUserReadingSessions(r.Context(), userID, limit)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, sessions)
}

// GetReadingSession handles GET /users/{user_id}/sessions/{session_id}
func (h *SessionHandler) GetReadingSession(w http.ResponseWriter, r *http.Request) {
	sessionID, err := utils.ParseUUIDParam(r, "session_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	session, err := h.sessionService.GetReadingSession(r.Context(), sessionID)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, session)
}

// UpdateReadingSession handles PUT /users/{user_id}/sessions/{session_id}
func (h *SessionHandler) UpdateReadingSession(w http.ResponseWriter, r *http.Request) {
	sessionID, err := utils.ParseUUIDParam(r, "session_id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	var req dto.UpdateReadingSessionRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	session, err := h.sessionService.UpdateReadingSession(r.Context(), sessionID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, session)
}