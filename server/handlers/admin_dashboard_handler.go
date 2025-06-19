package handlers

import (
	"encoding/json"
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

type AdminDashboardHandler struct {
	*BaseHandler
	adminDashboardService services.AdminDashboardService
}

func NewAdminDashboardHandler(
	adminDashboardService services.AdminDashboardService,
	logger *logger.Logger,
) *AdminDashboardHandler {
	return &AdminDashboardHandler{
		BaseHandler:           NewBaseHandler(logger),
		adminDashboardService: adminDashboardService,
	}
}

// GetSystemOverview handles GET /api/v1/admin/dashboard/overview
func (h *AdminDashboardHandler) GetSystemOverview(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	overview, err := h.adminDashboardService.GetSystemOverview(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, overview)
}

// GetRealtimeMetrics handles GET /api/v1/admin/dashboard/metrics/realtime
func (h *AdminDashboardHandler) GetRealtimeMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	metrics, err := h.adminDashboardService.GetRealtimeMetrics(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, metrics)
}

// GetUserStatistics handles POST /api/v1/admin/dashboard/users/statistics
func (h *AdminDashboardHandler) GetUserStatistics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req dto.UserStatisticsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	statistics, err := h.adminDashboardService.GetUserStatistics(ctx, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, statistics)
}

// GetUserEngagementMetrics handles GET /api/v1/admin/dashboard/users/engagement
func (h *AdminDashboardHandler) GetUserEngagementMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	timeframe := r.URL.Query().Get("timeframe")
	if timeframe == "" {
		timeframe = "7d"
	}

	engagement, err := h.adminDashboardService.GetUserEngagementMetrics(ctx, timeframe)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, engagement)
}

// GetBookStatistics handles GET /api/v1/admin/dashboard/books/statistics
func (h *AdminDashboardHandler) GetBookStatistics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	statistics, err := h.adminDashboardService.GetBookStatistics(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, statistics)
}

// GetContentPerformance handles POST /api/v1/admin/dashboard/content/performance
func (h *AdminDashboardHandler) GetContentPerformance(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req dto.ContentPerformanceRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	performance, err := h.adminDashboardService.GetContentPerformance(ctx, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, performance)
}

// GetRecommendationEffectiveness handles GET /api/v1/admin/dashboard/recommendations/effectiveness
func (h *AdminDashboardHandler) GetRecommendationEffectiveness(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	effectiveness, err := h.adminDashboardService.GetRecommendationEffectiveness(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, effectiveness)
}

// GetRevenueAnalytics handles POST /api/v1/admin/dashboard/revenue/analytics
func (h *AdminDashboardHandler) GetRevenueAnalytics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	var req dto.RevenueAnalyticsRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	analytics, err := h.adminDashboardService.GetRevenueAnalytics(ctx, &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, analytics)
}

// GetSubscriptionMetrics handles GET /api/v1/admin/dashboard/subscriptions/metrics
func (h *AdminDashboardHandler) GetSubscriptionMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	metrics, err := h.adminDashboardService.GetSubscriptionMetrics(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, metrics)
}

// GetChurnAnalysis handles GET /api/v1/admin/dashboard/subscriptions/churn
func (h *AdminDashboardHandler) GetChurnAnalysis(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	churn, err := h.adminDashboardService.GetChurnAnalysis(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, churn)
}

// GetSystemPerformance handles GET /api/v1/admin/dashboard/system/performance
func (h *AdminDashboardHandler) GetSystemPerformance(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	performance, err := h.adminDashboardService.GetSystemPerformance(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, performance)
}

// GetAPIMetrics handles GET /api/v1/admin/dashboard/api/metrics
func (h *AdminDashboardHandler) GetAPIMetrics(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()
	timeframe := r.URL.Query().Get("timeframe")
	if timeframe == "" {
		timeframe = "24h"
	}

	metrics, err := h.adminDashboardService.GetAPIMetrics(ctx, timeframe)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, metrics)
}

// GetErrorAnalysis handles GET /api/v1/admin/dashboard/errors/analysis
func (h *AdminDashboardHandler) GetErrorAnalysis(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	analysis, err := h.adminDashboardService.GetErrorAnalysis(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, analysis)
}

// GetModelPerformance handles GET /api/v1/admin/dashboard/ml/performance
func (h *AdminDashboardHandler) GetModelPerformance(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	performance, err := h.adminDashboardService.GetModelPerformance(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, performance)
}

// GetRecommendationQuality handles GET /api/v1/admin/dashboard/recommendations/quality
func (h *AdminDashboardHandler) GetRecommendationQuality(w http.ResponseWriter, r *http.Request) {
	ctx := r.Context()

	quality, err := h.adminDashboardService.GetRecommendationQuality(ctx)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, quality)
}