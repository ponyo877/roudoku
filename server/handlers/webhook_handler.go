package handlers

import (
	"crypto/hmac"
	"crypto/sha256"
	"encoding/hex"
	"encoding/json"
	"io"
	"net/http"
	"strings"
	"time"

	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

type WebhookHandler struct {
	subscriptionService services.SubscriptionService
	recommendationService services.RecommendationService
	logger              *logger.Logger
	webhookSecret       string
}

func NewWebhookHandler(
	subscriptionService services.SubscriptionService,
	recommendationService services.RecommendationService,
	webhookSecret string,
	logger *logger.Logger,
) *WebhookHandler {
	return &WebhookHandler{
		subscriptionService:   subscriptionService,
		recommendationService: recommendationService,
		logger:                logger,
		webhookSecret:         webhookSecret,
	}
}

// StripeWebhook handles Stripe subscription webhooks
func (h *WebhookHandler) StripeWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Failed to read request body", err))
		return
	}

	// Verify webhook signature
	signature := r.Header.Get("Stripe-Signature")
	if !h.verifyStripeSignature(body, signature) {
		utils.WriteError(w, r, h.logger, errors.Unauthorized("Invalid webhook signature", nil))
		return
	}

	var event StripeEvent
	if err := json.Unmarshal(body, &event); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid JSON payload", err))
		return
	}

	h.logger.Info("Processing Stripe webhook")

	switch event.Type {
	case "invoice.payment_succeeded":
		h.handlePaymentSucceeded(event.Data.Object)
	case "invoice.payment_failed":
		h.handlePaymentFailed(event.Data.Object)
	case "customer.subscription.created":
		h.handleSubscriptionCreated(event.Data.Object)
	case "customer.subscription.updated":
		h.handleSubscriptionUpdated(event.Data.Object)
	case "customer.subscription.deleted":
		h.handleSubscriptionDeleted(event.Data.Object)
	case "customer.subscription.trial_will_end":
		h.handleTrialWillEnd(event.Data.Object)
	default:
		h.logger.Info("Unhandled webhook event type")
	}

	utils.WriteSuccess(w, map[string]string{"status": "received"})
}

// PayPalWebhook handles PayPal subscription webhooks
func (h *WebhookHandler) PayPalWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Failed to read request body", err))
		return
	}

	var event PayPalEvent
	if err := json.Unmarshal(body, &event); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid JSON payload", err))
		return
	}

	h.logger.Info("Processing PayPal webhook")

	switch event.EventType {
	case "BILLING.SUBSCRIPTION.CREATED":
		h.handlePayPalSubscriptionCreated(event.Resource)
	case "BILLING.SUBSCRIPTION.ACTIVATED":
		h.handlePayPalSubscriptionActivated(event.Resource)
	case "BILLING.SUBSCRIPTION.CANCELLED":
		h.handlePayPalSubscriptionCancelled(event.Resource)
	case "PAYMENT.SALE.COMPLETED":
		h.handlePayPalPaymentCompleted(event.Resource)
	default:
		h.logger.Info("Unhandled PayPal webhook event type")
	}

	utils.WriteSuccess(w, map[string]string{"status": "received"})
}

// RecommendationWebhook handles ML model training completion webhooks
func (h *WebhookHandler) RecommendationWebhook(w http.ResponseWriter, r *http.Request) {
	body, err := io.ReadAll(r.Body)
	if err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Failed to read request body", err))
		return
	}

	var event MLEvent
	if err := json.Unmarshal(body, &event); err != nil {
		utils.WriteError(w, r, h.logger, errors.BadRequest("Invalid JSON payload", err))
		return
	}

	h.logger.Info("Processing ML webhook")

	switch event.Type {
	case "model.training.completed":
		h.handleModelTrainingCompleted(event.Data)
	case "embeddings.update.completed":
		h.handleEmbeddingsUpdateCompleted(event.Data)
	case "similarity.calculation.completed":
		h.handleSimilarityCalculationCompleted(event.Data)
	default:
		h.logger.Info("Unhandled ML webhook event type")
	}

	utils.WriteSuccess(w, map[string]string{"status": "received"})
}

// Private methods for handling specific webhook events

func (h *WebhookHandler) handlePaymentSucceeded(object map[string]interface{}) {
	h.logger.Info("Processing payment succeeded event")
	
	// Extract subscription ID and customer ID from the invoice
	subscriptionID, ok := object["subscription"].(string)
	if !ok {
		h.logger.Error("Missing subscription ID in payment succeeded event")
		return
	}

	customerID, ok := object["customer"].(string)
	if !ok {
		h.logger.Error("Missing customer ID in payment succeeded event")
		return
	}

	// Update subscription status to active
	h.updateSubscriptionStatus(subscriptionID, customerID, "active")
}

func (h *WebhookHandler) handlePaymentFailed(object map[string]interface{}) {
	h.logger.Info("Processing payment failed event")
	
	subscriptionID, ok := object["subscription"].(string)
	if !ok {
		h.logger.Error("Missing subscription ID in payment failed event")
		return
	}

	customerID, ok := object["customer"].(string)
	if !ok {
		h.logger.Error("Missing customer ID in payment failed event")
		return
	}

	// Update subscription status to suspended
	h.updateSubscriptionStatus(subscriptionID, customerID, "suspended")
	
	// TODO: Send notification to user about payment failure
}

func (h *WebhookHandler) handleSubscriptionCreated(object map[string]interface{}) {
	h.logger.Info("Processing subscription created event")
	
	// Extract subscription data and create/update in database
	subscriptionID, _ := object["id"].(string)
	customerID, _ := object["customer"].(string)
	status, _ := object["status"].(string)
	
	h.updateSubscriptionStatus(subscriptionID, customerID, status)
}

func (h *WebhookHandler) handleSubscriptionUpdated(object map[string]interface{}) {
	h.logger.Info("Processing subscription updated event")
	
	subscriptionID, _ := object["id"].(string)
	customerID, _ := object["customer"].(string)
	status, _ := object["status"].(string)
	
	h.updateSubscriptionStatus(subscriptionID, customerID, status)
}

func (h *WebhookHandler) handleSubscriptionDeleted(object map[string]interface{}) {
	h.logger.Info("Processing subscription deleted event")
	
	subscriptionID, _ := object["id"].(string)
	customerID, _ := object["customer"].(string)
	
	h.updateSubscriptionStatus(subscriptionID, customerID, "canceled")
}

func (h *WebhookHandler) handleTrialWillEnd(object map[string]interface{}) {
	h.logger.Info("Processing trial will end event")
	
	_, _ = object["id"].(string)       // subscriptionID - for future use
	_, _ = object["customer"].(string) // customerID - for future use
	
	// TODO: Send notification to user about trial ending
	h.logger.Info("Trial ending soon")
}

func (h *WebhookHandler) handlePayPalSubscriptionCreated(resource map[string]interface{}) {
	h.logger.Info("Processing PayPal subscription created event")
	
	_, _ = resource["id"].(string)     // subscriptionID - for future use
	_, _ = resource["status"].(string) // status - for future use
	
	// TODO: Map PayPal customer to internal user
	h.logger.Info("PayPal subscription created")
}

func (h *WebhookHandler) handlePayPalSubscriptionActivated(resource map[string]interface{}) {
	h.logger.Info("Processing PayPal subscription activated event")
	
	_, _ = resource["id"].(string) // subscriptionID - for future use
	h.logger.Info("PayPal subscription activated")
}

func (h *WebhookHandler) handlePayPalSubscriptionCancelled(resource map[string]interface{}) {
	h.logger.Info("Processing PayPal subscription cancelled event")
	
	_, _ = resource["id"].(string) // subscriptionID - for future use
	h.logger.Info("PayPal subscription cancelled")
}

func (h *WebhookHandler) handlePayPalPaymentCompleted(resource map[string]interface{}) {
	h.logger.Info("Processing PayPal payment completed event")
	
	amount, _ := resource["amount"].(map[string]interface{})
	_, _ = amount["total"].(string)    // total - for future use
	_, _ = amount["currency"].(string) // currency - for future use
	
	h.logger.Info("PayPal payment completed")
}

func (h *WebhookHandler) handleModelTrainingCompleted(data map[string]interface{}) {
	h.logger.Info("Processing model training completed event")
	
	_, _ = data["model_id"].(string)  // modelID - for future use
	_, _ = data["accuracy"].(float64) // accuracy - for future use
	
	h.logger.Info("Model training completed")
	
	// TODO: Update model status in database
	// TODO: Trigger recommendation cache invalidation
}

func (h *WebhookHandler) handleEmbeddingsUpdateCompleted(data map[string]interface{}) {
	h.logger.Info("Processing embeddings update completed event")
	
	_, _ = data["book_count"].(float64) // bookCount - for future use
	h.logger.Info("Embeddings update completed")
	
	// TODO: Trigger recommendation cache invalidation for affected users
}

func (h *WebhookHandler) handleSimilarityCalculationCompleted(data map[string]interface{}) {
	h.logger.Info("Processing similarity calculation completed event")
	
	_, _ = data["user_id"].(string) // userID - for future use
	h.logger.Info("Similarity calculation completed")
	
	// TODO: Trigger recommendation refresh for the user
}

func (h *WebhookHandler) updateSubscriptionStatus(subscriptionID, customerID, status string) {
	// TODO: Implement subscription status update
	// This would involve:
	// 1. Finding the user by customer ID
	// 2. Finding their subscription by external subscription ID
	// 3. Updating the status
	h.logger.Info("Updating subscription status")
}

func (h *WebhookHandler) verifyStripeSignature(payload []byte, signature string) bool {
	if h.webhookSecret == "" {
		h.logger.Warn("Webhook secret not configured, skipping signature verification")
		return true // Allow in development
	}

	// Parse signature header
	signatures := strings.Split(signature, ",")
	var timestamp string
	var v1Signature string
	
	for _, sig := range signatures {
		parts := strings.Split(sig, "=")
		if len(parts) != 2 {
			continue
		}
		
		switch parts[0] {
		case "t":
			timestamp = parts[1]
		case "v1":
			v1Signature = parts[1]
		}
	}

	if timestamp == "" || v1Signature == "" {
		return false
	}

	// Create expected signature
	signedPayload := timestamp + "." + string(payload)
	mac := hmac.New(sha256.New, []byte(h.webhookSecret))
	mac.Write([]byte(signedPayload))
	expectedSignature := hex.EncodeToString(mac.Sum(nil))

	return hmac.Equal([]byte(v1Signature), []byte(expectedSignature))
}

// Webhook event types

type StripeEvent struct {
	ID      string `json:"id"`
	Type    string `json:"type"`
	Created int64  `json:"created"`
	Data    struct {
		Object map[string]interface{} `json:"object"`
	} `json:"data"`
}

type PayPalEvent struct {
	ID           string                 `json:"id"`
	EventType    string                 `json:"event_type"`
	CreateTime   time.Time              `json:"create_time"`
	ResourceType string                 `json:"resource_type"`
	Resource     map[string]interface{} `json:"resource"`
}

type MLEvent struct {
	ID        string                 `json:"id"`
	Type      string                 `json:"type"`
	Timestamp time.Time              `json:"timestamp"`
	Data      map[string]interface{} `json:"data"`
}