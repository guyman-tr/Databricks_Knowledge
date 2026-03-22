# Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

## 1. Overview
Minute-by-minute LP/eToro-side hedging activity for index instruments (SPX500=27, DJ30=28, NSDQ100=32). Shows the LP's net open position, hedge volumes, and mark-to-market value at each minute, broken down by liquidity account and hedge server.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | Clustered (Date ASC) |
| **Row Count** | ~8.4M |
| **Date Range** | 2022-05-22 → present |
| **Grain** | One row per Date × Minute × InstrumentID × LiquidityAccountID × HedgeServerID |
| **Refresh** | Daily, via SP_IntraHourIndexReport |

## 2. Business Context
Companion table to `Dealing_IndiciesIntraHour_Clients`. While the Clients table shows client exposure, this table shows how eToro's liquidity providers (LPs) are hedging that exposure in real time. By comparing client NOP and LP NOP at each minute, the dealing desk can identify gaps between client exposure and LP hedging activity. The table includes the LP account name and the hedge execution volumes from the execution log.

**Author**: Graham Ellinson (created 2022-05-29). Same SP as the Clients table.

## 3. Elements

| Column | Data Type | Nullable | Description | Tier | Source |
|--------|-----------|----------|-------------|------|--------|
| Date | date | Yes | Trading date | T2 | SP_IntraHourIndexReport: `CONVERT(DATE, te.fromMinute)` |
| InstrumentID | int | Yes | Index instrument (mapped via PortfolioConversionConfigurations to hedge instruments) | T2 | SP_IntraHourIndexReport |
| Minute_Start | datetime | Yes | Start of the 1-minute interval | T2 | SP_IntraHourIndexReport: `te.fromMinute` |
| Minute_End | datetime | Yes | End of the 1-minute interval | T2 | SP_IntraHourIndexReport: `te.toMinute` |
| LiquidityAccountName | varchar(max) | Yes | LP account display name | T2 | SP_IntraHourIndexReport: from etoro_Trade_LiquidityAccounts |
| LiquidityAccountID | int | Yes | LP account identifier | T2 | SP_IntraHourIndexReport: from ExecutionLog |
| VolumeBuy | float | Yes | LP buy volume in USD for this minute. Formula: `SUM(CASE WHEN IsBuy=1 THEN Units*ExecutionRate) * ConversionFirst` | T2 | SP_IntraHourIndexReport |
| VolumeSell | float | Yes | LP sell volume in USD for this minute | T2 | SP_IntraHourIndexReport |
| Units_NOP | float | Yes | LP net open position in units. Formula: `SUM(Units * (2*IsBuy-1))` from netting tables | T2 | SP_IntraHourIndexReport |
| NOP | float | Yes | LP net open position in USD. Formula: `SUM(Units * ConversionFirst * (2*IsBuy-1) * (IsBuy?FirstBid:FirstAsk))` | T2 | SP_IntraHourIndexReport |
| ValueStart | float | Yes | Mark-to-market value at minute start. Same formula as NOP | T2 | SP_IntraHourIndexReport |
| ValueEnd | float | Yes | Mark-to-market value at minute end. Uses next minute's ValueStart via self-join | T2 | SP_IntraHourIndexReport: `te1.ValueStart` |
| ValueRealized | float | Yes | Realized value from LP executions. Formula: `SUM(VolumeSell*ConversionFirst - VolumeBuy*ConversionFirst)` | T2 | SP_IntraHourIndexReport |
| UpdateDate | datetime | Yes | Row write timestamp | T2 | SP_IntraHourIndexReport: `GETDATE()` |
| HedgeServerID | int | Yes | Hedge server for this LP position. Added SR-249626 | T2 | SP_IntraHourIndexReport |

## 4. Relationships
| Related Object | Relationship | Join Condition |
|----------------|--------------|----------------|
| CopyFromLake.etoro_Hedge_ExecutionLog | LP execution log | InstrumentID, LiquidityAccountID, ExecutionTime range |
| Dealing_staging.etoro_Trade_LiquidityAccounts | LP account name | LiquidityAccountID |
| Dealing_staging.etoro_Hedge_Netting | LP current positions | InstrumentID, LiquidityAccountID |
| Dealing_staging.etoro_History_Netting_History | LP historical positions | SCD2 temporal |
| CopyFromLake.PriceLog_History_CurrencyPrice | Minute-resolution prices | InstrumentID |
| Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Companion client-side table | Same SP, same instruments, same time grain |

## 5. ETL Details
| Property | Value |
|----------|-------|
| **Primary SP** | `Dealing_dbo.SP_IntraHourIndexReport` |
| **Parameters** | `@Date DATE` |
| **Load Pattern** | DELETE + INSERT for @Date |
| **Key Logic** | 1) Identify LP accounts from ExecutionLog for index instruments. 2) Generate minute × LP account grid. 3) Reconstruct LP NOP from netting tables (UNION current+history, ROW_NUMBER dedup). 4) Pull LP volumes from ExecutionLog. 5) Join to forward-filled prices. 6) Aggregate NOP, volumes, values per minute per LP account. 7) Self-join for ValueEnd. 8) Filter: only output rows where at least one measure is non-zero. |

## 6. Data Lifecycle
- **Retention**: No automated cleanup
- **Volume**: ~1440 minutes × 3+ instruments × N LP accounts per day

## 7. Known Gaps
- Same instrument set (27, 28, 32) as the Clients table — other asset classes not covered
- LP execution data depends on CopyFromLake sync
- Netting dedup ROW_NUMBER uses SysEndTime DESC — most recent state wins

## 8. Quality Score
**7.5/10** — Well-traced LP hedging activity at minute resolution. Companion to Clients table with consistent grain. Complex netting reconstruction logic is well-documented.
