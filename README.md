backend-fleet-golang/
├── go.mod
├── .env.example
├── README.md
├── main.go
├── config/
│   └── database.go          # Conexão PostgreSQL (fleet_db)
├── middleware/
│   └── auth.go              # Validação de JWT emitido pela graaa-golang-auth-api
├── models/
│   └── models.go            # Structs Go das tabelas (Vehicle, Driver, Trip, etc.)
├── handlers/
│   ├── vehicle_handler.go   # CRUD de viaturas
│   ├── driver_handler.go    # Gestão de motoristas
│   ├── trip_handler.go      # Despacho e status de corridas
│   ├── stop_handler.go      # Paragens com fotos MinIO
│   └── breakdown_handler.go # Avarias mecânicas com fotos MinIO
└── websocket/
    └── hub.go               # Servidor de WebSockets para telemetria em tempo real


🚀 Como executar no Windows 11 (PowerShell):

# Abra o terminal na pasta backend-fleet-golang criada:


cd backend-fleet-golang

# Baixe os pacotes:


go mod tidy

# Rode a API:


go run main.go


    ✅ Conexão bem-sucedida com o PostgreSQL no banco fleet_db.

    ✅ Todas as rotas REST ativas e mapeadas (/api/vehicles, /api/drivers, /api/trips, /api/stops, /api/breakdowns).

    ✅ Servidor de WebSockets ativo em ws://localhost:8082/ws/fleet pronto para enviar posições GPS ao vivo.

    ✅ Rodando na porta :8082.

# todos Endpoint

    [GIN-debug] GET /api/health --> main.main.func1 (4 handlers)
[GIN-debug] GET /ws/fleet --> frotago-fleet-api/websocket.HandleWebSocket (4 handlers)
[GIN-debug] GET /api/vehicles --> frotago-fleet-api/handlers.GetVehicles (4 handlers)
[GIN-debug] POST /api/vehicles --> frotago-fleet-api/handlers.CreateVehicle (4 handlers)
[GIN-debug] POST /api/vehicles/:id/telemetry --> frotago-fleet-api/handlers.UpdateVehicleLocation (4 handlers)
[GIN-debug] GET /api/drivers --> frotago-fleet-api/handlers.GetDrivers (4 handlers)
[GIN-debug] POST /api/drivers --> frotago-fleet-api/handlers.CreateDriver (4 handlers)
[GIN-debug] PATCH /api/drivers/:id/status --> frotago-fleet-api/handlers.UpdateDriverStatus (4 handlers)
[GIN-debug] GET /api/trips --> frotago-fleet-api/handlers.GetTrips (4 handlers)
[GIN-debug] POST /api/trips --> frotago-fleet-api/handlers.CreateTrip (4 handlers)
[GIN-debug] PATCH /api/trips/:id/status --> frotago-fleet-api/handlers.UpdateTripStatus (4 handlers)
[GIN-debug] GET /api/stops --> frotago-fleet-api/handlers.GetStops (4 handlers)
[GIN-debug] POST /api/stops --> frotago-fleet-api/handlers.CreateStop (4 handlers)
[GIN-debug] PATCH /api/stops/:id/review --> frotago-fleet-api/handlers.ReviewStop (4 handlers)
[GIN-debug] GET /api/breakdowns --> frotago-fleet-api/handlers.GetBreakdowns (4 handlers)
[GIN-debug] POST /api/breakdowns --> frotago-fleet-api/
