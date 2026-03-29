# Dealing_dbo.Dealing_HedgeCost

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_HedgeCost |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 15 |
| **Primary Source** | `etoro.Hedge.ExecutionLog` (etoroDB-REAL) via `CopyFromLake.etoro_Hedge_ExecutionLog` |
| **ETL SP** | `Dealing_dbo.SP_HedgeCost` |
| **Refresh** | Daily per @Date (delete+insert) |
| **PII** | none |
| **Tags** | dealing, hedging, LP, hedge-cost, stocks, ETF, commission |

---

## 1. Business Meaning

`Dealing_HedgeCost` is a **daily summary of eToro's hedge execution cost for USD-denominated Stocks and ETFs**. It compares the net client position flow (what clients bought/sold and at what average price) against the actual LP (Liquidity Provider) hedge executions, calculating the net hedge cost (HC) that eToro incurs or earns from the difference.

**Scope**: Only `InstrumentTypeID IN (5, 6)` (Stocks and ETFs) with `SellCurrencyID = 1` (USD-denominated). Forex, Commodities, Indices, and Crypto are excluded. This reflects the dealing desk's hedging activity in the equity market.

The key metric is **HC (Hedge Cost)**: the difference between what eToro charged clients (at spreaded ask price) and what eToro actually paid in the market (via LP execution rates and commissions). A positive HC means eToro recovered more from the spread than it paid in hedging; negative HC means eToro paid more for the hedge than it recovered.

**Business context** (SP author: Sarah Benchitrit, 2020): Used by the Dealing team to monitor daily hedge P&L per instrument×HedgeServer×IsSettled combination. The HC analysis helps identify instruments where hedging is costly relative to the spread income.

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_HedgeCost(@Date)` processes only Stocks & ETFs with USD sell currency:

1. **LP Executions** (`#LP`): Reads `CopyFromLake.etoro_Hedge_ExecutionLog` (source: `etoro.Hedge.ExecutionLog` on etoroDB-REAL, loaded hourly). Filters successful executions (`Success=1`) on `@Date`. Net units = `SUM(Units × (IsBuy×2-1))` — positive for net buy executions, negative for net sell. AvgRate = weighted average execution rate. `IsSettled` is derived: HedgeServerIDs {9, 102, 112, 125, 126} = 'Real' (settled assets); all others = 'CFD'.

2. **Client Positions** (`#Position`): Reads `Dim_Position` (source: `Trade.PositionTbl`) for valid customers, joined to `Dim_Instrument` (stocks/ETFs, USD) and `Dim_Customer` (IsValidCustomer=1). UNION ALL combines:
   - Positions **opened on @Date**: uses `InitForexRate`, standard `IsBuy`
   - Positions **closed on @Date**: uses `EndForexRate`, **IsBuy is inverted** (a closing buy becomes a sell in terms of net flow)

3. **IsSettled correction** (`#IsSettled_pcl`): For positions that changed IsSettled status **after** @Date (ChangeTypeID=13 in `Dim_PositionChangeLog`), takes `PreviousIsSettled` — i.e., what the position's settlement status was AT @Date. This corrects for positions that were converted between Real and CFD after the reporting day.

4. **Client aggregation** (`#Clients`): Per instrument×HS×IsSettled: net units, total volume, weighted avg rate, half of FullCommissionOnClose (`FullCommissionByUnits`). The halving reflects that commission is shared between open and close events.

5. **Final join** (`#Final`): Joins clients with LP executions, `Dealing_DailyZeroPnL_Stocks` (realized commission from zero-PnL events), and `BI_DB_VarCommission` (variable spread commission).

6. **HC (Hedge Cost) formula**:
   ```
   HC = [AskSpreaded × NetClientUnits - (NetClientUnits × ClientAvgRate - FullCommission)]
      - [AskSpreaded × LP_Executed_Units - LP_Executed_Units × LP_Avg_Rate]
   ```
   - **Client side**: `AskSpreaded × NetClientUnits` is what eToro would charge clients at the current spreaded ask; minus `(units × client rate - commission)` = actual net received from clients at market rate. This represents the spread income from clients.
   - **LP side**: `AskSpreaded × LP_Executed_Units - LP_Executed_Units × LP_Avg_Rate` = spread-equivalent value of LP hedge minus actual LP execution cost.
   - **HC = Client spread income - LP hedge cost difference**: Positive = profitable hedge; negative = hedge cost exceeds spread income.

### Coverage Note

The Dec 2024 change (SR-286858) replaced the old execution log with CopyFromLake, moving from a DWH staging table to the lake-sourced `etoro_Hedge_ExecutionLog`.

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `CopyFromLake.etoro_Hedge_ExecutionLog` | `InstrumentID, HedgeServerID, ExecutionTime` | LP execution records (source) |
| `DWH_dbo.Dim_Position` | `PositionID` | Client position data |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter (stocks/ETFs, USD) |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter |
| `DWH_dbo.Dim_PositionChangeLog` | `PositionID` | IsSettled correction (ChangeTypeID=13) |
| `Dealing_dbo.Dealing_DailyZeroPnL_Stocks` | `Date, InstrumentID, HedgeServerID, IsCFD` | Realized commission from zero-PnL |
| `BI_DB_dbo.BI_DB_VarCommission` | `DateID, InstrumentID, IsSettled, HedgeServerID` | Variable spread commission |
| `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | AskSpreaded price for HC calc |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_HedgeCost)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |
| ★ | Tier 4 — inferred [UNVERIFIED] | `[UNVERIFIED] (Tier 4 — inferred)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date for this hedge cost record. Matches the `@Date` parameter passed to SP_HedgeCost. Clustered index key. (Tier 2 — SP_HedgeCost) |
| 2 | InstrumentID | int | YES | Identifier for the tradeable instrument (Stocks and ETFs, USD-denominated only). FK to DWH_dbo.Dim_Instrument. Only instruments with InstrumentTypeID IN (5,6) and SellCurrencyID=1 appear in this table. (Tier 2 — SP_HedgeCost) |
| 3 | Name | varchar(50) | YES | Instrument name from `DWH_dbo.Dim_Instrument.Name` (internal name, e.g., 'COP.US/USD'). Note: in Phase 1 DDL this is varchar(50) which may truncate long names; prefer InstrumentDisplayName from Dim_Instrument for display. (Tier 2 — SP_HedgeCost) |
| 4 | IsSettled | varchar(20) | YES | 1 = real asset, 0 = CFD asset. (Tier 5 — Expert Review) |
| 5 | Clients_Units | decimal(16,6) | YES | Net client position units for this instrument×HS×IsSettled on `Date`. Computed as `SUM((IsBuy×2-1) × AmountInUnitsDecimal)` across all opens and closes for valid customers. Positive = net long client flow (clients bought more than sold); negative = net short client flow. (Tier 2 — SP_HedgeCost) |
| 6 | AvgRateClientsNoSpread | decimal(16,6) | YES | Client net volume per unit minus commission per unit, representing the effective market rate seen by clients excluding the spread. Formula: `(NetUnits × AvgRate - FullCommission) / NetUnits`. This backs out the commission from the client's average rate to isolate the pure market rate component. Zero when NetUnits=0. (Tier 2 — SP_HedgeCost) |
| 7 | VolumeMarket | decimal(16,6) | YES | Total USD dollar volume of client positions (both opens and closes) for this instrument×HS×IsSettled. Sum of `Volume` from Dim_Position (computed in Dim_Position as AmountInUnits × price). (Tier 2 — SP_HedgeCost) |
| 8 | LP_Executed_Units | decimal(16,6) | YES | Net units actually executed by eToro's Liquidity Provider on this date for this instrument×HS×IsSettled. Sourced from `etoro.Hedge.ExecutionLog.Units × (IsBuy×2-1)`, only successful executions (`Success=1`). Positive = LP bought (hedging eToro's net short exposure); negative = LP sold. Zero when no LP executions occurred. (Tier 2 — SP_HedgeCost) |
| 9 | LP_Avg_Rate | decimal(16,6) | YES | Volume-weighted average execution rate for LP hedge trades. `SUM(Units × ExecutionRate) / SUM(Units × (IsBuy×2-1))` from `etoro.Hedge.ExecutionLog`. Represents the average market price at which eToro hedged this instrument through the LP. Zero when LP_Executed_Units=0. (Tier 2 — SP_HedgeCost) |
| 10 | LP_Volume | decimal(16,6) | YES | Total USD volume of LP hedge executions: `SUM(Units × ExecutionRate)` from `etoro.Hedge.ExecutionLog`. Zero when no LP executions occurred. (Tier 2 — SP_HedgeCost) |
| 11 | HC | decimal(16,6) | YES | **Hedge Cost** — the net P&L impact of hedging for eToro. Formula: `AskSpreaded × (Clients_Units - LP_Executed_Units) - (Clients_Units × ClientAvgRate - FullCommission) + LP_Executed_Units × LP_Avg_Rate`. Simplification: (spread income from client flow) minus (LP hedge cost). Positive HC = eToro earned more from the spread than it paid in hedging; negative HC = hedging costs exceeded spread income. This is the primary KPI of this table. (Tier 2 — SP_HedgeCost) |
| 12 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at the time SP_HedgeCost ran. Not a business timestamp. (Tier 2 — SP_HedgeCost) |
| 13 | HedgeServerID | int | YES | The HedgeServer that managed these positions. IDs {9, 102, 112, 125, 126} are classified as 'Real' (settled assets); all others are 'CFD'. Key dimension for separating settled-stock hedging from CFD hedging. (Tier 2 — SP_HedgeCost) |
| 14 | FullCommission | decimal(16,6) | YES | Realized commission amount from `Dealing_DailyZeroPnL_Stocks.RealizedCommission` — zero-PnL based commission accruals for this date. Note: differs from `AvgRateClientsNoSpread` computation which uses `FullCommissionByUnits/2` (half-commission) from Dim_Position. This column stores the zero-PnL realized commission. (Tier 2 — SP_HedgeCost) |
| 15 | VariableSpread | decimal(16,6) | YES | Variable spread commission from `BI_DB_dbo.BI_DB_VarCommission` for this instrument×HedgeServer×IsSettled on `Date`. Represents the variable component of spread revenue. Note: `BI_DB_VarCommission` must have data for the same DateID for this to populate; NULL when no variable commission data exists. (Tier 2 — SP_HedgeCost) |

---

## 5. Usage Notes

**Primary use**: Compare `HC` across instruments and HedgeServers to identify costly instruments. Negative HC indicates instruments where hedging losses exceed spread income — these may need pricing review.

**IsSettled granularity**: Filter by `IsSettled` to separate analysis of Real (settled stock/ETF custody) vs CFD hedging. Real and CFD positions are hedged differently and have different risk profiles.

**Joining to Dim_Instrument**: Join on `InstrumentID` for instrument metadata (type, sector, full name). Note that only Stocks (TypeID=5) and ETFs (TypeID=6) with USD denomination appear here.

**Distribution**: ROUND_ROBIN with clustered index on `Date`. Efficient for single-date queries. For date-range queries, always filter on `Date` first.

**HC formula nuance**: `AskSpreaded` is the spreaded ask price from `Fact_CurrencyPriceWithSplit` at the closing price for `@Date`. Both client and LP calculations use the same reference price, so HC measures the rate differential — not absolute pricing.

**Zero LP case**: When `LP_Executed_Units=0`, the HC reduces to: `AskSpreaded × Clients_Units - (Clients_Units × ClientAvgRate - FullCommission)` — pure spread income from unhedged flow.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | `etoro.Hedge.ExecutionLog` (etoroDB-REAL) via Generic Pipeline → `dealing.bronze_etoro_hedge_executionlog` → `CopyFromLake.etoro_Hedge_ExecutionLog` (hourly) |
| **Refresh** | Daily per date via `SP_HedgeCost(@Date)` |
| **SP Author** | Sarah Benchitrit (2020) |
| **Last Modified** | Dec 2024 (SR-286858: replaced execution log source with CopyFromLake) |
| **PII** | none — aggregate instrument+HS level, no CID data |
| **Scope** | USD-denominated Stocks (TypeID=5) and ETFs (TypeID=6) only |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL, distribution, index |
| Live Data | 5/5 | Sample up to 2026-03-10 (current) |
| SP Logic | 5/5 | Short SP fully analyzed |
| Upstream Wiki | 2/5 | Production source identified (etoro.Hedge.ExecutionLog); no upstream wiki for Hedge schema |
| Business Context | 2/5 | Atlassian MCP unavailable; HC formula and business logic fully recovered from SP |
| **Total** | **7.8/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
