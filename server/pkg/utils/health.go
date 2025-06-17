package utils

import (
	"context"
	"net/http"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

type HealthChecker struct {
	db     *pgxpool.Pool
	logger *logger.Logger
}

type HealthStatus struct {
	Status    string            `json:"status"`
	Timestamp string            `json:"timestamp"`
	Version   string            `json:"version"`
	Services  map[string]string `json:"services"`
	Uptime    string            `json:"uptime"`
}

var startTime = time.Now()

func NewHealthChecker(db *pgxpool.Pool, log *logger.Logger) *HealthChecker {
	return &HealthChecker{
		db:     db,
		logger: log,
	}
}

func (h *HealthChecker) CheckHealth(ctx context.Context) *HealthStatus {
	status := &HealthStatus{
		Status:    "ok",
		Timestamp: time.Now().UTC().Format(time.RFC3339),
		Version:   "1.0.0",
		Services:  make(map[string]string),
		Uptime:    time.Since(startTime).String(),
	}

	// Check database connectivity
	if h.db != nil {
		dbCtx, cancel := context.WithTimeout(ctx, 5*time.Second)
		defer cancel()

		if err := h.db.Ping(dbCtx); err != nil {
			status.Status = "degraded"
			status.Services["database"] = "unhealthy"
			h.logger.WithError(err).Error("Database health check failed")
		} else {
			status.Services["database"] = "healthy"
		}
	} else {
		status.Status = "degraded"
		status.Services["database"] = "not_configured"
	}

	// Add more service checks here as needed
	status.Services["api"] = "healthy"

	return status
}

func (h *HealthChecker) Handler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		health := h.CheckHealth(r.Context())
		
		statusCode := http.StatusOK
		if health.Status != "ok" {
			statusCode = http.StatusServiceUnavailable
		}

		WriteJSON(w, statusCode, health)
	}
}

func (h *HealthChecker) ReadinessHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// More strict checks for readiness
		ctx, cancel := context.WithTimeout(r.Context(), 3*time.Second)
		defer cancel()

		if h.db != nil {
			if err := h.db.Ping(ctx); err != nil {
				WriteJSON(w, http.StatusServiceUnavailable, map[string]string{
					"status": "not_ready",
					"reason": "database_unavailable",
				})
				return
			}
		}

		WriteJSON(w, http.StatusOK, map[string]string{
			"status": "ready",
		})
	}
}

func (h *HealthChecker) LivenessHandler() http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		// Simple liveness check
		WriteJSON(w, http.StatusOK, map[string]string{
			"status": "alive",
		})
	}
}