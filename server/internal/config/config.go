package config

import (
	"os"
	"strconv"

	"github.com/ponyo877/roudoku/server/internal/database"
)

// Config represents application configuration
type Config struct {
	Port     string
	Database database.Config
}

// Load loads configuration from environment variables
func Load() *Config {
	return &Config{
		Port: getEnv("PORT", "8080"),
		Database: database.Config{
			Host:     getEnv("DB_HOST", "localhost"),
			Port:     getEnvAsInt("DB_PORT", 5432),
			Database: getEnv("DB_NAME", "roudoku"),
			Username: getEnv("DB_USER", "roudoku"),
			Password: getEnv("DB_PASSWORD", "roudoku_local_password"),
			// SSLMode:  getEnv("DB_SSLMODE", "require"), // Enable SSL for public IP
		},
	}
}

// Helper functions
func getEnv(key, defaultVal string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultVal
}

func getEnvAsInt(key string, defaultVal int) int {
	valueStr := getEnv(key, "")
	if value, err := strconv.Atoi(valueStr); err == nil {
		return value
	}
	return defaultVal
}
