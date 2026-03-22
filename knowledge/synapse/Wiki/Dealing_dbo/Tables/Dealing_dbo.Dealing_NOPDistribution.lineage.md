# Lineage: Dealing_dbo.Dealing_NOPDistribution

## Source Tables
| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_PositionPnL | Copier positions (NOP, IsBuy, MirrorID) |
| DWH_dbo.Dim_Mirror | Copy relationship mapping (MirrorID → ParentCID) |
| DWH_dbo.Dim_Instrument | InstrumentType, SymbolFull |
| DWH_dbo.Fact_SnapshotCustomer | IsValidCustomer, AccountTypeID, GuruStatusID |
| DWH_dbo.Dim_Range | SCD2 date range filter |
| DWH_dbo.Dim_GuruStatus | GuruStatusName lookup |

## Column Lineage

| Target Column | Source | Transformation |
|---------------|--------|----------------|
| Date | Parameter | `@Date` |
| DateID | Parameter | `DateToDateID(@Date)` |
| InstrumentID | BI_DB_PositionPnL.InstrumentID | Direct |
| InstrumentType | Dim_Instrument.InstrumentType | Direct |
| NOP | BI_DB_PositionPnL.NOP, IsBuy | `SUM((2*IsBuy-1)*NOP)` — signed aggregation across copiers |
| ParentUserName | Dim_Mirror.ParentUserName | Direct (joined via MirrorID) |
| ParentCID | Dim_Mirror.ParentCID | Direct |
| PI/CP | Fact_SnapshotCustomer.AccountTypeID | `CASE WHEN AccountTypeID=9 THEN 'CopyFund' ELSE 'PI' END` |
| SymbolFull | Dim_Instrument.SymbolFull | Direct |
| UpdateDate | — | `GETDATE()` |
| GuruStatusName | Dim_GuruStatus.GuruStatusName | Lookup via Fact_SnapshotCustomer.GuruStatusID |

## No Generic Pipeline Mapping
This table is not in the generic pipeline mapping.
