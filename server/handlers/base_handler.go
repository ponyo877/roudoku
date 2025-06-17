package handlers

import (
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
)

type BaseHandler struct {
	logger    *logger.Logger
	validator *utils.Validator
}

func NewBaseHandler(log *logger.Logger) *BaseHandler {
	return &BaseHandler{
		logger:    log,
		validator: utils.NewValidator(),
	}
}