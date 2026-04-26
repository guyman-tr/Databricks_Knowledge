---
object: BI_DB_dbo.BI_DB_Cross_Selling_Monthly
review_generated: 2026-04-23
status: needs_review
---

# Review Notes — BI_DB_Cross_Selling_Monthly

## Tier 4 Inferences (Reviewer Verification Required)

| Column | Inferred Claim | Confidence | Evidence |
|--------|---------------|------------|----------|
| CFD_ActiveOpen3M | 2-month lookback despite "3M" in name | High | @StartOpenDate = DATEADD(month,-2,@beginning_of_Month) explicit in SP. Column name is misleading — inherited from daily version. |
| eMoney_ActiveOpen3M | Same 2-month lookback as CFD (not 3M) | High | SP uses same @StartOpenDate for both eMoney and CFD lookbacks. |
| EOM_Club | Populated from beginning-of-month, NOT from EOM | High | SP: `where bdcmpfd.ActiveDate = @beginning_of_Month`. Despite being an EOM table, club reflects start-of-month state. |
| High_Bronze+ | $1,000 equity threshold maps to "Bronze+" club boundary | Medium | CASE expression explicit; but "Bronze+" club label not validated against Dim_PlayerLevel |

## Open Questions for Business Reviewer

1. **"3M" column naming discrepancy** — CFD_ActiveOpen3M and eMoney_ActiveOpen3M use 2 months in this SP. Is this intentional (EOM-optimized window) or an oversight? Should columns be renamed to `CFD_ActiveOpen2M`? Affects analytics where users assume 3M equivalence between daily and monthly versions.

2. **EOM_Club timing** — The table is an EOM snapshot but EOM_Club reflects the beginning-of-month club. Is this intentional? A customer promoted mid-month would show their pre-promotion club in this table. Would end-of-month club (from BI_DB_CID_MonthlyPanel_FullData at the EOM date) be more appropriate?

3. **Historical depth mismatch** — Monthly goes back to January 2017; daily only goes back to February 2025. Does this mean cross-sell analysis for pre-2025 periods should use the monthly table exclusively? Is there a known reason the daily was not backfilled?

4. **Total_Products comment in SP** — The SP has a commented-out `eMoney_Balance>50` product category. Was this decommissioned intentionally? Should it reappear? Does this affect Total_Products comparability to pre-decommission periods?

5. **eMoney April 2024 hard cap** — Like the daily, the eMoney lookback is capped at `DateID >= '20240401'` even though @StartOpenDate may compute to an earlier date. Is this hardcoded cutoff expected to remain forever or shift over time?

## UC Migration Status

- **UC Target**: `_Not_Migrated` — not present in `bronze_opsdb_dbo_vw_unitycatalog_mapping_tables`
- Sibling table BI_DB_Cross_Selling_Daily is also `_Not_Migrated`
- No Databricks lake path or UC schema assignment found for either cross-selling table
- Action: If migration is planned, both Daily and Monthly should be registered together as a pair
