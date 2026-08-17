package models

import (
	"time"
)

type Vehicle struct {
	ID               string    `gorm:"primaryKey;type:varchar(64)" json:"id"`
	Plate            string    `gorm:"unique;not null;type:varchar(20)" json:"plate"`
	Brand            string    `gorm:"not null;type:varchar(60)" json:"brand"`
	Model            string    `gorm:"not null;type:varchar(80)" json:"model"`
	Year             int       `gorm:"not null" json:"year"`
	Type             string    `gorm:"not null;type:varchar(30)" json:"type"` // car_taxi | moto_taxi
	FuelType         string    `gorm:"default:'gasoline';type:varchar(30)" json:"fuelType"`
	Status           string    `gorm:"default:'idle';type:varchar(30)" json:"status"` // idle, in_trip, stopped, maintenance, critical_breakdown
	FuelLevel        float64   `gorm:"default:100.0" json:"fuelLevel"`
	OilHealth        float64   `gorm:"default:100.0" json:"oilHealth"`
	EngineTempC      float64   `gorm:"default:85.0" json:"engineTempC"`
	SpeedKmH         float64   `gorm:"default:0.0" json:"speedKmH"`
	OdometerKm       float64   `gorm:"default:0.0" json:"odometerKm"`
	Heading          float64   `gorm:"default:0.0" json:"heading"`
	Latitude         float64   `gorm:"default:-8.8383;type:numeric(10,7)" json:"latitude"`
	Longitude        float64   `gorm:"default:13.2344;type:numeric(10,7)" json:"longitude"`
	CurrentAddress   string    `json:"currentAddress"`
	AssignedDriverID *string   `gorm:"type:varchar(64)" json:"assignedDriverId"`
	DriverName       string    `gorm:"->" json:"driverName,omitempty"`
	TrackerIMEI      string    `gorm:"type:varchar(50)" json:"trackerImei"`
	PhotoURL         string    `json:"photoUrl"` // URL MinIO (bucket: vehicles)
	CreatedAt        time.Time `json:"createdAt"`
	UpdatedAt        time.Time `json:"updatedAt"`
}

type Driver struct {
	ID                 string    `gorm:"primaryKey;type:varchar(64)" json:"id"`
	UserID             *string   `gorm:"type:varchar(64)" json:"userId"`
	Name               string    `gorm:"not null;type:varchar(150)" json:"name"`
	Phone              string    `gorm:"unique;not null;type:varchar(30)" json:"phone"`
	LicenseNumber      string    `gorm:"unique;not null;type:varchar(50)" json:"licenseNumber"`
	LicenseCategory    string    `gorm:"default:'B';type:varchar(10)" json:"licenseCategory"`
	Status             string    `gorm:"default:'offline';type:varchar(30)" json:"status"` // online, on_trip, break, offline
	Rating             float64   `gorm:"default:5.0" json:"rating"`
	TotalTrips         int       `gorm:"default:0" json:"totalTrips"`
	TotalEarningsAOA   float64   `gorm:"default:0.0" json:"totalEarningsAOA"`
	AvatarURL          string    `json:"avatarUrl"`          // URL MinIO (bucket: avatars)
	LicenseDocumentURL string    `json:"licenseDocumentUrl"` // URL MinIO (bucket: documents)
	CriminalRecordURL  string    `json:"criminalRecordUrl"`  // URL MinIO (bucket: documents)
	IsActive           bool      `gorm:"default:true" json:"isActive"`
	CreatedAt          time.Time `json:"createdAt"`
	UpdatedAt          time.Time `json:"updatedAt"`
}

type Trip struct {
	ID                       string     `gorm:"primaryKey;type:varchar(64)" json:"id"`
	VehicleID                string     `gorm:"not null;type:varchar(64)" json:"vehicleId"`
	DriverID                 *string    `gorm:"type:varchar(64)" json:"driverId"`
	DispatcherUserID         *string    `gorm:"type:varchar(64)" json:"dispatcherUserId"`
	PassengerName            string     `gorm:"not null;type:varchar(120)" json:"passengerName"`
	PassengerPhone           string     `gorm:"not null;type:varchar(30)" json:"passengerPhone"`
	OriginLatitude           float64    `gorm:"not null;type:numeric(10,7)" json:"originLatitude"`
	OriginLongitude          float64    `gorm:"not null;type:numeric(10,7)" json:"originLongitude"`
	OriginAddress            string     `gorm:"not null" json:"originAddress"`
	DestinationLatitude      float64    `gorm:"not null;type:numeric(10,7)" json:"destinationLatitude"`
	DestinationLongitude     float64    `gorm:"not null;type:numeric(10,7)" json:"destinationLongitude"`
	DestinationAddress       string     `gorm:"not null" json:"destinationAddress"`
	RoutePolyline            string     `json:"routePolyline"`
	DistanceKm               float64    `gorm:"not null" json:"distanceKm"`
	EstimatedDurationMinutes int        `json:"estimatedDurationMinutes"`
	ActualDurationMinutes    int        `json:"actualDurationMinutes"`
	FareAOA                  float64    `gorm:"not null" json:"fareAOA"`
	FareCurrency             string     `gorm:"default:'AOA'" json:"fareCurrency"`
	PaymentMethod            string     `gorm:"default:'multicaixa_express'" json:"paymentMethod"`
	PaymentStatus            string     `gorm:"default:'pending'" json:"paymentStatus"`
	Status                   string     `gorm:"default:'assigned'" json:"status"` // requested, assigned, in_progress, completed, cancelled
	Rating                   *int       `json:"rating"`
	PassengerFeedback        string     `json:"passengerFeedback"`
	StartedAt                *time.Time `json:"startedAt"`
	CompletedAt              *time.Time `json:"completedAt"`
	CreatedAt                time.Time  `json:"createdAt"`
	UpdatedAt                time.Time  `json:"updatedAt"`
}

type Breakdown struct {
	ID               string     `gorm:"primaryKey;type:varchar(64)" json:"id"`
	VehicleID        string     `gorm:"not null;type:varchar(64)" json:"vehicleId"`
	DriverID         *string    `gorm:"type:varchar(64)" json:"driverId"`
	ReportedByUserID *string    `gorm:"type:varchar(64)" json:"reportedByUserId"`
	Severity         string     `gorm:"default:'medium'" json:"severity"` // low, medium, high, critical
	Category         string     `gorm:"default:'engine'" json:"category"` // engine, brakes, tires, electrical
	Status           string     `gorm:"default:'reported'" json:"status"` // reported, in_review, in_repair, repaired, closed
	Description      string     `gorm:"not null" json:"description"`
	EstimatedCostAOA float64    `gorm:"default:0.0" json:"estimatedCostAOA"`
	FinalCostAOA     float64    `gorm:"default:0.0" json:"finalCostAOA"`
	WorkshopName     string     `json:"workshopName"`
	PhotoURL         string     `json:"photoUrl"`      // URL MinIO (bucket: breakdowns)
	InvoicePDFURL    string     `json:"invoicePdfUrl"` // URL MinIO (bucket: documents)
	ReportedAt       time.Time  `json:"reportedAt"`
	RepairedAt       *time.Time `json:"repairedAt"`
	CreatedAt        time.Time  `json:"createdAt"`
	UpdatedAt        time.Time  `json:"updatedAt"`
}

type StopReport struct {
	ID               string     `gorm:"primaryKey;type:varchar(64)" json:"id"`
	VehicleID        string     `gorm:"not null;type:varchar(64)" json:"vehicleId"`
	DriverID         string     `gorm:"not null;type:varchar(64)" json:"driverId"`
	Reason           string     `gorm:"not null" json:"reason"`                 // fuel, lunch_break, police_check, traffic_jam, breakdown, other
	Status           string     `gorm:"default:'pending_review'" json:"status"` // pending_review, approved, rejected
	Description      string     `gorm:"not null" json:"description"`
	PhotoProofURL    string     `json:"photoProofUrl"` // URL MinIO (bucket: stops)
	Latitude         float64    `gorm:"type:numeric(10,7)" json:"latitude"`
	Longitude        float64    `gorm:"type:numeric(10,7)" json:"longitude"`
	Address          string     `json:"address"`
	DurationMinutes  int        `gorm:"default:15" json:"durationMinutes"`
	ReviewedByUserID *string    `json:"reviewedByUserId"`
	ReviewNotes      string     `json:"reviewNotes"`
	ReportedAt       time.Time  `json:"reportedAt"`
	ReviewedAt       *time.Time `json:"reviewedAt"`
	CreatedAt        time.Time  `json:"createdAt"`
}

type TelemetryLog struct {
	ID          uint      `gorm:"primaryKey;autoIncrement" json:"id"`
	VehicleID   string    `gorm:"not null;type:varchar(64)" json:"vehicleId"`
	Latitude    float64   `gorm:"not null;type:numeric(10,7)" json:"latitude"`
	Longitude   float64   `gorm:"not null;type:numeric(10,7)" json:"longitude"`
	SpeedKmH    float64   `json:"speedKmH"`
	Heading     float64   `json:"heading"`
	FuelLevel   float64   `json:"fuelLevel"`
	OilHealth   float64   `json:"oilHealth"`
	EngineTempC float64   `json:"engineTempC"`
	OdometerKm  float64   `json:"odometerKm"`
	RecordedAt  time.Time `json:"recordedAt"`
}
