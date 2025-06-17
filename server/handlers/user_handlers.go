package handlers

import (
	"net/http"

	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/pkg/utils"
	"github.com/ponyo877/roudoku/server/services"
)

// UserHandler handles user-related HTTP requests
type UserHandler struct {
	*BaseHandler
	userService services.UserService
}

// NewUserHandler creates a new user handler
func NewUserHandler(userService services.UserService, log *logger.Logger) *UserHandler {
	return &UserHandler{
		BaseHandler: NewBaseHandler(log),
		userService: userService,
	}
}

// CreateUser handles POST /users
func (h *UserHandler) CreateUser(w http.ResponseWriter, r *http.Request) {
	var req dto.CreateUserRequest
	if err := utils.DecodeJSON(r, &req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	if err := h.validator.ValidateStruct(&req); err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	user, err := h.userService.CreateUser(r.Context(), &req)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteCreated(w, user)
}

// GetUser handles GET /users/{id}
func (h *UserHandler) GetUser(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseUUIDParam(r, "id")
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	user, err := h.userService.GetUser(r.Context(), id)
	if err != nil {
		utils.WriteError(w, r, h.logger, err)
		return
	}

	utils.WriteSuccess(w, user)

	user, err := h.userService.GetUser(r.Context(), id)
	if err != nil {
		if err == services.ErrUserNotFound {
			utils.WriteJSONError(w, "User not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	utils.WriteJSONSuccess(w, user, "", http.StatusOK)
}

// UpdateUser handles PUT /users/{id}
func (h *UserHandler) UpdateUser(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseUUIDParam(r, "id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	var req dto.UpdateUserRequest
	if err := utils.DecodeJSONBody(r, &req); err != nil {
		utils.WriteJSONError(w, "Invalid request body", utils.CodeInvalidFormat, http.StatusBadRequest)
		return
	}

	user, err := h.userService.UpdateUser(r.Context(), id, &req)
	if err != nil {
		if err == services.ErrUserNotFound {
			utils.WriteJSONError(w, "User not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	utils.WriteJSONSuccess(w, user, "User updated successfully", http.StatusOK)
}

// DeleteUser handles DELETE /users/{id}
func (h *UserHandler) DeleteUser(w http.ResponseWriter, r *http.Request) {
	id, err := utils.ParseUUIDParam(r, "id")
	if err != nil {
		utils.WriteJSONError(w, "Invalid or missing user ID", utils.CodeInvalidParameter, http.StatusBadRequest)
		return
	}

	err = h.userService.DeleteUser(r.Context(), id)
	if err != nil {
		if err == services.ErrUserNotFound {
			utils.WriteJSONError(w, "User not found", utils.CodeResourceNotFound, http.StatusNotFound)
		} else {
			utils.WriteJSONError(w, err.Error(), utils.CodeInternal, http.StatusInternalServerError)
		}
		return
	}

	w.WriteHeader(http.StatusNoContent)
}