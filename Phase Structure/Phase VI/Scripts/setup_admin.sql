
ALTER SESSION SET CONTAINER = tue_27395_diego_hotel_db;

-- Grant super admin privileges (REQUIREMENT)
GRANT CONNECT, RESOURCE, DBA TO hotel_admin;
GRANT UNLIMITED TABLESPACE TO hotel_admin;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE,
      CREATE TYPE, CREATE JOB TO hotel_admin;

-- Verify user creation
SELECT username, account_status, created 
FROM dba_users 
WHERE username = 'HOTEL_ADMIN';
