package middleware

import (
	"context"
	"log"
	"net/http"
	"time"

	"github.com/google/uuid"
)

// RequestIDKey is the context key for request ID
type contextKey string

const RequestIDKey contextKey = "requestID"

// LoggingMiddleware logs HTTP requests
func LoggingMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		start := time.Now()
		
		// Generate request ID
		requestID := uuid.New().String()
		
		// Create a response writer wrapper to capture status code
		wrappedWriter := &responseWriter{
			ResponseWriter: w,
			statusCode:     http.StatusOK,
		}
		
		// Add request ID to context
		ctx := r.Context()
		ctx = context.WithValue(ctx, RequestIDKey, requestID)
		r = r.WithContext(ctx)
		
		// Log request
		log.Printf("[%s] %s %s %s", requestID, r.Method, r.URL.Path, r.RemoteAddr)
		
		// Call the next handler
		next.ServeHTTP(wrappedWriter, r)
		
		// Log response
		duration := time.Since(start)
		log.Printf("[%s] %d %s %s %s %v", 
			requestID, 
			wrappedWriter.statusCode,
			r.Method, 
			r.URL.Path, 
			r.RemoteAddr,
			duration,
		)
	})
}

// responseWriter wraps http.ResponseWriter to capture status code
type responseWriter struct {
	http.ResponseWriter
	statusCode int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.statusCode = code
	rw.ResponseWriter.WriteHeader(code)
}