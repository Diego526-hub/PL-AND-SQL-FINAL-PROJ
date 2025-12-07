## Data Dictionary – Hotel Reservation System  
**Student:** Gaju Diego (ID: 27395)

---

## Table Schema Summary

### 🏨 HOTELS
| Column         | Type     | Size   | PK/FK | Nullable | Default  | Description        |
|----------------|----------|--------|--------|----------|----------|--------------------|
| hotel_id       | NUMBER   | 5      | PK     | NOT NULL | -        | Hotel ID           |
| name           | VARCHAR2 | 100    | -      | NOT NULL | -        | Hotel name         |
| location       | VARCHAR2 | 200    | -      | NOT NULL | -        | Address            |
| rating         | NUMBER   | 2,1    | -      | NULL     | -        | Rating (1.0–5.0)   |
| contact_phone  | VARCHAR2 | 20     | -      | NOT NULL | -        | Phone              |
| email          | VARCHAR2 | 100    | -      | NULL     | -        | Email              |
| created_date   | DATE     | -      | -      | NOT NULL | SYSDATE  | Created date       |

---

### 🛏️ ROOMS
| Column          | Type     | Size   | PK/FK         | Nullable | Default      | Description      |
|-----------------|----------|--------|----------------|----------|--------------|------------------|
| room_id         | NUMBER   | 10     | PK             | NOT NULL | -            | Room ID          |
| hotel_id        | NUMBER   | 5      | FK → HOTELS    | NOT NULL | -            | Hotel FK         |
| room_number     | VARCHAR2 | 10     | -              | NOT NULL | -            | Room number      |
| room_type       | VARCHAR2 | 20     | -              | NOT NULL | 'STANDARD'   | Room type        |
| price           | NUMBER   | 10,2   | -              | NOT NULL | -            | Price per night  |
| status          | VARCHAR2 | 20     | -              | NOT NULL | 'AVAILABLE'  | Room status      |
| max_occupancy   | NUMBER   | 2      | -              | NOT NULL | 2            | Max guests       |
| amenities       | VARCHAR2 | 500    | -              | NULL     | -            | Amenities        |

---

### 👤 CUSTOMERS
| Column             | Type     | Size   | PK/FK | Nullable | Default      | Description        |
|--------------------|----------|--------|--------|----------|--------------|--------------------|
| customer_id        | NUMBER   | 10     | PK     | NOT NULL | -            | Customer ID        |
| first_name         | VARCHAR2 | 50     | -      | NOT NULL | -            | First name         |
| last_name          | VARCHAR2 | 50     | -      | NOT NULL | -            | Last name          |
| email              | VARCHAR2 | 100    | -      | NOT NULL | -            | Email (Unique)     |
| phone              | VARCHAR2 | 20     | -      | NOT NULL | -            | Phone              |
| nationality        | VARCHAR2 | 50     | -      | NULL     | 'RWANDAN'    | Nationality        |
| loyalty_tier       | VARCHAR2 | 20     | -      | NOT NULL | 'STANDARD'  | Loyalty tier       |
| registration_date  | DATE     | -      | -      | NOT NULL | SYSDATE      | Sign-up date       |

---

### 📅 RESERVATIONS
| Column             | Type     | Size   | PK/FK              | Nullable | Default     | Description        |
|--------------------|----------|--------|---------------------|----------|-------------|--------------------|
| reservation_id     | NUMBER   | 15     | PK                  | NOT NULL | -           | Reservation ID     |
| customer_id        | NUMBER   | 10     | FK → CUSTOMERS      | NOT NULL | -           | Customer FK        |
| room_id            | NUMBER   | 10     | FK → ROOMS          | NOT NULL | -           | Room FK            |
| check_in_date      | DATE     | -      | -                   | NOT NULL | -           | Check-in date      |
| check_out_date     | DATE     | -      | -                   | NOT NULL | -           | Check-out date     |
| num_guests         | NUMBER   | 2      | -                   | NOT NULL | 1           | Guests (1–10)      |
| status             | VARCHAR2 | 20     | -                   | NOT NULL | 'PENDING'   | Status             |
| total_amount       | NUMBER   | 12,2   | -                   | NOT NULL | 0           | Total amount       |
| special_requests   | VARCHAR2 | 500    | -                   | NULL     | -           | Special requests   |
| created_date       | DATE     | -      | -                   | NOT NULL | SYSDATE     | Created date       |
| created_by         | VARCHAR2 | 50     | -                   | NULL     | -           | Created by         |

---

### 💳 PAYMENTS
| Column             | Type     | Size    | PK/FK                | Nullable | Default       | Description        |
|--------------------|----------|---------|-----------------------|----------|---------------|--------------------|
| payment_id         | NUMBER   | 15      | PK                    | NOT NULL | -             | Payment ID         |
| reservation_id     | NUMBER   | 15      | FK → RESERVATIONS     | NOT NULL | -             | Reservation FK     |
| amount             | NUMBER   | 10,2    | -                     | NOT NULL | -             | Payment amount     |
| payment_date       | DATE     | -       | -                     | NOT NULL | SYSDATE       | Payment date       |
| payment_method     | VARCHAR2 | 30      | -                     | NOT NULL | 'CASH'        | Payment method     |
| transaction_ref    | VARCHAR2 | 100     | -                     | NULL     | -             | Transaction ref    |
| status             | VARCHAR2 | 20      | -                     | NOT NULL | 'COMPLETED'   | Payment status     |

---

### 🎉 HOLIDAYS
| Column         | Type     | Size   | PK/FK | Nullable | Default     | Description              |
|----------------|----------|--------|--------|----------|-------------|--------------------------|
| holiday_id     | NUMBER   | 5      | PK     | NOT NULL | -           | Holiday ID               |
| holiday_date   | DATE     | -      | -      | NOT NULL | -           | Holiday date (Unique)    |
| holiday_name   | VARCHAR2 | 100    | -      | NOT NULL | -           | Holiday name             |
| country        | VARCHAR2 | 50     | -      | NOT NULL | 'RWANDA'    | Country                  |
| is_recurring   | CHAR     | 1      | -      | NOT NULL | 'Y'         | Recurring flag           |

---

### 📜 AUDIT_LOG
| Column         | Type       | Size   | PK/FK | Nullable | Default        | Description        |
|----------------|------------|--------|--------|----------|----------------|--------------------|
| log_id         | NUMBER     | 15     | PK     | NOT NULL | -              | Log ID             |
| user_id        | VARCHAR2   | 50     | -      | NOT NULL | -              | User ID            |
| action         | VARCHAR2   | 20     | -      | NOT NULL | -              | Action type        |
| table_name     | VARCHAR2   | 30     | -      | NOT NULL | -              | Table name         |
| record_id      | VARCHAR2   | 100    | -      | NOT NULL | -              | Record ID          |
| old_values     | CLOB       | -      | -      | NULL     | -              | Old values         |
| new_values     | CLOB       | -      | -      | NULL     | -              | New values         |
| timestamp      | TIMESTAMP  | -      | -      | NOT NULL | SYSTIMESTAMP   | Timestamp          |
| status         | VARCHAR2   | 20     | -      | NOT NULL | 'DENIED'       | Status             |
| error_message  | VARCHAR2   | 500    | -      | NULL     | -              | Error message      |
