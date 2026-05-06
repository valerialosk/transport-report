CREATE TABLE Client (
    id_client       SERIAL PRIMARY KEY,
    name            VARCHAR(255) NOT NULL,
    payment_type    VARCHAR(20) CHECK (payment_type IN ('prepayment', 'credit')),
    contact_person  VARCHAR(255),
    phone           VARCHAR(20),
    email           VARCHAR(100)
);

CREATE TABLE Employee (
    id_employee     SERIAL PRIMARY KEY,
    full_name       VARCHAR(255) NOT NULL,
    position        VARCHAR(100) NOT NULL,
    login_lib       VARCHAR(50)
);

CREATE TABLE Vehicle (
    id_vehicle      SERIAL PRIMARY KEY,
    license_plate   VARCHAR(15) NOT NULL UNIQUE,
    model           VARCHAR(100),
    capacity_kg     INTEGER
);

CREATE TABLE Request (
    id_request      SERIAL PRIMARY KEY,
    number          VARCHAR(50) NOT NULL,
    created_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    status          VARCHAR(50) DEFAULT 'черновик',
    id_client       INTEGER NOT NULL REFERENCES Client(id_client),
    id_manager      INTEGER NOT NULL REFERENCES Employee(id_employee),
    cargo_description TEXT,
    route_text      TEXT
);

CREATE TABLE Invoice (
    id_invoice      SERIAL PRIMARY KEY,
    number          VARCHAR(50) NOT NULL,
    id_request      INTEGER NOT NULL REFERENCES Request(id_request),
    amount          DECIMAL(12,2) NOT NULL,
    issue_date      DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_due_date DATE,
    status          VARCHAR(20) DEFAULT 'ожидает оплаты'
);

CREATE TABLE Payment (
    id_payment      SERIAL PRIMARY KEY,
    id_invoice      INTEGER NOT NULL REFERENCES Invoice(id_invoice),
    amount          DECIMAL(12,2) NOT NULL,
    payment_date    DATE NOT NULL DEFAULT CURRENT_DATE,
    payment_method  VARCHAR(50)
);

CREATE TABLE Trip (
    id_trip         SERIAL PRIMARY KEY,
    id_request      INTEGER NOT NULL REFERENCES Request(id_request),
    id_vehicle      INTEGER NOT NULL REFERENCES Vehicle(id_vehicle),
    id_logist       INTEGER NOT NULL REFERENCES Employee(id_employee),
    start_date      DATE,
    end_date        DATE,
    status          VARCHAR(50) DEFAULT 'назначен'
);

-- Индексы для производительности
CREATE INDEX idx_request_client ON Request(id_client);
CREATE INDEX idx_request_manager ON Request(id_manager);
CREATE INDEX idx_invoice_request ON Invoice(id_request);
CREATE INDEX idx_payment_invoice ON Payment(id_invoice);
CREATE INDEX idx_trip_request ON Trip(id_request);
CREATE INDEX idx_trip_vehicle ON Trip(id_vehicle);
CREATE INDEX idx_trip_logist ON Trip(id_logist);
CREATE INDEX idx_invoice_due_date ON Invoice(payment_due_date);