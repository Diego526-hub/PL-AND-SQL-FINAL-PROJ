## System Architecture – Hotel Reservation System

```text
┌─────────────────────────────────────┐
│        APPLICATION LAYER            │
│  • Hotel Management Interface       │
│  • Reporting Dashboards             │
└───────────────────┬─────────────────┘
                    │
┌───────────────────▼─────────────────┐
│         PL/SQL LAYER                │
│  • Procedures: Booking, Check-in/out│
│  • Functions: Calculations, Validation│
│  • Triggers: Business rules, Audit  │
└───────────────────┬─────────────────┘
                    │
┌───────────────────▼─────────────────┐
│        DATABASE LAYER               │
│  • Oracle PDB: tue_27395_diego_hotel_db │
│  • 7 Normalized Tables (3NF)        │
│  • Indexes for performance          │
└─────────────────────────────────────┘
