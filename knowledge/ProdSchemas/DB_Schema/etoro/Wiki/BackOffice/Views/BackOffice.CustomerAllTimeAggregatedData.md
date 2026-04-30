# BackOffice.CustomerAllTimeAggregatedData

> Canonical lifetime financial and activity aggregates view unifying the standard trading pipeline (_1 table) and the MIMO/eToro Money pipeline, presenting a single all-time summary row per customer regardless of which payment channels they use.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | View |
| **Key Identifier** | CID (from base tables) |
| **Partition** | N/A |
| **Indexes** | N/A (defined on base tables) |

---

## 1. Business Meaning

`BackOffice.CustomerAllTimeAggregatedData` is the canonical all-time financial summary for every customer on the platform. It combines data from two physical tables via a UNION ALL:

1. **BackOffice.CustomerAllTimeAggregatedData_1**: Lifetime aggregates for customers in the standard trading payment pipeline (deposits via card, bank, eWallet, etc.). Contains trading metrics (profit, volume, commissions) and billing totals. Updated in batch by `UpsertIntoAggregationTablesAction`.

2. **BackOffice.CustomerMIMOAllTimeAggregatedData**: Lifetime financial totals for customers transacting through the MIMO (eToro Money) payment pipeline. Contains billing totals only (no trading metrics). Updated event-by-event by `UpsertMIMOAggregation`.

The view ensures that:
- Customers who used **both** pipelines get a merged row (trading metrics from _1, billing totals from MIMO).
- Customers who used **only MIMO** (no standard pipeline record) still appear with zeros for trading metrics.
- All downstream consumers (`GetCustomerByCID`, `GetRiskExposureReport`, DWH pipelines, SalesForce sync) always query this view - never the raw tables directly.

This is the table that was renamed in February 2021: prior to that date, `BackOffice.CustomerAllTimeAggregatedData` was a physical table. That table was converted to this view (backward-compatible) and the physical data moved to `BackOffice.CustomerAllTimeAggregatedData_1`.

---

## 2. Business Logic

### 2.1 Two-Pipeline Merge with UNION ALL

**What**: Unifies standard and MIMO customer lifetime aggregates into a single row per CID.

**Columns/Tables Involved**: CustomerAllTimeAggregatedData_1 (A), CustomerMIMOAllTimeAggregatedData (M)

**Rules**:
- **Branch 1 (standard + optional MIMO overlay)**: All CIDs in `CustomerAllTimeAggregatedData_1` (A). LEFT JOINs to M on CID.
  - **Trading metrics** (TotalProfit, TotalInvestment, TotalCommission, TotalVolume, TotalLot, TotalChampWin, TotalGameCount, TotalPositionCount, TotalLoginCount, TotalLoggedTime, TotalEndOfWeekFee) come exclusively from A.
  - **Billing totals** (TotalDeposit, TotalBonus, TotalCashout, TotalCashoutRequest, TotalReverseCashout, TotalCompensation) come from M if present, defaulting to 0 via `ISNULL(M.col, CAST(0 AS MONEY))`.
  - **LastUpdate**: `MAX(A.LastUpdate, M.LastUpdate)` - the most recent update from either pipeline.
  - **LastOccurredTriggerToSF**: `MAX(A.LastOccurredTriggerToSF, M.LastOccurredTriggerToSF)` - most recent SalesForce trigger from either pipeline.
  - **Deposit dates** (FirstTimeDepositAttemptDate, FirstTimeDepositSuccessDate): from M (MIMO pipeline tracks these specifically).
  - **Session/access fields** (FirstTimeCashierLoginDate, LastLoggedInOn, LastClientIp, RealizedEquityLastChange, LastRealizedEquity): from A only.

- **Branch 2 (MIMO-only customers)**: CIDs in M that have NO record in A (`WHERE A.CID IS NULL` after LEFT JOIN). These are eToro Money customers who never entered the standard pipeline.
  - All trading metrics are 0 or CAST(0 AS MONEY).
  - Billing totals come from M (with ISNULL to 0 for nullable columns).
  - Session/access fields are NULL (never used the standard trading platform).

**Diagram**:
```
CustomerAllTimeAggregatedData_1 (A)   CustomerMIMOAllTimeAggregatedData (M)
     6.736M rows (standard + both)          4.674M rows (MIMO pipeline)
                 |                                     |
                 +----------LEFT JOIN on CID-----------+
                 |
       Branch 1: All CIDs in A
         TotalDeposit = ISNULL(M.TotalDeposit, 0)   <- MIMO billing wins
         TotalProfit  = A.TotalProfit               <- Trading from A
         LastUpdate   = MAX(A.LastUpdate, M.LastUpdate)
                 |
       UNION ALL
                 |
       Branch 2: CIDs in M but NOT in A (MIMO-only)
         TotalProfit  = 0   <- No trading activity
         TotalDeposit = ISNULL(M.TotalDeposit, 0)
         LastLoggedIn = NULL
                 |
                 v
     BackOffice.CustomerAllTimeAggregatedData
     (single row per CID, all pipelines merged)
```

### 2.2 Billing Totals Sourced from MIMO Table

**What**: The billing-related totals (deposits, cashouts, bonuses, compensation) are sourced from the MIMO table even for standard-pipeline customers.

**Why**: The MIMO table is the authoritative source for billing aggregates because it is maintained with individual credit events via MERGE (more accurate for MIMO flows). For customers using both pipelines, the MIMO totals represent the complete picture.

**Impact**: Consumers reading TotalDeposit from this view are reading MIMO-sourced data, not the standard _1 table values.

---

## 3. Data Overview

This view merges data from two physical tables:
- `BackOffice.CustomerAllTimeAggregatedData_1`: 6.736M rows (one per CID in standard pipeline)
- `BackOffice.CustomerMIMOAllTimeAggregatedData`: 4.674M rows (one per CID with MIMO activity)

Approximate view row count: ~6.7M+ (all _1 rows + MIMO-only CIDs not in _1).

---

## 4. Elements

| # | Element | Type | Source | Confidence | Description |
|---|---------|------|--------|------------|-------------|
| 1 | CID | int | A.CID / M.CID | CODE-BACKED | Customer ID - the row key. From _1 table in Branch 1, from MIMO table in Branch 2. |
| 2 | TotalProfit | money | A.TotalProfit | CODE-BACKED | Lifetime realized profit from all closed trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 3 | TotalDeposit | money | ISNULL(M.TotalDeposit, 0) | CODE-BACKED | Lifetime total deposits from the MIMO pipeline. For standard-only customers (no MIMO record) this is 0. Sourced from CustomerMIMOAllTimeAggregatedData. |
| 4 | TotalBonus | money | ISNULL(M.TotalBonus, 0) | CODE-BACKED | Lifetime total bonus credits from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData. |
| 5 | TotalInvestment | money | A.TotalInvestment | CODE-BACKED | Total funds locked into open trading positions. Zero for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 6 | TotalCommission | money | A.TotalCommission | CODE-BACKED | Total commission charges paid. From CustomerAllTimeAggregatedData_1. |
| 7 | TotalVolume | money | A.TotalVolume | CODE-BACKED | Total trading volume (sum of position sizes) in USD. From CustomerAllTimeAggregatedData_1. |
| 8 | TotalLot | money | A.TotalLot | CODE-BACKED | Total lot volume traded. From CustomerAllTimeAggregatedData_1. |
| 9 | TotalChampWin | money | A.TotalChampWin | CODE-BACKED | Total championship winnings. From CustomerAllTimeAggregatedData_1. |
| 10 | TotalCashout | money | ISNULL(M.TotalCashout, 0) | CODE-BACKED | Lifetime approved cashouts (withdrawals) from MIMO pipeline. Sourced from CustomerMIMOAllTimeAggregatedData. |
| 11 | TotalCashoutRequest | money | ISNULL(M.TotalCashoutRequest, 0) | CODE-BACKED | Total value of cashout requests (including pending). From CustomerMIMOAllTimeAggregatedData. |
| 12 | TotalReverseCashout | money | ISNULL(M.TotalReverseCashout, 0) | CODE-BACKED | Total reversed cashout amounts. From CustomerMIMOAllTimeAggregatedData. |
| 13 | TotalCompensation | money | ISNULL(M.TotalCompensation, 0) | CODE-BACKED | Total compensation credits from MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. |
| 14 | TotalGameCount | int | A.TotalGameCount | CODE-BACKED | Total number of games/contests participated in. From CustomerAllTimeAggregatedData_1. |
| 15 | TotalPositionCount | int | A.TotalPositionCount | CODE-BACKED | Total number of trading positions opened lifetime. From CustomerAllTimeAggregatedData_1. |
| 16 | TotalLoginCount | int | A.TotalLoginCount | CODE-BACKED | Total number of platform logins. From CustomerAllTimeAggregatedData_1. |
| 17 | TotalLoggedTime | int | A.TotalLoggedTime | CODE-BACKED | Total time spent logged in (seconds or minutes). From CustomerAllTimeAggregatedData_1. |
| 18 | TotalEndOfWeekFee | money | A.TotalEndOfWeekFee | CODE-BACKED | Total end-of-week inactivity fees charged. From CustomerAllTimeAggregatedData_1. |
| 19 | LastUpdate | datetime | MAX(A,M) | CODE-BACKED | Most recent update timestamp from either pipeline. `CASE WHEN A.LastUpdate > ISNULL(M.LastUpdate,'01-01-2000') THEN A.LastUpdate ELSE M.LastUpdate END`. |
| 20 | FirstTimeCashierLoginDate | datetime | A.FirstTimeCashierLoginDate | CODE-BACKED | Date customer first accessed the cashier/deposit flow. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 21 | FirstTimeDepositAttemptDate | datetime | M.FirstTimeDepositAttemptDate | CODE-BACKED | Date of customer's first deposit attempt via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. |
| 22 | FirstTimeDepositSuccessDate | datetime | M.FirstTimeDepositSuccessDate | CODE-BACKED | Date of customer's first successful deposit via MIMO pipeline. From CustomerMIMOAllTimeAggregatedData. |
| 23 | LastOccurredTriggerToSF | datetime | MAX(A,M) | CODE-BACKED | Most recent SalesForce sync trigger timestamp. Takes the later of A and M values. |
| 24 | LastLoggedInOn | datetime | A.LastLoggedInOn | CODE-BACKED | Most recent login timestamp. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 25 | LastClientIp | varchar | A.LastClientIp | CODE-BACKED | IP address from most recent login. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 26 | RealizedEquityLastChange | datetime | A.RealizedEquityLastChange | CODE-BACKED | Timestamp of last change to LastRealizedEquity. NULL for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |
| 27 | LastRealizedEquity | money | A.LastRealizedEquity | CODE-BACKED | Most recent snapshot of customer's realized equity balance. 0 for MIMO-only customers. From CustomerAllTimeAggregatedData_1. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| A | BackOffice.CustomerAllTimeAggregatedData_1 | Base Table | All-time aggregates for standard trading pipeline customers |
| M | BackOffice.CustomerMIMOAllTimeAggregatedData | Base Table | All-time aggregates for MIMO/eToro Money pipeline customers |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomerByCID | SELECT CustomerAllTimeAggregatedData | Reader | Retrieves lifetime aggregates for customer header/profile display |
| BackOffice.GetUserAdditionalDetails | SELECT CustomerAllTimeAggregatedData | Reader | Returns financial and activity details for a customer |
| BackOffice.GetRiskExposureReportPCIVersion | SELECT CustomerAllTimeAggregatedData | Reader | Used in risk exposure calculations |
| BackOffice.GetCashOutRequests_Main | SELECT CustomerAllTimeAggregatedData | Reader | Retrieves deposit totals for cashout eligibility checks |
| BackOffice.GetBlockedCustomers | SELECT CustomerAllTimeAggregatedData | Reader | Accesses aggregates for blocked customer reports |
| BackOffice.SetRiskClassificationNew | SELECT CustomerAllTimeAggregatedData | Reader | Reads lifetime totals for risk classification |
| BackOffice.UpsertIntoAggregationTablesAction | (writer to _1 base) | Indirect | Writes to CustomerAllTimeAggregatedData_1, not directly to view |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerAllTimeAggregatedData (view)
+-- BackOffice.CustomerAllTimeAggregatedData_1 (table)
|     +-- History.ActiveCredit -> UpsertIntoAggregationTablesAction (batch writer)
+-- BackOffice.CustomerMIMOAllTimeAggregatedData (table)
      +-- BackOffice.UpsertMIMOAggregation (event-driven writer, per credit)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.CustomerAllTimeAggregatedData_1 | Table | Branch 1 base - all CIDs in standard pipeline; provides trading and session metrics |
| BackOffice.CustomerMIMOAllTimeAggregatedData | Table | LEFT JOIN overlay for Branch 1; sole source for Branch 2 (MIMO-only CIDs); provides billing totals and deposit milestone dates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomerByCID | Stored Procedure | READER - customer profile and lifetime aggregates |
| BackOffice.GetUserAdditionalDetails | Stored Procedure | READER - customer detail pages |
| BackOffice.GetRiskExposureReportPCIVersion | Stored Procedure | READER - risk exposure reports |
| BackOffice.GetCashOutRequests_Main | Stored Procedure | READER - cashout processing |
| BackOffice.GetBlockedCustomers | Stored Procedure | READER - blocked customer reporting |
| BackOffice.SetRiskClassificationNew | Stored Procedure | READER - risk classification |
| BackOffice.CustomerAcceptance | Stored Procedure | READER - customer acceptance flow |
| BackOffice.GetPendingClosureAccountsByLastChangeDate | Stored Procedure | READER - account closure pipeline |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Index access is through the base tables:
- `CustomerAllTimeAggregatedData_1`: Clustered PK on CID, 4 NC indexes on milestone date columns
- `CustomerMIMOAllTimeAggregatedData`: Clustered PK on CID, NC on LastUpdate

### 7.2 Constraints

N/A for View. Constraints are defined on base tables.

---

## 8. Sample Queries

### 8.1 Get lifetime aggregates for a specific customer

```sql
SELECT CID,
       TotalDeposit,
       TotalCashout,
       TotalProfit,
       TotalVolume,
       TotalPositionCount,
       LastUpdate,
       FirstTimeDepositSuccessDate
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE CID = 12345;
```

### 8.2 Find high-value customers by lifetime deposit

```sql
SELECT TOP 100
    CID,
    TotalDeposit,
    TotalProfit,
    TotalCashout,
    LastLoggedInOn
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE TotalDeposit > 10000
ORDER BY TotalDeposit DESC;
```

### 8.3 Identify MIMO-only customers (no standard pipeline record)

```sql
-- MIMO-only customers have trading metrics = 0
SELECT CID,
       TotalDeposit,
       TotalCashout,
       TotalProfit  -- will be 0 for MIMO-only
FROM BackOffice.CustomerAllTimeAggregatedData WITH (NOLOCK)
WHERE TotalProfit = 0
  AND TotalDeposit > 0
  AND TotalPositionCount = 0;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this view.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 27 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11 (DDL, View Dep Scan, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerAllTimeAggregatedData | Type: View | Source: etoro/etoro/BackOffice/Views/BackOffice.CustomerAllTimeAggregatedData.sql*
