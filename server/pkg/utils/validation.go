package utils

import (
	"fmt"
	"strings"

	"github.com/go-playground/validator/v10"

	"github.com/ponyo877/roudoku/server/pkg/errors"
)

type Validator struct {
	validate *validator.Validate
}

func NewValidator() *Validator {
	return &Validator{
		validate: validator.New(),
	}
}

func (v *Validator) ValidateStruct(s interface{}) error {
	if err := v.validate.Struct(s); err != nil {
		var validationErrors []string
		
		for _, err := range err.(validator.ValidationErrors) {
			validationErrors = append(validationErrors, formatValidationError(err))
		}
		
		return errors.Validation(strings.Join(validationErrors, "; "))
	}
	return nil
}

func formatValidationError(err validator.FieldError) string {
	field := strings.ToLower(err.Field())
	
	switch err.Tag() {
	case "required":
		return fmt.Sprintf("%s is required", field)
	case "email":
		return fmt.Sprintf("%s must be a valid email address", field)
	case "min":
		return fmt.Sprintf("%s must be at least %s characters long", field, err.Param())
	case "max":
		return fmt.Sprintf("%s must be at most %s characters long", field, err.Param())
	case "len":
		return fmt.Sprintf("%s must be exactly %s characters long", field, err.Param())
	case "gte":
		return fmt.Sprintf("%s must be greater than or equal to %s", field, err.Param())
	case "lte":
		return fmt.Sprintf("%s must be less than or equal to %s", field, err.Param())
	case "gt":
		return fmt.Sprintf("%s must be greater than %s", field, err.Param())
	case "lt":
		return fmt.Sprintf("%s must be less than %s", field, err.Param())
	case "uuid":
		return fmt.Sprintf("%s must be a valid UUID", field)
	case "url":
		return fmt.Sprintf("%s must be a valid URL", field)
	default:
		return fmt.Sprintf("%s is invalid", field)
	}
}

func ValidateLimit(limit int) error {
	if limit < 1 {
		return errors.BadRequest("Limit must be greater than 0")
	}
	if limit > 100 {
		return errors.BadRequest("Limit must be less than or equal to 100")
	}
	return nil
}

func ValidateOffset(offset int) error {
	if offset < 0 {
		return errors.BadRequest("Offset must be greater than or equal to 0")
	}
	return nil
}