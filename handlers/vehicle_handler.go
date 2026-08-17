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

func GetVehicles(c *gin.Context) {
	var vehicles []models.Vehicle
	query := config.DB.Model(&models.Vehicle{})

	vType := c.Query("type")
	if vType != "" {
		query = query.Where("type = ?", vType)
	}

	status := c.Query("status")
	if status != "" {
		query = query.Where("status = ?", status)
	}

	if err := query.Find(&vehicles).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao buscar viaturas"})
		return
	}

	c.JSON(http.StatusOK, vehicles)
}

func CreateVehicle(c *gin.Context) {
	var req models.Vehicle
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Dados inválidos: " + err.Error()})
		return
	}

	if req.ID == "" {
		req.ID = fmt.Sprintf("veh_%d", time.Now().UnixNano()%1000000)
	}

	if req.Latitude == 0 && req.Longitude == 0 {
		req.Latitude = -8.8146
		req.Longitude = 13.2301
		req.CurrentAddress = "Mutamba, Luanda"
	}

	if err := config.DB.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao salvar viatura: " + err.Error()})
		return
	}

	websocket.GlobalHub.BroadcastMessage("VEHICLE_CREATED", req)

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Viatura registada com sucesso",
		"data":    req,
	})
}

func UpdateVehicleLocation(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Latitude    float64 `json:"lat" binding:"required"`
		Longitude   float64 `json:"lng" binding:"required"`
		SpeedKmH    float64 `json:"speedKmH"`
		Heading     float64 `json:"heading"`
		FuelLevel   float64 `json:"fuelLevel"`
		OilHealth   float64 `json:"oilHealth"`
		EngineTempC float64 `json:"engineTempC"`
		Address     string  `json:"address"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Parâmetros inválidos"})
		return
	}

	var vehicle models.Vehicle
	if err := config.DB.First(&vehicle, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Viatura não encontrada"})
		return
	}

	vehicle.Latitude = req.Latitude
	vehicle.Longitude = req.Longitude
	if req.SpeedKmH > 0 {
		vehicle.SpeedKmH = req.SpeedKmH
	}
	if req.Heading > 0 {
		vehicle.Heading = req.Heading
	}
	if req.FuelLevel > 0 {
		vehicle.FuelLevel = req.FuelLevel
	}
	if req.OilHealth > 0 {
		vehicle.OilHealth = req.OilHealth
	}
	if req.EngineTempC > 0 {
		vehicle.EngineTempC = req.EngineTempC
	}
	if req.Address != "" {
		vehicle.CurrentAddress = req.Address
	}

	config.DB.Save(&vehicle)

	config.DB.Create(&models.TelemetryLog{
		VehicleID:   vehicle.ID,
		Latitude:    vehicle.Latitude,
		Longitude:   vehicle.Longitude,
		SpeedKmH:    vehicle.SpeedKmH,
		Heading:     vehicle.Heading,
		FuelLevel:   vehicle.FuelLevel,
		OilHealth:   vehicle.OilHealth,
		EngineTempC: vehicle.EngineTempC,
		RecordedAt:  time.Now(),
	})

	websocket.GlobalHub.BroadcastMessage("VEHICLE_POSITION_UPDATE", gin.H{
		"vehicleId":   vehicle.ID,
		"lat":         vehicle.Latitude,
		"lng":         vehicle.Longitude,
		"speedKmH":    vehicle.SpeedKmH,
		"heading":     vehicle.Heading,
		"fuelLevel":   vehicle.FuelLevel,
		"oilHealth":   vehicle.OilHealth,
		"engineTempC": vehicle.EngineTempC,
	})

	c.JSON(http.StatusOK, gin.H{"status": "success", "vehicle": vehicle})
}
