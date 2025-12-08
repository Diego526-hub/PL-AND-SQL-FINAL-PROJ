# KPI Definitions

## **1. Financial KPIs**
| KPI | Formula | Target | Purpose |
|-----|---------|---------|---------|
| **Occupancy Rate** | (Rooms Occupied ÷ Total Rooms) × 100 | > 75% | Room utilization |
| **ADR** | Total Revenue ÷ Rooms Sold | > 85,000 RWF | Average room price |
| **RevPAR** | Total Revenue ÷ Total Rooms | > 65,000 RWF | Revenue efficiency |
| **Total Revenue** | SUM(Reservation Amounts) | Monthly growth | Overall performance |

## **2. Customer KPIs**
| KPI | Formula | Target | Purpose |
|-----|---------|---------|---------|
| **Customer Satisfaction** | (Positive Reviews ÷ Total Reviews) × 100 | > 90% | Service quality |
| **Repeat Guest Rate** | (Repeat Customers ÷ Total Customers) × 100 | > 30% | Loyalty |
| **Cancellation Rate** | (Cancelled ÷ Total Bookings) × 100 | < 10% | Booking reliability |
| **Average Stay Length** | AVG(Check-out - Check-in) | > 2.5 days | Guest duration |

## **3. Operational KPIs**
| KPI | Formula | Target | Purpose |
|-----|---------|---------|---------|
| **Room Turnaround** | Time(Room Cleaned - Guest Out) | < 2 hours | Housekeeping efficiency |
| **Check-in Time** | AVG(Actual Check-in - Scheduled) | < 15 mins | Front desk efficiency |
| **Maintenance Response** | Time(Fixed - Reported) | < 4 hours | Maintenance speed |
| **Staff Productivity** | Rooms Cleaned per Staff per Day | > 15 rooms | Staff efficiency |

## **4. Marketing KPIs**
| KPI | Formula | Target | Purpose |
|-----|---------|---------|---------|
| **Booking Lead Time** | AVG(Check-in - Booking Date) | > 14 days | Planning horizon |
| **Channel Performance** | Bookings by Source | Direct > 40% | Marketing ROI |
| **Seasonal Demand** | Occupancy by Month | June-Aug > 85% | Peak planning |
| **Customer Acquisition** | New Customers ÷ Marketing Spend | < 5,000 RWF | Marketing efficiency |

## **5. BI Implementation KPIs**
| KPI | Target | Purpose |
|-----|---------|---------|
| **Data Accuracy** | > 99% | Report reliability |
| **Report Timeliness** | < 1 hour from EOD | Decision speed |
| **User Adoption** | > 80% of managers | System effectiveness |
| **Query Performance** | < 5 seconds | User experience |

## **6. Sample Calculations (PL/SQL)**
```sql
-- Occupancy Rate for today
SELECT ROUND(
    (COUNT(DISTINCT r.room_id) * 100.0) / 
    (SELECT COUNT(*) FROM rooms WHERE status != 'MAINTENANCE'), 
    2
) as occupancy_rate
FROM reservations r
WHERE SYSDATE BETWEEN r.check_in_date AND r.check_out_date
AND r.status IN ('CHECKED_IN', 'CONFIRMED');

-- ADR (Average Daily Rate)
SELECT ROUND(AVG(total_amount / (check_out_date - check_in_date)), 2) as ADR
FROM reservations
WHERE status != 'CANCELLED'
AND check_out_date > check_in_date;

-- RevPAR
SELECT 
    ROUND(SUM(total_amount) / (SELECT COUNT(*) FROM rooms), 2) as RevPAR
FROM reservations
WHERE status != 'CANCELLED'
AND check_in_date >= TRUNC(SYSDATE, 'MONTH');
