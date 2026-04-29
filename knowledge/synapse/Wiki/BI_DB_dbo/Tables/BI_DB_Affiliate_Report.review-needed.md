# BI_DB_dbo.BI_DB_Affiliate_Report — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| All 26 non-ETL columns | Tier 4 | No writer SP, no data — all descriptions inferred from column names and eToro affiliate domain knowledge |

## Questions for Reviewer

1. **Decommission candidate**: 0 rows, no SP references. Should this table be dropped?
2. **Replacement**: Where did this affiliate P&L reporting move to? BI_DB_AffiliateLifeCycle? Tableau? Databricks?
3. **FTDEs definition**: What exactly is "First-Time Deposit Equivalent"? Normalized for currency? Weighted by deposit size?
4. **Relationship to BI_DB_Affiliate_Report_90898**: What is the 90898 suffix? Is it a specific affiliate's report? A specific regulation?

## Dormant Table Assessment

- **Evidence**: 0 rows, no writer SP, no reader SP, no references in any SP
- **Rich schema**: 27 columns covering full affiliate P&L — this was clearly an important report that was decommissioned
- **Column naming quirk**: `[FTD Amount]` has a space — requires bracket notation
