# Trade.RolloutAboveDollarPrecisionForPositions

> Updates open real-stock positions for a specific instrument to replace the legacy "no stop-loss/take-profit" sentinel rates with new above-dollar precision sentinels by iterating each position through PositionEditStopLoss and PositionEditTakeProfit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentID, @OldPrecision, @NewNOSLPrecision - precision migration parameters |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When an instrument's pricing precision changes to "above dollar precision" (fewer decimal places), open positions with the old precision's sentinel "no SL/TP" rate must be updated to the new precision's sentinel. This procedure handles the **positions** side of that migration for `Trade.Position` (open positions view over `Trade.PositionTbl`).

Unlike the orders counterpart, positions cannot be bulk-updated directly because each stop-loss and take-profit change requires business logic validation (audit trail, notification of the BSL system, SL manual version tracking). Therefore this procedure uses two CURSORs and calls `Trade.PositionEditStopLoss` and `Trade.PositionEditTakeProfit` row-by-row.

The first CURSOR handles Buy positions (IsBuy=1) with no-SL sentinel in `StopRate`. The second CURSOR handles Sell positions (IsBuy=0) with no-TP sentinel in `LimitRate`. Only real stock (Leverage=1) non-copy-trade (MirrorID=0) positions are affected.

---

## 2. Business Logic

### 2.1 Sentinel Rate Identification and Replacement

**What**: Identifies positions using the old precision sentinel and routes each through the standard SL/TP edit procedures.

**Columns/Parameters Involved**: `Trade.PositionTbl.StopRate`, `Trade.PositionTbl.LimitRate`, `Trade.PositionTbl.Leverage`, `Trade.PositionTbl.MirrorID`, `Trade.PositionTbl.IsBuy`

**Rules**:
- @OnePip = 1/10^@OldPrecision = old no-SL sentinel
- @NoStopRate = 1/10^@NewNOSLPrecision = new no-SL sentinel
- Buy positions cursor: WHERE StopRate=@OnePip AND MirrorID=0 AND Leverage=1 AND IsBuy=1
- Sell positions cursor: WHERE LimitRate=@OnePip AND MirrorID=0 AND Leverage=1 AND IsBuy=0
- Each BUY position: EXEC Trade.PositionEditStopLoss with @IsInitiatedByUser=0 (system update)
- Each SELL position: EXEC Trade.PositionEditTakeProfit with @IsInitiatedByUser=0
- Per-position TRY/CATCH: errors captured in #Errors, processing continues

### 2.2 Position Selection Criteria

**What**: Only real stock non-copy positions with sentinel rates are eligible.

**Rules**:
- Leverage=1: real stock positions only (non-leveraged = actual share ownership)
- MirrorID=0: direct (non-copy-trade) positions only - copy positions inherit from tree
- IsBuy=1 (SL cursor) or IsBuy=0 (TP cursor): separate handling by direction
- StopRate/@LimitRate must EXACTLY equal @OnePip - positions with custom SL/TP are untouched

**Diagram**:
```
CURSOR 1 (Buy, No-SL):
  Trade.Position WHERE InstrumentID=X, StopRate=@OnePip,
                       MirrorID=0, Leverage=1, IsBuy=1
  -> For each PositionID:
       EXEC Trade.PositionEditStopLoss(@StopRate=@NoStopRate, @IsInitiatedByUser=0)

CURSOR 2 (Sell, No-TP):
  Trade.Position WHERE InstrumentID=X, LimitRate=@OnePip,
                       MirrorID=0, Leverage=1, IsBuy=0
  -> For each PositionID:
       EXEC Trade.PositionEditTakeProfit(@LimitRate=@NoStopRate, @IsInitiatedByUser=0)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument being migrated. All open real-stock positions for this instrument with the old no-SL/TP sentinel are processed. |
| 2 | @OldPrecision | INT | NO | - | CODE-BACKED | The current decimal precision of the instrument. Determines the old sentinel rate: 1/10^OldPrecision. Example: 4 -> old sentinel = 0.0001. |
| 3 | @NewNOSLPrecision | INT | NO | - | CODE-BACKED | The new decimal precision for the no-SL/TP sentinel. Determines the replacement rate: 1/10^NewNOSLPrecision. Example: 2 -> new sentinel = 0.01. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CURSOR 1 SELECT | Trade.Position | Lookup | Reads open buy positions with old sentinel SL rate |
| CURSOR 2 SELECT | Trade.Position | Lookup | Reads open sell positions with old sentinel TP rate |
| EXEC | Trade.PositionEditStopLoss | Callee | Applies new sentinel SL rate per position (includes BSL notification, audit) |
| EXEC | Trade.PositionEditTakeProfit | Callee | Applies new sentinel TP rate per position |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RolloutAboveDollarPrecision | EXEC call | Caller | Orchestrator for precision rollout |
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | EXEC call | Caller | Fix variant with hardcoded OldPrecision=2 |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloutAboveDollarPrecisionForPositions (procedure)
|- Trade.Position (view - open positions, cursor source)
|- Trade.PositionEditStopLoss (procedure - applies SL update)
|- Trade.PositionEditTakeProfit (procedure - applies TP update)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | Source for two CURSORs - open buy positions (SL sentinel) and sell positions (TP sentinel) |
| Trade.PositionEditStopLoss | Procedure | Applies the SL rate change per Buy position with @IsInitiatedByUser=0 |
| Trade.PositionEditTakeProfit | Procedure | Applies the TP rate change per Sell position with @IsInitiatedByUser=0 |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloutAboveDollarPrecision | Procedure | Calls this as first step per instrument in precision rollout |
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | Procedure | Fix variant caller |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Exact match | Logic | Only positions where rate exactly equals @OnePip sentinel are processed |
| Per-position error | Logic | Inner TRY/CATCH per cursor row - individual position failures captured in #Errors |
| Row-by-row | Logic | Cursor-based processing required because PositionEditStopLoss/TakeProfit apply audit and business logic |

---

## 8. Sample Queries

### 8.1 Migrate SL/TP sentinels in open positions for an instrument

```sql
EXEC Trade.RolloutAboveDollarPrecisionForPositions
    @InstrumentID = 1234,
    @OldPrecision = 4,
    @NewNOSLPrecision = 2
```

### 8.2 Preview Buy positions with old sentinel stop rate

```sql
DECLARE @OnePip DECIMAL(8,6) = 1.00 / POWER(10, 4)  -- OldPrecision=4

SELECT PositionID, CID, InstrumentID, StopRate, Amount, Leverage, MirrorID
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID = 1234
    AND StopRate = @OnePip
    AND MirrorID = 0
    AND Leverage = 1
    AND IsBuy = 1
```

### 8.3 Count remaining old sentinel rates after migration

```sql
DECLARE @OnePip DECIMAL(8,6) = 0.0001  -- 1/10^4
SELECT
    SUM(CASE WHEN IsBuy=1 AND StopRate=@OnePip THEN 1 ELSE 0 END) AS BuyWithOldSL,
    SUM(CASE WHEN IsBuy=0 AND LimitRate=@OnePip THEN 1 ELSE 0 END) AS SellWithOldTP
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID = 1234 AND Leverage = 1 AND MirrorID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloutAboveDollarPrecisionForPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloutAboveDollarPrecisionForPositions.sql*
