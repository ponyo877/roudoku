package services

import (
	"context"
	"fmt"
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// SubscriptionService defines the interface for subscription operations
type SubscriptionService interface {
	// Subscription Plans
	GetAllPlans(ctx context.Context) (*dto.SubscriptionPlansResponse, error)
	GetActivePlans(ctx context.Context) (*dto.SubscriptionPlansResponse, error)
	GetPlanByID(ctx context.Context, planID uuid.UUID) (*dto.SubscriptionPlanResponse, error)
	
	// User Subscriptions
	GetUserSubscription(ctx context.Context, userID uuid.UUID) (*dto.SubscriptionResponse, error)
	CreateSubscription(ctx context.Context, userID uuid.UUID, req *dto.CreateSubscriptionRequest) (*dto.SubscriptionResponse, error)
	UpdateSubscription(ctx context.Context, userID uuid.UUID, req *dto.UpdateSubscriptionRequest) (*dto.SubscriptionResponse, error)
	CancelSubscription(ctx context.Context, userID uuid.UUID, req *dto.CancelSubscriptionRequest) (*dto.SubscriptionResponse, error)
	
	// Usage Tracking
	GetUsageStats(ctx context.Context, userID uuid.UUID) (*dto.UsageStatsResponse, error)
	TrackFeatureUsage(ctx context.Context, userID uuid.UUID, featureType string, count int, value float64) error
	CheckFeatureAccess(ctx context.Context, userID uuid.UUID, feature string) (*dto.FeatureAccessResponse, error)
	
	// Premium Features
	CanAccessPremiumBook(ctx context.Context, userID uuid.UUID, bookID int64) (bool, error)
	CanUseTTS(ctx context.Context, userID uuid.UUID, requestedMinutes int) (bool, error)
	CanDownloadOffline(ctx context.Context, userID uuid.UUID) (bool, error)
}

type subscriptionService struct {
	*BaseService
	planRepo         repository.SubscriptionPlanRepository
	subscriptionRepo repository.UserSubscriptionRepository
	usageRepo        repository.UsageTrackingRepository
}

// NewSubscriptionService creates a new subscription service
func NewSubscriptionService(
	planRepo repository.SubscriptionPlanRepository,
	subscriptionRepo repository.UserSubscriptionRepository,
	usageRepo repository.UsageTrackingRepository,
	logger *logger.Logger,
) SubscriptionService {
	return &subscriptionService{
		BaseService:      NewBaseService(logger),
		planRepo:         planRepo,
		subscriptionRepo: subscriptionRepo,
		usageRepo:        usageRepo,
	}
}

// GetAllPlans gets all subscription plans
func (s *subscriptionService) GetAllPlans(ctx context.Context) (*dto.SubscriptionPlansResponse, error) {
	s.logger.Info("Getting all subscription plans")

	plans, err := s.planRepo.GetAll(ctx)
	if err != nil {
		s.logger.Error("Failed to get subscription plans")
		return nil, fmt.Errorf("failed to get subscription plans: %w", err)
	}

	return &dto.SubscriptionPlansResponse{
		Plans: s.convertToSubscriptionPlanResponses(plans),
	}, nil
}

// GetActivePlans gets active subscription plans
func (s *subscriptionService) GetActivePlans(ctx context.Context) (*dto.SubscriptionPlansResponse, error) {
	s.logger.Info("Getting active subscription plans")

	plans, err := s.planRepo.GetActive(ctx)
	if err != nil {
		s.logger.Error("Failed to get active subscription plans")
		return nil, fmt.Errorf("failed to get active subscription plans: %w", err)
	}

	return &dto.SubscriptionPlansResponse{
		Plans: s.convertToSubscriptionPlanResponses(plans),
	}, nil
}

// GetPlanByID gets a subscription plan by ID
func (s *subscriptionService) GetPlanByID(ctx context.Context, planID uuid.UUID) (*dto.SubscriptionPlanResponse, error) {
	s.logger.Info("Getting subscription plan by ID")

	plan, err := s.planRepo.GetByID(ctx, planID)
	if err != nil {
		s.logger.Error("Failed to get subscription plan")
		return nil, fmt.Errorf("failed to get subscription plan: %w", err)
	}

	if plan == nil {
		return nil, fmt.Errorf("subscription plan not found")
	}

	return s.convertToSubscriptionPlanResponse(plan), nil
}

// GetUserSubscription gets user's current subscription
func (s *subscriptionService) GetUserSubscription(ctx context.Context, userID uuid.UUID) (*dto.SubscriptionResponse, error) {
	s.logger.Info("Getting user subscription")

	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to get user subscription")
		return nil, fmt.Errorf("failed to get user subscription: %w", err)
	}

	if subscription == nil {
		// Return free plan subscription
		return s.createFreeSubscriptionResponse(userID), nil
	}

	return s.convertToSubscriptionResponse(subscription), nil
}

// CreateSubscription creates a new subscription for user
func (s *subscriptionService) CreateSubscription(ctx context.Context, userID uuid.UUID, req *dto.CreateSubscriptionRequest) (*dto.SubscriptionResponse, error) {
	s.logger.Info("Creating subscription for user")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Get the plan
	plan, err := s.planRepo.GetByID(ctx, req.PlanID)
	if err != nil {
		return nil, fmt.Errorf("failed to get subscription plan: %w", err)
	}

	if plan == nil || !plan.IsActive {
		return nil, fmt.Errorf("subscription plan not found or inactive")
	}

	// Check if user already has an active subscription
	existingSubscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing subscription: %w", err)
	}

	if existingSubscription != nil && existingSubscription.IsActive() {
		return nil, fmt.Errorf("user already has an active subscription")
	}

	// Calculate pricing
	var price float64
	switch req.BillingCycle {
	case "monthly":
		price = plan.PriceMonthly
	case "yearly":
		if plan.PriceYearly != nil {
			price = *plan.PriceYearly
		} else {
			price = plan.PriceMonthly * 12 * 0.8 // 20% discount if no yearly price set
		}
	default:
		return nil, fmt.Errorf("invalid billing cycle")
	}

	// Create subscription
	now := time.Now()
	var periodEnd time.Time
	if req.BillingCycle == "monthly" {
		periodEnd = now.AddDate(0, 1, 0)
	} else {
		periodEnd = now.AddDate(1, 0, 0)
	}

	subscription := &domain.UserSubscription{
		ID:                 uuid.New(),
		UserID:             userID,
		PlanID:             req.PlanID,
		Status:             "active",
		BillingCycle:       req.BillingCycle,
		PricePaid:          price,
		Currency:           "USD",
		StartedAt:          now,
		CurrentPeriodStart: now,
		CurrentPeriodEnd:   periodEnd,
		PaymentMethodID:    &req.PaymentMethodID,
		AutoRenew:          req.AutoRenew,
		CreatedAt:          now,
		UpdatedAt:          now,
	}

	// Set trial end for new users (7 days trial)
	trialEnd := now.AddDate(0, 0, 7)
	subscription.TrialEnd = &trialEnd

	err = s.subscriptionRepo.Create(ctx, subscription)
	if err != nil {
		s.logger.Error("Failed to create subscription")
		return nil, fmt.Errorf("failed to create subscription: %w", err)
	}

	subscription.Plan = plan
	return s.convertToSubscriptionResponse(subscription), nil
}

// GetUsageStats gets user's usage statistics
func (s *subscriptionService) GetUsageStats(ctx context.Context, userID uuid.UUID) (*dto.UsageStatsResponse, error) {
	s.logger.Info("Getting user usage stats")

	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user subscription: %w", err)
	}

	var periodStart, periodEnd time.Time
	var plan *domain.SubscriptionPlan

	if subscription != nil && subscription.IsActive() {
		periodStart = subscription.CurrentPeriodStart
		periodEnd = subscription.CurrentPeriodEnd
		plan = subscription.Plan
	} else {
		// Free plan - use current month
		now := time.Now()
		periodStart = time.Date(now.Year(), now.Month(), 1, 0, 0, 0, 0, now.Location())
		periodEnd = periodStart.AddDate(0, 1, 0).Add(-time.Second)
		// Create default free plan limits
		plan = &domain.SubscriptionPlan{
			MaxTTSMinutesPerDay:  30,
			MaxPremiumBooks:      0,
			MaxOfflineDownloads:  5,
		}
	}

	// Get usage data
	usageData, err := s.usageRepo.GetByUserIDAndPeriod(ctx, userID, periodStart, periodEnd)
	if err != nil {
		return nil, fmt.Errorf("failed to get usage data: %w", err)
	}

	// Calculate totals
	var ttsMinutes, premiumBooks, offlineDownloads int
	usageBreakdown := make(map[string]dto.UsageBreakdown)

	for _, usage := range usageData {
		switch usage.FeatureType {
		case "tts_minutes":
			ttsMinutes += int(usage.UsageValue)
		case "premium_book_access":
			premiumBooks += usage.UsageCount
		case "offline_download":
			offlineDownloads += usage.UsageCount
		}

		dateStr := usage.UsageDate.Format("2006-01-02")
		breakdown := usageBreakdown[dateStr]
		breakdown.Date = dateStr
		breakdown.Count += usage.UsageCount
		breakdown.Value += usage.UsageValue
		usageBreakdown[dateStr] = breakdown
	}

	return &dto.UsageStatsResponse{
		CurrentPeriodStart:    periodStart,
		CurrentPeriodEnd:      periodEnd,
		TTSMinutesUsed:       ttsMinutes,
		TTSMinutesLimit:      plan.MaxTTSMinutesPerDay,
		PremiumBooksRead:     premiumBooks,
		PremiumBooksLimit:    plan.MaxPremiumBooks,
		OfflineDownloads:     offlineDownloads,
		OfflineDownloadLimit: plan.MaxOfflineDownloads,
		UsageBreakdown:       usageBreakdown,
	}, nil
}

// TrackFeatureUsage tracks usage of a premium feature
func (s *subscriptionService) TrackFeatureUsage(ctx context.Context, userID uuid.UUID, featureType string, count int, value float64) error {
	s.logger.Info("Tracking feature usage")

	usage := &domain.UsageTracking{
		ID:          uuid.New(),
		UserID:      userID,
		FeatureType: featureType,
		UsageDate:   time.Now(),
		UsageCount:  count,
		UsageValue:  value,
		CreatedAt:   time.Now(),
		UpdatedAt:   time.Now(),
	}

	err := s.usageRepo.Create(ctx, usage)
	if err != nil {
		s.logger.Error("Failed to track feature usage")
		return fmt.Errorf("failed to track feature usage: %w", err)
	}

	return nil
}

// CheckFeatureAccess checks if user can access a premium feature
func (s *subscriptionService) CheckFeatureAccess(ctx context.Context, userID uuid.UUID, feature string) (*dto.FeatureAccessResponse, error) {
	s.logger.Info("Checking feature access")

	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user subscription: %w", err)
	}

	response := &dto.FeatureAccessResponse{
		CanAccess: false,
		Reason:    "no_subscription",
	}

	if subscription == nil || !subscription.IsActive() {
		return response, nil
	}

	if subscription.CanAccessFeature(feature) {
		response.CanAccess = true
		response.Reason = "subscription_active"
		return response, nil
	}

	response.Reason = "feature_not_included"
	return response, nil
}

// Premium feature checks

func (s *subscriptionService) CanAccessPremiumBook(ctx context.Context, userID uuid.UUID, bookID int64) (bool, error) {
	access, err := s.CheckFeatureAccess(ctx, userID, "premium_books")
	if err != nil {
		return false, err
	}
	return access.CanAccess, nil
}

func (s *subscriptionService) CanUseTTS(ctx context.Context, userID uuid.UUID, requestedMinutes int) (bool, error) {
	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return false, err
	}

	var dailyLimit int
	if subscription == nil || !subscription.IsActive() {
		dailyLimit = 30 // Free plan limit
	} else if subscription.Plan.MaxTTSMinutesPerDay == -1 {
		return true, nil // Unlimited
	} else {
		dailyLimit = subscription.Plan.MaxTTSMinutesPerDay
	}

	// Check today's usage
	today := time.Now()
	todayUsage, err := s.usageRepo.GetUsageForFeature(ctx, userID, "tts_minutes", today)
	if err != nil {
		return false, err
	}

	currentUsage := 0
	if todayUsage != nil {
		currentUsage = int(todayUsage.UsageValue)
	}

	return currentUsage+requestedMinutes <= dailyLimit, nil
}

func (s *subscriptionService) CanDownloadOffline(ctx context.Context, userID uuid.UUID) (bool, error) {
	access, err := s.CheckFeatureAccess(ctx, userID, "offline_downloads")
	if err != nil {
		return false, err
	}
	return access.CanAccess, nil
}

// Helper methods

func (s *subscriptionService) convertToSubscriptionPlanResponses(plans []*domain.SubscriptionPlan) []dto.SubscriptionPlanResponse {
	var result []dto.SubscriptionPlanResponse
	for _, plan := range plans {
		result = append(result, *s.convertToSubscriptionPlanResponse(plan))
	}
	return result
}

func (s *subscriptionService) convertToSubscriptionPlanResponse(plan *domain.SubscriptionPlan) *dto.SubscriptionPlanResponse {
	features := []string{}
	if plan.Features != nil {
		for key := range plan.Features {
			features = append(features, key)
		}
	}

	return &dto.SubscriptionPlanResponse{
		ID:                      plan.ID,
		Name:                    plan.Name,
		Description:             plan.Description,
		PriceMonthly:            plan.PriceMonthly,
		PriceYearly:             plan.PriceYearly,
		Features:                features,
		MaxPremiumBooks:         plan.MaxPremiumBooks,
		MaxTTSMinutesPerDay:     plan.MaxTTSMinutesPerDay,
		MaxOfflineDownloads:     plan.MaxOfflineDownloads,
		HasAdvancedAnalytics:    plan.HasAdvancedAnalytics,
		HasAIRecommendations:    plan.HasAIRecommendations,
		HasPrioritySupport:      plan.HasPrioritySupport,
		IsActive:                plan.IsActive,
		SortOrder:               plan.SortOrder,
	}
}

func (s *subscriptionService) convertToSubscriptionResponse(subscription *domain.UserSubscription) *dto.SubscriptionResponse {
	var planResponse dto.SubscriptionPlanResponse
	if subscription.Plan != nil {
		planResponse = *s.convertToSubscriptionPlanResponse(subscription.Plan)
	}

	var nextBillingDate *time.Time
	if subscription.IsActive() && subscription.AutoRenew {
		nextBillingDate = &subscription.CurrentPeriodEnd
	}

	return &dto.SubscriptionResponse{
		ID:                 subscription.ID,
		UserID:             subscription.UserID,
		Plan:               planResponse,
		Status:             subscription.Status,
		BillingCycle:       subscription.BillingCycle,
		PricePaid:          subscription.PricePaid,
		Currency:           subscription.Currency,
		StartedAt:          subscription.StartedAt,
		CurrentPeriodStart: subscription.CurrentPeriodStart,
		CurrentPeriodEnd:   subscription.CurrentPeriodEnd,
		TrialEnd:           subscription.TrialEnd,
		CanceledAt:         subscription.CanceledAt,
		CancelReason:       subscription.CancelReason,
		AutoRenew:          subscription.AutoRenew,
		DaysRemaining:      subscription.DaysRemaining(),
		IsTrialActive:      subscription.IsTrialActive(),
		NextBillingDate:    nextBillingDate,
	}
}

func (s *subscriptionService) createFreeSubscriptionResponse(userID uuid.UUID) *dto.SubscriptionResponse {
	now := time.Now()
	return &dto.SubscriptionResponse{
		ID:       uuid.New(),
		UserID:   userID,
		Plan: dto.SubscriptionPlanResponse{
			Name:                    "Free",
			Description:             "Basic reading experience",
			PriceMonthly:            0,
			MaxPremiumBooks:         0,
			MaxTTSMinutesPerDay:     30,
			MaxOfflineDownloads:     5,
			HasAdvancedAnalytics:    false,
			HasAIRecommendations:    false,
			HasPrioritySupport:      false,
			IsActive:                true,
		},
		Status:             "active",
		BillingCycle:       "monthly",
		PricePaid:          0,
		Currency:           "USD",
		StartedAt:          now,
		CurrentPeriodStart: now,
		CurrentPeriodEnd:   now.AddDate(0, 1, 0),
		AutoRenew:          false,
		DaysRemaining:      30,
		IsTrialActive:      false,
	}
}

// Stub implementations for remaining methods

func (s *subscriptionService) UpdateSubscription(ctx context.Context, userID uuid.UUID, req *dto.UpdateSubscriptionRequest) (*dto.SubscriptionResponse, error) {
	s.logger.Info("Updating subscription")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Get current subscription
	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user subscription: %w", err)
	}

	if subscription == nil {
		return nil, fmt.Errorf("user has no active subscription")
	}

	// Update fields if provided
	updated := false
	
	if req.PlanID != nil {
		// Validate new plan exists
		plan, err := s.planRepo.GetByID(ctx, *req.PlanID)
		if err != nil {
			return nil, fmt.Errorf("failed to get plan: %w", err)
		}
		if plan == nil {
			return nil, fmt.Errorf("plan not found")
		}
		
		subscription.PlanID = *req.PlanID
		subscription.Plan = plan
		updated = true
	}

	if req.BillingCycle != nil {
		subscription.BillingCycle = *req.BillingCycle
		updated = true
	}

	if req.AutoRenew != nil {
		subscription.AutoRenew = *req.AutoRenew
		updated = true
	}

	if updated {
		subscription.UpdatedAt = time.Now()
		err = s.subscriptionRepo.Update(ctx, subscription)
		if err != nil {
			return nil, fmt.Errorf("failed to update subscription: %w", err)
		}
	}

	return s.convertToSubscriptionResponse(subscription), nil
}

func (s *subscriptionService) CancelSubscription(ctx context.Context, userID uuid.UUID, req *dto.CancelSubscriptionRequest) (*dto.SubscriptionResponse, error) {
	s.logger.Info("Canceling subscription")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	// Get current subscription
	subscription, err := s.subscriptionRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user subscription: %w", err)
	}

	if subscription == nil {
		return nil, fmt.Errorf("user has no active subscription")
	}

	if subscription.Status == "canceled" {
		return nil, fmt.Errorf("subscription is already canceled")
	}

	now := time.Now()

	// Update subscription status
	if req.CancelImmediately {
		subscription.Status = "canceled"
		subscription.CurrentPeriodEnd = now
	} else {
		// Cancel at end of current period
		subscription.Status = "canceling"
		subscription.AutoRenew = false
	}

	subscription.CanceledAt = &now
	subscription.CancelReason = &req.Reason
	subscription.UpdatedAt = now

	err = s.subscriptionRepo.Update(ctx, subscription)
	if err != nil {
		return nil, fmt.Errorf("failed to cancel subscription: %w", err)
	}

	// TODO: Send cancellation confirmation email
	// TODO: Process any refunds if applicable
	// TODO: Update external payment provider (Stripe/PayPal)

	s.logger.Info("Subscription canceled successfully")
	return s.convertToSubscriptionResponse(subscription), nil
}