# dbo.GetCurrentBalance

> Dispatcher procedure that calculates an affiliate's outstanding (unpaid) commission balance by delegating to GetCurrentBalance_WithDate when a date range is supplied, or GetCurrentBalance_WithOutDate when no dates are provided.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Guy Mansano |
| **Created** | 2011-12-04 |

---

## 1. Business Meaning

Affiliates view their current outstanding balance on the portal to track how much commission they are owed before the next payment run. The balance is calculated by summing unpaid commissions across all commission types (sales, CPA, leads, registrations, copy traders, first positions, eCost) minus chargebacks.

This procedure is the single public entry point for balance calculation. It examines whether date range parameters have been provided and dispatches to one of two worker procedures:
- dbo.GetCurrentBalance_WithOutDate: returns the total unpaid balance across all time (optimised for the typical portal balance display)
- dbo.GetCurrentBalance_WithDate: returns unpaid commissions earned within a specified date window (used for period-specific reporting)

This dispatcher pattern allows callers to use one consistent procedure name regardless of whether they are requesting a date-filtered or all-time balance.

---

## 2. Business Logic

### 2.1 Date Range Detection and Dispatch

**What**: Routes the balance calculation to the appropriate worker procedure based on whether @FromDate and @ToDate are both NULL.

**Columns/Parameters Involved**: `@affiliateId`, `@FromDate`, `@ToDate`

**Rules**:
- If BOTH @FromDate and @ToDate are NULL: delegates to GetCurrentBalance_WithOutDate with @affiliateId only
- If EITHER @FromDate or @ToDate is non-NULL: delegates to GetCurrentBalance_WithDate with all three parameters
- The worker procedures handle their own NULL defaults for the date parameters internally
- The result set (a single float column named "float") is produced entirely by the worker procedure; this dispatcher has no SELECT of its own

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @affiliateId | IN | int | (required) | The AffiliateID for which to calculate the outstanding balance. |
| 2 | @FromDate | IN | datetime | NULL | Start of the date range filter. When both @FromDate and @ToDate are NULL, the all-time balance is returned. |
| 3 | @ToDate | IN | datetime | NULL | End of the date range filter. When both @FromDate and @ToDate are NULL, the all-time balance is returned. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

None directly. All data access is performed by the delegated worker procedures.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCurrentBalance (stored procedure)
+-- dbo.GetCurrentBalance_WithOutDate (stored procedure) [EXEC when no date range]
    +-- AffiliateCommission.ClosedPositionDailySummary (table)
    +-- AffiliateCommission.Credit / CreditCommission (tables)
    +-- dbo.tblaff_Leads / tblaff_Leads_Commissions (tables)
    +-- AffiliateCommission.Registration / RegistrationCommission (tables)
    +-- dbo.tblaff_eCost / tblaff_eCost_Commissions (tables)
+-- dbo.GetCurrentBalance_WithDate (stored procedure) [EXEC when date range provided]
    +-- AffiliateCommission.ClosedPosition / ClosedPositionCommission (tables)
    +-- (same commission type tables as above with date filters)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetCurrentBalance_WithOutDate | Stored Procedure | Called when no date range is provided |
| dbo.GetCurrentBalance_WithDate | Stored Procedure | Called when a date range is provided |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Affiliate portal balance display | Application | Calls this procedure to show the affiliate's current outstanding balance |
| Payment processing service | Application | Calls this procedure to determine the balance due before generating a payment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- No SET NOCOUNT ON in this dispatcher; the worker procedures manage their own NOCOUNT settings
- No explicit transaction; the balance calculation is read-only across the worker procedures
- The original procedure was authored by Guy Mansano on 2011-12-04; worker procedures were subsequently updated by Amir Moualem and Noga Rozen (see PART-1052)

---

## 8. Sample Queries

### 8.1 Get an affiliate's total outstanding balance (all time)

```sql
EXEC dbo.GetCurrentBalance @affiliateId = 1001;
```

### 8.2 Get balance earned in a specific date range

```sql
EXEC dbo.GetCurrentBalance
    @affiliateId = 1001,
    @FromDate    = '2025-01-01',
    @ToDate      = '2025-03-31';
```

### 8.3 Get balance from a start date with no end date

```sql
EXEC dbo.GetCurrentBalance
    @affiliateId = 1001,
    @FromDate    = '2025-01-01',
    @ToDate      = NULL;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. See dbo.GetCurrentBalance_WithDate and dbo.GetCurrentBalance_WithOutDate for PART-1052 context.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.0/10*
*Object: dbo.GetCurrentBalance | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCurrentBalance.sql*
