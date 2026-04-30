# History.BackOfficeRedeemApproval

> Audit trail for the BackOffice multi-group withdrawal (redeem) approval workflow: records the previous state of BackOffice.RedeemApproval records when they are re-processed, preserving the old approval decision, manager, reason, and comment before the update. Active February 2023 to present.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ID (PK, INT IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (CLUSTERED PK) |

---

## 1. Business Meaning

History.BackOfficeRedeemApproval records the pre-update state of BackOffice redeem approval decisions. A "redeem" (customer withdrawal request) at eToro requires sign-off from multiple BackOffice teams before it is processed. Each team's decision is stored in `BackOffice.RedeemApproval` (one live record per redeem per UserGroup). When a team re-processes a redeem - changing their decision, updating the comment, or re-approving - the procedure `BackOffice.RedeemApprovalAdd` overwrites the live record and copies the OLD state here as an immutable history row.

**Three approval groups** are active in the data:
- **Operations** (UserGroupID=2): 8,169 history rows - primary processing team
- **Risk** (UserGroupID=3): 6,769 history rows - risk assessment team
- **AML** (UserGroupID=36): 1,090 history rows - anti-money laundering review

**The history mechanism**: `BackOffice.RedeemApprovalAdd` uses a `UPDATE ... OUTPUT DELETED.* INTO @Info` pattern to capture the old state before overwriting `BackOffice.RedeemApproval`, then inserts that captured old state into this table. This means:
- **First-time approvals** (new records inserted into BackOffice.RedeemApproval) do NOT generate history rows
- **Re-approvals / updates** to existing approval records generate one history row per change

**Why 99.9% Approved=1 in history**: When an approval record is being re-processed, the prior state was already approved (Approved=1) in virtually all cases. The 14 Approved=0 history rows represent the rare case where a pending/unapproved record was overwritten before it was finalized.

**Scale**: 16,028 rows, 240 distinct customers, 5 distinct managers. The small customer count (240) relative to the row count (16,028) indicates these are high-scrutiny redeems that cycle through multiple re-review events - averaging roughly 67 history rows per customer.

---

## 2. Business Logic

### 2.1 Redeem Approval Re-Processing Path (UPDATE...OUTPUT Pattern)

**What**: Captures the old approval state before overwriting, atomically within the same transaction as the update.

**Columns/Parameters Involved**: `ApprovedRedeemID`, `RedeemID`, `CID`, `UserGroupID`, `ManagerID`, `RedeemApprovalReasonID`, `Approved`, `Occurred`, `Comment`

**Rules**:
- Called via `BackOffice.RedeemApprovalAdd(@RedeemIDS, @UserGroupID, @ManagerID, @RedeemApprovalReasonID, @Approved, @Comment)`
- `@RedeemIDS` is a table-valued parameter `BackOffice.IDs` - allows batch approval of multiple redeems in one call
- Only processes redeems with `Billing.Redeem.RedeemStatusID IN (1,4,100)` (not already fully approved)
- For redeems that already have an approval record for this UserGroup: UPDATE the live record -> OUTPUT DELETED.* captures old state -> INSERT old state into this table
- For redeems with no existing record for this UserGroup: INSERT new live record -> NO history row (first-time approval is not historically tracked here)
- `Occurred` in the history row reflects the timestamp from the DELETED record (before the update), not the current time
- All three operations (UPDATE live, INSERT new live, INSERT history) occur within a single transaction; ROLLBACK on error

**Diagram**:
```
BackOffice team member re-approves redeem 789 (Operations group)
   |
   BackOffice.RedeemApprovalAdd(@RedeemIDS={789}, @UserGroupID=2, @ManagerID=42, @Approved=1, @Comment='Re-verified OK', @ReasonID=1)
   |
   Filter: RedeemStatusID IN (1,4,100) -> redeem 789 qualifies
   |
   BEGIN TRANSACTION
   UPDATE BackOffice.RedeemApproval
     OUTPUT DELETED.{ApprovedRedeemID=15, RedeemID=789, CID=101, UserGroupID=2, ManagerID=38, Approved=1, Occurred=2025-06-01, Comment='First approval'} INTO @Info
   SET ManagerID=42, Comment='Re-verified OK', Occurred=GETUTCDATE()
   WHERE RedeemID=789 AND UserGroupID=2
   |
   INSERT History.BackOfficeRedeemApproval FROM @Info:
   -> {ID=auto, ApprovedRedeemID=15, RedeemID=789, CID=101, UserGroupID=2,
       ManagerID=38, Approved=1, Occurred=2025-06-01, Comment='First approval'}
   COMMIT
```

### 2.2 Multi-Group Approval Chain

**What**: Each redeem requires independent approval decisions from each relevant BackOffice team.

**Rules**:
- `BackOffice.RedeemApproval` has one live record per (RedeemID, UserGroupID) combination
- A given redeem may have separate approval rows for Operations, Risk, and AML groups
- This history table logs changes across all three groups (identified by UserGroupID)
- `RedeemApprovalReasonID=1` ("Other") is the only reason code in use - the free-text Comment field carries the actual reasoning

### 2.3 RedeemApprovalReason Values

**What**: Lookup table for standardized approval reason codes.

| RedeemApprovalReasonID | Name |
|---|---|
| 1 | Other |

Only one reason exists in Dictionary.RedeemApprovalReason. All 16,028 rows use RedeemApprovalReasonID=1. The Comment field (VARCHAR(MAX)) carries the substantive reasoning.

---

## 3. Data Overview

16,028 rows, February 2023 to January 2026. 240 distinct customers. 5 managers made re-approval decisions. UserGroupID distribution: Operations (51%), Risk (42%), AML (7%). RedeemApprovalReasonID=1 (Other) for 100% of rows. Approved=1 for 99.9% of rows.

| ID | ApprovedRedeemID | RedeemID | CID | UserGroupID | ManagerID | Approved | Occurred | Meaning |
|---|---|---|---|---|---|---|---|---|
| 1 | 15 | 789 | 101 | 2 | 38 | 1 | 2023-02-15 | Old state of Operations approval for redeem 789. Previously approved by manager 38. Now being overwritten by a re-approval from manager 42. |
| (typical) | (any) | (any) | (any) | 3 | (any) | 1 | (current) | Risk group re-approval. Old state was already approved. 42% of all history rows are Risk group re-approvals. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | IDENTITY(1,1) | CODE-BACKED | Surrogate PK. Auto-generated IDENTITY, NOT FOR REPLICATION (independent sequence per replica). Clustered PK on PRIMARY filegroup. |
| 2 | ApprovedRedeemID | int | NO | - | CODE-BACKED | PK value from BackOffice.RedeemApproval at the time of the UPDATE. Identifies which live approval record was overwritten. Not a FK (historical snapshot). Together with RedeemID + UserGroupID uniquely identifies the approval event. |
| 3 | RedeemID | int | NO | - | CODE-BACKED | The withdrawal request ID being approved. References Billing.Redeem. Links this history row to the specific customer withdrawal. Multiple rows may exist for the same RedeemID across different UserGroups and over time. |
| 4 | CID | int | NO | - | CODE-BACKED | Customer ID of the customer who requested the withdrawal. 240 distinct values. No FK constraint - historical snapshot. |
| 5 | UserGroupID | int | NO | - | CODE-BACKED | The BackOffice team that owns this approval. FK to Dictionary.UserGroup. Values: 2=Operations (8,169 rows, 51%), 3=Risk (6,769 rows, 42%), 36=AML (1,090 rows, 7%). |
| 6 | ManagerID | int | NO | - | CODE-BACKED | The BackOffice manager who held the approval decision in the OLD state (before the update). FK to BackOffice.Manager. This is the manager whose decision is being replaced. 5 distinct values across all history. |
| 7 | RedeemApprovalReasonID | int | NO | - | CODE-BACKED | Standardized reason code for the approval decision. FK to Dictionary.RedeemApprovalReason. Only value in use: 1=Other. The actual reason is captured in the Comment field. |
| 8 | Approved | bit | NO | - | CODE-BACKED | Approval decision in the OLD state: 1=Approved, 0=Not approved. In 16,014 rows (99.9%) the old state was Approved=1 (approved record being re-approved). Only 14 rows show Approved=0 (unapproved record being overwritten). |
| 9 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Timestamp from the OLD approval record (DELETED.Occurred from the UPDATE OUTPUT). Reflects when the prior approval decision was recorded, NOT the time of the history insert. Default GETDATE() applies only if NULL was somehow passed. |
| 10 | Comment | varchar(max) | NO | - | CODE-BACKED | Free-text reasoning from the OLD approval decision. Preserved from the BackOffice.RedeemApproval record before it was overwritten. VARCHAR(MAX) supports detailed compliance commentary. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| UserGroupID | Dictionary.UserGroup | FK (FK_DUGR_HBRAP) | The BackOffice team group (Operations, Risk, AML). |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HBRAP) | The manager who held the decision being replaced. |
| RedeemApprovalReasonID | Dictionary.RedeemApprovalReason | FK (FK_DRAP_HBRAP) | Standard reason code for the approval decision. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.RedeemApprovalAdd | INSERT (from UPDATE OUTPUT) | Writer | Sole writer - captures old state of BackOffice.RedeemApproval before overwrite. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.BackOfficeRedeemApproval (table)
  - leaf node: no code-level dependencies
  - written by: BackOffice.RedeemApprovalAdd (UPDATE OUTPUT -> history)
  - mirrors: BackOffice.RedeemApproval (live approval state)
```

### 6.1 Objects This Depends On

No code-level dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RedeemApprovalAdd | Stored Procedure | Writer - inserts old approval state via UPDATE OUTPUT pattern |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HistoryBackOfficeRedeemApproval | CLUSTERED PK | ID ASC | - | - | Active |

**Note**: No index on RedeemID, CID, or UserGroupID. Queries filtering by these columns require full scans. At 16K rows, this is not a performance concern, but would become one if the table grows significantly.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HistoryBackOfficeRedeemApproval | PRIMARY KEY CLUSTERED | ID - surrogate PK |
| BAPR_OCCURRED | DEFAULT | Occurred = GETDATE() (fallback; actual value comes from OUTPUT DELETED.Occurred) |
| FK_BMNG_HBRAP | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DRAP_HBRAP | FOREIGN KEY | RedeemApprovalReasonID -> Dictionary.RedeemApprovalReason(RedeemApprovalReasonID) |
| FK_DUGR_HBRAP | FOREIGN KEY | UserGroupID -> Dictionary.UserGroup(UserGroupID) |
| NOT FOR REPLICATION on ID | Identity option | Independent IDENTITY per replica |

---

## 8. Sample Queries

### 8.1 Full re-approval history for a specific withdrawal
```sql
SELECT
    h.ID,
    h.Occurred AS PreviousDecisionTime,
    h.UserGroupID,
    ug.[Name] AS UserGroup,
    h.ManagerID,
    h.Approved AS PreviousApproved,
    h.Comment AS PreviousComment
FROM History.BackOfficeRedeemApproval h WITH (NOLOCK)
INNER JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON h.UserGroupID = ug.UserGroupID
WHERE h.RedeemID = @RedeemID
ORDER BY h.Occurred ASC;
```

### 8.2 Recent re-approval activity by group
```sql
SELECT
    ug.[Name] AS UserGroup,
    h.ManagerID,
    COUNT(*) AS ReApprovals,
    MAX(h.Occurred) AS LastActivity
FROM History.BackOfficeRedeemApproval h WITH (NOLOCK)
INNER JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON h.UserGroupID = ug.UserGroupID
WHERE h.Occurred >= DATEADD(day, -30, GETDATE())
GROUP BY ug.[Name], h.ManagerID
ORDER BY ReApprovals DESC;
```

### 8.3 Customers with most re-approval events (high scrutiny)
```sql
SELECT TOP 20
    CID,
    COUNT(*) AS TotalReApprovals,
    COUNT(DISTINCT RedeemID) AS UniqueRedeems,
    MAX(Occurred) AS LastActivity
FROM History.BackOfficeRedeemApproval WITH (NOLOCK)
GROUP BY CID
ORDER BY TotalReApprovals DESC;
```

---

## 9. Atlassian Knowledge Sources

No directly relevant Atlassian pages found for this specific table. Related operational pages found:
- "AML-OPS Monitoring Procedure" (Confluence 905216142) - references AML/Operations approval workflows
- "Risk: Follow-up and account closure" (Confluence 900530561) - references Risk group redeem review

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.BackOfficeRedeemApproval | Type: Table | Source: etoro/etoro/History/Tables/History.BackOfficeRedeemApproval.sql*
