# Lineage: BI_DB_dbo.BI_DB_Capital_Adequacy_Monthly_NOP

**Generated:** 2026-04-21 | **Writer SP:** SP_Risk_Capital_Adequacy | **Pattern:** DELETE WHERE Date=@Date + INSERT

## ETL Pipeline

```
BI_DB_PositionPnL (open position P&L)
  JOIN Dim_Instrument ON InstrumentID — InstrumentType, Real_CFD, Manual_Copy
  JOIN Fact_SnapshotCustomer ON CID — RegulationID, PlayerStatusID, MifidCategorization
  |── #capitaldata_cid (position-level NOP per customer)
  |── #capitaldata (aggregated NOP: Regulation × Player_Status × MifidCategorization × InstrumentType × Manual_Copy × Real_CFD)
  WHERE Manual_Copy = 'Copy' [copy/social-trading instruments only]
    |
    v
SP_Risk_Capital_Adequacy (@date)
    |
    v
BI_DB_dbo.BI_DB_Capital_Adequacy_Monthly_NOP
(DELETE WHERE Date=@Date + INSERT, ~40.7K rows)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform |
|---|--------|-------------|--------------|-----------|
| 1 | EOM_Date | SP computed | @date | EOMONTH(@date) — last calendar day of the reporting month |
| 2 | YearMonthID | SP computed | @date | YEAR(@date)*100 + MONTH(@date) — e.g., 202604 for April 2026 |
| 3 | Date | SP parameter | @date | Passthrough — ETL run date |
| 4 | Manual_Copy | Dim_Instrument | Manual_Copy | Passthrough — always 'Copy' in this table (SP filter: WHERE Manual_Copy='Copy') |
| 5 | Real_CFD | Dim_Instrument | Real_CFD | Passthrough — instrument type flag; values observed: 'CFD', 'Real' |
| 6 | InstrumentType | Dim_Instrument | InstrumentType | Passthrough — instrument category (Currencies, Indices, Stocks, ETF, Crypto Currencies) |
| 7 | Regulation | Dim_Regulation / Fact_SnapshotCustomer | Name / RegulationID | Resolved via sc.RegulationID; snapshot at ETL run time |
| 8 | Player_Status | Dim_PlayerStatus / Fact_SnapshotCustomer | Name / PlayerStatusID | Resolved via sc.PlayerStatusID; snapshot at ETL run time |
| 9 | MifidCategorization | Fact_SnapshotCustomer | MifidCategorization | Passthrough — MiFID II investor category at ETL run time |
| 10 | Total_NOP | BI_DB_PositionPnL | NOP / position values | Aggregated Net Open Position from #capitaldata for copy instruments; may be positive (net long) or negative (net short) |
| 11 | UpdateDate | SP metadata | GETDATE() | ETL run timestamp; rows before 2022-02-23 were backfilled at table creation |

**Note**: No IsFuture column — the Monthly_NOP DDL omits it, and the SP INSERT for Monthly_NOP does not include the IsFuture dimension.

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Open position P&L source — NOP computation base for copy instruments |
| Dim_Instrument | DWH_dbo | Instrument attributes — InstrumentType, Real_CFD, Manual_Copy |
| Fact_SnapshotCustomer | DWH_dbo | Daily customer snapshot — RegulationID, PlayerStatusID, MifidCategorization |
| Dim_Regulation | DWH_dbo | Regulation name resolver (RegulationID → Name) |
| Dim_PlayerStatus | DWH_dbo | Player status name resolver (PlayerStatusID → Name) |

## Tier Assignment Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream production wiki available) |
| Tier 2 | 11 | All columns — SP_Risk_Capital_Adequacy code analysis |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## UC External Lineage

UC Target: `_Not_Migrated`
