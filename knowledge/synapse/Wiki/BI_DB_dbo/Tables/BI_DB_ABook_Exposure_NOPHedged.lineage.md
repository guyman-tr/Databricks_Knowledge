# Lineage: BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_ABook_Exposure_NOPHedged
**Object Type**: Table — ABook hedging NOP exposure snapshot (net-only, per liquidity account)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Generic Pipeline #471 (Override, every 60 min) — source table from Synapse production (SynapseSourceWithoutSecret)
**UC Target**: `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged`
**Related Tables**:
- `BI_DB_dbo.BI_DB_ABook_Exposure` (same 17-col schema sans Liquidity/proxy columns, HedgeServerID-clustered — current-state companion, EMPTY)
- `BI_DB_dbo.BI_DB_ABook_Exposure_History` (DATE-clustered historical log companion, EMPTY)
- `BI_DB_dbo.External_etoro_Hedge_HedgeServerToLiquidityAccount` (Bronze/etoro/Hedge/HedgeServerToLiquidityAccount)
**HedgeServer Reference**: `BI_DB_dbo.External_etoro_Trade_HedgeServer` (Bronze/etoro/Trade/HedgeServer)

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | Date | Unknown (ABook hedging feed) | Date | Trading date | Tier 3 |
| 2 | InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | Passthrough | Tier 3 |
| 3 | InstrumentIDToHedge | Unknown (ABook proxy hedge mapping) | InstrumentID | Proxy hedge instrument; NULL = hedge same instrument (85% null in live data) | Tier 3 |
| 4 | InstrumentID_Final | Derived | InstrumentIDToHedge ?? InstrumentID | COALESCE(InstrumentIDToHedge, InstrumentID) | Tier 3 |
| 5 | InstrumentName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | Passthrough / truncated to varchar(45) | Tier 3 |
| 6 | InstrumentType | DWH_dbo.Dim_Instrument | InstrumentType | Passthrough | Tier 3 |
| 7 | HedgeServerID | External_etoro_Trade_HedgeServer | HedgeServerID | Passthrough (FK) | Tier 3 |
| 8 | LiquidityAccountID | External_etoro_Hedge_HedgeServerToLiquidityAccount | LiquidityAccountID | Passthrough (FK); NULL when no LP assigned | Tier 3 |
| 9 | LiquidityAccountName | Unknown (LP account configuration system) | AccountName | De-normalized LP name | Tier 3 |
| 10 | NOP | Unknown (ABook hedged position feed) | — | Net NOP after hedging | Tier 3 |
| 11 | Nop_Units | Unknown | — | Net NOP in instrument units | Tier 3 |
| 12 | NOPHedged | Unknown (ABook hedging engine) | — | Dollar value of NOP externally hedged | Tier 3 |
| 13 | OpenPositions | Unknown | — | Net open position after hedging | Tier 3 |
| 14 | Short | Unknown | — | Net short exposure after hedging | Tier 3 |
| 15 | Long | Unknown | — | Net long exposure after hedging | Tier 3 |
| 16 | UpdateDate | ETL pipeline | — | Load timestamp | Tier 5 |

## ETL Pipeline

```
etoro ABook hedging engine (external hedging system)
  |-- Unknown feed mechanism (no SSDT SP, no External Table for this table) --|
  v
BI_DB_dbo.BI_DB_ABook_Exposure_NOPHedged (15,178 rows — stale as of 2024-02-15)
  |-- Generic Pipeline #471 (Override strategy, every 60 min) --|
  v
Gold/sql_dp_prod_we/BI_DB_dbo/BI_DB_ABook_Exposure_NOPHedged/ (parquet, Azure Data Lake)
  |-- Unity Catalog auto-discovery --|
  v
bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_abook_exposure_nophedged (UC table)

Reference data:
  External_etoro_Hedge_HedgeServerToLiquidityAccount → Bronze/etoro/Hedge/HedgeServerToLiquidityAccount
  External_etoro_Trade_HedgeServer → Bronze/etoro/Trade/HedgeServer
  DWH_dbo.Dim_Instrument → instrument metadata

Related dormant tables (same source, no active pipeline):
  BI_DB_ABook_Exposure (0 rows — EMPTY)
  BI_DB_ABook_Exposure_History (0 rows — EMPTY)
```

## Notes

- Table has live data (15,178 rows from 2024-02-15) but stale — last update 2024-02-15 00:08:38
- No unhedged columns — net-only view vs siblings which have {metric}_unhedged pairs
- New columns vs siblings: InstrumentIDToHedge (proxy hedge), InstrumentID_Final (resolved hedge instrument), LiquidityAccountID/LiquidityAccountName (LP granularity)
- 85% of rows have NULL InstrumentIDToHedge — most instruments hedge with same instrument
- 25% of rows have NULL LiquidityAccountID — positions without assigned LP (likely BBook or unassigned)
- Override strategy: table is replaced on each Generic Pipeline run (single-date snapshot semantics)
- 44 distinct liquidity accounts observed; top accounts: APEX Traffix (3,032), EMSX JPM (2,591), Horizon OMS Apex (1,254)
