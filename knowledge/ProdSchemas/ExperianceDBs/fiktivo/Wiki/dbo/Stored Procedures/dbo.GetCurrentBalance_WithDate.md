# dbo.GetCurrentBalance_WithDate

> Calculates an affiliate's total outstanding (unpaid) commission balance filtered to a specific date range, summing across sales, chargebacks, CPA, leads, registrations, copy traders, first positions, and eCost commission types.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A |
| **Author** | Guy Mansano (modified by Amir Moualem; updated by Noga, Feb 2023) |
| **Created** | 2011-12-04 |

---

## 1. Business Meaning

Affiliates and administrators need to view the commission balance that was earned within a specific time window -- for example, to reconcile a monthly statement or to investigate a discrepancy in a given period. This procedure calculates that date-bounded outstanding balance by querying the new commission table schema introduced in 2023 (PART-1052).

The procedure sums unpaid commissions across eight distinct commission streams, each from its own source table pair, and returns their total as a single float value. Only commissions where Paid = 0 and Valid != 0 are included, ensuring that already-paid or invalidated records do not inflate the balance.

This procedure is called by dbo.GetCurrentBalance when the caller supplies at least one non-NULL date boundary.

---

## 2. Business Logic

### 2.1 Date Range Defaulting

**What**: Provides all-time boundaries when one or both date parameters are NULL.

**Columns/Parameters Involved**: `@FromDate`, `@ToDate`

**Rules**:
- If @FromDate IS NULL, it defaults to '1900-01-01'
- If @ToDate IS NULL, it defaults to '9999-01-01'
- This allows partial date ranges (e.g., only @FromDate set) to work correctly

### 2.2 Sales Commission (ClosedPositions)

**What**: Sums unpaid sales commission from the AffiliateCommission schema.

**Columns/Parameters Involved**: `AffiliateCommission.ClosedPosition`, `AffiliateCommission.ClosedPositionCommission`

**Rules**:
- Filters on CC.AffiliateID, C.Valid != 0, CC.Paid = 0, C.CommissionDate within range
- Uses new commission tables (post PART-1052 migration)

### 2.3 Chargeback Commission

**What**: Sums unpaid chargeback commissions (CreditTypeID IN (4,5)).

**Rules**:
- CreditTypeID 4 and 5 represent chargeback credit types
- Filters on CreditDate within range, Valid != 0, Paid = 0

### 2.4 CPA Commission

**What**: Sums unpaid CPA commissions (CreditTypeID = 1).

**Rules**:
- CreditTypeID 1 represents CPA credits
- Filters on CreditDate within range

### 2.5 Leads Commission

**What**: Sums unpaid lead commissions from legacy tblaff_Leads tables.

**Rules**:
- Requires AffiliateSaleAccepted != 0 and Valid != 0
- Date filter applied on ORDER_DATE

### 2.6 Registrations Commission

**What**: Sums unpaid registration commissions.

**Rules**:
- Joins AffiliateCommission.Registration to dbo.tblaff_Registrations_Commissions
- Date filter on RegistrationDate

### 2.7 Copy Traders Commission

**What**: Sums unpaid copy trader commissions.

**Rules**:
- Joins tblaff_CopyTraders to tblaff_CopyTraders_Commissions
- Date filter on ORDER_DATE

### 2.8 First Positions Commission

**What**: Sums unpaid first-position commissions.

**Rules**:
- Joins tblaff_FirstPositions to tblaff_FirstPositions_Commissions
- Date filter on ORDER_DATE

### 2.9 eCost Commission

**What**: Sums unpaid eCost commissions.

**Rules**:
- Joins tblaff_eCost to tblaff_eCost_Commissions
- Date filter on ORDER_DATE

### 2.10 Final Summation

**What**: Returns the sum of all eight component values as a single float.

**Rules**:
- ISNULL / IsNull wrapping ensures each component defaults to 0.0 if no matching rows exist
- The final SELECT adds all eight variables and returns the result aliased as "float"

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Parameter | Direction | Type | Default | Description |
|---|-----------|-----------|------|---------|-------------|
| 1 | @affiliateId | IN | int | (required) | The AffiliateID for which the date-bounded outstanding balance is calculated. |
| 2 | @FromDate | IN | datetime | NULL | Start of the date range. Defaults to '1900-01-01' if NULL. |
| 3 | @ToDate | IN | datetime | NULL | End of the date range. Defaults to '9999-01-01' if NULL. |

---

## 5. Relationships

### 5.1 Tables Written

None. Read-only procedure.

### 5.2 Tables Read

| Table | Operation | Notes |
|-------|-----------|-------|
| AffiliateCommission.ClosedPosition | SELECT | Sales commission events, date-filtered |
| AffiliateCommission.ClosedPositionCommission | SELECT (INNER JOIN) | Commission amounts for closed positions |
| AffiliateCommission.Credit | SELECT | CPA and chargeback credit events |
| AffiliateCommission.CreditCommission | SELECT (INNER JOIN) | Commission amounts for credits |
| dbo.tblaff_Leads | SELECT | Lead events |
| dbo.tblaff_Leads_Commissions | SELECT (LEFT JOIN) | Commission amounts for leads |
| AffiliateCommission.Registration | SELECT | Registration events |
| dbo.tblaff_Registrations_Commissions | SELECT (INNER JOIN) | Commission amounts for registrations |
| dbo.tblaff_CopyTraders | SELECT | Copy trader events |
| dbo.tblaff_CopyTraders_Commissions | SELECT (LEFT JOIN) | Commission amounts for copy traders |
| dbo.tblaff_FirstPositions | SELECT | First position events |
| dbo.tblaff_FirstPositions_Commissions | SELECT (LEFT JOIN) | Commission amounts for first positions |
| dbo.tblaff_eCost | SELECT | eCost events |
| dbo.tblaff_eCost_Commissions | SELECT (LEFT JOIN) | Commission amounts for eCost |

### 5.3 Result Set

| Column | Source | Description |
|--------|--------|-------------|
| float | Calculated | The total outstanding unpaid balance for the affiliate within the specified date range |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetCurrentBalance_WithDate (stored procedure)
+-- AffiliateCommission.ClosedPosition / ClosedPositionCommission (tables)
+-- AffiliateCommission.Credit / CreditCommission (tables)
+-- dbo.tblaff_Leads / tblaff_Leads_Commissions (tables)
+-- AffiliateCommission.Registration (table)
+-- dbo.tblaff_Registrations_Commissions (table)
+-- dbo.tblaff_CopyTraders / tblaff_CopyTraders_Commissions (tables)
+-- dbo.tblaff_FirstPositions / tblaff_FirstPositions_Commissions (tables)
+-- dbo.tblaff_eCost / tblaff_eCost_Commissions (tables)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPosition | Table | Sales commission events |
| AffiliateCommission.ClosedPositionCommission | Table | Sales commission amounts |
| AffiliateCommission.Credit | Table | CPA and chargeback events |
| AffiliateCommission.CreditCommission | Table | CPA and chargeback amounts |
| dbo.tblaff_Leads | Table | Lead events |
| dbo.tblaff_Leads_Commissions | Table | Lead commission amounts |
| AffiliateCommission.Registration | Table | Registration events |
| dbo.tblaff_Registrations_Commissions | Table | Registration commission amounts |
| dbo.tblaff_CopyTraders | Table | Copy trader events |
| dbo.tblaff_CopyTraders_Commissions | Table | Copy trader commission amounts |
| dbo.tblaff_FirstPositions | Table | First position events |
| dbo.tblaff_FirstPositions_Commissions | Table | First position commission amounts |
| dbo.tblaff_eCost | Table | eCost events |
| dbo.tblaff_eCost_Commissions | Table | eCost commission amounts |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.GetCurrentBalance | Stored Procedure | Calls this procedure when @FromDate or @ToDate is non-NULL |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Notes

- SET NOCOUNT ON suppresses rowcount messages
- All table accesses use WITH (NOLOCK) or with(nolock); accepts dirty reads
- Updated Feb 2023 by Noga to use new AffiliateCommission schema tables and fix outstanding balance calculation bug (PART-1052); bonuses removed in that update
- Note in source code: a comment "???make sure with Gil" on CPA CreditDate and Registration RegistrationDate filtering was left in the code during the 2023 migration
- The @resultCopyTraders variable is calculated but not used in the final summation -- CopyTraders appear to have been removed from the WithDate variant during PART-1052; the variable declaration and SELECT remain as dead code

---

## 8. Sample Queries

### 8.1 Get Q1 2025 outstanding balance

```sql
EXEC dbo.GetCurrentBalance_WithDate
    @affiliateId = 1001,
    @FromDate    = '2025-01-01',
    @ToDate      = '2025-03-31 23:59:59.997';
```

### 8.2 Get balance from start of year to today

```sql
EXEC dbo.GetCurrentBalance_WithDate
    @affiliateId = 1001,
    @FromDate    = '2025-01-01',
    @ToDate      = NULL;
```

### 8.3 Direct query for unpaid sales in a date range

```sql
SELECT ISNULL(SUM(CC.Commission), 0) AS UnpaidSales
FROM AffiliateCommission.ClosedPosition C WITH (NOLOCK)
JOIN AffiliateCommission.ClosedPositionCommission CC WITH (NOLOCK)
    ON C.ClosedPositionID = CC.ClosedPositionID
WHERE CC.AffiliateID = 1001
  AND C.Valid <> 0
  AND CC.Paid = 0
  AND C.CommissionDate BETWEEN '2025-01-01' AND '2025-03-31';
```

---

## 9. Atlassian Knowledge Sources

- PART-1052 (Feb 2023, Noga): Migrated balance calculation to new AffiliateCommission schema tables, fixed outstanding balance bug, and removed bonuses from the balance calculation.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.4/10*
*Object: dbo.GetCurrentBalance_WithDate | Type: Stored Procedure | Source: fiktivo/dbo/Stored Procedures/dbo.GetCurrentBalance_WithDate.sql*
