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

func GetBreakdowns(c *gin.Context) {
	var breakdowns []models.Breakdown
	if err := config.DB.Order("reported_at desc").Find(&breakdowns).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao listar avarias"})
		return
	}
	c.JSON(http.StatusOK, breakdowns)
}

func CreateBreakdown(c *gin.Context) {
	var req models.Breakdown
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Dados inválidos: " + err.Error()})
		return
	}

	if req.ID == "" {
		req.ID = fmt.Sprintf("brk_%d", time.Now().UnixNano()%1000000)
	}

	req.ReportedAt = time.Now()
	req.Status = "reported"

	vStatus := "maintenance"
	if req.Severity == "critical" {
		vStatus = "critical_breakdown"
	}
	config.DB.Model(&models.Vehicle{}).Where("plate = ? OR id = ?", req.VehicleID, req.VehicleID).Update("status", vStatus)

	if err := config.DB.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao reportar avaria: " + err.Error()})
		return
	}

	websocket.GlobalHub.BroadcastMessage("CRITICAL_ALERT", gin.H{
		"vehicleId": req.VehicleID,
		"severity":  req.Severity,
		"category":  req.Category,
		"message":   req.Description,
	})

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Avaria mecânica reportada com sucesso",
		"data":    req,
	})
}
