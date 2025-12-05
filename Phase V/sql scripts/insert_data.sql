-- =============================================
-- SIMPLE INSERT SCRIPT - RUN AFTER CREATING TABLES
-- =============================================

CONNECT hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db

SET SERVEROUTPUT ON

-- 1. HOTELS (3 rows)
BEGIN
    INSERT INTO hotels (hotel_id, name, location, rating, contact_phone, email, created_date) 
    VALUES (seq_hotels.NEXTVAL, 'Kigali Serena Hotel', 'KN 3 Ave, Kigali', 4.8, '+250788123456', 'serena@email.com', SYSDATE);
    
    INSERT INTO hotels (hotel_id, name, location, rating, contact_phone, email, created_date) 
    VALUES (seq_hotels.NEXTVAL, 'Radisson Blu Hotel', 'KG 624 St, Kigali', 4.5, '+250788234567', 'radisson@email.com', SYSDATE);
    
    INSERT INTO hotels (hotel_id, name, location, rating, contact_phone, email, created_date) 
    VALUES (seq_hotels.NEXTVAL, 'Lake Kivu Serena Hotel', 'Rubavu, Western Province', 4.3, '+250788345678', 'kivu@email.com', SYSDATE);
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('3 hotels inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting hotels: ' || SQLERRM);
END;
/

-- 2. ROOMS (30 rows)
BEGIN
    FOR i IN 1..10 LOOP
        -- Hotel 1 rooms
        INSERT INTO rooms (room_id, hotel_id, room_number, room_type, price, status, max_occupancy, amenities)
        VALUES (seq_rooms.NEXTVAL, 100, '10' || i, 'STANDARD', 50000, 'AVAILABLE', 2, 'WiFi, AC');
        
        -- Hotel 2 rooms  
        INSERT INTO rooms (room_id, hotel_id, room_number, room_type, price, status, max_occupancy, amenities)
        VALUES (seq_rooms.NEXTVAL, 101, '20' || i, 'DELUXE', 75000, 'AVAILABLE', 2, 'WiFi, AC, TV');
        
        -- Hotel 3 rooms
        INSERT INTO rooms (room_id, hotel_id, room_number, room_type, price, status, max_occupancy, amenities)
        VALUES (seq_rooms.NEXTVAL, 102, '30' || i, 'SUITE', 100000, 'AVAILABLE', 4, 'WiFi, AC, Mini-bar, View');
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('30 rooms inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting rooms: ' || SQLERRM);
END;
/

-- 3. CUSTOMERS (100 rows)
BEGIN
    FOR i IN 1..100 LOOP
        INSERT INTO customers (customer_id, first_name, last_name, email, phone, nationality, loyalty_tier, registration_date)
        VALUES (
            seq_customers.NEXTVAL,
            CASE MOD(i, 5) 
                WHEN 0 THEN 'James' WHEN 1 THEN 'Mary' WHEN 2 THEN 'John' 
                WHEN 3 THEN 'Sarah' ELSE 'David' 
            END,
            CASE MOD(i, 5) 
                WHEN 0 THEN 'Smith' WHEN 1 THEN 'Johnson' WHEN 2 THEN 'Williams' 
                WHEN 3 THEN 'Brown' ELSE 'Jones' 
            END,
            'customer' || i || '@rwanda.com',
            '+25078' || LPAD(100000 + i, 6, '0'),
            CASE MOD(i, 3) WHEN 0 THEN 'RWANDAN' WHEN 1 THEN 'KENYAN' ELSE 'UGANDAN' END,
            CASE 
                WHEN i <= 5 THEN 'PLATINUM'
                WHEN i <= 15 THEN 'GOLD'
                WHEN i <= 30 THEN 'SILVER'
                ELSE 'STANDARD'
            END,
            SYSDATE - MOD(i, 365)
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('100 customers inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting customers: ' || SQLERRM);
END;
/

-- 4. RESERVATIONS (150 rows)
BEGIN
    FOR i IN 1..150 LOOP
        INSERT INTO reservations (
            reservation_id, customer_id, room_id, check_in_date, check_out_date,
            num_guests, status, total_amount, created_date, created_by
        ) VALUES (
            seq_reservations.NEXTVAL,
            5000 + MOD(i, 100),  -- Customer IDs from 5000-5099
            1000 + MOD(i, 30),   -- Room IDs from 1000-1029
            SYSDATE - MOD(i, 180),  -- Dates in last 6 months
            SYSDATE - MOD(i, 180) + CASE MOD(i, 4) WHEN 0 THEN 7 WHEN 1 THEN 3 ELSE 2 END,
            CASE MOD(i, 3) WHEN 0 THEN 1 WHEN 1 THEN 2 ELSE 3 END,
            CASE MOD(i, 10) 
                WHEN 0 THEN 'CANCELLED'
                WHEN 1 THEN 'CHECKED_OUT'
                WHEN 2 THEN 'CHECKED_IN'
                WHEN 3 THEN 'CONFIRMED'
                ELSE 'PENDING'
            END,
            CASE MOD(i, 4) 
                WHEN 0 THEN 50000 * 2
                WHEN 1 THEN 75000 * 3
                WHEN 2 THEN 100000 * 7
                ELSE 50000
            END,
            SYSDATE - MOD(i, 180),
            'staff_' || MOD(i, 3)
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('150 reservations inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting reservations: ' || SQLERRM);
END;
/

-- 5. PAYMENTS (120 rows)
BEGIN
    FOR i IN 1..120 LOOP
        INSERT INTO payments (
            payment_id, reservation_id, amount, payment_date, 
            payment_method, transaction_ref, status
        ) VALUES (
            seq_payments.NEXTVAL,
            10000 + MOD(i, 150),  -- Reservation IDs from 10000-10149
            CASE MOD(i, 4) 
                WHEN 0 THEN 50000
                WHEN 1 THEN 75000
                WHEN 2 THEN 100000
                ELSE 125000
            END,
            SYSDATE - MOD(i, 30),
            CASE MOD(i, 4)
                WHEN 0 THEN 'CASH'
                WHEN 1 THEN 'CREDIT_CARD'
                WHEN 2 THEN 'MOBILE_MONEY'
                ELSE 'BANK_TRANSFER'
            END,
            'PAY-' || TO_CHAR(SYSDATE, 'YYYYMMDD') || '-' || LPAD(i, 6, '0'),
            'COMPLETED'
        );
    END LOOP;
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('120 payments inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting payments: ' || SQLERRM);
END;
/

-- 6. HOLIDAYS (5 rows)
BEGIN
    INSERT INTO holidays (holiday_id, holiday_date, holiday_name, country, is_recurring)
    SELECT seq_holidays.NEXTVAL, holiday_date, holiday_name, 'RWANDA', 'Y'
    FROM (
        SELECT DATE '2024-01-01' as holiday_date, 'New Year''s Day' as holiday_name FROM dual UNION ALL
        SELECT DATE '2024-02-01', 'Heroes Day' FROM dual UNION ALL
        SELECT DATE '2024-04-07', 'Genocide Memorial Day' FROM dual UNION ALL
        SELECT DATE '2024-07-01', 'Independence Day' FROM dual UNION ALL
        SELECT DATE '2024-12-25', 'Christmas Day' FROM dual
    ) h
    WHERE NOT EXISTS (
        SELECT 1 FROM holidays hol WHERE hol.holiday_date = h.holiday_date
    );
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Holidays inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting holidays: ' || SQLERRM);
END;
/

-- 7. AUDIT_LOG (3 rows)
BEGIN
    INSERT INTO audit_log (log_id, user_id, action, table_name, record_id, timestamp, status)
    VALUES (seq_audit_log.NEXTVAL, 'staff_1', 'INSERT', 'RESERVATIONS', '10001', SYSTIMESTAMP, 'SUCCESS');
    
    INSERT INTO audit_log (log_id, user_id, action, table_name, record_id, timestamp, status)
    VALUES (seq_audit_log.NEXTVAL, 'staff_2', 'UPDATE', 'ROOMS', '1001', SYSTIMESTAMP, 'DENIED');
    
    INSERT INTO audit_log (log_id, user_id, action, table_name, record_id, timestamp, status)
    VALUES (seq_audit_log.NEXTVAL, 'staff_3', 'DELETE', 'RESERVATIONS', '10050', SYSTIMESTAMP, 'DENIED');
    
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('3 audit logs inserted');
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error inserting audit logs: ' || SQLERRM);
END;
/

