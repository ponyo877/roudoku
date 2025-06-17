package middleware

import (
	"context"
	"net/http"
	"time"

	"github.com/google/uuid"
	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

type responseWriter struct {
	http.ResponseWriter
	status int
	size   int
}

func (rw *responseWriter) WriteHeader(code int) {
	rw.status = code
	rw.ResponseWriter.WriteHeader(code)
}

func (rw *responseWriter) Write(b []byte) (int, error) {
	size, err := rw.ResponseWriter.Write(b)
	rw.size += size
	return size, err
}

func Logging(log *logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			requestID := uuid.New().String()

			ctx := context.WithValue(r.Context(), "request_id", requestID)
			r = r.WithContext(ctx)

			rw := &responseWriter{
				ResponseWriter: w,
				status:         http.StatusOK,
			}

			w.Header().Set("X-Request-ID", requestID)

			next.ServeHTTP(rw, r)

			duration := time.Since(start)

			log.WithContext(ctx).Info("HTTP Request",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.String("query", r.URL.RawQuery),
				zap.String("remote_addr", r.RemoteAddr),
				zap.String("user_agent", r.UserAgent()),
				zap.Int("status", rw.status),
				zap.Int("response_size", rw.size),
				zap.Duration("duration", duration),
			)
		})
	}
}