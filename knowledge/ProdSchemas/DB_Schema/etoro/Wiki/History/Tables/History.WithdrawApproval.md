# History.WithdrawApproval

> Audit trail of superseded withdrawal approval decisions - each row captures the previous state of a back-office group's approval record for a withdrawal, written when that group's approval is updated or reversed.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | LineID (INT, IDENTITY, CLUSTERED PK) |
| **Partition** | No - stored on [MAIN] filegroup |
| **Indexes** | 6 active (CLUSTERED PK on LineID, NC on ApprovedWithdrawID, NC on ManagerID, NC on WithdrawApprovalReasonID, NC on UserGroupID, NC on WithdrawID) |

---

## 1. Business Meaning

History.WithdrawApproval is the change-history table for BackOffice.WithdrawApproval - the multi-group approval gate that controls when a withdrawal request is released for payment processing.

eToro's withdrawal approval workflow requires sign-off from multiple back-office user groups before a withdrawal can be released. Depending on the withdrawal amount (thresholds configured in Maintenance.Feature XML settings), approvals may be required from Administrators (group 1), Risk (group 3), Marketing (group 4), and Trading (group 6). Each group has one approval record per withdrawal in BackOffice.WithdrawApproval; when a group changes its decision (e.g., initially rejected then later approved, or reason code updated), the old record is captured here via the OUTPUT DELETED clause before the update is applied.

With 29,243 rows spanning 2008 to 2026, this table provides compliance-grade evidence of who changed their approval decisions and when - critical for investigating disputed withdrawals or auditing the multi-group approval process.

**Key architectural note**: History.WithdrawApproval records UPDATES only - initial approval inserts by a group for a new withdrawal are NOT recorded here (no prior state to capture). Only when a group's existing approval record is overwritten does a history row appear. This means the absence of a history row for a (WithdrawID, UserGroupID) pair is normal - it means that group approved exactly once without revision.

---

## 2. Business Logic

### 2.1 Multi-Group Approval Workflow

**What**: Each withdrawal needing manual approval requires sign-off from multiple back-office user groups. History records when any group revises its approval record.

**Columns/Parameters Involved**: `WithdrawID`, `UserGroupID`, `Approved`, `ManagerID`, `WithdrawApprovalReasonID`, `Comment`

**Rules**:
- BackOffice.WithdrawApproval holds ONE row per (WithdrawID, UserGroupID) pair - the current approval state for that group
- When a group's approval record is updated (via MERGE WHEN MATCHED or explicit UPDATE), the previous state is OUTPUT DELETED into History.WithdrawApproval
- When all required groups have approved (Approved=1), BackOffice.WithdrawApprovalAdd automatically calls BackOffice.WithdrawRequestApprove to trigger payment processing
- Amount thresholds (from Maintenance.Feature XML) determine which groups must approve:
  - `WithdrawAdminApprovalFrom` -> Administrators (UserGroupID=1) required above this amount
  - `WithdrawRiskApprovalFrom` -> Risk (UserGroupID=3) required above this amount
  - `WithdrawMarketingApprovalFrom` -> Marketing (UserGroupID=4) required (unless customer is non-affiliate)
  - `WithdrawTradingApprovalFrom` -> Trading (UserGroupID=6) required above this amount
- ManagerID=0 means automated system approval; ManagerID>0 means a specific back-office manager acted

**Diagram**:
```
Withdrawal arrives -> BackOffice.WithdrawApproval gets one row per required group:
  (WithdrawID=5000, UserGroupID=1, Approved=0, ReasonID=1)  <- Administrators: pending
  (WithdrawID=5000, UserGroupID=3, Approved=0, ReasonID=1)  <- Risk: pending

Risk manager reviews and approves:
  UPDATE BackOffice.WithdrawApproval
  OUTPUT DELETED.* INTO History.WithdrawApproval   <- captures old Approved=0 state
  SET Approved=1, ManagerID=734

Admin then approves:
  -> Auto-triggers BackOffice.WithdrawRequestApprove
  -> Withdrawal moves to payment processing
```

### 2.2 User Group Distribution in History

**What**: The UserGroupID identifies which back-office team's approval record was superseded.

**Columns/Parameters Involved**: `UserGroupID`

**Distribution** (from 29,243 rows):
| UserGroupID | Group Name | Count | Pct | Notes |
|-------------|-----------|-------|-----|-------|
| 3 | Risk | 14,901 | 51% | Most frequent revision - risk teams update conditions |
| 1 | Administrators | 11,382 | 39% | Second most frequent |
| 6 | Trading | 1,920 | 7% | Trading group revisions |
| 5 | Accounting | 1,040 | 4% | Accounting reviews |

### 2.3 Approval Reason Values

**What**: WithdrawApprovalReasonID categorizes why a group flagged or held a withdrawal - the "reason for review" rather than a final decision reason.

**Columns/Parameters Involved**: `WithdrawApprovalReasonID`

**Values** (from Dictionary.WithdrawApprovalReason):
| ID | Name | Count | Pct |
|----|------|-------|-----|
| 7 | Other | 25,418 | 87% |
| 10 | CO Form | 1,116 | 4% |
| 8 | CC Docs | 628 | 2% |
| 2 | Bonus Abusing | 536 | 2% |
| 1 | Awaiting Documents | 468 | 2% |
| 3 | Zero Lots Activity | 263 | 1% |
| 9 | PP Docs | 261 | 1% |
| 13 | Copy of Missing CC | 237 | 1% |
| 12 | Copy of Missing Utility Bill | 209 | 1% |
| 16 | Documents - Other | 45 | <1% |
| 11 | Better Copy of Documents | 29 | <1% |
| 6 | Scalper Trader | 15 | <1% |
| 5 | Bad/Suspicious Affiliate | 9 | <1% |
| 4 | Client Call Request | 8 | <1% |
| 14 | Filled and Signed Withdrawal Form | 1 | <1% |

### 2.4 Write Pattern - OUTPUT DELETED

**What**: History rows are produced by the OUTPUT clause capturing the pre-update state, not by a separate INSERT.

**Writers**: BackOffice.WithdrawApprovalAdd (older style) and BackOffice.WithdrawApprovalUpsert (MERGE-based, 2022)

**Rules**:
- Both procedures write to BackOffice.WithdrawApproval first, then INSERT the OUTPUT DELETED result into History.WithdrawApproval
- Only UPDATES produce history rows (WHEN MATCHED path in MERGE); first-time INSERTs (WHEN NOT MATCHED) produce no history row
- The MERGE approach (WithdrawApprovalUpsert) includes `WHERE ApprovedWithdrawID IS NOT NULL` guard to ensure only real previous records are captured
- ApprovedWithdrawID in the history row = the PK value from BackOffice.WithdrawApproval at the time it was updated (the ID of the record that was overwritten)

---

## 3. Data Overview

| LineID | ApprovedWithdrawID | WithdrawID | UserGroupID | ManagerID | Approved | Occurred | Comment | Meaning |
|--------|-------------------|------------|-------------|-----------|----------|----------|---------|---------|
| 30282 | 3729536 | 1739560 | 1 (Admin) | 734 | true | 2026-03-20 21:47 | Manual Approve Group Tests | Manager 734 manually approved Admin group - prior state captured |
| 30281 | 3729085 | 1739347 | 6 (Trading) | 0 | true | 2026-03-20 20:44 | Auto Approval | Automated system re-approved Trading group |
| 30280 | 3729084 | 1739347 | 1 (Admin) | 0 | true | 2026-03-20 20:44 | Auto Approval | Automated re-approval of Admin group for same withdrawal |
| 30279 | 3729079 | 1739342 | 6 (Trading) | 0 | true | 2026-03-20 20:40 | Auto Approval | Trading auto-approval for different withdrawal |

Note: Multiple rows for the same WithdrawID (1739347) shows two groups' records were both updated in the same automated pass.

Total rows: 29,243 | Date range: 2008-12-01 to 2026-03-20

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApprovedWithdrawID | INT | NO | - | CODE-BACKED | The PK value (ApprovedWithdrawID) from BackOffice.WithdrawApproval at the time this record was overwritten. Identifies exactly which approval record was superseded. NC index HWAP_APPROVE supports lookups by this ID. |
| 2 | WithdrawID | INT | NO | - | CODE-BACKED | The withdrawal request this approval decision belongs to. FK to Billing.Withdraw. NC index HWAP_WITHDRAW for efficient lookup of all approval history for a specific withdrawal. Multiple rows per WithdrawID are expected (one per group per revision). |
| 3 | UserGroupID | INT | NO | - | CODE-BACKED | The back-office user group whose approval record was superseded. FK to Dictionary.UserGroup. Dominant values: 3=Risk (51%), 1=Administrators (39%), 6=Trading (7%), 5=Accounting (4%). NC index HWAP_USERGROUP. |
| 4 | ManagerID | INT | NO | - | CODE-BACKED | The back-office manager who performed the action that generated this history row. FK to BackOffice.Manager. 0=automated system action. >0=specific manager. NC index HWAP_MANAGER for manager activity lookups. |
| 5 | WithdrawApprovalReasonID | INT | NO | - | CODE-BACKED | The reason category for the approval decision at the time this record was captured. FK to Dictionary.WithdrawApprovalReason. 7=Other dominates at 87%. NC index HWAP_REASON. See Section 2.3 for full value map. |
| 6 | Approved | BIT | NO | - | CODE-BACKED | Whether this group's approval was granted (1) or not (0) at the time this history row was captured. Most history rows show Approved=1 (revision of already-approved records by automation). |
| 7 | Occurred | DATETIME | NO | GETDATE() | CODE-BACKED | Timestamp when the original BackOffice.WithdrawApproval record was created or last updated (before being superseded). Default GETDATE() was set at insert time in BackOffice. This is the business event time, not the history-write time. |
| 8 | Comment | VARCHAR(MAX) | NO | - | CODE-BACKED | Human-readable description of the approval action. Common values: "Auto Approval" (automated approval pass), "Manual Approve Group Tests" (manager testing). NOT NULL - callers must provide a comment string. |
| 9 | LineID | INT IDENTITY(1,1) | NO | - | CODE-BACKED | Auto-incrementing surrogate PK for the history table itself. IDENTITY NOT FOR REPLICATION. Sequential across all groups and withdrawals. CLUSTERED PK on MAIN filegroup. Not semantically meaningful - used only for row ordering. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw | FK (FK_BWIT_HWAP) | The withdrawal whose approval history this row captures. |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HWAP) | The manager who updated the approval record (when non-zero). |
| UserGroupID | Dictionary.UserGroup | FK (FK_DUGR_HWAP) | The back-office team whose approval decision was revised. |
| WithdrawApprovalReasonID | Dictionary.WithdrawApprovalReason | FK (FK_DWAP_HWAP) | The reason category for the approval decision. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.WithdrawApprovalAdd | WithdrawID | Writer (OUTPUT DELETED -> INSERT) | Primary older writer - captures pre-update state when BackOffice.WithdrawApproval is updated |
| BackOffice.WithdrawApprovalUpsert | WithdrawID | Writer (MERGE OUTPUT DELETED -> INSERT) | Newer MERGE-based writer (2022) - same pattern |
| BackOffice.GetWithdrawApprovalHistory | WithdrawID | Reader | Returns full approval history for a withdrawal |
| BackOffice.GetWithdrawApprovalHistoryByID | ApprovedWithdrawID | Reader | Returns approval history for a specific approval record ID |
| BackOffice.GetCryptoTransferWithdrawApprovalHistory | WithdrawID | Reader | Returns crypto-specific withdrawal approval history |
| Billing.GetWithdrawHistory | WithdrawID | Reader | Joins approval history into withdrawal summary |
| Billing.GetHistory | WithdrawID | Reader | General billing history reader |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.WithdrawApproval (table)
  (leaf - no code-level DDL dependencies)
  FKs to: Billing.Withdraw, BackOffice.Manager, Dictionary.UserGroup, Dictionary.WithdrawApprovalReason
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK target for WithdrawID (FK_BWIT_HWAP) |
| BackOffice.Manager | Table | FK target for ManagerID (FK_BMNG_HWAP) |
| Dictionary.UserGroup | Table | FK target for UserGroupID (FK_DUGR_HWAP) |
| Dictionary.WithdrawApprovalReason | Table | FK target for WithdrawApprovalReasonID (FK_DWAP_HWAP) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApprovalAdd | Stored Procedure | WRITER - OUTPUT DELETED pattern |
| BackOffice.WithdrawApprovalUpsert | Stored Procedure | WRITER - MERGE OUTPUT DELETED pattern |
| BackOffice.GetWithdrawApprovalHistory | Stored Procedure | READER |
| BackOffice.GetWithdrawApprovalHistoryByID | Stored Procedure | READER |
| BackOffice.GetCryptoTransferWithdrawApprovalHistory | Stored Procedure | READER |
| Billing.GetWithdrawHistory | Stored Procedure | READER |
| Billing.GetHistory | Stored Procedure | READER |
| Billing.GetWithdrawalHistoryByDate | Stored Procedure | READER |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_WithdrawApproval | CLUSTERED PK | LineID ASC | - | - | Active (FILLFACTOR=90) |
| HWAP_APPROVE | NONCLUSTERED | ApprovedWithdrawID ASC | - | - | Active (FILLFACTOR=90) |
| HWAP_MANAGER | NONCLUSTERED | ManagerID ASC | - | - | Active (FILLFACTOR=90) |
| HWAP_REASON | NONCLUSTERED | WithdrawApprovalReasonID ASC | - | - | Active (FILLFACTOR=90) |
| HWAP_USERGROUP | NONCLUSTERED | UserGroupID ASC | - | - | Active (FILLFACTOR=90) |
| HWAP_WITHDRAW | NONCLUSTERED | WithdrawID ASC | - | - | Active (FILLFACTOR=90) |

Note: CLUSTERED PK on LineID (IDENTITY) for fast sequential inserts. Five NC indexes support lookups by each FK dimension independently - enabling efficient queries like "all history for manager X" or "all revisions for group Y on withdrawal Z".

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_WithdrawApproval | PRIMARY KEY CLUSTERED | LineID (auto-increment surrogate PK) |
| FK_BWIT_HWAP | FOREIGN KEY | WithdrawID -> Billing.Withdraw(WithdrawID) |
| FK_BMNG_HWAP | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DUGR_HWAP | FOREIGN KEY | UserGroupID -> Dictionary.UserGroup(UserGroupID) |
| FK_DWAP_HWAP | FOREIGN KEY | WithdrawApprovalReasonID -> Dictionary.WithdrawApprovalReason(WithdrawApprovalReasonID) |
| BAPW_OCCURRED | DEFAULT | Occurred = GETDATE() |

---

## 8. Sample Queries

### 8.1 Full approval revision history for a specific withdrawal
```sql
SELECT
    ha.LineID,
    ha.ApprovedWithdrawID,
    ug.Name AS UserGroup,
    ha.ManagerID,
    ha.Approved,
    war.Name AS ReasonName,
    ha.Occurred,
    ha.Comment
FROM History.WithdrawApproval ha WITH (NOLOCK)
INNER JOIN Dictionary.UserGroup ug WITH (NOLOCK)
    ON ha.UserGroupID = ug.UserGroupID
INNER JOIN Dictionary.WithdrawApprovalReason war WITH (NOLOCK)
    ON ha.WithdrawApprovalReasonID = war.WithdrawApprovalReasonID
WHERE ha.WithdrawID = 1739347
ORDER BY ha.Occurred;
```

### 8.2 Find withdrawals where a group changed its approval decision
```sql
SELECT ha.WithdrawID,
       ug.Name AS UserGroup,
       ha.Approved AS OldApproved,
       ha.Comment AS OldComment,
       ha.Occurred AS ChangedAt,
       ha.ManagerID AS ChangedByManager
FROM History.WithdrawApproval ha WITH (NOLOCK)
INNER JOIN Dictionary.UserGroup ug WITH (NOLOCK)
    ON ha.UserGroupID = ug.UserGroupID
WHERE ha.Occurred >= DATEADD(DAY, -7, GETUTCDATE())
ORDER BY ha.Occurred DESC;
```

### 8.3 Manager revision activity report
```sql
SELECT ha.ManagerID,
       ug.Name AS UserGroup,
       COUNT(*) AS Revisions,
       SUM(CASE WHEN ha.Approved = 1 THEN 1 ELSE 0 END) AS ApprovalRevisions
FROM History.WithdrawApproval ha WITH (NOLOCK)
INNER JOIN Dictionary.UserGroup ug WITH (NOLOCK)
    ON ha.UserGroupID = ug.UserGroupID
WHERE ha.ManagerID > 0
    AND ha.Occurred >= CAST(GETUTCDATE() AS DATE)
GROUP BY ha.ManagerID, ug.Name
ORDER BY Revisions DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 7 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.WithdrawApproval | Type: Table | Source: etoro/etoro/History/Tables/History.WithdrawApproval.sql*
