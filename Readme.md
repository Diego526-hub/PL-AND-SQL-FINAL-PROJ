# 🏨 Hotel Reservation & Room Management System
### PL/SQL-Based Solution for Efficient Hotel Booking in Rwanda

**Student:** Gaju Diego  
**Student ID:** 27395  
**Course:** Database Development with PL/SQL (INSY 8311)  
**Institution:** Adventist University of Central Africa (AUCA)  
**Lecturer:** Eric Maniraquha  
**Project Date:** December 2025  
**Database:** Oracle 19c/21c  

---

## 📋 Table of Contents
1. [Project Overview](#-project-overview)
2. [Problem Statement](#-problem-statement)  
3. [Solution Features](#-solution-features)
4. [Database Design](#-database-design)
5. [Project Phases](#-project-phases)
6. [Installation Guide](#-installation-guide)
7. [Usage Examples](#-usage-examples)
8. [Business Intelligence](#-business-intelligence)
9. [Critical Business Rule](#-critical-business-rule)
10. [Documentation](#-documentation)
11. [Contact Information](#-contact-information)

---

## 🎯 Project Overview

This project implements a comprehensive **Hotel Reservation & Room Management System** using Oracle PL/SQL. Designed specifically for hotels in Rwanda, it automates booking processes, prevents double-bookings, and provides business intelligence insights to improve operational efficiency and customer satisfaction.

---

## ⚠️ Problem Statement

Hotels in Rwanda face significant operational challenges:
- **Manual booking errors** causing double-bookings and overbooking
- **Inefficient room allocation** during peak tourism seasons
- **Lack of real-time analytics** for data-driven decisions
- **No automated audit trails** for security compliance
- **Paper-based processes** leading to delays and customer dissatisfaction

These issues result in:
- Lost revenue from booking conflicts
- Poor customer experience
- Inefficient resource utilization
- Compliance risks

---

## ✨ Solution Features

### ✅ **Core Functionality**
- **Real-time room availability checking**
- **Automated reservation creation** with validation
- **Check-in/check-out processing** with automatic billing
- **Payment tracking** and reconciliation
- **Customer management** with loyalty program

### ✅ **Advanced Features**
- **Double-booking prevention** via PL/SQL triggers
- **Dynamic pricing** based on demand and season
- **Business Intelligence dashboards** for analytics
- **Complete audit logging** of all operations
- **Role-based access control** for security

### ✅ **Technical Excellence**
- **7 Normalized Tables** (3NF compliance)
- **15+ PL/SQL Objects** (Procedures, Functions, Packages)
- **Compound Triggers** for business rule enforcement
- **Window Functions** for analytical queries
- **Bulk Operations** for performance optimization

---

## 🗄️ Database Design

### **Database Schema:**

<img width="641" height="721" alt="ER diagram final drawio" src="https://github.com/user-attachments/assets/e99f32b0-75ee-4cf6-9db4-5a1217ce9a7a" />


### **7 Core Tables:**
1. **HOTELS** - Hotel master data (3 rows)
2. **ROOMS** - Room inventory (120+ rows)  
3. **CUSTOMERS** - Guest information (200+ rows)
4. **RESERVATIONS** - Booking transactions (300+ rows)
5. **PAYMENTS** - Financial transactions (250+ rows)
6. **HOLIDAYS** - Rwanda public holidays (11 rows)
7. **AUDIT_LOG** - Security audit trail (All operations)

### **Data Volume:**
- **Total Tables:** 7
- **Total Rows:** 900+ realistic records
- **Test Data:** Rwandan-specific hotel information

---

## 📊 Project Phases

### **✅ Phase I: Problem Identification**
- PowerPoint presentation (5 slides)
- Problem definition for Rwandan hotels
- Business Intelligence potential analysis

### **✅ Phase II: Business Process Modeling**
- BPMN diagram with swimlanes
- Process flow from booking to check-out
- One-page process explanation

### **✅ Phase III: Logical Database Design**
- Entity-Relationship Diagram (ERD)
- Complete Data Dictionary
- 3NF normalization justification

### **✅ Phase IV: Database Creation**
- Oracle PDB: `tue_27395_diego_hotel_db`
- Admin user: `hotel_admin` / `diego`
- Tablespace configuration
- Memory parameters optimization

### **✅ Phase V: Table Implementation**
- 7 tables created with all constraints
- 900+ rows of realistic test data
- Validation queries (SELECT, JOIN, GROUP BY, subqueries)

### **✅ Phase VI: PL/SQL Development**
- **Package:** `HOTEL_MGMT_PKG`
- **5 Procedures:** make_reservation, check_in_guest, check_out_guest, cancel_reservation, update_room_prices
- **5 Functions:** calculate_stay_cost, check_room_availability, get_occupancy_rate, get_customer_points, validate_booking_dates
- **Cursors:** Explicit cursor processing
- **Window Functions:** ROW_NUMBER(), RANK(), LAG(), LEAD()

### **✅ Phase VII: Advanced Programming & Auditing**
- **Critical Business Rule:** No operations on weekdays/holidays
- **Compound Trigger:** `RESERVATIONS_RESTRICTION_TRG`
- **Audit System:** Complete logging of all attempts
- **Custom Functions:** Restriction checking and audit logging

### **🔄 Phase VIII: Documentation & Presentation**
- Complete project documentation
- Business Intelligence dashboards
- Final presentation (10 slides)

---

## 🚀 Installation Guide

### **Step 1: Database Setup**
```sql
-- Connect as SYSDBA to CDB
CONNECT sys/oracle@localhost:1521/CDB as sysdba

-- Create Pluggable Database
CREATE PLUGGABLE DATABASE tue_27395_diego_hotel_db
ADMIN USER admin IDENTIFIED BY diego
FILE_NAME_CONVERT = ('/opt/oracle/oradata/CDB/pdbseed/', 
                     '/opt/oracle/oradata/CDB/tue_27395_diego_hotel_db/');

ALTER PLUGGABLE DATABASE tue_27395_diego_hotel_db OPEN;
ALTER SESSION SET CONTAINER = tue_27395_diego_hotel_db;
