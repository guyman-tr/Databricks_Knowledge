# Trade.RollbackTakeProfitByInstrumentID

> Reverses a bulk take-profit update operation by iterating the History.SystemUpdatePositionTakeProfit audit log for a given OperationID and restoring each tree's original take-profit rate via Trade.PositionEditTakeProfit.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @OperationID INT - references a batch of take-profit changes to reverse |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro performs bulk take-profit adjustments across many positions (e.g., during corporate actions, instrument parameter updates, or data corrections), those changes are recorded in `History.SystemUpdatePositionTakeProfit` with an `OperationID`. This procedure provides a rollback mechanism: given the OperationID of a previous bulk TP update, it restores every affected position tree to its original take-profit rate.

The rollback creates a new OperationID (MAX+1) and records each rollback action back into `History.SystemUpdatePositionTakeProfit`, so the rollback itself is also auditable and can itself be rolled back if needed. The actual take-profit change is applied via `Trade.PositionEditTakeProfit` - the same procedure used for regular user take-profit edits - ensuring all business logic and validations are applied.

The procedure uses a CURSOR to iterate position trees because each tree may have different original/max TP rates, and each `PositionEditTakeProfit` call requires individual parameters. Per-tree error handling allows partial success - if one tree fails to roll back, the error is captured and processing continues for remaining trees.

---

## 2. Business Logic

### 2.1 Rollback Execution Flow

**What**: Audit-driven rollback that mirrors the original operation in reverse.

**Columns/Parameters Involved**: `History.SystemUpdatePositionTakeProfit.OperationID`, `TreeID`, `OrigTakeProfit`, `MaxTakeProfitRate`, `RollBackExec`

**Rules**:
- Source data: `History.SystemUpdatePositionTakeProfit` WHERE OperationID = @OperationID
- For each row: executes `RollBackExec` (a stored dynamic SQL string from the audit table), then calls `Trade.PositionEditTakeProfit` with @LimitRate=OrigTakeProfit and @NetProfit=0
- New rollback records are inserted with @NewOperationID (MAX+1), swapping OrigTakeProfit and MaxTakeProfitRate values
- Per-tree TRY/CATCH: individual tree failures are logged but processing continues
- RAISERROR if OperationID not found at all

**Diagram**:
```
Input: @OperationID (original bulk TP change ID)

History.SystemUpdatePositionTakeProfit WHERE OperationID=@OperationID
  -> For each TreeID:
     1. EXEC @RollBackExec (dynamic SQL stored in audit record)
     2. INSERT new audit record (@NewOperationID, swap Orig/Max)
     3. EXEC Trade.PositionEditTakeProfit(@TreeID, @OrigTakeProfit)
     -> On error: ROLLBACK TRAN, log error message, continue next tree
```

### 2.2 New OperationID Assignment

**What**: The rollback creates its own OperationID, making it auditable and re-reversible.

**Rules**:
- @NewOperationID = MAX(OperationID) + 1 from History.SystemUpdatePositionTakeProfit
- Each rollback action records: @NewOperationID, TreeID, MaxTakeProfitRate (as OrigTakeProfit), OrigTakeProfit (as MaxTakeProfitRate)
- This swap allows this rollback's OperationID to be used as input to a future rollback call, restoring the current state

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @OperationID | INT | NO | - | CODE-BACKED | The OperationID from History.SystemUpdatePositionTakeProfit that identifies the bulk take-profit change batch to roll back. Must exist in the table or RAISERROR is raised. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CURSOR source | History.SystemUpdatePositionTakeProfit | Lookup | Reads the audit log of the original bulk TP update to get TreeIDs and original rates |
| INSERT | History.SystemUpdatePositionTakeProfit | Writer | Records each rollback action as a new OperationID entry |
| EXEC | Trade.PositionEditTakeProfit | Callee | Applies the restored take-profit rate to each position tree |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.RollbackTakeProfitByInstrumentID (procedure)
|- History.SystemUpdatePositionTakeProfit (table - audit log read/write)
|- Trade.PositionEditTakeProfit (procedure - applies TP change)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.SystemUpdatePositionTakeProfit | Table | CURSOR source for original TP changes; INSERT target for rollback audit records |
| Trade.PositionEditTakeProfit | Procedure | Called per tree to restore the original take-profit rate with @IsInitiatedByUser=0 |

### 6.2 Objects That Depend On This

No dependents found - called ad-hoc by DBA/ops teams for take-profit rollback operations.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| OperationID exists | Validation | IF NOT EXISTS(SELECT * FROM History.SystemUpdatePositionTakeProfit WHERE OperationID=@OperationID) -> RAISERROR |
| Per-tree error handling | Logic | Inner TRY/CATCH per cursor row - individual failures don't abort entire rollback; ROLLBACK TRAN per failed tree |

---

## 8. Sample Queries

### 8.1 Roll back a specific bulk TP operation

```sql
EXEC Trade.RollbackTakeProfitByInstrumentID @OperationID = 42
```

### 8.2 Check what operations are available to roll back

```sql
SELECT OperationID, COUNT(*) AS TreeCount, MIN(Description) AS Description,
    MIN(MaxTakeProfitRate) AS MinMaxTP, MAX(OrigTakeProfit) AS MaxOrigTP
FROM History.SystemUpdatePositionTakeProfit WITH (NOLOCK)
GROUP BY OperationID
ORDER BY OperationID DESC
```

### 8.3 Preview what would be rolled back for a given OperationID

```sql
SELECT OperationID, TreeID, OrigTakeProfit AS WillRestoreTo,
    MaxTakeProfitRate AS CurrentRateBefore, Description, RollBackExec
FROM History.SystemUpdatePositionTakeProfit WITH (NOLOCK)
WHERE OperationID = 42
ORDER BY TreeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.RollbackTakeProfitByInstrumentID | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.RollbackTakeProfitByInstrumentID.sql*
