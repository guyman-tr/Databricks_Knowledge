---
object: Dealing_Apex_PnL_EE
schema: Dealing_dbo
lineage_type: lp-external-staging
generated: 2026-03-21
---

# Lineage — Dealing_Apex_PnL_EE

## ETL Chain

Same SP as Dealing_Apex_PnL. See Dealing_Apex_PnL.lineage.md for full chain.

```
Apex LP equity statement files (external)
    → Dealing_staging tables (equity, transfers, dividends per account)
        → SP_Apex_PnL
            → Dealing_dbo.Dealing_Apex_PnL_EE  (equity WTD)
```

## Column Lineage

| DWH Column | Source | Transform |
|------------|--------|-----------|
| Date | SP @Date | passthrough |
| AccountNumber | Apex equity files | COALESCE(equity.AccountNumber, transfers.AccountNumber, dividends.AccountNumber) |
| Equity_Start | Apex equity statement | Friday EOD equity value |
| Equity_End | Apex equity statement | This-day EOD equity value |
| Transfers | Apex transfers feed | SUM of transfers this week |
| PnL | Computed | Equity_End - Equity_Start - Transfers |
| Dividends | Apex dividend feed | SUM of dividends per account this week |
| UpdateDate | ETL | GETDATE() |
