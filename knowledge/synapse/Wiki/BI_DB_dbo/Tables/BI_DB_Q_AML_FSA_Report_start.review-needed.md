# Review Needed: BI_DB_dbo.BI_DB_Q_AML_FSA_Report_start

## Tier 4 Items

None — all columns traced to SP code and upstream sources.

## Review Questions

1. **Report_Start_Date inconsistency**: Earlier quarterly snapshots (20231231, 20240331, 20240630, 20240930) use quarter-end dates as Report_Start_Date values, while later snapshots (20241001, 20250101, 20250401, 20250701, 20251001, 20260101) use quarter-start dates. Was the SP modified mid-life? The current SP code assigns @StartDateID (quarter start), but historical data suggests older versions used @EndDateID or quarter-end dates.

2. **Equity uses end-of-period data**: UnrealizedEquity and RealizedEquity are computed from @EndDateID even for the start-of-quarter snapshot. Is this intentional? It means the "start" snapshot has equity values from the END of the reporting period.

3. **HNW uses end-of-period population**: The #High_Net_Worth temp table joins against #pop_end (end-of-period customers), but the results are LEFT JOINed into #final_table_start. This means HNW status reflects end-of-quarter KYC panel answers applied to start-of-quarter customers.

4. **Cross-object tier discrepancy — EU column**: The sibling `BI_DB_Q_AML_FSA_Report_end` wiki (batch 99) assigned EU as Tier 1 (Dim_Country), but the Dim_Country canonical wiki documents EU as Tier 3 (Ext_Dim_Country). This wiki uses the correct Tier 3 per the canonical source. The _end wiki should be updated in a future pass.

## Corrections Applied

- EU: Changed from Tier 1 (as in _end wiki) to Tier 3 (per Dim_Country canonical wiki — Ext_Dim_Country source)
- Desk: Tier 3 (per Dim_Country canonical wiki — Ext_Dim_Country_Region_Desk source)
- Region: Tier 2 (per Dim_Country canonical wiki — SP_Dictionaries_Country_DL_To_Synapse)
