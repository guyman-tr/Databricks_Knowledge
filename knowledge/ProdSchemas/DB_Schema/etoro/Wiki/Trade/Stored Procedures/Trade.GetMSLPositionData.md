# Trade.GetMSLPositionData

> Returns open copy-trade position data (amounts, rates, settlement info) for a specific shard partition (MirrorID % @ModDivder = @ModResult), used by the Mirror Stop-Loss calculation engine to compute per-mirror PnL and compare against stop-loss thresholds.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ModDivder + @ModResult - selects a specific shard of active mirrors |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMSLPositionData` is the third of three MSL (Mirror Stop-Loss) data-feed procedures. It returns the position-level data needed for PnL calculation across all open copy positions in a specific shard: the position identifier, instrument, size (in units and dollars/cents), entry rates, direction, and settlement metadata.

The MSL calculation engine uses this data alongside `GetMSLMirrorData` (same shard) to compute each mirror's realized equity. For each position, the engine calculates unrealized PnL using the current instrument price (fetched for instruments returned by `GetMSLInstrumentsData`) and the `InitForexRate` and `InitConversionRate` from this procedure. If the sum of PnL across all positions causes the mirror's equity to drop below `MirrorSL`, the mirror is auto-closed.

Data flows: Called per-shard by the MSL engine, paired with `GetMSLMirrorData` (same @ModDivder + @ModResult) for the threshold comparison. `GetMSLInstrumentsData` (same @ModDivder) provides the instrument set for price fetching. Change history: FB 53719 (2019-03-13, Free Stocks) - added PnLVersion, InitConversionRate, SettlementTypeID, IsSettled columns to support fractional share settlement paths.

---

## 2. Business Logic

### 2.1 Mirror Shard Selection

**What**: Returns only positions belonging to mirrors in a specific shard.

**Columns/Parameters Involved**: `@ModDivder`, `@ModResult`, `pos.MirrorID`

**Rules**:
- `pos.MirrorID % @ModDivder = @ModResult`: Only positions whose mirror falls in this modulus bucket.
- `tm.IsActive = 1`: Only positions in active mirrors. Closed mirrors are excluded.
- `pos.ParentPositionID > 0`: Only copy-trade (child) positions. Manual positions have ParentPositionID=0 and are not part of any mirror.
- JOIN to `Trade.Mirror` on MirrorID validates mirror status; the position table itself is not filtered by IsActive.

### 2.2 Dual-Unit Amount Output

**What**: Position amount returned in both cents and dollars for MSL engine compatibility.

**Columns/Parameters Involved**: `Amount`, `AmountInDollars`

**Rules**:
- `pos.Amount * 100 AS Amount`: Position allocated amount in cents. Primary unit for MSL PnL calculation.
- `pos.Amount AS AmountInDollars`: Same amount in dollars. Informational/alternate path.
- Consistent with the cents convention used by `GetMSLMirrorData` (MirrorAmount, MirrorSLAmount).

### 2.3 PnL Calculation Inputs

**What**: The rate and unit fields provide the PnL calculation engine with all inputs needed to value each position at current market price.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `InitForexRate`, `IsBuy`, `InitConversionRate`, `PnLVersion`

**Rules**:
- `AmountInUnitsDecimal`: Position size in instrument units (e.g., shares or contract units). Used with current price to compute mark-to-market value.
- `InitForexRate`: Entry exchange rate. Needed to compute PnL in account currency.
- `IsBuy`: 1=long, 0=short. Direction determines sign of PnL.
- `InitConversionRate`: Rate used to convert position PnL to USD at time of open (added in FB 53719 for Free Stocks fractional share path).
- `PnLVersion`: Signals which PnL calculation path to use. Fractional share positions (PnLVersion=2) use a different formula than standard CFD positions.

### 2.4 Settlement Metadata

**What**: SettlementTypeID and IsSettled flag enable the MSL engine to differentiate positions that are fully settled.

**Columns/Parameters Involved**: `SettlementTypeID`, `IsSettled`

**Rules**:
- `SettlementTypeID`: Identifies how position PnL settles (e.g., cash, stock delivery). Added in FB 53719.
- `IsSettled`: 1 = position has been settled. Settled positions may have different equity contribution than open mark-to-market positions.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ModDivder | TINYINT | NO | - | CODE-BACKED | The total number of shards. Divisor in the modulus calculation (MirrorID % @ModDivder). Must match the value used in GetMSLMirrorData for the same processing cycle. |
| 2 | @ModResult | TINYINT | NO | - | CODE-BACKED | The shard number to return. Only positions in mirrors where MirrorID % @ModDivder = @ModResult are returned. Range: 0 to @ModDivder-1. |

**Output columns** (result set):

| # | Column | Description |
|---|--------|-------------|
| 1 | PositionID | The position identifier. Matches Trade.PositionTbl.PositionID. |
| 2 | InstrumentID | The instrument being traded. Used by MSL engine to look up current market price (fetched via GetMSLInstrumentsData instrument set). |
| 3 | AmountInUnitsDecimal | Position size in instrument units (e.g., shares, contract units). Used with current price to compute mark-to-market PnL. |
| 4 | InitForexRate | Entry exchange rate. Used in PnL calculation to convert instrument price move to account currency. |
| 5 | IsBuy | 1=long position, 0=short. Determines PnL sign when price moves. |
| 6 | MirrorID | The mirror this copy position belongs to. Used to aggregate PnL across all positions of the same mirror for MSL comparison. |
| 7 | Amount | Position allocated amount in CENTS (Amount * 100). Primary unit for MSL calculation consistency with GetMSLMirrorData. |
| 8 | AmountInDollars | Position allocated amount in dollars (Trade.PositionTbl.Amount). |
| 9 | PnLVersion | PnL calculation path selector. 2 = fractional share/Free Stocks path (uses InitConversionRate). Other values = standard CFD path. |
| 10 | InitConversionRate | USD conversion rate at position open (added for Free Stocks fractional share path, FB 53719). Used in PnLVersion=2 calculation. |
| 11 | SettlementTypeID | Settlement method identifier. Influences how position equity is counted in mirror MSL calculation. |
| 12 | IsSettled | 1 = position has been fully settled. 0 = mark-to-market open position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| pos.MirrorID | Trade.Position (view) | Primary read | Source of copy-trade positions (ParentPositionID>0). Position view applies additional filters vs raw PositionTbl. |
| tm.MirrorID | Trade.Mirror | JOIN filter | Filters to active mirrors only (IsActive=1). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMSLPositionData (procedure)
├── Trade.Position (view)
│   └── Trade.PositionTbl (table)
└── Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT PositionID, InstrumentID, AmountInUnitsDecimal, InitForexRate, IsBuy, MirrorID, Amount, PnLVersion, InitConversionRate, SettlementTypeID, IsSettled WHERE ParentPositionID>0 AND MirrorID%@ModDivder=@ModResult |
| Trade.Mirror | Table | INNER JOIN on MirrorID WHERE IsActive=1 - restricts to active mirrors only |

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

### 8.1 Get MSL position data for shard 3 of 10

```sql
EXEC Trade.GetMSLPositionData @ModDivder = 10, @ModResult = 3;
```

### 8.2 Full MSL data feed for shard 3 (all three procedures)

```sql
-- Step 1: Get instrument inventory for all shards
EXEC Trade.GetMSLInstrumentsData @ModDivder = 10;
-- (fetch current prices for those instruments from pricing service)

-- Step 2: Get mirror thresholds for shard 3
EXEC Trade.GetMSLMirrorData @ModDivder = 10, @ModResult = 3;

-- Step 3: Get position data for shard 3
EXEC Trade.GetMSLPositionData @ModDivder = 10, @ModResult = 3;

-- MSL engine: for each MirrorID in shard 3, sum position PnL and compare equity vs MirrorSLAmount
```

### 8.3 Equivalent direct query

```sql
SELECT pos.PositionID, pos.InstrumentID, pos.AmountInUnitsDecimal,
       pos.InitForexRate, pos.IsBuy, pos.MirrorID,
       pos.Amount * 100 AS Amount, pos.Amount AS AmountInDollars,
       pos.PnLVersion, pos.InitConversionRate, pos.SettlementTypeID, pos.IsSettled
FROM Trade.Position pos WITH (NOLOCK)
INNER JOIN Trade.Mirror tm WITH (NOLOCK) ON pos.MirrorID = tm.MirrorID
WHERE pos.ParentPositionID > 0
  AND pos.MirrorID % 10 = 3  -- shard 3 of 10
  AND tm.IsActive = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 9/10, Logic: 9/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMSLPositionData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMSLPositionData.sql*
