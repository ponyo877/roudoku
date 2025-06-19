package handlers

import (
	"net/http"
	"strconv"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// NotificationHandler handles notification-related HTTP requests
type NotificationHandler struct {
	notificationService services.NotificationService
	logger              *logger.Logger
}

// NewNotificationHandler creates a new notification handler
func NewNotificationHandler(notificationService services.NotificationService, logger *logger.Logger) *NotificationHandler {
	return &NotificationHandler{
		notificationService: notificationService,
		logger:              logger,
	}
}

// RegisterFCMToken handles FCM token registration
func (h *NotificationHandler) RegisterFCMToken(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.FCMTokenRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	response, err := h.notificationService.RegisterFCMToken(r.Context(), userUUID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to register FCM token", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetUserTokens handles getting user's FCM tokens
func (h *NotificationHandler) GetUserTokens(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	tokens, err := h.notificationService.GetUserTokens(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get user tokens", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"tokens": tokens,
	})
}

// DeactivateToken handles FCM token deactivation
func (h *NotificationHandler) DeactivateToken(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	tokenIDStr := vars["token_id"]

	tokenID, err := uuid.Parse(tokenIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid token ID", err))
		return
	}

	err = h.notificationService.DeactivateToken(r.Context(), tokenID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to deactivate token", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}

// GetNotificationPreferences handles getting user's notification preferences
func (h *NotificationHandler) GetNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	preferences, err := h.notificationService.GetNotificationPreferences(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get notification preferences", err))
		return
	}

	utils.WriteSuccess(w, preferences)
}

// UpdateNotificationPreferences handles updating user's notification preferences
func (h *NotificationHandler) UpdateNotificationPreferences(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.UpdateNotificationPreferencesRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	preferences, err := h.notificationService.UpdateNotificationPreferences(r.Context(), userUUID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to update notification preferences", err))
		return
	}

	utils.WriteSuccess(w, preferences)
}

// SendNotification handles sending notifications (admin only)
func (h *NotificationHandler) SendNotification(w http.ResponseWriter, r *http.Request) {
	var req dto.SendNotificationRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	response, err := h.notificationService.SendNotification(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to send notification", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetNotificationHistory handles getting user's notification history
func (h *NotificationHandler) GetNotificationHistory(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	// Parse pagination parameters
	pageStr := r.URL.Query().Get("page")
	perPageStr := r.URL.Query().Get("per_page")

	page := 1
	perPage := 20

	if pageStr != "" {
		if p, err := strconv.Atoi(pageStr); err == nil && p > 0 {
			page = p
		}
	}

	if perPageStr != "" {
		if pp, err := strconv.Atoi(perPageStr); err == nil && pp > 0 && pp <= 100 {
			perPage = pp
		}
	}

	history, err := h.notificationService.GetNotificationHistory(r.Context(), userUUID, page, perPage)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get notification history", err))
		return
	}

	utils.WriteSuccess(w, history)
}

// GetUnreadNotifications handles getting user's unread notifications
func (h *NotificationHandler) GetUnreadNotifications(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	notifications, err := h.notificationService.GetUnreadNotifications(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get unread notifications", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"notifications": notifications,
	})
}

// MarkNotificationAsRead handles marking a notification as read
func (h *NotificationHandler) MarkNotificationAsRead(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	notificationIDStr := vars["notification_id"]

	notificationID, err := uuid.Parse(notificationIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid notification ID", err))
		return
	}

	err = h.notificationService.MarkNotificationAsRead(r.Context(), notificationID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to mark notification as read", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}

// MarkAllNotificationsAsRead handles marking all notifications as read
func (h *NotificationHandler) MarkAllNotificationsAsRead(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	err = h.notificationService.MarkAllNotificationsAsRead(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to mark all notifications as read", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"success": true,
	})
}

// GetUnreadCount handles getting user's unread notification count
func (h *NotificationHandler) GetUnreadCount(w http.ResponseWriter, r *http.Request) {
	userID, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userUUID, err := uuid.Parse(userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	count, err := h.notificationService.GetUnreadCount(r.Context(), userUUID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get unread count", err))
		return
	}

	utils.WriteSuccess(w, map[string]interface{}{
		"unread_count": count,
	})
}

// ScheduleNotification handles scheduling notifications
func (h *NotificationHandler) ScheduleNotification(w http.ResponseWriter, r *http.Request) {
	var req dto.ScheduleNotificationRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	response, err := h.notificationService.ScheduleNotification(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to schedule notification", err))
		return
	}

	utils.WriteSuccess(w, response)
}