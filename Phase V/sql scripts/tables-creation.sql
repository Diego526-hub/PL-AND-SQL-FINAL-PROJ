-- 1. HOTELS TABLE
CREATE TABLE hotels (
    hotel_id NUMBER(5) PRIMARY KEY,
    name VARCHAR2(100) NOT NULL,
    location VARCHAR2(200) NOT NULL,
    rating NUMBER(2,1) CHECK (rating BETWEEN 1.0 AND 5.0),
    contact_phone VARCHAR2(20) NOT NULL,
    email VARCHAR2(100),
    created_date DATE DEFAULT SYSDATE
);

-- 2. ROOMS TABLE
CREATE TABLE rooms (
    room_id NUMBER(10) PRIMARY KEY,
    hotel_id NUMBER(5) NOT NULL,
    room_number VARCHAR2(10) NOT NULL,
    room_type VARCHAR2(20) DEFAULT 'STANDARD' 
        CHECK (room_type IN ('STANDARD', 'DELUXE', 'SUITE', 'FAMILY')),
    price NUMBER(10,2) NOT NULL CHECK (price > 0),
    status VARCHAR2(20) DEFAULT 'AVAILABLE' 
        CHECK (status IN ('AVAILABLE', 'RESERVED', 'OCCUPIED', 'MAINTENANCE')),
    max_occupancy NUMBER(2) DEFAULT 2 CHECK (max_occupancy BETWEEN 1 AND 10),
    amenities VARCHAR2(500),
    CONSTRAINT fk_rooms_hotel FOREIGN KEY (hotel_id) REFERENCES hotels(hotel_id)
);

-- 3. CUSTOMERS TABLE
CREATE TABLE customers (
    customer_id NUMBER(10) PRIMARY KEY,
    first_name VARCHAR2(50) NOT NULL,
    last_name VARCHAR2(50) NOT NULL,
    email VARCHAR2(100) UNIQUE NOT NULL,
    phone VARCHAR2(20) NOT NULL,
    nationality VARCHAR2(50) DEFAULT 'RWANDAN',
    loyalty_tier VARCHAR2(20) DEFAULT 'STANDARD' 
        CHECK (loyalty_tier IN ('STANDARD', 'SILVER', 'GOLD', 'PLATINUM')),
    registration_date DATE DEFAULT SYSDATE
);

-- 4. RESERVATIONS TABLE (Main Fact Table)
CREATE TABLE reservations (
    reservation_id NUMBER(15) PRIMARY KEY,
    customer_id NUMBER(10) NOT NULL,
    room_id NUMBER(10) NOT NULL,
    check_in_date DATE NOT NULL,
    check_out_date DATE NOT NULL,
    num_guests NUMBER(2) DEFAULT 1 CHECK (num_guests BETWEEN 1 AND 10),
    status VARCHAR2(20) DEFAULT 'PENDING' 
        CHECK (status IN ('PENDING', 'CONFIRMED', 'CHECKED_IN', 'CHECKED_OUT', 'CANCELLED')),
    total_amount NUMBER(12,2) DEFAULT 0 CHECK (total_amount >= 0),
    special_requests VARCHAR2(500),
    created_date DATE DEFAULT SYSDATE,
    created_by VARCHAR2(50),
    CONSTRAINT fk_res_customer FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    CONSTRAINT fk_res_room FOREIGN KEY (room_id) REFERENCES rooms(room_id),
    CONSTRAINT chk_dates CHECK (check_out_date > check_in_date)
);

-- 5. PAYMENTS TABLE
CREATE TABLE payments (
    payment_id NUMBER(15) PRIMARY KEY,
    reservation_id NUMBER(15) NOT NULL,
    amount NUMBER(10,2) NOT NULL CHECK (amount > 0),
    payment_date DATE DEFAULT SYSDATE,
    payment_method VARCHAR2(30) DEFAULT 'CASH' 
        CHECK (payment_method IN ('CASH', 'CREDIT_CARD', 'MOBILE_MONEY', 'BANK_TRANSFER')),
    transaction_ref VARCHAR2(100) UNIQUE,
    status VARCHAR2(20) DEFAULT 'COMPLETED' 
        CHECK (status IN ('PENDING', 'COMPLETED', 'FAILED', 'REFUNDED')),
    CONSTRAINT fk_payment_res FOREIGN KEY (reservation_id) REFERENCES reservations(reservation_id)
);

-- 6. HOLIDAYS TABLE (Phase VII Requirement)
CREATE TABLE holidays (
    holiday_id NUMBER(5) PRIMARY KEY,
    holiday_date DATE UNIQUE NOT NULL,
    holiday_name VARCHAR2(100) NOT NULL,
    country VARCHAR2(50) DEFAULT 'RWANDA',
    is_recurring CHAR(1) DEFAULT 'Y' CHECK (is_recurring IN ('Y', 'N'))
);

-- 7. AUDIT_LOG TABLE (Phase VII Requirement)
CREATE TABLE audit_log (
    log_id NUMBER(15) PRIMARY KEY,
    user_id VARCHAR2(50) NOT NULL,
    action VARCHAR2(20) NOT NULL CHECK (action IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT')),
    table_name VARCHAR2(30) NOT NULL,
    record_id VARCHAR2(100) NOT NULL,
    old_values CLOB,
    new_values CLOB,
    timestamp TIMESTAMP DEFAULT SYSTIMESTAMP,
    status VARCHAR2(20) DEFAULT 'DENIED' CHECK (status IN ('SUCCESS', 'DENIED', 'ERROR')),
    error_message VARCHAR2(500)
);
