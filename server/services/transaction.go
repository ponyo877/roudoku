package services

import (
	"context"
	"database/sql"
)

// Transaction represents a database transaction
type Transaction interface {
	Commit() error
	Rollback() error
}

// TransactionManager handles database transactions
type TransactionManager interface {
	// BeginTx starts a new transaction
	BeginTx(ctx context.Context, opts *sql.TxOptions) (Transaction, error)
	
	// WithTransaction executes a function within a transaction
	// It automatically handles commit/rollback based on the error returned
	WithTransaction(ctx context.Context, fn func(ctx context.Context, tx Transaction) error) error
}

// TxKey is the context key for storing transaction
type txKey struct{}

// GetTxFromContext retrieves a transaction from context if available
func GetTxFromContext(ctx context.Context) (Transaction, bool) {
	tx, ok := ctx.Value(txKey{}).(Transaction)
	return tx, ok
}

// WithTx adds a transaction to the context
func WithTx(ctx context.Context, tx Transaction) context.Context {
	return context.WithValue(ctx, txKey{}, tx)
}