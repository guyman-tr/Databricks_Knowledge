# BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks

> Daily stock/ETF hedge-accounting snapshot tracking Zero PnL decomposition per instrument, hedge server, and regulatory jurisdiction. 197.6M rows covering 2019-01-01 to 2024-02-09 (frozen — table was deprecated 2024-02-15 when the live feed was redirected to Dealing_dbo.Dealing_DailyZeroPnL_Stocks). Originally populated by Dealing_dbo.SP_DailyZeroPnL_Stocks from DWH_dbo.Dim_Position, BI_DB_dbo.BI_DB_PositionPnL, and DWH_dbo.Fact_SnapshotCustomer.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (dormant — SP migrated to Dealing_dbo.Dealing_DailyZeroPnL_Stocks on 2024-02-15) |
| **Refresh** | Frozen. Was daily via Dealing_dbo.SP_DailyZeroPnL_Stocks @dd. Last data: 2024-02-09. |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX on [Date] ASC |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A |

---

## 1. Business Meaning

197.6M-row daily stock and ETF Zero PnL table recording realized and unrealized P&L decomposition per instrument, hedge server, and regulation. Each row represents one instrument–hedge-server–regulation–leverage–MifID group for a single calendar date. Data spans 2019-01-01 to 2024-02-09 across two instrument types (Stocks: 177M rows, ETF: 20M rows) and 11 regulatory jurisdictions led by CySEC (77.6M), FCA (53.4M), and ASIC & GAML (33.7M). The table is frozen: on 2024-02-15 the writer SP was updated to target Dealing_dbo.Dealing_DailyZeroPnL_Stocks instead. Use the successor table for current data.

---

## 2. Business Logic

### 2.1 Zero PnL Decomposition

**What**: Each row splits the day's P&L into realized (closed positions) and change-in-unrealized (open positions) components, summed per instrument group.
**Columns Involved**: `RealizedZero`, `ChangeInUnrealizedZero`, `TotalZero`, `RealizedCommission`
**Rules**:
- `RealizedZero` = SUM of CalculatedZero for closed positions (NetProfit ± prior PnL ± commissions).
- `ChangeInUnrealizedZero` = SUM of DailyPnL for open positions (from BI_DB_PositionPnL).
- `TotalZero` = RealizedZero + ChangeInUnrealizedZero.
- `RealizedCommission` = SUM of commission components (FullCommissionOnClose ± FullCommissionByUnits).

### 2.2 IsManual / IsCFD Flags

**What**: Two tinyint flags classifying each grouped position by trading mode and settlement type.
**Columns Involved**: `IsManual`, `IsCFD`
**Rules**:
- `IsManual` = 1 when MirrorID = 0 (direct customer trade), 0 when copy-trade (MirrorID > 0).
- `IsCFD` = 1 when IsSettled = 0 (CFD), 0 when IsSettled = 1 (real asset ownership).

---

## 3. Query Advisory

### 3.1 Distribution & Index

ROUND_ROBIN distribution with a clustered index on `[Date]` ASC. Date-range filters will efficiently prune the 197M rows; always include a `WHERE Date BETWEEN ...` clause. No HASH distribution — all hedge servers co-located queries are full-table.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|---|---|
| Daily Zero PnL by regulation | `GROUP BY Date, Regulation, InstrumentType` with `SUM(TotalZero)` |
| NOP exposure by hedge server | `WHERE Date = @d GROUP BY HedgeServerID, InstrumentID` with `SUM(NOP)` |
| Realized commission by instrument | `WHERE Date BETWEEN @from AND @to GROUP BY InstrumentID, InstrumentName` with `SUM(RealizedCommission)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Instrument | ON InstrumentID | Enrich with exchange, ISINCode, sector |
| DWH_dbo.Dim_Date | ON Date = FullDate | Calendar attributes (IsWeekend, IsHoliday) |
| Dealing_dbo.Dealing_DailyZeroPnL_Stocks | ON Date, HedgeServerID, InstrumentID | Extend historical data (this table) with current data (successor) |

### 3.4 Gotchas

- **Table is frozen at 2024-02-09.** For dates after that, use `Dealing_dbo.Dealing_DailyZeroPnL_Stocks`.
- **InstrumentType only 2 values here**: `Stocks` (89.7%) and `ETF` (10.3%) — the SP filtered `InstrumentTypeID IN (5,6)`.
- **NOP sign**: `NOP` is always positive (absolute USD exposure); `OpenPositions` is signed (positive=long, negative=short).
- **StockIndex NULL**: Many rows have NULL StockIndex (BI_DB_IndexesMapping_Static did not cover all instruments).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|---|---|
| Tier 1 | Verbatim from upstream production wiki — exact match to source |
| Tier 2 | ETL-computed, aggregated, or inherited from a Tier 2 dim column |
| Tier 3 | Grounded in DDL + SP code; no upstream wiki located for source |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | ETL reporting date parameter passed to SP_DailyZeroPnL_Stocks. Determines which open/closed positions are included in the day's calculation. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 2 | HedgeServerID | int | YES | FK to Trade.HedgeServer. Hedge server managing this position. (Tier 1 — Trade.PositionTbl) |
| 3 | Industry | varchar(250) | YES | Industry sector label from IMD (e.g., Technology, Consumer Goods). NULL for forex/crypto. From Trade.InstrumentMetaData. (Tier 1 — Trade.InstrumentMetaData) |
| 4 | InstrumentType | varchar(50) | YES | ETL-computed asset class label. CASE on InstrumentTypeID: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto Currencies, else Other. Here only 'Stocks' and 'ETF' appear (InstrumentTypeID IN (5,6) filter in SP). (Tier 2 — SP_Dim_Instrument) |
| 5 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. (Tier 1 — Trade.PositionTbl) |
| 6 | InstrumentDisplayName | varchar(250) | YES | Human-readable name shown in UI (e.g., "Apple", "EUR/USD"). Used in position displays, order forms, and APIs. (Tier 1 — Trade.InstrumentMetaData) |
| 7 | StockIndex | varchar(50) | YES | Stock exchange / index grouping from BI_DB_IndexesMapping_Static (e.g., 'US', 'GER30'). NULL when InstrumentID has no mapping. (Tier 3 — BI_DB_IndexesMapping_Static, no upstream wiki located) |
| 8 | IsManual | tinyint | YES | 1 = direct (manual) trade (MirrorID=0), 0 = copy-trade position (MirrorID > 0). Computed from Dim_Position.MirrorID. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 9 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. (Tier 1 — Trade.PositionTbl) |
| 10 | IsCFD | tinyint | YES | 1 = CFD (IsSettled=0), 0 = real asset (IsSettled=1). Inverted from Dim_Position.IsSettled. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 11 | Regulation | varchar(50) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. DWH note: ISNULL wraps NULL to 'Unknown'. (Tier 1 — Dictionary.Regulation) |
| 12 | MifID | int | YES | MiFID II client categorization (Retail/Professional/Eligible Counterparty). DEFAULT 0. Source: Ext_FSC_BackOffice_Customer.MifidCategorizationID (BO). FK to Dim_MifidCategorization. (Tier 2 — SP_Fact_SnapshotCustomer) |
| 13 | RealizedCommission | money | YES | Daily sum of commissions on closed positions per group: SUM(FullCommissionOnClose - FullCommissionByUnits) for partially-closed; SUM(FullCommissionOnClose) for fully-closed same-day positions. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 14 | RealizedZero | money | YES | Daily realized Zero PnL: SUM of CalculatedZero for closed positions (NetProfit adjusted for prior unrealized PnL and commissions). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 15 | ChangeInUnrealizedZero | money | YES | Daily change in unrealized Zero PnL: SUM of DailyPnL (from BI_DB_PositionPnL) for open positions, plus opening-day commission adjustments. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 16 | TotalZero | money | YES | Total Zero PnL for the day: SUM(CalculatedZero) across all indicators = RealizedZero + ChangeInUnrealizedZero. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 17 | NOP | money | YES | Net open position in USD from units × pair rate × USD conversion. From BI_DB_PositionPnL.NOP (always positive). (Tier 2 — SP_PositionPnL) |
| 18 | OpenPositions | money | YES | Signed net open position: SUM(NOP * direction) where direction = IsBuy=1 → +1, IsBuy=0 → -1. Positive = net long, negative = net short. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 19 | NOP_Units | numeric(38,6) | YES | Sum of instrument units in open positions for the group on the report date (AmountInUnitsDecimal). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 20 | VolumeOnOpen | bigint | YES | Sum of USD-equivalent volume for positions opened on the report date: SUM(CASE WHEN OpenDateID=RepDate THEN Volume ELSE 0 END). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 21 | VolumeOnClose | bigint | YES | Sum of USD-equivalent volume for positions closed on the report date: SUM(CASE WHEN CloseDateID=RepDate THEN VolumeOnClose ELSE 0 END). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 22 | OpenPositionValue | money | YES | Sum of invested amount plus unrealized PnL for open positions: SUM(BI_DB_PositionPnL.Amount + BI_DB_PositionPnL.PositionPnL). (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 23 | UpdateDate | datetime | YES | ETL load timestamp. GETDATE() at SP_DailyZeroPnL_Stocks execution time. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 24 | InstrumentName | varchar(100) | YES | Computed: TDCUR_BUY.Abbreviation + '/' + TDCUR_SEL.Abbreviation. Display name for UI (e.g., EUR/USD, AAPL/USD). (Tier 1 — Trade.GetInstrument) |
| 25 | Units | decimal(16,6) | YES | Total instrument units that opened or closed on the report date per group: SUM(OpenUnits + CloseUnits) from #Units temp table. (Tier 2 — SP_DailyZeroPnL_Stocks) |
| 26 | Currency | varchar(50) | YES | Trading symbol / ticker for the sell-side currency. "USD", "EUR", "GBX". UNIQUE constraint in production. Passthrough from Dictionary.Currency.Abbreviation via sell-side join. (Tier 1 — Dictionary.Currency) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| HedgeServerID | Trade.PositionTbl | HedgeServerID | Passthrough via Dim_Position |
| Industry | Trade.InstrumentMetaData | Industry | Passthrough via Dim_Instrument |
| InstrumentID | Trade.PositionTbl | InstrumentID | Passthrough via Dim_Position |
| InstrumentDisplayName | Trade.InstrumentMetaData | InstrumentDisplayName | Passthrough via Dim_Instrument |
| Leverage | Trade.PositionTbl | Leverage | Passthrough via Dim_Position |
| Regulation | Dictionary.Regulation | Name | Passthrough via Dim_Regulation; ISNULL to 'Unknown' |
| InstrumentName | Trade.GetInstrument | Name | Passthrough via Dim_Instrument.Name aliased |
| Currency | Dictionary.Currency | Abbreviation | Passthrough via Dim_Instrument.SellCurrency |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (Trade.PositionTbl origin)
DWH_dbo.Dim_Instrument (Trade.GetInstrument / InstrumentMetaData)
DWH_dbo.Dim_Regulation (Dictionary.Regulation)
DWH_dbo.Fact_SnapshotCustomer (BackOffice.Customer)
BI_DB_dbo.BI_DB_PositionPnL (SP_PositionPnL daily snapshot)
BI_DB_dbo.BI_DB_IndexesMapping_Static (static mapping)
  |-- Dealing_dbo.SP_DailyZeroPnL_Stocks @dd (DEPRECATED 2024-02-15) ---|
  v
BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks (FROZEN at 2024-02-09, 197.6M rows)

Active successor:
  |-- Dealing_dbo.SP_DailyZeroPnL_Stocks @dd ---|
  v
Dealing_dbo.Dealing_DailyZeroPnL_Stocks (live, from 2024-02-10)
```

Frozen since 2024-02-15 when NirW changed the INSERT target in SP_DailyZeroPnL_Stocks.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---|---|---|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| HedgeServerID | Trade.HedgeServer (production) | Hedge server identity |
| MifID | DWH_dbo.Dim_MifidCategorization | MiFID II client category |

### 6.2 Referenced By

| Object | Join Condition | Purpose |
|---|---|---|
| Dealing_dbo.SP_Apex_PnL | ON InstrumentID, HedgeServerID, Date | Used TotalZero for Apex broker reconciliation (pre-2024-02-15) |
| Dealing_dbo.SP_Manual_Exec_Trade | ON InstrumentID, Date | Used TotalZero for manual execution trade analysis (pre-2024-02-15) |

---

## 7. Sample Queries

### Daily Total Zero PnL by regulation for a given date

```sql
SELECT
    Date,
    Regulation,
    InstrumentType,
    SUM(TotalZero)           AS TotalZero,
    SUM(RealizedZero)        AS RealizedZero,
    SUM(ChangeInUnrealizedZero) AS UnrealizedZero,
    SUM(NOP)                 AS TotalNOP
FROM [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
WHERE Date = '2024-02-09'
GROUP BY Date, Regulation, InstrumentType
ORDER BY TotalNOP DESC;
```

### Top instruments by NOP on last available date

```sql
SELECT TOP 20
    InstrumentID,
    InstrumentDisplayName,
    InstrumentName,
    StockIndex,
    Currency,
    SUM(NOP)           AS TotalNOP,
    SUM(OpenPositions) AS NetPosition,
    SUM(NOP_Units)     AS TotalUnits
FROM [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
WHERE Date = '2024-02-09'
GROUP BY InstrumentID, InstrumentDisplayName, InstrumentName, StockIndex, Currency
ORDER BY TotalNOP DESC;
```

---

## 8. Atlassian Knowledge Sources

- No Confluence or Jira sources found for this object.
- See SR-229607 (migration to Synapse, 2024-01-31) and the 2024-02-15 change log in Dealing_dbo.SP_DailyZeroPnL_Stocks for migration history.

---

*Generated: 2026-04-29 | Quality: estimated 7.5/10 | Phases: 11/14*
*Tiers: 7 T1, 18 T2, 1 T3, 0 T4 | Elements: 26/26, Logic: present*
*Object: BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks | Type: Table | Production Source: Unknown (dormant — successor: Dealing_dbo.Dealing_DailyZeroPnL_Stocks)*
