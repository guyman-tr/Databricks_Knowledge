# BI_DB_Investors_Top10 — Review Needed

## Tier 4 / Uncertain Items

1. **InstrumentID for PI/Portfolio rows**: Documented as CID of the Popular Investor/Portfolio manager based on SP code (`CID` from `BI_DB_CopyDailyData`). Confirm with BI team that this is intentional and that consumers know not to join these rows to Dim_Instrument.

2. **BI_DB_CopyDailyData (not yet documented)**: The netMI and CopyAUM column semantics were inferred from SP code and column names — not from an upstream wiki. When BI_DB_CopyDailyData is documented, verify that netMI and CopyAUM descriptions here are consistent.

3. **AUA_AUM for TimeFrame='Yesterday' only**: The SP does not compute weekly/monthly/yearly AUA snapshots. This appears to be a design constraint (point-in-time AUM vs. cumulative MI). Confirm whether weekly/monthly AUA is planned or intentionally omitted.

4. **Dim_Manager joined but unused**: SP_InvestorReportTop10 JOINs `DWH_dbo.Dim_Manager dm1 ON fsc.AccountManagerID = dm1.ManagerID` but does not use any columns from dm1 in the output. This join appears to be a legacy filter step or artifact — dm1 is not selected. Confirm whether this is intentional (possibly a remnant from an older version that filtered by manager).

5. **NetMI sign convention consistency**: Manual NetMI uses `-1 × Amount` from Fact_CustomerAction. Copy NetMI uses `netMI` from BI_DB_CopyDailyData directly. Verify that both streams use the same sign convention (positive = net inflow to broker) before aggregating them.

6. **SP authorship**: No author or creation date comment in SP_InvestorReportTop10. Business owner unknown.

## No Review Needed
- Table name, distribution, index: confirmed from DDL
- TimeFrame values, AmountType values: confirmed from live data
- Row count, date range: confirmed via MCP sample
