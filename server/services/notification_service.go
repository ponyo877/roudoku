package services

import (
	"context"
	"encoding/json"
	"fmt"
	"time"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/messaging"
	"github.com/google/uuid"
	"google.golang.org/api/option"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// NotificationService defines the interface for notification operations
type NotificationService interface {
	// FCM Token management
	RegisterFCMToken(ctx context.Context, userID uuid.UUID, req *dto.FCMTokenRequest) (*dto.FCMTokenResponse, error)
	GetUserTokens(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error)
	DeactivateToken(ctx context.Context, tokenID uuid.UUID) error

	// Notification preferences
	GetNotificationPreferences(ctx context.Context, userID uuid.UUID) (*domain.NotificationPreferences, error)
	UpdateNotificationPreferences(ctx context.Context, userID uuid.UUID, req *dto.UpdateNotificationPreferencesRequest) (*domain.NotificationPreferences, error)

	// Send notifications
	SendNotification(ctx context.Context, req *dto.SendNotificationRequest) (*dto.SendNotificationResponse, error)
	SendNotificationToUser(ctx context.Context, userID uuid.UUID, title, body string, data map[string]interface{}, notificationType string) error

	// Notification history
	GetNotificationHistory(ctx context.Context, userID uuid.UUID, page, perPage int) (*dto.NotificationHistoryResponse, error)
	GetUnreadNotifications(ctx context.Context, userID uuid.UUID) ([]*domain.Notification, error)
	MarkNotificationAsRead(ctx context.Context, notificationID uuid.UUID) error
	MarkAllNotificationsAsRead(ctx context.Context, userID uuid.UUID) error
	GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error)

	// Scheduled notifications
	ScheduleNotification(ctx context.Context, req *dto.ScheduleNotificationRequest) (*dto.ScheduleNotificationResponse, error)
	ProcessPendingNotifications(ctx context.Context) error

	// Cleanup
	CleanupExpiredNotifications(ctx context.Context) error
}

type notificationService struct {
	fcmTokenRepo         repository.FCMTokenRepository
	notificationRepo     repository.NotificationRepository
	scheduledNotifyRepo  repository.ScheduledNotificationRepository
	notificationPrefRepo repository.NotificationPreferencesRepository
	messagingClient      *messaging.Client
	logger               *logger.Logger
}

// NewNotificationService creates a new notification service
func NewNotificationService(
	fcmTokenRepo repository.FCMTokenRepository,
	notificationRepo repository.NotificationRepository,
	scheduledNotifyRepo repository.ScheduledNotificationRepository,
	notificationPrefRepo repository.NotificationPreferencesRepository,
	firebaseCredentialsPath string,
	logger *logger.Logger,
) (NotificationService, error) {
	ctx := context.Background()

	var app *firebase.App
	var err error

	if firebaseCredentialsPath != "" {
		opt := option.WithCredentialsFile(firebaseCredentialsPath)
		app, err = firebase.NewApp(ctx, nil, opt)
	} else {
		app, err = firebase.NewApp(ctx, nil)
	}

	if err != nil {
		return nil, fmt.Errorf("failed to initialize Firebase app: %w", err)
	}

	messagingClient, err := app.Messaging(ctx)
	if err != nil {
		return nil, fmt.Errorf("failed to initialize Firebase messaging client: %w", err)
	}

	return &notificationService{
		fcmTokenRepo:         fcmTokenRepo,
		notificationRepo:     notificationRepo,
		scheduledNotifyRepo:  scheduledNotifyRepo,
		notificationPrefRepo: notificationPrefRepo,
		messagingClient:      messagingClient,
		logger:               logger,
	}, nil
}

func (s *notificationService) RegisterFCMToken(ctx context.Context, userID uuid.UUID, req *dto.FCMTokenRequest) (*dto.FCMTokenResponse, error) {
	// Deactivate any existing tokens for this device
	err := s.fcmTokenRepo.DeactivateByDeviceID(ctx, userID, req.DeviceID)
	if err != nil {
		s.logger.Error("Failed to deactivate existing tokens for device")
		return nil, fmt.Errorf("failed to deactivate existing tokens: %w", err)
	}

	// Create new token
	now := time.Now()
	fcmToken := &domain.FCMToken{
		ID:         uuid.New(),
		UserID:     userID,
		Token:      req.Token,
		DeviceType: req.DeviceType,
		DeviceID:   req.DeviceID,
		IsActive:   true,
		LastUsedAt: now,
		CreatedAt:  now,
		UpdatedAt:  now,
	}

	err = s.fcmTokenRepo.Create(ctx, fcmToken)
	if err != nil {
		s.logger.Error("Failed to register FCM token")
		return nil, fmt.Errorf("failed to register FCM token: %w", err)
	}

	return &dto.FCMTokenResponse{
		Success:      true,
		TokenID:      fcmToken.ID,
		RegisteredAt: fcmToken.CreatedAt,
	}, nil
}

func (s *notificationService) GetUserTokens(ctx context.Context, userID uuid.UUID) ([]*domain.FCMToken, error) {
	return s.fcmTokenRepo.GetActiveTokensByUserID(ctx, userID)
}

func (s *notificationService) DeactivateToken(ctx context.Context, tokenID uuid.UUID) error {
	token, err := s.fcmTokenRepo.GetByID(ctx, tokenID)
	if err != nil {
		return fmt.Errorf("failed to get FCM token: %w", err)
	}
	if token == nil {
		return fmt.Errorf("FCM token not found")
	}

	token.IsActive = false
	token.UpdatedAt = time.Now()

	return s.fcmTokenRepo.Update(ctx, token)
}

func (s *notificationService) GetNotificationPreferences(ctx context.Context, userID uuid.UUID) (*domain.NotificationPreferences, error) {
	prefs, err := s.notificationPrefRepo.GetByUserID(ctx, userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get notification preferences: %w", err)
	}

	// Create default preferences if none exist
	if prefs == nil {
		now := time.Now()
		prefs = &domain.NotificationPreferences{
			UserID:                userID,
			PushEnabled:           true,
			EmailEnabled:          false,
			ReadingReminders:      true,
			ReadingReminderTime:   "19:00:00",
			WeeklyProgress:        true,
			Achievements:          true,
			Recommendations:       true,
			SilentHoursEnabled:    false,
			SilentHoursStart:      "22:00:00",
			SilentHoursEnd:        "08:00:00",
			SoundEnabled:          true,
			VibrationEnabled:      true,
			CreatedAt:             now,
			UpdatedAt:             now,
		}

		err = s.notificationPrefRepo.Create(ctx, prefs)
		if err != nil {
			return nil, fmt.Errorf("failed to create default notification preferences: %w", err)
		}
	}

	return prefs, nil
}

func (s *notificationService) UpdateNotificationPreferences(ctx context.Context, userID uuid.UUID, req *dto.UpdateNotificationPreferencesRequest) (*domain.NotificationPreferences, error) {
	prefs, err := s.GetNotificationPreferences(ctx, userID)
	if err != nil {
		return nil, err
	}

	// Update only provided fields
	if req.PushEnabled != nil {
		prefs.PushEnabled = *req.PushEnabled
	}
	if req.EmailEnabled != nil {
		prefs.EmailEnabled = *req.EmailEnabled
	}
	if req.ReadingReminders != nil {
		prefs.ReadingReminders = *req.ReadingReminders
	}
	if req.ReadingReminderTime != nil {
		prefs.ReadingReminderTime = *req.ReadingReminderTime
	}
	if req.WeeklyProgress != nil {
		prefs.WeeklyProgress = *req.WeeklyProgress
	}
	if req.Achievements != nil {
		prefs.Achievements = *req.Achievements
	}
	if req.Recommendations != nil {
		prefs.Recommendations = *req.Recommendations
	}
	if req.SilentHoursEnabled != nil {
		prefs.SilentHoursEnabled = *req.SilentHoursEnabled
	}
	if req.SilentHoursStart != nil {
		prefs.SilentHoursStart = *req.SilentHoursStart
	}
	if req.SilentHoursEnd != nil {
		prefs.SilentHoursEnd = *req.SilentHoursEnd
	}
	if req.SoundEnabled != nil {
		prefs.SoundEnabled = *req.SoundEnabled
	}
	if req.VibrationEnabled != nil {
		prefs.VibrationEnabled = *req.VibrationEnabled
	}

	prefs.UpdatedAt = time.Now()

	err = s.notificationPrefRepo.Update(ctx, prefs)
	if err != nil {
		return nil, fmt.Errorf("failed to update notification preferences: %w", err)
	}

	return prefs, nil
}

func (s *notificationService) SendNotification(ctx context.Context, req *dto.SendNotificationRequest) (*dto.SendNotificationResponse, error) {
	sentCount := 0
	failedCount := 0
	notificationID := uuid.New()

	for _, userID := range req.UserIDs {
		err := s.SendNotificationToUser(ctx, userID, req.Title, req.Body, req.Data, req.Type)
		if err != nil {
			s.logger.Error("Failed to send notification to user")
			failedCount++
		} else {
			sentCount++
		}
	}

	return &dto.SendNotificationResponse{
		Success:        sentCount > 0,
		SentCount:      sentCount,
		FailedCount:    failedCount,
		NotificationID: notificationID,
		SentAt:         time.Now(),
	}, nil
}

func (s *notificationService) SendNotificationToUser(ctx context.Context, userID uuid.UUID, title, body string, data map[string]interface{}, notificationType string) error {
	// Check user's notification preferences
	prefs, err := s.GetNotificationPreferences(ctx, userID)
	if err != nil {
		s.logger.Error("Failed to get notification preferences")
		return fmt.Errorf("failed to get notification preferences: %w", err)
	}

	// Check if push notifications are enabled
	if !prefs.PushEnabled {
		s.logger.Debug("Push notifications disabled for user")
		return nil
	}

	// Check notification type preferences
	switch notificationType {
	case "reading_reminder":
		if !prefs.ReadingReminders {
			return nil
		}
	case "achievement":
		if !prefs.Achievements {
			return nil
		}
	case "weekly_progress":
		if !prefs.WeeklyProgress {
			return nil
		}
	case "recommendation":
		if !prefs.Recommendations {
			return nil
		}
	}

	// Get user's FCM tokens
	tokens, err := s.fcmTokenRepo.GetActiveTokensByUserID(ctx, userID)
	if err != nil {
		return fmt.Errorf("failed to get user FCM tokens: %w", err)
	}

	if len(tokens) == 0 {
		s.logger.Debug("No active FCM tokens found for user")
		return nil
	}

	// Create notification record
	now := time.Now()
	notification := &domain.Notification{
		ID:             uuid.New(),
		UserID:         userID,
		Title:          title,
		Body:           body,
		Data:           data,
		Type:           notificationType,
		IsRead:         false,
		SentAt:         now,
		DeliveryStatus: "pending",
		CreatedAt:      now,
		UpdatedAt:      now,
	}

	// Convert data to string map for FCM
	stringData := make(map[string]string)
	for k, v := range data {
		if str, ok := v.(string); ok {
			stringData[k] = str
		} else {
			jsonBytes, _ := json.Marshal(v)
			stringData[k] = string(jsonBytes)
		}
	}

	// Send to all user's devices
	var lastMessageID string
	successCount := 0

	for _, token := range tokens {
		message := &messaging.Message{
			Token: token.Token,
			Notification: &messaging.Notification{
				Title: title,
				Body:  body,
			},
			Data: stringData,
			Android: &messaging.AndroidConfig{
				Notification: &messaging.AndroidNotification{
					Sound: "default",
				},
				Priority: "high",
			},
			APNS: &messaging.APNSConfig{
				Payload: &messaging.APNSPayload{
					Aps: &messaging.Aps{
						Alert: &messaging.ApsAlert{
							Title: title,
							Body:  body,
						},
						Sound: "default",
					},
				},
			},
		}

		response, err := s.messagingClient.Send(ctx, message)
		if err != nil {
			s.logger.Error("Failed to send FCM message")
			continue
		}

		lastMessageID = response
		successCount++

		// Update token last used time
		token.LastUsedAt = now
		token.UpdatedAt = now
		s.fcmTokenRepo.Update(ctx, token)
	}

	// Update notification status
	if successCount > 0 {
		notification.DeliveryStatus = "sent"
		notification.FCMMessageID = &lastMessageID
	} else {
		notification.DeliveryStatus = "failed"
		errMsg := "Failed to send to any device"
		notification.ErrorMessage = &errMsg
	}

	// Save notification record
	err = s.notificationRepo.Create(ctx, notification)
	if err != nil {
		s.logger.Error("Failed to save notification record")
		return fmt.Errorf("failed to save notification: %w", err)
	}

	return nil
}

func (s *notificationService) GetNotificationHistory(ctx context.Context, userID uuid.UUID, page, perPage int) (*dto.NotificationHistoryResponse, error) {
	offset := (page - 1) * perPage
	notifications, err := s.notificationRepo.GetByUserID(ctx, userID, perPage, offset)
	if err != nil {
		return nil, fmt.Errorf("failed to get notification history: %w", err)
	}

	// Convert to history format
	history := make([]dto.NotificationHistory, len(notifications))
	for i, n := range notifications {
		history[i] = dto.NotificationHistory{
			ID:        n.ID,
			Title:     n.Title,
			Body:      n.Body,
			Data:      n.Data,
			Type:      n.Type,
			IsRead:    n.IsRead,
			ReadAt:    n.ReadAt,
			SentAt:    n.SentAt,
			ExpiresAt: n.ExpiresAt,
		}
	}

	// Get total count (simplified - would need separate query in production)
	totalCount := len(history)

	return &dto.NotificationHistoryResponse{
		Notifications: history,
		TotalCount:    totalCount,
		Page:          page,
		PerPage:       perPage,
	}, nil
}

func (s *notificationService) GetUnreadNotifications(ctx context.Context, userID uuid.UUID) ([]*domain.Notification, error) {
	return s.notificationRepo.GetUnreadByUserID(ctx, userID)
}

func (s *notificationService) MarkNotificationAsRead(ctx context.Context, notificationID uuid.UUID) error {
	return s.notificationRepo.MarkAsRead(ctx, notificationID)
}

func (s *notificationService) MarkAllNotificationsAsRead(ctx context.Context, userID uuid.UUID) error {
	return s.notificationRepo.MarkAllAsRead(ctx, userID)
}

func (s *notificationService) GetUnreadCount(ctx context.Context, userID uuid.UUID) (int, error) {
	return s.notificationRepo.GetUnreadCount(ctx, userID)
}

func (s *notificationService) ScheduleNotification(ctx context.Context, req *dto.ScheduleNotificationRequest) (*dto.ScheduleNotificationResponse, error) {
	now := time.Now()
	scheduledNotification := &domain.ScheduledNotification{
		ID:         uuid.New(),
		UserID:     req.UserID,
		Title:      req.Title,
		Body:       req.Body,
		Data:       req.Data,
		Type:       req.Type,
		ScheduleAt: req.ScheduleAt,
		IsActive:   true,
		CreatedAt:  now,
		UpdatedAt:  now,
	}

	if req.Recurring != nil {
		scheduledNotification.IsRecurring = true
		scheduledNotification.RecurringFrequency = &req.Recurring.Frequency
		scheduledNotification.RecurringDaysOfWeek = req.Recurring.DaysOfWeek
		scheduledNotification.RecurringTimeOfDay = &req.Recurring.TimeOfDay
		scheduledNotification.RecurringEndDate = req.Recurring.EndDate
	}

	err := s.scheduledNotifyRepo.Create(ctx, scheduledNotification)
	if err != nil {
		return nil, fmt.Errorf("failed to create scheduled notification: %w", err)
	}

	return &dto.ScheduleNotificationResponse{
		Success:       true,
		ScheduleID:    scheduledNotification.ID,
		NextExecution: *scheduledNotification.NextExecutionAt,
		ScheduledAt:   scheduledNotification.CreatedAt,
	}, nil
}

func (s *notificationService) ProcessPendingNotifications(ctx context.Context) error {
	pendingNotifications, err := s.scheduledNotifyRepo.GetPendingNotifications(ctx)
	if err != nil {
		return fmt.Errorf("failed to get pending notifications: %w", err)
	}

	now := time.Now()
	for _, scheduled := range pendingNotifications {
		if scheduled.ScheduleAt.After(now) {
			continue
		}

		// Send the notification
		err := s.SendNotificationToUser(ctx, scheduled.UserID, scheduled.Title, scheduled.Body, scheduled.Data, scheduled.Type)
		if err != nil {
			s.logger.Error("Failed to send scheduled notification")
			continue
		}

		// Update execution time
		err = s.scheduledNotifyRepo.UpdateExecutionTime(ctx, scheduled.ID)
		if err != nil {
			s.logger.Error("Failed to update execution time")
		}
	}

	return nil
}

func (s *notificationService) CleanupExpiredNotifications(ctx context.Context) error {
	return s.notificationRepo.DeleteExpiredNotifications(ctx)
}