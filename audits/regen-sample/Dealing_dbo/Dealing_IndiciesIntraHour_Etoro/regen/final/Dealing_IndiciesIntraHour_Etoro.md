# Dealing_dbo.Dealing_IndiciesIntraHour_Etoro

> ~8.7M-row minute-level aggregation table capturing eToro's hedge-side intra-hour activity for three index instruments (hedge IDs 254, 255, 259 mapping to S&P 500, DJ30, GER30) from 2022-05-22 to present — recording per-minute execution volumes, net open position (NOP) in units and USD, position values, and realized P&L per liquidity account, sourced from hedge execution logs and netting data via SP_IntraHourIndexReport daily.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | etoro_Hedge_ExecutionLog + etoro_Hedge_Netting + PriceLog via SP_IntraHourIndexReport |
| **Refresh** | Daily (1440 min, Append via Generic Pipeline) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | `general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro` |
| **UC Format** | Delta |
| **UC Partitioned By** | None |
| **UC Table Type** | Gold export (Generic Pipeline, Append) |

---

## 1. Business Meaning

Dealing_IndiciesIntraHour_Etoro is the eToro hedge-side component of the intra-hour hedging activity report. While the companion table `Dealing_IndiciesIntraHour_Clients` tracks what clients are doing (positions, unrealized P&L), this table tracks what eToro's hedge desk is doing through liquidity providers — execution volumes, net open positions (NOP), and realized values per minute per liquidity account.

The table covers three hardcoded index instruments mapped through PortfolioConversionConfigurations: S&P 500 (original InstrumentID=27), DJ30 (28), and GER30 (32). However, the InstrumentID stored here is the **hedge instrument ID** (254, 255, 259 as of current data), not the original index ID. This is because the Etoro side records activity against the hedge-mapped instruments used for actual execution with liquidity providers.

**Data volume**: ~8.7M rows spanning 2022-05-22 to 2026-04-26. Each row represents one minute of activity for one liquidity account, one hedge instrument, and one hedge server.

**Key dimensions**:
- **LiquidityAccountID/LiquidityAccountName**: Currently 2 active accounts — "EMSX Marex Indices Real" (ID=275) and "EMSX Marex MAEX Real" (ID=317)
- **HedgeServerID**: Added 2024-04-30 (SR-249626). Current active servers: 8 and 25. Older rows have NULL HedgeServerID.

**ETL pattern**: `SP_IntraHourIndexReport @Date` runs daily. It DELETEs existing rows for @Date, then INSERTs fresh data. The SP:
1. Maps original index instruments (27/28/32) to hedge instruments via PortfolioConversionConfigurations
2. Loads hedge execution data from CopyFromLake.etoro_Hedge_ExecutionLog for the day
3. Loads netting positions from etoro_Hedge_Netting (current) and etoro_History_Netting_History (historical)
4. Resolves liquidity account names from etoro_Trade_LiquidityAccounts
5. Pulls prices from CopyFromLake.PriceLog_History_CurrencyPrice (with gap-filling)
6. Computes per-minute volumes, NOP, position values, and realized P&L per liquidity account per instrument per hedge server
7. Filters out minutes with zero activity (WHERE VolumeBuy<>0 OR VolumeSell<>0 OR NOP<>0 OR ValueStart<>0 OR ValueRealized<>0 OR ValueEnd<>0)

**Row filtering**: Unlike the client-side companion (which includes all minutes), the Etoro table only stores minutes with non-zero activity, making it sparser.

---

## 2. Business Logic

### 2.1 Volume Calculation (VolumeBuy / VolumeSell)

**What**: USD-equivalent execution volumes per minute from eToro's hedge executions with liquidity providers.

**Columns Involved**: `VolumeBuy`, `VolumeSell`

**Rules**:
- Raw volumes from etoro_Hedge_ExecutionLog: SUM(Units * ExecutionRate) per direction (IsBuy=1 for buy, IsBuy=0 for sell)
- Converted to USD via ConversionFirst from PriceLog_History_CurrencyPrice: final = SUM(raw_volume * ConversionFirst)
- ISNULL defaults to 0 when no executions occurred in a minute

### 2.2 Net Open Position (Units_NOP / NOP)

**What**: eToro's aggregate net open position from netting data, in both units and USD equivalent.

**Columns Involved**: `Units_NOP`, `NOP`

**Rules**:
- Source: etoro_Hedge_Netting (current) UNION etoro_History_Netting_History (historical), with temporal filtering (SysStartTime/SysEndTime)
- Per netting record, direction encoded as: (2 * IsBuy - 1) — yields +1 for buy, -1 for sell
- Units_NOP = SUM(Units * (2*IsBuy-1)) — net units (positive = net long, negative = net short)
- NOP = SUM(Units * ConversionFirst * (2*IsBuy-1) * CASE WHEN IsBuy=1 THEN FirstBid ELSE FirstAsk END) — USD-equivalent NOP using direction-appropriate price
- When multiple netting records overlap a minute for the same instrument, ROW_NUMBER(ORDER BY SysEndTime DESC) picks the most recent
- ISNULL defaults to 0

### 2.3 Position Values (ValueStart / ValueEnd)

**What**: USD value of eToro's hedge position at start and end of each minute.

**Columns Involved**: `ValueStart`, `ValueEnd`

**Rules**:
- ValueStart uses the identical formula to NOP: SUM(Units * ConversionFirst * (2*IsBuy-1) * price). In practice, ValueStart = NOP for each row.
- ValueEnd = next minute's ValueStart via self-join (te1.fromMinute = te.toMinute AND same LiquidityAccountID AND InstrumentID). Defaults to 0 for the last active minute.
- This enables minute-to-minute position value tracking and P&L decomposition.

### 2.4 Realized Value

**What**: Net realized value from hedge executions in the minute.

**Columns Involved**: `ValueRealized`

**Rules**:
- ValueRealized = SUM(VolumeSell * ConversionFirst) - SUM(VolumeBuy * ConversionFirst)
- Positive = net selling (reducing hedge position); Negative = net buying (adding hedge position)
- ISNULL defaults to 0

### 2.5 Price Smoothing (Bid / Ask source)

**What**: Prices used in NOP/Value calculations come from PriceLog with gap-filling.

**Columns Involved**: (internal to computation — prices not stored as columns in this table)

**Rules**:
- Raw prices from PriceLog_History_CurrencyPrice, bucketed to 1-minute intervals (last price per minute via ROW_NUMBER ORDER BY Occurred DESC)
- NULL gaps forward-filled using OUTER APPLY (find latest non-NULL price before this minute)
- FirstBid/FirstAsk = LAG(LastBid/LastAsk, 1) — previous minute's last price = start-of-current-minute price
- ConversionFirst = LAG(Conversion, 1) — USD conversion rate at start of minute

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN**: All data evenly spread across distributions. No single column dominates query patterns enough for HASH.

**Clustered Index on [Date]**: Date-range queries are efficient. Always include `WHERE [Date] BETWEEN ... AND ...`.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Intra-day hedge activity for a day | `WHERE [Date] = '2026-04-25' AND InstrumentID = 254 ORDER BY Minute_Start` |
| Daily hedge volume totals | `SELECT [Date], SUM(VolumeBuy), SUM(VolumeSell) WHERE InstrumentID = 254 GROUP BY [Date]` |
| NOP exposure at a point in time | `WHERE [Date] = '2026-04-25' AND Minute_Start = '2026-04-25 14:30:00'` |
| Compare liquidity accounts | `GROUP BY LiquidityAccountName` to compare EMSX Marex Indices Real vs EMSX Marex MAEX Real |
| Client vs eToro comparison | JOIN with Dealing_IndiciesIntraHour_Clients ON Date, Minute_Start, InstrumentID (note: instrument IDs differ — use PortfolioConversionConfigurations mapping) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Resolve hedge instrument name, asset class |
| Dealing_dbo.Dealing_IndiciesIntraHour_Clients | ON Date, Minute_Start + instrument mapping | Compare client-side vs eToro hedging activity |

### 3.4 Gotchas

- **Hedge instrument IDs, not original indices**: InstrumentIDs here are 254, 255, 259 (hedge instruments), NOT 27, 28, 32 (original indices). To JOIN with the client-side table, use PortfolioConversionConfigurations to map between them.
- **Only 3 instruments**: This table ONLY contains data for three index instruments (hedge-mapped equivalents of S&P 500, DJ30, GER30).
- **Sparse minutes**: Unlike the client-side table, rows are only stored for minutes with non-zero activity (WHERE VolumeBuy<>0 OR NOP<>0 OR ...). Not every minute of the day has a row.
- **HedgeServerID is NULL for pre-2024 data**: Added 2024-04-30 (SR-249626). Older rows have NULL. Current active servers: 8, 25.
- **NOP = ValueStart**: Both columns use the identical formula in the SP. They are always equal.
- **ValueEnd can be 0**: For the last active minute, the self-join finds no next minute, so ValueEnd defaults to 0 (not NULL, unlike the client-side companion which uses NULL).
- **LiquidityAccountID granularity**: Each row is per liquidity account per minute. To get total eToro exposure, aggregate across LiquidityAccountIDs.
- **Delete-insert pattern per day**: Re-running SP_IntraHourIndexReport for a past date replaces all rows for that date.
- **Volume is USD-equivalent**: VolumeBuy/VolumeSell are Units * ExecutionRate * USDConversionRate — an approximate USD value.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 2 | ETL-computed in SP_IntraHourIndexReport — transform documented from SP code |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Trading date extracted from the minute bucket. CONVERT(DATE, fromMinute). One row per instrument per minute per liquidity account per HedgeServerID per date. (Tier 2 — SP_IntraHourIndexReport) |
| 2 | InstrumentID | int | YES | Hedge instrument ID. Represents the hedge-mapped instrument used for execution with liquidity providers, mapped from original index instruments (27/28/32) via PortfolioConversionConfigurations. Current hedge IDs: 254, 255, 259. FK to Trade.Instrument. (Tier 2 — etoro_Hedge_ExecutionLog / etoro_Hedge_PortfolioConversionConfigurations) |
| 3 | Minute_Start | datetime | YES | Start of the 1-minute time bucket (e.g., '2026-04-25 14:30:00'). Generated from a minute grid covering the full 24-hour day. (Tier 2 — SP_IntraHourIndexReport) |
| 4 | Minute_End | datetime | YES | End of the 1-minute time bucket (Minute_Start + 1 minute, e.g., '2026-04-25 14:31:00'). (Tier 2 — SP_IntraHourIndexReport) |
| 5 | LiquidityAccountName | varchar(max) | YES | Name of the liquidity provider account used for hedge execution. Resolved from etoro_Trade_LiquidityAccounts via JOIN on LiquidityAccountID. Current values: 'EMSX Marex Indices Real', 'EMSX Marex MAEX Real'. (Tier 2 — etoro_Trade_LiquidityAccounts) |
| 6 | LiquidityAccountID | int | YES | Liquidity provider account identifier. FK to Trade.LiquidityAccounts. Used as a grouping dimension — each row represents one liquidity account per minute. Current IDs: 275, 317. (Tier 2 — etoro_Hedge_ExecutionLog) |
| 7 | VolumeBuy | float | YES | USD-equivalent buy volume from hedge executions in the minute. SUM(Units * ExecutionRate) for IsBuy=1 from ExecutionLog, multiplied by USD ConversionFirst from PriceLog. ISNULL defaults to 0. (Tier 2 — etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice) |
| 8 | VolumeSell | float | YES | USD-equivalent sell volume from hedge executions in the minute. SUM(Units * ExecutionRate) for IsBuy=0 from ExecutionLog, multiplied by USD ConversionFirst from PriceLog. ISNULL defaults to 0. (Tier 2 — etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice) |
| 9 | Units_NOP | float | YES | Net open position in units from netting data. SUM(Units * (2*IsBuy-1)): positive = net long, negative = net short. Sources: etoro_Hedge_Netting (current) UNION etoro_History_Netting_History (historical). ISNULL defaults to 0. (Tier 2 — etoro_Hedge_Netting / etoro_History_Netting_History) |
| 10 | NOP | float | YES | Net open position in USD equivalent. SUM(Units * ConversionFirst * (2*IsBuy-1) * CASE IsBuy=1 THEN FirstBid ELSE FirstAsk END). Uses direction-appropriate price from PriceLog. Identical formula to ValueStart. ISNULL defaults to 0. (Tier 2 — etoro_Hedge_Netting / PriceLog_History_CurrencyPrice) |
| 11 | ValueStart | float | YES | USD value of eToro's hedge position at start of this minute. Identical formula to NOP: SUM(Units * ConversionFirst * (2*IsBuy-1) * price). Always equals NOP for the same row. ISNULL defaults to 0. (Tier 2 — etoro_Hedge_Netting / PriceLog_History_CurrencyPrice) |
| 12 | ValueEnd | float | YES | USD value of eToro's hedge position at end of this minute. Equals the next minute's ValueStart via self-join (te1.fromMinute = te.toMinute, same LiquidityAccountID and InstrumentID). Defaults to 0 for the last active minute of the day. (Tier 2 — etoro_Hedge_Netting / PriceLog_History_CurrencyPrice) |
| 13 | ValueRealized | float | YES | Net realized value from hedge executions in the minute. SUM(VolumeSell * ConversionFirst) - SUM(VolumeBuy * ConversionFirst). Positive = net selling (reducing position); negative = net buying (adding position). ISNULL defaults to 0. (Tier 2 — etoro_Hedge_ExecutionLog / PriceLog_History_CurrencyPrice) |
| 14 | UpdateDate | datetime | YES | ETL execution timestamp. Set to GETDATE() at SP_IntraHourIndexReport run time. (Tier 2 — SP_IntraHourIndexReport) |
| 15 | HedgeServerID | int | YES | Hedge server identifier used as a grouping dimension. Added 2024-04-30 (SR-249626). NULL for pre-2024 rows. Current active values: 8, 25. Sourced from ExecutionLog and Netting data. (Tier 2 — etoro_Hedge_ExecutionLog / etoro_Hedge_Netting) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| Date | (generated) | — | CONVERT(DATE, minute bucket) |
| InstrumentID | etoro_Hedge_ExecutionLog | InstrumentID | Passthrough (hedge instrument, mapped via PortfolioConversionConfigurations) |
| Minute_Start | (generated) | — | Minute grid start |
| Minute_End | (generated) | — | Minute grid end |
| LiquidityAccountName | etoro_Trade_LiquidityAccounts | LiquidityAccountName | Passthrough via JOIN on LiquidityAccountID |
| LiquidityAccountID | etoro_Hedge_ExecutionLog | LiquidityAccountID | Passthrough |
| VolumeBuy | etoro_Hedge_ExecutionLog + PriceLog | Units, ExecutionRate, USDConversionRate | SUM(Units*ExecutionRate) for IsBuy=1, * ConversionFirst |
| VolumeSell | etoro_Hedge_ExecutionLog + PriceLog | Units, ExecutionRate, USDConversionRate | SUM(Units*ExecutionRate) for IsBuy=0, * ConversionFirst |
| Units_NOP | etoro_Hedge_Netting / etoro_History_Netting_History | Units, IsBuy | SUM(Units * (2*IsBuy-1)) |
| NOP | etoro_Hedge_Netting + PriceLog | Units, IsBuy, Bid/Ask, ConversionRate | SUM(Units * Conversion * direction * price) |
| ValueStart | etoro_Hedge_Netting + PriceLog | Units, IsBuy, Bid/Ask, ConversionRate | Same formula as NOP |
| ValueEnd | (self-join) | ValueStart | Next minute's ValueStart; 0 for last minute |
| ValueRealized | etoro_Hedge_ExecutionLog + PriceLog | VolumeSell, VolumeBuy, ConversionRate | SUM(VolumeSell*Conv) - SUM(VolumeBuy*Conv) |
| UpdateDate | (generated) | — | GETDATE() |
| HedgeServerID | etoro_Hedge_ExecutionLog / etoro_Hedge_Netting | HedgeServerID | Passthrough |

### 5.2 ETL Pipeline

```
etoro.Hedge.ExecutionLog (hedge executions)
etoro.Hedge.Netting (current netting)
etoro.History.Netting_History (historical netting)
etoro.Trade.LiquidityAccounts (LP names)
PriceLog.History.CurrencyPrice (bid/ask prices)
etoro.Hedge/History.PortfolioConversionConfigurations (instrument mapping)
  |-- Generic Pipeline / CopyFromLake (Bronze export) --|
  v
CopyFromLake.etoro_Hedge_ExecutionLog
CopyFromLake.PriceLog_History_CurrencyPrice
Dealing_staging.etoro_Hedge_Netting
Dealing_staging.etoro_History_Netting_History
Dealing_staging.etoro_Trade_LiquidityAccounts
Dealing_staging.etoro_Hedge/History_PortfolioConversionConfigurations
  |
  |-- SP_IntraHourIndexReport @Date --|
  |   (DELETE+INSERT for @Date, Etoro section)
  |   1. Map instruments via PortfolioConversionConfigurations
  |   2. Load executions from ExecutionLog
  |   3. Load netting positions (current + historical)
  |   4. Pull prices from PriceLog (5-day window, gap-filled)
  |   5. Compute volumes, NOP, values, realized per minute per LP per instrument per HedgeServer
  |   6. Filter to minutes with non-zero activity
  v
Dealing_dbo.Dealing_IndiciesIntraHour_Etoro (~8.7M rows)
  |-- Generic Pipeline (Append, delta, daily) --|
  v
general.gold_sql_dp_prod_we_dealing_dbo_dealing_indiciesintrahour_etoro
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Resolve hedge instrument name, asset class (IDs 254, 255, 259) |
| LiquidityAccountID | Trade.LiquidityAccounts | Liquidity provider account identifier |
| HedgeServerID | Trade.HedgeServer | Hedge server managing this position |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|-------------|-------------|
| Dealing_dbo.Dealing_IndiciesIntraHour_Clients | Companion table | Client-side of the same intra-hour report; typically joined on Date, Minute_Start, InstrumentID (with mapping), HedgeServerID |

---

## 7. Sample Queries

### 7.1 Intra-Day Hedge Activity for an Instrument

```sql
SELECT Minute_Start,
       LiquidityAccountName,
       VolumeBuy,
       VolumeSell,
       Units_NOP,
       NOP,
       ValueRealized
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Etoro
WHERE [Date] = '2026-04-25'
  AND InstrumentID = 254
ORDER BY Minute_Start, LiquidityAccountName;
```

### 7.2 Daily NOP Summary by Liquidity Account

```sql
SELECT [Date],
       LiquidityAccountName,
       InstrumentID,
       SUM(VolumeBuy) AS TotalVolumeBuy,
       SUM(VolumeSell) AS TotalVolumeSell,
       MAX(ABS(NOP)) AS PeakNOP
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Etoro
WHERE [Date] >= '2026-04-01'
GROUP BY [Date], LiquidityAccountName, InstrumentID
ORDER BY [Date], LiquidityAccountName;
```

### 7.3 Client vs eToro Volume Comparison (Requires Instrument Mapping)

```sql
-- Note: Client table uses original InstrumentIDs (27,28,32); Etoro uses hedge IDs (254,255,259)
-- Use PortfolioConversionConfigurations to map between them
SELECT c.[Date],
       c.Minute_Start,
       c.InstrumentID AS ClientInstrumentID,
       e.InstrumentID AS HedgeInstrumentID,
       SUM(c.VolumeBuy) AS ClientVolumeBuy,
       SUM(e.VolumeBuy) AS EtoroVolumeBuy
FROM Dealing_dbo.Dealing_IndiciesIntraHour_Clients c
JOIN Dealing_staging.etoro_Hedge_PortfolioConversionConfigurations pcc
  ON c.InstrumentID = pcc.InstrumentID
JOIN Dealing_dbo.Dealing_IndiciesIntraHour_Etoro e
  ON c.[Date] = e.[Date]
  AND c.Minute_Start = e.Minute_Start
  AND pcc.InstrumentIDToHedge = e.InstrumentID
  AND c.HedgeServerID = e.HedgeServerID
WHERE c.[Date] = '2026-04-25'
GROUP BY c.[Date], c.Minute_Start, c.InstrumentID, e.InstrumentID
ORDER BY c.Minute_Start;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources were searched in this regen run (Phase 10 skipped in harness mode). SP change history references SR-249626 (HedgeServerID addition, 2024-04-30) and SR-257613 (CopyFromLake migration, 2024-06-18).

---

*Generated: 2026-04-30 | Phases: 11/14*
*Tiers: 0 T1, 15 T2, 0 T3, 0 T4, 0 T5 | Elements: 15/15, Logic: 5 subsections*
*Object: Dealing_dbo.Dealing_IndiciesIntraHour_Etoro | Type: Table | Production Source: etoro_Hedge_ExecutionLog + etoro_Hedge_Netting + PriceLog via SP_IntraHourIndexReport*
