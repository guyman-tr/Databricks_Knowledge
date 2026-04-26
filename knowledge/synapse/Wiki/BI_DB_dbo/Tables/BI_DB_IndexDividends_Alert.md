# BI_DB_dbo.BI_DB_IndexDividends_Alert

> 0-row data quality alert table that flags dates where BuyTax is NULL across three index dividend reporting tables (BI_DB_DailyDividendsByPosition, BI_DB_Index_Dividend_TaxReport, BI_DB_Index_Dividend_TaxReport_CID_Level) within a rolling 30-day window. Empty when healthy — rows appear only when NULL BuyTax issues are detected. Daily TRUNCATE + INSERT via SP_IndexDividend_Alert.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Data Quality Alert) |
| **Production Source** | Derived — NULL BuyTax scan across 3 BI_DB dividend tables by SP_IndexDividend_Alert |
| **Refresh** | Daily TRUNCATE + INSERT (SB_Daily) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |

---

## 1. Business Meaning

`BI_DB_IndexDividends_Alert` is a **data quality monitoring table** that detects missing BuyTax values in the index dividend reporting pipeline. Each day, `SP_IndexDividend_Alert` scans three dividend-related tables for any date within the last 30 days where the BuyTax column contains NULL values, then reports which table and which date has the issue.

The table is designed to be **empty when everything is healthy**. Rows appear only when a data quality issue exists — specifically, when the dividend tax calculation pipeline failed to populate BuyTax for one or more dates. At the time of sampling, the table contains 0 rows, indicating no outstanding NULL BuyTax issues.

### Monitored Tables

1. **BI_DB_DailyDividendsByPosition** — position-level daily dividend calculations
2. **BI_DB_Index_Dividend_TaxReport** — index-level dividend tax report
3. **BI_DB_Index_Dividend_TaxReport_CID_Level** — CID-level aggregation of dividend tax

### Load Pattern

- **Daily TRUNCATE + INSERT**: The entire table is truncated and rebuilt from scratch each day
- The SP checks the last 30 days in each monitored table for any date with NULL BuyTax
- Only dates where NULL BuyTax exists are included in the output (BuyTax_Null_Ind = 1 filter)

---

## 2. Business Logic

### 2.1 NULL BuyTax Detection

**What**: Identifies dates where dividend tax calculations are incomplete.
**Columns Involved**: BuyTax_Null_Ind, TableName, Date
**Rules**:
- For each monitored table, GROUP BY DateID and compute MAX(CASE WHEN BuyTax IS NULL THEN 1 ELSE 0 END)
- Only dates where the indicator = 1 (at least one NULL BuyTax) are included
- The 30-day rolling window ensures historical issues are tracked until resolved

### 2.2 Table Identification

**What**: Each row identifies which specific table has the issue.
**Columns Involved**: TableName
**Rules**:
- Hardcoded fully-qualified table names: `BI_DB_dbo.BI_DB_DailyDividendsByPosition`, `BI_DB_dbo.BI_DB_Index_Dividend_TaxReport`, `BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level`
- UNION ALL across all three — a single date may appear up to 3 times if all tables have issues

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN HEAP. Tiny table (typically 0 rows). Full scan is instantaneous.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Any outstanding dividend tax issues? | `SELECT * FROM BI_DB_IndexDividends_Alert` (empty = healthy) |
| Which tables have issues? | `SELECT DISTINCT TableName FROM BI_DB_IndexDividends_Alert` |
| Date range of issues | `SELECT MIN(Date), MAX(Date), COUNT(*) FROM BI_DB_IndexDividends_Alert` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_DailyDividendsByPosition | DateID match | Investigate NULL BuyTax rows |
| BI_DB_Index_Dividend_TaxReport | DateID match | Investigate NULL BuyTax rows |

### 3.4 Gotchas

- **Usually empty**: 0 rows is the expected healthy state — do not assume the table is broken
- **TRUNCATE daily**: Historical alert state is not preserved — only current 30-day window issues are visible
- **BuyTax_Null_Ind is always 1**: The SP filters to BuyTax_Null_Ind = 1 before inserting, so this column is always 1 when rows exist (effectively a constant)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Business date where NULL BuyTax was detected. Converted from YYYYMMDD integer DateID to DATE type. Within the last 30 days from SP execution date. (Tier 2 — SP_IndexDividend_Alert) |
| 2 | TableName | nvarchar(1000) | YES | Fully-qualified name of the BI_DB table where NULL BuyTax was found. One of: BI_DB_dbo.BI_DB_DailyDividendsByPosition, BI_DB_dbo.BI_DB_Index_Dividend_TaxReport, BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level. Hardcoded string literal in SP. (Tier 2 — SP_IndexDividend_Alert) |
| 3 | BuyTax_Null_Ind | bit | YES | NULL BuyTax indicator. Always 1 when rows exist (SP filters to BuyTax_Null_Ind = 1 before inserting). 1 = at least one row in the source table for this date had NULL BuyTax. (Tier 2 — SP_IndexDividend_Alert) |
| 4 | UpdateDate | date | YES | SP execution date (@Date parameter). Indicates when this alert scan was performed. (Tier 5 — SP_IndexDividend_Alert) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Date | BI_DB_DailyDividendsByPosition / BI_DB_Index_Dividend_TaxReport / BI_DB_Index_Dividend_TaxReport_CID_Level | DateID | CAST from int YYYYMMDD to DATE |
| TableName | — | — | Hardcoded string literal |
| BuyTax_Null_Ind | Same 3 tables | BuyTax | MAX(CASE WHEN BuyTax IS NULL THEN 1 ELSE 0 END), filtered to =1 |
| UpdateDate | — | — | @Date parameter |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_DailyDividendsByPosition (BuyTax NULL check, 30-day window)
  + BI_DB_dbo.BI_DB_Index_Dividend_TaxReport (BuyTax NULL check, 30-day window)
  + BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level (BuyTax NULL check, 30-day window)
    |-- SP_IndexDividend_Alert @Date (daily, TRUNCATE + INSERT) --|
    |   GROUP BY DateID per table, MAX NULL indicator              |
    |   UNION ALL where indicator = 1                              |
    v
BI_DB_dbo.BI_DB_IndexDividends_Alert (0 rows when healthy, up to ~90 rows when issues exist)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date, BuyTax_Null_Ind | BI_DB_dbo.BI_DB_DailyDividendsByPosition | Monitored table 1 |
| Date, BuyTax_Null_Ind | BI_DB_dbo.BI_DB_Index_Dividend_TaxReport | Monitored table 2 |
| Date, BuyTax_Null_Ind | BI_DB_dbo.BI_DB_Index_Dividend_TaxReport_CID_Level | Monitored table 3 |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Check for Outstanding Dividend Tax Issues

```sql
SELECT * FROM [BI_DB_dbo].[BI_DB_IndexDividends_Alert]
-- Empty result = healthy; rows = investigate
```

### 7.2 Count Issues by Monitored Table

```sql
SELECT TableName, COUNT(*) AS dates_with_issues
FROM [BI_DB_dbo].[BI_DB_IndexDividends_Alert]
GROUP BY TableName
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 0 T1, 3 T2, 0 T3, 0 T4, 1 T5 | Elements: 4/4, Logic: 7/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_IndexDividends_Alert | Type: Table | Production Source: Derived — NULL BuyTax scan across 3 BI_DB dividend tables*
