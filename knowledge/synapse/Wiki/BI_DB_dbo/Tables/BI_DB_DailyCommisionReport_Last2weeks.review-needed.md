# Review Needed — BI_DB_DailyCommisionReport_Last2weeks

**Batch**: 21 | **Generated**: 2026-04-22 | **Reviewer**: Domain Owner / Analytics Engineering

---

## Tier 4 Columns — Always NULL (1)

| Column | Type | Notes |
|--------|------|-------|
| CommissionInRisk | money | Ghost column — present in DDL but absent from the SP INSERT list. SP_DailyCommisionReport does not write to this column. Confirmed 100% NULL via live sampling (~861K rows). Likely intended for a commission-at-risk or margin-risk metric that was never implemented. |

---

## Questions for Domain Owner

1. **CommissionInRisk — intended purpose?** The column name suggests a margin or counterparty risk-adjusted commission figure. Was this planned as part of a risk reporting initiative that was cancelled? If there is no plan to populate it, it is a candidate for DDL cleanup.

2. **IsThisWeek stored as `money` type** — this is a 0/1 flag computed as a CASE expression but persisted as `money`. Was this intentional (e.g., to match a parent column type), or an oversight? Consumers must cast it to int before using it in numeric comparisons. Should this be corrected in a future schema ALTER?

3. **TRUNCATE+INSERT data availability risk** — if SP_DailyCommisionReport fails between the TRUNCATE and the INSERT completion, the table is left empty. Is there an ETL monitoring alert on this table to detect zero-row states? The parent table (incremental) does not have this risk.

4. **No Unity Catalog migration** — this table is not in `_generic_pipeline_mapping.json` and has no UC Gold target. Is this intentional (the rolling window nature makes it less suitable for historical UC Gold) or a pending backlog item?

5. **NOLOCK on source read** — the SP reads the parent table `WITH (NOLOCK)`. If SP_DailyCommisionReport runs while the parent's own ETL is still writing rows for the current date, this table could capture uncommitted data. Is there a sequencing guard in the SP execution order to prevent this?

---

## Correction Notes

- No corrections to documented ETL logic — SP code read directly from SSDT is authoritative.
- CommissionInRisk ghost status confirmed by cross-referencing SP INSERT column list against DDL column list.
- IsThisWeek money type confirmed from DDL (`[IsThisWeek] [money] NULL`); CASE expression in SP confirmed to produce 0 or 1.
