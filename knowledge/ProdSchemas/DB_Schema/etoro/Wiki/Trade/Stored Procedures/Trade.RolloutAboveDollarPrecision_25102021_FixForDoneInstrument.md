# Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument

> Fix variant of RolloutAboveDollarPrecision created on 2021-10-25, with hardcoded @OldPrecision=2 and the "already migrated" guard and ProviderToInstrument precision update steps both commented out, enabling re-processing of instruments whose precision was already set but whose positions/orders still had old sentinel rates.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentIDs VARCHAR(MAX) - comma-separated list of instruments to re-process |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is a **one-time fix procedure** created on 25 October 2021 to handle instruments that had already been migrated to the new precision at the `Trade.ProviderToInstrument` level, but whose open positions and/or pending orders still contained the old sentinel rates (due to a partial run or bug in the original migration).

The key differences from the main `Trade.RolloutAboveDollarPrecision`:
1. **@OldPrecision is hardcoded to 2** (not read from ProviderToInstrument) - these are instruments already at precision 2, being re-processed with OldPrecision=2 to catch remaining old sentinel rates from a prior precision level
2. **The "already migrated" guard is commented out** - allows processing instruments that are already at @Precision in ProviderToInstrument
3. **The ProviderToInstrument UPDATE is commented out** - does NOT update Precision or AboveDollarPrecision (they were already correct)

By skipping the precision update and the guard check, this procedure **only re-runs the position and order sentinel cleanup** without touching the precision configuration columns. This makes it safe to run on instruments that are already at the correct precision.

The name suffix `_25102021` (2021-10-25) indicates this was created as a one-time fix for a specific incident on that date and was retained for potential re-use.

---

## 2. Business Logic

### 2.1 Instrument List Parsing (Same as Main Proc)

**What**: Converts the CSV input into a processable temp table.

**Rules**:
- `SELECT [value] AS InstrumentID INTO #Instruments FROM STRING_SPLIT(@InstrumentIDs, ',')`
- Identical to main proc

### 2.2 Hardcoded OldPrecision=2

**What**: Skips the dynamic precision lookup; assumes all instruments were at precision 2.

**Rules**:
- `SET @OldPrecision = 2` (hardcoded)
- The `SELECT @OldPrecision FROM ProviderToInstrument` is commented out
- The already-migrated check is commented out
- Old sentinel = `1/10^2 = 0.01`

### 2.3 Position and Order Sentinel Re-migration

**What**: Re-runs the sentinel rate cleanup for positions and orders.

**Rules**:
- EXEC RolloutAboveDollarPrecisionForPositions @InstrumentID, 2 (hardcoded), @Precision
- EXEC RolloutAboveDollarPrecisionForOrders @InstrumentID, 2 (hardcoded), @Precision
- Functionally identical to main proc but with OldPrecision always = 2

### 2.4 No ProviderToInstrument Update

**What**: Does NOT update precision columns - they are already correct.

**Rules**:
- `UPDATE Trade.ProviderToInstrument SET Precision=... WHERE InstrumentID=...` is commented out
- This is the defining difference: this proc only fixes data, not configuration

**Comparison with main proc**:

| Feature | Main Proc | Fix Variant |
|---------|-----------|-------------|
| @OldPrecision source | ProviderToInstrument.Precision | Hardcoded = 2 |
| Already-migrated guard | YES (RAISERROR) | Disabled (commented) |
| Updates ProviderToInstrument | YES | NO (commented out) |
| Position/Order cleanup | YES | YES (same) |
| Intended use | First-time migration | Re-run after partial migration |

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentIDs | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of InstrumentIDs to re-process. These should be instruments that were already migrated at the configuration level but still have old sentinel rates (0.01) in positions/orders. |
| 2 | @Precision | DECIMAL(16,8) | NO | - | CODE-BACKED | The new precision (passed to sub-procedures as @NewNOSLPrecision). For instruments originally at precision 2 being re-processed, this would be the target new precision. |
| 3 | @AboveDollarPrecision | DECIMAL(16,8) | NO | - | CODE-BACKED | Accepted as parameter for signature compatibility with main proc; NOT used (the ProviderToInstrument update is commented out). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Position re-migration | Trade.RolloutAboveDollarPrecisionForPositions | Callee | Re-runs sentinel SL/TP cleanup for open positions with OldPrecision=2 |
| Order re-migration | Trade.RolloutAboveDollarPrecisionForOrders | Callee | Re-runs sentinel SL/TP cleanup for pending orders with OldPrecision=2 |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - one-time fix procedure, called ad-hoc.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument (procedure - fix variant)
|- Trade.RolloutAboveDollarPrecisionForPositions (procedure - position sentinel re-cleanup)
|- Trade.RolloutAboveDollarPrecisionForOrders (procedure - order sentinel re-cleanup)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloutAboveDollarPrecisionForPositions | Procedure | Called per instrument with hardcoded OldPrecision=2 |
| Trade.RolloutAboveDollarPrecisionForOrders | Procedure | Called per instrument with hardcoded OldPrecision=2 |

### 6.2 Objects That Depend On This

No dependents found - one-time fix procedure retained for re-use.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Hardcoded OldPrecision | Assumption | All instruments processed assumed to have been at precision=2 before migration |
| No guard check | Risk | Can be called on any instrument regardless of current precision - caller must ensure suitability |
| No config update | Safety | Does NOT modify ProviderToInstrument.Precision - safe to run without affecting precision config |
| Non-transactional | Risk | Transactions commented out - same as main proc |

---

## 8. Sample Queries

### 8.1 Re-run sentinel cleanup for instruments already at new precision

```sql
-- Use when instruments are already at correct precision in ProviderToInstrument
-- but still have 0.01 sentinel rates (OldPrecision=2) in positions/orders
EXEC Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument
    @InstrumentIDs = '1001,1002',
    @Precision = 4,
    @AboveDollarPrecision = 2
```

### 8.2 Check for residual old sentinels before deciding which proc to use

```sql
-- If instruments already have correct Precision in ProviderToInstrument but have 0.01 sentinels:
DECLARE @OldPip DECIMAL(8,6) = 0.01  -- OldPrecision=2 sentinel

SELECT InstrumentID, COUNT(*) AS ResidualsInPositions
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID IN (1001, 1002)
    AND (StopRate = @OldPip OR LimitRate = @OldPip)
    AND Leverage = 1 AND MirrorID = 0
GROUP BY InstrumentID

-- If residuals found -> use Fix variant
-- If instrument precision not yet set -> use main RolloutAboveDollarPrecision
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument.sql*
