# Trade.RolloutAboveDollarPrecision

> Orchestrates the above-dollar precision migration for a comma-separated list of instruments: parses the IDs, checks for already-migrated instruments, calls RolloutAboveDollarPrecisionForPositions and RolloutAboveDollarPrecisionForOrders per instrument, then updates ProviderToInstrument.Precision and AboveDollarPrecision.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentIDs VARCHAR(MAX) - comma-separated list of instruments to migrate |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When an instrument's market price rises above $1 (or a similar threshold), eToro migrates it to "above-dollar precision" - reducing the number of decimal places in rates. For example, a stock trading at $150 doesn't need 4 decimal places (0.0001 precision); it only needs 2 (0.01 precision). This migration affects all stored rates in the system.

This procedure is the **orchestrator** for the precision migration. Given a list of instrument IDs and the new precision values, it:
1. Parses the comma-separated instrument IDs into `#Instruments`
2. For each instrument: verifies it hasn't already been migrated (precision != @Precision)
3. Calls `RolloutAboveDollarPrecisionForPositions` to update sentinel SL/TP rates in open positions
4. Calls `RolloutAboveDollarPrecisionForOrders` to update sentinel SL/TP rates in pending orders
5. Updates `Trade.ProviderToInstrument.Precision` and `AboveDollarPrecision` to record the new precision

The sentinel rate concept: a rate of `1/10^OldPrecision` means "no stop-loss/take-profit set". After migration, this sentinel must become `1/10^NewPrecision` to maintain the same semantic meaning.

Note: The `BEGIN TRAN/COMMIT` and `ROLLBACK` calls are commented out - the migration is NOT transactional. If an error occurs mid-batch, already-processed instruments stay migrated and the failing instrument causes the procedure to stop (THROW).

---

## 2. Business Logic

### 2.1 Instrument List Parsing

**What**: Converts the CSV input into a processable temp table.

**Columns/Parameters Involved**: `@InstrumentIDs`, `STRING_SPLIT`, `#Instruments`

**Rules**:
- `SELECT [value] AS InstrumentID INTO #Instruments FROM STRING_SPLIT(@InstrumentIDs, ',')`
- Drops existing `#Instruments` if it exists (clean re-run safety)

### 2.2 Already-Migrated Check

**What**: Prevents re-processing instruments that were already migrated to the target precision.

**Rules**:
- SELECT @OldPrecision = Precision FROM Trade.ProviderToInstrument WHERE InstrumentID = @InstrumentID
- IF @OldPrecision = @Precision -> RAISERROR: 'Update precision was already done instrument:{ID} precision:{N}'
- This is a hard stop per instrument (THROW propagates up, stopping the batch)

### 2.3 Position and Order Sentinel Migration

**What**: Delegates the actual sentinel rate replacement to the specialized sub-procedures.

**Rules**:
- @OnePip = 1.00 / POWER(10, @OldPrecision) - old sentinel (computed but not directly passed)
- EXEC RolloutAboveDollarPrecisionForPositions @InstrumentID, @OldPrecision, @Precision
- EXEC RolloutAboveDollarPrecisionForOrders @InstrumentID, @OldPrecision, @Precision
- Note: @Precision is passed as @NewNOSLPrecision in both sub-procedures

### 2.4 Precision Record Update

**What**: Records the new precision values in the instrument configuration.

**Rules**:
- UPDATE Trade.ProviderToInstrument SET Precision=@Precision, AboveDollarPrecision=@AboveDollarPrecision WHERE InstrumentID=@InstrumentID
- This step distinguishes the main proc from the Fix variant (which skips this update)
- After this update, future calls to this proc for the same instrument will trigger the "already done" check

**Diagram**:
```
Input: @InstrumentIDs='1001,1002', @Precision=2, @AboveDollarPrecision=4

STRING_SPLIT -> #Instruments: {1001, 1002}

For each InstrumentID:
  1. Read current Precision from ProviderToInstrument
  2. If Precision = @Precision -> RAISERROR (already migrated)
  3. @OldPrecision set; old sentinel = 1/10^OldPrecision
  4. EXEC RolloutAboveDollarPrecisionForPositions (updates open positions)
  5. EXEC RolloutAboveDollarPrecisionForOrders (updates pending orders)
  6. UPDATE ProviderToInstrument SET Precision=@Precision, AboveDollarPrecision=@AboveDollarPrecision
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentIDs | VARCHAR(MAX) | NO | - | CODE-BACKED | Comma-separated list of InstrumentIDs to migrate. Parsed via STRING_SPLIT. Example: '1001,1002,1003'. Each instrument is processed sequentially. |
| 2 | @Precision | DECIMAL(16,8) | NO | - | CODE-BACKED | The new decimal precision for the instrument's rates after migration. Also used as the @NewNOSLPrecision for sentinel calculation in sub-procedures. Example: 2 means rates use 2 decimal places (0.01 precision). |
| 3 | @AboveDollarPrecision | DECIMAL(16,8) | NO | - | CODE-BACKED | The above-dollar precision value to record in ProviderToInstrument.AboveDollarPrecision. Stored as a configuration marker after migration. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Precision check + UPDATE | Trade.ProviderToInstrument | Modifier | Reads current Precision for guard check; updates Precision+AboveDollarPrecision post-migration |
| Position migration | Trade.RolloutAboveDollarPrecisionForPositions | Callee | Migrates sentinel SL/TP rates in open positions |
| Order migration | Trade.RolloutAboveDollarPrecisionForOrders | Callee | Migrates sentinel SL/TP rates in pending orders |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | Sibling | Fix variant | Same structure but hardcoded @OldPrecision=2 and skips ProviderToInstrument update |
| DBA/Ops teams | Ad-hoc | Caller | Called during corporate action processing when instruments cross the $1 threshold |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RolloutAboveDollarPrecision (procedure)
|- Trade.ProviderToInstrument (table - precision read + update)
|- Trade.RolloutAboveDollarPrecisionForPositions (procedure - position sentinel update)
|- Trade.RolloutAboveDollarPrecisionForOrders (procedure - order sentinel update)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | Read current Precision for guard; UPDATE Precision+AboveDollarPrecision after migration |
| Trade.RolloutAboveDollarPrecisionForPositions | Procedure | Called per instrument to update open position sentinel rates |
| Trade.RolloutAboveDollarPrecisionForOrders | Procedure | Called per instrument to update pending order sentinel rates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.RolloutAboveDollarPrecision_25102021_FixForDoneInstrument | Procedure | Fix variant - shares the same sub-procedure calls |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Already-migrated guard | Validation | If current Precision = @Precision -> RAISERROR - prevents double-migration |
| Non-transactional | Risk | BEGIN TRAN/COMMIT commented out - partial migration possible if error occurs mid-batch |
| CURSOR-per-instrument | Logic | Sequential processing; error on any instrument stops the remaining batch (THROW) |
| Precision parameter dual-use | Logic | @Precision is BOTH the new instrument precision AND the @NewNOSLPrecision for sentinel calculation |

---

## 8. Sample Queries

### 8.1 Migrate a single instrument to 2 decimal precision

```sql
EXEC Trade.RolloutAboveDollarPrecision
    @InstrumentIDs = '1001',
    @Precision = 2,
    @AboveDollarPrecision = 4
```

### 8.2 Migrate a batch of instruments

```sql
EXEC Trade.RolloutAboveDollarPrecision
    @InstrumentIDs = '1001,1002,1003,1004',
    @Precision = 2,
    @AboveDollarPrecision = 4
```

### 8.3 Check current precision values before migration

```sql
SELECT InstrumentID, Precision, AboveDollarPrecision
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID IN (1001, 1002, 1003)
```

### 8.4 Verify migration completed

```sql
-- Check ProviderToInstrument was updated
SELECT InstrumentID, Precision, AboveDollarPrecision
FROM Trade.ProviderToInstrument WITH (NOLOCK)
WHERE InstrumentID IN (1001, 1002, 1003)

-- Check no old sentinels remain in open positions
DECLARE @OldPip DECIMAL(8,6) = 1.00 / POWER(10, 4)  -- old precision=4
SELECT COUNT(*) AS RemainingOldSentinels
FROM Trade.Position WITH (NOLOCK)
WHERE InstrumentID IN (1001, 1002, 1003)
    AND (StopRate = @OldPip OR LimitRate = @OldPip)
    AND Leverage = 1 AND MirrorID = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RolloutAboveDollarPrecision | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RolloutAboveDollarPrecision.sql*
