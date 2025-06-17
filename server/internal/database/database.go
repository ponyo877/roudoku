package database

import (
	"context"
	"fmt"
	"log"
	"time"

	"github.com/jackc/pgx/v5/pgxpool"
)

// Config represents database configuration
type Config struct {
	Host            string
	Port            int
	Database        string
	Username        string
	Password        string
	SSLMode         string
	MaxOpenConns    int
	MaxIdleConns    int
	ConnMaxLifetime time.Duration
}

// ConnectWithOptimization establishes an optimized connection to PostgreSQL
func Connect(cfg Config) (*pgxpool.Pool, error) {
	dsn := fmt.Sprintf("host=%s port=%d user=%s password=%s dbname=%s sslmode=%s",
		cfg.Host, cfg.Port, cfg.Username, cfg.Password, cfg.Database, cfg.SSLMode)

	config, err := pgxpool.ParseConfig(dsn)
	if err != nil {
		return nil, fmt.Errorf("failed to parse database config: %w", err)
	}

	// Optimize connection pool settings
	if cfg.MaxOpenConns > 0 {
		config.MaxConns = int32(cfg.MaxOpenConns)
	} else {
		config.MaxConns = 25
	}
	
	if cfg.MaxIdleConns > 0 {
		config.MinConns = int32(cfg.MaxIdleConns)
	} else {
		config.MinConns = 5
	}
	
	if cfg.ConnMaxLifetime > 0 {
		config.MaxConnLifetime = cfg.ConnMaxLifetime
		config.MaxConnIdleTime = cfg.ConnMaxLifetime / 2
	} else {
		config.MaxConnLifetime = time.Hour
		config.MaxConnIdleTime = 30 * time.Minute
	}

	// Performance optimizations
	config.ConnConfig.RuntimeParams["statement_timeout"] = "30s"
	config.ConnConfig.RuntimeParams["lock_timeout"] = "10s"
	config.ConnConfig.RuntimeParams["idle_in_transaction_session_timeout"] = "60s"

	pool, err := pgxpool.NewWithConfig(context.Background(), config)
	if err != nil {
		return nil, fmt.Errorf("failed to create connection pool: %w", err)
	}

	// Test the connection
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	
	if err := pool.Ping(ctx); err != nil {
		pool.Close()
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	log.Printf("Successfully connected to database with %d max connections", config.MaxConns)
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