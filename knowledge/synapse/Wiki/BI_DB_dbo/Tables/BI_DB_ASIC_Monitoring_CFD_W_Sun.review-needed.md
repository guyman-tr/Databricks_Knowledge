# Review Needed: BI_DB_dbo.BI_DB_ASIC_Monitoring_CFD_W_Sun

Generated: 2026-04-23 | Batch: 54 | Pipeline: build-wiki-bidb-batch

---

## 🟡 MEDIUM — Sentinel Date Values Should Be NULL

**Columns**: A4_Last_BSL_Date_MaxDate, A5_Last_NegativeBalance_Date_MaxDate

Both columns use `1999-01-01` as a sentinel value to indicate "no event" rather than NULL:
```sql
MAX(CASE WHEN ... THEN CloseOccurred ELSE '1999-01-01' END)
MAX(CASE WHEN ... THEN DateID ELSE 19990101 END)
```

This forces all downstream consumers to explicitly handle the sentinel. NULL would be semantically cleaner. Consider refactoring the SP to use NULL and updating consumers accordingly.

**Action**: Evaluate whether consuming reports already handle the 1999-01-01 sentinel. If a SP change is made, update consumers simultaneously.

---

## 🟡 MEDIUM — Alert A3 Gap

The table documents Alerts A1, A2, A4, A5, A6 but no Alert A3. It is unclear whether:
- A3 exists in a separate table
- A3 was planned but never implemented
- A3 was removed after initial design

**Action**: Confirm with the original ASIC monitoring team (or SP author) whether A3 is tracked elsewhere or was decommissioned. Update documentation when clarified.

---

## 🟡 MEDIUM — Population Covers FCA + ASIC (Not ASIC-Only)

Despite the table name suggesting ASIC-only (`ASIC_Monitoring`), the population is `RegulationID IN (4,10)` — FCA (4) and ASIC (10). The ~375K weekly row count reflects this combined scope vs ~82K for ASIC-only populations.

**Action**: Confirm whether FCA customers are intentionally included in ASIC regulatory reporting. If the FCA rows are unused by consuming reports, consider narrowing the filter to reduce ETL cost.

---

## ℹ️ INFO — UC Migration Status

**UC Target**: `_Not_Migrated`

No Unity Catalog migration target is defined. If ASIC/FCA regulatory reporting is moving to Databricks, include this table in scope planning.

---

## ℹ️ INFO — Weekly Sunday Schedule

This table runs once per week on Sundays (OpsDB FrequencySP = "Weekly Sunday"). The ClusteredIndex on Date ASC means date-range queries are efficient. Do NOT expect daily data — gaps between Sundays are by design.
