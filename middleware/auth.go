package middleware

import (
	"crypto/subtle"
	"fmt"
	"net/http"
	"os"
	"strings"

	"github.com/gin-gonic/gin"
	"github.com/golang-jwt/jwt/v5"
)

const minimumJWTSecretLength = 32

type accessClaims struct {
	UserID    string   `json:"user_id"`
	TokenType string   `json:"token_type"`
	Roles     []string `json:"roles"`
	jwt.RegisteredClaims
}

func JWTAuthMiddleware() gin.HandlerFunc {
	return jwtMiddleware(false)
}

func JWTWebSocketAuthMiddleware() gin.HandlerFunc {
	return jwtMiddleware(true)
}

func jwtMiddleware(websocket bool) gin.HandlerFunc {
	return func(c *gin.Context) {
		secret := os.Getenv("JWT_SECRET")
		if len(secret) < minimumJWTSecretLength {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
				"status":  "error",
				"message": "Autenticação não configurada",
			})
			return
		}

		tokenString := bearerToken(c.GetHeader("Authorization"))
		if websocket && tokenString == "" {
			tokenString = websocketToken(c.GetHeader("Sec-WebSocket-Protocol"))
		}
		if tokenString == "" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Token de autenticação não fornecido",
			})
			return
		}

		claims := &accessClaims{}
		token, err := jwt.ParseWithClaims(
			tokenString,
			claims,
			func(token *jwt.Token) (interface{}, error) {
				if token.Method != jwt.SigningMethodHS256 {
					return nil, fmt.Errorf("método de assinatura inválido")
				}
				return []byte(secret), nil
			},
			jwt.WithValidMethods([]string{jwt.SigningMethodHS256.Alg()}),
			jwt.WithExpirationRequired(),
		)
		if err != nil || token == nil || !token.Valid || claims.UserID == "" || claims.TokenType != "access" {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{
				"status":  "error",
				"message": "Token JWT inválido ou expirado",
			})
			return
		}

		c.Set("userID", claims.UserID)
		c.Set("userRole", primaryRole(claims.Roles))
		c.Next()
	}
}

func bearerToken(header string) string {
	parts := strings.Fields(header)
	if len(parts) != 2 || !strings.EqualFold(parts[0], "Bearer") {
		return ""
	}
	return parts[1]
}

func websocketToken(protocolHeader string) string {
	protocols := strings.Split(protocolHeader, ",")
	for i, protocol := range protocols {
		if strings.TrimSpace(protocol) == "bearer" && i+1 < len(protocols) {
			return strings.TrimSpace(protocols[i+1])
		}
	}
	return ""
}

func primaryRole(roles []string) string {
	role := "viewer"
	for _, roleName := range roles {
		switch strings.ToLower(roleName) {
		case "admin":
			return "admin"
		case "member":
			role = "member"
		}
	}
	return role
}

func RequireRole(allowedRoles ...string) gin.HandlerFunc {
	return func(c *gin.Context) {
		role, _ := c.Get("userRole")
		userRole, ok := role.(string)
		if !ok {
			c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"status": "error", "message": "Acesso negado"})
			return
		}

		for _, allowed := range allowedRoles {
			if strings.EqualFold(userRole, allowed) {
				c.Next()
				return
			}
		}

		c.AbortWithStatusJSON(http.StatusForbidden, gin.H{"status": "error", "message": "Acesso negado"})
	}
}

func TelemetryServiceAuthMiddleware() gin.HandlerFunc {
	return serviceTokenAuthMiddleware("FLEET_TELEMETRY_TOKEN", "Autenticação do serviço de telemetria não configurada")
}

func PaymentServiceAuthMiddleware() gin.HandlerFunc {
	return serviceTokenAuthMiddleware("FLEET_PAYMENT_TOKEN", "Autenticação do serviço de pagamentos não configurada")
}

func serviceTokenAuthMiddleware(environmentKey, missingMessage string) gin.HandlerFunc {
	return func(c *gin.Context) {
		expected := os.Getenv(environmentKey)
		if len(expected) < minimumJWTSecretLength {
			c.AbortWithStatusJSON(http.StatusServiceUnavailable, gin.H{
				"status":  "error",
				"message": missingMessage,
			})
			return
		}

		provided := c.GetHeader("X-Service-Token")
		if len(provided) != len(expected) || subtle.ConstantTimeCompare([]byte(provided), []byte(expected)) != 1 {
			c.AbortWithStatusJSON(http.StatusUnauthorized, gin.H{"status": "error", "message": "Credencial de serviço inválida"})
			return
		}

		c.Next()
	}
}
