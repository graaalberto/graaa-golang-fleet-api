package handlers

import (
	"fmt"
	"net/http"
	"time"

	"frotago-fleet-api/config"
	"frotago-fleet-api/models"
	"frotago-fleet-api/websocket"

	"github.com/gin-gonic/gin"
)

func GetTrips(c *gin.Context) {
	var trips []models.Trip
	query := config.DB.Order("created_at desc")

	status := c.Query("status")
	if status != "" {
		query = query.Where("status = ?", status)
	}

	if err := query.Find(&trips).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao listar corridas"})
		return
	}

	c.JSON(http.StatusOK, trips)
}

func CreateTrip(c *gin.Context) {
	var req models.Trip
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Dados inválidos: " + err.Error()})
		return
	}

	if req.ID == "" {
		req.ID = fmt.Sprintf("trp_%d", time.Now().UnixNano()%1000000)
	}

	req.Status = "assigned"
	now := time.Now()
	req.StartedAt = &now

	config.DB.Model(&models.Vehicle{}).Where("id = ?", req.VehicleID).Update("status", "in_trip")

	if err := config.DB.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao criar despacho: " + err.Error()})
		return
	}

	websocket.GlobalHub.BroadcastMessage("TRIP_DISPATCHED", req)

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Corrida despachada com sucesso",
		"data":    req,
	})
}

func UpdateTripStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status                string `json:"status" binding:"required"`
		ActualDurationMinutes int    `json:"actualDurationMinutes"`
		Rating                *int   `json:"rating"`
		Feedback              string `json:"feedback"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Status obrigatório"})
		return
	}

	var trip models.Trip
	if err := config.DB.First(&trip, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Corrida não encontrada"})
		return
	}

	trip.Status = req.Status
	if req.ActualDurationMinutes > 0 {
		trip.ActualDurationMinutes = req.ActualDurationMinutes
	}
	if req.Rating != nil {
		trip.Rating = req.Rating
	}
	if req.Feedback != "" {
		trip.PassengerFeedback = req.Feedback
	}

	if req.Status == "completed" {
		now := time.Now()
		trip.CompletedAt = &now
		trip.PaymentStatus = "paid"
		config.DB.Model(&models.Vehicle{}).Where("id = ?", trip.VehicleID).Update("status", "idle")
	}

	config.DB.Save(&trip)

	websocket.GlobalHub.BroadcastMessage("TRIP_UPDATED", trip)

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Corrida atualizada com sucesso",
		"trip":    trip,
	})
}
