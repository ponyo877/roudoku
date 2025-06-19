package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/google/uuid"
	"github.com/gorilla/mux"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/middleware"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

type SubscriptionHandler struct {
	subscriptionService services.SubscriptionService
	logger              *logger.Logger
}

func NewSubscriptionHandler(subscriptionService services.SubscriptionService, logger *logger.Logger) *SubscriptionHandler {
	return &SubscriptionHandler{
		subscriptionService: subscriptionService,
		logger:              logger,
	}
}

// GetPlans handles GET /subscriptions/plans
func (h *SubscriptionHandler) GetPlans(w http.ResponseWriter, r *http.Request) {
	query := r.URL.Query()
	activeOnly := query.Get("active") == "true"

	var response *dto.SubscriptionPlansResponse
	var err error

	if activeOnly {
		response, err = h.subscriptionService.GetActivePlans(r.Context())
	} else {
		response, err = h.subscriptionService.GetAllPlans(r.Context())
	}

	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get subscription plans", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetPlan handles GET /subscriptions/plans/{planId}
func (h *SubscriptionHandler) GetPlan(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	planIDStr, exists := vars["planId"]
	if !exists {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Plan ID is required", nil))
		return
	}

	planID, err := uuid.Parse(planIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid plan ID", err))
		return
	}

	response, err := h.subscriptionService.GetPlanByID(r.Context(), planID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get subscription plan", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetUserSubscription handles GET /subscriptions/me
func (h *SubscriptionHandler) GetUserSubscription(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	response, err := h.subscriptionService.GetUserSubscription(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get user subscription", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// CreateSubscription handles POST /subscriptions
func (h *SubscriptionHandler) CreateSubscription(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.CreateSubscriptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid request body", err))
		return
	}

	response, err := h.subscriptionService.CreateSubscription(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to create subscription", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// UpdateSubscription handles PUT /subscriptions/me
func (h *SubscriptionHandler) UpdateSubscription(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.UpdateSubscriptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid request body", err))
		return
	}

	response, err := h.subscriptionService.UpdateSubscription(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to update subscription", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// CancelSubscription handles DELETE /subscriptions/me
func (h *SubscriptionHandler) CancelSubscription(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	var req dto.CancelSubscriptionRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid request body", err))
		return
	}

	response, err := h.subscriptionService.CancelSubscription(r.Context(), userID, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to cancel subscription", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// GetUsageStats handles GET /subscriptions/usage
func (h *SubscriptionHandler) GetUsageStats(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	response, err := h.subscriptionService.GetUsageStats(r.Context(), userID)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to get usage stats", err))
		return
	}

	utils.WriteSuccess(w, response)
}

// CheckFeatureAccess handles GET /subscriptions/features/{feature}/access
func (h *SubscriptionHandler) CheckFeatureAccess(w http.ResponseWriter, r *http.Request) {
	userIDStr, ok := middleware.GetUserIDFromContext(r.Context())
	if !ok {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("User not authenticated", nil))
		return
	}

	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid user ID", err))
		return
	}

	vars := mux.Vars(r)
	feature, exists := vars["feature"]
	if !exists {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Feature is required", nil))
		return
	}

	response, err := h.subscriptionService.CheckFeatureAccess(r.Context(), userID, feature)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.InternalServerError("Failed to check feature access", err))
		return
	}

	utils.WriteSuccess(w, response)
}