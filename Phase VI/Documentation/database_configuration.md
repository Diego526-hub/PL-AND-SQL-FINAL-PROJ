# Database Configuration

## Overview
The Hotel Reservation System database is built on Oracle 21c using a Pluggable Database (PDB) architecture.

## Technical Specifications

### Database Details
- **Database Name:** tue_27395_diego_hotel_db
- **Type:** Pluggable Database (PDB)
- **Container Database:** CDB (Root Container)
- **Oracle Version:** 21c Express Edition

### Naming Convention
Follows the project requirement: `GrpName_StudentId_FirstName_ProjectName_DB`
- `tue` = Tuesday group
- `27395` = Student ID
- `diego` = First name
- `hotel` = Project name
- `db` = Database

### Storage Configuration
| Tablespace | Initial Size | Autoextend | Max Size | Purpose |
|------------|--------------|------------|----------|---------|
| hotel_data | 200 MB | 50 MB | 1 GB | Table data storage |
| hotel_index | 100 MB | 25 MB | 500 MB | Index storage |
| TEMP | 100 MB | 50 MB | Unlimited | Temporary operations |

### Memory Configuration
- **SGA_TARGET:** 800 MB
- **PGA_AGGREGATE_TARGET:** 400 MB
- **PROCESSES:** 300
- **SESSIONS:** 500

### Security Features
1. **Admin User:** hotel_admin with DBA privileges
2. **Password Policy:** Using student's first name as password
3. **Audit Trail:** Enabled for all DML operations
4. **Archive Logging:** Enabled for recovery

### Backup Configuration
- Archive log mode: ENABLED
- Flashback: ENABLED (24-hour retention)
- Automated backups: Configured via RMAN

## Setup Sequence
1. Create PDB in root container
2. Open PDB and save state
3. Create admin user with super privileges
4. Configure tablespaces
5. Set memory parameters
6. Enable archive logging
