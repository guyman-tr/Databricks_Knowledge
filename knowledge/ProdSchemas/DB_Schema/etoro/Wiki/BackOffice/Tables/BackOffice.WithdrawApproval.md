# BackOffice.WithdrawApproval

> Multi-group approval records for customer withdrawal (cashout) requests, tracking each user group's decision, manager, and reason. Mirrors to History.WithdrawApproval on every change.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BWAP: ApprovedWithdrawID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 3 (1 clustered PK + 2 nonclustered) |

---

## 1. Business Meaning

`BackOffice.WithdrawApproval` is the approval workflow table for customer withdrawal requests. When a customer requests to withdraw funds (cashout), the request must be reviewed and approved by multiple independent back-office groups before it is processed. This table stores one row per (WithdrawID, UserGroupID) pair: each group (Admin, Risk, Marketing, Trading) records its decision independently.

This table is the counterpart to `BackOffice.RedeemApproval` (which handles crypto redemptions). The same upsert-plus-history-mirror pattern is used: `WithdrawApprovalAdd` inserts new approval rows or updates existing ones, and mirrors the old values to `History.WithdrawApproval` for a complete decision audit trail.

The approval requirement is amount-based and configurable: thresholds in `Maintenance.Feature` XML determine at what withdrawal amount each group's sign-off is required. Marketing approval can be waived for non-affiliate customers. Once all required groups have approved, `WithdrawRequestApprove` is automatically called to finalize the withdrawal.

Live data: 3,720,700 rows - a very active, high-throughput table. Most approvals use ReasonID=7 (Other) and ManagerID=0, indicating large-scale automated approvals.

---

## 2. Business Logic

### 2.1 Amount-Threshold Multi-Group Approval

**What**: 4 groups can be required to approve a withdrawal, with each group's requirement gated by the withdrawal amount and configurable thresholds.

**Columns/Parameters Involved**: `WithdrawID`, `UserGroupID`, `Approved`, `ManagerID`

**Rules**:
- One row per (WithdrawID, UserGroupID) combination - enforced by UNIQUE NC index BWAP_CASHOUT.
- `Approved=1` means that group approved; `Approved=0` means rejected.
- Groups and their roles:
  - **UserGroupID=1 (Admin)**: Required if withdrawal Amount >= `Maintenance.Feature.WithdrawAdminApprovalFrom`.
  - **UserGroupID=3 (Risk)**: Required if Amount >= `WithdrawRiskApprovalFrom`.
  - **UserGroupID=4 (Marketing)**: Required if Amount >= `WithdrawMarketingApprovalFrom` AND customer `IsAffiliate=1`.
  - **UserGroupID=6 (Trading)**: Required if Amount >= `WithdrawTradingApprovalFrom`.
- After all required groups have Approved=1, `WithdrawApprovalAdd` automatically calls `WithdrawRequestApprove`.
- ManagerID=0 in live data = automated/system approval (no human involved).

**Approval flow diagram**:
```
Withdrawal request created (Billing.Withdraw)
    -> Each required group submits approval via WithdrawApprovalAdd
    -> WithdrawApprovalAdd checks: all required groups approved?
        -> YES: calls WithdrawRequestApprove automatically
        -> NO: waits for remaining groups
```

### 2.2 History Mirroring

**What**: Every update to an existing approval row is mirrored to the history table.

**Columns/Parameters Involved**: All columns

**Rules**:
- `WithdrawApprovalAdd` uses OUTPUT clause to capture old row values before UPDATE.
- Old values are inserted into `History.WithdrawApproval`.
- New inserts (first approval by a group) are also mirrored via SELECT * from @Info table variable.
- Creates full timeline of every approval decision including reversals.

### 2.3 Filtered Index for History Display

**What**: The BWAP_GetWithdrawalHistoryByDate index filters out ReasonID=7 (Other), optimizing the typical history display query.

**Columns/Parameters Involved**: `WithdrawID`, `Occurred`, `WithdrawApprovalReasonID`

**Rules**:
- The filtered index covers WHERE `WithdrawApprovalReasonID <> 7` (Other).
- Since ReasonID=7 is used for bulk/automated approvals, this filter excludes the noise from routine auto-approvals.
- Human review decisions (ReasonIDs 1-6, 8-16) are included in the index for fast history lookups.

### 2.4 Withdrawal Approval Reasons

**WithdrawApprovalReason values** (from Dictionary.WithdrawApprovalReason):

| ID | Name | Usage |
|----|------|-------|
| 1 | Awaiting Documents | Customer needs to submit docs |
| 2 | Bonus Abusing | Suspected bonus abuse |
| 3 | Zero Lots Activity | No trading activity |
| 4 | Client Call Request | Customer called in |
| 5 | Bad/Suspicious Affiliate | Affiliate fraud concern |
| 6 | Scalper Trader | Scalping pattern detected |
| 7 | Other | Default/automated approvals |
| 8 | CC Docs | Credit card documentation |
| 9 | PP Docs | PayPal documentation |
| 10 | CO Form | Cashout form required |
| 11 | Better Copy of Documents | Document quality issue |
| 12 | Copy of Missing Utility Bill | Missing utility bill |
| 13 | Copy of Missing CC | Missing credit card copy |
| 14 | Filled and Signed Withdrawal Form | Form completion required |
| 15 | Colored Copy of Documents | Color copy required |
| 16 | Documents - Other | Other document request |

---

## 3. Data Overview

| ApprovedWithdrawID | WithdrawID | UserGroupID | ManagerID | ReasonID | Approved | Occurred |
|-------------------|-----------|-------------|-----------|---------|---------|---------|
| 3720700 | 1734869 | 3 (Risk) | 780 | 7 (Other) | 1 | 2026-03-17 12:38 |
| 3720699 | 1734869 | 1 (Admin) | 780 | 7 (Other) | 1 | 2026-03-17 12:38 |
| 3720698 | 1734862 | 6 (Trading) | 0 (auto) | 7 (Other) | 1 | 2026-03-17 12:38 |
| 3720697 | 1734862 | 1 (Admin) | 0 (auto) | 7 (Other) | 1 | 2026-03-17 12:38 |

Pattern: Most approvals are auto (ManagerID=0, ReasonID=7). Manual approvals use named manager IDs. Groups 1 (Admin), 3 (Risk), 6 (Trading) most active.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApprovedWithdrawID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate PK. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each approval record. ~3.7M records as of 2026-03-17. |
| 2 | WithdrawID | int | NO | - | CODE-BACKED | FK to Billing.Withdraw.WithdrawID (FK_BWIT_BWAP). Identifies the withdrawal request being approved. Multiple rows share a WithdrawID (one per approval group). Part of UNIQUE index (WithdrawID + UserGroupID). |
| 3 | UserGroupID | int | NO | - | CODE-BACKED | FK to Dictionary.UserGroup.UserGroupID (FK_DUGR_BWAP). Identifies which approval group this row represents. 1=Admin, 3=Risk, 4=Marketing, 6=Trading. Each group submits one row per withdrawal. |
| 4 | ManagerID | int | NO | - | CODE-BACKED | FK to BackOffice.Manager.ManagerID (FK_BMNG_BWAP). The manager who submitted this group's decision. ManagerID=0 indicates automated/system approval without human review. |
| 5 | WithdrawApprovalReasonID | int | NO | - | CODE-BACKED | FK to Dictionary.WithdrawApprovalReason (FK_DWAP_BWAP). Reason for the approval decision. 7=Other (default for automated approvals). 1-6 and 8-16 indicate specific compliance reasons for manual holds/approvals. |
| 6 | Approved | bit | NO | - | CODE-BACKED | 1=This group approved the withdrawal. 0=This group rejected/held. A withdrawal proceeds only when all required groups (per Maintenance.Feature thresholds) have Approved=1. |
| 7 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | Timestamp when this approval decision was recorded. Defaults to GETDATE() for direct inserts; set to GetDate() in WithdrawApprovalAdd SP. |
| 8 | Comment | varchar(max) | NO | - | CODE-BACKED | Free-text comment from the approving/rejecting manager. Required field (NOT NULL). Contains compliance notes, rejection rationale, or auto-generated notes for system approvals. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WithdrawID | Billing.Withdraw.WithdrawID | FK (FK_BWIT_BWAP) | The withdrawal request being approved |
| UserGroupID | Dictionary.UserGroup.UserGroupID | FK (FK_DUGR_BWAP) | The approval group this decision belongs to |
| ManagerID | BackOffice.Manager.ManagerID | FK (FK_BMNG_BWAP) | The manager who submitted this decision |
| WithdrawApprovalReasonID | Dictionary.WithdrawApprovalReason.WithdrawApprovalReasonID | FK (FK_DWAP_BWAP) | Classification of the reason for the decision |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.WithdrawApprovalAdd | INSERT/UPDATE | Writer | Upserts approval decisions; auto-calls WithdrawRequestApprove when all groups approve |
| BackOffice.WithdrawApprovalUpsert | INSERT/UPDATE | Writer | Alternative upsert path |
| BackOffice.GetCashOutRequests | JOIN | Reader | Fetches pending withdrawal requests with approval status |
| BackOffice.GetUnapprovedWithdrawRequests | JOIN | Reader | Finds withdrawals lacking required approvals |
| BackOffice.GetWithdrawApprovalHistory | JOIN | Reader | History view of approval decisions |
| BackOffice.GetWithdrawApprovalHistoryByID | JOIN | Reader | Per-withdrawal approval history |
| BackOffice.GetCryptoTransferWithdrawApprovalHistory | JOIN | Reader | Crypto withdrawal approval history |
| BackOffice.WithdrawApprovalGet | SELECT | Reader | Retrieves approval status for a withdrawal |
| History.WithdrawApproval | INSERT | History mirror | All changes mirrored here for complete audit trail |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.WithdrawApproval (table)
+-- Billing.Withdraw (table) [FK_BWIT_BWAP]
+-- BackOffice.Manager (table) [FK_BMNG_BWAP]
+-- Dictionary.UserGroup (table) [FK_DUGR_BWAP]
+-- Dictionary.WithdrawApprovalReason (table) [FK_DWAP_BWAP]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | FK: WithdrawID must be a valid withdrawal request |
| BackOffice.Manager | Table | FK: ManagerID must be a valid manager |
| Dictionary.UserGroup | Table | FK: UserGroupID must be a valid approval group |
| Dictionary.WithdrawApprovalReason | Table | FK: WithdrawApprovalReasonID must be a valid reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApprovalAdd | Stored Procedure | Primary writer - upserts and checks completion |
| BackOffice.WithdrawApprovalUpsert | Stored Procedure | Alternative writer |
| BackOffice.GetCashOutRequests | Stored Procedure | Reader - pending requests |
| BackOffice.GetUnapprovedWithdrawRequests | Stored Procedure | Reader - approval gap detection |
| BackOffice.GetWithdrawApprovalHistory | Stored Procedure | Reader - approval audit history |
| BackOffice.WithdrawApprovalGet | Stored Procedure | Reader - per-withdrawal status |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BWAP | CLUSTERED PK | ApprovedWithdrawID ASC (FILLFACTOR=90) | - | - | Active |
| BWAP_CASHOUT | UNIQUE NONCLUSTERED | WithdrawID ASC, UserGroupID ASC (FILLFACTOR=90) | Approved, Occurred | - | Active |
| Idx_BackOffice_WithdrawApproval_Billing_GetWithdrawalHistoryByDate | NONCLUSTERED | WithdrawID ASC, Occurred DESC | WithdrawApprovalReasonID | WithdrawApprovalReasonID <> 7 | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BAPW_OCCURRED | DEFAULT | Occurred defaults to GETDATE() |
| FK_BWIT_BWAP | FK | WithdrawID -> Billing.Withdraw |
| FK_BMNG_BWAP | FK | ManagerID -> BackOffice.Manager |
| FK_DUGR_BWAP | FK | UserGroupID -> Dictionary.UserGroup |
| FK_DWAP_BWAP | FK | WithdrawApprovalReasonID -> Dictionary.WithdrawApprovalReason |

---

## 8. Sample Queries

### 8.1 Get all approval decisions for a specific withdrawal

```sql
SELECT
    wa.ApprovedWithdrawID, wa.WithdrawID, wa.UserGroupID,
    ug.Name AS UserGroup, wa.ManagerID,
    r.Name AS Reason, wa.Approved, wa.Occurred, wa.Comment
FROM BackOffice.WithdrawApproval wa WITH (NOLOCK)
JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = wa.UserGroupID
JOIN Dictionary.WithdrawApprovalReason r WITH (NOLOCK) ON r.WithdrawApprovalReasonID = wa.WithdrawApprovalReasonID
WHERE wa.WithdrawID = 1734869
ORDER BY wa.Occurred;
```

### 8.2 Find withdrawals pending Risk group approval

```sql
SELECT wa.WithdrawID, wa.Occurred, wa.Approved
FROM BackOffice.WithdrawApproval wa WITH (NOLOCK)
WHERE wa.UserGroupID = 3  -- Risk
  AND wa.Approved = 0
ORDER BY wa.Occurred;
```

### 8.3 Count approvals by group and reason today

```sql
SELECT
    ug.Name AS UserGroup, r.Name AS Reason, COUNT(*) AS Count
FROM BackOffice.WithdrawApproval wa WITH (NOLOCK)
JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = wa.UserGroupID
JOIN Dictionary.WithdrawApprovalReason r WITH (NOLOCK) ON r.WithdrawApprovalReasonID = wa.WithdrawApprovalReasonID
WHERE wa.Occurred >= CAST(GETUTCDATE() AS DATE)
GROUP BY ug.Name, r.Name
ORDER BY Count DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11 (DDL, Live Data, FK Resolution, Procedure Ref, Logic Extraction, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.WithdrawApproval | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.WithdrawApproval.sql*
