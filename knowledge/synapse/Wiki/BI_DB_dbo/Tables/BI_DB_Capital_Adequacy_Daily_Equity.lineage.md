# Lineage: BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_Equity

**Generated:** 2026-04-21 | **Writer SP:** SP_Risk_Capital_Adequacy | **Pattern:** DELETE WHERE Date=@Date + INSERT

## ETL Pipeline

```
V_Liabilities (customer cash balances)
  JOIN Fact_SnapshotCustomer ON CID — VerLevelID≥2, IsCreditReportValidCB=1
  |── #customerbalance_cid (Regulation, Player_Status, MifidCategorization, cash equity)
  |
BI_DB_PositionPnL (open CFD position P&L)
  JOIN Dim_Instrument ON InstrumentID — IsFuture, InstrumentType, Real_CFD flags
  JOIN Fact_SnapshotCustomer ON CID — customer attributes
  |── #capitaldata_cid (position-level P&L per customer)
  |── #capitaldata (aggregated by customer + Regulation + Status)
  |── #cfdequity (CFD unrealized equity: Regulation × Player_Status × MifidCategorization × IsFuture)
  |
FULL OUTER JOIN #customerbalance_cid + #cfdequity
  |── #kcmh (combined: ISNULL(cash,0) + ISNULL(cfd_equity,0))
  WHERE RegulationID IN (1,2,4,5,10) [CySEC, BVI, FCA, ASIC, ASIC+GAML]
    |
    v
SP_Risk_Capital_Adequacy (@date)
    |
    v
BI_DB_dbo.BI_DB_Capital_Adequacy_Daily_Equity
(DELETE WHERE Date=@Date + INSERT, ~493K rows)
```

## Column Lineage

| # | Column | Source Table | Source Column | Transform |
|---|--------|-------------|--------------|-----------|
| 1 | EOM_Date | SP computed | @date | EOMONTH(@date) — last calendar day of the reporting month |
| 2 | Date | SP parameter | @date | Passthrough — ETL run date |
| 3 | Regulation | Dim_Regulation / Fact_SnapshotCustomer | Name / RegulationID | Resolved via sc.RegulationID; only IN(1,2,4,5,10) included |
| 4 | Player_Status | Dim_PlayerStatus / Fact_SnapshotCustomer | Name / PlayerStatusID | Resolved via sc.PlayerStatusID in #customerbalance_cid / #cfdequity |
| 5 | MifidCategorization | Fact_SnapshotCustomer | MifidCategorization | Passthrough — customer MiFID II category at ETL run time |
| 6 | Unrealized_Equity | #kcmh | cash_balance + cfd_unrealized_equity | ISNULL(cash,0) + ISNULL(cfd_equity,0) via FULL OUTER JOIN; may be negative |
| 7 | UpdateDate | SP metadata | GETDATE() | ETL run timestamp; rows before 2022-02-23 were backfilled at table creation |
| 8 | IsFuture | Dim_Instrument | IsFuture | Via #cfdequity from position data; NULL for cash-only rows (no matching CFD position in FULL OUTER JOIN) |

## Source Objects

| Object | Schema | Role |
|--------|--------|------|
| V_Liabilities | DWH_dbo | Customer cash balance view — VerLevelID≥2 and IsCreditReportValidCB=1 required |
| Fact_SnapshotCustomer | DWH_dbo | Daily customer snapshot — RegulationID, PlayerStatusID, MifidCategorization, VerLevelID |
| BI_DB_PositionPnL | BI_DB_dbo | Open position P&L source for CFD unrealized equity calculation |
| Dim_Instrument | DWH_dbo | Instrument attributes — IsFuture, InstrumentType, Real_CFD classification |
| Dim_Regulation | DWH_dbo | Regulation name resolver (RegulationID → Name) |
| Dim_PlayerStatus | DWH_dbo | Player status name resolver (PlayerStatusID → Name) |

## Tier Assignment Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 1 | 0 | — (no upstream production wiki available) |
| Tier 2 | 8 | All columns — SP_Risk_Capital_Adequacy code analysis |
| Tier 3 | 0 | — |
| Tier 4 | 0 | — |

## UC External Lineage

UC Target: `_Not_Migrated`
