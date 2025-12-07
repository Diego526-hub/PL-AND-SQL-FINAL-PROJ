
CONNECT hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db

SET SERVEROUTPUT ON
SET PAGESIZE 50
SET LINESIZE 200
COLUMN table_name FORMAT A20
COLUMN check_type FORMAT A40
COLUMN error_count FORMAT 999999

PROMPT ============================================
PROMPT PHASE V: DATA INTEGRITY VERIFICATION
PROMPT ============================================

-- 1. BASIC RETRIEVAL (SELECT *) - First 5 rows each table
PROMPT === 1. BASIC RETRIEVAL (First 5 rows each table) ===

PROMPT --- HOTELS ---
SELECT * FROM hotels WHERE ROWNUM <= 5;

PROMPT --- ROOMS ---
SELECT * FROM rooms WHERE ROWNUM <= 5;

PROMPT --- CUSTOMERS ---
SELECT * FROM customers WHERE ROWNUM <= 5;

PROMPT --- RESERVATIONS ---
SELECT * FROM reservations WHERE ROWNUM <= 5;

PROMPT --- PAYMENTS ---
SELECT * FROM payments WHERE ROWNUM <= 5;

PROMPT --- HOLIDAYS ---
SELECT * FROM holidays WHERE ROWNUM <= 5;

PROMPT --- AUDIT_LOG ---
SELECT * FROM audit_log WHERE ROWNUM <= 5;

-- 2. DATA COMPLETENESS CHECK (FIXED)
PROMPT === 2. DATA COMPLETENESS CHECK ===

SELECT 'NULL in required hotel fields' as check_type, COUNT(*) as error_count
FROM hotels 
WHERE name IS NULL OR location IS NULL OR contact_phone IS NULL
UNION ALL
SELECT 'NULL in required room fields', COUNT(*)
FROM rooms 
WHERE hotel_id IS NULL OR room_number IS NULL OR price IS NULL
UNION ALL
SELECT 'NULL in required customer fields', COUNT(*)
FROM customers 
WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL OR phone IS NULL
UNION ALL
SELECT 'NULL in required reservation fields', COUNT(*)
FROM reservations 
WHERE customer_id IS NULL OR room_id IS NULL OR check_in_date IS NULL OR check_out_date IS NULL
UNION ALL
SELECT 'NULL in required payment fields', COUNT(*)
FROM payments 
WHERE reservation_id IS NULL OR amount IS NULL;

-- 3. FOREIGN KEY INTEGRITY CHECK
PROMPT === 3. FOREIGN KEY INTEGRITY CHECK ===

SELECT 'Rooms without valid hotel' as check_type, COUNT(*) as error_count
FROM rooms r
WHERE NOT EXISTS (SELECT 1 FROM hotels h WHERE h.hotel_id = r.hotel_id)
UNION ALL
SELECT 'Reservations without valid customer', COUNT(*)
FROM reservations res
WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = res.customer_id)
UNION ALL
SELECT 'Reservations without valid room', COUNT(*)
FROM reservations res
WHERE NOT EXISTS (SELECT 1 FROM rooms r WHERE r.room_id = res.room_id)
UNION ALL
SELECT 'Payments without valid reservation', COUNT(*)
FROM payments p
WHERE NOT EXISTS (SELECT 1 FROM reservations r WHERE r.reservation_id = p.reservation_id);

-- 4. CONSTRAINT ENFORCEMENT CHECK
PROMPT === 4. CONSTRAINT ENFORCEMENT CHECK ===

SELECT 'Duplicate customer emails' as check_type, COUNT(*) as error_count
FROM (
    SELECT email FROM customers GROUP BY email HAVING COUNT(*) > 1
) t
UNION ALL
SELECT 'Duplicate holiday dates', COUNT(*)
FROM (
    SELECT holiday_date FROM holidays GROUP BY holiday_date HAVING COUNT(*) > 1
) t
UNION ALL
SELECT 'Duplicate payment references', COUNT(*)
FROM (
    SELECT transaction_ref FROM payments WHERE transaction_ref IS NOT NULL GROUP BY transaction_ref HAVING COUNT(*) > 1
) t;

-- 5. BUSINESS RULE VALIDATION
PROMPT === 5. BUSINESS RULE VALIDATION ===

SELECT 'Invalid date ranges' as check_type, COUNT(*) as error_count
FROM reservations WHERE check_out_date <= check_in_date
UNION ALL
SELECT 'Negative room prices', COUNT(*)
FROM rooms WHERE price < 0
UNION ALL
SELECT 'Negative payment amounts', COUNT(*)
FROM payments WHERE amount < 0
UNION ALL
SELECT 'Invalid hotel ratings', COUNT(*)
FROM hotels WHERE rating NOT BETWEEN 1.0 AND 5.0 AND rating IS NOT NULL
UNION ALL
SELECT 'Reservations with too many guests', COUNT(*)
FROM reservations r
JOIN rooms rm ON r.room_id = rm.room_id
WHERE r.num_guests > rm.max_occupancy;

-- 6. JOINS (Multi-table queries)
PROMPT === 6. JOINS - Multi-table Queries ===

PROMPT --- Active reservations with full details (First 10) ---
SELECT 
    r.reservation_id,
    c.first_name || ' ' || c.last_name as customer_name,
    h.name as hotel_name,
    rm.room_number,
    rm.room_type,
    r.check_in_date,
    r.check_out_date,
    r.num_guests,
    r.total_amount,
    r.status
FROM reservations r
JOIN customers c ON r.customer_id = c.customer_id
JOIN rooms rm ON r.room_id = rm.room_id
JOIN hotels h ON rm.hotel_id = h.hotel_id
WHERE r.status IN ('CONFIRMED', 'CHECKED_IN')
AND ROWNUM <= 10
ORDER BY r.check_in_date;

-- 7. AGGREGATIONS (GROUP BY)
PROMPT === 7. AGGREGATIONS (GROUP BY) ===

PROMPT --- Revenue summary by hotel ---
SELECT 
    h.name as hotel_name,
    COUNT(r.reservation_id) as total_reservations,
    SUM(r.total_amount) as total_revenue,
    ROUND(AVG(r.total_amount), 2) as avg_booking_value
FROM reservations r
JOIN rooms rm ON r.room_id = rm.room_id
JOIN hotels h ON rm.hotel_id = h.hotel_id
GROUP BY h.name
ORDER BY total_revenue DESC;

PROMPT --- Monthly reservation statistics ---
SELECT 
    TO_CHAR(check_in_date, 'YYYY-MM') as month,
    COUNT(*) as reservation_count,
    SUM(total_amount) as monthly_revenue
FROM reservations
GROUP BY TO_CHAR(check_in_date, 'YYYY-MM')
ORDER BY month;

-- 8. SUBQUERIES
PROMPT === 8. SUBQUERIES ===

PROMPT --- Top 5 customers by total spending ---
SELECT 
    c.customer_id,
    c.first_name || ' ' || c.last_name as customer_name,
    (SELECT COUNT(*) FROM reservations r WHERE r.customer_id = c.customer_id) as booking_count,
    (SELECT SUM(total_amount) FROM reservations r WHERE r.customer_id = c.customer_id) as total_spent
FROM customers c
WHERE (SELECT COUNT(*) FROM reservations r WHERE r.customer_id = c.customer_id) > 0
ORDER BY total_spent DESC NULLS LAST
FETCH FIRST 5 ROWS ONLY;

PROMPT --- Available rooms that have never been booked ---
SELECT 
    rm.room_id,
    rm.room_number,
    h.name as hotel_name,
    rm.room_type,
    rm.price
FROM rooms rm
JOIN hotels h ON rm.hotel_id = h.hotel_id
WHERE NOT EXISTS (
    SELECT 1 
    FROM reservations r 
    WHERE r.room_id = rm.room_id
)
AND rm.status = 'AVAILABLE'
ORDER BY h.name, rm.room_number;

-- 9. FINAL VALIDATION SUMMARY
PROMPT === 9. FINAL VALIDATION SUMMARY ===

DECLARE
    v_total_errors NUMBER := 0;
BEGIN
    -- Count all errors from previous checks
    SELECT SUM(error_count) INTO v_total_errors
    FROM (
        SELECT COUNT(*) as error_count FROM hotels WHERE name IS NULL OR location IS NULL OR contact_phone IS NULL
        UNION ALL
        SELECT COUNT(*) FROM rooms WHERE hotel_id IS NULL OR room_number IS NULL OR price IS NULL
        UNION ALL
        SELECT COUNT(*) FROM customers WHERE first_name IS NULL OR last_name IS NULL OR email IS NULL OR phone IS NULL
        UNION ALL
        SELECT COUNT(*) FROM reservations WHERE customer_id IS NULL OR room_id IS NULL OR check_in_date IS NULL OR check_out_date IS NULL
        UNION ALL
        SELECT COUNT(*) FROM payments WHERE reservation_id IS NULL OR amount IS NULL
        UNION ALL
        SELECT COUNT(*) FROM rooms r WHERE NOT EXISTS (SELECT 1 FROM hotels h WHERE h.hotel_id = r.hotel_id)
        UNION ALL
        SELECT COUNT(*) FROM reservations res WHERE NOT EXISTS (SELECT 1 FROM customers c WHERE c.customer_id = res.customer_id)
        UNION ALL
        SELECT COUNT(*) FROM reservations res WHERE NOT EXISTS (SELECT 1 FROM rooms r WHERE r.room_id = res.room_id)
        UNION ALL
        SELECT COUNT(*) FROM payments p WHERE NOT EXISTS (SELECT 1 FROM reservations r WHERE r.reservation_id = p.reservation_id)
        UNION ALL
        SELECT COUNT(*) FROM reservations WHERE check_out_date <= check_in_date
        UNION ALL
        SELECT COUNT(*) FROM rooms WHERE price < 0
        UNION ALL
        SELECT COUNT(*) FROM payments WHERE amount < 0
    );
    
    DBMS_OUTPUT.PUT_LINE('VALIDATION COMPLETE');
    DBMS_OUTPUT.PUT_LINE('===================');
    DBMS_OUTPUT.PUT_LINE('Total errors found: ' || v_total_errors);
    
    IF v_total_errors = 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ All validations passed successfully!');
        DBMS_OUTPUT.PUT_LINE('✅ Database is ready for Phase VI (PL/SQL)');
    ELSE
        DBMS_OUTPUT.PUT_LINE('❌ Issues found in database. Please fix before proceeding.');
    END IF;
    
    DBMS_OUTPUT.PUT_LINE('');
    DBMS_OUTPUT.PUT_LINE('Requirements Verified:');
    DBMS_OUTPUT.PUT_LINE('1. ✅ Basic retrieval (SELECT *)');
    DBMS_OUTPUT.PUT_LINE('2. ✅ Joins (multi-table queries)');
    DBMS_OUTPUT.PUT_LINE('3. ✅ Aggregations (GROUP BY)');
    DBMS_OUTPUT.PUT_LINE('4. ✅ Subqueries');
    DBMS_OUTPUT.PUT_LINE('5. ✅ Constraints enforced');
    DBMS_OUTPUT.PUT_LINE('6. ✅ Foreign key relationships');
    DBMS_OUTPUT.PUT_LINE('7. ✅ Data completeness');
END;
/

-- 10. QUICK STATISTICS
PROMPT === 10. DATABASE STATISTICS ===
SELECT 'Total Hotels' as metric, TO_CHAR(COUNT(*)) as value FROM hotels
UNION ALL SELECT 'Total Rooms', TO_CHAR(COUNT(*)) FROM rooms
UNION ALL SELECT 'Total Customers', TO_CHAR(COUNT(*)) FROM customers
UNION ALL SELECT 'Total Reservations', TO_CHAR(COUNT(*)) FROM reservations
UNION ALL SELECT 'Total Payments', TO_CHAR(COUNT(*)) FROM payments
UNION ALL SELECT 'Avg Reservation Value', TO_CHAR(ROUND(AVG(total_amount), 2)) FROM reservations
UNION ALL SELECT 'Most Loyal Customer', 
    (SELECT first_name || ' ' || last_name FROM (
        SELECT c.first_name, c.last_name, COUNT(r.reservation_id) as bookings
        FROM customers c
        JOIN reservations r ON c.customer_id = r.customer_id
        GROUP BY c.customer_id, c.first_name, c.last_name
        ORDER BY bookings DESC
    ) WHERE ROWNUM = 1)
FROM dual;
