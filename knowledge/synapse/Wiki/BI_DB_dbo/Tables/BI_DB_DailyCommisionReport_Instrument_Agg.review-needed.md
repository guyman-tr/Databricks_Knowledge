# Review Needed — BI_DB_DailyCommisionReport_Instrument_Agg

**Batch**: 21 | **Generated**: 2026-04-22 | **Reviewer**: Domain Owner / Analytics Engineering

---

## Tier 4 Columns — Always NULL (14)

These columns exist in the DDL but are never populated by SP_DailyCommisionReport. Confirm with the domain owner whether any of these should be:
(a) removed from the DDL in a future schema cleanup, or (b) populated by a future SP enhancement.

| Column | Type | Notes |
|--------|------|-------|
| IsOutlier | int | Statistical outlier flag — never activated |
| Transition | varchar(50) | Regulatory transition label — never populated |
| IsGermanBaFIN | int | BaFIN jurisdiction flag — superseded by Regulation column |
| RegulationIDPrev | int | Prior regulation ID tracking — never implemented |
| RegulationPrev | varchar(50) | Prior regulation label tracking — never implemented |
| IsCreditReportValidCBPrev | int | Prior CB validity tracking — never implemented |
| CommissionByUnitsAtClose | float | Commission decomposition attempt — never inserted |
| UnrealizedCommissionNew | float | Unrealized commission decomposition — never inserted |
| UnrealizedCommissionOldClosing | float | Unrealized commission decomposition — never inserted |
| RealizedCommission | float | Realized commission decomposition — never inserted |
| FullCommissionByUnitsAtClose | float | Full commission decomposition — never inserted |
| UnrealizedFullCommissionNew | float | Full unrealized commission decomposition — never inserted |
| UnrealizedFullCommissionOldClosing | float | Full unrealized commission decomposition — never inserted |
| UnealizedFullCommissionChange | float | Full unrealized commission daily delta — never inserted; **also has DDL typo: "Unealized" (missing 'r')** |

---

## Questions for Domain Owner

1. **`[FTD Year]` column name has a space** — was this intentional? All other columns use no spaces. Using bracket-quoted names adds friction in downstream SQL (especially in PySpark / Unity Catalog DDL generation). Is there a plan to rename this to `FTD_Year` in a schema migration?

2. **`UnealizedFullCommissionChange` DDL typo** — the column name is permanently `UnealizedFullCommissionChange` (not `UnrealizedFullCommissionChange`). It is always NULL anyway. Should this be corrected in a future ALTER + rename, or left as-is given it carries no data?

3. **EY Audit usage** — SP_EY_Audit_Opened_Positions reads `UnrealizedCommissionChange` from this table for open-position commission audit reports. Is this SP still active post-2023 audit? If the EY engagement is closed, this SP may be a dead dependency.

4. **CountUU semantics at aggregate level** — at the Instrument_Agg grain, `CountUU` is a SUM of parent CountUU values, so a single customer contributing to 3 instrument types on the same day would be counted 3 times. Confirm whether analysts understand this and whether a deduplicated unique-customer count is needed at this level.

5. **14 Tier 4 columns — schema cleanup** — with 22% of columns always NULL, there is meaningful schema debt. Is there a planned DDL cleanup cycle for the BI_DB_DailyCommisionReport family of tables?

---

## Correction Notes

- No corrections made to the documented ETL logic — the SP_DailyCommisionReport code was read directly from SSDT and is authoritative.
- Live data sampling confirmed all 14 Tier 4 columns are 100% NULL as of 2026-04-22.
- Column count confirmed as 63 (recount from DDL; initial read stated 64 — self-corrected before writing).
