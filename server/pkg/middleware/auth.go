package middleware

import (
	"context"
	"net/http"
	"strings"

	firebase "firebase.google.com/go/v4"
	"firebase.google.com/go/v4/auth"
	"google.golang.org/api/option"

	"github.com/ponyo877/roudoku/server/pkg/errors"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
)

// AuthMiddleware provides Firebase authentication middleware
type AuthMiddleware struct {
	authClient *auth.Client
	logger     *logger.Logger
}

// NewAuthMiddleware creates a new auth middleware
func NewAuthMiddleware(credentialsPath string, logger *logger.Logger) (*AuthMiddleware, error) {
	ctx := context.Background()
	
	var app *firebase.App
	var err error
	
	if credentialsPath != "" {
		opt := option.WithCredentialsFile(credentialsPath)
		app, err = firebase.NewApp(ctx, nil, opt)
	} else {
		app, err = firebase.NewApp(ctx, nil)
	}
	
	if err != nil {
		return nil, err
	}

	authClient, err := app.Auth(ctx)
	if err != nil {
		return nil, err
	}

	return &AuthMiddleware{
		authClient: authClient,
		logger:     logger,
	}, nil
}

// RequireAuth middleware that requires valid Firebase authentication
func (m *AuthMiddleware) RequireAuth() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token, err := m.extractTokenFromRequest(r)
			if err != nil {
				utils.WriteError(w, r, m.logger, errors.Unauthorized("Authentication required", err))
				return
			}

			userToken, err := m.authClient.VerifyIDToken(r.Context(), token)
			if err != nil {
				utils.WriteError(w, r, m.logger, errors.Unauthorized("Invalid token", err))
				return
			}

			// Add user info to context
			ctx := context.WithValue(r.Context(), "user_id", userToken.UID)
			ctx = context.WithValue(ctx, "user_token", userToken)
			
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// OptionalAuth middleware that allows both authenticated and unauthenticated requests
func (m *AuthMiddleware) OptionalAuth() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			token, err := m.extractTokenFromRequest(r)
			if err != nil {
				// Continue without authentication
				next.ServeHTTP(w, r)
				return
			}

			userToken, err := m.authClient.VerifyIDToken(r.Context(), token)
			if err != nil {
				// Log error but continue without authentication
				m.logger.Debug("Failed to verify token, continuing without auth")
				next.ServeHTTP(w, r)
				return
			}

			// Add user info to context
			ctx := context.WithValue(r.Context(), "user_id", userToken.UID)
			ctx = context.WithValue(ctx, "user_token", userToken)
			
			next.ServeHTTP(w, r.WithContext(ctx))
		})
	}
}

// extractTokenFromRequest extracts Bearer token from Authorization header
func (m *AuthMiddleware) extractTokenFromRequest(r *http.Request) (string, error) {
	authHeader := r.Header.Get("Authorization")
	if authHeader == "" {
		return "", errors.Unauthorized("Authorization header missing", nil)
	}

	parts := strings.Split(authHeader, " ")
	if len(parts) != 2 || parts[0] != "Bearer" {
		return "", errors.Unauthorized("Invalid authorization header format", nil)
	}

	return parts[1], nil
}

// GetUserIDFromContext extracts user ID from request context
func GetUserIDFromContext(ctx context.Context) (string, bool) {
	userID, ok := ctx.Value("user_id").(string)
	return userID, ok
}

// GetUserTokenFromContext extracts user token from request context  
func GetUserTokenFromContext(ctx context.Context) (*auth.Token, bool) {
	token, ok := ctx.Value("user_token").(*auth.Token)
	return token, ok
}