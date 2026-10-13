# FrotaGo Fleet API

## Configuração de segurança

- Defina `JWT_SECRET` com a mesma chave aleatória de pelo menos 32 bytes usada pelo auth API. Só são aceites JWT HS256 de acesso (`token_type=access`) com expiração.
- Defina `FLEET_TELEMETRY_TOKEN` com um segredo aleatório de pelo menos 32 bytes; use exatamente o mesmo valor na telemetry API. Apenas esta credencial pode atualizar a localização interna da viatura.
- Defina `FLEET_PAYMENT_TOKEN` com outro segredo aleatório de pelo menos 32 bytes; use-o apenas entre payments e fleet API para sincronizar o estado do pagamento.
- Defina `ALLOWED_ORIGINS` com a lista separada por vírgulas das origens exatas do frontend, incluindo esquema e porta, por exemplo `https://app.example.com`. O WebSocket também exige um JWT no subprotocolo `bearer`.
- As operações de escrita REST requerem papel `admin` ou `member`; as leituras requerem um utilizador autenticado. A conclusão da corrida não altera automaticamente o estado do pagamento.

## Estrutura

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
