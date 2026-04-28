---
object: Dealing_Apex_PnL
schema: Dealing_dbo
lineage_type: lp-external-staging
generated: 2026-03-21
---

# Lineage — Dealing_Apex_PnL

## Pipeline Status

**STALE** — Last data 2024-06-07. Writer SP exists but pipeline appears inactive.

## ETL Chain

```
Apex LP Files (external)
    → Dealing_staging.LP_APEX_EXT872_3EU_217314  (trades, dividends)
    → Dealing_staging.LP_APEX_EXT982_3EU          (NOP/holdings)
    → Dealing_staging.PriceLog_History_CurrencyPrice (prices)
    → Dealing_dbo.Dealing_DailyZeroPnL_Stocks     (zero positions)
    → DWH_dbo.Dim_Instrument                      (symbol lookup)
    → DWH_dbo.Dim_Date                            (date/holiday logic)
        → SP_Apex_PnL
            → Dealing_dbo.Dealing_Apex_PnL        (WTD grain)
            → Dealing_dbo.Dealing_Apex_PnL_Daily  (daily grain)
            → Dealing_dbo.Dealing_Apex_PnL_EE     (equity WTD)
            → Dealing_dbo.Dealing_Apex_PnL_EE_Daily (equity daily)
```

## Production Source

| Attribute | Value |
|-----------|-------|
| Generic Pipeline mapping | Not found — LP external staging, not tracked in Generic Pipeline |
| Source system | Apex Clearing LP (external US equities broker/clearer) |
| Upstream wiki | None — external LP data |

## Column Lineage

| DWH Column | Source Table | Source Column | Transform |
|------------|-------------|---------------|-----------|
| Date | SP parameter | @Date | passthrough |
| AccountNumber | LP_APEX_EXT982_3EU | AccountNumber | passthrough |
| Symbol | LP_APEX_EXT982_3EU | Symbol | passthrough |
| NOP_Start | LP_APEX_EXT982_3EU | MarketValue (Friday) | cast to decimal |
| NOP_Start_DBPrice | PriceLog_History_CurrencyPrice | Bid (Friday) × Qty | ETL-computed |
| NOP_End | LP_APEX_EXT982_3EU | MarketValue (Date) | cast to decimal |
| NOP_End_DBPrice | PriceLog_History_CurrencyPrice | Bid (Date) × Qty | ETL-computed |
| Trades | LP_APEX_EXT872_3EU_217314 | Trade activity | ETL-computed (net) |
| Dividends | LP_APEX_EXT872_3EU_217314 | Dividend records | ETL-computed (sum) |
| PnL | Computed | NOP_End - NOP_Start - Trades + Dividends + AdditionalFees | ETL-computed |
| PnL_DBPrice | Computed | NOP_End_DBPrice - NOP_Start_DBPrice - Trades + Dividends + AdditionalFees | ETL-computed |
| InstrumentID | DWH_dbo.Dim_Instrument | InstrumentID | resolved via Symbol/CUSIP/ISIN join |
| Zero | Dealing_DailyZeroPnL_Stocks | TotalZero | SUM over week |
| UpdateDate | ETL | GETDATE() | ETL metadata |
