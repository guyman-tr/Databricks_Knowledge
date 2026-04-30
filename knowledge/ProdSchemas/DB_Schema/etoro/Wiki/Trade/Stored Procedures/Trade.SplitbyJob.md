# Trade.SplitbyJob

> Batched stock-split processor that applies a pre-computed split ratio to open positions for a single NtilePositionID partition, updating unit counts and price rates in Trade.PositionTbl and Trade.PositionTreeInfo, with separate logic for US vs non-US customers.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @NtilePositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When a publicly traded stock undergoes a split (e.g., 2-for-1), every open position holding that stock must have its unit counts multiplied by the split ratio and its price rates divided by the same ratio. This procedure is one of 11 parallel workers (NtilePositionID 1-10) that process different partition slices of the affected open positions. A 12th special value (NtilePositionID=11) is reserved for single-position debug/dry-run mode (BatchSize=1).

The caller (typically a SQL Agent job) prepopulates `Trade.PositionToSplitByJob` with the positions to process and their computed ratios. This procedure reads that queue, applies the split math to `Trade.PositionTbl` in batches of 2000, updates `Trade.PositionTreeInfo` stop/limit rates for root positions, records each processed position into `History.PositionSplit` (for idempotency), and marks each batch as done. US customer positions follow a stricter 5-decimal truncation and receive an additional `UnitsToAdd` correction from APEX-computed values in `Trade.UsUnitsToAddByPositionToSplitByJob`.

The real vs demo environment distinction changes how `Trade.PositionTreeInfo` is joined: real positions join by `TreeID`, demo positions use the negative of the PositionID as the TreeID (a platform convention for demo position trees).

---

## 2. Business Logic

### 2.1 Partition-Based Parallel Processing

**What**: The 11-partition design allows the caller to run up to 10 simultaneous instances of this procedure, each handling a non-overlapping slice of affected positions.

**Columns/Parameters Involved**: `@NtilePositionID`, `Trade.PositionToSplitByJob.NtilePositionID`

**Rules**:
- NtilePositionID 1-10 = production partitions, BatchSize = 2000
- NtilePositionID = 11 = single-position debug mode, BatchSize = 1; errors write diagnostic rows to `Trade.DebugSplitwithError`

### 2.2 Idempotency via History.PositionSplit

**What**: The procedure skips any position that already has a record in `History.PositionSplit` for the current SplitID.

**Columns/Parameters Involved**: `History.PositionSplit.PositionID`, `History.PositionSplit.SplitID`

**Rules**:
- LEFT JOIN to History.PositionSplit with AND PS.SplitID = @SplitID
- WHERE PS.PositionID IS NULL -> only positions NOT yet split this round
- If the procedure is restarted after a partial failure, already-processed positions are automatically skipped
- OUTPUT DELETED.PositionID INTO History.PositionSplit atomically records the split within the same transaction

### 2.3 Unit Count Scaling

**What**: Multiplies unit quantities by AmountRatio, with a precision floor to avoid zero-unit positions.

**Columns/Parameters Involved**: `AmountInUnitsDecimal`, `LotCountDecimal`, `InitialUnits`, `InitialLotCount`, `@AmountRatio`

**Rules**:
- Non-US: IIF(value * @AmountRatio > @UnitsPrecision, value * @AmountRatio, @UnitsPrecision) where @UnitsPrecision = 0.000001
- US: ROUND(IIF(value * @AmountRatio > @UsUnitsPrecision, value * @AmountRatio, @UsUnitsPrecision), 5, 1) + UTA.UnitsToAdd where @UsUnitsPrecision = 0.00001
  - The ROUND(..., 5, 1) applies truncation (not rounding) to match APEX precision requirements
  - UnitsToAdd corrects for fractional share differences computed by the APEX clearing system
- InitialUnits/InitialLotCount use ISNULL(InitialX, CurrentX) to handle NULL baselines

### 2.4 Price Rate Scaling

**What**: Multiplies all stored price rates by PriceRatio and rounds to the instrument's precision.

**Columns/Parameters Involved**: `InitForexRate`, `SpreadedPipBid`, `SpreadedPipAsk`, `OrderPriceRate`, `MarketPriceRate`, `LastOpPriceRate`, `@PriceRatio`, `@Precision`

**Rules**:
- ROUND(rate * @PriceRatio, @Precision) for most rates
- TRY_CAST to decimal(16,8) for SpreadedPipBid/SpreadedPipAsk with fallback to original on overflow

### 2.5 PositionTreeInfo Stop/Limit Rate Scaling

**What**: Scales stop-loss and take-profit rates on the root position tree entries.

**Columns/Parameters Involved**: `Trade.PositionTreeInfo.StopRate`, `LimitRate`, `NextThresHold`, `@OnePip`

**Rules**:
- Only updates rows where ParentPositionID = 0 (root positions - children inherit from root)
- IIF(@OnePip = rate, rate, RoundByPrecisions(...)) - if the rate equals one pip (sentinel for "no stop/limit set"), leave it unchanged
- Uses `Trade.RoundByPrecisions` function with Precision + AboveDollarPrecision + IsBuy direction for correct rounding
- Also increments SLManualVer + 1 and sets SLManualVerTimestamp = GETUTCDATE() (version tracking for optimistic concurrency)

### 2.6 Real vs Demo TreeID Join Pattern

**What**: The TreeID key in Trade.PositionTreeInfo differs between real and demo positions.

**Columns/Parameters Involved**: `Trade.PositionTreeInfo.TreeID`, `#PositionToSplitByJob.TreeID`

**Rules**:
- Real environment (@IsReal=1): JOIN ON PTS.TreeID = TPTI.TreeID and abs(PTS.TreeID%50) = TPTI.PartitionCol
- Demo environment (@IsReal=0): JOIN ON TPTI.TreeID = 0-PTS.PositionID and abs(PTS.TreeID%50) = TPTI.PartitionCol
  - Demo trees are keyed by the negative of the PositionID (platform convention for demo leaf-as-root positions)
  - Demo update does NOT filter by ParentPositionID = 0 (demo positions are their own roots)

### 2.7 Error Handling and Debug Capture

**What**: Errors are caught per batch; the batch is rolled back and marked failed. Debug mode (NtilePositionID=11) additionally captures what the values would have been.

**Columns/Parameters Involved**: `Trade.PositionToSplitByJob.PositionWasSplit`, `Trade.PositionToSplitByJob.ErrorMessage`

**Rules**:
- On success: PositionWasSplit = 1, ErrorMessage = ''
- On error (regular partition): PositionWasSplit = -1, ErrorMessage = error message + stepID
- On error (debug partition NtilePositionID=11): PositionWasSplit = -2, + INSERT into Trade.DebugSplitwithError with computed (pre-error) column values
- @stepID tracks which step failed: 1 = PositionTbl update, 2 = PositionTreeInfo update

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @NtilePositionID | int | NO | - | CODE-BACKED | Partition identifier (1-11). Determines which slice of Trade.PositionToSplitByJob to process. NtilePositionID=11 activates single-position debug mode (BatchSize=1) with error capture to Trade.DebugSplitwithError. |

**Runtime variables loaded from Trade.PositionToSplitByJob:**

| Variable | Source Column | Description |
|----------|--------------|-------------|
| @InstrumentID | InstrumentID | The stock instrument being split. Used to filter PositionTbl. |
| @AmountRatio | AmountRatio | Multiplier for unit quantities (e.g., 2.0 for a 2-for-1 split). |
| @PriceRatio | PriceRatio | Multiplier for price rates (e.g., 0.5 for a 2-for-1 split). |
| @SplitID | SplitID | Identifier for this split event. Used for idempotency check in History.PositionSplit. |
| @OnePip | OnePip | One pip value for the instrument. Used as sentinel: if StopRate/LimitRate equals OnePip, it means "no stop/limit" and should not be scaled. |
| @MinDate | MinDate | Cutoff datetime: only positions opened before this date are split. Positions opened after the split announcement are already at post-split prices. |

**Trade.PositionTbl columns updated:**

| Column | Update Expression | Description |
|--------|------------------|-------------|
| AmountInUnitsDecimal | IIF(val*AmountRatio > 0.000001, val*AmountRatio, 0.000001) | New unit count after split. Floored at 0.000001 to prevent zero positions. US: truncated to 5dp + UnitsToAdd. |
| LotCountDecimal | IIF(val*AmountRatio > 0.000001, val*AmountRatio, 0.000001) | Lot count scaled by split ratio. |
| InitialUnits | ISNULL(InitialUnits, AmountInUnitsDecimal) * AmountRatio | Initial units at position open (baseline for P&L calculation). |
| InitialLotCount | ISNULL(InitialLotCount, LotCountDecimal) * AmountRatio | Initial lot count at position open. |
| InitForexRate | ROUND(InitForexRate * PriceRatio, Precision) | Opening forex rate adjusted for split. |
| SpreadedPipBid | TRY_CAST(SpreadedPipBid * PriceRatio AS decimal(16,8)) | Bid spread pips at open, adjusted. TRY_CAST handles potential overflow gracefully. |
| SpreadedPipAsk | TRY_CAST(SpreadedPipAsk * PriceRatio AS decimal(16,8)) | Ask spread pips at open, adjusted. |
| OrderPriceRate | ROUND(OrderPriceRate * PriceRatio, Precision) | Order entry price adjusted. |
| MarketPriceRate | ROUND(MarketPriceRate * PriceRatio, Precision) | Market price at open adjusted. |
| LastOpPriceRate | ROUND(LastOpPriceRate * PriceRatio, Precision) | Last operation price adjusted. |

**Trade.PositionTreeInfo columns updated:**

| Column | Update Expression | Description |
|--------|------------------|-------------|
| LimitRate | IIF(OnePip=LimitRate, LimitRate, RoundByPrecisions(LimitRate*PriceRatio,...)) | Take-profit rate adjusted. Left unchanged if equals OnePip (sentinel for no take-profit). |
| StopRate | IIF(OnePip=StopRate, StopRate, RoundByPrecisions(StopRate*PriceRatio,...)) | Stop-loss rate adjusted. Left unchanged if equals OnePip (sentinel for no stop-loss). |
| NextThresHold | ROUND(NextThresHold * PriceRatio, Precision) | TSL (trailing stop loss) threshold adjusted. |
| SLManualVer | SLManualVer + 1 | Version counter incremented to signal SL change to consumers (optimistic concurrency). |
| SLManualVerTimestamp | GETUTCDATE() | Timestamp of this SL version change. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @NtilePositionID | Trade.PositionToSplitByJob | Reader + Writer | Reads job parameters and position list; marks PositionWasSplit on completion |
| @InstrumentID | Trade.ProviderToInstrument | Reader | Reads Precision + AboveDollarPrecision for rounding |
| FeatureID=22 | Maintenance.Feature | Reader | Reads IsReal flag to choose real vs demo PositionTreeInfo join pattern |
| PositionID | Trade.PositionTbl | Writer | Updates unit counts and price rates for all open positions of this instrument/partition |
| PositionID, SplitID | History.PositionSplit | Writer (OUTPUT INTO) | Records each successfully split position for idempotency |
| PositionID, IsUsCustomer | Trade.UsUnitsToAddByPositionToSplitByJob | Reader | Reads APEX-computed unit correction for US customers |
| TreeID | Trade.PositionTreeInfo | Writer | Updates stop/limit/threshold rates on root position trees |
| NtilePositionID=11 errors | Trade.DebugSplitwithError | Writer | Captures computed-but-not-applied values on debug mode errors |
| - | Trade.RoundByPrecisions | Function call | Rounding function for PositionTreeInfo rates |
| - | Trade.RoundByPrecisions_ForDebug | Function call | Rounding function used in debug error capture |

### 5.2 Referenced By (other objects point to this)

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent split job | External | Invoked once per partition (NtilePositionID 1-10) in parallel; NtilePositionID=11 used for pre-flight testing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SplitbyJob (procedure)
+-- Trade.PositionToSplitByJob (table) [read job queue + write status]
+-- Trade.ProviderToInstrument (table) [read Precision/AboveDollarPrecision]
+-- Maintenance.Feature (table) [read FeatureID=22 real/demo flag]
+-- Trade.PositionTbl (table) [write: unit counts + price rates]
+-- History.PositionSplit (table) [write: idempotency log via OUTPUT INTO]
+-- Trade.UsUnitsToAddByPositionToSplitByJob (table) [read: US units correction]
+-- Trade.PositionTreeInfo (table) [write: stop/limit/threshold rates]
+-- Trade.DebugSplitwithError (table) [write: debug error capture]
+-- Trade.RoundByPrecisions (function) [rate rounding]
+-- Trade.RoundByPrecisions_ForDebug (function) [debug rate rounding]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionToSplitByJob | Table | Reads job parameters and position list; marks results |
| Trade.ProviderToInstrument | Table | Reads instrument Precision and AboveDollarPrecision for ROUND() calls |
| Maintenance.Feature | Table | Reads FeatureID=22 to determine real vs demo environment |
| Trade.PositionTbl | Table | Target for unit count + price rate updates |
| History.PositionSplit | Table | Idempotency tracker - prevents double-splitting; receives OUTPUT INTO |
| Trade.UsUnitsToAddByPositionToSplitByJob | Table | Provides APEX-computed fractional share correction for US customers |
| Trade.PositionTreeInfo | Table | Target for stop-loss/take-profit/threshold rate updates |
| Trade.DebugSplitwithError | Table | Receives diagnostic rows on debug partition errors (NtilePositionID=11) |
| Trade.RoundByPrecisions | Function | Instrument-aware rounding for TreeInfo rates |
| Trade.RoundByPrecisions_ForDebug | Function | Same rounding logic used in debug error capture branch |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| SQL Agent: split job | External | Calls this SP once per partition for each stock split event |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

Temp table `#PositionToSplitByJob` creates:
- `UNIQUE CLUSTERED INDEX IX_ID` on `(ID, PositionID, PositionPartitionCol)`
- `NONCLUSTERED INDEX IX_PositionID` on `(PositionID)`
- `NONCLUSTERED INDEX IX_PositionPartitionCol` on `(PositionPartitionCol)`
- `NONCLUSTERED INDEX IX_IsUsCustomer` on `(IsUsCustomer)`

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BatchSize cap | Design | 2000 positions per transaction (1 for NtilePositionID=11) - prevents oversized transactions |
| Idempotency | Design | LEFT JOIN History.PositionSplit with PS.PositionID IS NULL prevents re-processing already-split positions |
| MinDate filter | Business | TPOS.InitDateTime < @MinDate - only splits positions opened before the split announcement date |
| StatusID=1 filter | Business | Only processes open positions; closed positions do not need split adjustment |
| ParentPositionID=0 | Business | PositionTreeInfo updates only target root positions (real env); children inherit via tree traversal |

---

## 8. Sample Queries

### 8.1 Execute split for partition 3

```sql
EXEC Trade.SplitbyJob @NtilePositionID = 3;
```

### 8.2 Debug single position (NtilePositionID=11)

```sql
-- First: ensure only the target position is in PositionToSplitByJob with NtilePositionID=11
-- Then run in debug mode (BatchSize=1, errors captured to DebugSplitwithError):
EXEC Trade.SplitbyJob @NtilePositionID = 11;

-- Check debug output:
SELECT * FROM Trade.DebugSplitwithError ORDER BY SplitID DESC;
```

### 8.3 Check split progress

```sql
SELECT NtilePositionID,
       COUNT(*) AS TotalPositions,
       SUM(CASE WHEN PositionWasSplit = 1 THEN 1 ELSE 0 END) AS Success,
       SUM(CASE WHEN PositionWasSplit = -1 THEN 1 ELSE 0 END) AS Failed,
       SUM(CASE WHEN PositionWasSplit IS NULL OR PositionWasSplit = 0 THEN 1 ELSE 0 END) AS Pending
FROM Trade.PositionToSplitByJob WITH (NOLOCK)
GROUP BY NtilePositionID
ORDER BY NtilePositionID;
```

### 8.4 Find failed batches and their errors

```sql
SELECT NtilePositionID, PositionID, PositionWasSplit, ErrorMessage
FROM Trade.PositionToSplitByJob WITH (NOLOCK)
WHERE PositionWasSplit IN (-1, -2)
ORDER BY NtilePositionID, ID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 35 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers found | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SplitbyJob | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SplitbyJob.sql*
