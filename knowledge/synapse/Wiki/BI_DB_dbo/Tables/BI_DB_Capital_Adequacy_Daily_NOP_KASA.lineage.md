# Lineage: BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_NOP_KASA

**Generated:** 2026-04-21 | **Writer SP:** SP_Risk_Capital_Adequacy | **Pattern:** DELETE WHERE Date=@Date + INSERT

## ETL Pipeline

```
BI_DB_PositionPnL (open position P&L)
  JOIN Dim_Instrument ON InstrumentID — InstrumentType, Real_CFD, Manual_Copy, IsFuture
  JOIN Fact_SnapshotCustomer ON CID — RegulationID, PlayerStatusID, MifidCategorization
  |── #capitaldata_cid (position-level NOP per customer)
  |── #capitaldata (aggregated NOP: Regulation × Player_Status × MifidCategorization × InstrumentType × Manual_Copy × Real_CFD × IsFuture)
  WHERE Real_CFD = 'Real' [real CFD instruments only — excludes copy/synthetic positions]
    |
    v
SP_Risk_Capital_Adequacy (@date)
    |
    v
BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_NOP_KASA
(DELETE WHERE Date=@Date + INSERT, ~1.34M rows)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform |
|---|--------|-------------|--------------|-----------|
| 1 | EOM_Date | SP computed | @date | EOMONTH(@date) — last calendar day of the reporting month |
| 2 | Date | SP parameter | @date | Passthrough — ETL run date |
| 3 | Manual_Copy | Dim_Instrument | Manual_Copy | Passthrough — instrument classification: manual-entry vs copy-trade instrument |
| 4 | Real_CFD | Dim_Instrument | Real_CFD | Passthrough — instrument type flag; always 'Real' in this table (SP filter: WHERE Real_CFD='Real') |
| 5 | InstrumentType | Dim_Instrument | InstrumentType | Passthrough — instrument category (Currencies, Indices, Stocks, ETF, Crypto Currencies) |
| 6 | Regulation | Dim_Regulation / Fact_SnapshotCustomer | Name / RegulationID | Resolved via sc.RegulationID; snapshot at ETL run time |
| 7 | Player_Status | Dim_PlayerStatus / Fact_SnapshotCustomer | Name / PlayerStatusID | Resolved via sc.PlayerStatusID; snapshot at ETL run time |
| 8 | MifidCategorization | Fact_SnapshotCustomer | MifidCategorization | Passthrough — MiFID II investor category at ETL run time |
| 9 | Total_NOP | BI_DB_PositionPnL | NOP / position values | Aggregated Net Open Position in money terms from #capitaldata; may be positive (net long) or negative (net short) |
| 10 | UpdateDate | SP metadata | GETDATE() | ETL run timestamp; rows before 2022-02-23 were backfilled at table creation |
| 11 | IsFuture | Dim_Instrument | IsFuture | Instrument futures flag: 1=futures, 0=spot CFD; NULL possible where instrument metadata is absent |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| BI_DB_PositionPnL | BI_DB_dbo | Open position P&L source — NOP computation base |
| Dim_Instrument | DWH_dbo | Instrument attributes — InstrumentType, Real_CFD, Manual_Copy, IsFuture |
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
