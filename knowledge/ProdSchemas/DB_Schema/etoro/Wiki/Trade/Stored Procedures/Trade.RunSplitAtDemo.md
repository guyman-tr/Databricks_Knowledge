# Trade.RunSplitAtDemo

> Copies a stock split from the real trading environment into the demo environment by reading split ratios from RealSplitRatio, inserting into History.SplitRatio with a new demo-side ID, recording the real-to-demo ID mapping in SplitRealInDemoMap, and then calling Trade.ActivateSplit to apply the split to demo positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @SplitID INT - the Real-environment split ID to replicate in Demo |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro processes a stock split on the real environment, the demo environment must be kept in sync so that demo account users experience the same corporate actions. This procedure is the entry point for applying a real-environment split in demo.

The procedure is **demo-only**: it checks `Maintenance.Feature FeatureID=22` (the "is real environment" flag) and raises an error if called on the real server, preventing accidental real-env execution.

The process has two phases:

1. **Split registration** (if not already done): Reads the split data (instrument, price ratio, amount ratio, units before/after, effective date) from `RealSplitRatio` (a cross-environment view/synonym pointing to real env's split table). Inserts the new split record into demo's `History.SplitRatio` with a new IDENTITY-based demo ID and records the real-to-demo ID mapping in `Trade.SplitRealInDemoMap`. This is idempotent - if the split was already registered (mapping exists), this step is skipped.

2. **Split activation**: Calls `Trade.ActivateSplit` with the demo-side split ID. This applies the actual split to demo positions, orders, and prices.

The `@IsReRun` flag (default 0) passes through to `Trade.ActivateSplit` to allow re-running a split that was previously applied (e.g., for corrections).

---

## 2. Business Logic

### 2.1 Environment Guard

**What**: Prevents execution in the real trading environment.

**Columns/Parameters Involved**: `Maintenance.Feature.Value WHERE FeatureID=22`

**Rules**:
- `SELECT CAST(Value AS INT) FROM Maintenance.Feature WHERE FeatureID = 22`
- If value = 1 -> RAISERROR: "You can't run the procedure Trade.RunSplitAtDemo in real environment"
- FeatureID=22 is the "IsRealEnvironment" flag - value 1=real, 0=demo

### 2.2 Idempotent Split Registration

**What**: Copies the real-env split record to demo only if not already done, preventing duplicate splits.

**Columns/Parameters Involved**: `Trade.SplitRealInDemoMap.RealID`, `History.SplitRatio`, `RealSplitRatio`

**Rules**:
- IF NOT EXISTS (SELECT * FROM Trade.SplitRealInDemoMap WHERE RealID = @SplitID) -> register the split
- Reads from `RealSplitRatio` (cross-env view): InstrumentID, PriceRatioUnAdjustedFull/PriceRatioUnAdjusted, AmountRatioUnAdjustedFull/AmountRatioUnAdjusted, UnitsBefore, UnitsAfter, MinDate
- Uses `ISNULL(Full, nonFull)` fallback: `@PriceRatio = ISNULL(PriceRatioUnAdjustedFull, PriceRatioUnAdjusted)`
- Validates no existing History.SplitRatio record covers the same date for same instrument: RAISERROR if duplicate date found
- Closes the existing active record: `UPDATE History.SplitRatio SET MaxDate = @MinDate WHERE MaxDate = '21000101' AND InstrumentID = @InstrumentID` - expects exactly 1 row updated (RAISERROR if @@ROWCOUNT != 1)
- Inserts new History.SplitRatio row; captures SCOPE_IDENTITY() as @DemoSplitID
- Inserts mapping: `INSERT INTO Trade.SplitRealInDemoMap (RealID, DemoID) VALUES (@SplitID, @DemoSplitID)`
- Entire registration is wrapped in a transaction with ROLLBACK on error

### 2.3 Split Activation

**What**: Applies the registered demo split to all affected demo positions and orders.

**Columns/Parameters Involved**: `@DemoSplitID`, `@IsReRun`, `@RetVal`

**Rules**:
- After registration (or if already registered): `SELECT @DemoSplitID = DemoID FROM Trade.SplitRealInDemoMap WHERE RealID = @SplitID`
- EXEC `Trade.ActivateSplit @SplitID = @DemoSplitID, @IsReRun = @IsReRun`
- If ActivateSplit returns -1 -> RAISERROR('Procedure Trade.ActivateSplit had an error')
- CATCH: ROLLBACK if in transaction; re-THROW

**Diagram**:
```
Input: @SplitID (Real env ID)

1. Environment guard: Maintenance.Feature FeatureID=22 = 1? -> STOP (real env)

2. SplitRealInDemoMap has RealID=@SplitID?
   NO:
     a. Read RealSplitRatio WHERE ID=@SplitID
     b. Check no date conflict in History.SplitRatio
     c. BEGIN TRAN:
        - Close active History.SplitRatio (set MaxDate=@MinDate)
        - INSERT new History.SplitRatio -> @DemoSplitID = SCOPE_IDENTITY()
        - INSERT SplitRealInDemoMap (RealID, DemoID)
        COMMIT
   YES: skip to step 3

3. Get @DemoSplitID from SplitRealInDemoMap
4. EXEC Trade.ActivateSplit @DemoSplitID, @IsReRun
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @SplitID | INT | NO | - | CODE-BACKED | The split ID from the Real environment's Trade.SplitRatio/History.SplitRatio. Used to look up the split data in RealSplitRatio and to check/record the mapping in SplitRealInDemoMap. This is the Real ID - the procedure creates a separate Demo ID. |
| 2 | @IsReRun | INT | YES | 0 | CODE-BACKED | Controls whether Trade.ActivateSplit treats this as a re-run (1) or first run (0). Passed through directly to ActivateSplit. Default 0 = first run. Use 1 to re-apply a split that was previously processed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Env check | Maintenance.Feature | Lookup | FeatureID=22: IsRealEnvironment flag; value=1 blocks execution |
| Idempotency check | Trade.SplitRealInDemoMap | Lookup | Checks if Real->Demo mapping already exists |
| Split data source | RealSplitRatio | Lookup | Cross-env view/synonym; provides real-env split ratios and dates |
| Date conflict check | History.SplitRatio | Lookup | Validates no duplicate date coverage for instrument |
| Close active record | History.SplitRatio | Modifier | Updates MaxDate='21000101' row to @MinDate |
| New split insert | History.SplitRatio | Writer | Inserts new demo-side split record |
| Mapping insert | Trade.SplitRealInDemoMap | Writer | Records RealID->DemoID mapping for idempotency |
| Activation | Trade.ActivateSplit | Callee | Applies the split to demo positions, orders, and prices |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase - called ad-hoc by DBA/ops when replicating a real-env split to demo.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RunSplitAtDemo (procedure)
|- Maintenance.Feature (table - environment flag)
|- Trade.SplitRealInDemoMap (table - idempotency/mapping)
|- RealSplitRatio (view/synonym - cross-env source data)
|- History.SplitRatio (table - demo split history, read+write)
|- Trade.ActivateSplit (procedure - applies split to positions)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | FeatureID=22: environment guard - raises error if on real env |
| Trade.SplitRealInDemoMap | Table | Idempotency check (SELECT) and new mapping INSERT |
| RealSplitRatio | View/Synonym | Reads real-env split ratios, instrument, and date |
| History.SplitRatio | Table | Date conflict check; UPDATE existing active record; INSERT new record |
| Trade.ActivateSplit | Procedure | Applies the demo split to all affected positions/orders |

### 6.2 Objects That Depend On This

No dependents found - called ad-hoc during demo environment maintenance.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Real env block | Validation | Maintenance.Feature FeatureID=22 = 1 -> RAISERROR; prevents real-env execution |
| Idempotent registration | Logic | IF NOT EXISTS SplitRealInDemoMap -> only registers once; safe to call multiple times |
| Single active record | Validation | Expects exactly 1 History.SplitRatio row with MaxDate='21000101' for the instrument; RAISERROR if !=1 |
| Date conflict | Validation | RAISERROR if History.SplitRatio already has a record covering @MinDate for the instrument |
| Full ratio fallback | Logic | ISNULL(PriceRatioUnAdjustedFull, PriceRatioUnAdjusted) - uses full precision if available |
| ActivateSplit error | Validation | Return value -1 from ActivateSplit triggers RAISERROR |
| Transaction rollback | Safety | ROLLBACK on inner TRY/CATCH (registration); outer CATCH handles transaction count correctly |

---

## 8. Sample Queries

### 8.1 Apply a real-env split to demo (first time)

```sql
EXEC Trade.RunSplitAtDemo @SplitID = 12345, @IsReRun = 0
```

### 8.2 Re-run a split that was previously applied

```sql
EXEC Trade.RunSplitAtDemo @SplitID = 12345, @IsReRun = 1
```

### 8.3 Check if a real-env split has been mapped to demo

```sql
SELECT RealID, DemoID
FROM Trade.SplitRealInDemoMap WITH (NOLOCK)
WHERE RealID = 12345
```

### 8.4 Verify the split data in demo History.SplitRatio after execution

```sql
SELECT ID, InstrumentID, PriceRatio, AmountRatio, MinDate, MaxDate,
    UnitsBefore, UnitsAfter
FROM History.SplitRatio WITH (NOLOCK)
WHERE InstrumentID = (
    SELECT InstrumentID FROM RealSplitRatio WHERE ID = 12345
)
ORDER BY MinDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RunSplitAtDemo | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RunSplitAtDemo.sql*
