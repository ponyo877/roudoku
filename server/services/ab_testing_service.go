package services

import (
	"context"
	"fmt"
	"hash/fnv"
	"math"
	"time"

	"github.com/google/uuid"

	"github.com/ponyo877/roudoku/server/domain"
	"github.com/ponyo877/roudoku/server/dto"
	"github.com/ponyo877/roudoku/server/pkg/logger"
	"github.com/ponyo877/roudoku/server/repository"
)

// ABTestingService provides A/B testing functionality for recommendations
type ABTestingService interface {
	// Experiment Management
	CreateExperiment(ctx context.Context, req *dto.CreateExperimentRequest) (*dto.ExperimentResponse, error)
	GetExperiment(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentResponse, error)
	UpdateExperiment(ctx context.Context, experimentID uuid.UUID, req *dto.UpdateExperimentRequest) (*dto.ExperimentResponse, error)
	DeleteExperiment(ctx context.Context, experimentID uuid.UUID) error
	ListExperiments(ctx context.Context, req *dto.ListExperimentsRequest) (*dto.ExperimentListResponse, error)
	
	// User Assignment
	AssignUserToExperiment(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID) (*dto.ExperimentAssignment, error)
	GetUserAssignment(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID) (*dto.ExperimentAssignment, error)
	GetUserActiveExperiments(ctx context.Context, userID uuid.UUID) ([]*dto.ExperimentAssignment, error)
	
	// Recommendation Variants
	GetRecommendationsWithExperiment(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) (*dto.RecommendationResponse, error)
	RecordExperimentInteraction(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID, interaction *dto.ExperimentInteraction) error
	
	// Analytics
	GetExperimentResults(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentResults, error)
	GetExperimentStatistics(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentStatistics, error)
	CalculateExperimentSignificance(ctx context.Context, experimentID uuid.UUID) (*dto.SignificanceTest, error)
	
	// Experiment Lifecycle
	StartExperiment(ctx context.Context, experimentID uuid.UUID) error
	StopExperiment(ctx context.Context, experimentID uuid.UUID) error
	ArchiveExperiment(ctx context.Context, experimentID uuid.UUID) error
}

type abTestingService struct {
	*BaseService
	experimentRepo    repository.ExperimentRepository
	assignmentRepo    repository.ExperimentAssignmentRepository
	interactionRepo   repository.ExperimentInteractionRepository
	recommendationService RecommendationService
}

// NewABTestingService creates a new A/B testing service
func NewABTestingService(
	experimentRepo repository.ExperimentRepository,
	assignmentRepo repository.ExperimentAssignmentRepository,
	interactionRepo repository.ExperimentInteractionRepository,
	recommendationService RecommendationService,
	logger *logger.Logger,
) ABTestingService {
	return &abTestingService{
		BaseService:           NewBaseService(logger),
		experimentRepo:        experimentRepo,
		assignmentRepo:        assignmentRepo,
		interactionRepo:       interactionRepo,
		recommendationService: recommendationService,
	}
}

// CreateExperiment creates a new A/B test experiment
func (s *abTestingService) CreateExperiment(ctx context.Context, req *dto.CreateExperimentRequest) (*dto.ExperimentResponse, error) {
	s.logger.Info("Creating A/B test experiment")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	experiment := &domain.RecommendationExperiment{
		ID:               uuid.New(),
		Name:             req.Name,
		Description:      req.Description,
		AlgorithmType:    req.AlgorithmType,
		Parameters:       req.Parameters,
		TargetPercentage: req.TargetPercentage,
		IsActive:         false, // Start inactive
		StartDate:        req.StartDate,
		EndDate:          req.EndDate,
		SuccessMetrics:   req.SuccessMetrics,
		CreatedAt:        time.Now(),
		UpdatedAt:        time.Now(),
	}

	err := s.experimentRepo.Create(ctx, experiment)
	if err != nil {
		s.logger.Error("Failed to create experiment")
		return nil, fmt.Errorf("failed to create experiment: %w", err)
	}

	return s.convertToExperimentResponse(experiment), nil
}

// GetExperiment retrieves an experiment by ID
func (s *abTestingService) GetExperiment(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentResponse, error) {
	s.logger.Info("Getting experiment")

	experiment, err := s.experimentRepo.GetByID(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get experiment: %w", err)
	}

	if experiment == nil {
		return nil, fmt.Errorf("experiment not found")
	}

	return s.convertToExperimentResponse(experiment), nil
}

// AssignUserToExperiment assigns a user to an experiment variant
func (s *abTestingService) AssignUserToExperiment(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID) (*dto.ExperimentAssignment, error) {
	s.logger.Info("Assigning user to experiment")

	// Check if user is already assigned
	existing, err := s.assignmentRepo.GetByUserAndExperiment(ctx, userID, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to check existing assignment: %w", err)
	}

	if existing != nil {
		return s.convertToExperimentAssignment(existing), nil
	}

	// Get experiment details
	experiment, err := s.experimentRepo.GetByID(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get experiment: %w", err)
	}

	if experiment == nil || !experiment.IsActive {
		return nil, fmt.Errorf("experiment not found or inactive")
	}

	// Determine variant assignment
	variant := s.determineVariant(userID, experiment)

	// Create assignment
	assignment := &domain.UserExperimentAssignment{
		UserID:       userID,
		ExperimentID: experimentID,
		Variant:      variant,
		AssignedAt:   time.Now(),
	}

	err = s.assignmentRepo.Create(ctx, assignment)
	if err != nil {
		return nil, fmt.Errorf("failed to create assignment: %w", err)
	}

	return s.convertToExperimentAssignment(assignment), nil
}

// GetRecommendationsWithExperiment provides recommendations with A/B testing
func (s *abTestingService) GetRecommendationsWithExperiment(ctx context.Context, userID uuid.UUID, req *dto.RecommendationRequest) (*dto.RecommendationResponse, error) {
	s.logger.Info("Getting recommendations with A/B testing")

	// Get active experiments for recommendation algorithm
	activeExperiments, err := s.getActiveExperimentsForUser(ctx, userID)
	if err != nil {
		// If A/B testing fails, fall back to regular recommendations
		s.logger.Warn("Failed to get active experiments, falling back to regular recommendations")
		return s.recommendationService.GetRecommendations(ctx, userID, req)
	}

	// If no active experiments, use regular recommendations
	if len(activeExperiments) == 0 {
		return s.recommendationService.GetRecommendations(ctx, userID, req)
	}

	// Apply experiment modifications to the request
	modifiedReq := s.applyExperimentModifications(req, activeExperiments)

	// Get recommendations with modified parameters
	response, err := s.recommendationService.GetRecommendations(ctx, userID, modifiedReq)
	if err != nil {
		return nil, err
	}

	// Add experiment metadata to response explanations
	if response.Explanations == nil {
		response.Explanations = make(map[string]string)
	}
	response.Explanations["ab_testing"] = fmt.Sprintf("Using %d active experiments", len(activeExperiments))

	return response, nil
}

// RecordExperimentInteraction records user interaction for experiment tracking
func (s *abTestingService) RecordExperimentInteraction(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID, interaction *dto.ExperimentInteraction) error {
	s.logger.Info("Recording experiment interaction")

	// Get user assignment
	assignment, err := s.assignmentRepo.GetByUserAndExperiment(ctx, userID, experimentID)
	if err != nil {
		return fmt.Errorf("failed to get user assignment: %w", err)
	}

	if assignment == nil {
		return fmt.Errorf("user not assigned to experiment")
	}

	// Create interaction record
	record := &domain.ExperimentInteraction{
		ID:           uuid.New(),
		UserID:       userID,
		ExperimentID: experimentID,
		Variant:      assignment.Variant,
		InteractionType: interaction.InteractionType,
		InteractionValue: interaction.InteractionValue,
		BookID:       interaction.BookID,
		Metadata:     interaction.Metadata,
		Timestamp:    time.Now(),
	}

	err = s.interactionRepo.Create(ctx, record)
	if err != nil {
		return fmt.Errorf("failed to record interaction: %w", err)
	}

	return nil
}

// GetExperimentResults calculates experiment results
func (s *abTestingService) GetExperimentResults(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentResults, error) {
	s.logger.Info("Getting experiment results")

	// Get experiment details
	experiment, err := s.experimentRepo.GetByID(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get experiment: %w", err)
	}

	// Get all assignments for this experiment
	assignments, err := s.assignmentRepo.GetByExperiment(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get assignments: %w", err)
	}

	// Get all interactions for this experiment
	interactions, err := s.interactionRepo.GetByExperiment(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get interactions: %w", err)
	}

	// Calculate metrics for each variant
	variantResults := s.calculateVariantResults(assignments, interactions)

	return &dto.ExperimentResults{
		ExperimentID:     experimentID,
		ExperimentName:   experiment.Name,
		StartDate:        experiment.StartDate,
		EndDate:          experiment.EndDate,
		TotalParticipants: len(assignments),
		VariantResults:   variantResults,
		OverallMetrics:   s.calculateOverallMetrics(variantResults),
		CalculatedAt:     time.Now(),
	}, nil
}

// CalculateExperimentSignificance performs statistical significance testing
func (s *abTestingService) CalculateExperimentSignificance(ctx context.Context, experimentID uuid.UUID) (*dto.SignificanceTest, error) {
	s.logger.Info("Calculating experiment significance")

	results, err := s.GetExperimentResults(ctx, experimentID)
	if err != nil {
		return nil, fmt.Errorf("failed to get experiment results: %w", err)
	}

	if len(results.VariantResults) < 2 {
		return nil, fmt.Errorf("need at least 2 variants for significance testing")
	}

	// Perform two-sample z-test for conversion rates
	controlVariant := results.VariantResults[0] // Assume first variant is control
	treatmentVariant := results.VariantResults[1] // Assume second variant is treatment

	zScore, pValue := s.calculateZTest(
		controlVariant.ConversionRate, controlVariant.ParticipantCount,
		treatmentVariant.ConversionRate, treatmentVariant.ParticipantCount,
	)

	confidenceLevel := 0.95
	isSignificant := pValue < (1.0 - confidenceLevel)

	return &dto.SignificanceTest{
		ExperimentID:     experimentID,
		ControlVariant:   controlVariant.Variant,
		TreatmentVariant: treatmentVariant.Variant,
		ZScore:           zScore,
		PValue:           pValue,
		ConfidenceLevel:  confidenceLevel,
		IsSignificant:    isSignificant,
		Effect:           s.calculateEffect(controlVariant.ConversionRate, treatmentVariant.ConversionRate),
		SampleSizeControl: controlVariant.ParticipantCount,
		SampleSizeTreatment: treatmentVariant.ParticipantCount,
		CalculatedAt:     time.Now(),
	}, nil
}

// Private helper methods

func (s *abTestingService) determineVariant(userID uuid.UUID, experiment *domain.RecommendationExperiment) string {
	// Use consistent hashing to assign users to variants
	hash := fnv.New32a()
	hash.Write([]byte(userID.String() + experiment.ID.String()))
	hashValue := hash.Sum32()

	// Convert to percentage (0-100)
	percentage := float64(hashValue%10000) / 100.0

	// Assign to control or treatment based on target percentage
	if percentage < experiment.TargetPercentage {
		return "treatment"
	}
	return "control"
}

func (s *abTestingService) getActiveExperimentsForUser(ctx context.Context, userID uuid.UUID) ([]*domain.UserExperimentAssignment, error) {
	// Get all active experiments
	activeExperiments, err := s.experimentRepo.GetActive(ctx)
	if err != nil {
		return nil, err
	}

	var userAssignments []*domain.UserExperimentAssignment
	for _, experiment := range activeExperiments {
		assignment, err := s.AssignUserToExperiment(ctx, userID, experiment.ID)
		if err != nil {
			continue // Skip this experiment if assignment fails
		}

		// Convert DTO back to domain object (simplified)
		domainAssignment := &domain.UserExperimentAssignment{
			UserID:       assignment.UserID,
			ExperimentID: assignment.ExperimentID,
			Variant:      assignment.Variant,
			AssignedAt:   assignment.AssignedAt,
		}

		userAssignments = append(userAssignments, domainAssignment)
	}

	return userAssignments, nil
}

func (s *abTestingService) applyExperimentModifications(req *dto.RecommendationRequest, experiments []*domain.UserExperimentAssignment) *dto.RecommendationRequest {
	modifiedReq := *req // Copy the request

	for _, assignment := range experiments {
		if assignment.Variant == "treatment" {
			// Apply treatment modifications based on experiment type
			// This is a simplified example - in reality, you'd fetch experiment details
			// and apply specific modifications based on the experiment parameters

			// Example: Modify recommendation type for treatment group
			if req.RecommendationType == "hybrid" {
				modifiedReq.RecommendationType = "content_based"
			}

			// Example: Increase diversity for treatment group
			if modifiedReq.Filters == nil {
				modifiedReq.Filters = &dto.RecommendationFilters{}
			}
		}
	}

	return &modifiedReq
}

func (s *abTestingService) buildExperimentInfo(experiments []*domain.UserExperimentAssignment) map[string]interface{} {
	info := make(map[string]interface{})
	
	var activeExperiments []map[string]interface{}
	for _, exp := range experiments {
		activeExperiments = append(activeExperiments, map[string]interface{}{
			"experiment_id": exp.ExperimentID,
			"variant":       exp.Variant,
			"assigned_at":   exp.AssignedAt,
		})
	}

	info["active_experiments"] = activeExperiments
	info["experiment_count"] = len(experiments)

	return info
}

func (s *abTestingService) calculateVariantResults(assignments []*domain.UserExperimentAssignment, interactions []*domain.ExperimentInteraction) []dto.VariantResult {
	variantStats := make(map[string]*dto.VariantResult)

	// Initialize variant stats
	for _, assignment := range assignments {
		if _, exists := variantStats[assignment.Variant]; !exists {
			variantStats[assignment.Variant] = &dto.VariantResult{
				Variant:         assignment.Variant,
				ParticipantCount: 0,
				InteractionCount: 0,
				ConversionCount:  0,
				ConversionRate:   0.0,
				AverageValue:     0.0,
				Metrics:         make(map[string]float64),
			}
		}
		variantStats[assignment.Variant].ParticipantCount++
	}

	// Calculate interaction metrics
	for _, interaction := range interactions {
		variant := interaction.Variant
		if stats, exists := variantStats[variant]; exists {
			stats.InteractionCount++
			
			// Count conversions (define conversion based on interaction type)
			if s.isConversion(interaction.InteractionType) {
				stats.ConversionCount++
			}

			// Add interaction value to average
			if interaction.InteractionValue != nil {
				stats.AverageValue += *interaction.InteractionValue
			}
		}
	}

	// Calculate final rates and averages
	var results []dto.VariantResult
	for _, stats := range variantStats {
		if stats.ParticipantCount > 0 {
			stats.ConversionRate = float64(stats.ConversionCount) / float64(stats.ParticipantCount)
		}
		if stats.InteractionCount > 0 {
			stats.AverageValue /= float64(stats.InteractionCount)
		}
		results = append(results, *stats)
	}

	return results
}

func (s *abTestingService) calculateOverallMetrics(variantResults []dto.VariantResult) map[string]float64 {
	metrics := make(map[string]float64)

	totalParticipants := 0
	totalConversions := 0
	totalInteractions := 0

	for _, result := range variantResults {
		totalParticipants += result.ParticipantCount
		totalConversions += result.ConversionCount
		totalInteractions += result.InteractionCount
	}

	if totalParticipants > 0 {
		metrics["overall_conversion_rate"] = float64(totalConversions) / float64(totalParticipants)
		metrics["overall_interaction_rate"] = float64(totalInteractions) / float64(totalParticipants)
	}

	metrics["total_participants"] = float64(totalParticipants)
	metrics["total_conversions"] = float64(totalConversions)
	metrics["total_interactions"] = float64(totalInteractions)

	return metrics
}

func (s *abTestingService) calculateZTest(p1 float64, n1 int, p2 float64, n2 int) (float64, float64) {
	// Two-sample z-test for proportions
	if n1 == 0 || n2 == 0 {
		return 0.0, 1.0
	}

	// Pooled proportion
	pPool := (p1*float64(n1) + p2*float64(n2)) / float64(n1+n2)
	
	// Standard error
	se := math.Sqrt(pPool * (1 - pPool) * (1.0/float64(n1) + 1.0/float64(n2)))
	
	if se == 0 {
		return 0.0, 1.0
	}

	// Z-score
	zScore := (p1 - p2) / se

	// Two-tailed p-value (simplified normal approximation)
	pValue := 2.0 * (1.0 - s.normalCDF(math.Abs(zScore)))

	return zScore, pValue
}

func (s *abTestingService) normalCDF(x float64) float64 {
	// Simplified normal CDF approximation
	return 0.5 * (1.0 + math.Erf(x/math.Sqrt(2)))
}

func (s *abTestingService) calculateEffect(controlRate, treatmentRate float64) string {
	if treatmentRate > controlRate {
		return "positive"
	} else if treatmentRate < controlRate {
		return "negative"
	}
	return "neutral"
}

func (s *abTestingService) isConversion(interactionType string) bool {
	// Define what constitutes a conversion
	conversionTypes := map[string]bool{
		"click":    true,
		"start":    true,
		"complete": true,
		"rate":     true,
		"like":     true,
	}
	return conversionTypes[interactionType]
}

func (s *abTestingService) convertToExperimentResponse(experiment *domain.RecommendationExperiment) *dto.ExperimentResponse {
	return &dto.ExperimentResponse{
		ID:               experiment.ID,
		Name:             experiment.Name,
		Description:      experiment.Description,
		AlgorithmType:    experiment.AlgorithmType,
		Parameters:       experiment.Parameters,
		TargetPercentage: experiment.TargetPercentage,
		IsActive:         experiment.IsActive,
		StartDate:        experiment.StartDate,
		EndDate:          experiment.EndDate,
		SuccessMetrics:   experiment.SuccessMetrics,
		CreatedAt:        experiment.CreatedAt,
		UpdatedAt:        experiment.UpdatedAt,
	}
}

func (s *abTestingService) convertToExperimentAssignment(assignment *domain.UserExperimentAssignment) *dto.ExperimentAssignment {
	return &dto.ExperimentAssignment{
		UserID:       assignment.UserID,
		ExperimentID: assignment.ExperimentID,
		Variant:      assignment.Variant,
		AssignedAt:   assignment.AssignedAt,
	}
}

// Stub implementations for remaining methods

func (s *abTestingService) UpdateExperiment(ctx context.Context, experimentID uuid.UUID, req *dto.UpdateExperimentRequest) (*dto.ExperimentResponse, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *abTestingService) DeleteExperiment(ctx context.Context, experimentID uuid.UUID) error {
	return fmt.Errorf("not implemented")
}

func (s *abTestingService) ListExperiments(ctx context.Context, req *dto.ListExperimentsRequest) (*dto.ExperimentListResponse, error) {
	s.logger.Info("Listing experiments")

	if err := s.ValidateStruct(req); err != nil {
		return nil, err
	}

	activeOnly := false
	if req.IsActive != nil {
		activeOnly = *req.IsActive
	}

	experiments, err := s.experimentRepo.List(ctx, activeOnly, req.Limit, req.Offset)
	if err != nil {
		return nil, fmt.Errorf("failed to list experiments: %w", err)
	}

	var responses []dto.ExperimentResponse
	for _, exp := range experiments {
		responses = append(responses, *s.convertToExperimentResponse(exp))
	}

	return &dto.ExperimentListResponse{
		Experiments: responses,
		TotalCount:  len(responses), // In a real implementation, this would be a separate count query
		Limit:       req.Limit,
		Offset:      req.Offset,
	}, nil
}

func (s *abTestingService) GetUserAssignment(ctx context.Context, userID uuid.UUID, experimentID uuid.UUID) (*dto.ExperimentAssignment, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *abTestingService) GetUserActiveExperiments(ctx context.Context, userID uuid.UUID) ([]*dto.ExperimentAssignment, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *abTestingService) GetExperimentStatistics(ctx context.Context, experimentID uuid.UUID) (*dto.ExperimentStatistics, error) {
	return nil, fmt.Errorf("not implemented")
}

func (s *abTestingService) StartExperiment(ctx context.Context, experimentID uuid.UUID) error {
	s.logger.Info("Starting experiment")

	experiment, err := s.experimentRepo.GetByID(ctx, experimentID)
	if err != nil {
		return fmt.Errorf("failed to get experiment: %w", err)
	}

	if experiment == nil {
		return fmt.Errorf("experiment not found")
	}

	if experiment.IsActive {
		return fmt.Errorf("experiment is already active")
	}

	now := time.Now()
	experiment.IsActive = true
	experiment.StartDate = &now
	experiment.UpdatedAt = now

	err = s.experimentRepo.Update(ctx, experiment)
	if err != nil {
		return fmt.Errorf("failed to start experiment: %w", err)
	}

	s.logger.Info("Experiment started successfully")
	return nil
}

func (s *abTestingService) StopExperiment(ctx context.Context, experimentID uuid.UUID) error {
	s.logger.Info("Stopping experiment")

	experiment, err := s.experimentRepo.GetByID(ctx, experimentID)
	if err != nil {
		return fmt.Errorf("failed to get experiment: %w", err)
	}

	if experiment == nil {
		return fmt.Errorf("experiment not found")
	}

	if !experiment.IsActive {
		return fmt.Errorf("experiment is not active")
	}

	now := time.Now()
	experiment.IsActive = false
	experiment.EndDate = &now
	experiment.UpdatedAt = now

	err = s.experimentRepo.Update(ctx, experiment)
	if err != nil {
		return fmt.Errorf("failed to stop experiment: %w", err)
	}

	s.logger.Info("Experiment stopped successfully")
	return nil
}

func (s *abTestingService) ArchiveExperiment(ctx context.Context, experimentID uuid.UUID) error {
	return fmt.Errorf("not implemented")
}