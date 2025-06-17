package middleware

import (
	"fmt"
	"net/http"
	"runtime/debug"

	"go.uber.org/zap"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

func Recovery(log *logger.Logger) func(http.Handler) http.Handler {
	return func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			defer func() {
				if err := recover(); err != nil {
					requestID := r.Context().Value("request_id")
					if requestID == nil {
						requestID = "unknown"
					}

					stack := debug.Stack()

					log.WithContext(r.Context()).Error("Panic recovered",
						zap.Any("error", err),
						zap.String("path", r.URL.Path),
						zap.String("method", r.Method),
						zap.String("stack", string(stack)),
					)

					w.Header().Set("Content-Type", "application/json")
					w.WriteHeader(http.StatusInternalServerError)
					w.Write([]byte(fmt.Sprintf(`{
						"error": "Internal server error",
						"request_id": "%s",
						"message": "An unexpected error occurred"
					}`, requestID)))
				}
			}()

			next.ServeHTTP(w, r)
		})
	}
}