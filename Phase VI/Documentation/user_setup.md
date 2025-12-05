# User Setup Documentation

## Admin User Configuration

### Primary Admin User
**Username:** hotel_admin
**Password:** diego
**Purpose:** Super administrator for the hotel database

### Privileges Granted
```sql
GRANT CONNECT, RESOURCE, DBA TO hotel_admin;
GRANT UNLIMITED TABLESPACE TO hotel_admin;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE,
      CREATE TYPE, CREATE JOB TO hotel_admin;
