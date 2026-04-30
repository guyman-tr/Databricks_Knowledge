# Billing.SetRedeemStatus

> Bulk direct-update of Redeem status for a batch of RedeemIDs supplied via a table-valued parameter, bypassing the state machine enforced by Billing.RedeemStatusUpdate - intended for back-office or operational override scenarios.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk UPDATE Billing.Redeem via dbo.IdList TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

In the eToro redemption (cashout) lifecycle, status transitions are normally governed by the `Billing.RedeemStatusUpdate` procedure which enforces `Dictionary.RedeemStatusStateMachine` rules - ensuring that only valid state transitions occur (e.g., Pending -> Approved but not Pending -> Completed directly). `Billing.SetRedeemStatus` deliberately bypasses this state machine.

This procedure is a back-office power tool: it accepts a batch of RedeemIDs via the `dbo.IdList` table-valued parameter and sets them ALL to any target `RedeemStatusID` unconditionally, without validating whether the transition is legal per the state machine. It also conditionally updates `RedeemReasonID` and `Remark` (only overwriting if non-NULL supplied), and updates `ManagerOpsID` to record which operations manager made the change (preserving existing value if NULL passed).

Typical use cases: mass status correction after a processing error, manual override by the BO/Ops team, bulk cancellation, or resolving a backlog after a system failure.

**Contrast with `Billing.RedeemStatusUpdate`**: That procedure enforces state machine rules, processes one record at a time (or set via TVP), and logs the transition. `Billing.SetRedeemStatus` is a blunt instrument - no state validation, no logging, just a bulk UPDATE.

---

## 2. Business Logic

### 2.1 Bulk Status Override

**What**: Unconditional bulk UPDATE of Billing.Redeem for all RedeemIDs in the supplied @Ids list.

**Columns/Parameters Involved**: `@Ids`, `@RedeemStatusID`, `@RedeemReasonID`, `@OpsManagerId`, `@Remark`

**Rules**:
- No precondition check. No state machine validation. Any RedeemStatusID can be set regardless of current status.
- UPDATE Billing.Redeem WHERE RedeemID IN (SELECT CID FROM @Ids).
  - Note: `dbo.IdList` uses a column named `CID` as its generic ID column; it contains RedeemIDs here.
- RedeemStatusID is always overwritten with @RedeemStatusID (no ISNULL protection - passing NULL would null out the status).
- RedeemReasonID is always overwritten (NULL clears it if NULL passed).
- ManagerOpsID = ISNULL(@OpsManagerId, ManagerOpsID) - preserves existing value if NULL passed.
- Remark = ISNULL(@Remark, Remark) - preserves existing value if NULL passed.
- No return value; no @@rowcount output.

**dbo.IdList TVP**: Table type with a single column named `CID` (generic integer ID column). Used across multiple Billing procedures for batch input. Caller populates the TVP with RedeemIDs before calling this procedure.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Ids | dbo.IdList READONLY | NO | - | CODE-BACKED | Table-valued parameter containing the RedeemIDs to update. Column named 'CID' (generic ID column in dbo.IdList type). Pass one row per RedeemID to bulk-update. |
| 2 | @OpsManagerId | INT | YES | NULL | CODE-BACKED | Operations manager ID authorizing this override. If NULL, preserves the existing ManagerOpsID value (ISNULL pattern). Used for audit trail. |
| 3 | @RedeemStatusID | INT | NO | - | CODE-BACKED | Target status to set on ALL matched records. Required. No state machine validation - any value accepted. See Dictionary.RedeemStatus for valid values. |
| 4 | @RedeemReasonID | INT | YES | NULL | CODE-BACKED | Reason code for the status change. If NULL, clears the existing RedeemReasonID (no ISNULL protection on this column). |
| 5 | @Remark | VARCHAR(500) | YES | NULL | CODE-BACKED | Free-text comment about the reason for this override. If NULL, preserves the existing Remark value (ISNULL pattern). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Batch input | dbo.IdList | TVP parameter type | Table-valued parameter type used for RedeemID list input |
| Redeem records | Billing.Redeem | UPDATE | Direct bulk status update; no state machine check |

### 5.2 Referenced By (other objects point to this)

No SQL callers found. Called by back-office or operations tooling for manual status overrides.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.SetRedeemStatus (procedure)
├── dbo.IdList (user defined type) - TVP for batch input
└── Billing.Redeem (table) - UPDATE target
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.IdList | User Defined Type (TVP) | Accepts batch of RedeemIDs as table parameter |
| Billing.Redeem | Table | Direct UPDATE target for status, reason, manager, remark |

### 6.2 Objects That Depend On This

No SQL dependents.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No state machine | Design | Unlike Billing.RedeemStatusUpdate, no Dictionary.RedeemStatusStateMachine validation. Any -> Any status transition is permitted. |
| RedeemReasonID NULL passthrough | Risk | NULL @RedeemReasonID CLEARS the existing RedeemReasonID (not ISNULL-protected). |
| @RedeemStatusID required | No default | Must be supplied. No default value. Passing NULL will set RedeemStatusID=NULL on all matched rows. |
| dbo.IdList.CID column | Naming | The generic ID column in dbo.IdList is named 'CID' even when containing RedeemIDs. |
| SET NOCOUNT ON | Performance | Suppresses row count messages from the UPDATE statement. |
| No return value | Behavior | No @@rowcount output. Caller has no confirmation of how many rows were updated. |

---

## 8. Sample Queries

### 8.1 Bulk-cancel a list of redeems (back-office override)

```sql
DECLARE @Ids dbo.IdList
INSERT INTO @Ids (CID) VALUES (100001), (100002), (100003)

EXEC Billing.SetRedeemStatus
    @Ids = @Ids,
    @RedeemStatusID = 10,    -- Cancelled (example value)
    @RedeemReasonID = 5,     -- Fraud/error reason code
    @OpsManagerId = 9001,
    @Remark = 'Bulk cancel per fraud review 2026-03-18'
```

### 8.2 Check valid status values

```sql
SELECT RedeemStatusID, Name
FROM Dictionary.RedeemStatus WITH (NOLOCK)
ORDER BY RedeemStatusID
```

### 8.3 Compare with state-machine-enforced update

```sql
-- State machine enforced (normal flow):
EXEC Billing.RedeemStatusUpdate
    @RedeemID = 100001,
    @NewStatusID = 5,
    @ManagerOpsID = 9001

-- Direct override (bypasses state machine):
DECLARE @Ids dbo.IdList
INSERT INTO @Ids (CID) VALUES (100001)
EXEC Billing.SetRedeemStatus
    @Ids = @Ids,
    @RedeemStatusID = 5,
    @OpsManagerId = 9001
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.2/10 (Elements: 9/10, Logic: 8/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 8, 9B-skipped, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: skipped | Corrections: 0 applied*
*Object: Billing.SetRedeemStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.SetRedeemStatus.sql*
