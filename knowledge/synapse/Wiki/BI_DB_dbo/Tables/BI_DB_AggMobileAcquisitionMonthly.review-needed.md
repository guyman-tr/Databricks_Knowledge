# BI_DB_dbo.BI_DB_AggMobileAcquisitionMonthly -- Review Needed

## Dormant Table Assessment

- **Status**: 0 rows, no writer SP, fully orphaned
- **Recommendation**: Consider DROP -- table has never been populated in Synapse and has an identical Daily sibling (also empty)
- **Column typo**: "Cocntact" should be "Contact" -- if table is ever reactivated, rename the column

## Tier 4 Items (All Columns)

All 27 non-ETL columns are Tier 4 (inferred from column names). No upstream wiki, no SP code, no live data to verify against. Descriptions are best-effort based on:
1. Column naming conventions (standard eToro affiliate/acquisition terminology)
2. Sibling table BI_DB_AggMobileAcquisitionDaily (identical structure, also dormant)
3. Domain knowledge of mobile acquisition funnels

## Questions for Reviewer

1. **Was this table ever populated on-prem?** If so, what was the production source (likely an on-prem BI_DB SP)?
2. **Has mobile acquisition reporting moved to another system?** (AppsFlyer, Adjust, BigQuery, Databricks)
3. **Should both Monthly and Daily variants be decommissioned?** Neither has been populated in Synapse.
4. **TierCountry mapping**: What are the valid tier values (1-3? 1-5?) and which countries map to which tier?
5. **FTDEs definition**: Is this currency-normalized or threshold-based FTD equivalents?

## Cross-Object Consistency

- Sibling: BI_DB_AggMobileAcquisitionDaily (Batch 112, Quality 7.0) -- descriptions aligned
