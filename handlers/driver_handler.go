package handlers

import (
	"fmt"
	"net/http"
	"time"

	"frotago-fleet-api/config"
	"frotago-fleet-api/models"

	"github.com/gin-gonic/gin"
)

func GetDrivers(c *gin.Context) {
	var drivers []models.Driver
	if err := config.DB.Find(&drivers).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao buscar motoristas"})
		return
	}
	c.JSON(http.StatusOK, drivers)
}

func CreateDriver(c *gin.Context) {
	var req models.Driver
	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Dados inválidos: " + err.Error()})
		return
	}

	if req.ID == "" {
		req.ID = fmt.Sprintf("drv_%d", time.Now().UnixNano()%1000000)
	}

	if err := config.DB.Create(&req).Error; err != nil {
		c.JSON(http.StatusInternalServerError, gin.H{"status": "error", "message": "Erro ao cadastrar motorista: " + err.Error()})
		return
	}

	c.JSON(http.StatusCreated, gin.H{
		"status":  "success",
		"message": "Motorista cadastrado com sucesso",
		"data":    req,
	})
}

func UpdateDriverStatus(c *gin.Context) {
	id := c.Param("id")
	var req struct {
		Status string `json:"status" binding:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		c.JSON(http.StatusBadRequest, gin.H{"status": "error", "message": "Status obrigatório"})
		return
	}

	var driver models.Driver
	if err := config.DB.First(&driver, "id = ?", id).Error; err != nil {
		c.JSON(http.StatusNotFound, gin.H{"status": "error", "message": "Motorista não encontrado"})
		return
	}

	driver.Status = req.Status
	config.DB.Save(&driver)

	c.JSON(http.StatusOK, gin.H{
		"status":  "success",
		"message": "Status atualizado com sucesso",
		"driver":  driver,
	})
}
