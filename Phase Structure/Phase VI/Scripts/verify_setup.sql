

-- Test 1: Verify database connection
SELECT '✅ Connected to: ' || name || 
       ' | Open Mode: ' || open_mode as database_info
FROM v$database;

-- Test 2: Verify user and privileges
SELECT '✅ Current User: ' || USER as user_info FROM dual;

SELECT '✅ Has DBA Role: ' || 
       CASE WHEN 'DBA' IN (
         SELECT granted_role FROM user_role_privs
       ) THEN 'YES' ELSE 'NO' END as dba_check
FROM dual;

-- Test 3: Verify tablespaces
SELECT '✅ Tablespace: ' || tablespace_name || 
       ' | Contents: ' || contents as tablespace_info
FROM user_tablespaces
ORDER BY tablespace_name;

-- Test 4: Create and test a table
CREATE TABLE verification_test (
    test_id NUMBER PRIMARY KEY,
    test_name VARCHAR2(50),
    test_date DATE DEFAULT SYSDATE
) TABLESPACE hotel_data;

INSERT INTO verification_test (test_id, test_name) 
VALUES (1, 'Database Setup Verification');

COMMIT;

SELECT '✅ Test Completed: ' || test_name || 
       ' on ' || TO_CHAR(test_date, 'DD-MON-YYYY HH24:MI') as test_result
FROM verification_test;

-- Cleanup
DROP TABLE verification_test;

-- Final success message
SELECT '========================================' as line FROM dual;
SELECT '✅ DATABASE SETUP VERIFIED SUCCESSFULLY' as status FROM dual;
SELECT '========================================' as line FROM dual;
SELECT 'Database: tue_27395_diego_hotel_db' as info FROM dual;
SELECT 'Admin User: hotel_admin/diego' as info FROM dual;
SELECT 'Connection String:' as info FROM dual;
SELECT '  hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db' as info FROM dual;
SELECT '========================================' as line FROM dual;
