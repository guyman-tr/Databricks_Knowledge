# BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: 0 when no alert fires; populated only on discrepancy days | **Refresh**: daily, Priority 0
**Distribution**: ROUND_ROBIN | **Structure**: HEAP

---

## 1. Business Meaning

A **reconciliation alert table** that fires when the daily client balance total (`CBZero`) diverges from the daily treesize total (`TreesizeZero`) by 0.5% or more. One row is written per date where the discrepancy threshold is breached.

`CBZero` and `TreesizeZero` are two independent aggregations that should track roughly the same metric — total client balance — but computed from different source systems. When they agree (within 0.5%), the table is empty (truncated clean). When they diverge, a row is inserted as an alert signal for data quality monitoring.

The table is currently empty in production, indicating that the reconciliation discrepancy has been below 0.5% for the current run. This is expected normal operating state. The table has value during investigations when one of the upstream processes misfires.

---

## 2. Business Logic

### 2.1 Threshold Filter
The SP only inserts when: `(ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100 >= 0.5`. This is a percentage divergence of 0.5% or more relative to CBZero. Rows below the threshold produce no output (the TRUNCATE still fires, leaving the table empty).

### 2.2 TRUNCATE + INSERT Pattern
The SP uses `TRUNCATE TABLE BI_DB_CBZero_TreesizeZero_Alert` before inserting — not a date-keyed delete. This means the table always reflects only the most recent alert state (not a history of past alerts). If the discrepancy drops below 0.5% on a subsequent run, the table is wiped clean.

### 2.3 Date Parameter
`@date` is the target date. `DateID` is the YYYYMMDD integer for that date.

### 2.4 Source Aggregations
Both `CBZero` and `TreesizeZero` are aggregated to a single daily total from their respective source tables (`BI_DB_Client_Balance_CID_Level_New` and `BI_DB_DailyZero_TreeSize_NEW`) before comparison.

---

## 3. Query Advisory

### 3.1 Empty Table Is Normal
`SELECT COUNT(*) FROM BI_DB_CBZero_TreesizeZero_Alert` returning 0 means the reconciliation is within tolerance. This is the healthy state, not a pipeline failure.

### 3.2 No Historical Alert Log
Due to the TRUNCATE pattern, historical alert days are not preserved. Only the most recent run's data exists. Do not use this table for trending discrepancy over time.

### 3.3 `PercentDiff` Is an Absolute Divergence Percentage
`PercentDiff = (ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100`. A value of 1.2 means 1.2% divergence. This is always positive (absolute value).

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| DateID | int | YYYYMMDD integer for the alert date. Derived from @date SP parameter. | Tier 2 — SP code | Primary key equivalent |
| CBZero | decimal or float | Total client balance zero-balance metric for the date. Aggregated from BI_DB_Client_Balance_CID_Level_New. | Tier 2 — SP code | One row per alert day |
| TreesizeZero | decimal or float | Total treesize zero metric for the date. Aggregated from BI_DB_DailyZero_TreeSize_NEW. | Tier 2 — SP code | Should approximately equal CBZero |
| PercentDiff | decimal or float | Percentage divergence between CBZero and TreesizeZero: (ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100. | Tier 2 — SP code | Always ≥ 0.5 when row exists (threshold filter) |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | BI_DB table | CBZero source — daily client balance aggregation |
| BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW | BI_DB table | TreesizeZero source — daily treesize aggregation |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
  → aggregate to total CBZero for @date
BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW
  → aggregate to total TreesizeZero for @date
  |-- SP_Client_Balance_and_DailyZero_TreeSize_Alert @date (daily, P0) --|
  |-- FILTER: (ABS(CBZero - TreesizeZero) / ABS(CBZero)) * 100 >= 0.5 --|
  |-- TRUNCATE BI_DB_CBZero_TreesizeZero_Alert + INSERT (if filter passes) --|
  v
BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert
  (0 rows if within tolerance; 1 row if alert fires)
  |-- UC: _Not_Migrated --|
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | DateID | Source table for CBZero aggregation |
| BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW | DateID | Source table for TreesizeZero aggregation |

---

## 7. Sample Queries

**Check current alert state**
```sql
SELECT * FROM BI_DB_dbo.BI_DB_CBZero_TreesizeZero_Alert
-- Returns 0 rows when reconciliation is within 0.5% tolerance (healthy state)
-- Returns 1 row when a discrepancy alert has fired
```

**Historical discrepancy context (from source tables)**
```sql
-- Since this table has no history, check source tables directly for a given date
SELECT
    'CBZero' AS metric,
    SUM(CBZero) AS total
FROM BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New
WHERE DateID = 20260420

UNION ALL

SELECT
    'TreesizeZero' AS metric,
    SUM(TreesizeZero) AS total
FROM BI_DB_dbo.BI_DB_DailyZero_TreeSize_NEW
WHERE DateID = 20260420
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | Unknown | Unknown | Initial creation — client balance vs treesize reconciliation alert |
