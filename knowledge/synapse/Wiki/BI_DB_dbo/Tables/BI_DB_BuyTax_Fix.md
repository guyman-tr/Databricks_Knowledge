# BI_DB_dbo.BI_DB_BuyTax_Fix

**Schema**: BI_DB_dbo | **UC Target**: _Not_Migrated
**Row count**: 0 (empty in production) | **Refresh**: Unknown / ad-hoc
**Distribution**: ROUND_ROBIN | **Structure**: HEAP

---

## 1. Business Meaning

A **vestigial staging table** associated with the buy-tax dividend reprocessing workflow. The table exists in the DDL with a single column (`Date`) but contains no rows in production — no active writer SP populates it.

The related stored procedure `SP_BuyTax_Fix` suggests the original intent: to track which dates were reprocessed when correcting buy-tax data for dividends. However, the SP does not write to this table — it reads `BI_DB_IndexDividends_Alert` to determine affected dates, then reruns three downstream SPs (`SP_DailyDividendsByPosition`, `SP_Index_Divident_TaxReport`, `SP_Index_Divident_TaxReport_CID_Level`).

This table is likely either a never-completed stub (the INSERT logic was never implemented), a manual-input table populated only during specific remediation events, or a remnant of a refactored workflow. It has no downstream dependencies identified in the current SSDT codebase.

---

## 2. Business Logic

### 2.1 SP_BuyTax_Fix Does Not Write Here
`SP_BuyTax_Fix` is the only SP nominally related to this table by name, but inspection of its body confirms it does not reference or write to `BI_DB_BuyTax_Fix`. The SP is an orchestration procedure that reruns dividend tax SPs for affected dates.

### 2.2 No Other Known Writers
A full search of the SSDT repository finds no SP, trigger, or job that issues an INSERT or UPDATE to `BI_DB_BuyTax_Fix`. The table is not referenced in any pipeline configuration or Generic Pipeline mapping.

---

## 3. Query Advisory

### 3.1 Table Is Always Empty
Do not join or aggregate on this table expecting production data. Any query against it will return 0 rows.

### 3.2 Single Column: `Date`
The only column is `Date date NULL`. There is no ID, no metadata, no partition key.

---

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| Date | date | Intended to store a reprocessed date value. Never populated in production. | Tier 4 — best guess | Table contains 0 rows; purpose inferred from table name and SP context |

---

## 5. Lineage

### 5.1 Source Objects

| Source | Layer | Role |
|--------|-------|------|
| None identified | — | No active writer SP; table is unpopulated |

### 5.2 ETL Pipeline

```
SP_BuyTax_Fix (nominally related, does NOT write here)
  |-- reads BI_DB_IndexDividends_Alert for affected dates --|
  |-- reruns SP_DailyDividendsByPosition --|
  |-- reruns SP_Index_Divident_TaxReport --|
  |-- reruns SP_Index_Divident_TaxReport_CID_Level --|
  v
[BI_DB_BuyTax_Fix — NOT written by SP_BuyTax_Fix]
  (0 rows, vestigial/stub table)
```

---

## 6. Relationships

| Related Table | Join | Notes |
|--------------|------|-------|
| BI_DB_dbo.BI_DB_IndexDividends_Alert | Date | SP_BuyTax_Fix reads this table for reprocessing; indirect thematic relationship |

---

## 7. Sample Queries

**Check if table has any rows (expect 0)**
```sql
SELECT COUNT(*) row_count FROM BI_DB_dbo.BI_DB_BuyTax_Fix
```

---

## 8. Atlassian / Change History

| Reference | Date | Author | Change |
|-----------|------|--------|--------|
| Original | Unknown | Unknown | Table created as part of buy-tax dividend fix workflow; never populated |
