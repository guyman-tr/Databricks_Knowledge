# BI_DB_dbo.BI_DB_EndOfDayReport_Cashouts

> 16-row hourly TRUNCATE+INSERT cashout operations dashboard summarizing withdrawal request counts by status and time frame over the last 3 months. Populated by `SP_H_EndOfDayReport_Cashouts` from `External_etoro_Billing_Withdraw` joined with `Dim_CashoutStatus`. Each row represents a unique combination of cashout status and age bucket.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `External_etoro_Billing_Withdraw` + `Dim_CashoutStatus` via `SP_H_EndOfDayReport_Cashouts` |
| **Refresh** | SB_Hourly, hourly TRUNCATE+INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a real-time operational dashboard for the payments team, showing how many cashout (withdrawal) requests exist in each status bucket across different time horizons. It refreshes hourly to give the operations team a current view of cashout pipeline health.

**Grain**: One row per (COStatus, CashoutStatus, TimeFrame) combination. Only ~16 rows at any time.

**Population**: Withdrawals from the last 3 months, excluding FundingTypeID=27, CashoutStatusID=4 (Cancelled), and CashoutReasonID IN (12=Foreclose account, 15=Affiliate Payment).

**Key semantics**:
- `COStatus` = raw status from Dim_CashoutStatus (Processed, Pending, InProcess, Partially Processed, Rejected, Reversed)
- `CashoutStatus` = grouped status (3 buckets: Processed, Pending-Sent, Pending-Not Sent)
- `TimeFrame` = age bucket relative to today (T, T-1, T-2 to T-7, T-7 to T-15, Over 15 days)

---

## 2. Business Logic

### 2.1 Cashout Status Grouping

**What**: Maps raw statuses to 3 operational groups.
**Columns Involved**: COStatus, CashoutStatus
**Rules**:
- 'Processed' → 'Cashout Processed'
- 'Pending', 'Partially Processed', 'InProcess' → 'Cashouts Pending - Payment Sent'
- Everything else (Rejected, Reversed) → 'Cashouts Pending -Payment Not Sent'
- Note: SP has inconsistency — GROUP BY CASE only maps 'Pending' to Sent, but SELECT CASE also includes 'Partially Processed' and 'InProcess'

### 2.2 Time Frame Buckets

**What**: Ages cashout requests into 5 buckets.
**Columns Involved**: TimeFrame
**Rules**:
- T = requested today
- T-1 = requested yesterday
- T-2 to T-7 = 2-7 days ago (note: typo "tO" in value)
- T-7 to T-15 = 8-15 days ago
- Over 15 days = older than 15 days

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — 16 rows, no optimization needed. Query the entire table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Total pending cashouts | `SELECT SUM(NoOfCashouts) WHERE CashoutStatus LIKE 'Cashouts Pending%'` |
| Today's cashout volume | `WHERE TimeFrame = 'T'` |
| Aging analysis | `SELECT TimeFrame, SUM(NoOfCashouts) GROUP BY TimeFrame` |

### 3.3 Common JOINs

None needed — table is self-contained and very small.

### 3.4 Gotchas

- **IDENTITY ID column**: System-generated, resets on each TRUNCATE+INSERT — not stable across refreshes
- **Hourly refresh**: Data changes every hour — queries at different times give different results
- **TimeFrame typo**: 'T-2 tO T-7' has lowercase 'to' with uppercase 'O'
- **CashoutStatus GROUP BY inconsistency**: The SELECT CASE and GROUP BY CASE have different condition lists for the 'Pending - Sent' bucket
- **No date column**: Table has no date/DateID — it's always "as of now"
- **Over 15 days dominates**: The Processed/Over 15 days bucket contains ~1.9M cashouts — the vast majority

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki documentation |
| Tier 2 | Derived from SP code analysis |
| Tier 3 | Inferred from live data patterns |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / propagation |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ID | int | NO | System-generated identity column (IDENTITY(1,1)). Resets on each TRUNCATE+INSERT cycle. Not meaningful for business logic. (Tier 2 — DDL IDENTITY) |
| 2 | NoOfCashouts | bigint | YES | Count of distinct WithdrawIDs in this status/timeframe bucket. COUNT(DISTINCT WithdrawID) from External_Billing_Withdraw. (Tier 2 — SP_H_EndOfDayReport_Cashouts) |
| 3 | COStatus | varchar(max) | YES | Raw cashout status name from Dim_CashoutStatus.Name. Values: Processed, Pending, InProcess, Partially Processed, Rejected, Reversed. (Tier 2 — SP_H_EndOfDayReport_Cashouts, via Dim_CashoutStatus) |
| 4 | CashoutStatus | varchar(max) | YES | Grouped cashout status: 'Cashout Processed', 'Cashouts Pending - Payment Sent', or 'Cashouts Pending -Payment Not Sent'. Derived from COStatus via CASE expression. (Tier 2 — SP_H_EndOfDayReport_Cashouts) |
| 5 | TimeFrame | varchar(max) | YES | Age bucket relative to today: 'T' (today), 'T-1' (yesterday), 'T-2 tO T-7' (2-7 days), 'T-7 to T-15' (8-15 days), 'Over 15 days'. Note: 'tO' capitalization inconsistency. (Tier 2 — SP_H_EndOfDayReport_Cashouts) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp of the last hourly refresh (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| NoOfCashouts | External_Billing_Withdraw | WithdrawID | COUNT(DISTINCT) per group |
| COStatus | Dim_CashoutStatus | Name | Direct |
| CashoutStatus | Computed | Dim_CashoutStatus.Name | CASE grouping |
| TimeFrame | Computed | RequestDate | CASE age bucket |

### 5.2 ETL Pipeline

```
etoro.Billing.Withdraw (withdrawal requests)
  |-- Generic Pipeline → lake --|
  v
BI_DB_dbo.External_etoro_Billing_Withdraw
DWH_dbo.Dim_CashoutStatus (status names)
  |
  |-- SP_H_EndOfDayReport_Cashouts (hourly TRUNCATE+INSERT) --|
  |   3-month window, excl Cancelled/Foreclose/Affiliate       |
  |   GROUP BY status + timeframe                               |
  v
BI_DB_dbo.BI_DB_EndOfDayReport_Cashouts (16 rows)
  |
  (UC: _Not_Migrated)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

None — aggregated summary table with no FK columns.

### 6.2 Referenced By (other objects point to this)

No known downstream consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Pending Cashout Summary

```sql
SELECT CashoutStatus, TimeFrame, NoOfCashouts
FROM [BI_DB_dbo].[BI_DB_EndOfDayReport_Cashouts]
WHERE CashoutStatus LIKE 'Cashouts Pending%'
ORDER BY TimeFrame
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 7/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_EndOfDayReport_Cashouts | Type: Table | Production Source: SP_H_EndOfDayReport_Cashouts (hourly ops dashboard)*
