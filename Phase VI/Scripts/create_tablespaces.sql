
-- Create DATA tablespace (200MB, autoextend to 1GB)
CREATE TABLESPACE hotel_data
DATAFILE SIZE 200M
AUTOEXTEND ON NEXT 50M MAXSIZE 1G
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- Create INDEX tablespace (100MB, autoextend to 500MB)
CREATE TABLESPACE hotel_index
DATAFILE SIZE 100M
AUTOEXTEND ON NEXT 25M MAXSIZE 500M
EXTENT MANAGEMENT LOCAL
SEGMENT SPACE MANAGEMENT AUTO;

-- Set admin user's default tablespace
ALTER USER hotel_admin DEFAULT TABLESPACE hotel_data;
ALTER USER hotel_admin TEMPORARY TABLESPACE temp;

-- Grant quota on tablespaces
ALTER USER hotel_admin QUOTA UNLIMITED ON hotel_data;
ALTER USER hotel_admin QUOTA UNLIMITED ON hotel_index;

-- Verify tablespaces
SELECT tablespace_name, file_name, 
       bytes/1024/1024 as size_mb,
       autoextensible, status
FROM dba_data_files 
ORDER BY tablespace_name;
