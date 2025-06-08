package handlers

import (
	"encoding/json"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/services"
)

// SessionHandler handles reading session-related HTTP requests
type SessionHandler struct {
	sessionService services.SessionService
}

// NewSessionHandler creates a new session handler
func NewSessionHandler(sessionService services.SessionService) *SessionHandler {
	return &SessionHandler{
		sessionService: sessionService,
	}
}

// CreateReadingSession handles POST /users/{user_id}/sessions
func (h *SessionHandler) CreateReadingSession(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr, ok := vars["user_id"]
	if !ok {
		http.Error(w, "Missing user ID", http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	var req dto.CreateReadingSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	session, err := h.sessionService.CreateReadingSession(r.Context(), userID, &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(session)
}

// GetReadingSession handles GET /users/{user_id}/sessions/{session_id}
func (h *SessionHandler) GetReadingSession(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sessionIDStr, ok := vars["session_id"]
	if !ok {
		http.Error(w, "Missing session ID", http.StatusBadRequest)
		return
	}

	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		http.Error(w, "Invalid session ID", http.StatusBadRequest)
		return
	}

	session, err := h.sessionService.GetReadingSession(r.Context(), sessionID)
	if err != nil {
		http.Error(w, err.Error(), http.StatusNotFound)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(session)
}

// UpdateReadingSession handles PUT /users/{user_id}/sessions/{session_id}
func (h *SessionHandler) UpdateReadingSession(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	sessionIDStr, ok := vars["session_id"]
	if !ok {
		http.Error(w, "Missing session ID", http.StatusBadRequest)
		return
	}

	sessionID, err := uuid.Parse(sessionIDStr)
	if err != nil {
		http.Error(w, "Invalid session ID", http.StatusBadRequest)
		return
	}

	var req dto.UpdateReadingSessionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		http.Error(w, "Invalid request body", http.StatusBadRequest)
		return
	}

	session, err := h.sessionService.UpdateReadingSession(r.Context(), sessionID, &req)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(session)
}

// GetUserReadingSessions handles GET /users/{user_id}/sessions
func (h *SessionHandler) GetUserReadingSessions(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	userIDStr, ok := vars["user_id"]
	if !ok {
		http.Error(w, "Missing user ID", http.StatusBadRequest)
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		http.Error(w, "Invalid user ID", http.StatusBadRequest)
		return
	}

	limit := 50
	if limitStr := r.URL.Query().Get("limit"); limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}

	sessions, err := h.sessionService.GetUserReadingSessions(r.Context(), userID, limit)
	if err != nil {
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(sessions)
}