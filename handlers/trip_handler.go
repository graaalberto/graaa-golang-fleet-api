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
	req.PaymentStatus = "pending"
	if userID := c.GetString("userID"); userID != "" {
		req.DispatcherUserID = &userID
	}
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

func UpdateTripPaymentStatus(c *gin.Context) {
	var req struct {
		Status string `json:"status" binding:"required"`
	}
	if err := c.ShouldBindJSON(&req); err != nil || (req.Status != "paid" && req.Status != "failed" && req.Status != "refunded") {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Estado de pagamento inválido"})
		return
	}

	result := config.DB.Model(&models.Trip{}).
		Where("id = ?", c.Param("id")).
		Update("payment_status", req.Status)
	if result.Error != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Não foi possível atualizar o pagamento da corrida"})
		return
	}
	if result.RowsAffected == 0 {
		var trip models.Trip
		if err := config.DB.Select("id, payment_status").First(&trip, "id = ?", c.Param("id")).Error; err != nil {
			c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Corrida não encontrada"})
			return
		}
		if trip.PaymentStatus != req.Status {
			c.JSON(http.StatusConflict, gin.H{"status": "error", "message": "Não foi possível aplicar o novo estado de pagamento"})
			return
		}
	}

	websocket.GlobalHub.BroadcastMessage("TRIP_PAYMENT_UPDATED", gin.H{
		"tripId":        c.Param("id"),
		"paymentStatus": req.Status,
	})
	c.JSON(http.StatusOK, gin.H{"status": "success", "paymentStatus": req.Status})
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
	switch req.Status {
	case "assigned", "in_progress", "completed", "cancelled":
	default:
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Status de corrida inválido"})
		return
	}

	var trip models.Trip
	if err := config.DB.First(&trip, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Corrida não encontrada"})
		return
	}
	if c.GetString("userRole") != "admin" {
		userID := c.GetString("userID")
		isDispatcher := trip.DispatcherUserID != nil && *trip.DispatcherUserID == userID
		isAssignedDriver := false
		if !isDispatcher && userID != "" && trip.DriverID != nil {
			var driver models.Driver
			if err := config.DB.Select("user_id").First(&driver, "id = ?", *trip.DriverID).Error; err == nil {
				isAssignedDriver = driver.UserID != nil && *driver.UserID == userID
			}
		}
		if !isDispatcher && !isAssignedDriver {
			c.JSON(http.StatusForbidden, gin.H{"status": "error", "message": "Acesso negado"})
			return
		}
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
		config.DB.Model(&models.Vehicle{}).Where("id = ?", trip.VehicleID).Update("status", "idle")
	}

	if err := config.DB.Save(&trip).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao atualizar corrida"})
		return
	}

	websocket.GlobalHub.BroadcastMessage("TRIP_UPDATED", trip)

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Corrida atualizada com sucesso",
		"trip":    trip,
	})
}
