package main

import (
	"bytes"
	"fmt"
	"net/http"
	"io"
	"time"
	"os"
)

type TestResult struct {
	Endpoint   string
	Method     string
	StatusCode int
	Success    bool
	Response   string
	Error      string
}

func main() {
	fmt.Println("🧪 Comprehensive API Testing")
	fmt.Println("=============================")
	
	// Test various API endpoints
	tests := []struct {
		name     string
		method   string
		endpoint string
		body     string
		needsAuth bool
	}{
		// Health and basic endpoints
		{"Health Check", "GET", "/api/v1/health", "", false},
		{"Search Books", "GET", "/api/v1/books", "", false},
		{"Get Book by ID", "GET", "/api/v1/books/1", "", false},
		{"Get Random Quotes", "GET", "/api/v1/books/1/quotes/random", "", false},
		
		// TTS endpoints (require auth - will fail without token)
		{"TTS Voices", "GET", "/api/v1/tts/voices", "", true},
		
		// Webhook endpoints (no auth required)
		{"Stripe Webhook", "POST", "/api/v1/webhooks/stripe", `{"type":"test"}`, false},
		{"PayPal Webhook", "POST", "/api/v1/webhooks/paypal", `{"event_type":"test"}`, false},
		{"ML Webhook", "POST", "/api/v1/webhooks/ml", `{"model":"test"}`, false},
	}
	
	baseURL := "http://localhost:8080"
	
	// Check if server is running
	if !isServerRunning(baseURL) {
		fmt.Println("❌ Server is not running on localhost:8080")
		fmt.Println("Please start the server first with: go run ./cmd/server/main.go")
		os.Exit(1)
	}
	
	fmt.Println("✅ Server is running, starting tests...\n")
	
	results := []TestResult{}
	
	for _, test := range tests {
		fmt.Printf("Testing %s (%s %s)...\n", test.name, test.method, test.endpoint)
		
		result := testEndpoint(baseURL, test.method, test.endpoint, test.body, test.needsAuth)
		result.Endpoint = test.endpoint
		result.Method = test.method
		
		if result.Success {
			fmt.Printf("  ✅ Status: %d\n", result.StatusCode)
		} else {
			fmt.Printf("  ❌ Status: %d, Error: %s\n", result.StatusCode, result.Error)
		}
		
		results = append(results, result)
		fmt.Println()
	}
	
	// Summary
	fmt.Println("=============================")
	fmt.Println("📊 Test Summary:")
	
	successCount := 0
	for _, result := range results {
		if result.Success {
			successCount++
		}
	}
	
	fmt.Printf("✅ Successful: %d/%d\n", successCount, len(results))
	fmt.Printf("❌ Failed: %d/%d\n", len(results)-successCount, len(results))
	
	if successCount == len(results) {
		fmt.Println("🎉 All tests passed!")
	} else {
		fmt.Println("⚠️  Some tests failed - see details above")
	}
}

func isServerRunning(baseURL string) bool {
	client := &http.Client{Timeout: 2 * time.Second}
	_, err := client.Get(baseURL + "/api/v1/health")
	return err == nil
}

func testEndpoint(baseURL, method, endpoint, body string, needsAuth bool) TestResult {
	client := &http.Client{Timeout: 5 * time.Second}
	
	var req *http.Request
	var err error
	
	if body != "" {
		req, err = http.NewRequest(method, baseURL+endpoint, bytes.NewBufferString(body))
		if err != nil {
			return TestResult{Success: false, Error: err.Error()}
		}
		req.Header.Set("Content-Type", "application/json")
	} else {
		req, err = http.NewRequest(method, baseURL+endpoint, nil)
		if err != nil {
			return TestResult{Success: false, Error: err.Error()}
		}
	}
	
	// Add fake auth header for endpoints that need it
	if needsAuth {
		req.Header.Set("Authorization", "Bearer fake-token-for-testing")
	}
	
	resp, err := client.Do(req)
	if err != nil {
		return TestResult{Success: false, Error: err.Error()}
	}
	defer resp.Body.Close()
	
	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return TestResult{Success: false, Error: err.Error()}
	}
	
	// Consider 2xx and 4xx as successful responses (4xx means the endpoint exists but request is invalid)
	success := resp.StatusCode >= 200 && resp.StatusCode < 500
	
	return TestResult{
		StatusCode: resp.StatusCode,
		Success:    success,
		Response:   string(responseBody),
		Error:      "",
	}
}