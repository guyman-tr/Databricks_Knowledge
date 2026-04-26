---
table: BI_DB_dbo.BI_DB_eTorian_NetProfit
schema: BI_DB_dbo
type: lineage
generated_by: batch-37
---

# Lineage: BI_DB_eTorian_NetProfit

## ETL Writer

| Property | Value |
|----------|-------|
| Stored Procedure | `BI_DB_dbo.SP_eTorian_PnL_NetProfit` |
| Input Parameter | `@Date DATE` |
| ETL Pattern | DELETE WHERE CloseDate = @Date, then INSERT |
| OpsDB Priority | 20 (third wave — depends on P0 and P15 outputs) |
| Schedule | Daily · ProcessType=SQL · SB_Daily |
| Co-writer | Same SP also writes `BI_DB_eTorian_PnL` (end-of-month only) |

## eTorian Population Filter

The SP builds a population (#list) from `DWH_dbo.Fact_SnapshotCustomer` for `@Date`:

```sql
WHERE (fsc.PlayerLevelID = 4                     -- Popular Investor level
       AND (fsc.AccountStatusID != 2 OR fsc.AccountStatusID IS NULL)  -- not deactivated
       AND fsc.AccountTypeID IN (7, 13)           -- eTorian-specific account types
       AND fsc.PlayerStatusID != 2)               -- not banned
   OR fsc.RealCID = 149                           -- system/admin account
```

`PlayerLevelID=4` = Popular Investor program participants — eToro's copy trading strategy providers. These are NOT regular retail customers (`IsValidCustomer` in Dim_Customer explicitly excludes `PlayerLevelID=4`).

## Production Source Mapping

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| CID | `DWH_dbo.Fact_SnapshotCustomer` → `Dim_Position` | RealCID / CID | Passthrough — eTorian population |
| UserName | `DWH_dbo.Dim_Customer` | UserName | Passthrough via #list JOIN |
| CloseDate | `DWH_dbo.Dim_Position` | CloseOccurred | `CAST(CloseOccurred AS DATE)` |
| EOM_CloseDate | `DWH_dbo.Dim_Position` | CloseOccurred | `EOMONTH(CAST(CloseOccurred AS DATE))` — last day of month |
| NetProfit_Crypto | `DWH_dbo.Dim_Position` | NetProfit WHERE InstrumentTypeID=10 | `SUM(CASE WHEN InstrumentTypeID=10 THEN NetProfit ELSE 0 END)` |
| NetProfit_Stocks_ETFs | `DWH_dbo.Dim_Position` | NetProfit WHERE InstrumentTypeID IN (5,6) | `SUM(CASE WHEN InstrumentTypeID IN (5,6) THEN NetProfit ELSE 0 END)` |
| NetProfit_Other | `DWH_dbo.Dim_Position` | NetProfit WHERE InstrumentTypeID IN (1,2,4) | `SUM(CASE WHEN InstrumentTypeID IN (1,2,4) THEN NetProfit ELSE 0 END)` |
| UpdateDate | — | — | `GETDATE()` |

## Instrument Type Mapping (from Dim_Instrument)

| InstrumentTypeID | Type | NetProfit Column |
|-----------------|------|-----------------|
| 10 | Crypto Currencies | NetProfit_Crypto |
| 5 | Stocks (real ownership) | NetProfit_Stocks_ETFs |
| 6 | ETF (real ownership) | NetProfit_Stocks_ETFs |
| 1 | Currencies (Forex) | NetProfit_Other |
| 2 | Commodities | NetProfit_Other |
| 4 | Indices | NetProfit_Other |

## ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer + Dim_Range + Dim_Customer
  (WHERE PlayerLevelID=4, AccountTypeID IN (7,13), not deactivated/banned)
  → #list (eTorian CID × UserName population for @Date)

DWH_dbo.Dim_Position (WHERE CloseDateID = @DateID)
  JOIN #list ON CID
  JOIN DWH_dbo.Dim_Instrument ON InstrumentID
  → GROUP BY CID, UserName, CloseDate
  → SUM NetProfit by InstrumentTypeID bucket
  → #pos

[End-of-month only]
BI_DB_dbo.BI_DB_PositionPnL (WHERE DateID=@DateID)
  JOIN #list, Dim_Instrument
  → #PnL (unrealized open position PnL at month-end)
  → DELETE + INSERT → BI_DB_eTorian_PnL

DELETE WHERE CloseDate=@Date + INSERT FROM #pos
→ BI_DB_dbo.BI_DB_eTorian_NetProfit
```

## Grain

One row per `CID × CloseDate`. A CID can have multiple rows for different close dates. All positions closed by a Popular Investor on a given date are aggregated into a single row per CID per date, split by asset class.
