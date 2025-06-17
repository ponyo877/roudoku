package middleware

import (
	"context"
	"fmt"
	"net/http"
	"time"

	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

func Timeout(duration time.Duration, log *logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			ctx, cancel := context.WithTimeout(r.Context(), duration)
			defer cancel()

			r = r.WithContext(ctx)

			done := make(chan struct{})
			go func() {
				next.ServeHTTP(w, r)
				close(done)
			}()

			select {
			case <-done:
				return
			case <-ctx.Done():
				if ctx.Err() == context.DeadlineExceeded {
					requestID := r.Context().Value("request_id")
					if requestID == nil {
						requestID = "unknown"
					}

					log.WithContext(r.Context()).Warn("Request timeout",
						zap.String("path", r.URL.Path),
						zap.String("method", r.Method),
						zap.Duration("timeout", duration),
					)

					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusRequestTimeout)
					w.Write([]byte(fmt.Sprintf(`{
						"error": "Request timeout",
						"request_id": "%s",
						"message": "The request took too long to process"
					}`, requestID)))
				}
			}
		})
	}
}