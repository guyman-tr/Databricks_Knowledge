# BI_DB_dbo.BI_DB_CreditLine_Amounts — Review Needed

## 1. Tier 3 Items Requiring Human Review

| # | Column | Current Tier | Issue | Suggested Action |
|---|--------|-------------|-------|------------------|
| 1 | CreditLine | Tier 3 | No SP writes to this table. No upstream wiki exists. Values appear to be manually maintained fee schedule thresholds. | Confirm with finance/BI team: who maintains this table and how are new tiers added? |
| 2 | Cost | Tier 3 | Same as above — static reference data with no automated source. | Confirm fee cost calculation methodology and whether values are reviewed periodically. |
| 3 | UpdateDate | Tier 3 | Column exists but is NULL across all 13 rows. No process ever writes to it. | Consider whether this column should be dropped or if a trigger/manual process should populate it. |

## 2. Open Questions

- **Data ownership**: Who is responsible for maintaining the fee schedule? The original hardcoded values (visible in commented-out SP code) suggest this was a one-time migration from code to table, but it's unclear who updates it when fee tiers change.
- **Exact-match semantics**: The LEFT JOIN in SP_Daily_CreditLine uses exact match (`TotalCLAmount = CreditLine`). If a customer's credit line amount doesn't match one of the 13 discrete values, no fee is assigned. Is this intentional, or should this be a range-based lookup?
- **Missing high-end tiers**: The maximum CreditLine is 260,000. Are there customers with credit lines above this amount, and if so, what fee applies to them?
- **UpdateDate purpose**: This column is never populated. Should it be removed, or is there a planned use for it?

## 3. Dormant Table Assessment

This table has `_no_upstream_found.txt` set. It appears to be a static, manually maintained reference table rather than a dormant/deprecated one — it is actively read by SP_Daily_CreditLine daily. The "dormant" classification refers only to the lack of automated ETL population, not to disuse.
