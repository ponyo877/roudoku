package middleware

import (
	"log"
	"net/http"
	"runtime/debug"

	"github.com/ponyo877/roudoku/server/handlers/utils"
)

// RecoveryMiddleware recovers from panics and returns a 500 error
func RecoveryMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		defer func() {
			if err := recover(); err != nil {
				// Get request ID from context if available
				requestID := ""
				if id, ok := r.Context().Value(RequestIDKey).(string); ok {
					requestID = id
				}
				
				// Log the panic with stack trace
				log.Printf("[%s] PANIC: %v\n%s", requestID, err, debug.Stack())
				
				// Return a generic error response
				utils.WriteJSONError(w, 
					"An internal error occurred", 
					utils.CodeInternal, 
					http.StatusInternalServerError,
				)
			}
		}()
		
		next.ServeHTTP(w, r)
	})
}