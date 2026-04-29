# Lineage: BI_DB_dbo.BI_DB_EY_Audit_Automation_IFRSControl_Results

## Source Objects

| # | Source Object | Type | Schema | Role |
|---|--------------|------|--------|------|
| 1 | BI_DB_EY_Audit_Closed_Positions | Table | BI_DB_dbo | Closed crypto positions — provides Units, InitialUnits, VolumeOnClose for positions closed on @date |
| 2 | BI_DB_EY_Audit_Opened_Positions | Table | BI_DB_dbo | Opened crypto positions — provides InitialUnits, Volume for positions opened on @date still open |
| 3 | BI_DB_EY_Audit_ChangeLog | Table | BI_DB_dbo | CFD↔Real conversion events — provides AmountInUnits, AmountChanged for ChangeTypeID=13 |
| 4 | Dim_Instrument | Table | DWH_dbo | Instrument dimension — used to filter InstrumentTypeID=10 (crypto only) |
| 5 | BI_DB_IFRS15_Daily_Balance | Table | BI_DB_dbo | IFRS 15 daily balance — comparison target for Buy/Sell metric totals |

## Column Lineage

| # | Column | Source Object | Source Column | Transform | Tier |
|---|--------|--------------|---------------|-----------|------|
| 1 | Date | SP_EY_Audit_IFRS_Control | @date parameter | SP input parameter passed as @date | Tier 2 |
| 2 | Stored_Proc | SP_EY_Audit_IFRS_Control | — | Hardcoded string: 'SP_EY_Audit_Automation_IFRS_Contorl' | Tier 2 |
| 3 | Metric_a | SP_EY_Audit_IFRS_Control | — | Hardcoded label: 'TotalBuy_Calc_detailed' or 'TotalSell_Calc_detailed' | Tier 2 |
| 4 | Metric_a_Value | BI_DB_EY_Audit_Closed_Positions, BI_DB_EY_Audit_Opened_Positions, BI_DB_EY_Audit_ChangeLog | TotalUnits (via #IFRSCompare) | SUM of aggregated Buy or Sell units from position-level temp tables | Tier 2 |
| 5 | Metric_b | SP_EY_Audit_IFRS_Control | — | Hardcoded label: 'IFRSTotalBuy' or 'IFRSTotalSell' | Tier 2 |
| 6 | Metric_b_Value | BI_DB_IFRS15_Daily_Balance | TotalUnits | SUM(TotalUnits) WHERE Date=@date AND Metric IN (Buy or Sell group) | Tier 2 |
| 7 | Diff | SP_EY_Audit_IFRS_Control | Metric_a_Value, Metric_b_Value | Metric_a_Value − Metric_b_Value | Tier 2 |
| 8 | Diff_Percentage | SP_EY_Audit_IFRS_Control | Diff, Metric_b_Value | ROUND(ABS(Diff) / Metric_b_Value × 100, 4) | Tier 2 |
| 9 | IsPriceFound | SP_EY_Audit_IFRS_Control | — | Hardcoded NULL | Tier 2 |
| 10 | UpdateDate | SP_EY_Audit_IFRS_Control | — | GETDATE() at INSERT time | Tier 2 |
