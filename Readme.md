# 🏨 Hotel Reservation & Room Management System (HRRMS)

======================================================================

## 🎓 Personal Information

**Student:** Gaju Diego  
**Student ID:** 27395  
**Program:** IT – Software Engineering  
**Course:** INSY 8311 | Database Development with PL/SQL  
**Institution:** Adventist University of Central Africa (AUCA)  
**Lecturer:** Eric Maniraguha  
**Academic Year:** 2025–2026 | Semester I  

**Project Title:** Hotel Reservation & Room Management System  
**Database:** Oracle 19c / 21c  
**Project Date:** December 2025  

---

## 📑 Project Phases – Table of Content

| Phase | Primary Objective | Key Deliverable |
|-------|-------------------|-----------------|
| I | Problem Identification | PowerPoint Presentation |
| II | Business Process Modeling | BPMN Diagram |
| III | Logical Database Design | ER Diagram + Data Dictionary |
| IV | Database Creation | Oracle PDB + Configuration |
| V | Table Implementation | CREATE & INSERT Scripts |
| VI | PL/SQL Development | Procedures, Functions, Packages |
| VII | Advanced Programming | Triggers, Auditing, Security |
| VIII | Final Documentation | GitHub Repository + Presentation |

---

# ✅ Phase I: Problem Identification

## 🎯 Project Overview

This is a multi-phase individual capstone project focused on **Oracle Database Design, PL/SQL Programming, and Business Intelligence**.  
The system automates hotel reservations, room allocation, billing, and reporting for hotels operating in Rwanda.

## ⚠️ Problem Statement

Hotels in Rwanda currently face:
- Manual booking processes leading to **double booking**
- **Poor room allocation** during peak seasons
- Lack of **real-time business analytics**
- Weak **security and audit tracking**
- Paper-based reservations causing **customer delays**

These problems result in:
- Revenue loss  
- Customer dissatisfaction  
- Inefficient hotel operations  
- Poor strategic decision-making  

## 🛠 Proposed Solution

A **PL/SQL-based Hotel Reservation & Room Management System** that:
- Automates all booking operations  
- Prevents double reservations using triggers  
- Tracks payments and customers  
- Produces real-time business intelligence reports  

---

# ✅ Phase II: Business Process Modeling

## 👥 System Actors

- **Receptionist** – Registers customers and creates reservations  
- **Hotel Manager** – Monitors performance and pricing  
- **Accountant** – Tracks payments and billing  
- **System Admin** – Manages users and security  
- **Guest** – Makes reservations and checks in/out  

## 🔄 Core Process Flow

1. Customer arrives or books online  
2. Receptionist checks room availability  
3. Reservation is created  
4. Customer checks in  
5. Billing and payment processed  
6. Customer checks out  
7. Audit logs updated  

## 📌 BPMN Diagram

> ![BPMN diagram](https://github.com/Diego526-hub/PL-AND-SQL-FINAL-PROJ/blob/main/Database/Documentation/BPMN%20diagram.svg)

# ✅ Phase III: Logical Database Design

## 📊 Entities (7 Tables)

| Table Name | Description |
|-----------|-------------|
| HOTELS | Hotel master information |
| ROOMS | Room inventory |
| CUSTOMERS | Guest information |
| RESERVATIONS | Booking transactions |
| PAYMENTS | Payment details |
| HOLIDAYS | Public holidays |
| AUDIT_LOG | System audit trail |

## 🧩 ER Diagram
> ![ER DIAGRAM](https://github.com/Diego526-hub/PL-AND-SQL-FINAL-PROJ/blob/main/Database/Documentation/ER%20diagram%20final.drawio.png)

## ✅ Normalization
1NF: Atomic values  
2NF: No partial dependencies  
3NF: No transitive dependencies  

Database is fully compliant with **Third Normal Form (3NF)**.

--------------------------------------------------------------------

# ✅ Phase IV: Database Creation

## 🗄️ Pluggable Database (PDB)

PDB Name: tue_27395_diego_hotel_db  
Admin User: hotel_admin  
Password: diego  

sql
CREATE PLUGGABLE DATABASE tue_27395_diego_hotel_db
ADMIN USER admin IDENTIFIED BY diego
FILE_NAME_CONVERT = (
 '/opt/oracle/oradata/CDB/pdbseed/',
 '/opt/oracle/oradata/CDB/tue_27395_diego_hotel_db/'
);

ALTER PLUGGABLE DATABASE tue_27395_diego_hotel_db OPEN;
ALTER SESSION SET CONTAINER = tue_27395_diego_hotel_db;

# ✅ Phase V: Table Implementation & Data Insertion

Tables Implemented:
HOTELS  
ROOMS  
CUSTOMERS  
RESERVATIONS  
PAYMENTS  
HOLIDAYS  
AUDIT_LOG  

Validation Queries:
sql
SELECT COUNT(*) FROM hotels;
SELECT COUNT(*) FROM rooms;
SELECT COUNT(*) FROM customers;
SELECT COUNT(*) FROM reservations;
SELECT COUNT(*) FROM payments;
SELECT COUNT(*) FROM holidays;
SELECT COUNT(*) FROM audit_log; 

![all tables](https://github.com/user-attachments/assets/1240edf2-9c46-48f4-be1d-9bc981919676)

# ✅ Phase VI: PL/SQL Development

Package Name:
HOTEL_MGMT_PKG

--------------------------------------------------

Procedures:
- make_reservation
- check_in_guest
- check_out_guest
- cancel_reservation
- update_room_prices

--------------------------------------------------

Functions:
- calculate_stay_cost
- check_room_availability
- get_occupancy_rate
- get_customer_points
- validate_booking_dates

--------------------------------------------------

Window Functions Used:
- ROW_NUMBER()
- RANK()
- LAG()
- LEAD()

--------------------------------------------------



