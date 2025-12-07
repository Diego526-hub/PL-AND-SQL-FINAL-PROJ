-- =============================================
-- DATA RETRIEVAL QUERIES
-- Basic SELECT operations for hotel system
-- =============================================

-- 1. BASIC RETRIEVAL (SELECT * from all tables)
-- Get all hotels
SELECT * FROM hotels ORDER BY hotel_id;

-- Get all available rooms
SELECT * FROM rooms WHERE status = 'AVAILABLE' ORDER BY price;

-- Get all customers
SELECT customer_id, first_name || ' ' || last_name as full_name, 
       email, phone, loyalty_tier
FROM customers ORDER BY last_name, first_name;

-- Get active reservations
SELECT * FROM reservations 
WHERE status IN ('CONFIRMED', 'CHECKED_IN')
ORDER BY check_in_date;

-- 2. SINGLE TABLE QUERIES WITH CONDITIONS
-- Find rooms by type and price range
SELECT room_id, room_number, room_type, price, amenities
FROM rooms 
WHERE room_type = 'DELUXE' 
AND price BETWEEN 70000 AND 120000
AND status = 'AVAILABLE'
ORDER BY price;

-- Find customers by loyalty tier
SELECT customer_id, first_name, last_name, email, 
       registration_date, loyalty_tier
FROM customers 
WHERE loyalty_tier IN ('GOLD', 'PLATINUM')
ORDER BY loyalty_tier, last_name;

-- Find reservations for a specific date
SELECT reservation_id, customer_id, room_id, 
       check_in_date, check_out_date, total_amount, status
FROM reservations
WHERE check_in_date <= DATE '2024-12-15'
AND check_out_date >= DATE '2024-12-15'
ORDER BY check_in_date;

-- 3. DATA FILTERING AND SORTING
-- Top 10 highest paying reservations
SELECT reservation_id, customer_id, total_amount, 
       check_in_date, check_out_date, status
FROM reservations
WHERE total_amount > 0
ORDER BY total_amount DESC
FETCH FIRST 10 ROWS ONLY;

-- Rooms needing maintenance
SELECT room_id, room_number, hotel_id, room_type
FROM rooms
WHERE status = 'MAINTENANCE'
ORDER BY hotel_id, room_number;

-- Upcoming reservations (next 7 days)
SELECT reservation_id, customer_id, room_id,
       check_in_date, check_out_date, num_guests, status
FROM reservations
WHERE check_in_date BETWEEN SYSDATE AND SYSDATE + 7
AND status = 'CONFIRMED'
ORDER BY check_in_date;

-- 4. SIMPLE JOINS
-- Reservation details with customer names
SELECT r.reservation_id, 
       c.first_name || ' ' || c.last_name as customer_name,
       c.email, c.phone,
       r.check_in_date, r.check_out_date, r.total_amount, r.status
FROM reservations r
JOIN customers c ON r.customer_id = c.customer_id
WHERE r.status = 'CONFIRMED'
ORDER BY r.check_in_date;

-- Room details with hotel information
SELECT r.room_id, r.room_number, r.room_type, r.price, r.status,
       h.name as hotel_name, h.location, h.rating
FROM rooms r
JOIN hotels h ON r.hotel_id = h.hotel_id
WHERE r.status = 'AVAILABLE'
ORDER BY h.name, r.room_type, r.price;

-- 5. AGGREGATE QUERIES (Basic)
-- Count reservations by status
SELECT status, COUNT(*) as reservation_count
FROM reservations
GROUP BY status
ORDER BY reservation_count DESC;

-- Average room price by type
SELECT room_type, 
       COUNT(*) as room_count,
       AVG(price) as avg_price,
       MIN(price) as min_price,
       MAX(price) as max_price
FROM rooms
GROUP BY room_type
ORDER BY avg_price DESC;

-- Total revenue by month
SELECT TO_CHAR(check_in_date, 'YYYY-MM') as month,
       COUNT(*) as reservations,
       SUM(total_amount) as total_revenue,
       AVG(total_amount) as avg_booking_value
FROM reservations
GROUP BY TO_CHAR(check_in_date, 'YYYY-MM')
ORDER BY month;

-- 6. SUBQUERIES
-- Customers with more than 2 reservations
SELECT c.customer_id, c.first_name, c.last_name, c.email,
       (SELECT COUNT(*) FROM reservations r 
        WHERE r.customer_id = c.customer_id) as total_bookings,
       (SELECT SUM(total_amount) FROM reservations r 
        WHERE r.customer_id = c.customer_id) as total_spent
FROM customers c
WHERE (SELECT COUNT(*) FROM reservations r 
       WHERE r.customer_id = c.customer_id) > 2
ORDER BY total_spent DESC;

-- Rooms that have never been booked
SELECT r.room_id, r.room_number, h.name as hotel_name, 
       r.room_type, r.price
FROM rooms r
JOIN hotels h ON r.hotel_id = h.hotel_id
WHERE NOT EXISTS (
    SELECT 1 FROM reservations res 
    WHERE res.room_id = r.room_id
)
ORDER BY hotel_name, room_number;

-- 7. DATA VALIDATION QUERIES
-- Check for data integrity issues
SELECT 'Reservations with invalid dates' as issue_type,
       COUNT(*) as error_count
FROM reservations
WHERE check_out_date <= check_in_date
UNION ALL
SELECT 'Rooms with invalid status',
       COUNT(*)
FROM rooms
WHERE status NOT IN ('AVAILABLE', 'RESERVED', 'OCCUPIED', 'MAINTENANCE', 'DIRTY')
UNION ALL
SELECT 'Customers without email',
       COUNT(*)
FROM customers
WHERE email IS NULL OR email NOT LIKE '%@%';

-- 8. UTILITY QUERIES
-- Generate hotel room inventory
SELECT h.name as hotel_name,
       COUNT(*) as total_rooms,
       SUM(CASE WHEN r.status = 'AVAILABLE' THEN 1 ELSE 0 END) as available_rooms,
       SUM(CASE WHEN r.status = 'OCCUPIED' THEN 1 ELSE 0 END) as occupied_rooms,
       SUM(CASE WHEN r.status = 'RESERVED' THEN 1 ELSE 0 END) as reserved_rooms
FROM hotels h
JOIN rooms r ON h.hotel_id = r.hotel_id
GROUP BY h.name, h.hotel_id
ORDER BY hotel_name;
