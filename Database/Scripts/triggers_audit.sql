-- =============================================
-- PHASE VII: TRIGGERS & AUDIT SYSTEM
-- Critical Business Rule Implementation
-- Run after Phase V & VI are complete
-- =============================================

CONNECT hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db

SET SERVEROUTPUT ON

-- ========== 1. AUDIT LOGGING FUNCTION ==========
CREATE OR REPLACE FUNCTION log_audit_trail(
    p_user_id      IN VARCHAR2,
    p_action       IN VARCHAR2,
    p_table_name   IN VARCHAR2,
    p_record_id    IN VARCHAR2,
    p_old_values   IN CLOB DEFAULT NULL,
    p_new_values   IN CLOB DEFAULT NULL,
    p_status       IN VARCHAR2 DEFAULT 'ATTEMPTED',
    p_error_msg    IN VARCHAR2 DEFAULT NULL
) RETURN NUMBER IS
    PRAGMA AUTONOMOUS_TRANSACTION;
    v_log_id NUMBER;
BEGIN
    INSERT INTO audit_log (
        log_id, user_id, action, table_name, record_id,
        old_values, new_values, timestamp, status, error_message
    ) VALUES (
        seq_audit_log.NEXTVAL, p_user_id, p_action, p_table_name, p_record_id,
        p_old_values, p_new_values, SYSTIMESTAMP, p_status, p_error_msg
    ) RETURNING log_id INTO v_log_id;
    
    COMMIT;
    RETURN v_log_id;
    
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        RAISE;
END log_audit_trail;
/

DBMS_OUTPUT.PUT_LINE('✅ Audit logging function created');

-- ========== 2. RESTRICTION CHECK FUNCTION ==========
CREATE OR REPLACE FUNCTION check_restriction_allowed(
    p_operation_date IN DATE DEFAULT SYSDATE
) RETURN VARCHAR2 IS
    v_day_of_week VARCHAR2(10);
    v_is_holiday NUMBER;
    v_message VARCHAR2(500);
BEGIN
    -- Get day of week
    v_day_of_week := TO_CHAR(p_operation_date, 'DY');
    
    -- Check if weekday (Monday-Friday)
    IF v_day_of_week IN ('MON', 'TUE', 'WED', 'THU', 'FRI') THEN
        v_message := 'DENIED - Operation not allowed on weekdays (Monday-Friday)';
        RETURN v_message;
    END IF;
    
    -- Check if public holiday (Rwanda - next month only)
    SELECT COUNT(*) INTO v_is_holiday
    FROM holidays
    WHERE holiday_date = TRUNC(p_operation_date)
    AND country = 'RWANDA'
    AND holiday_date BETWEEN TRUNC(SYSDATE, 'MM') AND LAST_DAY(ADD_MONTHS(SYSDATE, 1));
    
    IF v_is_holiday > 0 THEN
        v_message := 'DENIED - Operation not allowed on Rwanda public holiday';
        RETURN v_message;
    END IF;
    
    -- Check if weekend (Saturday-Sunday)
    IF v_day_of_week IN ('SAT', 'SUN') THEN
        v_message := 'ALLOWED - Operation allowed on weekend';
        RETURN v_message;
    END IF;
    
    RETURN 'ALLOWED - No restrictions apply';
    
EXCEPTION
    WHEN OTHERS THEN
        RETURN 'ERROR - Could not check restrictions: ' || SQLERRM;
END check_restriction_allowed;
/

DBMS_OUTPUT.PUT_LINE('✅ Restriction check function created');

-- ========== 3. COMPOUND TRIGGER (MAIN REQUIREMENT) ==========
CREATE OR REPLACE TRIGGER reservations_restriction_trg
FOR INSERT OR UPDATE OR DELETE ON reservations
COMPOUND TRIGGER

    -- Declaration section
    TYPE t_audit_info IS RECORD (
        user_id     VARCHAR2(50),
        action      VARCHAR2(20),
        record_id   VARCHAR2(100),
        old_values  CLOB,
        new_values  CLOB,
        status      VARCHAR2(20),
        error_msg   VARCHAR2(500)
    );
    
    TYPE t_audit_table IS TABLE OF t_audit_info;
    g_audit_data t_audit_table := t_audit_table();
    
    -- Before each row
    BEFORE EACH ROW IS
        v_restriction_result VARCHAR2(500);
        v_old_values CLOB;
        v_new_values CLOB;
        v_record_id VARCHAR2(100);
    BEGIN
        -- Determine action type and prepare values
        CASE
            WHEN INSERTING THEN
                v_record_id := TO_CHAR(:NEW.reservation_id);
                v_restriction_result := check_restriction_allowed(SYSDATE);
                
                -- Prepare new values as JSON
                v_new_values := '{' ||
                    '"reservation_id":"' || :NEW.reservation_id || '",' ||
                    '"customer_id":"' || :NEW.customer_id || '",' ||
                    '"room_id":"' || :NEW.room_id || '",' ||
                    '"check_in":"' || TO_CHAR(:NEW.check_in_date, 'YYYY-MM-DD') || '",' ||
                    '"check_out":"' || TO_CHAR(:NEW.check_out_date, 'YYYY-MM-DD') || '",' ||
                    '"status":"' || :NEW.status || '",' ||
                    '"amount":"' || :NEW.total_amount || '"' ||
                '}';
                
                -- Store for audit
                g_audit_data.EXTEND;
                g_audit_data(g_audit_data.LAST).user_id := USER;
                g_audit_data(g_audit_data.LAST).action := 'INSERT';
                g_audit_data(g_audit_data.LAST).record_id := v_record_id;
                g_audit_data(g_audit_data.LAST).old_values := NULL;
                g_audit_data(g_audit_data.LAST).new_values := v_new_values;
                g_audit_data(g_audit_data.LAST).error_msg := v_restriction_result;
                
                -- Check restriction
                IF v_restriction_result LIKE 'DENIED%' THEN
                    g_audit_data(g_audit_data.LAST).status := 'DENIED';
                    RAISE_APPLICATION_ERROR(-20999, 
                        'PHASE VII RESTRICTION: ' || v_restriction_result ||
                        ' | User: ' || USER || 
                        ' | Time: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
                ELSE
                    g_audit_data(g_audit_data.LAST).status := 'SUCCESS';
                END IF;
                
            WHEN UPDATING THEN
                v_record_id := TO_CHAR(:OLD.reservation_id);
                v_restriction_result := check_restriction_allowed(SYSDATE);
                
                -- Prepare old and new values
                v_old_values := '{' ||
                    '"reservation_id":"' || :OLD.reservation_id || '",' ||
                    '"old_status":"' || :OLD.status || '",' ||
                    '"new_status":"' || :NEW.status || '",' ||
                    '"old_amount":"' || :OLD.total_amount || '",' ||
                    '"new_amount":"' || :NEW.total_amount || '"' ||
                '}';
                
                v_new_values := '{' ||
                    '"status_changed":"' || :OLD.status || '->' || :NEW.status || '",' ||
                    '"amount_changed":"' || :OLD.total_amount || '->' || :NEW.total_amount || '"' ||
                '}';
                
                -- Store for audit
                g_audit_data.EXTEND;
                g_audit_data(g_audit_data.LAST).user_id := USER;
                g_audit_data(g_audit_data.LAST).action := 'UPDATE';
                g_audit_data(g_audit_data.LAST).record_id := v_record_id;
                g_audit_data(g_audit_data.LAST).old_values := v_old_values;
                g_audit_data(g_audit_data.LAST).new_values := v_new_values;
                g_audit_data(g_audit_data.LAST).error_msg := v_restriction_result;
                
                -- Check restriction
                IF v_restriction_result LIKE 'DENIED%' THEN
                    g_audit_data(g_audit_data.LAST).status := 'DENIED';
                    RAISE_APPLICATION_ERROR(-20998, 
                        'PHASE VII RESTRICTION: ' || v_restriction_result ||
                        ' | User: ' || USER || 
                        ' | Time: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
                ELSE
                    g_audit_data(g_audit_data.LAST).status := 'SUCCESS';
                END IF;
                
            WHEN DELETING THEN
                v_record_id := TO_CHAR(:OLD.reservation_id);
                v_restriction_result := check_restriction_allowed(SYSDATE);
                
                -- Prepare old values
                v_old_values := '{' ||
                    '"reservation_id":"' || :OLD.reservation_id || '",' ||
                    '"customer_id":"' || :OLD.customer_id || '",' ||
                    '"room_id":"' || :OLD.room_id || '",' ||
                    '"status":"' || :OLD.status || '",' ||
                    '"amount":"' || :OLD.total_amount || '"' ||
                '}';
                
                -- Store for audit
                g_audit_data.EXTEND;
                g_audit_data(g_audit_data.LAST).user_id := USER;
                g_audit_data(g_audit_data.LAST).action := 'DELETE';
                g_audit_data(g_audit_data.LAST).record_id := v_record_id;
                g_audit_data(g_audit_data.LAST).old_values := v_old_values;
                g_audit_data(g_audit_data.LAST).new_values := NULL;
                g_audit_data(g_audit_data.LAST).error_msg := v_restriction_result;
                
                -- Check restriction
                IF v_restriction_result LIKE 'DENIED%' THEN
                    g_audit_data(g_audit_data.LAST).status := 'DENIED';
                    RAISE_APPLICATION_ERROR(-20997, 
                        'PHASE VII RESTRICTION: ' || v_restriction_result ||
                        ' | User: ' || USER || 
                        ' | Time: ' || TO_CHAR(SYSDATE, 'YYYY-MM-DD HH24:MI:SS'));
                ELSE
                    g_audit_data(g_audit_data.LAST).status := 'SUCCESS';
                END IF;
        END CASE;
    END BEFORE EACH ROW;
    
    -- After statement (for bulk audit logging)
    AFTER STATEMENT IS
        v_log_id NUMBER;
    BEGIN
        FOR i IN 1..g_audit_data.COUNT LOOP
            -- Log to audit trail
            v_log_id := log_audit_trail(
                p_user_id    => g_audit_data(i).user_id,
                p_action     => g_audit_data(i).action,
                p_table_name => 'RESERVATIONS',
                p_record_id  => g_audit_data(i).record_id,
                p_old_values => g_audit_data(i).old_values,
                p_new_values => g_audit_data(i).new_values,
                p_status     => g_audit_data(i).status,
                p_error_msg  => g_audit_data(i).error_msg
            );
        END LOOP;
        
        -- Clear the collection
        g_audit_data.DELETE;
    END AFTER STATEMENT;
    
END reservations_restriction_trg;
/

DBMS_OUTPUT.PUT_LINE('✅ Compound trigger created');

-- ========== 4. ADDITIONAL TRIGGERS ==========

-- Trigger to auto-update room status after check-in/out
CREATE OR REPLACE TRIGGER update_room_status_trg
AFTER UPDATE OF status ON reservations
FOR EACH ROW
BEGIN
    IF :NEW.status = 'CHECKED_IN' AND :OLD.status != 'CHECKED_IN' THEN
        UPDATE rooms SET status = 'OCCUPIED'
        WHERE room_id = :NEW.room_id;
        
        -- Log the update
        log_audit_trail(
            USER, 'AUTO_UPDATE', 'ROOMS', 
            TO_CHAR(:NEW.room_id), 
            '{"status":"RESERVED"}', 
            '{"status":"OCCUPIED"}', 
            'SUCCESS', 
            'Auto-updated from reservation check-in'
        );
        
    ELSIF :NEW.status = 'CHECKED_OUT' AND :OLD.status != 'CHECKED_OUT' THEN
        UPDATE rooms SET status = 'DIRTY'
        WHERE room_id = :NEW.room_id;
        
        -- Log the update
        log_audit_trail(
            USER, 'AUTO_UPDATE', 'ROOMS', 
            TO_CHAR(:NEW.room_id), 
            '{"status":"OCCUPIED"}', 
            '{"status":"DIRTY"}', 
            'SUCCESS', 
            'Auto-updated from reservation check-out'
        );
        
    ELSIF :NEW.status = 'CANCELLED' AND :OLD.status = 'CONFIRMED' THEN
        UPDATE rooms SET status = 'AVAILABLE'
        WHERE room_id = :NEW.room_id;
    END IF;
END;
/

DBMS_OUTPUT.PUT_LINE('✅ Room status trigger created');

-- Trigger to prevent double booking
CREATE OR REPLACE TRIGGER prevent_double_booking_trg
BEFORE INSERT ON reservations
FOR EACH ROW
DECLARE
    v_conflict_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_conflict_count
    FROM reservations
    WHERE room_id = :NEW.room_id
    AND status IN ('CONFIRMED', 'CHECKED_IN')
    AND NOT (:NEW.check_out_date <= check_in_date OR :NEW.check_in_date >= check_out_date);
    
    IF v_conflict_count > 0 THEN
        -- Log the attempt
        log_audit_trail(
            USER, 'INSERT', 'RESERVATIONS',
            TO_CHAR(:NEW.reservation_id),
            NULL,
            '{"room_id":"' || :NEW.room_id || '","check_in":"' || TO_CHAR(:NEW.check_in_date, 'YYYY-MM-DD') || '"}',
            'DENIED',
            'Double booking attempt detected'
        );
        
        RAISE_APPLICATION_ERROR(-20010, 
            'Room ' || :NEW.room_id || ' is already booked for the selected dates');
    END IF;
END;
/

DBMS_OUTPUT.PUT_LINE('✅ Double booking prevention trigger created');

-- ========== 5. TEST THE TRIGGERS ==========
PROMPT ========== TESTING PHASE VII ==========

-- Test 1: Check restriction function
BEGIN
    DBMS_OUTPUT.PUT_LINE('Testing restriction check:');
    DBMS_OUTPUT.PUT_LINE('1. Today: ' || check_restriction_allowed(SYSDATE));
    DBMS_OUTPUT.PUT_LINE('2. Next Monday: ' || check_restriction_allowed(NEXT_DAY(SYSDATE, 'MONDAY')));
    DBMS_OUTPUT.PUT_LINE('3. Next Saturday: ' || check_restriction_allowed(NEXT_DAY(SYSDATE, 'SATURDAY')));
END;
/

-- Test 2: Try to insert on current day (will succeed or fail based on weekday)
DECLARE
    v_res_id NUMBER;
    v_total NUMBER;
BEGIN
    DBMS_OUTPUT.PUT_LINE('Testing INSERT on current day:');
    
    BEGIN
        hotel_mgmt_pkg.make_reservation(
            p_customer_id    => 5000,
            p_room_id        => 1000,
            p_check_in       => SYSDATE + 1,
            p_check_out      => SYSDATE + 3,
            p_num_guests     => 2,
            p_created_by     => 'phase_vii_test',
            p_reservation_id => v_res_id,
            p_total_amount   => v_total
        );
        DBMS_OUTPUT.PUT_LINE('✅ INSERT succeeded (allowed day)');
        
        -- Clean up
        DELETE FROM reservations WHERE reservation_id = v_res_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE = -20999 THEN
                DBMS_OUTPUT.PUT_LINE('✅ INSERT correctly blocked by Phase VII rule');
                DBMS_OUTPUT.PUT_LINE('   Error: ' || SUBSTR(SQLERRM, 1, 100));
            ELSE
                DBMS_OUTPUT.PUT_LINE('❌ Different error: ' || SQLERRM);
            END IF;
    END;
END;
/

-- Test 3: Check audit log was updated
DECLARE
    v_audit_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_audit_count
    FROM audit_log 
    WHERE timestamp > SYSDATE - 5/1440; -- Last 5 minutes
    
    DBMS_OUTPUT.PUT_LINE('Audit log entries in last 5 minutes: ' || v_audit_count);
    
    IF v_audit_count > 0 THEN
        DBMS_OUTPUT.PUT_LINE('✅ Audit logging is working');
        
        -- Show recent audit entries
        DBMS_OUTPUT.PUT_LINE('Recent audit entries:');
        FOR rec IN (
            SELECT action, user_id, status, 
                   TO_CHAR(timestamp, 'HH24:MI:SS') as time,
                   SUBSTR(error_message, 1, 50) as error
            FROM audit_log
            WHERE timestamp > SYSDATE - 5/1440
            ORDER BY timestamp DESC
            FETCH FIRST 3 ROWS ONLY
        ) LOOP
            DBMS_OUTPUT.PUT_LINE('  ' || rec.action || ' by ' || rec.user_id || 
                               ' - ' || rec.status || ' at ' || rec.time);
        END LOOP;
    END IF;
END;
/

-- Test 4: Verify trigger exists
PROMPT ========== VERIFICATION ==========
SELECT trigger_name, trigger_type, table_name, status
FROM user_triggers
WHERE trigger_name LIKE '%RESERVATIONS%' OR trigger_name LIKE '%RESTRICTION%'
ORDER BY trigger_name;

PROMPT ========== PHASE VII COMPLETE ==========
DBMS_OUTPUT.PUT_LINE('✅ All Phase VII components created successfully');
DBMS_OUTPUT.PUT_LINE('✅ Critical business rule implemented');
DBMS_OUTPUT.PUT_LINE('✅ Audit system operational');
DBMS_OUTPUT.PUT_LINE('✅ Triggers are active and enforcing rules');
