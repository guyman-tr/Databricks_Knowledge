---
object: Dealing_Apex_PnL_Daily
schema: Dealing_dbo
lineage_type: lp-external-staging
generated: 2026-03-21
---

# Lineage — Dealing_Apex_PnL_Daily

## Pipeline Status

**STALE** — Last data 2024-06-07. Same pipeline as Dealing_Apex_PnL.

## ETL Chain

Same as `Dealing_Apex_PnL` — see that lineage file. Both tables are written in the same SP_Apex_PnL execution run: Dealing_Apex_PnL gets the WTD INSERT and Dealing_Apex_PnL_Daily gets the daily INSERT.

```
SP_Apex_PnL (@Date)
    → DELETE/INSERT Dealing_Apex_PnL        (WTD logic — uses #NOP, #Trades_ApexFiles, etc.)
    → DELETE/INSERT Dealing_Apex_PnL_EE     (equity WTD)
    → DELETE/INSERT Dealing_Apex_PnL_Daily  (daily logic — uses #NOP_Daily, #Trades_ApexFiles_Daily, etc.)
    → DELETE/INSERT Dealing_Apex_PnL_EE_Daily (equity daily)
```

## Column Lineage

Identical to Dealing_Apex_PnL — same columns, same source mapping. Daily versions use `#NOP_Daily` and `#Trades_ApexFiles_Daily` temp tables (prior day NOP vs same-week NOP).
