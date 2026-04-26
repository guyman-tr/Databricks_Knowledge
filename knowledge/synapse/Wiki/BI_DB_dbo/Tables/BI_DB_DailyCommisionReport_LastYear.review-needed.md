# Review Needed — BI_DB_DailyCommisionReport_LastYear

**Batch**: 21 | **Generated**: 2026-04-22 | **Reviewer**: Domain Owner / Analytics Engineering

---

## Tier 4 Columns — Always NULL (1)

| Column | Type | Notes |
|--------|------|-------|
| CommissionInRisk | money | Ghost column — present in DDL but absent from the SP INSERT list. SP_DailyCommisionReport does not write to this column. Same pattern as in BI_DB_DailyCommisionReport_Last2weeks. Confirmed via SP code inspection (column absent from INSERT column list). |

---

## Questions for Domain Owner

1. **CommissionInRisk — consistent ghost across satellites** — CommissionInRisk is a ghost column in both Last2weeks and LastYear (same column name, same money type, same "not in INSERT list" pattern). This suggests it was added to the DDL as part of a shared schema change that was planned but never implemented in the SP. Is there a planned implementation, or should it be cleaned up from the DDL in both tables?

2. **No Club or Country in LastYear** — unlike Last2weeks, the LastYear aggregation does not include Club or Country in the GROUP BY. For annual customer tier analysis (e.g., revenue by Diamond vs Platinum), analysts must fall back to the parent table. Was the exclusion intentional (to reduce cardinality in a large table), or an oversight when the SP was first written?

3. **TRUNCATE+INSERT data availability risk** — same as Last2weeks: if the SP fails between TRUNCATE and INSERT, the table is left empty. With 6.48M rows and a full-year aggregation, a failure here is more expensive to recover than in Last2weeks. Is there an ETL health alert monitoring row counts on this table?

4. **Annual roll-over behaviour** — on January 1 of each new year, this table's content shifts to the new prior year. There is no snapshot/archive of prior "last year" data in this table. If 2025 data is needed after the 2027 roll-over, analysts must query the parent table. Is this understood by downstream consumers, or should a longer-window archive table be considered?

5. **No Unity Catalog migration** — same as Last2weeks. Is there a plan to add this to the Generic Pipeline mapping?

---

## Correction Notes

- No corrections to documented ETL logic — SP code read directly from SSDT.
- CommissionInRisk ghost status confirmed by cross-referencing SP INSERT column list against DDL.
- Year dimension confirmed as always a single value (2025 as of 2026-04-22) via live sampling.
