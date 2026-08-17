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

func GetStops(c *gin.Context) {
	var stops []models.StopReport
	if err := config.DB.Order("reported_at desc").Find(&stops).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao listar paragens"})
		return
	}
	c.JSON(http.StatusOK, stops)
}

func CreateStop(c *gin.Context) {
	var req models.StopReport
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Dados inválidos: " + err.Error()})
		return
	}

	if req.ID == "" {
		req.ID = fmt.Sprintf("stp_%d", time.Now().UnixNano()%1000000)
	}

	req.ReportedAt = time.Now()
	req.Status = "pending_review"

	config.DB.Model(&models.Vehicle{}).Where("plate = ? OR id = ?", req.VehicleID, req.VehicleID).Update("status", "stopped")

	if err := config.DB.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao registrar paragem: " + err.Error()})
		return
	}

	websocket.GlobalHub.BroadcastMessage("STOP_REPORTED", req)

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Paragem registada com sucesso",
		"data":    req,
	})
}

func ReviewStop(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status      string `json:"status" binding:"required"` // approved, rejected
		ReviewNotes string `json:"reviewNotes"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Status obrigatório"})
		return
	}

	var stop models.StopReport
	if err := config.DB.First(&stop, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Paragem não encontrada"})
		return
	}

	stop.Status = req.Status
	stop.ReviewNotes = req.ReviewNotes
	now := time.Now()
	stop.ReviewedAt = &now

	config.DB.Save(&stop)

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Paragem avaliada com sucesso",
		"stop":    stop,
	})
}
