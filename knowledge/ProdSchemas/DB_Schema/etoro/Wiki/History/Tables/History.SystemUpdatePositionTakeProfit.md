# History.SystemUpdatePositionTakeProfit

> Audit and rollback log for system-initiated bulk take-profit adjustments - records each tree-level TP change made by Trade.UpdatePositionsTakeProfitByInstrumentID, including a pre-built rollback SQL command to reverse the change.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | OperationID (INT, no formal PK - manually assigned as MAX+1) |
| **Partition** | No |
| **Indexes** | 0 (no indexes defined) |

---

## 1. Business Meaning

History.SystemUpdatePositionTakeProfit is an audit and operational rollback log for batch take-profit (TP) adjustments applied by the trading system. When eToro's operations team needs to enforce a maximum take-profit ceiling across all open positions for a given instrument (e.g., the 200% TP cap introduced with Free Stocks in 2019), Trade.UpdatePositionsTakeProfitByInstrumentID iterates through all affected copy-trading trees and updates each tree's take-profit rate. Every such update is recorded here.

The table serves two distinct purposes: (1) audit trail - showing what TP values were changed, when, to what, and why; and (2) rollback capability - the `RollBackExec` column stores a pre-built `EXEC Trade.PositionEditTakeProfit` SQL string that, when executed, reverses the TP change. Trade.RollbackTakeProfitByInstrumentID reads this column and executes the stored commands to undo an entire operation.

Rows are grouped by `OperationID`, where one operation = one execution of the batch update procedure for one instrument. Each row within an operation covers one copy-trading tree. The table is currently empty in this environment (0 rows), consistent with a tooling table populated only by operations-team interventions rather than routine trading activity.

---

## 2. Business Logic

### 2.1 Operation Grouping and Audit

**What**: All tree-level TP changes in a single batch run share one OperationID, enabling the entire batch to be reviewed or rolled back atomically.

**Columns/Parameters Involved**: `OperationID`, `Occurred`, `TreeID`, `Description`

**Rules**:
- OperationID is assigned as `MAX(OperationID) + 1` at the start of each run - there is no sequence or identity column
- All rows inserted during one procedure execution share the same OperationID
- Description is auto-generated: "Take Profit Update, instrumentID: {N}"
- Occurred defaults to `GETUTCDATE()` at the moment of each tree's update (not the batch start time)
- A rollback operation creates a new OperationID with Description = "Rollback for OperationID #{original}"

**Diagram**:
```
OperationID = 1 (batch run for InstrumentID 5)
  Row 1: TreeID=100001, OrigTP=1.50, NewTP=1.20, Occurred=2024-01-15 10:00:01
  Row 2: TreeID=100002, OrigTP=1.80, NewTP=1.20, Occurred=2024-01-15 10:00:02
  Row 3: TreeID=100003, OrigTP=2.10, NewTP=1.20, Occurred=2024-01-15 10:00:02

OperationID = 2 (rollback of OperationID=1)
  Row 1: TreeID=100001, OrigTP=1.20, NewTP=1.50, Description="Rollback for OperationID #1"
  Row 2: TreeID=100002, OrigTP=1.20, NewTP=1.80, Description="Rollback for OperationID #1"
  Row 3: TreeID=100003, OrigTP=1.20, NewTP=2.10, Description="Rollback for OperationID #1"
```

### 2.2 RollBackExec - Executable Rollback Command

**What**: Each row stores a pre-built SQL string that reverses its specific TP change when executed.

**Columns/Parameters Involved**: `RollBackExec`, `TreeID`, `OrigTakeProfit`

**Rules**:
- Built at INSERT time: `CONCAT('DECLARE @XMLResult XML; DECLARE @ErrOut NVARCHAR(4000); EXEC [Trade].[PositionEditTakeProfit] ', @TreeID, ' ,', @OrigTakeProfit, ',0,@XMLResult OUTPUT,NULL,NULL,NULL,NULL,-1,@ErrOut OUTPUT,null')`
- Trade.RollbackTakeProfitByInstrumentID executes this string via `EXEC (@cmd)` - dynamic SQL rollback
- The rollback procedure swaps OrigTakeProfit and MaxTakeProfitRate: the original TP becomes the new "max" in the rollback row, and vice versa, creating a symmetric audit trail
- VARCHAR(200) limit constrains TP value precision in the rollback command - very long decimal values could be truncated

### 2.3 Free Stocks Take-Profit Cap (Origin Context)

**What**: This table was introduced for FB 53719 ("Free Stocks", March 2019) to manage the maximum take-profit ceiling on real stock positions.

**Columns/Parameters Involved**: `RateDiffPercentage`, `MaxTakeProfitRate`

**Rules**:
- Default @RateDiffPercentage = 200 (200% above current rate = max TP allowed for Free Stocks)
- Only trees where OrigTakeProfit differs from the calculated MaxTakeProfitRate are updated (and logged)
- MaxTakeProfitRate is rounded to instrument precision from Trade.ProviderToInstrument before insert
- The procedure also inserts into History.BrexitModifiedPositions alongside this table (same transaction)

---

## 3. Data Overview

Table is currently empty (0 rows) in this environment. This is expected - the table is populated only when operations team explicitly runs the batch TP adjustment procedure. In production, rows appear after each bulk TP enforcement run.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationID | INT | NO | - | CODE-BACKED | Manually assigned batch identifier: computed as `ISNULL(MAX(OperationID), 0) + 1` at the start of each batch run. Groups all tree-level TP updates from a single procedure execution. Rollback operations create a new OperationID with a "Rollback for OperationID #N" description. No formal PK or IDENTITY. |
| 2 | Occurred | DATETIME | NO | getutcdate() | CODE-BACKED | UTC timestamp of when this specific tree's TP was updated (captured mid-loop, not batch start time). Defaults to GETUTCDATE(). NULL for rollback rows (inserted without explicit @Occured value). |
| 3 | TreeID | BIGINT | NO | - | CODE-BACKED | Copy-trading tree root PositionID. All positions in a copy-trading family share the same TreeID (the root position's PositionID). One row per tree per operation. References Trade.PositionTbl (copy-trade root). |
| 4 | OrigTakeProfit | dbo.dtPrice | NO | - | CODE-BACKED | The take-profit rate of this tree BEFORE the batch update was applied. Used as the restore target in rollback operations. In rollback rows, this field holds the MaxTakeProfitRate from the original operation (reflecting the swap logic in the rollback procedure). |
| 5 | MaxTakeProfitRate | dbo.dtPrice | NO | - | CODE-BACKED | The calculated maximum allowed take-profit rate for this tree after rounding to instrument precision. This is the NEW value applied by the batch update. Derived from Trade.OldAndNewTakeProfitPerInstrumentID function applied to @RateDiffPercentage. |
| 6 | RateDiffPercentage | DECIMAL(16,8) | YES | NULL | CODE-BACKED | The percentage threshold used to compute MaxTakeProfitRate. Default = 200 (200% cap). Set to NULL for rollback rows. Allows auditors to identify what ceiling was applied in a given operation. |
| 7 | ConversionRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Currency conversion rate (from Trade.GetMinorConversionRate) used to compute TP values in the instrument's minor currency. NULL for rollback rows. Provides full rate context for audit verification of the TP calculations. |
| 8 | CurrentRate | dbo.dtPrice | YES | NULL | CODE-BACKED | Market rate of the instrument at the time of the TP update. Sourced from Trade.OldAndNewTakeProfitPerInstrumentID. NULL for rollback rows. Contextualizes how far the existing TP was from the current market when the cap was applied. |
| 9 | RollBackExec | VARCHAR(200) | YES | NULL | CODE-BACKED | Pre-built T-SQL command string to reverse this specific TP change: `EXEC [Trade].[PositionEditTakeProfit] {TreeID}, {OrigTakeProfit}, 0, @XMLResult OUTPUT, NULL, NULL, NULL, NULL, -1, @ErrOut OUTPUT, null`. Executed via `EXEC (@cmd)` in Trade.RollbackTakeProfitByInstrumentID. NULL for rollback rows (rollbacks are not themselves reversible via this mechanism). |
| 10 | Description | VARCHAR(200) | YES | NULL | CODE-BACKED | Human-readable description of the operation. For forward operations: "Take Profit Update, instrumentID: {N}". For rollback operations: "Rollback for OperationID #{N}". NULL if not provided. |
| 11 | TpPNLDelta | dbo.dtPrice | YES | NULL | CODE-BACKED | The PnL delta attributable to the TP change for this tree, sourced from Trade.OldAndNewTakeProfitPerInstrumentID. Indicates the financial impact of the TP cap on the customer's take-profit payout. NULL for rollback rows. |
| 12 | IsBuy | INT | YES | NULL | CODE-BACKED | Position direction: 1 = Buy/Long, 0 = Sell/Short. Typed as INT (not BIT - allows NULL). Not inserted by the forward procedure (only inserted by History.BrexitModifiedPositions path). Stored for potential rollback direction validation. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TreeID | Trade.PositionTbl | Implicit | References the copy-trading tree root position. TreeID = root PositionID in Trade.PositionTbl. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | OperationID, TreeID, ... | Writer (INSERT) | Primary writer. Inserts one row per tree per batch TP adjustment. |
| Trade.RollbackTakeProfitByInstrumentID | OperationID | Reader + Writer | Reads RollBackExec commands to reverse a prior operation; writes new rows documenting the rollback. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SystemUpdatePositionTakeProfit (table)
  (leaf - no code-level dependencies; uses dbo.dtPrice UDT as column type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.dtPrice | User Defined Type | Column type for OrigTakeProfit, MaxTakeProfitRate, ConversionRate, CurrentRate, TpPNLDelta |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdatePositionsTakeProfitByInstrumentID | Stored Procedure | WRITER - inserts audit rows per tree TP change; also reads MAX(OperationID) to assign next operation number |
| Trade.RollbackTakeProfitByInstrumentID | Stored Procedure | READER + WRITER - reads RollBackExec to execute rollback; writes rollback audit rows |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The table has no PK, no clustered index, and no nonclustered indexes. Access patterns (cursor reads by OperationID) work with a table scan, which is acceptable given the expected small row count.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_HistorySystemUpdatePositionTakeProfit_Occurred | DEFAULT | `getutcdate()` for Occurred - ensures timestamp is captured even if caller does not supply it |

---

## 8. Sample Queries

### 8.1 Review all trees updated in a specific operation
```sql
SELECT
    h.OperationID,
    h.TreeID,
    h.OrigTakeProfit,
    h.MaxTakeProfitRate,
    h.RateDiffPercentage,
    h.CurrentRate,
    h.Occurred,
    h.Description
FROM History.SystemUpdatePositionTakeProfit h WITH (NOLOCK)
WHERE h.OperationID = 1
ORDER BY h.Occurred;
```

### 8.2 List all operations with summary counts
```sql
SELECT
    h.OperationID,
    MIN(h.Description) AS Description,
    COUNT(*) AS TreesAffected,
    MIN(h.Occurred) AS StartTime,
    MAX(h.Occurred) AS EndTime
FROM History.SystemUpdatePositionTakeProfit h WITH (NOLOCK)
GROUP BY h.OperationID
ORDER BY h.OperationID DESC;
```

### 8.3 Preview rollback commands for an operation (before executing)
```sql
SELECT
    h.OperationID,
    h.TreeID,
    h.OrigTakeProfit AS CurrentTP,
    h.MaxTakeProfitRate AS TPAfterForward,
    h.RollBackExec AS RollbackCommand
FROM History.SystemUpdatePositionTakeProfit h WITH (NOLOCK)
WHERE h.OperationID = 1
    AND h.RollBackExec IS NOT NULL
ORDER BY h.TreeID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed (Trade.UpdatePositionsTakeProfitByInstrumentID, Trade.RollbackTakeProfitByInstrumentID) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SystemUpdatePositionTakeProfit | Type: Table | Source: etoro/etoro/History/Tables/History.SystemUpdatePositionTakeProfit.sql*
