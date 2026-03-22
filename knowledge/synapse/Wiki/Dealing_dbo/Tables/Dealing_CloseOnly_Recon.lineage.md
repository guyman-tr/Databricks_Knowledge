# Column Lineage: Dealing_dbo.Dealing_CloseOnly_Recon

**Generated**: 2026-03-21 | **Batch**: 5 | **Writer SP**: SP_CloseOnly_Recon

## Pipeline Summary

```
Dealing_dbo.Dealing_Duco_EODRecon (@Date)          ─┐ (today's holdings — prerequisite)
Dealing_dbo.Dealing_Duco_EODRecon (@Previous_Date)  ─┘─► SP_CloseOnly_Recon ──► Dealing_CloseOnly_Recon
   (filtered: AllowBuy=0 AND AllowSell=0)                (skip Sundays)         (DELETE+INSERT by Current_Date)
   (self-join: current vs previous business day)
```

## Column-Level Lineage

| Column | Source Table | Source Column | Transformation |
|--------|-------------|---------------|----------------|
| Current_Date | @Date parameter | — | Today's date |
| Previous_Date | @Previous_Date | — | Previous business day (Fri if today=Mon) |
| HedgeServerID | Dealing_Duco_EODRecon | HedgeServerID | GROUP BY key (current date) |
| InstrumentID | Dealing_Duco_EODRecon | InstrumentID | GROUP BY key |
| InstrumentDisplayName | Dealing_Duco_EODRecon | InstrumentDisplayName | From current date row |
| Symbol | Dealing_Duco_EODRecon | Symbol | From current date row |
| ISINCode | Dealing_Duco_EODRecon | ISINCode | From current date row |
| CurrencyPrimary | Dealing_Duco_EODRecon | SellCurrency | From current date row |
| Exchange | Dealing_Duco_EODRecon | Exchange | From current date row |
| AllowClosePosition | Dealing_Duco_EODRecon | AllowBuy=0 AND AllowSell=0 flag | 1 for close-only instruments |
| Change_in_Units_Clients | — | current.ClientUnits − previous.ClientUnits | Delta computation |
| Change_in_Units_eToro | — | current.eToro_Units − previous.eToro_Units | Delta computation |
| ClientUnits | Dealing_Duco_EODRecon | ClientUnits | Current date aggregate |
| ClientUnits_Previous | Dealing_Duco_EODRecon | ClientUnits | Previous date aggregate |
| eToro_Units | Dealing_Duco_EODRecon | eToro_Units | Current date LP units |
| eToro_Units_Previous | Dealing_Duco_EODRecon | eToro_Units | Previous date LP units |
| Change_in_Amount_Clients | — | current.ClientAmount − previous.ClientAmount | Delta computation |
| Change_in_USDAmount_eToro | — | current.eToroUSDAmount − previous.eToroUSDAmount | Delta computation |
| ClientAmount | Dealing_Duco_EODRecon | ClientAmount | Current date USD client amount |
| ClientAmount_Previous | Dealing_Duco_EODRecon | ClientAmount | Previous date USD client amount |
| eToroUSDAmount | Dealing_Duco_EODRecon | eToroUSDAmount | Current date LP USD amount |
| eToroUSDAmount_Previous | Dealing_Duco_EODRecon | eToroUSDAmount | Previous date LP USD amount |
| UpdateDate | GETDATE() | — | Batch timestamp |

## Scope Filter

```sql
-- Only instruments in close-only mode:
WHERE AllowBuy = 0 AND AllowSell = 0
-- From Dealing_Duco_EODRecon filtered set
```

## Weekend-Aware Previous Date Logic

```
IF today = Monday:
    Previous_Date = Friday (skip Sat/Sun)
ELSE IF today = Sunday:
    SP does not run
ELSE:
    Previous_Date = yesterday
```

## ETL Pattern

- DELETE WHERE Current_Date=@Date → INSERT
- Requires Dealing_Duco_EODRecon for BOTH @Date AND @Previous_Date (SP_DataForDuco must complete first)
- Skips Sundays
