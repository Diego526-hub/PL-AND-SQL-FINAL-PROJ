
-- PHASE IV: DATABASE CREATION
-- Creates PDB, users, tablespaces
-- Run as: SYS user with SYSDBA privileges

-- Connect to CDB as SYS
CONNECT sys/oracle@localhost:1521/CDB as sysdba

-- 1. Create Pluggable Database
CREATE PLUGGABLE DATABASE tue_27395_diego_hotel_db
ADMIN USER admin IDENTIFIED BY diego
ROLES = (dba)


-- Open the PDB
ALTER PLUGGABLE DATABASE tue_27395_diego_hotel_db OPEN;
ALTER PLUGGABLE DATABASE tue_27395_diego_hotel_db SAVE STATE;

-- Switch to new PDB
ALTER SESSION SET CONTAINER = tue_27395_diego_hotel_db;

-- 2. Create Admin User
CREATE USER hotel_admin IDENTIFIED BY diego
DEFAULT TABLESPACE users
TEMPORARY TABLESPACE temp
QUOTA UNLIMITED ON users;

-- Grant privileges
GRANT CONNECT, RESOURCE TO hotel_admin;
GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SEQUENCE,
      CREATE TYPE TO hotel_admin;
GRANT UNLIMITED TABLESPACE TO hotel_admin;

-- 3. Create Application Users
CREATE USER hotel_app IDENTIFIED BY app123;
CREATE USER hotel_report IDENTIFIED BY report123;

GRANT CREATE SESSION TO hotel_app, hotel_report;
GRANT SELECT ANY TABLE TO hotel_report;

-- 4. Create Tablespaces
CREATE TABLESPACE hotel_data
DATAFILE 'hotel_data01.dbf' SIZE 500M
AUTOEXTEND ON NEXT 100M MAXSIZE 2G;

CREATE TABLESPACE hotel_index
DATAFILE 'hotel_index01.dbf' SIZE 200M
AUTOEXTEND ON NEXT 50M MAXSIZE 1G;

-- 5. Set default tablespace
ALTER USER hotel_admin DEFAULT TABLESPACE hotel_data;
ALTER USER hotel_admin TEMPORARY TABLESPACE temp;

-- 6. Verify creation
PROMPT ========== DATABASE CREATED SUCCESSFULLY ==========
PROMPT PDB: tue_27395_diego_hotel_db
PROMPT Admin: hotel_admin / diego
PROMPT Connect: hotel_admin/diego@localhost:1521/tue_27395_diego_hotel_db
PROMPT ====================================================

-- Display verification
SELECT name, open_mode FROM v$database;
SELECT username FROM dba_users WHERE username LIKE 'HOTEL%';
SELECT tablespace_name FROM dba_tablespaces;
