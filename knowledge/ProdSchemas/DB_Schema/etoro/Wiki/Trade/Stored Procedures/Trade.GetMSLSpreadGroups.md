# Trade.GetMSLSpreadGroups

> Returns current spread group pricing data (bid, ask, pip difference, and markup) for all instruments in ProviderID=1, used by the Mirror Stop-Loss calculation engine to obtain current instrument prices for PnL valuation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - always returns ProviderID=1 spread data |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMSLSpreadGroups` returns the current spread group pricing for all instruments under the primary provider (ProviderID=1). It provides the MSL (Mirror Stop-Loss) calculation engine with the current bid/ask prices and markup (spread percentage adjusted for instrument precision) needed to mark copy positions to market for PnL calculation.

The MSL engine uses the instrument list from `GetMSLInstrumentsData`, fetches prices from this procedure, and then computes unrealized PnL for each position using data from `GetMSLPositionData`. The `Markup` column (spread percentage normalized by instrument decimal precision) quantifies the cost of the spread for each instrument.

ProviderID=1 is the default/primary price provider. This procedure is not sharded - it returns all instruments at once, unlike the position/mirror procedures which use `@ModDivder`/`@ModResult` sharding.

Data flows: Called once per MSL processing cycle (not per shard) to build the instrument price table. The price data is then used across all shards when computing position PnL.

---

## 2. Business Logic

### 2.1 Primary Provider Pricing (ProviderID=1)

**What**: Restricts to the default price provider.

**Columns/Parameters Involved**: `ProviderID`, `TSG.ProviderID`

**Rules**:
- `WHERE TSG.ProviderID = 1`: Only returns pricing for the primary/default provider.
- ProviderID=1 is the main market data provider used across the trading engine.
- The JOIN to `Trade.ProviderToInstrument` is on both ProviderID and InstrumentID, ensuring the precision metadata matches the same provider.

### 2.2 Spread Components

**What**: Returns bid, ask, pip difference, and markup for each instrument/spread group combination.

**Columns/Parameters Involved**: `Bid`, `Ask`, `PipDiff`, `Markup`

**Rules**:
- `ISNULL(TSG.Bid, 0) AS Bid`: Current bid price; NULL replaced with 0 for instruments with no quote.
- `ISNULL(TSG.Ask, 0) AS Ask`: Current ask price; NULL replaced with 0.
- `ABS(TSG.Bid) + ABS(TSG.Ask) AS PipDiff`: Total pip spread width. Absolute values handle instruments where bid or ask can be negative (e.g., oil spreads near zero). Used to assess bid-ask spread cost.
- `CONVERT(DECIMAL(16,8), ISNULL(SpreadPct, 0)) / POWER(10, ISNULL(TPI.Precision, 0)) AS Markup`: Spread percentage normalized by instrument's decimal precision. Converts the raw SpreadPct integer into a correctly-scaled decimal spread fraction for PnL cost calculation.

### 2.3 Markup Precision Scaling

**What**: The Markup formula adjusts SpreadPct by instrument precision to produce a correctly-scaled spread value.

**Columns/Parameters Involved**: `SpreadPct`, `TPI.Precision`, `Markup`

**Rules**:
- `Trade.ProviderToInstrument.Precision`: The number of decimal places for this instrument's pricing (e.g., 4 for EURUSD, 2 for AAPL).
- `SpreadPct / POWER(10, Precision)`: If SpreadPct=300 and Precision=4, Markup=0.03 (3 basis points). This normalization allows uniform PnL calculations regardless of instrument scale.
- `ISNULL(SpreadPct, 0)` and `ISNULL(TPI.Precision, 0)`: Safe defaults when spread or precision metadata is missing.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | SpreadGroupID | The spread group identifier. Multiple instruments may share a spread group; each instrument-spread group pair is a distinct row. |
| 2 | InstrumentID | The instrument identifier. Joinable with GetMSLInstrumentsData results to map current price to each open position's instrument. |
| 3 | Bid | Current bid price from Trade.GetSpreadGroup. ISNULL(..., 0) - 0 when no active quote. |
| 4 | Ask | Current ask price from Trade.GetSpreadGroup. ISNULL(..., 0) - 0 when no active quote. |
| 5 | PipDiff | ABS(Bid) + ABS(Ask) - total pip spread width. Represents bid-ask spread cost in raw price units. |
| 6 | Markup | Spread percentage (SpreadPct) divided by 10^Precision. Precision-normalized spread fraction used by MSL engine in PnL cost calculations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TSG.SpreadGroupID, TSG.InstrumentID | Trade.GetSpreadGroup | Primary read | Source of current bid/ask spread data; filtered to ProviderID=1. |
| TPI.Precision, TPI.SpreadPct | Trade.ProviderToInstrument | JOIN | Provides instrument precision and spread percentage for Markup calculation. Joined on ProviderID + InstrumentID. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMSLSpreadGroups (procedure)
├── Trade.GetSpreadGroup (view/table)
└── Trade.ProviderToInstrument (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetSpreadGroup | View/Table | SELECT SpreadGroupID, InstrumentID, Bid, Ask, ProviderID WHERE ProviderID=1 |
| Trade.ProviderToInstrument | Table | JOIN on ProviderID+InstrumentID to get SpreadPct and Precision for Markup calculation |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get all MSL spread group data

```sql
EXEC Trade.GetMSLSpreadGroups;
```

### 8.2 Equivalent direct query

```sql
SELECT TSG.SpreadGroupID,
       TSG.InstrumentID,
       ISNULL(TSG.Bid, 0) AS Bid,
       ISNULL(TSG.Ask, 0) AS Ask,
       ABS(TSG.Bid) + ABS(TSG.Ask) AS PipDiff,
       CONVERT(DECIMAL(16,8), ISNULL(SpreadPct, 0)) / POWER(10, ISNULL(TPI.Precision, 0)) AS Markup
FROM Trade.GetSpreadGroup TSG WITH (NOLOCK)
JOIN Trade.ProviderToInstrument TPI WITH (NOLOCK)
  ON TPI.ProviderID = TSG.ProviderID
  AND TPI.InstrumentID = TSG.InstrumentID
WHERE TSG.ProviderID = 1;
```

### 8.3 Find instruments with widest spreads

```sql
SELECT TOP 20 InstrumentID, PipDiff, Markup
FROM (
    EXEC Trade.GetMSLSpreadGroups
) AS sg
ORDER BY PipDiff DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMSLSpreadGroups | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMSLSpreadGroups.sql*
