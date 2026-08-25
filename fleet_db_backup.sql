--
-- PostgreSQL database dump
--

\restrict 5k0Y5JBoejRObjFvidq1NsVmSDbkOxRe3huWWvKqQJKFqWlV40PCrk2qhlshVhT

-- Dumped from database version 18.4
-- Dumped by pg_dump version 18.4

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET transaction_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


--
-- Name: uuid-ossp; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA public;


--
-- Name: EXTENSION "uuid-ossp"; Type: COMMENT; Schema: -; Owner: 
--

COMMENT ON EXTENSION "uuid-ossp" IS 'generate universally unique identifiers (UUIDs)';


--
-- Name: breakdown_category; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.breakdown_category AS ENUM (
    'engine',
    'brakes',
    'tires',
    'electrical',
    'transmission',
    'body',
    'suspension',
    'other'
);


ALTER TYPE public.breakdown_category OWNER TO postgres;

--
-- Name: breakdown_severity; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.breakdown_severity AS ENUM (
    'low',
    'medium',
    'high',
    'critical'
);


ALTER TYPE public.breakdown_severity OWNER TO postgres;

--
-- Name: breakdown_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.breakdown_status AS ENUM (
    'reported',
    'in_review',
    'in_repair',
    'repaired',
    'closed'
);


ALTER TYPE public.breakdown_status OWNER TO postgres;

--
-- Name: driver_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.driver_status AS ENUM (
    'online',
    'on_trip',
    'break',
    'offline',
    'available',
    'suspended',
    'active',
    'AVAILABLE',
    'ON_TRIP',
    'OFFLINE',
    'SUSPENDED'
);


ALTER TYPE public.driver_status OWNER TO postgres;

--
-- Name: payment_method; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_method AS ENUM (
    'multicaixa_express',
    'cash',
    'card_pos',
    'digital_wallet'
);


ALTER TYPE public.payment_method OWNER TO postgres;

--
-- Name: payment_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.payment_status AS ENUM (
    'pending',
    'paid',
    'failed',
    'refunded'
);


ALTER TYPE public.payment_status OWNER TO postgres;

--
-- Name: review_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.review_status AS ENUM (
    'pending_review',
    'approved',
    'rejected'
);


ALTER TYPE public.review_status OWNER TO postgres;

--
-- Name: stop_reason; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.stop_reason AS ENUM (
    'fuel',
    'lunch_break',
    'police_check',
    'traffic_jam',
    'breakdown',
    'maintenance',
    'other'
);


ALTER TYPE public.stop_reason OWNER TO postgres;

--
-- Name: trip_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.trip_status AS ENUM (
    'requested',
    'assigned',
    'in_progress',
    'completed',
    'cancelled',
    'pending',
    'IN_PROGRESS',
    'COMPLETED',
    'CANCELLED'
);


ALTER TYPE public.trip_status OWNER TO postgres;

--
-- Name: user_role; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.user_role AS ENUM (
    'admin',
    'fleet_manager',
    'dispatcher',
    'driver',
    'mechanic'
);


ALTER TYPE public.user_role OWNER TO postgres;

--
-- Name: vehicle_status; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vehicle_status AS ENUM (
    'idle',
    'in_trip',
    'stopped',
    'maintenance',
    'critical_breakdown',
    'offline',
    'AVAILABLE',
    'IN_TRIP',
    'MAINTENANCE',
    'OFFLINE',
    'ACTIVE',
    'active'
);


ALTER TYPE public.vehicle_status OWNER TO postgres;

--
-- Name: vehicle_type; Type: TYPE; Schema: public; Owner: postgres
--

CREATE TYPE public.vehicle_type AS ENUM (
    'car_taxi',
    'moto_taxi',
    'taxi',
    'moto',
    'TAXI',
    'MOTO',
    'car',
    'motorcycle'
);


ALTER TYPE public.vehicle_type OWNER TO postgres;

--
-- Name: find_nearest_available_vehicles(numeric, numeric, numeric, public.vehicle_type); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.find_nearest_available_vehicles(p_lat numeric, p_lng numeric, p_radius_meters numeric DEFAULT 10000, p_vehicle_type public.vehicle_type DEFAULT NULL::public.vehicle_type) RETURNS TABLE(vehicle_id character varying, plate character varying, brand character varying, model character varying, v_type public.vehicle_type, fuel_level numeric, driver_name character varying, distance_meters numeric, lat numeric, lng numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    RETURN QUERY
    SELECT 
        v.id AS vehicle_id,
        v.plate,
        v.brand,
        v.model,
        v.type AS v_type,
        v.fuel_level,
        COALESCE(d.name, 'Sem motorista') AS driver_name,
        ROUND(ST_Distance(v.current_location::geography, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)::NUMERIC, 2) AS distance_meters,
        ST_Y(v.current_location)::NUMERIC AS lat,
        ST_X(v.current_location)::NUMERIC AS lng
    FROM vehicles v
    LEFT JOIN drivers d ON v.assigned_driver_id = d.id
    WHERE v.status = 'idle'
      AND (p_vehicle_type IS NULL OR v.type = p_vehicle_type)
      AND ST_DWithin(v.current_location::geography, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_radius_meters)
    ORDER BY distance_meters ASC
    LIMIT 10;
END;
$$;


ALTER FUNCTION public.find_nearest_available_vehicles(p_lat numeric, p_lng numeric, p_radius_meters numeric, p_vehicle_type public.vehicle_type) OWNER TO postgres;

--
-- Name: update_updated_at_column(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.update_updated_at_column() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.update_updated_at_column() OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: breakdowns; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.breakdowns (
    id character varying(64) DEFAULT ('brk_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    vehicle_id character varying(64) NOT NULL,
    driver_id character varying(64),
    reported_by_user_id character varying(64),
    severity public.breakdown_severity DEFAULT 'medium'::public.breakdown_severity,
    category public.breakdown_category DEFAULT 'engine'::public.breakdown_category,
    status public.breakdown_status DEFAULT 'reported'::public.breakdown_status,
    description text NOT NULL,
    estimated_cost_aoa numeric(12,2) DEFAULT 0.00,
    final_cost_aoa numeric(12,2) DEFAULT 0.00,
    workshop_name character varying(150),
    photo_url text,
    invoice_pdf_url text,
    reported_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    repaired_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.breakdowns OWNER TO postgres;

--
-- Name: drivers; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.drivers (
    id character varying(64) DEFAULT ('drv_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    user_id character varying(64),
    name character varying(100) NOT NULL,
    phone character varying(30) NOT NULL,
    license_number character varying(50) NOT NULL,
    license_category character varying(50) DEFAULT 'B'::character varying,
    license_expiry_date date,
    status public.driver_status DEFAULT 'offline'::public.driver_status,
    rating numeric(3,2) DEFAULT 5.00,
    total_trips integer DEFAULT 0,
    total_earnings_aoa numeric(14,2) DEFAULT 0.00,
    avatar_url text,
    license_document_url text,
    criminal_record_url text,
    is_active boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT drivers_rating_check CHECK (((rating >= 1.00) AND (rating <= 5.00)))
);


ALTER TABLE public.drivers OWNER TO postgres;

--
-- Name: notification_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.notification_logs (
    id character varying(64) NOT NULL,
    recipient character varying(50) NOT NULL,
    channel character varying(20) NOT NULL,
    type character varying(50) NOT NULL,
    message text NOT NULL,
    status character varying(20) DEFAULT 'sent'::character varying,
    sent_at timestamp with time zone
);


ALTER TABLE public.notification_logs OWNER TO postgres;

--
-- Name: payments; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.payments (
    id character varying(64) DEFAULT ('pay_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    trip_id character varying(64) NOT NULL,
    amount_aoa numeric(12,2) NOT NULL,
    method public.payment_method NOT NULL,
    status public.payment_status DEFAULT 'pending'::public.payment_status,
    gateway_transaction_id character varying(100),
    customer_phone character varying(30),
    receipt_pdf_url text,
    paid_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.payments OWNER TO postgres;

--
-- Name: stop_reports; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.stop_reports (
    id character varying(64) DEFAULT ('stp_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    vehicle_id character varying(64) NOT NULL,
    driver_id character varying(64) NOT NULL,
    reason public.stop_reason NOT NULL,
    status public.review_status DEFAULT 'pending_review'::public.review_status,
    description text NOT NULL,
    photo_proof_url text,
    location public.geometry(Point,4326),
    address text,
    duration_minutes integer DEFAULT 15,
    reviewed_by_user_id character varying(64),
    review_notes text,
    reported_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    reviewed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.stop_reports OWNER TO postgres;

--
-- Name: telemetry_alert_rules; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.telemetry_alert_rules (
    id character varying(64) DEFAULT ('rul_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    name character varying(100) NOT NULL,
    metric_type character varying(50) NOT NULL,
    threshold_value numeric(8,2) NOT NULL,
    condition_operator character varying(5) NOT NULL,
    is_active boolean DEFAULT true,
    notify_sms boolean DEFAULT false,
    notify_whatsapp boolean DEFAULT true,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.telemetry_alert_rules OWNER TO postgres;

--
-- Name: trips; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.trips (
    id character varying(64) DEFAULT ('trp_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    vehicle_id character varying(64) NOT NULL,
    driver_id character varying(64),
    dispatcher_user_id character varying(64),
    passenger_name character varying(120) NOT NULL,
    passenger_phone character varying(30) NOT NULL,
    origin_location public.geometry(Point,4326),
    origin_address text NOT NULL,
    destination_location public.geometry(Point,4326),
    destination_address text NOT NULL,
    route_polyline text,
    distance_km numeric(6,2) NOT NULL,
    estimated_duration_minutes integer,
    actual_duration_minutes integer,
    fare_aoa numeric(12,2) NOT NULL,
    fare_currency character varying(5) DEFAULT 'AOA'::character varying,
    payment_method public.payment_method DEFAULT 'multicaixa_express'::public.payment_method,
    payment_status public.payment_status DEFAULT 'pending'::public.payment_status,
    status public.trip_status DEFAULT 'assigned'::public.trip_status,
    rating integer,
    passenger_feedback text,
    started_at timestamp with time zone,
    completed_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    origin_latitude double precision DEFAULT '-8.8146'::numeric,
    origin_longitude double precision DEFAULT 13.2301,
    destination_latitude double precision DEFAULT '-8.9146'::numeric,
    destination_longitude double precision DEFAULT 13.1801,
    estimated_minutes integer DEFAULT 25,
    notes text DEFAULT ''::text,
    CONSTRAINT trips_rating_check CHECK (((rating >= 1) AND (rating <= 5)))
);


ALTER TABLE public.trips OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.users (
    id character varying(64) DEFAULT ('usr_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    name character varying(150) NOT NULL,
    email character varying(150) NOT NULL,
    password_hash character varying(255) NOT NULL,
    role public.user_role DEFAULT 'dispatcher'::public.user_role,
    phone character varying(30),
    avatar_url text,
    two_factor_enabled boolean DEFAULT false,
    is_active boolean DEFAULT true,
    last_login_at timestamp with time zone,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.users OWNER TO postgres;

--
-- Name: vehicle_telemetry_logs; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicle_telemetry_logs (
    id bigint NOT NULL,
    vehicle_id character varying(64) NOT NULL,
    location public.geometry(Point,4326) NOT NULL,
    speed_km_h numeric(6,2) DEFAULT 0.00,
    heading numeric(5,2) DEFAULT 0.00,
    fuel_level numeric(5,2),
    oil_health numeric(5,2),
    engine_temp_c numeric(5,2),
    odometer_km numeric(10,2),
    recorded_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP
);


ALTER TABLE public.vehicle_telemetry_logs OWNER TO postgres;

--
-- Name: vehicle_telemetry_logs_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.vehicle_telemetry_logs_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.vehicle_telemetry_logs_id_seq OWNER TO postgres;

--
-- Name: vehicle_telemetry_logs_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.vehicle_telemetry_logs_id_seq OWNED BY public.vehicle_telemetry_logs.id;


--
-- Name: vehicles; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.vehicles (
    id character varying(64) DEFAULT ('veh_'::text || substr(md5((random())::text), 1, 12)) NOT NULL,
    plate character varying(20) NOT NULL,
    brand character varying(60) NOT NULL,
    model character varying(80) NOT NULL,
    year integer NOT NULL,
    type public.vehicle_type NOT NULL,
    fuel_type character varying(30) DEFAULT 'gasoline'::character varying,
    status public.vehicle_status DEFAULT 'idle'::public.vehicle_status,
    fuel_level numeric(5,2) DEFAULT 100.00,
    oil_health numeric(5,2) DEFAULT 100.00,
    engine_temp_c numeric(5,2) DEFAULT 85.00,
    speed_km_h numeric(6,2) DEFAULT 0.00,
    odometer_km numeric(10,2) DEFAULT 0.00,
    heading numeric(5,2) DEFAULT 0.00,
    current_location public.geometry(Point,4326),
    current_address text,
    assigned_driver_id character varying(64),
    tracker_imei character varying(50),
    photo_url text,
    registration_doc_url text,
    insurance_doc_url text,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    updated_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    latitude double precision DEFAULT '-8.8146'::numeric,
    longitude double precision DEFAULT 13.2301,
    address character varying(255) DEFAULT 'Luanda, Angola'::character varying,
    fuel_capacity double precision DEFAULT 70.0,
    speed_kmh double precision DEFAULT 0.0,
    CONSTRAINT vehicles_fuel_level_check CHECK (((fuel_level >= (0)::numeric) AND (fuel_level <= (100)::numeric))),
    CONSTRAINT vehicles_oil_health_check CHECK (((oil_health >= (0)::numeric) AND (oil_health <= (100)::numeric)))
);


ALTER TABLE public.vehicles OWNER TO postgres;

--
-- Name: vehicle_telemetry_logs id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_telemetry_logs ALTER COLUMN id SET DEFAULT nextval('public.vehicle_telemetry_logs_id_seq'::regclass);


--
-- Data for Name: breakdowns; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.breakdowns (id, vehicle_id, driver_id, reported_by_user_id, severity, category, status, description, estimated_cost_aoa, final_cost_aoa, workshop_name, photo_url, invoice_pdf_url, reported_at, repaired_at, created_at, updated_at) FROM stdin;
\.


--
-- Data for Name: drivers; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.drivers (id, user_id, name, phone, license_number, license_category, license_expiry_date, status, rating, total_trips, total_earnings_aoa, avatar_url, license_document_url, criminal_record_url, is_active, created_at, updated_at) FROM stdin;
drv_01	\N	AntÃ³nio Silva	+244 923 111 222	LD-90214-B	B	\N	online	4.95	342	1850000.00	https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150	\N	\N	t	2026-08-17 00:48:01.66735+01	2026-08-17 00:48:01.66735+01
drv_02	\N	Mateus Kiala	+244 924 333 444	LD-88120-B	B	\N	on_trip	4.88	280	1420000.00	https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150	\N	\N	t	2026-08-17 00:48:01.66735+01	2026-08-17 00:48:01.66735+01
drv_03	\N	Domingos Pedro	+244 931 555 666	LD-77319-A	B	\N	online	4.90	410	980000.00	https://images.unsplash.com/photo-1492562080023-ab3db95bfbce?w=150	\N	\N	t	2026-08-17 00:48:01.66735+01	2026-08-17 00:48:01.66735+01
drv_04	\N	Manuel Costa	+244 912 777 888	LD-66201-B	B	\N	offline	4.70	115	650000.00	https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=150	\N	\N	t	2026-08-17 00:48:01.66735+01	2026-08-17 00:48:01.66735+01
drv_174500	\N	Ana Emilia	+244956920920	123456789	B	\N	available	5.00	0	0.00				t	2026-08-23 16:18:26.541687+01	2026-08-23 16:18:26.541687+01
drv_380000	\N	Vumbi Alberto	+244956963369	LA-123456	A	\N	available	5.00	0	0.00				t	2026-08-23 16:33:06.849889+01	2026-08-23 17:34:15.905172+01
\.


--
-- Data for Name: notification_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.notification_logs (id, recipient, channel, type, message, status, sent_at) FROM stdin;
ntf_31300	+244923111222	whatsapp	trip_assigned	🚖 *FrotaGo Angola - Nova Corrida Atribuída*\nOlá! A sua viatura (LD-44-12-FK) tem uma nova corrida atribuída.\n*Passageiro:* Passageiro Teste (+244923000111)\n*Origem:* Mutamba\n*Destino:* Maianga\n*Valor:* 2.500,00 AOA	sent	2026-08-21 22:03:53.300194+01
\.


--
-- Data for Name: payments; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.payments (id, trip_id, amount_aoa, method, status, gateway_transaction_id, customer_phone, receipt_pdf_url, paid_at, created_at) FROM stdin;
\.


--
-- Data for Name: spatial_ref_sys; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.spatial_ref_sys (srid, auth_name, auth_srid, srtext, proj4text) FROM stdin;
\.


--
-- Data for Name: stop_reports; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.stop_reports (id, vehicle_id, driver_id, reason, status, description, photo_proof_url, location, address, duration_minutes, reviewed_by_user_id, review_notes, reported_at, reviewed_at, created_at) FROM stdin;
\.


--
-- Data for Name: telemetry_alert_rules; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.telemetry_alert_rules (id, name, metric_type, threshold_value, condition_operator, is_active, notify_sms, notify_whatsapp, created_at) FROM stdin;
rul_01	Alerta CrÃ­tico de CombustÃ­vel	fuel_low	15.00	<	t	t	t	2026-08-17 00:48:01.71824+01
rul_02	Alerta de Ã“leo Degradado	oil_critical	25.00	<	t	f	t	2026-08-17 00:48:01.71824+01
rul_03	Alerta de Superaquecimento do Motor	engine_overheat	98.00	>	t	t	t	2026-08-17 00:48:01.71824+01
\.


--
-- Data for Name: trips; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.trips (id, vehicle_id, driver_id, dispatcher_user_id, passenger_name, passenger_phone, origin_location, origin_address, destination_location, destination_address, route_polyline, distance_km, estimated_duration_minutes, actual_duration_minutes, fare_aoa, fare_currency, payment_method, payment_status, status, rating, passenger_feedback, started_at, completed_at, created_at, updated_at, origin_latitude, origin_longitude, destination_latitude, destination_longitude, estimated_minutes, notes) FROM stdin;
trp_58200	veh_34100	\N	\N	Emilia Alberto	+244997384382	\N		\N			0.00	0	0	3000.00	AOA	cash	pending	assigned	\N		2026-08-23 17:32:39.278058+01	\N	2026-08-23 17:32:39.284983+01	2026-08-23 17:32:39.284983+01	0	0	0	0	25	
trp_478100	veh_04	\N	\N	Emilia Alberto	+244995020	\N		\N			0.00	0	0	4000.00	AOA	multicaixa_express	paid	completed	\N		2026-08-23 17:36:26.949478+01	2026-08-23 17:37:21.312247+01	2026-08-23 17:36:26.955457+01	2026-08-23 17:37:21.314718+01	0	0	0	0	25	
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.users (id, name, email, password_hash, role, phone, avatar_url, two_factor_enabled, is_active, last_login_at, created_at, updated_at) FROM stdin;
usr_admin_01	Administrador FrotaGo	admin@frotago.ao	$2a$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi	admin	+244 923 000 001	\N	f	t	\N	2026-08-17 00:48:01.663831+01	2026-08-17 00:48:01.663831+01
\.


--
-- Data for Name: vehicle_telemetry_logs; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicle_telemetry_logs (id, vehicle_id, location, speed_km_h, heading, fuel_level, oil_health, engine_temp_c, odometer_km, recorded_at) FROM stdin;
\.


--
-- Data for Name: vehicles; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.vehicles (id, plate, brand, model, year, type, fuel_type, status, fuel_level, oil_health, engine_temp_c, speed_km_h, odometer_km, heading, current_location, current_address, assigned_driver_id, tracker_imei, photo_url, registration_doc_url, insurance_doc_url, created_at, updated_at, latitude, longitude, address, fuel_capacity, speed_kmh) FROM stdin;
veh_01	LD-44-12-FK	Toyota	Hiace (Quadrado)	2021	car_taxi	gasoline	in_trip	78.00	85.00	88.00	48.00	68420.00	0.00	0101000020E6100000849ECDAACF752A40A9A44E4013A121C0	Mutamba, Av. 4 de Fevereiro, Luanda	drv_01	864201048291048	https://images.unsplash.com/photo-1549317661-bd32c8ce0db2?w=400	\N	\N	2026-08-17 00:48:01.674148+01	2026-08-17 00:48:01.674148+01	-8.8146	13.2301	Luanda, Angola	70	0
veh_02	LD-99-23-AA	Suzuki	Haojue 125cc	2023	moto_taxi	gasoline	in_trip	65.00	90.00	78.00	36.00	14200.00	0.00	0101000020E61000003D0AD7A3707D2A40EC51B81E85AB21C0	Maianga, Rua AmÃ­lcar Cabral, Luanda	drv_02	864201048291049	https://images.unsplash.com/photo-1558981403-c5f9899a28bc?w=400	\N	\N	2026-08-17 00:48:01.674148+01	2026-08-17 00:48:01.674148+01	-8.8146	13.2301	Luanda, Angola	70	0
veh_03	LD-90-AA-11	Toyota	Corolla	2019	car_taxi	gasoline	critical_breakdown	14.00	12.00	102.00	0.00	142800.00	0.00	0101000020E6100000AEB6627FD95D2A40857CD0B359D521C0	Talatona, Belas Shopping, Luanda	drv_03	864201048291050	https://images.unsplash.com/photo-1590362891991-f776e747a588?w=400	\N	\N	2026-08-17 00:48:01.674148+01	2026-08-17 00:48:01.674148+01	-8.8146	13.2301	Luanda, Angola	70	0
veh_139600	LD-AA-AA-12	HONDA	Hiace	2026	car	gasoline	AVAILABLE	100.00	100.00	85.00	0.00	0.00	0.00	\N		\N			\N	\N	2026-08-23 13:22:23.633647+01	2026-08-23 13:22:23.633647+01	-8.82490696354477	13.210956420882598	Luanda, Angola	70	0
veh_754100	LD-BB-BB-12	YAHMA	YB 125	2026	motorcycle	gasoline	AVAILABLE	100.00	100.00	85.00	0.00	0.00	0.00	\N		\N	86420605499440		\N	\N	2026-08-23 13:42:53.543264+01	2026-08-23 13:42:53.543264+01	-8.834201054536335	13.210597686289205	Luanda, Angola	70	0
veh_303500	LD-AA-BB-11	Toyota 	i10	2025	car	gasoline	AVAILABLE	100.00	100.00	85.00	0.00	0.00	0.00	\N		\N	864207018835693		\N	\N	2026-08-23 14:12:51.16088+01	2026-08-23 14:12:51.16088+01	-8.810191706185172	13.222741272196956	Luanda, Angola	70	0
veh_764200	LD-AA-BV-09	Toyota	Hiace-A	2026	car	gasoline	AVAILABLE	100.00	100.00	85.00	0.00	0.00	0.00	\N		\N	864209866883208		\N	\N	2026-08-23 15:49:45.669712+01	2026-08-23 15:49:45.669712+01	-8.8166758353231	13.226422726031926	Luanda, Angola	70	0
veh_34100	LD-BN-MN-01	HILUX	Hiace	2026	car	gasoline	in_trip	100.00	100.00	85.00	0.00	0.00	0.00	\N		\N	864206258271316		\N	\N	2026-08-23 16:16:45.130655+01	2026-08-23 17:32:39.278969+01	-8.806044798637714	13.218679254615026	Luanda, Angola	70	0
veh_04	LD-12-34-BB	Yamaha	Crux 110cc	2022	moto_taxi	gasoline	idle	92.00	95.00	72.00	0.00	8900.00	0.00	0101000020E61000008FC2F5285C8F2A403D0AD7A370BD21C0	Aeroporto 4 de Fevereiro, Luanda	drv_04	864201048291051	https://images.unsplash.com/photo-1568772585407-9361f9bf3a87?w=400	\N	\N	2026-08-17 00:48:01.674148+01	2026-08-23 17:37:21.31243+01	-8.8146	13.2301	Luanda, Angola	70	0
\.


--
-- Name: vehicle_telemetry_logs_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.vehicle_telemetry_logs_id_seq', 1, false);


--
-- Name: breakdowns breakdowns_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breakdowns
    ADD CONSTRAINT breakdowns_pkey PRIMARY KEY (id);


--
-- Name: drivers drivers_license_number_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_license_number_key UNIQUE (license_number);


--
-- Name: drivers drivers_phone_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_phone_key UNIQUE (phone);


--
-- Name: drivers drivers_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_pkey PRIMARY KEY (id);


--
-- Name: notification_logs notification_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.notification_logs
    ADD CONSTRAINT notification_logs_pkey PRIMARY KEY (id);


--
-- Name: payments payments_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_pkey PRIMARY KEY (id);


--
-- Name: stop_reports stop_reports_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_reports
    ADD CONSTRAINT stop_reports_pkey PRIMARY KEY (id);


--
-- Name: telemetry_alert_rules telemetry_alert_rules_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.telemetry_alert_rules
    ADD CONSTRAINT telemetry_alert_rules_pkey PRIMARY KEY (id);


--
-- Name: trips trips_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_pkey PRIMARY KEY (id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: vehicle_telemetry_logs vehicle_telemetry_logs_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_telemetry_logs
    ADD CONSTRAINT vehicle_telemetry_logs_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_pkey PRIMARY KEY (id);


--
-- Name: vehicles vehicles_plate_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_plate_key UNIQUE (plate);


--
-- Name: vehicles vehicles_tracker_imei_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_tracker_imei_key UNIQUE (tracker_imei);


--
-- Name: idx_breakdowns_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_breakdowns_status ON public.breakdowns USING btree (status);


--
-- Name: idx_drivers_phone; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_phone ON public.drivers USING btree (phone);


--
-- Name: idx_drivers_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_drivers_status ON public.drivers USING btree (status);


--
-- Name: idx_stops_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stops_location ON public.stop_reports USING gist (location);


--
-- Name: idx_stops_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_stops_status ON public.stop_reports USING btree (status);


--
-- Name: idx_telemetry_logs_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telemetry_logs_location ON public.vehicle_telemetry_logs USING gist (location);


--
-- Name: idx_telemetry_vehicle_time; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_telemetry_vehicle_time ON public.vehicle_telemetry_logs USING btree (vehicle_id, recorded_at DESC);


--
-- Name: idx_trips_created_at; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trips_created_at ON public.trips USING btree (created_at DESC);


--
-- Name: idx_trips_dest_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trips_dest_location ON public.trips USING gist (destination_location);


--
-- Name: idx_trips_origin_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trips_origin_location ON public.trips USING gist (origin_location);


--
-- Name: idx_trips_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_trips_status ON public.trips USING btree (status);


--
-- Name: idx_vehicles_location; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_location ON public.vehicles USING gist (current_location);


--
-- Name: idx_vehicles_plate; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_plate ON public.vehicles USING btree (plate);


--
-- Name: idx_vehicles_status; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_status ON public.vehicles USING btree (status);


--
-- Name: idx_vehicles_type; Type: INDEX; Schema: public; Owner: postgres
--

CREATE INDEX idx_vehicles_type ON public.vehicles USING btree (type);


--
-- Name: breakdowns trg_breakdowns_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_breakdowns_updated_at BEFORE UPDATE ON public.breakdowns FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: drivers trg_drivers_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_drivers_updated_at BEFORE UPDATE ON public.drivers FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: trips trg_trips_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_trips_updated_at BEFORE UPDATE ON public.trips FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: users trg_users_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON public.users FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: vehicles trg_vehicles_updated_at; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trg_vehicles_updated_at BEFORE UPDATE ON public.vehicles FOR EACH ROW EXECUTE FUNCTION public.update_updated_at_column();


--
-- Name: breakdowns breakdowns_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breakdowns
    ADD CONSTRAINT breakdowns_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE SET NULL;


--
-- Name: breakdowns breakdowns_reported_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breakdowns
    ADD CONSTRAINT breakdowns_reported_by_user_id_fkey FOREIGN KEY (reported_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: breakdowns breakdowns_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.breakdowns
    ADD CONSTRAINT breakdowns_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;


--
-- Name: drivers drivers_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.drivers
    ADD CONSTRAINT drivers_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: payments payments_trip_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.payments
    ADD CONSTRAINT payments_trip_id_fkey FOREIGN KEY (trip_id) REFERENCES public.trips(id) ON DELETE CASCADE;


--
-- Name: stop_reports stop_reports_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_reports
    ADD CONSTRAINT stop_reports_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE CASCADE;


--
-- Name: stop_reports stop_reports_reviewed_by_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_reports
    ADD CONSTRAINT stop_reports_reviewed_by_user_id_fkey FOREIGN KEY (reviewed_by_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: stop_reports stop_reports_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.stop_reports
    ADD CONSTRAINT stop_reports_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;


--
-- Name: trips trips_dispatcher_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_dispatcher_user_id_fkey FOREIGN KEY (dispatcher_user_id) REFERENCES public.users(id) ON DELETE SET NULL;


--
-- Name: trips trips_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_driver_id_fkey FOREIGN KEY (driver_id) REFERENCES public.drivers(id) ON DELETE SET NULL;


--
-- Name: trips trips_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.trips
    ADD CONSTRAINT trips_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE RESTRICT;


--
-- Name: vehicle_telemetry_logs vehicle_telemetry_logs_vehicle_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicle_telemetry_logs
    ADD CONSTRAINT vehicle_telemetry_logs_vehicle_id_fkey FOREIGN KEY (vehicle_id) REFERENCES public.vehicles(id) ON DELETE CASCADE;


--
-- Name: vehicles vehicles_assigned_driver_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.vehicles
    ADD CONSTRAINT vehicles_assigned_driver_id_fkey FOREIGN KEY (assigned_driver_id) REFERENCES public.drivers(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict 5k0Y5JBoejRObjFvidq1NsVmSDbkOxRe3huWWvKqQJKFqWlV40PCrk2qhlshVhT

