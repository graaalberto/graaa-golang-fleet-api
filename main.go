package main

import (
	"log"
	"net/http"
	"os"
	"strings"
	"time"

	"frotago-fleet-api/config"
	"frotago-fleet-api/handlers"
	"frotago-fleet-api/middleware"
	"frotago-fleet-api/websocket"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/joho/godotenv"
)

func main() {
	_ = godotenv.Load()

	// Conecta com o PostgreSQL (fleet_db)
	config.ConnectDB()

	// Inicia Hub de WebSockets em background
	go websocket.GlobalHub.Run()

	mode := os.Getenv("GIN_MODE")
	if mode == "release" {
		gin.SetMode(gin.ReleaseMode)
	}
	r := gin.Default()

	allowedOrigins := strings.FieldsFunc(os.Getenv("ALLOWED_ORIGINS"), func(r rune) bool {
		return r == ',' || r == ';'
	})
	for i := range allowedOrigins {
		allowedOrigins[i] = strings.TrimSpace(allowedOrigins[i])
	}
	if len(allowedOrigins) == 0 {
		allowedOrigins = []string{"http://localhost:5173"}
	}

	r.Use(cors.New(cors.Config{
		AllowOrigins:     allowedOrigins,
		AllowMethods:     []string{"GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"Origin", "Content-Type", "Authorization", "Accept", "X-Requested-With"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
		MaxAge:           12 * time.Hour,
	}))

	r.GET("/api/health", func(c *gin.Context) {
		c.JSON(http.StatusOK, gin.H{
			"status":    "healthy",
			"service":   "graaa-golang-fleet-api",
			"database":  "fleet_db",
			"version":   "v1.0.0",
			"timestamp": time.Now().Format(time.RFC3339),
		})
	})

	// Servidor de WebSocket para o mapa ao vivo
	r.GET("/ws/fleet", middleware.JWTWebSocketAuthMiddleware(), websocket.HandleWebSocket)

	api := r.Group("/api")
	api.Use(middleware.JWTAuthMiddleware())
	{
		// Viaturas
		api.GET("/vehicles", handlers.GetVehicles)

		// Motoristas
		api.GET("/drivers", handlers.GetDrivers)

		// Corridas e Despacho
		api.GET("/trips", handlers.GetTrips)

		// Paragens Técnicas (com fotos MinIO)
		api.GET("/stops", handlers.GetStops)

		// Avarias Mecânicas (com fotos MinIO)
		api.GET("/breakdowns", handlers.GetBreakdowns)
	}

	writes := r.Group("/api")
	writes.Use(middleware.JWTAuthMiddleware(), middleware.RequireRole("admin", "member"))
	{
		writes.POST("/vehicles", handlers.CreateVehicle)
		writes.POST("/drivers", handlers.CreateDriver)
		writes.PATCH("/drivers/:id/status", handlers.UpdateDriverStatus)
		writes.POST("/trips", handlers.CreateTrip)
		writes.PATCH("/trips/:id/status", handlers.UpdateTripStatus)
		writes.POST("/stops", handlers.CreateStop)
		writes.PATCH("/stops/:id/review", handlers.ReviewStop)
		writes.POST("/breakdowns", handlers.CreateBreakdown)
	}

	serviceAPI := r.Group("/api/vehicles")
	serviceAPI.Use(middleware.TelemetryServiceAuthMiddleware())
	{
		serviceAPI.POST("/:id/telemetry", handlers.UpdateVehicleLocation)
	}

	paymentAPI := r.Group("/api/internal/trips")
	paymentAPI.Use(middleware.PaymentServiceAuthMiddleware())
	{
		paymentAPI.PATCH("/:id/payment-status", handlers.UpdateTripPaymentStatus)
	}

	port := os.Getenv("PORT")
	if port == "" {
		port = "8082"
	}

	log.Printf("🚀 FrotaGo Fleet Core API rodando na porta :%s", port)
	log.Printf("📡 WebSocket Server ativo em ws://localhost:%s/ws/fleet", port)
	if err := r.Run(":" + port); err != nil {
		log.Fatalf("Erro ao iniciar servidor: %v", err)
	}
}
