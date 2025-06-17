package services

import (
	"github.com/go-playground/validator/v10"

	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
)

const (
	DefaultLimit = 20
	MaxLimit     = 100
)

type BaseService struct {
	logger    *logger.Logger
	validator *utils.Validator
}

func NewBaseService(log *logger.Logger) *BaseService {
	return &BaseService{
		logger:    log,
		validator: utils.NewValidator(),
	}
}

func (s *BaseService) ValidateLimit(limit int) error {
	return utils.ValidateLimit(limit)
}

func (s *BaseService) ValidateOffset(offset int) error {
	return utils.ValidateOffset(offset)
}

func (s *BaseService) NormalizeLimit(limit int) int {
	if limit <= 0 {
		return DefaultLimit
	}
	if limit > MaxLimit {
		return MaxLimit
	}
	return limit
}

func (s *BaseService) ValidateStruct(obj interface{}) error {
	return s.validator.ValidateStruct(obj)
}