-- =============================================
-- AUDIT QUERIES
-- For Phase VII requirement monitoring
-- =============================================

-- 1. AUDIT LOG REVIEW
-- View all audit entries
SELECT 
    log_id,
    user_id,
    action,
    table_name,
    record_id,
    TO_CHAR(timestamp, 'DD-MON-YYYY HH24:MI:SS') as action_time,
    status,
    error_message
FROM audit_log
ORDER BY timestamp DESC;

-- 2. UNAUTHORIZED ACCESS ATTEMPTS
-- Show all denied operations
SELECT 
    user_id,
    action,
    table_name,
    COUNT(*) as attempt_count,
    MIN(timestamp) as first_attempt,
    MAX(timestamp) as last_attempt
FROM audit_log
WHERE status = 'DENIED'
GROUP BY user_id, action, table_name
ORDER BY attempt_count DESC;

-- 3. WEEKDAY/HOLIDAY RESTRICTION VIOLATIONS
-- Check attempts on restricted days (for Phase VII)
SELECT 
    al.user_id,
    al.action,
    al.table_name,
    TO_CHAR(al.timestamp, 'Day') as day_of_week,
    TO_CHAR(al.timestamp, 'DD-MON-YYYY') as attempt_date,
    al.status,
    CASE 
        WHEN h.holiday_name IS NOT NULL THEN 'HOLIDAY: ' || h.holiday_name
        WHEN TO_CHAR(al.timestamp, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN 'WEEKDAY'
        ELSE 'WEEKEND'
    END as restriction_type
FROM audit_log al
LEFT JOIN holidays h ON TRUNC(al.timestamp) = h.holiday_date
WHERE al.status = 'DENIED'
ORDER BY al.timestamp DESC;

-- 4. USER ACTIVITY MONITORING
-- User activity summary
SELECT 
    user_id,
    COUNT(*) as total_actions,
    SUM(CASE WHEN status = 'SUCCESS' THEN 1 ELSE 0 END) as successful_actions,
    SUM(CASE WHEN status = 'DENIED' THEN 1 ELSE 0 END) as denied_actions,
    SUM(CASE WHEN status = 'ERROR' THEN 1 ELSE 0 END) as error_actions,
    MIN(timestamp) as first_action,
    MAX(timestamp) as last_action
FROM audit_log
GROUP BY user_id
ORDER BY total_actions DESC;

-- 5. TABLE-LEVEL AUDIT SUMMARY
-- Which tables are most frequently accessed/changed
SELECT 
    table_name,
    action,
    COUNT(*) as operation_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) as percentage_of_total
FROM audit_log
GROUP BY table_name, action
ORDER BY table_name, operation_count DESC;

-- 6. TIME-BASED AUDIT ANALYSIS
-- Audit activity by hour of day
SELECT 
    EXTRACT(HOUR FROM timestamp) as hour_of_day,
    COUNT(*) as audit_count,
    SUM(CASE WHEN status = 'DENIED' THEN 1 ELSE 0 END) as denied_count,
    ROUND(SUM(CASE WHEN status = 'DENIED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as denial_rate
FROM audit_log
GROUP BY EXTRACT(HOUR FROM timestamp)
ORDER BY hour_of_day;

-- 7. PATTERN DETECTION
-- Detect suspicious patterns (multiple rapid denials)
WITH user_attempts AS (
    SELECT 
        user_id,
        timestamp,
        LAG(timestamp) OVER (PARTITION BY user_id ORDER BY timestamp) as prev_timestamp
    FROM audit_log
    WHERE status = 'DENIED'
)
SELECT 
    user_id,
    COUNT(*) as rapid_denials,
    MIN(timestamp) as first_denial,
    MAX(timestamp) as last_denial
FROM user_attempts
WHERE timestamp - prev_timestamp < INTERVAL '5' MINUTE
GROUP BY user_id
HAVING COUNT(*) >= 3
ORDER BY rapid_denials DESC;

-- 8. COMPLIANCE REPORTING
-- Generate compliance report for Phase VII requirement
SELECT 
    'Phase VII Compliance Report' as report_title,
    TO_CHAR(SYSDATE, 'DD-MON-YYYY HH24:MI:SS') as report_time
FROM dual;

SELECT 
    'Total Audit Records' as metric,
    COUNT(*) as value
FROM audit_log
UNION ALL
SELECT 'Weekday Restriction Violations',
       COUNT(*)
FROM audit_log al
WHERE status = 'DENIED'
AND TO_CHAR(al.timestamp, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI')
UNION ALL
SELECT 'Holiday Restriction Violations',
       COUNT(*)
FROM audit_log al
JOIN holidays h ON TRUNC(al.timestamp) = h.holiday_date
WHERE al.status = 'DENIED'
UNION ALL
SELECT 'Successful Operations',
       COUNT(*)
FROM audit_log
WHERE status = 'SUCCESS'
UNION ALL
SELECT 'Compliance Rate',
       ROUND((COUNT(CASE WHEN status = 'SUCCESS' THEN 1 END) * 100.0 / COUNT(*)), 2)
FROM audit_log;

-- 9. DETAILED AUDIT TRAIL FOR SPECIFIC RECORDS
-- Track all changes to a specific reservation
SELECT 
    al.log_id,
    al.user_id,
    al.action,
    TO_CHAR(al.timestamp, 'DD-MON-YYYY HH24:MI:SS') as change_time,
    al.status,
    al.old_values,
    al.new_values
FROM audit_log al
WHERE al.table_name = 'RESERVATIONS'
AND al.record_id LIKE '%1000%'  -- Change this to specific ID
ORDER BY al.timestamp DESC;

-- 10. AUDIT DATA CLEANUP & MAINTENANCE
-- Identify old audit records (older than 90 days)
SELECT 
    TO_CHAR(timestamp, 'YYYY-MM') as month,
    COUNT(*) as record_count,
    ROUND(SUM(CASE WHEN status = 'DENIED' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) as denial_percentage
FROM audit_log
WHERE timestamp < SYSDATE - 90
GROUP BY TO_CHAR(timestamp, 'YYYY-MM')
ORDER BY month;

-- 11. REAL-TIME MONITORING QUERY
-- Current hour audit activity
SELECT 
    user_id,
    action,
    table_name,
    COUNT(*) as actions_last_hour,
    SUM(CASE WHEN status = 'DENIED' THEN 1 ELSE 0 END) as denials_last_hour
FROM audit_log
WHERE timestamp >= SYSDATE - (1/24)  -- Last hour
GROUP BY user_id, action, table_name
ORDER BY actions_last_hour DESC;

-- 12. AUDIT EXCEPTION REPORT
-- Generate exception report for management
SELECT 
    'AUDIT EXCEPTION REPORT' as report_type,
    TO_CHAR(SYSDATE, 'DD-MON-YYYY') as report_date
FROM dual;

SELECT 
    al.user_id,
    al.action,
    al.table_name,
    TO_CHAR(al.timestamp, 'DD-MON-YYYY HH24:MI') as exception_time,
    al.error_message,
    CASE 
        WHEN h.holiday_name IS NOT NULL THEN 'Holiday Violation: ' || h.holiday_name
        WHEN TO_CHAR(al.timestamp, 'DY') IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN 'Weekday Violation'
        ELSE 'Other Restriction'
    END as violation_type
FROM audit_log al
LEFT JOIN holidays h ON TRUNC(al.timestamp) = h.holiday_date
WHERE al.status = 'DENIED'
AND al.timestamp >= SYSDATE - 7  -- Last 7 days
ORDER BY al.timestamp DESC;
