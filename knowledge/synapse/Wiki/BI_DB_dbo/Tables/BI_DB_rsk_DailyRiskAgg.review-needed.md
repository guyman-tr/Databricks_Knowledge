# BI_DB_dbo.BI_DB_rsk_DailyRiskAgg — Review Needed

## Tier 4 Items (Require Verification)

None — all columns are Tier 2 (SP code) or Tier 5 (ETL metadata).

## Questions for Reviewer

1. The SP also populates BI_DB_Mirror_Assets_Allocation (TRUNCATE+INSERT) — is that a separate documentation target?
2. Column names with spaces (`[NetMoneyIn - Copyfund]`) are unusual — is there a plan to rename?
3. The DDL has 26 columns but the batch assignment listed 24 — verify no columns were missed.
4. STD normalization can produce division-by-zero when segment AUM=0 — confirm this is acceptable NULL behavior.
5. Legacy data (2017-2019) used a different equity calculation — should historical values be treated with caveats?

## Validation Notes

- Column count: 26 DDL = 26 wiki elements (MATCH)
- All 8 sections present
- Tier distribution: 0 T1, 25 T2, 0 T3, 0 T4, 1 T5
