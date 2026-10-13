package middleware

import (
	"net/http"
	"net/http/httptest"
	"testing"
	"time"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

func TestJWTAuthMiddlewareRequiresAccessToken(t *testing.T) {
	gin.SetMode(gin.TestMode)
	t.Setenv("JWT_SECRET", "test-secret-with-at-least-thirty-two-bytes")

	claims := &accessClaims{
		UserID:    "user-1",
		TokenType: "access",
		Roles:     []string{"member"},
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(time.Minute)),
		},
	}
	token, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte("test-secret-with-at-least-thirty-two-bytes"))
	if err != nil {
		t.Fatal(err)
	}

	router := gin.New()
	router.GET("/protected", JWTAuthMiddleware(), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})

	request := httptest.NewRequest(http.MethodGet, "/protected", nil)
	request.Header.Set("Authorization", "Bearer "+token)
	response := httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusNoContent {
		t.Fatalf("valid access token status = %d, want %d", response.Code, http.StatusNoContent)
	}

	claims.TokenType = "refresh"
	refreshToken, err := jwt.NewWithClaims(jwt.SigningMethodHS256, claims).SignedString([]byte("test-secret-with-at-least-thirty-two-bytes"))
	if err != nil {
		t.Fatal(err)
	}
	request = httptest.NewRequest(http.MethodGet, "/protected", nil)
	request.Header.Set("Authorization", "Bearer "+refreshToken)
	response = httptest.NewRecorder()
	router.ServeHTTP(response, request)
	if response.Code != http.StatusUnauthorized {
		t.Fatalf("refresh token status = %d, want %d", response.Code, http.StatusUnauthorized)
	}
}

func TestJWTAuthMiddlewareFailsClosedWithoutSecret(t *testing.T) {
	gin.SetMode(gin.TestMode)
	t.Setenv("JWT_SECRET", "")

	router := gin.New()
	router.GET("/protected", JWTAuthMiddleware(), func(c *gin.Context) {
		c.Status(http.StatusNoContent)
	})
	response := httptest.NewRecorder()
	router.ServeHTTP(response, httptest.NewRequest(http.MethodGet, "/protected", nil))

	if response.Code != http.StatusServiceUnavailable {
		t.Fatalf("missing-secret status = %d, want %d", response.Code, http.StatusServiceUnavailable)
	}
}
