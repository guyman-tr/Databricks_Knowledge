# Trade.UpdatePositionRedeemStatus

> Orchestrates a redeem status transition for a single open position by updating Billing.Redeem (via Billing.RedeemStatusUpdate), conditionally setting Trade.PositionTbl.RedeemStatus and RedeemID for pending/terminate states (IDs 1 and 20), and inserting a PositionChangeLog entry (ChangeTypeID 8 or 9) within a single transaction.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

"Redeeming" a position in eToro is the process by which a customer requests to convert their CFD position into actual stock ownership (or cancels that request). The redeem workflow has multiple status stages tracked in Billing.Redeem. This procedure handles the cross-schema orchestration: it updates the Billing-side status first, then conditionally updates the Trade-side position to reflect the new redeem state.

The two status IDs handled specially for the Trade.PositionTbl update are:
- **1 (Pending Redeem / Set)**: Sets RedeemStatus=1 and RedeemID on the position - marks it as actively in the redeem process
- **20 (Terminate Redeem)**: Sets RedeemStatus=0 and clears RedeemID - cancels the redeem request

All other status IDs (non-1/non-20) only update Billing.Redeem and return early without touching Trade.PositionTbl.

A PositionChangeLog entry is always inserted for the pending and terminate events (ChangeTypeID 9 for pending, 8 for terminate), preserving the audit trail of all position state changes.

---

## 2. Business Logic

### 2.1 Redeem Context Resolution

**What**: Before the update, the procedure looks up the current Redeem record and inherits context values not provided by the caller.

**Columns/Parameters Involved**: `Billing.Redeem.RedeemID`, `Billing.Redeem.RedeemReasonID`, `Billing.Redeem.Remark`

**Rules**:
- `@RedeemReasonID = IIF(@RedeemReasonID = 0, NULL, @RedeemReasonID)` - zero treated as NULL
- CTE: SELECT MAX(RedeemID) FROM Billing.Redeem WHERE PositionID = @PositionID -> gets latest RedeemID
- Inherits: `@RedeemReasonID = ISNULL(@RedeemReasonID, Billing.Redeem.RedeemReasonID)` - caller value overrides if provided
- Inherits: `@RedeemID = Billing.Redeem.RedeemID`
- Inherits: `@Remark = ISNULL(@Remark, Billing.Redeem.Remark)`
- If no Billing.Redeem row found (@@ROWCOUNT <> 1) -> RAISERROR(60112) - "Redeem not found"

### 2.2 Position Existence Check

**What**: Verifies the position is still open before proceeding.

**Columns/Parameters Involved**: `Trade.PositionTbl.StatusID`

**Rules**:
- `IF NOT EXISTS (SELECT * FROM Trade.PositionTbl WHERE PositionID = PositionID AND StatusID = 1)` -> RAISERROR(60113)
- StatusID = 1 = open position
- Note: The WHERE clause has a bug - `PositionID = PositionID` always evaluates to true (compares column to itself rather than to @PositionID parameter). This check is effectively always true and provides no real validation.

### 2.3 Billing.RedeemStatusUpdate Delegation

**What**: The actual Billing-side status update is delegated to Billing.RedeemStatusUpdate.

**Columns/Parameters Involved**: All parameters passed through

**Rules**:
- `EXEC Billing.RedeemStatusUpdate` called with all relevant parameters
- This updates Billing.Redeem.RedeemStatusID and related fields
- If RedeemStatusID is not 1 or 20 -> COMMIT and RETURN (no Trade.PositionTbl update needed)

### 2.4 Conditional PositionTbl Update

**What**: Only for RedeemStatusID = 1 (pending) and 20 (terminate) does the procedure update Trade.PositionTbl.

**Columns/Parameters Involved**: `Trade.PositionTbl.RedeemStatus`, `Trade.PositionTbl.RedeemID`

**Rules**:
- RedeemStatusID = 1 (pending): RedeemStatus = 1, RedeemID = @RedeemID
- RedeemStatusID = 20 (terminate): RedeemStatus = 0, RedeemID = NULL
- Partition-safe: `WHERE PositionID = @PositionID AND PartitionCol = @PositionID % 50`
- If @@ROWCOUNT <> 1 after UPDATE -> RAISERROR('Could not find position...')

### 2.5 ChangeTypeID for PositionChangeLog

**What**: The change type in the position change log reflects whether this is a pending start or a cancellation.

**Columns/Parameters Involved**: `@ChangeTypeID`, `History.PositionChangeLog_Insert`

**Rules**:
- RedeemStatusID = 1 -> ChangeTypeID = 9 (PositionRedeemPending)
- RedeemStatusID = 20 -> ChangeTypeID = 8 (PositionRedeemCancel)
- Called via `EXEC History.PositionChangeLog_Insert` with all position snapshot fields

### 2.6 Error Recovery for Closed Position

**What**: If RAISERROR(60113) fires (position not found as open), the catch block additionally updates Billing.Redeem to terminated status.

**Rules**:
- `IF ERROR_NUMBER() = 60113 -> UPDATE Billing.Redeem SET RedeemStatusID = 20 WHERE RedeemID = @RedeemID`
- Compensating action: if the Trade position doesn't exist, the billing record is auto-terminated to prevent orphaned redeem records

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID. Read from Trade.Position (overwritten by query) and passed to PositionChangeLog_Insert. |
| 2 | @PositionID | bigint | NO | - | CODE-BACKED | Target position. Used to look up Billing.Redeem (latest RedeemID), validate position existence, update Trade.PositionTbl (with partition routing), read state for PCL, and write PCL. |
| 3 | @RedeemStatusID | int | NO | - | CODE-BACKED | New redeem status to apply. Passed to Billing.RedeemStatusUpdate. Only 1 (pending) and 20 (terminate) trigger Trade.PositionTbl and PCL updates. Other values update billing only and return. |
| 4 | @SessionID | bigint | NO | - | CODE-BACKED | Session identifier. Available for the procedure but not explicitly used in the current code body (likely passed to Billing.RedeemStatusUpdate). |
| 5 | @RedeemID | int | YES | NULL | CODE-BACKED | Optional: the specific Redeem record to update. If NULL, resolved from MAX(Billing.Redeem.RedeemID) for the position. |
| 6 | @RedeemReasonID | int | YES | NULL | CODE-BACKED | Reason code for the redeem status change. Zero is converted to NULL. If NULL, inherited from existing Billing.Redeem row. |
| 7 | @Remark | varchar(500) | YES | NULL | CODE-BACKED | Free-text remark for the status change. If NULL, inherited from existing Billing.Redeem row. |
| 8 | @Units | decimal(16,6) | YES | NULL | CODE-BACKED | Optional units value for the redeem operation. |
| 9 | @NetProfit | money | YES | 0 | CODE-BACKED | Net profit context for the redeem operation. Default 0. |
| 10 | @ManagerID | int | YES | NULL | CODE-BACKED | Manager user ID for operations context. Passed to Billing.RedeemStatusUpdate. |
| 11 | @ManagerOpsId | int | YES | NULL | CODE-BACKED | Manager ops system ID. Passed to Billing.RedeemStatusUpdate. |
| 12 | @ClientRequestGuid | uniqueidentifier | YES | NULL | CODE-BACKED | Client correlation GUID passed to PositionChangeLog_Insert.ClientRequestGuid for traceability. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PositionID | Billing.Redeem | SELECT (read) | Looks up latest RedeemID + inherits RedeemReasonID and Remark |
| @PositionID | Trade.PositionTbl | Existence check + UPDATE | Checks StatusID=1 (open); sets RedeemStatus + RedeemID for states 1 and 20 |
| @PositionID | Trade.Position | SELECT (read) | Reads position snapshot fields for PCL entry |
| @RedeemStatusID | Billing.RedeemStatusUpdate | EXEC call | Billing-side status update; cross-schema delegation |
| @ChangeTypeID | History.PositionChangeLog_Insert | EXEC call | Inserts PCL entry; ChangeTypeID 9 = pending, 8 = cancel |
| On error 60113 | Billing.Redeem | UPDATE | Compensating action: auto-terminates billing record if position not found |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External redeem management service | Application call | Caller | No internal SP callers found; invoked from the redeem workflow service when processing redeem status transitions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdatePositionRedeemStatus (procedure)
|- Billing.Redeem (table) [READ - latest RedeemID lookup; WRITE on error-60113 compensation]
|- Trade.PositionTbl (table) [existence check + UPDATE - RedeemStatus, RedeemID]
|- Trade.Position (view) [READ - position snapshot for PCL]
|- Billing.RedeemStatusUpdate (procedure) [EXEC - billing-side status update]
+-- History.PositionChangeLog_Insert (procedure) [EXEC - PCL entry, ChangeTypeID 8 or 9]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | READ: MAX(RedeemID) lookup + inherit context; WRITE: auto-terminate on error 60113 |
| Trade.PositionTbl | Table | Existence check (StatusID=1) + UPDATE (RedeemStatus, RedeemID) |
| Trade.Position | View | READ: Position snapshot fields for PCL entry |
| Billing.RedeemStatusUpdate | Procedure | EXECuted: billing-side redeem status update |
| History.PositionChangeLog_Insert | Procedure | EXECuted: PCL entry for ChangeTypeID 8 (cancel) or 9 (pending) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Redeem workflow service | Application | Calls to transition position redeem state as part of the stock redemption workflow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RedeemID resolved from MAX | Design | Procedure looks up latest Billing.Redeem row; caller-provided @RedeemID is overwritten |
| Position check bug | Code issue | WHERE PositionID = PositionID (compares column to itself, not to @PositionID) - check is always true |
| Conditional PositionTbl update | Design | Only RedeemStatusIDs 1 and 20 trigger PositionTbl + PCL; all others update billing only and return |
| Compensation on error 60113 | Safety | Auto-terminates Billing.Redeem if position not found, preventing orphaned billing records |
| THROW on error | Catch | THROW re-raises after rollback (or commit for nested) |
| Partition routing | Pattern | PartitionCol = @PositionID % 50 used for both PositionTbl UPDATE and Position read |

---

## 8. Sample Queries

### 8.1 Set position to pending redeem

```sql
EXEC Trade.UpdatePositionRedeemStatus
    @CID = 12345,
    @PositionID = 100001,
    @RedeemStatusID = 1,     -- Pending redeem
    @SessionID = 9999,
    @RedeemID = NULL,        -- Will be resolved from Billing.Redeem
    @ClientRequestGuid = NULL
```

### 8.2 Terminate (cancel) a redeem request

```sql
EXEC Trade.UpdatePositionRedeemStatus
    @CID = 12345,
    @PositionID = 100001,
    @RedeemStatusID = 20,    -- Terminate redeem
    @SessionID = 9999,
    @Remark = 'Customer cancelled redeem request'
```

### 8.3 Check current redeem state of a position

```sql
SELECT
    pt.PositionID,
    pt.RedeemStatus,
    pt.RedeemID,
    br.RedeemStatusID,
    br.RedeemReasonID,
    br.Remark
FROM Trade.PositionTbl pt WITH (NOLOCK)
LEFT JOIN Billing.Redeem br WITH (NOLOCK) ON br.PositionID = pt.PositionID
WHERE pt.PositionID = 100001
AND pt.PartitionCol = 100001 % 50
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdatePositionRedeemStatus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdatePositionRedeemStatus.sql*
