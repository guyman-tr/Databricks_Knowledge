# BI_DB_dbo.BI_DB_DailyGain_History — Column Lineage

## Lineage Metadata

| Property | Value |
|----------|-------|
| **Target Table** | BI_DB_dbo.BI_DB_DailyGain_History |
| **Writer SP** | BI_DB_dbo.SP_DailyGain_History |
| **Upstream SP** | BI_DB_dbo.SP_Create_Rankings_History_MonthlyGainAnon_Range |
| **Staging Table** | BI_DB_dbo.DailyGain |
| **Ultimate Source** | Data Lake Bronze: `/internal-sources/Bronze/Rankings/History/MonthlyGainAnon/` (Parquet) |
| **Load Pattern** | Daily DELETE (current month) + INSERT from staging for @today |
| **Generated** | 2026-04-26 |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Tier |
|---|---------------|-------------|---------------|-----------|------|
| 1 | ID | Rankings.MonthlyGainAnon (Bronze) | ID | Passthrough via DailyGain staging | Tier 3 |
| 2 | StartPeriod | Rankings.MonthlyGainAnon (Bronze) | StartPeriod | Passthrough | Tier 3 |
| 3 | EndPeriod | Rankings.MonthlyGainAnon (Bronze) | EndPeriod | Passthrough | Tier 3 |
| 4 | StartCash | Rankings.MonthlyGainAnon (Bronze) | StartCash | Passthrough | Tier 3 |
| 5 | StartInvestment | Rankings.MonthlyGainAnon (Bronze) | StartInvestment | Passthrough | Tier 3 |
| 6 | StartPnL | Rankings.MonthlyGainAnon (Bronze) | StartPnL | Passthrough | Tier 3 |
| 7 | StartEquity | Rankings.MonthlyGainAnon (Bronze) | StartEquity | Passthrough | Tier 3 |
| 8 | EndCash | Rankings.MonthlyGainAnon (Bronze) | EndCash | Passthrough | Tier 3 |
| 9 | EndInvestment | Rankings.MonthlyGainAnon (Bronze) | EndInvestment | Passthrough | Tier 3 |
| 10 | EndPnL | Rankings.MonthlyGainAnon (Bronze) | EndPnL | Passthrough | Tier 3 |
| 11 | EndEquity | Rankings.MonthlyGainAnon (Bronze) | EndEquity | Passthrough | Tier 3 |
| 12 | PositiveCashFlows | Rankings.MonthlyGainAnon (Bronze) | PositiveCashFlows | Passthrough | Tier 3 |
| 13 | NegativeCashFlows | Rankings.MonthlyGainAnon (Bronze) | NegativeCashFlows | Passthrough | Tier 3 |
| 14 | Gain | Rankings.MonthlyGainAnon (Bronze) | Gain | Passthrough | Tier 3 |
| 15 | HasTradingActivity | Rankings.MonthlyGainAnon (Bronze) | HasTradingActivity | Passthrough | Tier 3 |
| 16 | DeltaGain | Rankings.MonthlyGainAnon (Bronze) | DeltaGain | Passthrough | Tier 3 |
| 17 | AdjustedCash | Rankings.MonthlyGainAnon (Bronze) | AdjustedCash | Passthrough | Tier 3 |

## Source Objects

| Source Object | Type | Purpose |
|--------------|------|---------|
| Rankings/History/MonthlyGainAnon (Bronze Parquet) | Data Lake | Ultimate source — Rankings service monthly gain calculations |
| BI_DB_dbo.DailyGain | Staging Table | COPY INTO target from Bronze Parquet; auto-created |
| BI_DB_dbo.SP_Create_Rankings_History_MonthlyGainAnon_Range | Stored Procedure | Loads Parquet from lake into DailyGain staging via COPY INTO |
| BI_DB_dbo.SP_DailyGain_History | Stored Procedure | Writer SP: DELETE current month + INSERT from DailyGain |

## Downstream Consumers

| Consumer | Type | Usage |
|----------|------|-------|
| BI_DB_dbo.SP_PI_Gain | Stored Procedure | Reads DailyGain_History JOIN Dim_Customer to compute PI/Portfolio yearly/quarterly/monthly gain aggregations → BI_DB_PI_Gain |
