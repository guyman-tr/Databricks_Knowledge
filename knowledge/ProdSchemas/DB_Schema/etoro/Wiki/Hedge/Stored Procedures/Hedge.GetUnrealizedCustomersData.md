# Hedge.GetUnrealizedCustomersData

> Computes current unrealized customer P&L per active hedge server and instrument by joining open positions from Trade.PositionTbl against live currency and price rate data, returning per-server/instrument aggregates.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns: HedgeServerID, InstrumentID, UnrealizedPL, CommissionOnOpen, OpenedBuyUnits, OpenedSellUnits, PriceRateID, NetOpenInUSD |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetUnrealizedCustomersData` is the unrealized P&L computation procedure for the hedge cost system. It calculates, at the moment of execution, the total unrealized profit/loss of all open customer positions that are in scope for hedge computation (`IsComputeForHedge = 1, StatusID = 1`), grouped by hedge server and instrument.

The procedure is more complex than its realized counterpart - it must join live market prices and handle multi-currency conversion to express everything in USD. The result is consumed by `Hedge.AddCustomersDataGeneral` to populate `Hedge.CustomerOpenPositions`.

**Design notes (from in-code change history)**:
- Re-engineered 2015-11-24 (Yitzchak Wahnon / Paz): fundamental change in how UnrealizedPnL is calculated.
- 2019-07-02 (Danny): performance improvements using CLUSTERED COLUMNSTORE INDEX on temp tables, removed MAXDOP.
- 2020-01-16 (Pini): NetOpenInUSD set to 0 (Hernan approval) - the value is computed but capped/zeroed by a commented-out formula.

---

## 2. Business Logic

### 2.1 Multi-Currency Unrealized P&L Calculation

**What**: For each open hedge-eligible position, computes the PnL in USD using live bid/ask prices and currency conversion rates.

**Columns/Parameters Involved**: `IsBuy`, `InitForexRate`, `AmountInUnitsDecimal`, `ReciprocalForConversion`, `ConversionInstrumentID`

**Rules**:
- PnL per position = `(CurrentRate - InitForexRate) * AmountInUnitsDecimal * ConversionRate`
  - For `IsBuy = 1` (long): uses `Bid - InitForexRate` (profit when price rises)
  - For `IsBuy = 0` (short): uses `InitForexRate - Ask` (profit when price falls)
- Currency conversion: `ReciprocalForConversion` controls how `Con.Bid` is applied:
  - `-1`: no conversion needed (already USD-denominated)
  - `0`: multiply by `Con.Bid`
  - `1`: divide by `Con.Bid` (reciprocal)
  - else: `0` (conversion unavailable)
- `Commission = ISNULL(SUM(TPOS.Commission), 0)` summed per server/instrument.

### 2.2 Temp Table Architecture for Performance

**What**: Uses two temp tables with CLUSTERED indexes for join optimization.

**Columns/Parameters Involved**: `#Data` (currency/rate lookup), `#S1` (per-server/instrument aggregates)

**Rules**:
- `#Data`: currency and price rate data per instrument. CLUSTERED on InstrumentID. Pre-computed JOIN between Trade.Instrument, Dictionary.Currency, Trade.CurrencyPrice, Trade.InstrumentConversion.
- `#S1`: position aggregates per (HedgeServerID, InstrumentID). CLUSTERED on HedgeServerID. Uses MAXDOP 4 for the main aggregation query.
- Final CTE: RIGHT OUTER JOIN with Trade.HedgeServer (IsActive=1) ensures all active hedge servers appear in output, even if they have no open positions (with NULL-to-zero substitution via ISNULL).

### 2.3 NetOpenInUSD Capping

**What**: The USD net exposure value is clamped to prevent extreme values from corrupting reports.

**Columns/Parameters Involved**: `NetOpenInUSD`

**Rules**:
- The actual NetOpenInUSD calculation via `Internal.GetNetOpenInUSD` is commented out (`/*...*/ 0`) - NetOpenInUSD is always returned as 0 (per approval by Hernan, 2020-01-16).
- The final SELECT nonetheless applies a cap: if NetOpenInUSD > 9,999,999,999.9999 or < -9,999,999,999.9999, clamp to those bounds. This cap was left in after the zeroing, providing safety if the calculation is re-enabled.

**Diagram**:
```
Trade.Instrument
  JOIN Dictionary.Currency (SellCurrencyID)
  JOIN Trade.CurrencyPrice (InstrumentID)
  LEFT JOIN Trade.InstrumentConversion (SellCurrencyID)
  --> #Data (InstrumentID CLUSTERED index)

Trade.PositionTbl (IsComputeForHedge=1, StatusID=1)
  INNER JOIN #Data
  LEFT JOIN #Data (conversion instrument)
  GROUP BY (HedgeServerID, InstrumentID) MAXDOP 4
  --> #S1 (HedgeServerID CLUSTERED index)

Trade.HedgeServer (IsActive=1)
  RIGHT OUTER JOIN #S1
  --> Result: one row per active HedgeServer (even with no positions)
  --> Order By HedgeServerID, InstrumentID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

*This procedure takes no parameters.*

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (no parameters) | - | - | - | - | - | This procedure is called without parameters; it uses the current state of Trade.PositionTbl, Trade.HedgeServer, and live price data at execution time. |

**Output columns (result set):**

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | HedgeServerID | int | Hedge server for this aggregate. All active servers appear (RIGHT OUTER JOIN ensures this). |
| 2 | InstrumentID | int | Trading instrument. InstrumentID = 1 appears as default for servers with no open positions (ISNULL placeholder). |
| 3 | UnrealizedPL | decimal | Sum of unrealized P&L for all hedge-eligible open positions on this server/instrument, in USD, at current market prices. ISNULL(..., 0) returns 0 for servers with no positions. |
| 4 | CommissionOnOpen | decimal | Sum of commission charged when these positions were opened, in USD. |
| 5 | OpenedBuyUnits | decimal | Total units of long open positions on this instrument/server. |
| 6 | OpenedSellUnits | decimal | Total units of short open positions on this instrument/server. |
| 7 | PriceRateID | bigint | Market rate snapshot ID used for this computation. MAX(PriceRateID) within the group - the most recent rate used. |
| 8 | NetOpenInUSD | decimal | Always 0 in current implementation (calculation commented out). Originally: USD equivalent of net open units, capped at +/-9,999,999,999.9999. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.PositionTbl | READ (NOLOCK) | Source of all open hedge-eligible customer positions |
| - | Trade.Instrument | READ (NOLOCK) | Currency denomination lookup per instrument |
| - | Dictionary.Currency | JOIN (NOLOCK) | Currency metadata for sell-side currency of each instrument |
| - | Trade.CurrencyPrice | JOIN (NOLOCK) | Live bid/ask prices for currency conversion |
| - | Trade.InstrumentConversion | LEFT JOIN (NOLOCK) | Conversion rate lookup for non-USD instrument pairs |
| - | Trade.HedgeServer | RIGHT OUTER JOIN (NOLOCK) | Ensures all active hedge servers appear in output |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.AddCustomersDataGeneral | EXEC call | Caller | Calls this procedure to populate Hedge.CustomerOpenPositions with unrealized P&L snapshot |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetUnrealizedCustomersData (procedure)
├── Trade.PositionTbl (table) [READ - NOLOCK, IsComputeForHedge=1, StatusID=1]
├── Trade.Instrument (table) [READ - NOLOCK]
├── Dictionary.Currency (table) [JOIN - NOLOCK]
├── Trade.CurrencyPrice (table) [JOIN - NOLOCK]
├── Trade.InstrumentConversion (table) [LEFT JOIN - NOLOCK]
└── Trade.HedgeServer (table) [RIGHT OUTER JOIN - NOLOCK, IsActive=1]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Source of open customer positions (IsComputeForHedge=1, StatusID=1) |
| Trade.Instrument | Table | Provides BuyCurrencyID, SellCurrencyID per instrument |
| Dictionary.Currency | Table | Provides currency metadata for sell-side conversion |
| Trade.CurrencyPrice | Table | Live bid/ask prices for PnL and currency conversion calculation |
| Trade.InstrumentConversion | Table | Provides conversion instrument and reciprocal flag for cross-currency PnL |
| Trade.HedgeServer | Table | Ensures complete output - all active servers included |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AddCustomersDataGeneral | Stored Procedure | Calls this to get unrealized customer data for Hedge.CustomerOpenPositions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OPTION (MAXDOP 4) | Query hint | Limits parallelism on the PositionTbl aggregation query; CLUSTERED COLUMNSTORE INDEX on temp tables for performance |
| IsComputeForHedge = 1 | Business filter | Includes only positions flagged as in-scope for hedge computation |
| StatusID = 1 | Business filter | Includes only open positions (StatusID = 1 = Open in Trade.PositionTbl) |
| IsActive = 1 | Server filter | Includes only active hedge servers in the output |

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC [Hedge].[GetUnrealizedCustomersData]
```

### 8.2 Check open positions in scope for hedge compute
```sql
SELECT HedgeServerID, InstrumentID, COUNT(*) AS PositionCount,
       SUM(AmountInUnitsDecimal) AS TotalUnits
FROM [Trade].[PositionTbl] WITH (NOLOCK)
WHERE IsComputeForHedge = 1 AND StatusID = 1
GROUP BY HedgeServerID, InstrumentID
ORDER BY TotalUnits DESC
```

### 8.3 View current unrealized positions snapshot
```sql
SELECT TOP 20 HedgeServerID, InstrumentID, OccurredAt,
       UnrealizedPL, CommissionOnOpen, OpenedBuyUnits, OpenedSellUnits
FROM [Hedge].[CustomerOpenPositions] WITH (NOLOCK)
ORDER BY OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [System Overview](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/14109638672/System+Overview) | Confluence | CustomerPL (unrealized) = Rate + Exposure data; stored in RealTime SQL DB (per Account/Unrealized Customer); this procedure computes the unrealized side of the hedge cost equation |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 10, 11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 caller analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetUnrealizedCustomersData | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetUnrealizedCustomersData.sql*
