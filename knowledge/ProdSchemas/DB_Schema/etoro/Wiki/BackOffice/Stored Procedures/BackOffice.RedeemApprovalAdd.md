# BackOffice.RedeemApprovalAdd

> Upserts multi-group approval decisions for eligible crypto redemption requests: updates existing group approvals (logging old values to history) and inserts new group approvals, using a TVP of RedeemIDs and TRY/CATCH for atomicity.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | UPSERT BackOffice.RedeemApproval via TVP @RedeemIDS BackOffice.IDs READONLY; filter Billing.Redeem WHERE RedeemStatusID IN (1,4,100); INSERT History.BackOfficeRedeemApproval |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`BackOffice.RedeemApprovalAdd` records or updates a manager's group approval decision for one or more crypto redemption requests simultaneously. In eToro's redeem workflow, a customer's withdrawal request (Billing.Redeem) must be approved by multiple internal user groups (Operations, Risk, etc.) before it can proceed. This procedure is the write endpoint for those group decisions.

The procedure accepts a batch of RedeemIDs via a Table-Valued Parameter (TVP) of type `BackOffice.IDs`. For each RedeemID, it:
1. Validates the redeem is in an approvable status (1=PositionPending, 4=ReadyToRedeem, 100=New).
2. If this group has already submitted a decision, updates the existing row and logs the old values to History.
3. If this is the first decision from this group, inserts a new row and logs it to History.

The full UPSERT-with-history pattern ensures an audit trail of every approval decision, including changes and reversals. Wrapped in TRY/CATCH with THROW for error propagation.

---

## 2. Business Logic

### 2.1 Approvable Status Filter

**What**: Only redeems in specific statuses are eligible for approval actions.

**Rules**:
- `WHERE Billing.Redeem.RedeemStatusID IN (1, 4, 100)`: allowed states are PositionPending (1), ReadyToRedeem (4), and New (100).
- RedeemIDs in other statuses (Approved=3, PositionClosing=5, Terminated=20, etc.) are silently excluded - no error raised.
- This prevents retroactive approval of already-processed or cancelled redeems.

### 2.2 UPSERT Pattern with History Logging

**What**: Separate UPDATE (existing group approvals) and INSERT (new group approvals) paths, both with history capture.

**Rules**:
- **UPDATE path**: For (RedeemID, UserGroupID) pairs that already exist in BackOffice.RedeemApproval:
  - Uses OUTPUT clause (or @Info table variable) to capture the OLD column values before overwriting.
  - Updates Approved, ManagerID, RedeemApprovalReasonID, Occurred to new values.
  - Inserts the OLD values from @Info into History.BackOfficeRedeemApproval (preserving the before-state for audit).
- **INSERT path**: For (RedeemID, UserGroupID) pairs that do NOT exist in BackOffice.RedeemApproval (LEFT JOIN WHERE IS NULL pattern):
  - Inserts new row into BackOffice.RedeemApproval.
  - Inserts the same new row into History.BackOfficeRedeemApproval (logs the initial approval event).
- After all upserts, an @Info table holds all inserted/updated rows for consolidated history insertion.

### 2.3 Batch TVP Input

**What**: Accepts multiple RedeemIDs in a single call via Table-Valued Parameter.

**Rules**:
- `@RedeemIDS BackOffice.IDs READONLY`: the BackOffice.IDs TVP type is a single-column table (ID INT or BIGINT). READONLY means the procedure cannot modify the TVP contents.
- Batch processing: all RedeemIDs are processed in a single set-based operation, not a cursor.
- Empty TVP: if @RedeemIDS is empty, 0 rows are affected (no error).

### 2.4 Error Handling

**What**: TRY/CATCH wrapper with THROW for full error propagation.

**Rules**:
- Any error during UPDATE, INSERT, or History logging is caught and re-thrown to the caller.
- No partial commits: if the second INSERT (new approvals) fails after the first UPDATE succeeded, the THROW causes the caller's transaction to roll back (if the caller has an open transaction).
- No explicit BEGIN TRANSACTION inside the SP - relies on caller to manage transaction boundaries if needed.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @RedeemIDS | BackOffice.IDs (TVP) | NO | - | CODE-BACKED | Table-valued parameter containing the list of RedeemIDs to approve. BackOffice.IDs is a single-column TVP (INT or BIGINT). READONLY - procedure cannot modify it. Filters against Billing.Redeem WHERE RedeemStatusID IN (1,4,100). |
| 2 | @UserGroupID | int | NO | - | CODE-BACKED | The approval group making this decision. FK to Dictionary.UserGroup. Known approval groups: 2=Operations, 3=Risk, 36=(unknown internal group). Each group gets its own approval row per RedeemID. |
| 3 | @ManagerID | int | NO | - | CODE-BACKED | The manager recording this approval decision. FK to BackOffice.Manager.ManagerID. Stored in BackOffice.RedeemApproval.ManagerID. |
| 4 | @RedeemApprovalReasonID | int | YES | - | CODE-BACKED | Reason code for the approval/rejection decision. FK to a reason lookup table. Known value: 1=Other (most common). May be NULL for system-initiated approvals. |
| 5 | @Approved | bit | NO | - | CODE-BACKED | 1=Approved, 0=Rejected. The group's decision for all redeems in this batch. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Status filter | Billing.Redeem | Reader | Filters RedeemIDs to only those in approvable statuses (1, 4, 100) |
| UPDATE path | BackOffice.RedeemApproval | Writer | Updates existing group approval records; captures old values via OUTPUT |
| INSERT path | BackOffice.RedeemApproval | Writer | Inserts new group approval records (LEFT JOIN WHERE IS NULL) |
| History | History.BackOfficeRedeemApproval | Writer | Logs all approval decisions (old values for updates, new values for inserts) |

### 5.2 Referenced By (other objects point to this)

No SQL-layer callers found. Called from BackOffice approval workflow UI when managers submit group approval decisions for crypto redemptions.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.RedeemApprovalAdd (procedure)
+-- BackOffice.IDs (TVP type) [READONLY input parameter]
+-- Billing.Redeem (table) [SELECT - status filter]
+-- BackOffice.RedeemApproval (table) [UPDATE + INSERT - upsert target]
+-- History.BackOfficeRedeemApproval (table) [INSERT - audit log]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.IDs | TVP Type | Input parameter type - list of RedeemIDs to process |
| Billing.Redeem | Table | SELECT - filters RedeemIDs by RedeemStatusID IN (1,4,100) |
| BackOffice.RedeemApproval | Table | UPDATE existing + INSERT new approval records (upsert) |
| History.BackOfficeRedeemApproval | Table | INSERT - logs before/after state of every approval action |

### 6.2 Objects That Depend On This

No SQL-layer dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BackOffice.IDs TVP | Parameter Type | Requires BackOffice.IDs TVP type to exist on the server. READONLY prevents modification inside the SP. |
| Status filter | Business Rule | Only RedeemStatusID IN (1,4,100) redeems are processed. Others silently excluded. |
| UPSERT guard | LEFT JOIN IS NULL | Detects new vs existing group approvals without a MERGE statement, avoiding MERGE locking issues. |
| TRY/CATCH + THROW | Error Handling | Propagates any error to caller; no silent failure. |

---

## 8. Sample Queries

### 8.1 Approve multiple redeems for Operations group

```sql
-- Create TVP with RedeemIDs to approve
DECLARE @RedeemIDs BackOffice.IDs;
INSERT INTO @RedeemIDs VALUES (40018), (40005), (39987);

EXEC BackOffice.RedeemApprovalAdd
    @RedeemIDS = @RedeemIDs,
    @UserGroupID = 2,          -- Operations
    @ManagerID = 969,
    @RedeemApprovalReasonID = 1, -- Other
    @Approved = 1;             -- Approved
```

### 8.2 Reject a single redeem for Risk group

```sql
DECLARE @RedeemIDs BackOffice.IDs;
INSERT INTO @RedeemIDs VALUES (40021);

EXEC BackOffice.RedeemApprovalAdd
    @RedeemIDS = @RedeemIDs,
    @UserGroupID = 3,          -- Risk
    @ManagerID = 969,
    @RedeemApprovalReasonID = 1,
    @Approved = 0;             -- Rejected
```

### 8.3 Check approval status for a redeem

```sql
SELECT r.RedeemID, r.RedeemStatusID,
       ra.UserGroupID, ra.ManagerID, ra.Approved, ra.Occurred
FROM Billing.Redeem r WITH (NOLOCK)
LEFT JOIN BackOffice.RedeemApproval ra WITH (NOLOCK) ON ra.RedeemID = r.RedeemID
WHERE r.RedeemID = 40018
ORDER BY ra.UserGroupID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (DDL, Proc Ref Scan, Atlassian, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RedeemApprovalAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.RedeemApprovalAdd.sql*
