# Column Lineage: DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments

| Property | Value |
|----------|-------|
| **DWH Table** | `DWH_dbo.Dim_Instrument_Correlation_GroupsInstruments` |
| **UC Target** | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument_correlation_groupsinstruments` (not verified in this Databricks workspace; reserved for roster) |
| **ETL Focus** | `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` |
| **Generated** | 2026-05-14 |

## Source Objects

| Source Object | Role |
|---------------|------|
| Active instrument universe in 3-month correlation window | Input to grouping algorithm (`SP_Dim_Instrument_Correlation_Build_GroupsInstruments`) |
| `DWH_dbo.Dim_Instrument_Correlation` conceptual model | Consumers read `GroupID` ranges to route half-matrix computations |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|--------------|---------------|-----------|
| GroupID | ETL scratch aggregation | sequence / dense rank | `SP_Dim_Instrument_Correlation_Build_GroupsInstruments` assigns monotonic group ids while targeting ~89 groups per run / pair-budget |
| MinInstrumentID | Instrument ordering | MIN(InstrumentID) per group | Lower inclusive bound of `InstrumentID` values owned by the group |
| MaxInstrumentID | Instrument ordering | MAX(InstrumentID) per group | Upper inclusive bound of `InstrumentID` values owned by the group |

**Verbatim rule cited from `Dim_Instrument_Correlation.md` §2.3:** "Result stored in `Dim_Instrument_Correlation_GroupsInstruments`" after dynamic partitioning that targets `(N² / 2) / 89` rows per group.
