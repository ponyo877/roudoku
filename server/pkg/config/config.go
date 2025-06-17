package config

import (
	"fmt"
	"os"
	"strconv"
	"time"

	"gopkg.in/yaml.v3"

	"github.com/ponyo877/roudoku/server/pkg/logger"
)

type Config struct {
	Server           ServerConfig           `yaml:"server"`
	Database         DatabaseConfig         `yaml:"database"`
	Logging          logger.Config          `yaml:"logging"`
	ExternalServices ExternalServicesConfig `yaml:"external_services"`
}

type ServerConfig struct {
	Port            string        `yaml:"port"`
	Timeout         time.Duration `yaml:"timeout"`
	ShutdownTimeout time.Duration `yaml:"shutdown_timeout"`
}

type DatabaseConfig struct {
	Host            string        `yaml:"host"`
	Port            int           `yaml:"port"`
	Name            string        `yaml:"name"`
	User            string        `yaml:"user"`
	Password        string        `yaml:"password"`
	SSLMode         string        `yaml:"ssl_mode"`
	MaxOpenConns    int           `yaml:"max_open_conns"`
	MaxIdleConns    int           `yaml:"max_idle_conns"`
	ConnMaxLifetime time.Duration `yaml:"conn_max_lifetime"`
}

type ExternalServicesConfig struct {
	GoogleCloud GoogleCloudConfig `yaml:"google_cloud"`
	TTS         TTSConfig         `yaml:"tts"`
	Storage     StorageConfig     `yaml:"storage"`
}

type GoogleCloudConfig struct {
	ProjectID       string `yaml:"project_id"`
	CredentialsPath string `yaml:"credentials_path"`
}

type TTSConfig struct {
	VoiceLanguage string `yaml:"voice_language"`
	VoiceName     string `yaml:"voice_name"`
	AudioEncoding string `yaml:"audio_encoding"`
}

type StorageConfig struct {
	BucketName string `yaml:"bucket_name"`
}

func Load() (*Config, error) {
	env := getEnv("GO_ENV", "local")
	configPath := fmt.Sprintf("configs/config.%s.yaml", env)
	
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		configPath = "configs/config.yaml"
	}

	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, fmt.Errorf("failed to read config file %s: %w", configPath, err)
	}

	var cfg Config
	if err := yaml.Unmarshal(data, &cfg); err != nil {
		return nil, fmt.Errorf("failed to unmarshal config: %w", err)
	}

	cfg.overrideWithEnvVars()
	return &cfg, nil
}

func (c *Config) overrideWithEnvVars() {
	if port := os.Getenv("PORT"); port != "" {
		c.Server.Port = port
	}

	if dbHost := os.Getenv("DB_HOST"); dbHost != "" {
		c.Database.Host = dbHost
	}
	if dbPort := os.Getenv("DB_PORT"); dbPort != "" {
		if port, err := strconv.Atoi(dbPort); err == nil {
			c.Database.Port = port
		}
	}
	if dbName := os.Getenv("DB_NAME"); dbName != "" {
		c.Database.Name = dbName
	}
	if dbUser := os.Getenv("DB_USER"); dbUser != "" {
		c.Database.User = dbUser
	}
	if dbPassword := os.Getenv("DB_PASSWORD"); dbPassword != "" {
		c.Database.Password = dbPassword
	}
	if sslMode := os.Getenv("DB_SSLMODE"); sslMode != "" {
		c.Database.SSLMode = sslMode
	}

	if logLevel := os.Getenv("LOG_LEVEL"); logLevel != "" {
		c.Logging.Level = logLevel
	}

	if projectID := os.Getenv("GOOGLE_CLOUD_PROJECT"); projectID != "" {
		c.ExternalServices.GoogleCloud.ProjectID = projectID
	}
	if credPath := os.Getenv("GOOGLE_APPLICATION_CREDENTIALS"); credPath != "" {
		c.ExternalServices.GoogleCloud.CredentialsPath = credPath
	}
	if bucketName := os.Getenv("STORAGE_BUCKET_NAME"); bucketName != "" {
		c.ExternalServices.Storage.BucketName = bucketName
	}
}

func getEnv(key, defaultVal string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultVal
}