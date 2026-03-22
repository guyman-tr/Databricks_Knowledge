# Column Lineage: Dealing_dbo.Dealing_ClientsCapitalAdequacy

| Property | Value |
|----------|-------|
| **DWH Table** | `Dealing_dbo.Dealing_ClientsCapitalAdequacy` |
| **UC Target** | _Pending — resolved during write-objects_ |
| **Primary Source** | `BI_DB_dbo.BI_DB_PositionPnL` (Synapse DWH) |
| **ETL SP** | `Dealing_dbo.SP_Capital_Adequacy_IFR_KPMG` |
| **Secondary Sources** | `DWH_dbo.Fact_SnapshotCustomer`, `DWH_dbo.Dim_Instrument`, `DWH_dbo.Dim_Range`, `DWH_dbo.Dim_Regulation` |
| **Generated** | 2026-03-21 |

## Lineage Chain

```
BI_DB_dbo.BI_DB_PositionPnL ──────────┐
DWH_dbo.Fact_SnapshotCustomer ────────┤
DWH_dbo.Dim_Instrument ──────────────┤──► SP_Capital_Adequacy_IFR_KPMG ──► Dealing_ClientsCapitalAdequacy
DWH_dbo.Dim_Range ────────────────────┤
DWH_dbo.Dim_Regulation ──────────────┘
```

No Generic Pipeline mapping — derived from DWH-layer aggregation of position and customer data.

## Column Lineage

### Legend

| Transform | Meaning |
|-----------|---------|
| **passthrough** | Column copied as-is. |
| **ETL-computed** | Derived/calculated by ETL SP. |
| **join-enriched** | Joined from a secondary source table during ETL. |

### Columns

| DWH Column | Source Table | Source Column | Transform | Computation Formula | Notes |
|-----------|-------------|---------------|-----------|---------------------|-------|
| Date | — | — | ETL-computed | `@Date` SP parameter | Input date |
| Real/CFD | BI_DB_dbo.BI_DB_PositionPnL | IsSettled | ETL-computed | `CASE WHEN IsSettled=1 THEN 'Real' ELSE 'CFD' END` | Position settlement mode |
| InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | join-enriched | From Dim_Instrument via InstrumentID JOIN | Asset class name |
| Clients_Long_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP, IsBuy | ETL-computed | `SUM(CASE WHEN IsBuy=1 THEN NOP ELSE 0 END)` grouped by InstrumentType, Real/CFD, Regulation | Long open positions NOP value |
| Clients_Short_OP | BI_DB_dbo.BI_DB_PositionPnL | NOP, IsBuy | ETL-computed | `SUM(CASE WHEN IsBuy=0 THEN ABS(NOP) ELSE 0 END)` grouped by InstrumentType, Real/CFD, Regulation | Short open positions NOP value |
| UpdateDate | — | — | ETL-computed | `GETDATE()` | ETL load timestamp |
| Regulation | DWH_dbo.Dim_Regulation | Name | join-enriched | From Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID | Regulatory entity name |

## Summary

| Category | Count |
|----------|-------|
| **ETL-computed** | 4 |
| **Join-enriched** | 2 |
| **Passthrough** | 0 |
| **Total** | 7 (including Date as ETL-computed from SP param) |
