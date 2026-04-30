# BackOffice.CustomerMTDAggregatedData_1

> Monthly financial aggregates per customer per calendar month (Month-To-Date), recording each customer's financial activity summed by year and month. Third tier of the three-tier aggregation system alongside BackOffice.CustomerAllTimeAggregatedData_1 (lifetime) and BackOffice.CustomerDTDAggregatedData_1 (daily).

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | (CID, Year, Month) - composite CLUSTERED PK |
| **Partition** | No (stored ON [HISTORY] filegroup with DATA_COMPRESSION=PAGE) |
| **Indexes** | 2 active (1 clustered composite PK + 1 NC on CID) |

---

## 1. Business Meaning

BackOffice.CustomerMTDAggregatedData_1 stores one row per customer per active month - a month being any calendar month in which the customer had financial activity. Together with the AllTime and DTD tables, it forms the complete three-tier aggregation system that powers all BackOffice financial reporting.

The MTD granularity enables month-by-month analysis: monthly deposit totals for chargeback risk scoring, monthly trading volumes for VIP tier evaluations, monthly compensation amounts for accounting reconciliation, and month-over-month trend reporting. It is more compact than DTD (7.9M vs 9.9M rows) because multiple days in a month collapse to a single row.

**Naming**: "MTD" = Month-To-Date. The "_1" suffix mirrors BackOffice.CustomerAllTimeAggregatedData_1 and CustomerDTDAggregatedData_1 - original table renamed to _1 and a view (BackOffice.CustomerMTDAggregatedData) created on top for backward compatibility.

7.905M rows as of 2026-03-17 covering 6.736M unique customers across 103 unique year/month combinations (earliest: 2013, latest: 2026).

---

## 2. Business Logic

### 2.1 Monthly Aggregation from Same Pipeline

**What**: Monthly totals are maintained by the same near-real-time upsert procedure as the AllTime and DTD tables.

**Columns Involved**: All `Total*` columns, `Year`, `Month`

**Rules**:
- `UpsertIntoAggregationTablesAction` is the sole writer. In the same transaction that upserts AllTime and DTD, it also upserts into this table.
- The procedure aggregates credit events by (CID, Year(Date), Month(Date)).
- Same CreditTypeID -> column mapping as AllTime and DTD (see BackOffice.CustomerAllTimeAggregatedData_1 Section 2.1).
- Year and Month are stored as separate INT columns (not a date), enabling direct filtering: `WHERE Year = 2026 AND Month = 3`.
- INSERT guard: New rows only inserted if CID exists in Customer.CustomerStatic (see upsert code: `EXISTS (SELECT * FROM Customer.CustomerStatic C WHERE C.CID=...)`). CID=1 is explicitly excluded.
- No LastRealizedEquity column (unlike DTD and AllTime). MTD tracks financial flow only, not equity snapshots.

### 2.2 Relationship to AllTime and DTD

See BackOffice.CustomerDTDAggregatedData_1 Section 2.2 for the complete three-tier description. At the MTD level:
- SUM(TotalDeposit GROUP BY Year, Month) across DTD rows = MTD rows for the same CID.
- SUM(TotalDeposit) across all MTD rows for a CID = AllTime.TotalDeposit for that CID.

### 2.3 NOCHECK FK Constraint

**What**: An explicit (but disabled) FK on CID enforces referential integrity against Customer.CustomerStatic at the constraint definition level, but is not enforced at runtime.

**Rules**:
- `FK_BOCMTDAD_TSCMA_New`: CID REFERENCES Customer.CustomerStatic(CID) WITH NOCHECK - constraint exists but is disabled.
- NOCHECK means existing rows were NOT validated when the constraint was added, and new rows are NOT checked.
- The CID=1 exclusion in the INSERT guard and the `EXISTS (Customer.CustomerStatic)` check serve as the functional referential integrity mechanism instead.

---

## 3. Data Overview

| Scale Metric | Value |
|-------------|-------|
| Total rows (2026-03-17) | 7.905M |
| Unique CIDs | 6.736M |
| Unique year/month combinations | 103 |
| Date range | 2013 to 2026 (earliest to latest Year) |
| Average monthly rows per customer | 1.17 (most customers active in 1-2 months) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | VERIFIED | Customer account ID. Part of composite PK. FK (NOCHECK) to Customer.CustomerStatic.CID. |
| 2 | Year | int | NO | - | VERIFIED | Calendar year of the financial activity (e.g., 2026). Part of composite PK. Stored as INT, not as part of a DATE type. |
| 3 | Month | int | NO | - | VERIFIED | Calendar month of the financial activity (1=January through 12=December). Part of composite PK. |
| 4 | TotalProfit | decimal(34,4) | NO | 0 | VERIFIED | Net realized profit from closed positions in this month. |
| 5 | TotalDeposit | decimal(34,4) | NO | 0 | VERIFIED | Total deposit amount in this month (CreditTypeID=1). |
| 6 | TotalBonus | decimal(34,4) | NO | 0 | VERIFIED | Total bonus credits received in this month (CreditTypeID=7). |
| 7 | TotalInvestment | decimal(34,4) | NO | 0 | VERIFIED | Total funds locked into positions in this month (CreditTypeID=3,13). |
| 8 | TotalCommission | decimal(34,4) | NO | 0 | VERIFIED | Total commissions charged on closed positions in this month. |
| 9 | TotalVolume | decimal(34,6) | YES | 0 | VERIFIED | Total trading volume in units in this month. Nullable for legacy rows. |
| 10 | TotalLot | decimal(34,6) | YES | 0 | VERIFIED | Total lots traded in this month. Nullable for legacy rows. |
| 11 | TotalChampWin | decimal(34,4) | NO | 0 | VERIFIED | Championship prize payouts received in this month (CreditTypeID=5). |
| 12 | TotalCashout | decimal(34,4) | NO | 0 | VERIFIED | Total successful withdrawal payments in this month (CreditTypeID=2). |
| 13 | TotalCashoutRequest | decimal(34,4) | NO | 0 | VERIFIED | Total withdrawal requests submitted in this month (CreditTypeID=9,15 negative). |
| 14 | TotalReverseCashout | decimal(34,4) | NO | 0 | VERIFIED | Total reversed withdrawals in this month (CreditTypeID=8,15 positive). |
| 15 | TotalCompensation | decimal(34,4) | NO | 0 | VERIFIED | Total compensation payments received in this month (CreditTypeID=6). |
| 16 | TotalGameCount | bigint | NO | 0 | CODE-BACKED | Game/contest count for this month. Always 0 in current code (game tracking inactive). |
| 17 | TotalPositionCount | bigint | NO | 0 | VERIFIED | Number of positions closed in this month. |
| 18 | TotalLoginCount | bigint | NO | 0 | VERIFIED | Number of login sessions in this month. |
| 19 | TotalLoggedTime | bigint | YES | 0 | CODE-BACKED | Total seconds logged in during this month. Nullable. |
| 20 | TotalEndOfWeekFee | decimal(34,4) | NO | 0 | VERIFIED | End-of-week fees charged in this month (CreditTypeID=14). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | FK (WITH NOCHECK - disabled) | Customer account scope; disabled at runtime |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.CustomerMTDAggregatedData | (CID, Year, Month) | VIEW WRAPPER | View wrapping this table for backward compatibility |
| BackOffice.UpsertIntoAggregationTablesAction | (CID, Year, Month) | WRITER/MODIFIER | Sole data population mechanism |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerMTDAggregatedData_1 (table)
- FK (NOCHECK): Customer.CustomerStatic
- Written by same pipeline as AllTime and DTD tables
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.CustomerStatic | Table | FK (NOCHECK) on CID; INSERT guard checks CID exists here |
| History.ActiveCredit | Table | Event source for all monthly financial deltas (via upsert pipeline) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerMTDAggregatedData | View | WRAPPER - exposes table to legacy readers |
| BackOffice.UpsertIntoAggregationTablesAction | Procedure | WRITER - sole population mechanism |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BOCMTDAD_New | CLUSTERED PK | CID ASC, Year ASC, Month ASC | - | - | Active (PAGE compressed, FILLFACTOR=90) |
| BOCMTDAD_CUSTOMER_New | NC | CID ASC | - | - | Active (FILLFACTOR=90, no PAGE compression) |

**Storage**: Data on [HISTORY] filegroup with DATA_COMPRESSION=PAGE on clustered PK. NC index on [HISTORY] without PAGE compression.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BOCMTDAD_New | PK | (CID, Year, Month) - one row per customer per calendar month |
| FK_BOCMTDAD_TSCMA_New | FK (NOCHECK) | CID -> Customer.CustomerStatic(CID) - defined but not enforced |
| BOCMTDAD_TOTALPROFIT_New through BOCMTDAD_TOTALENDOFWEEKFEE_New | DEFAULT | All Total* columns default to 0 |

---

## 8. Sample Queries

### 8.1 Get a customer's monthly financial activity
```sql
SELECT
    m.Year,
    m.Month,
    m.TotalDeposit,
    m.TotalCashout,
    m.TotalProfit,
    m.TotalPositionCount,
    m.TotalBonus
FROM BackOffice.CustomerMTDAggregatedData_1 m WITH (NOLOCK)
WHERE m.CID = 12345
ORDER BY m.Year DESC, m.Month DESC
```

### 8.2 Monthly deposit totals for chargeback risk analysis (last 3 months)
```sql
SELECT
    m.CID,
    SUM(m.TotalDeposit) AS DepositLast3Months,
    SUM(m.TotalCashout) AS CashoutLast3Months
FROM BackOffice.CustomerMTDAggregatedData_1 m WITH (NOLOCK)
WHERE m.CID = 12345
  AND ((m.Year = 2026 AND m.Month >= 1)
    OR (m.Year = 2025 AND m.Month >= 12))
GROUP BY m.CID
```

### 8.3 Platform-wide monthly deposit trend
```sql
SELECT
    m.Year,
    m.Month,
    SUM(m.TotalDeposit) AS TotalDeposits,
    COUNT(DISTINCT m.CID) AS DepositingCustomers
FROM BackOffice.CustomerMTDAggregatedData_1 m WITH (NOLOCK)
WHERE m.Year >= 2025
  AND m.TotalDeposit > 0
GROUP BY m.Year, m.Month
ORDER BY m.Year DESC, m.Month DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to CustomerMTDAggregatedData. See BackOffice.CustomerAllTimeAggregatedData_1 for DWH pipeline context applicable to all three aggregation tables.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 8.8/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 10 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerMTDAggregatedData_1 | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.CustomerMTDAggregatedData_1.sql*
