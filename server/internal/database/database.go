package database

import (
	"context"
	"fmt"
	"log"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Config represents database configuration
type Config struct {
	Host     string
	Port     int
	Database string
	Username string
	Password string
	SSLMode  string
}

// Connect establishes a connection to the PostgreSQL database
func Connect(cfg Config) (*pgxpool.Pool, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.Username, cfg.Password, cfg.Database, cfg.SSLMode)

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Test the connection
	if err := pool.Ping(context.Background()); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Println("Successfully connected to database")
	return pool, nil
}

// GetDefaultConfig returns default database configuration
func GetDefaultConfig() Config {
	return Config{
		Host:     "localhost",
		Port:     5432,
		Database: "roudoku",
		Username: "postgres",
		Password: "password",
		SSLMode:  "disable",
	}
}