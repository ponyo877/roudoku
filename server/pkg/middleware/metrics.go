package middleware

import (
	"net/http"
	"time"

	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

type MetricsCollector struct {
	logger *logger.Logger
}

func NewMetricsCollector(log *logger.Logger) *MetricsCollector {
	return &MetricsCollector{
		logger: log,
	}
}

func (m *MetricsCollector) Middleware() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			start := time.Now()
			
			rw := &responseWriter{
				ResponseWriter: w,
				status:         http.StatusOK,
			}

			next.ServeHTTP(rw, r)

			duration := time.Since(start)

			// Log request metrics
			m.logger.Info("Request metrics",
				zap.String("method", r.Method),
				zap.String("path", r.URL.Path),
				zap.Int("status_code", rw.status),
				zap.Duration("duration", duration),
				zap.Int("response_size", rw.size),
				zap.String("user_agent", r.UserAgent()),
				zap.String("remote_addr", r.RemoteAddr),
			)

			// Log slow requests
			if duration > time.Second {
				m.logger.Warn("Slow request detected",
					zap.String("method", r.Method),
					zap.String("path", r.URL.Path),
					zap.Duration("duration", duration),
				)
			}

			// Log error responses
			if rw.status >= 400 {
				level := zap.WarnLevel
				if rw.status >= 500 {
					level = zap.ErrorLevel
				}

				m.logger.Log(level, "HTTP error response",
					zap.String("method", r.Method),
					zap.String("path", r.URL.Path),
					zap.Int("status_code", rw.status),
					zap.Duration("duration", duration),
				)
			}
		})
	}
}

func HealthCheck() func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			if r.URL.Path == "/health" || r.URL.Path == "/healthz" {
				w.Header().Set("Content-Type", "application/json")
				w.WriteHeader(http.StatusOK)
				w.Write([]byte(`{"status":"ok","timestamp":"` + time.Now().UTC().Format(time.RFC3339) + `"}`))
				return
			}
			next.ServeHTTP(w, r)
		})
	}
}