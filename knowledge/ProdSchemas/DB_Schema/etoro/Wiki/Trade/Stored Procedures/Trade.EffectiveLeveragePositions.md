# Trade.EffectiveLeveragePositions

> Calculates effective leverage for open positions on specified instruments and logs hedge server reassignment decisions based on volatility thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns result set of positions needing hedge server changes |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure implements the Effective Leverage System (ELS) - a risk management mechanism that dynamically reassigns positions between hedge servers based on their real-time effective leverage relative to instrument-specific volatility thresholds. When a position's effective leverage crosses a volatility boundary, the position is flagged for migration to a different hedge server that handles that leverage tier.

ELS exists because different hedge servers handle different risk profiles. High-leverage positions during volatile conditions require different hedging strategies than low-leverage ones. Without this system, all positions for an instrument would remain on their initially assigned hedge server regardless of changing market conditions and leverage dynamics.

The procedure is called with a comma-separated list of instrument IDs. It reads the latest volatility data for those instruments, joins with open positions (via `Trade.Position` view) and current prices (via `Trade.CurrencyPrice`), calculates each position's effective leverage, and compares it against the volatility threshold. Positions that are currently on the wrong hedge server (relative to their effective leverage) are logged to the ELS change log tables on the ElsAzure database (via synonyms) and returned as a result set. The companion procedure `Trade.EffectiveLeveragePositions_Job` handles the BCP-based transfer of these log records to the ELS Azure database.

---

## 2. Business Logic

### 2.1 Effective Leverage Calculation

**What**: Computes the real-time effective leverage of each position based on current market prices and position economics.

**Columns/Parameters Involved**: `UnitMargin`, `UnitMarginBid`, `UnitMarginAsk`, `AmountInUnitsDecimal`, `Amount`, `IsBuy`

**Rules**:
- CurrentRate = UnitMarginBid when IsBuy=1 (long), UnitMarginAsk when IsBuy=0 (short)
- CurrentAmount = (PnL per unit * AmountInUnitsDecimal) + Amount, where PnL per unit = (CurrentRate - UnitMargin) for longs, (UnitMargin - CurrentRate) for shorts
- EffectiveLeverage = (CurrentRate * AmountInUnitsDecimal) / MAX(CurrentAmount, 0.001) - the denominator floor of 0.001 prevents division by zero when equity is near zero
- Higher effective leverage means the position's equity has eroded relative to its notional value, indicating higher risk

**Diagram**:
```
Position Economics:
  NotionalValue = CurrentRate * AmountInUnitsDecimal
  Equity (CurrentAmount) = UnrealizedPnL + InitialAmount
  EffectiveLeverage = NotionalValue / MAX(Equity, 0.001)

Example (Long, IsBuy=1):
  UnitMargin (open price) = 100
  UnitMarginBid (current) = 95
  AmountInUnitsDecimal = 10
  Amount (initial investment) = 200
  CurrentAmount = (95 - 100) * 10 + 200 = 150
  EffectiveLeverage = (95 * 10) / 150 = 6.33
```

### 2.2 Hedge Server Reassignment Logic

**What**: Determines which positions need to move between hedge servers based on their effective leverage relative to the instrument's volatility threshold.

**Columns/Parameters Involved**: `EffectiveLeverage`, `VolatilityThreshold`, `HedgeServerID`, `HedgeServerIDOverVolatilityThreshold`, `HedgeServerIDBelowVolatilityThreshold`

**Rules**:
- Each instrument has a VolatilityThreshold and two designated hedge servers: one for positions with leverage ABOVE the threshold, one for BELOW
- A position needs reassignment when it is on the WRONG server for its current effective leverage:
  - If VolatilityThreshold > EffectiveLeverage AND position is currently on the OverVolatilityThreshold server -> move to BelowVolatilityThreshold server
  - If VolatilityThreshold < EffectiveLeverage AND position is currently on the BelowVolatilityThreshold server -> move to OverVolatilityThreshold server
- For tree-based positions (copy trading), the root position's destination hedge server is used as the ToRootHedgeServerID for child positions

**Diagram**:
```
VolatilityThreshold (e.g., 5.0)
       |
       v
 [Below]  |  [Over]
 Low EL   |  High EL
 Server A |  Server B
       |
Position EL crosses threshold -> reassign server
```

### 2.3 Batched Insert to ELS Change Log

**What**: Writes hedge server change records in batches to the ELS Azure database via synonyms.

**Columns/Parameters Involved**: `@SummaryID`, `@Maxid`, `@Minid`, `@delta`

**Rules**:
- A summary record is created first in ELSPositionsHedgeServerChangeSummaryLog with a StartTime
- Position change records are inserted in batches of 5,000 rows (controlled by @delta) to ELSPositionsHedgeServerChangeLog
- After all batches complete, the summary record's EndTime is updated
- Both log tables are on the ElsAzure database, accessed via dbo synonyms

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @instruments | varchar(MAX) | NO | - | CODE-BACKED | Comma-separated list of InstrumentIDs to evaluate. Parsed using STRING_SPLIT into a temp table for JOIN filtering. Each value must be a valid integer InstrumentID present in Trade.Position and Trade.CurrencyPrice. |

**Output Columns (returned result set from #UnionPositions):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | bigint | NO | - | CODE-BACKED | Row number assigned via ROW_NUMBER() OVER (ORDER BY (SELECT NULL)). Sequential identifier for batching insert operations. |
| 2 | ToHedgeServerID | int | NO | - | CODE-BACKED | Target hedge server for reassignment. Set to HedgeServerIDBelowVolatilityThreshold when VolatilityThreshold > EffectiveLeverage (position is less leveraged than threshold), or HedgeServerIDOverVolatilityThreshold when VolatilityThreshold < EffectiveLeverage (position is more leveraged). |
| 3 | TreeID | int | NO | - | CODE-BACKED | Copy-trading tree identifier from Trade.Position. Groups parent and child copied positions. Used to determine root position's destination for child reassignment. |
| 4 | PositionID | bigint | NO | - | CODE-BACKED | Unique position identifier from Trade.Position. Primary key of the position being evaluated for hedge server reassignment. |
| 5 | HedgeServerID | int | NO | - | CODE-BACKED | Current hedge server the position is assigned to. Becomes the FromHedgeServerID in the change log. |
| 6 | RootHedgeServerID | int | YES | - | CODE-BACKED | Root hedge server for copy-trading tree positions. COALESCE'd to 0 when NULL (non-tree positions). |
| 7 | InstrumentID | int | NO | - | CODE-BACKED | Financial instrument identifier. Used as the JOIN key across all source tables (Position, CurrencyPrice, InstrumentVolatiliy, VolatilityThresholdHedgeServer). |
| 8 | ParentPositionID | bigint | NO | - | CODE-BACKED | Parent position in copy-trading hierarchy. 0 indicates root/independent position. Used to identify tree heads in the self-join for ToRootHedgeServerID calculation. |
| 9 | Leverage | int | NO | - | CODE-BACKED | Position's configured leverage multiplier from Trade.Position. |
| 10 | Amount | money | NO | - | CODE-BACKED | Initial invested amount (equity) of the position. Used in CurrentAmount (equity) calculation. |
| 11 | AmountInUnitsDecimal | decimal | NO | - | CODE-BACKED | Position size in instrument units. Multiplied by price difference to compute PnL; multiplied by CurrentRate for notional value. |
| 12 | InitForexRate | float | YES | - | CODE-BACKED | Initial forex conversion rate at position open. Selected from Trade.Position but not used in effective leverage calculation. |
| 13 | IsBuy | bit | NO | - | CODE-BACKED | Trade direction: 1 = Long (uses Bid price as CurrentRate), 0 = Short (uses Ask price as CurrentRate). Determines PnL sign convention in effective leverage formula. |
| 14 | UnitMargin | decimal | NO | - | CODE-BACKED | Position's opening price (unit margin). The base price for PnL calculation. (CurrentRate - UnitMargin) for longs, (UnitMargin - CurrentRate) for shorts. |
| 15 | UnitMarginBid | decimal | NO | - | CODE-BACKED | Current bid price for the instrument from Trade.CurrencyPrice. Used as CurrentRate for long positions (IsBuy=1). |
| 16 | UnitMarginAsk | decimal | NO | - | CODE-BACKED | Current ask price for the instrument from Trade.CurrencyPrice. Used as CurrentRate for short positions (IsBuy=0). |
| 17 | IsComputeForHedge | bit | YES | - | CODE-BACKED | Flag from Trade.Position indicating whether the position should be included in hedge exposure calculations. Selected but not used in the effective leverage logic itself. |
| 18 | CurrentRate | decimal | NO | - | CODE-BACKED | Computed: `CASE WHEN IsBuy=1 THEN UnitMarginBid ELSE UnitMarginAsk END`. The current market price relevant to this position's direction. |
| 19 | CurrentAmount | money | NO | - | CODE-BACKED | Computed: position equity = (PnL per unit * AmountInUnitsDecimal) + Amount. Represents the position's current total value including unrealized PnL. |
| 20 | effectiveLeverage | decimal | NO | - | CODE-BACKED | Computed: (CurrentRate * AmountInUnitsDecimal) / MAX(CurrentAmount, 0.001). The ratio of notional exposure to equity. Higher values indicate higher risk; compared against VolatilityThreshold to determine hedge server assignment. |
| 21 | VolatilityThreshold | numeric(18,10) | NO | - | CODE-BACKED | Instrument's volatility threshold from the most recent InstrumentVolatiliy record. The cutoff point for hedge server assignment: positions with effectiveLeverage above this go to the "Over" server, below to the "Below" server. |
| 22 | HedgeServerIDBelowVolatilityThreshold | int | NO | - | CODE-BACKED | Target hedge server for positions whose effective leverage is BELOW the volatility threshold. From Hedge.VolatilityThresholdHedgeServer. |
| 23 | HedgeServerIDOverVolatilityThreshold | int | NO | - | CODE-BACKED | Target hedge server for positions whose effective leverage is OVER the volatility threshold. From Hedge.VolatilityThresholdHedgeServer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @instruments -> InstrumentID | Trade.Position (view) | JOIN | Reads open position data for specified instruments |
| InstrumentID | Trade.CurrencyPrice | JOIN | Reads current bid/ask prices per instrument |
| InstrumentID | Hedge.VolatilityThresholdHedgeServer | JOIN | Reads volatility threshold and designated hedge servers per instrument |
| InstrumentID | InstrumentVolatiliy (cross-DB, via PriceLog) | JOIN | Reads latest volatility data per instrument |
| INSERT | dbo.ELSPositionsHedgeServerChangeLog (synonym -> ElsAzure) | WRITER | Logs each position's hedge server change in batches |
| INSERT/UPDATE | dbo.ELSPositionsHedgeServerChangeSummaryLog (synonym -> ElsAzure) | WRITER | Creates and completes summary records for each ELS run |
| effectiveLeverage calc | dbo.fnMax | Function Call | Scalar function returning the greater of two decimals; used as denominator floor to prevent division by zero |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.EffectiveLeveragePositions_Job | Related procedure | Companion | Transfers ELS change log records from DBA staging to ElsAzure via BCP export; processes the data this procedure writes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.EffectiveLeveragePositions (procedure)
+-- Trade.Position (view)
+-- Trade.CurrencyPrice (table)
+-- Hedge.VolatilityThresholdHedgeServer (table)
+-- InstrumentVolatiliy (cross-DB table, PriceLog/Price)
+-- dbo.ELSPositionsHedgeServerChangeLog (synonym -> ElsAzure)
+-- dbo.ELSPositionsHedgeServerChangeSummaryLog (synonym -> ElsAzure)
+-- dbo.fnMax (function)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | JOINed on InstrumentID to read open position data (PositionID, TreeID, HedgeServerID, etc.) |
| Trade.CurrencyPrice | Table | JOINed on InstrumentID to read current bid/ask prices |
| Hedge.VolatilityThresholdHedgeServer | Table | JOINed on InstrumentID to read volatility threshold and designated hedge servers |
| InstrumentVolatiliy | Table (cross-DB) | JOINed on InstrumentID for latest volatility data; originally from PriceLog.Hedge.InstrumentVolatiliy |
| dbo.ELSPositionsHedgeServerChangeLog | Synonym | INSERT target for position hedge server change records (points to ElsAzure.Els.Trade.ELSPositionsHedgeServerChangeLog) |
| dbo.ELSPositionsHedgeServerChangeSummaryLog | Synonym | INSERT/UPDATE target for operation summary records (points to ElsAzure.Els.Trade.ELSPositionsHedgeServerChangeSummaryLog) |
| dbo.fnMax | Scalar Function | Called in effective leverage denominator to prevent division by zero: MAX(CurrentAmount, 0.001) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.EffectiveLeveragePositions_Job | Stored Procedure | Companion procedure that transfers the ELS change log records to ElsAzure via BCP; depends on the data written by this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp table indexes created at runtime:
- `#instruments`: PRIMARY KEY CLUSTERED on InstrumentID
- `#InstrumentVolatiliy`: CLUSTERED INDEX `cix` on InstrumentID

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Run ELS Check for Specific Instruments

```sql
EXEC Trade.EffectiveLeveragePositions @instruments = '1,2,3,4,5'
```

### 8.2 View Recent ELS Change Log Entries

```sql
SELECT TOP 100
       sl.ID AS SummaryID,
       sl.StartTime,
       sl.EndTime,
       sl.Comments,
       cl.PositionID,
       cl.FromHedgeServerID,
       cl.ToHedgeServerID,
       cl.EffectiveLeverage,
       cl.VolatilityThreshold
  FROM ELSPositionsHedgeServerChangeSummaryLog sl WITH (NOLOCK)
  JOIN ELSPositionsHedgeServerChangeLog cl WITH (NOLOCK)
    ON sl.ID = cl.OperationSummaryID
 ORDER BY sl.StartTime DESC
```

### 8.3 Check Volatility Threshold Configuration for Instruments

```sql
SELECT vt.InstrumentID,
       vt.HedgeServerIDOverVolatilityThreshold,
       vt.HedgeServerIDBelowVolatilityThreshold,
       iv.VolatilityThreshold,
       iv.VolatilityDate,
       iv.Volatility
  FROM Hedge.VolatilityThresholdHedgeServer vt WITH (NOLOCK)
  JOIN (SELECT InstrumentID,
               VolatilityDate,
               Volatility,
               VolatilityThreshold,
               ROW_NUMBER() OVER (PARTITION BY InstrumentID ORDER BY VolatilityDate DESC) AS rn
          FROM InstrumentVolatiliy WITH (NOLOCK)
       ) iv ON vt.InstrumentID = iv.InstrumentID AND iv.rn = 1
 ORDER BY vt.InstrumentID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 23 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.EffectiveLeveragePositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.EffectiveLeveragePositions.sql*
