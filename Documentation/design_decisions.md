## Design Decisions - Hotel Reservation System
**1. Database Design**
Decision: 7 tables normalized to 3NF
Why: Meets requirements with clean structure
Tables: HOTELS, ROOMS, CUSTOMERS, RESERVATIONS, PAYMENTS, HOLIDAYS, AUDIT_LOG

**Decision: Star schema design**
Fact Table: RESERVATIONS
Dimension Tables: CUSTOMERS, ROOMS, HOTELS
Why: Optimized for BI and analytics

**Decision: Simple data types**
NUMBER for IDs: Consistent identification system
VARCHAR2 for text: Balanced storage and flexibility
DATE for dates: Sufficient for booking needs

## 2. PL/SQL Architecture
Decision: Single package (HOTEL_MGMT_PKG)
Why: Centralized logic, easier maintenance
Contains: 5 procedures, 5 functions, 2 cursors

**Decision: Comprehensive error handling**
Custom exceptions: Named errors with clear messages
Audit logging: All operations logged to AUDIT_LOG
Transaction safety: COMMIT/ROLLBACK in procedures

**Decision: Performance optimization**
Indexes: On PKs, FKs, and search columns
Bulk operations: For price updates and data processing
Efficient cursors: Proper OPEN/FETCH/CLOSE patterns

## 3. Business Rules
Booking Rules:

No double-booking (function validation)

Check-out must be after check-in (CHECK constraint)

Guest count limited to room capacity (CHECK constraint)

Phase VII Restriction:

No operations on weekdays (Mon-Fri)

No operations on Rwanda holidays

Compound trigger implementation

All attempts logged to AUDIT_LOG

Pricing Strategy:

Base price per room type

Loyalty discounts: Platinum 15%, Gold 10%, Silver 5%

Extra guest charge: 5000 RWF per extra guest per night

## 4. Security & Audit
User Roles:

HOTEL_ADMIN: Full system access

HOTEL_APP: Limited front desk operations

HOTEL_REPORT: Read-only for analytics

Audit System:

Logs all INSERT/UPDATE/DELETE attempts

Separate AUDIT_LOG table

Timestamp, user, action, status recorded

Supports compliance and troubleshooting

## 5. Rwanda-Specific Design
Localization:

Currency: Rwandan Francs (RWF)

Holidays: Rwanda-specific dates

Phone format: +250 prefix

Target market: Small-medium hotels in Rwanda

## 6. Technical Trade-offs
Simplicity vs Complexity: Chose simplicity
Why: Meets requirements without over-engineering
Benefit: Easier to implement, test, and maintain

Performance vs Features: Balanced approach
Optimizations: Indexes, bulk operations, efficient queries
Features: All capstone requirements included

Code Maintainability:

Modular procedures for distinct tasks

Consistent naming conventions

Comprehensive comments

Well-documented business logic

## 7. Future Considerations
Scalability Path:

Phase 1: Single hotel (current)

Phase 2: Multiple hotels (add hotel_group)

Phase 3: Regional expansion

Enhancement Roadmap:

Basic system (capstone complete)

Web/mobile interface

Advanced analytics dashboard

Payment gateway integration

## 8. Capstone Requirements Focus
Requirement	How Implemented	Evidence
100+ rows per table	Sample data scripts	Screenshots
5+ procedures	HOTEL_MGMT_PKG	Code files
Triggers & audit	Phase VII implementation	Test results
BI integration	KPI definitions & queries	Documentation
9. Design Philosophy
Core Principles:

Keep it simple

Make it work reliably

Ensure easy maintenance

Meet all requirements exactly

Success Criteria:

All 8 phases completed

Production-ready code

Comprehensive documentation

Working BI components
