-- =============================================
-- CREATE SEQUENCES AND INDEXES
-- =============================================

CONNECT hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db

-- SEQUENCES for Primary Keys
CREATE SEQUENCE seq_hotels START WITH 100 INCREMENT BY 1;
CREATE SEQUENCE seq_rooms START WITH 1000 INCREMENT BY 1;
CREATE SEQUENCE seq_customers START WITH 5000 INCREMENT BY 1;
CREATE SEQUENCE seq_reservations START WITH 10000 INCREMENT BY 1;
CREATE SEQUENCE seq_payments START WITH 20000 INCREMENT BY 1;
CREATE SEQUENCE seq_holidays START WITH 1 INCREMENT BY 1;
CREATE SEQUENCE seq_audit_log START WITH 1 INCREMENT BY 1;

-- INDEXES for Performance
-- Reservations indexes
CREATE INDEX idx_reservations_dates ON reservations(check_in_date, check_out_date);
CREATE INDEX idx_reservations_status ON reservations(status);
CREATE INDEX idx_reservations_customer ON reservations(customer_id);

-- Rooms indexes
CREATE INDEX idx_rooms_hotel ON rooms(hotel_id);
CREATE INDEX idx_rooms_status ON rooms(status);
CREATE INDEX idx_rooms_type ON rooms(room_type);

-- Customers indexes
CREATE INDEX idx_customers_email ON customers(email);
CREATE INDEX idx_customers_name ON customers(last_name, first_name);

-- Payments indexes
CREATE INDEX idx_payments_date ON payments(payment_date);
CREATE INDEX idx_payments_reservation ON payments(reservation_id);

-- Audit log indexes
CREATE INDEX idx_audit_timestamp ON audit_log(timestamp);
CREATE INDEX idx_audit_user ON audit_log(user_id);

-- Display all sequences and indexes
SELECT sequence_name FROM user_sequences ORDER BY sequence_name;
SELECT index_name, table_name FROM user_indexes ORDER BY table_name, index_name;
