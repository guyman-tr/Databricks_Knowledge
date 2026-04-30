# Trade.DetachPositionsFromMirror

> Detaches a position from a mirror (copy-trade) relationship by creating a new tree, updating the position and child positions, adjusting mirror equity, recording credit, and queuing post-detach operations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID, @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This is the **primary mirror detachment procedure** for the copy-trade system. When a copier position needs to be disconnected from its leader's mirror (e.g., user stops copying, regulatory requirement, country/instrument restriction), this procedure orchestrates the full detachment workflow: validates the mirror is active, creates a new independent PositionTreeInfo record, updates the position (ParentPositionID=0, MirrorID=0, new TreeID), updates all child positions, adjusts the mirror's equity and withdrawal summary, records the credit via Customer.SetBalanceInsertCredit_Native (CreditTypeID=27), and queues post-detach operations in Trade.PostDetachOperation for asynchronous processing by background jobs.

The procedure supports optional parameter overrides for stop-loss (@NewStopRate), take-profit (@NewLimitRate), trailing stop (@NewThresHold, @NewIsTslEnabled), and settlement type conversion (@SetPositionsAsReal). When @SetPositionsAsReal=1 and the position is a buy with leverage 1, IsSettled is flipped to 1 (converting from CFD to real stock ownership).

---

## 2. Business Logic

### 2.1 Mirror Validation and Position Resolution

**What**: Validates the mirror is active and resolves position data.

**Columns/Parameters Involved**: `@MirrorID`, `@PositionID`, `Trade.Mirror.IsActive`

**Rules**:
- Reads Trade.Mirror for CID, RealizedEquity, Amount, IsActive, MirrorSL ratio
- If IsActive IS NULL: RAISERROR "Mirror has already been closed"
- Resolves position data from Trade.Position WHERE CID=@CID AND MirrorID=@MirrorID AND PositionID=@PositionID

### 2.2 Position and Tree Update

**What**: Creates new tree, detaches position from mirror, updates child positions.

**Columns/Parameters Involved**: `@NewTreeID`, `Trade.PositionTreeInfo`, `Trade.PositionTbl`

**Rules**:
- @NewTreeID = @IsReal * @PositionID (positive for real, negative for demo)
- INSERT INTO Trade.PositionTreeInfo with overridden or existing SL/TP/TSL values
- UPDATE Trade.PositionTbl SET ParentPositionID=0, TreeID=@NewTreeID, MirrorID=0, IsSettled=@IsSettled
- UPDATE all child positions (from @ChildPositionList TVP) SET TreeID = @NewTreeID
- Uses OUTPUT clauses to capture results into TVP variables for return to caller

### 2.3 Mirror Equity Adjustment and Post-Detach Queue

**What**: Adjusts mirror financial state and queues async post-detach operations.

**Columns/Parameters Involved**: `Trade.Mirror`, `Trade.PostDetachOperation`, `Customer.SetBalanceInsertCredit_Native`

**Rules**:
- NewMirrorRE = MirrorRE - PositionAmount (removing position's equity contribution)
- UPDATE Trade.Mirror SET RealizedEquity, MirrorSL (proportionally adjusted), WithdrawalSummary += PositionAmount
- Uses OUTPUT INTO Trade.PostDetachOperation to queue the detach for async processing (change log, history mirror log, etc.)
- MirrorOperationID = 10 (Position Transfer)
- Calls Customer.SetBalanceInsertCredit_Native for CreditTypeID=27 (Detachment)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | Mirror (copy-trade relationship) ID from which the position is being detached. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Position being detached from the mirror. Becomes the root of a new independent tree. |
| 3 | @SetPositionsAsReal | TINYINT | NO | 0 | CODE-BACKED | When 1: converts eligible positions (IsBuy=1, Leverage=1) to settled/real stock (IsSettled=1). Used when detaching into real stock ownership. |
| 4 | @ChildPositionList | Trade.PositionIDsTbl (TVP) | READONLY | - | CODE-BACKED | List of child position IDs under this position in the copy tree. All will have their TreeID updated. |
| 5 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client request correlation ID for tracking the detach operation end-to-end. |
| 6 | @NewStopRate | dtPrice | YES | NULL | CODE-BACKED | Override stop-loss rate for the new tree. If NULL, inherits from the position's current StopRate. |
| 7 | @NewLimitRate | dtPrice | YES | NULL | CODE-BACKED | Override take-profit rate for the new tree. If NULL, inherits from the position's current LimitRate. |
| 8 | @NewThresHold | dtPrice | YES | NULL | CODE-BACKED | Override trailing stop-loss threshold. If NULL, inherits from position's NextThresHold. |
| 9 | @NewIsTslEnabled | TINYINT | YES | NULL | CODE-BACKED | Override trailing stop-loss enabled flag. If NULL, inherits from position's IsTslEnabled. |
| 10 | @ConversionRate | dtPrice | YES | NULL | CODE-BACKED | Currency conversion rate for the detach operation. If NULL, uses position's LastOpConversionRate. |
| 11 | @ConversionRateID | BIGINT | YES | NULL | CODE-BACKED | ID of the conversion rate record. If NULL, uses position's LastOpConversionRateID. |
| 12 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | Override no-stop-loss flag. If NULL, inherits from position. |
| 13 | @IsNoTakeProfit | BIT | YES | NULL | CODE-BACKED | Override no-take-profit flag. If NULL, inherits from position. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Read + Write | Reads mirror data, updates RealizedEquity/MirrorSL/WithdrawalSummary |
| @PositionID | Trade.PositionTbl | Read + Write | Updates ParentPositionID=0, MirrorID=0, TreeID, IsSettled |
| (INSERT) | Trade.PositionTreeInfo | Write | Creates new tree record with SL/TP/TSL settings |
| (INSERT) | Trade.PostDetachOperation | Write | Queues post-detach async operations |
| (EXEC) | Customer.SetBalanceInsertCredit_Native | Procedure call | Records mirror credit for CreditTypeID=27 |
| (SELECT) | Customer.CustomerMoney | Read | Gets customer credit/payment/equity for balance recording |
| (INSERT) | History.PositionFailWrite | Write (on error) | Logs failure details with FailTypeID=8 |
| @ChildPositionList | Trade.PositionIDsTbl | UDT (TVP) | Child position list type |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.DetachPositionsByCountryAndInstrument | EXEC call | Caller | Calls per-position with @SetPositionsAsReal=1 for country/instrument-based detachment |
| (Application layer) | N/A | Direct caller | Called by the trading service when a user stops copying |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DetachPositionsFromMirror (procedure)
+-- Trade.Mirror (table)
+-- Trade.PositionTbl (table)
+-- Trade.Position (view)
+-- Trade.PositionTreeInfo (table)
+-- Trade.PostDetachOperation (table)
+-- Customer.CustomerMoney (table)
+-- Customer.SetBalanceInsertCredit_Native (procedure)
+-- Maintenance.Feature (table)
+-- History.PositionFailWrite (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Read + UPDATE mirror equity/SL |
| Trade.PositionTbl | Table | Read + UPDATE position detachment |
| Trade.Position | View | Read position data with join info |
| Trade.PositionTreeInfo | Table | INSERT new tree record |
| Trade.PostDetachOperation | Table | INSERT post-detach queue entry |
| Customer.CustomerMoney | Table | Read customer financial data |
| Customer.SetBalanceInsertCredit_Native | Procedure | Record mirror detachment credit |
| Maintenance.Feature | Table | Read real/demo flag |
| History.PositionFailWrite | Table | Log failures |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.DetachPositionsByCountryAndInstrument | Stored Procedure | Wrapper that calls this per-position for batch detachment |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Note**: Uses extensive OUTPUT clauses to capture results into TVP table variables (@DetachPositionsFromMirror, @DetachPositionsFromMirrorPosition, @DetachPositionsFromMirrorTree). Returns a result set with position, tree, and hedge data for the caller.

---

## 8. Sample Queries

### 8.1 Find positions in a mirror relationship

```sql
SELECT  PositionID, CID, MirrorID, TreeID, ParentPositionID, IsSettled
FROM    Trade.PositionTbl WITH (NOLOCK)
WHERE   MirrorID = 12345
ORDER BY PositionID;
```

### 8.2 Check mirror state

```sql
SELECT  MirrorID, CID, RealizedEquity, Amount, IsActive, MirrorSL
FROM    Trade.Mirror WITH (NOLOCK)
WHERE   MirrorID = 12345;
```

### 8.3 View pending post-detach operations

```sql
SELECT  TOP 20 PCL_PositionID, PCL_CID, PCL_ChangeTypeID, PCL_Occurred
FROM    Trade.PostDetachOperation WITH (NOLOCK)
ORDER BY PCL_Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DetachPositionsFromMirror | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.DetachPositionsFromMirror.sql*
