# Review Needed — eMoney_dbo.eMoney_Reports_MIMO_Actions

**Generated**: 2026-04-21
**Wiki Quality**: 8.8/10
**Reviewer**: eMoney Data Analytics Team

---

## Tier 4 Items

None. All 20 columns are Tier 2 (same source chain as eMoney_Daily_MIMO_New_Reports_Action).

---

## Open Questions

1. **Should this table be archived?**: The table is frozen since 2024-10-12. Is it still actively queried by Tableau dashboards or reports? If not, it could be a candidate for deprecation (keeping the data but removing from the active wiki tracking).

2. **Overlap between tables**: Both tables contain data from 2022-05-01. The new table was backfilled from the same SP. Is there an exact date boundary with no duplication? From live data: new table has 2022-05-01 onwards, old table ends at 2024-10-12. Are rows identical for the overlapping period (2022-05-01 to 2024-10-12)?

3. **UC export status**: Is `eMoney_Reports_MIMO_Actions` still being exported to Unity Catalog? If the new table is the authoritative source, the UC export may be redundant and confusing for downstream users.

4. **Documentation priority**: Since this is a frozen legacy table, it may be lower priority for data quality review. The successor table `eMoney_Daily_MIMO_New_Reports_Action` should be the focus.

---

## Cross-Object Consistency Checks

| Column | Checked Against | Result |
|--------|----------------|--------|
| All 20 shared columns | eMoney_Daily_MIMO_New_Reports_Action | IDENTICAL descriptions — same source chain, same SP, same tier assignments |
| UpdateDate nullability | eMoney_Daily_MIMO_New_Reports_Action | DIFFERENCE: nullable here vs. NOT NULL in successor — documented |
