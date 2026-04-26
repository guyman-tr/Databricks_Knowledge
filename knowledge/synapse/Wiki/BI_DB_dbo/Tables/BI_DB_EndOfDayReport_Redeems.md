# BI_DB_dbo.BI_DB_EndOfDayReport_Redeems

> 111-row hourly TRUNCATE+INSERT redeem operations dashboard summarizing redeem request counts by status, request date, and time frame over the last 3 months. Populated by `SP_H_EndOfDayReport_Redeems` from `External_etoro_Billing_Redeem` joined with `Dim_RedeemStatus`. Each row represents a unique combination of redeem status, request date, and age bucket.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `External_etoro_Billing_Redeem` + `Dim_RedeemStatus` via `SP_H_EndOfDayReport_Redeems` |
| **Refresh** | SB_Hourly, hourly TRUNCATE+INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

This table is a real-time operational dashboard for the payments team, showing how many redeem (eToro Money withdrawal) requests exist in each status bucket across different time horizons. It refreshes hourly to monitor redeem pipeline health.

**Grain**: One row per (RedeemStatus, RequestDate, TimeFrame) combination. ~111 rows at any time.

**Population**: Redeem requests from the last 3 months, excluding RedeemStatusID IN (2=Rejected, 20=Terminated).

**Key semantics**:
- Unlike Cashouts, this table includes `RequestDate` as a separate column — providing per-day granularity within each time bucket
- `RedeemStatus` = raw status from Dim_RedeemStatus.DisplayName (TransactionDone, Pending, Approved, ReadyToRedeem, etc.)
- `Redeem Status Group` = binary grouping: Processed vs Pending
- `TimeFrame` = age bucket: Today, Past 7 days, Past 15 days, Over 30 days

---

## 2. Business Logic

### 2.1 Redeem Status Grouping

**What**: Binary processed/pending classification.
**Columns Involved**: RedeemStatus, Redeem Status Group
**Rules**:
- 'TransactionDone' → 'Redeem Processed'
- Everything else → 'Redeem Pending' (includes Pending, Approved, ReadyToRedeem, etc.)

### 2.2 Time Frame Buckets

**What**: Ages redeem requests into 4 buckets (simpler than Cashouts).
**Columns Involved**: TimeFrame
**Rules**:
- Today = requested today
- Past 7 days = 1-7 days ago
- Past 15 days = 8-15 days ago
- Over 30 days = older than 15 days (note: bucket name says 30 but threshold is 15)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP — 111 rows, no optimization needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Total pending redeems | `SELECT SUM(NoOfRedees) WHERE [Redeem Status Group] = 'Redeem Pending'` |
| Today's redeem requests | `WHERE TimeFrame = 'Today'` |
| Redeem aging | `SELECT TimeFrame, [Redeem Status Group], SUM(NoOfRedees) GROUP BY TimeFrame, [Redeem Status Group]` |

### 3.3 Common JOINs

None needed — table is self-contained.

### 3.4 Gotchas

- **Column name typo**: `NoOfRedees` is missing an 'm' (should be NoOfRedeems)
- **Column name with space**: `[Redeem Status Group]` — requires bracket-quoting in SQL
- **TimeFrame 'Over 30 days' threshold is actually 15 days**: The CASE uses DATEADD(DAY,-15) as the last boundary, so anything older than 15 days falls into 'Over 30 days'
- **IDENTITY ID resets hourly**: Not stable across refreshes
- **RequestDate at day granularity**: Unlike Cashouts (which have no date column), Redeems have a per-day RequestDate, leading to more rows (~111 vs ~16)
- **Hourly refresh**: Data changes every hour

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
| 2 | NoOfRedees | bigint | YES | Count of distinct RedeemIDs in this status/date/timeframe bucket. Column name has typo (should be 'NoOfRedeems'). COUNT(DISTINCT RedeemID) from External_Billing_Redeem. (Tier 2 — SP_H_EndOfDayReport_Redeems) |
| 3 | RedeemStatus | varchar(50) | YES | Raw redeem status from Dim_RedeemStatus.DisplayName. Values: TransactionDone, Pending, Approved, ReadyToRedeem, etc. (Tier 2 — SP_H_EndOfDayReport_Redeems, via Dim_RedeemStatus) |
| 4 | RequestDate | date | YES | Date the redeem was requested, CAST to date from External_Billing_Redeem.RequestDate. Provides per-day granularity within time frame buckets. (Tier 2 — SP_H_EndOfDayReport_Redeems) |
| 5 | Redeem Status Group | varchar(max) | YES | Binary classification: 'Redeem Processed' (TransactionDone) or 'Redeem Pending' (all other statuses). Column name has spaces — requires bracket-quoting. (Tier 2 — SP_H_EndOfDayReport_Redeems) |
| 6 | TimeFrame | varchar(max) | YES | Age bucket relative to today: 'Today', 'Past 7 days', 'Past 15 days', 'Over 30 days'. Note: 'Over 30 days' actually starts at 15 days (threshold mismatch). (Tier 2 — SP_H_EndOfDayReport_Redeems) |
| 7 | UpdateDate | datetime | YES | ETL metadata: timestamp of the last hourly refresh (GETDATE()). (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| NoOfRedees | External_Billing_Redeem | RedeemID | COUNT(DISTINCT) per group |
| RedeemStatus | Dim_RedeemStatus | DisplayName | Direct |
| RequestDate | External_Billing_Redeem | RequestDate | CAST to date |
| Redeem Status Group | Computed | Dim_RedeemStatus.DisplayName | CASE: TransactionDone→Processed, else→Pending |
| TimeFrame | Computed | RequestDate | CASE age bucket |

### 5.2 ETL Pipeline

```
etoro.Billing.Redeem (redeem requests)
  |-- Generic Pipeline → lake --|
  v
BI_DB_dbo.External_etoro_Billing_Redeem
DWH_dbo.Dim_RedeemStatus (status names)
  |
  |-- SP_H_EndOfDayReport_Redeems (hourly TRUNCATE+INSERT) --|
  |   3-month window, excl Rejected/Terminated                |
  |   GROUP BY status + date + timeframe                       |
  v
BI_DB_dbo.BI_DB_EndOfDayReport_Redeems (111 rows)
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

### 7.1 Pending Redeem Summary

```sql
SELECT [Redeem Status Group], TimeFrame, SUM(NoOfRedees) AS total_redeems
FROM [BI_DB_dbo].[BI_DB_EndOfDayReport_Redeems]
WHERE [Redeem Status Group] = 'Redeem Pending'
GROUP BY [Redeem Status Group], TimeFrame
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this table.

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 14/14*
*Tiers: 0 T1, 5 T2, 0 T3, 0 T4, 1 T5 | Elements: 7/7, Logic: 7/10, Completeness: 9/10*
*Object: BI_DB_dbo.BI_DB_EndOfDayReport_Redeems | Type: Table | Production Source: SP_H_EndOfDayReport_Redeems (hourly ops dashboard)*
