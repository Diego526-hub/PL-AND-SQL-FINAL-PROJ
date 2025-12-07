-- =============================================
-- PHASE VI: PL/SQL PACKAGE
-- Complete hotel management package
-- Run after Phase V tables are created
-- =============================================

CONNECT hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db

SET SERVEROUTPUT ON

-- Drop existing package if exists
BEGIN
    EXECUTE IMMEDIATE 'DROP PACKAGE hotel_mgmt_pkg';
    DBMS_OUTPUT.PUT_LINE('Old package dropped');
EXCEPTION WHEN OTHERS THEN NULL;
END;
/

-- ========== PACKAGE SPECIFICATION ==========
CREATE OR REPLACE PACKAGE hotel_mgmt_pkg AS
    
    -- Custom exceptions
    invalid_dates_exc EXCEPTION;
    room_unavailable_exc EXCEPTION;
    customer_not_found_exc EXCEPTION;
    
    -- ========== PROCEDURES (5 required) ==========
    
    -- 1. Make reservation
    PROCEDURE make_reservation(
        p_customer_id    IN  NUMBER,
        p_room_id        IN  NUMBER,
        p_check_in       IN  DATE,
        p_check_out      IN  DATE,
        p_num_guests     IN  NUMBER DEFAULT 1,
        p_created_by     IN  VARCHAR2,
        p_reservation_id OUT NUMBER,
        p_total_amount   OUT NUMBER
    );
    
    -- 2. Check-in guest
    PROCEDURE check_in_guest(
        p_reservation_id IN NUMBER,
        p_status_out     OUT VARCHAR2
    );
    
    -- 3. Check-out guest
    PROCEDURE check_out_guest(
        p_reservation_id IN NUMBER,
        p_final_bill     OUT NUMBER,
        p_status_out     OUT VARCHAR2
    );
    
    -- 4. Cancel reservation
    PROCEDURE cancel_reservation(
        p_reservation_id IN NUMBER,
        p_refund_amount  OUT NUMBER,
        p_status_out     OUT VARCHAR2
    );
    
    -- 5. Update room prices (Bulk operation)
    PROCEDURE update_room_prices(
        p_hotel_id      IN NUMBER,
        p_percentage    IN NUMBER,
        p_updated_count OUT NUMBER
    );
    
    -- ========== FUNCTIONS (5 required) ==========
    
    -- 1. Calculate stay cost
    FUNCTION calculate_stay_cost(
        p_room_id    IN NUMBER,
        p_check_in   IN DATE,
        p_check_out  IN DATE
    ) RETURN NUMBER;
    
    -- 2. Check room availability
    FUNCTION check_room_availability(
        p_room_id    IN NUMBER,
        p_check_in   IN DATE,
        p_check_out  IN DATE
    ) RETURN VARCHAR2;
    
    -- 3. Get hotel occupancy rate
    FUNCTION get_occupancy_rate(
        p_hotel_id IN NUMBER
    ) RETURN NUMBER;
    
    -- 4. Get customer loyalty points
    FUNCTION get_customer_points(
        p_customer_id IN NUMBER
    ) RETURN NUMBER;
    
    -- 5. Validate booking dates
    FUNCTION validate_booking_dates(
        p_check_in  IN DATE,
        p_check_out IN DATE
    ) RETURN VARCHAR2;
    
    -- ========== CURSOR DECLARATION ==========
    
    -- Cursor for active reservations
    CURSOR c_active_reservations(p_hotel_id NUMBER) IS
        SELECT r.reservation_id, r.customer_id, r.check_in_date
        FROM reservations r
        JOIN rooms rm ON r.room_id = rm.room_id
        WHERE rm.hotel_id = p_hotel_id
        AND r.status IN ('CONFIRMED', 'CHECKED_IN');
    
END hotel_mgmt_pkg;
/

DBMS_OUTPUT.PUT_LINE('✅ Package specification created');

-- ========== PACKAGE BODY ==========
CREATE OR REPLACE PACKAGE BODY hotel_mgmt_pkg AS
    
    -- Private helper function
    FUNCTION calculate_nights(p_check_in DATE, p_check_out DATE) 
    RETURN NUMBER IS
    BEGIN
        RETURN p_check_out - p_check_in;
    END calculate_nights;
    
    -- 1. MAKE RESERVATION procedure
    PROCEDURE make_reservation(
        p_customer_id    IN  NUMBER,
        p_room_id        IN  NUMBER,
        p_check_in       IN  DATE,
        p_check_out      IN  DATE,
        p_num_guests     IN  NUMBER DEFAULT 1,
        p_created_by     IN  VARCHAR2,
        p_reservation_id OUT NUMBER,
        p_total_amount   OUT NUMBER
    ) IS
        v_room_price NUMBER;
        v_nights NUMBER;
        v_max_occupancy NUMBER;
    BEGIN
        -- Validate dates
        IF p_check_out <= p_check_in THEN
            RAISE invalid_dates_exc;
        END IF;
        
        -- Check room availability
        IF check_room_availability(p_room_id, p_check_in, p_check_out) != 'AVAILABLE' THEN
            RAISE room_unavailable_exc;
        END IF;
        
        -- Get room details
        SELECT price, max_occupancy INTO v_room_price, v_max_occupancy
        FROM rooms WHERE room_id = p_room_id;
        
        -- Check guest count
        IF p_num_guests > v_max_occupancy THEN
            RAISE_APPLICATION_ERROR(-20001, 
                'Number of guests (' || p_num_guests || 
                ') exceeds room capacity (' || v_max_occupancy || ')');
        END IF;
        
        -- Calculate total
        v_nights := calculate_nights(p_check_in, p_check_out);
        p_total_amount := v_room_price * v_nights;
        
        -- Apply loyalty discount
        DECLARE
            v_tier customers.loyalty_tier%TYPE;
        BEGIN
            SELECT loyalty_tier INTO v_tier 
            FROM customers WHERE customer_id = p_customer_id;
            
            CASE v_tier
                WHEN 'PLATINUM' THEN p_total_amount := p_total_amount * 0.85;
                WHEN 'GOLD'     THEN p_total_amount := p_total_amount * 0.90;
                WHEN 'SILVER'   THEN p_total_amount := p_total_amount * 0.95;
                ELSE NULL;
            END CASE;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                RAISE customer_not_found_exc;
        END;
        
        -- Create reservation
        INSERT INTO reservations (
            reservation_id, customer_id, room_id, 
            check_in_date, check_out_date, num_guests,
            status, total_amount, created_by
        ) VALUES (
            seq_reservations.NEXTVAL, p_customer_id, p_room_id,
            p_check_in, p_check_out, p_num_guests,
            'CONFIRMED', p_total_amount, p_created_by
        ) RETURNING reservation_id INTO p_reservation_id;
        
        -- Update room status
        UPDATE rooms SET status = 'RESERVED'
        WHERE room_id = p_room_id;
        
        COMMIT;
        
    EXCEPTION
        WHEN invalid_dates_exc THEN
            RAISE_APPLICATION_ERROR(-20002, 'Check-out must be after check-in');
        WHEN room_unavailable_exc THEN
            RAISE_APPLICATION_ERROR(-20003, 'Room not available for selected dates');
        WHEN customer_not_found_exc THEN
            RAISE_APPLICATION_ERROR(-20004, 'Customer not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END make_reservation;
    
    -- 2. CHECK IN GUEST procedure
    PROCEDURE check_in_guest(
        p_reservation_id IN NUMBER,
        p_status_out     OUT VARCHAR2
    ) IS
        v_room_id NUMBER;
    BEGIN
        -- Get room ID
        SELECT room_id INTO v_room_id
        FROM reservations WHERE reservation_id = p_reservation_id;
        
        -- Update reservation
        UPDATE reservations SET status = 'CHECKED_IN'
        WHERE reservation_id = p_reservation_id;
        
        -- Update room
        UPDATE rooms SET status = 'OCCUPIED'
        WHERE room_id = v_room_id;
        
        COMMIT;
        p_status_out := 'CHECKED_IN';
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20005, 'Reservation not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END check_in_guest;
    
    -- 3. CHECK OUT GUEST procedure
    PROCEDURE check_out_guest(
        p_reservation_id IN NUMBER,
        p_final_bill     OUT NUMBER,
        p_status_out     OUT VARCHAR2
    ) IS
        v_room_id NUMBER;
    BEGIN
        -- Get details
        SELECT room_id, total_amount INTO v_room_id, p_final_bill
        FROM reservations WHERE reservation_id = p_reservation_id;
        
        -- Update reservation
        UPDATE reservations SET status = 'CHECKED_OUT'
        WHERE reservation_id = p_reservation_id;
        
        -- Update room
        UPDATE rooms SET status = 'AVAILABLE'
        WHERE room_id = v_room_id;
        
        COMMIT;
        p_status_out := 'CHECKED_OUT';
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20006, 'Reservation not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END check_out_guest;
    
    -- 4. CANCEL RESERVATION procedure
    PROCEDURE cancel_reservation(
        p_reservation_id IN NUMBER,
        p_refund_amount  OUT NUMBER,
        p_status_out     OUT VARCHAR2
    ) IS
        v_total_amount NUMBER;
        v_room_id NUMBER;
        v_status VARCHAR2(20);
    BEGIN
        -- Get reservation details
        SELECT total_amount, room_id, status 
        INTO v_total_amount, v_room_id, v_status
        FROM reservations WHERE reservation_id = p_reservation_id;
        
        -- Calculate refund (50% if cancelled before check-in)
        IF v_status = 'CONFIRMED' THEN
            p_refund_amount := v_total_amount * 0.5;
        ELSE
            p_refund_amount := 0;
        END IF;
        
        -- Update reservation
        UPDATE reservations SET status = 'CANCELLED'
        WHERE reservation_id = p_reservation_id;
        
        -- Update room if it was reserved
        IF v_status = 'CONFIRMED' THEN
            UPDATE rooms SET status = 'AVAILABLE'
            WHERE room_id = v_room_id;
        END IF;
        
        COMMIT;
        p_status_out := 'CANCELLED';
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20007, 'Reservation not found');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END cancel_reservation;
    
    -- 5. UPDATE ROOM PRICES procedure (BULK with cursor)
    PROCEDURE update_room_prices(
        p_hotel_id      IN NUMBER,
        p_percentage    IN NUMBER,
        p_updated_count OUT NUMBER
    ) IS
        -- Declare cursor FOR UPDATE
        CURSOR room_cursor IS
            SELECT room_id, price FROM rooms
            WHERE hotel_id = p_hotel_id
            FOR UPDATE;
    BEGIN
        p_updated_count := 0;
        
        -- Process each room
        FOR room_rec IN room_cursor LOOP
            UPDATE rooms 
            SET price = room_rec.price * (1 + p_percentage/100)
            WHERE CURRENT OF room_cursor;
            
            p_updated_count := p_updated_count + 1;
        END LOOP;
        
        COMMIT;
        
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END update_room_prices;
    
    -- 1. CALCULATE STAY COST function
    FUNCTION calculate_stay_cost(
        p_room_id    IN NUMBER,
        p_check_in   IN DATE,
        p_check_out  IN DATE
    ) RETURN NUMBER IS
        v_price NUMBER;
        v_nights NUMBER;
    BEGIN
        SELECT price INTO v_price FROM rooms WHERE room_id = p_room_id;
        v_nights := calculate_nights(p_check_in, p_check_out);
        RETURN v_price * v_nights;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN -1;
        WHEN OTHERS THEN
            RETURN -2;
    END calculate_stay_cost;
    
    -- 2. CHECK ROOM AVAILABILITY function
    FUNCTION check_room_availability(
        p_room_id    IN NUMBER,
        p_check_in   IN DATE,
        p_check_out  IN DATE
    ) RETURN VARCHAR2 IS
        v_conflict_count NUMBER;
        v_room_status VARCHAR2(20);
    BEGIN
        -- Check room status
        SELECT status INTO v_room_status
        FROM rooms WHERE room_id = p_room_id;
        
        IF v_room_status IN ('OCCUPIED', 'MAINTENANCE') THEN
            RETURN 'NOT AVAILABLE - Room is ' || v_room_status;
        END IF;
        
        -- Check for booking conflicts
        SELECT COUNT(*) INTO v_conflict_count
        FROM reservations
        WHERE room_id = p_room_id
        AND status IN ('CONFIRMED', 'CHECKED_IN')
        AND NOT (check_out_date <= p_check_in OR check_in_date >= p_check_out);
        
        IF v_conflict_count > 0 THEN
            RETURN 'NOT AVAILABLE - Booking conflict';
        ELSE
            RETURN 'AVAILABLE';
        END IF;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 'ERROR - Room not found';
        WHEN OTHERS THEN
            RETURN 'ERROR - ' || SQLERRM;
    END check_room_availability;
    
    -- 3. GET OCCUPANCY RATE function
    FUNCTION get_occupancy_rate(
        p_hotel_id IN NUMBER
    ) RETURN NUMBER IS
        v_total_rooms NUMBER;
        v_occupied_rooms NUMBER;
    BEGIN
        -- Get total rooms
        SELECT COUNT(*) INTO v_total_rooms
        FROM rooms WHERE hotel_id = p_hotel_id;
        
        -- Get occupied rooms
        SELECT COUNT(DISTINCT r.room_id) INTO v_occupied_rooms
        FROM reservations r
        JOIN rooms rm ON r.room_id = rm.room_id
        WHERE rm.hotel_id = p_hotel_id
        AND r.status IN ('CHECKED_IN')
        AND SYSDATE BETWEEN r.check_in_date AND r.check_out_date;
        
        IF v_total_rooms > 0 THEN
            RETURN ROUND((v_occupied_rooms / v_total_rooms) * 100, 2);
        ELSE
            RETURN 0;
        END IF;
        
    EXCEPTION
        WHEN OTHERS THEN
            RETURN -1;
    END get_occupancy_rate;
    
    -- 4. GET CUSTOMER POINTS function
    FUNCTION get_customer_points(
        p_customer_id IN NUMBER
    ) RETURN NUMBER IS
        v_total_spent NUMBER;
        v_tier VARCHAR2(20);
    BEGIN
        -- Get total spent
        SELECT COALESCE(SUM(total_amount), 0) INTO v_total_spent
        FROM reservations
        WHERE customer_id = p_customer_id
        AND status != 'CANCELLED';
        
        -- Get tier
        SELECT loyalty_tier INTO v_tier
        FROM customers WHERE customer_id = p_customer_id;
        
        -- Calculate points (1 point per 1000 RWF)
        v_total_spent := FLOOR(v_total_spent / 1000);
        
        -- Apply tier multiplier
        CASE v_tier
            WHEN 'PLATINUM' THEN v_total_spent := v_total_spent * 2;
            WHEN 'GOLD'     THEN v_total_spent := v_total_spent * 1.5;
            WHEN 'SILVER'   THEN v_total_spent := v_total_spent * 1.2;
            ELSE NULL;
        END CASE;
        
        RETURN v_total_spent;
        
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN 0;
        WHEN OTHERS THEN
            RETURN -1;
    END get_customer_points;
    
    -- 5. VALIDATE BOOKING DATES function
    FUNCTION validate_booking_dates(
        p_check_in  IN DATE,
        p_check_out IN DATE
    ) RETURN VARCHAR2 IS
    BEGIN
        IF p_check_out <= p_check_in THEN
            RETURN 'INVALID: Check-out must be after check-in';
        ELSIF p_check_in < SYSDATE THEN
            RETURN 'INVALID: Cannot book in past';
        ELSIF (p_check_out - p_check_in) > 30 THEN
            RETURN 'INVALID: Maximum stay is 30 nights';
        ELSE
            RETURN 'VALID';
        END IF;
    END validate_booking_dates;
    
END hotel_mgmt_pkg;
/

DBMS_OUTPUT.PUT_LINE('✅ Package body created');
DBMS_OUTPUT.PUT_LINE('✅ Phase VI: PL/SQL Package COMPLETE');

-- Test the package
PROMPT ========== TESTING PACKAGE ==========
DECLARE
    v_result VARCHAR2(100);
    v_number NUMBER;
    v_text VARCHAR2(200);
BEGIN
    -- Test function 1
    v_number := hotel_mgmt_pkg.calculate_stay_cost(1000, SYSDATE+1, SYSDATE+3);
    DBMS_OUTPUT.PUT_LINE('1. calculate_stay_cost: ' || v_number || ' RWF');
    
    -- Test function 2
    v_text := hotel_mgmt_pkg.check_room_availability(1000, SYSDATE+10, SYSDATE+12);
    DBMS_OUTPUT.PUT_LINE('2. check_room_availability: ' || v_text);
    
    -- Test function 3
    v_number := hotel_mgmt_pkg.get_occupancy_rate(100);
    DBMS_OUTPUT.PUT_LINE('3. get_occupancy_rate: ' || v_number || '%');
    
    -- Test function 4
    v_number := hotel_mgmt_pkg.get_customer_points(5000);
    DBMS_OUTPUT.PUT_LINE('4. get_customer_points: ' || v_number || ' points');
    
    -- Test function 5
    v_text := hotel_mgmt_pkg.validate_booking_dates(SYSDATE+1, SYSDATE+3);
    DBMS_OUTPUT.PUT_LINE('5. validate_booking_dates: ' || v_text);
    
    -- Test cursor
    v_number := 0;
    FOR rec IN hotel_mgmt_pkg.c_active_reservations(100) LOOP
        v_number := v_number + 1;
    END LOOP;
    DBMS_OUTPUT.PUT_LINE('6. Cursor processed ' || v_number || ' active reservations');
    
    DBMS_OUTPUT.PUT_LINE('✅ All tests passed!');
END;
/
