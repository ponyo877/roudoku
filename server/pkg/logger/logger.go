package logger

import (
	"context"
	"fmt"
	"os"

	"go.uber.org/zap"
	"go.uber.org/zap/zapcore"
)

type Logger struct {
	*zap.Logger
}

type Config struct {
	Level  string `yaml:"level"`
	Format string `yaml:"format"`
	Output string `yaml:"output"`
}

func New(cfg Config) (*Logger, error) {
	level, err := zapcore.ParseLevel(cfg.Level)
	if err != nil {
		return nil, fmt.Errorf("invalid log level %s: %w", cfg.Level, err)
	}

	var zapConfig zap.Config
	if cfg.Format == "json" {
		zapConfig = zap.NewProductionConfig()
	} else {
		zapConfig = zap.NewDevelopmentConfig()
	}

	zapConfig.Level = zap.NewAtomicLevelAt(level)
	zapConfig.OutputPaths = []string{cfg.Output}
	zapConfig.ErrorOutputPaths = []string{cfg.Output}

	logger, err := zapConfig.Build()
	if err != nil {
		return nil, fmt.Errorf("failed to build logger: %w", err)
	}

	return &Logger{Logger: logger}, nil
}

func NewDefault() *Logger {
	logger, _ := zap.NewDevelopment()
	return &Logger{Logger: logger}
}

func (l *Logger) WithContext(ctx context.Context) *Logger {
	if requestID := ctx.Value("request_id"); requestID != nil {
		return &Logger{
			Logger: l.Logger.With(zap.String("request_id", requestID.(string))),
		}
	}
	return l
}

func (l *Logger) WithFields(fields ...zap.Field) *Logger {
	return &Logger{
		Logger: l.Logger.With(fields...),
	}
}

func (l *Logger) WithError(err error) *Logger {
	return &Logger{
		Logger: l.Logger.With(zap.Error(err)),
	}
}

func (l *Logger) Sync() {
	_ = l.Logger.Sync()
}

func init() {
	if os.Getenv("GO_ENV") != "production" {
		zap.ReplaceGlobals(zap.Must(zap.NewDevelopment()))
	} else {
		zap.ReplaceGlobals(zap.Must(zap.NewProduction()))
	}
}