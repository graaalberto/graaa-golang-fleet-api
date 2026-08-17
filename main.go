package main

import (
	"log"
	"net/http"
	"os"
	"time"

	"frotago-fleet-api/config"
	"frotago-fleet-api/handlers"
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

	// CORS liberado para o Frontend React
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"},
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
	r.GET("/ws/fleet", websocket.HandleWebSocket)

	api := r.Group("/api")
	{
		// Viaturas
		api.GET("/vehicles", handlers.GetVehicles)
		api.POST("/vehicles", handlers.CreateVehicle)
		api.POST("/vehicles/:id/telemetry", handlers.UpdateVehicleLocation)

		// Motoristas
		api.GET("/drivers", handlers.GetDrivers)
		api.POST("/drivers", handlers.CreateDriver)
		api.PATCH("/drivers/:id/status", handlers.UpdateDriverStatus)

		// Corridas e Despacho
		api.GET("/trips", handlers.GetTrips)
		api.POST("/trips", handlers.CreateTrip)
		api.PATCH("/trips/:id/status", handlers.UpdateTripStatus)

		// Paragens Técnicas (com fotos MinIO)
		api.GET("/stops", handlers.GetStops)
		api.POST("/stops", handlers.CreateStop)
		api.PATCH("/stops/:id/review", handlers.ReviewStop)

		// Avarias Mecânicas (com fotos MinIO)
		api.GET("/breakdowns", handlers.GetBreakdowns)
		api.POST("/breakdowns", handlers.CreateBreakdown)
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
