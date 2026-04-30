# Trade.UpdateTree

> Updates stop-loss, take-profit, close-on-end-of-week, or trailing-stop-loss settings for a position tree in Trade.PositionTreeInfo, logs the change via History.PositionChangeLog_Insert, and returns all child positions in the tree for TradeServer synchronization.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TreeID (the position tree to update) |
| **Partition** | Trade.PositionTreeInfo.PartitionCol = ABS(TreeID) % 50 |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.UpdateTree is the core procedure for modifying risk-management settings (stop-loss, take-profit, trailing stop loss, close-on-end-of-week) on a position tree. A "tree" groups a root position with all its copy-trade children, sharing the same risk parameters via Trade.PositionTreeInfo.

This procedure is called by higher-level procedures that handle validation and authorization, never directly by applications in a Real environment (blocked by FeatureID 22 check when @FromEditProd=0). It performs the update, captures previous values using the OUTPUT clause, logs the change to History.PositionChangeLog_Insert, and returns the list of child positions so the TradeServer can broadcast the updated settings.

The @Operation value is inferred from which parameter is non-NULL: 1=StopRate, 2=LimitRate, 3=CloseOnEndOfWeek, 7=IsTslEnabled. Only one operation can be performed per call. The SLManualVer (stop-loss manual version) counter increments on manual stop-loss or TSL changes, providing optimistic concurrency control.

---

## 2. Business Logic

### 2.1 Operation Type Detection

**What**: Automatically determines what type of update is being performed based on which parameter is non-NULL.

**Columns/Parameters Involved**: `@StopRate`, `@LimitRate`, `@CloseOnEndOfWeek`, `@IsTslEnabled`

**Rules**:
- @StopRate not null → Operation 1 (Stop Loss update)
- @LimitRate not null → Operation 2 (Take Profit update)
- @CloseOnEndOfWeek not null → Operation 3 (End-of-week close toggle)
- @IsTslEnabled not null → Operation 7 (Trailing Stop Loss toggle)
- Only one parameter should be non-NULL per call

### 2.2 Real vs Demo Environment

**What**: The procedure behaves differently in Real vs Demo environments.

**Rules**:
- FeatureID 22 value=1 → Real environment: @IsReal=1, TreeID is positive
- FeatureID 22 value≠1 → Demo environment: @IsReal=-1, TreeID is negative
- Direct calls (@FromEditProd=0) are blocked in Real environment
- Demo environment uses NOLOCK hint on child position query (trees can exceed 30,000 records)

### 2.3 SLManualVer Concurrency Control

**What**: Tracks stop-loss manual version for optimistic concurrency in real-time trading.

**Rules**:
- Incremented when: @IsManualOperation=1 AND (@StopRate is changed OR @IsTslEnabled=1)
- Uses @SLManualVerTimestamp or GETUTCDATE() as the version timestamp
- Returned as OUTPUT parameter so the caller can verify version after update

### 2.4 PositionTreeInfo Update

**What**: Atomically updates tree-level settings using ISNULL/IIF patterns.

**Rules**:
- Each column only updated if corresponding parameter is non-NULL (ISNULL pattern)
- IsTslEnabled: converts any truthy value to 1, any falsy to 0
- NextThresHold: only updated when enabling TSL or when TSL is already enabled
- IsNoStopLoss/IsNoTakeProfit: updated independently if provided
- OUTPUT clause captures both previous and new values for change logging

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TreeID | BIGINT | NO | - | VERIFIED | Position tree identifier. Positive in Real, negative in Demo. Used as the root PositionID. |
| 2 | @StopRate | dtPrice | YES | NULL | VERIFIED | New stop-loss rate. When non-NULL, triggers Operation=1 update. OUTPUT: returns current value after update. |
| 3 | @LimitRate | dtPrice | YES | NULL | VERIFIED | New take-profit rate. When non-NULL, triggers Operation=2 update. OUTPUT: returns current value after update. |
| 4 | @CloseOnEndOfWeek | BIT | YES | NULL | VERIFIED | New close-on-end-of-week setting. When non-NULL, triggers Operation=3 update. OUTPUT: returns current value. |
| 5 | @FromEditProd | TINYINT | YES | 0 | CODE-BACKED | Safety flag: 0=direct call (blocked in Real), 1=called from validated higher-level procedure. |
| 6 | @Credit | MONEY | YES | 0 | CODE-BACKED | Amount change (credit/debit) for the position, logged in change log as AmountChanged. |
| 7 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Trading session ID for audit trail, passed to History.PositionChangeLog_Insert. |
| 8 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Override for last operation price rate. Falls back to PositionTbl value if NULL. |
| 9 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Override for last operation price rate ID. Falls back to PositionTbl value if NULL. |
| 10 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Override for last operation conversion rate. Falls back to PositionTbl value if NULL. |
| 11 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Override for last operation conversion rate ID. Falls back to PositionTbl value if NULL. |
| 12 | @IsTslEnabled | TINYINT | YES | NULL | CODE-BACKED | Enable/disable trailing stop loss. When non-NULL, triggers Operation=7. |
| 13 | @NextThresHold | dtPrice | YES | NULL | CODE-BACKED | Next price threshold for TSL adjustment. Only set when TSL is being enabled or is already active. |
| 14 | @SLManualVerTimestamp | DATETIME | YES | NULL | CODE-BACKED | Timestamp for the SL manual version update. Defaults to GETUTCDATE() if NULL. |
| 15 | @SLManualVer | INT | YES | NULL | CODE-BACKED | OUTPUT: Returns the updated stop-loss manual version counter for optimistic concurrency. |
| 16 | @IsManualOperation | TINYINT | YES | 1 | CODE-BACKED | Whether this is a user-initiated operation (1) vs system-initiated (0). Controls SLManualVer increment. |
| 17 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client request correlation ID for end-to-end tracing. |
| 18 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | When set, explicitly marks the tree as having no stop loss configured. |
| 19 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | When set, explicitly marks the tree as having no take profit configured. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UPDATE | Trade.PositionTreeInfo | UPDATE | Updates tree-level SL/TP/TSL/CloseOnEndOfWeek settings |
| FROM | Trade.Position | SELECT | Reads root position data for change logging |
| JOIN | Customer.Customer | SELECT | Gets RealizedEquity for change log |
| JOIN | Trade.Mirror | SELECT | Gets mirror RealizedEquity for change log |
| FROM | Maintenance.Feature | SELECT | Checks FeatureID 22 for Real/Demo detection |
| EXEC | History.PositionChangeLog_Insert | EXEC | Logs the change to position history |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ChangeTreePropertiesPerInstrument | (batch #17) | EXEC | Batch updates tree settings per instrument |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateTree (procedure)
+-- Trade.PositionTreeInfo (table)
+-- Trade.Position (view)
+-- Customer.Customer (table)
+-- Trade.Mirror (table)
+-- Maintenance.Feature (table)
+-- History.PositionChangeLog_Insert (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTreeInfo | Table | UPDATE - modifies tree-level risk settings |
| Trade.Position | View | SELECT - reads root position data |
| Customer.Customer | Table | SELECT - customer RealizedEquity |
| Trade.Mirror | Table | SELECT - mirror RealizedEquity |
| Maintenance.Feature | Table | SELECT - Real/Demo environment detection |
| History.PositionChangeLog_Insert | Procedure | EXEC - logs position changes |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ChangeTreePropertiesPerInstrument | Procedure | Calls this for each tree of an instrument |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Real environment block | Safety | @FromEditProd=0 in Real → RAISERROR |
| Partition elimination | Performance | PartitionCol = ABS(@TreeID) % 50 |
| Change log silenced | Error handling | History.PositionChangeLog_Insert errors are silently caught |

---

## 8. Sample Queries

### 8.1 View current tree settings

```sql
SELECT  TreeID, StopRate, LimitRate, CloseOnEndOfWeek, IsTslEnabled,
        NextThresHold, SLManualVer, SLManualVerTimestamp, IsNoStopLoss, IsNoTakeProfit
FROM    Trade.PositionTreeInfo WITH (NOLOCK)
WHERE   TreeID = 12345
        AND PartitionCol = ABS(12345) % 50;
```

### 8.2 View child positions in a tree

```sql
SELECT  PositionID, CID, IsDiscounted
FROM    Trade.Position WITH (NOLOCK)
WHERE   TreeID = 12345
        AND ABS(TreeID) <> PositionID
        AND TreePartitionCol = ABS(12345) % 50;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 9.0/10 (Elements: 9.5/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateTree | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateTree.sql*
