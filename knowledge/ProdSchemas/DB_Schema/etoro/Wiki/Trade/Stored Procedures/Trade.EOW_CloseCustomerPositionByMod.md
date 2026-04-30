# Trade.EOW_CloseCustomerPositionByMod

> DISABLED (returns 0 immediately). Legacy end-of-week position close procedure that processed customer positions in modular batches for weekend fee settlement.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Mod / @ModResults for batch partitioning |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure was part of the legacy end-of-week (EOW) fee settlement system. It closed customer positions that were flagged for weekend closure (`CloseOnEndOfWeek = 1`), distributing the workload across parallel executions using a modular arithmetic partitioning scheme (CID % @Mod = @ModResults). The procedure has been **permanently disabled** - it immediately returns 0 with the comment "Yitzchak RO Fee Disable Old EOW Fees".

When active, the procedure existed because certain positions (likely leveraged CFD positions) incurred weekend holding fees. Rather than charging the fee, the old approach was to close these positions before the weekend and allow customers to reopen Monday. This pattern was superseded by the "RO Fee" (rollover fee) system that charges fees directly without closing positions.

The procedure first processed positions with `CloseOnEndOfWeek = 1` (positions to be closed), then processed positions with `CloseOnEndOfWeek = 0` (positions carried over the weekend). For each customer, it called `Trade.CloseCustomerOpenPositions` and collected CIDs. After all processing, it sent a batch notification via `Customer.SendMessage` with MessageTypeID 5 (for ActionType 2) or 8 (for other action types).

---

## 2. Business Logic

### 2.1 Disabled - Legacy EOW Processing

**What**: Entire procedure logic is unreachable due to `RETURN 0` on line 16.

**Columns/Parameters Involved**: All parameters

**Rules**:
- `RETURN 0` executes immediately, bypassing all cursor and processing logic
- Comment indicates this was disabled as part of the "RO Fee" migration that replaced position-closing weekend fees with direct rollover fee charges

### 2.2 Modular Batch Partitioning (Historical)

**What**: Distributed processing across parallel job instances using CID modular arithmetic.

**Columns/Parameters Involved**: `@Mod`, `@ModResults`

**Rules**:
- Positions filtered by `CID % @Mod = @ModResults` to enable parallel processing
- Default: @Mod=1, @ModResults=0 (processes all CIDs in a single pass)
- For parallel execution: @Mod=4 with @ModResults=0,1,2,3 across four jobs distributes load by CID
- Two cursors: first closes positions flagged for closure, then processes weekend-carry positions

### 2.3 Post-Processing Notification (Historical)

**What**: Sent batch customer notification after all positions processed.

**Columns/Parameters Involved**: `@CIDASSTR`, `@MessageTypeID`, `@ActionType`

**Rules**:
- Collected all processed CIDs in a semicolon-delimited string
- MessageTypeID = 5 when ActionType = 2 (standard close), MessageTypeID = 8 otherwise
- Sent via Customer.SendMessage with semicolon delimiter

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ActionType | int | NO | 2 | CODE-BACKED | Close action type passed to Trade.CloseCustomerOpenPositions. Default 2 = standard close. Determines MessageTypeID for notification: 2->5, other->8. |
| 2 | @CloseAll | bit | NO | 1 | CODE-BACKED | Whether to close all positions for the customer. Passed through to Trade.CloseCustomerOpenPositions. Default 1 = close all eligible positions. |
| 3 | @Mod | tinyint | NO | 1 | CODE-BACKED | Modular divisor for CID-based batch partitioning. CID % @Mod = @ModResults determines which customers this instance processes. Default 1 = process all CIDs. |
| 4 | @ModResults | tinyint | NO | 0 | CODE-BACKED | Modular remainder for CID-based batch partitioning. Combined with @Mod to partition customer processing across parallel job instances. Default 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FROM | Trade.Position (view) | READER | Reads open positions with CloseOnEndOfWeek flag (code unreachable) |
| EXEC | Trade.CloseCustomerOpenPositions | Caller | Closes positions for each CID (code unreachable) |
| EXEC | Customer.SendMessage | Caller | Sends batch notification after processing (code unreachable) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Not analyzed in this phase. | - | - | Likely called by SQL Agent Job for end-of-week processing (now disabled) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.EOW_CloseCustomerPositionByMod (procedure) [DISABLED]
+-- Trade.Position (view) [unreachable]
+-- Trade.CloseCustomerOpenPositions (procedure) [unreachable]
+-- Customer.SendMessage (procedure) [unreachable]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Position | View | SELECT with cursor - reads CIDs with CloseOnEndOfWeek flag (unreachable) |
| Trade.CloseCustomerOpenPositions | Stored Procedure | EXEC - closes positions per CID (unreachable) |
| Customer.SendMessage | Stored Procedure | EXEC - sends batch notification (unreachable) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

**Status**: DISABLED. `RETURN 0` at line 16 prevents all logic from executing. Candidate for removal if the RO Fee system is permanent.

**Performance Note (Historical)**: Uses cursors (LOCAL READ_ONLY FORWARD_ONLY) for row-by-row processing. The modular partitioning (@Mod/@ModResults) was the mechanism for parallelizing this cursor-based approach across multiple SQL Agent Job steps.

---

## 8. Sample Queries

### 8.1 Verify Procedure is Disabled

```sql
DECLARE @Result INT
EXEC @Result = Trade.EOW_CloseCustomerPositionByMod
SELECT @Result AS ReturnValue
-- Returns 0 immediately (disabled)
```

### 8.2 Check for Positions Flagged for Weekend Close (Historical)

```sql
SELECT CID,
       COUNT(*) AS PositionCount,
       SUM(CAST(CloseOnEndOfWeek AS INT)) AS CloseOnWeekend,
       SUM(1 - CAST(CloseOnEndOfWeek AS INT)) AS CarryOverWeekend
  FROM Trade.Position WITH (NOLOCK)
 GROUP BY CID
HAVING SUM(CAST(CloseOnEndOfWeek AS INT)) > 0
 ORDER BY PositionCount DESC
```

### 8.3 View CloseOnEndOfWeek Distribution

```sql
SELECT CloseOnEndOfWeek,
       COUNT(*) AS PositionCount
  FROM Trade.Position WITH (NOLOCK)
 GROUP BY CloseOnEndOfWeek
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.EOW_CloseCustomerPositionByMod | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.EOW_CloseCustomerPositionByMod.sql*
