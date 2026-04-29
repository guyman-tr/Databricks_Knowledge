# BI_DB_dbo.BI_DB_ReverseCoReport — Review Needed

## Tier 4 Items (Low Confidence)

None — all columns traced to documented upstream sources.

## Questions for Reviewer

1. **Data stopped flowing**: Last CoCanceledDate is 2024-11-22. Is this SP still active? Has it been disabled or replaced by a newer report?
2. **dbo_BI_DB_ReverseCoReport**: A duplicate/migration DDL file exists (`BI_DB_dbo.dbo_BI_DB_ReverseCoReport.sql`). Is this a legacy migration artifact?
3. **$5,000 threshold**: Is this still the correct business threshold for "high-value" cashouts? Has it been updated?
4. **Column count discrepancy**: Batch assignment said 18 columns, DDL has 16. Verified from live data: 16 columns.
5. **WITH (NOLOCK)**: Multiple instances in the SP — unnecessary for Synapse but not harmful. Consider removing for code hygiene.

## Upstream Verification

| Column | Source | Verified |
|--------|--------|----------|
| CID | Fact_CustomerAction.RealCID wiki (Tier 1 — Customer.CustomerStatic) | Yes |
| CoRequestAmount | Fact_CustomerAction.Amount wiki (Tier 1 — Trade.PositionTbl) | Yes |
| CoCanceledDate | Fact_CustomerAction.Occurred wiki (Tier 1 — source-dependent) | Yes |
| Desk | Dim_Country.Desk wiki (Tier 3 — Ext_Dim_Country_Region_Desk) | Yes |
| Country | CIDFirstDates.Country wiki (Tier 2 — SP_CIDFirstDates) | Yes |
| Region | CIDFirstDates.Region wiki (Tier 2 — SP_CIDFirstDates) | Yes |
