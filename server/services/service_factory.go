package services

import (
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/repository"
)

// ServiceContainer holds all initialized services
type ServiceContainer struct {
	BookService           BookService
	UserService           UserService
	RatingService         RatingService
	SessionService        SessionService
	SwipeService          SwipeService
	RecommendationService RecommendationService
	ValidationService     BusinessValidationService
}

// ServiceFactory creates and manages service dependencies
type ServiceFactory struct {
	logger *zap.Logger
}

// NewServiceFactory creates a new service factory
func NewServiceFactory(logger *zap.Logger) *ServiceFactory {
	return &ServiceFactory{
		logger: logger,
	}
}

// CreateServices creates all services with proper dependency injection
func (f *ServiceFactory) CreateServices(
	bookRepo repository.BookRepository,
	userRepo repository.UserRepository,
	ratingRepo repository.RatingRepository,
	sessionRepo repository.SessionRepository,
	swipeRepo repository.SwipeRepository,
) *ServiceContainer {
	// Create core services first (no business validation dependencies)
	bookService := NewBookService(bookRepo, f.logger)
	userService := NewUserService(userRepo, f.logger)

	// Create basic services that don't need validation
	baseSessionService := &sessionService{
		BaseService: NewBaseService(f.logger),
		sessionRepo: sessionRepo,
	}
	baseSwipeService := &swipeService{
		BaseService: NewBaseService(f.logger),
		swipeRepo:   swipeRepo,
	}

	// Create validation service with dependencies
	validationService := NewBusinessValidationService(
		userService,
		bookService,
		baseSessionService,
		baseSwipeService,
		f.logger,
	)

	// Create services with validation
	ratingService := NewRatingService(ratingRepo, validationService, f.logger)
	sessionService := NewSessionService(sessionRepo, validationService, f.logger)
	swipeService := NewSwipeService(swipeRepo, validationService, f.logger)

	// Create recommendation service
	recommendationService := NewRecommendationService(
		bookService,
		swipeService,
		sessionService,
		ratingService,
		f.logger,
	)

	return &ServiceContainer{
		BookService:           bookService,
		UserService:           userService,
		RatingService:         ratingService,
		SessionService:        sessionService,
		SwipeService:          swipeService,
		RecommendationService: recommendationService,
		ValidationService:     validationService,
	}
}