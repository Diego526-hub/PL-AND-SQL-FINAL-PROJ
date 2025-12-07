-- =============================================
-- ANALYTICS & BI QUERIES
-- Business Intelligence for hotel management
-- =============================================

-- 1. OCCUPANCY ANALYTICS
-- Daily occupancy rate for last 30 days
WITH daily_occupancy AS (
    SELECT 
        TRUNC(r.check_in_date) as date,
        h.hotel_id,
        h.name as hotel_name,
        COUNT(DISTINCT r.room_id) as occupied_rooms,
        (SELECT COUNT(*) FROM rooms rm WHERE rm.hotel_id = h.hotel_id) as total_rooms
    FROM reservations r
    JOIN rooms rm ON r.room_id = rm.room_id
    JOIN hotels h ON rm.hotel_id = h.hotel_id
    WHERE r.status IN ('CHECKED_IN', 'CONFIRMED')
    AND r.check_in_date >= SYSDATE - 30
    GROUP BY TRUNC(r.check_in_date), h.hotel_id, h.name
)
SELECT date, hotel_name,
       occupied_rooms,
       total_rooms,
       ROUND((occupied_rooms / total_rooms) * 100, 2) as occupancy_rate
FROM daily_occupancy
ORDER BY date DESC, occupancy_rate DESC;

-- 2. REVENUE ANALYTICS
-- Revenue by hotel, room type, and month
SELECT 
    h.name as hotel_name,
    rm.room_type,
    TO_CHAR(r.check_in_date, 'YYYY-MM') as month,
    COUNT(r.reservation_id) as booking_count,
    SUM(r.total_amount) as total_revenue,
    AVG(r.total_amount) as avg_revenue_per_booking,
    ROUND(SUM(r.total_amount) / COUNT(DISTINCT TRUNC(r.check_in_date)), 2) as revenue_per_day
FROM reservations r
JOIN rooms rm ON r.room_id = rm.room_id
JOIN hotels h ON rm.hotel_id = h.hotel_id
WHERE r.status != 'CANCELLED'
GROUP BY h.name, rm.room_type, TO_CHAR(r.check_in_date, 'YYYY-MM')
ORDER BY hotel_name, room_type, month;

-- 3. CUSTOMER ANALYTICS
-- Customer segmentation by spending
WITH customer_stats AS (
    SELECT 
        c.customer_id,
        c.first_name || ' ' || c.last_name as customer_name,
        c.loyalty_tier,
        COUNT(r.reservation_id) as total_bookings,
        SUM(r.total_amount) as total_spent,
        AVG(r.total_amount) as avg_booking_value,
        MAX(r.check_in_date) as last_booking_date
    FROM customers c
    LEFT JOIN reservations r ON c.customer_id = r.customer_id
    WHERE r.status != 'CANCELLED' OR r.status IS NULL
    GROUP BY c.customer_id, c.first_name, c.last_name, c.loyalty_tier
)
SELECT 
    loyalty_tier,
    COUNT(*) as customer_count,
    ROUND(AVG(total_spent), 2) as avg_lifetime_value,
    ROUND(AVG(total_bookings), 2) as avg_bookings_per_customer,
    SUM(total_spent) as tier_total_revenue,
    ROUND(SUM(total_spent) * 100 / SUM(SUM(total_spent)) OVER (), 2) as revenue_percentage
FROM customer_stats
GROUP BY loyalty_tier
ORDER BY 
    CASE loyalty_tier 
        WHEN 'PLATINUM' THEN 1
        WHEN 'GOLD' THEN 2
        WHEN 'SILVER' THEN 3
        ELSE 4 
    END;

-- 4. WINDOW FUNCTIONS FOR TREND ANALYSIS
-- Month-over-month growth
WITH monthly_revenue AS (
    SELECT 
        TO_CHAR(check_in_date, 'YYYY-MM') as month,
        SUM(total_amount) as monthly_revenue,
        LAG(SUM(total_amount)) OVER (ORDER BY TO_CHAR(check_in_date, 'YYYY-MM')) as prev_month_revenue
    FROM reservations
    WHERE status != 'CANCELLED'
    GROUP BY TO_CHAR(check_in_date, 'YYYY-MM')
)
SELECT month,
       monthly_revenue,
       prev_month_revenue,
       ROUND(((monthly_revenue - prev_month_revenue) / prev_month_revenue) * 100, 2) as growth_percentage
FROM monthly_revenue
ORDER BY month;

-- 5. PEAK SEASON ANALYSIS
-- Identify peak booking periods
SELECT 
    TO_CHAR(check_in_date, 'MM') as month_number,
    TO_CHAR(check_in_date, 'Month') as month_name,
    COUNT(*) as total_bookings,
    SUM(total_amount) as total_revenue,
    AVG(total_amount) as avg_booking_value,
    RANK() OVER (ORDER BY COUNT(*) DESC) as booking_rank,
    RANK() OVER (ORDER BY SUM(total_amount) DESC) as revenue_rank
FROM reservations
WHERE status != 'CANCELLED'
GROUP BY TO_CHAR(check_in_date, 'MM'), TO_CHAR(check_in_date, 'Month')
ORDER BY month_number;

-- 6. ROOM PERFORMANCE ANALYTICS
-- Room utilization and revenue
SELECT 
    r.room_id,
    r.room_number,
    r.room_type,
    r.price as current_rate,
    h.name as hotel_name,
    COUNT(res.reservation_id) as times_booked,
    SUM(res.total_amount) as revenue_generated,
    AVG(res.total_amount) as avg_revenue_per_booking,
    ROUND(COUNT(res.reservation_id) * 100.0 / (SELECT COUNT(*) FROM reservations), 2) as booking_market_share
FROM rooms r
JOIN hotels h ON r.hotel_id = h.hotel_id
LEFT JOIN reservations res ON r.room_id = res.room_id AND res.status != 'CANCELLED'
GROUP BY r.room_id, r.room_number, r.room_type, r.price, h.name
ORDER BY revenue_generated DESC NULLS LAST;

-- 7. CANCELLATION ANALYSIS
-- Cancellation trends and reasons
SELECT 
    TO_CHAR(created_date, 'YYYY-MM') as month,
    COUNT(*) as total_reservations,
    SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) as cancelled_reservations,
    ROUND(SUM(CASE WHEN status = 'CANCELLED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as cancellation_rate,
    AVG(CASE WHEN status = 'CANCELLED' THEN total_amount ELSE 0 END) as avg_cancelled_amount
FROM reservations
GROUP BY TO_CHAR(created_date, 'YYYY-MM')
ORDER BY month;

-- 8. ADVANCED ANALYTICS WITH COMMON TABLE EXPRESSIONS
-- Customer retention analysis
WITH customer_activity AS (
    SELECT 
        customer_id,
        TO_CHAR(check_in_date, 'YYYY-MM') as activity_month,
        COUNT(*) as monthly_bookings,
        LAG(TO_CHAR(check_in_date, 'YYYY-MM')) OVER (PARTITION BY customer_id ORDER BY TO_CHAR(check_in_date, 'YYYY-MM')) as prev_month
    FROM reservations
    WHERE status != 'CANCELLED'
    GROUP BY customer_id, TO_CHAR(check_in_date, 'YYYY-MM')
)
SELECT 
    activity_month,
    COUNT(DISTINCT customer_id) as active_customers,
    COUNT(DISTINCT CASE WHEN prev_month IS NOT NULL THEN customer_id END) as retained_customers,
    ROUND(COUNT(DISTINCT CASE WHEN prev_month IS NOT NULL THEN customer_id END) * 100.0 / 
          LAG(COUNT(DISTINCT customer_id)) OVER (ORDER BY activity_month), 2) as retention_rate
FROM customer_activity
GROUP BY activity_month
ORDER BY activity_month;

-- 9. PRICE OPTIMIZATION ANALYTICS
-- Price elasticity analysis
SELECT 
    rm.room_type,
    ROUND(AVG(rm.price), 2) as avg_room_price,
    COUNT(res.reservation_id) as bookings_at_price,
    ROUND(AVG(res.total_amount / (res.check_out_date - res.check_in_date)), 2) as avg_daily_rate,
    ROUND(CORR(rm.price, (res.check_out_date - res.check_in_date)), 4) as price_stay_correlation
FROM rooms rm
LEFT JOIN reservations res ON rm.room_id = res.room_id AND res.status != 'CANCELLED'
GROUP BY rm.room_type
ORDER BY avg_room_price DESC;

-- 10. EXECUTIVE DASHBOARD SUMMARY
-- KPI Summary for dashboard
SELECT 
    'Total Hotels' as metric, COUNT(*) as value FROM hotels
UNION ALL
SELECT 'Total Rooms', COUNT(*) FROM rooms
UNION ALL
SELECT 'Total Customers', COUNT(*) FROM customers
UNION ALL
SELECT 'Total Reservations', COUNT(*) FROM reservations
UNION ALL
SELECT 'Total Revenue', SUM(total_amount) FROM reservations WHERE status != 'CANCELLED'
UNION ALL
SELECT 'Current Occupancy Rate', 
       ROUND((SELECT COUNT(DISTINCT room_id) FROM reservations 
              WHERE status IN ('CHECKED_IN') 
              AND SYSDATE BETWEEN check_in_date AND check_out_date) * 100.0 / 
             (SELECT COUNT(*) FROM rooms), 2)
FROM dual
UNION ALL
SELECT 'Average Daily Rate', 
       ROUND(AVG(total_amount / (check_out_date - check_in_date)), 2)
FROM reservations 
WHERE status != 'CANCELLED' 
AND check_out_date > check_in_date
UNION ALL
SELECT 'Customer Satisfaction', 
       ROUND(AVG(CASE WHEN loyalty_tier = 'PLATINUM' THEN 95
                      WHEN loyalty_tier = 'GOLD' THEN 85
                      WHEN loyalty_tier = 'SILVER' THEN 75
                      ELSE 65 END), 2)
FROM customers;
