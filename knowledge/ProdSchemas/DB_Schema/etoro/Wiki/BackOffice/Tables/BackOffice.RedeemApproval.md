# BackOffice.RedeemApproval

> Multi-group approval records for Bitcoin/crypto redemption requests, tracking each user group's approval decision, manager, and reason for a given redeem.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Table |
| **Key Identifier** | PK_BRAP: ApprovedRedeemID IDENTITY (CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 (clustered PK) |

---

## 1. Business Meaning

`BackOffice.RedeemApproval` records the approval workflow decisions for eToro's redeem (Bitcoin/crypto withdrawal) requests. "Redeem" refers to the process by which customers convert their crypto holdings back to fiat or withdraw them. This table stores one row per (RedeemID, UserGroupID) pair: each approval group (Operations, Risk, etc.) records its approval or rejection decision independently, allowing a multi-group sign-off process before a redeem is processed.

This table exists to enforce a segregation-of-duties control over crypto redemptions: a single manager cannot self-approve a significant withdrawal. Multiple independent approval groups (defined by Dictionary.UserGroup) must each grant approval. The table provides the audit trail for each group's decision, who made it, why, and when.

Data flows in via `RedeemApprovalAdd`: the SP upserts - updating an existing group approval if one exists, or inserting if not. Every change is simultaneously mirrored to `History.BackOfficeRedeemApproval`. Live data shows ~52K approval records. `IsApprovedByAllUserGroups` reads this table to determine whether all required groups have approved a given redeem before it can proceed.

---

## 2. Business Logic

### 2.1 Multi-Group Approval Workflow

**What**: Each redeem requires approval from multiple user groups. This table records each group's individual decision.

**Columns/Parameters Involved**: `RedeemID`, `UserGroupID`, `Approved`, `ManagerID`

**Rules**:
- One row per (RedeemID, UserGroupID) combination.
- `Approved=1` means that group approved. `Approved=0` means that group rejected.
- A redeem is only fully approved when ALL required groups have Approved=1 (checked by `IsApprovedByAllUserGroups`).
- Only redeems with RedeemStatusID IN (1, 4, 100) are eligible for the approval process.
- If a group has already submitted an approval, `RedeemApprovalAdd` updates the existing row (not inserts a new one) and logs the old values to History.

**Diagram**:
```
RedeemID=40018 needs approval from 3 groups:
  UserGroupID=2 (Operations) -> ManagerID=969, Approved=1 [Approved at 10:56]
  UserGroupID=3 (Risk)       -> ManagerID=969, Approved=1 [Approved at 10:58]
  UserGroupID=36 (?)         -> ManagerID=969, Approved=1 [Approved at 10:58]

IsApprovedByAllUserGroups -> TRUE -> Redeem can proceed
```

### 2.2 History Mirroring

**What**: Every insert or update to this table is immediately copied to the history log.

**Columns/Parameters Involved**: All columns

**Rules**:
- `RedeemApprovalAdd` uses OUTPUT to capture the old row values before an UPDATE, then inserts them into `History.BackOfficeRedeemApproval`.
- New rows (first approval by a group) are also inserted into History after commit.
- This creates a complete timeline of every approval decision including changes/reversals.

---

## 3. Data Overview

| ApprovedRedeemID | RedeemID | CID | UserGroupID | ManagerID | RedeemApprovalReasonID | Approved | Occurred |
|-----------------|---------|-----|-------------|-----------|----------------------|----------|----------|
| 52360 | 40018 | 3635308 | 2 (Operations) | 969 | 1 (Other) | 1 | 2026-03-12 10:58 |
| 52359 | 40018 | 3635308 | 36 | 969 | 1 (Other) | 1 | 2026-03-12 10:58 |
| 52358 | 40018 | 3635308 | 3 (Risk) | 969 | 1 (Other) | 1 | 2026-03-12 10:56 |
| 52357 | 40005 | 25237750 | 3 (Risk) | 969 | 1 (Other) | 1 | 2026-03-02 08:40 |
| 52356 | 40005 | 25237750 | 2 (Operations) | 969 | 1 (Other) | 1 | 2026-03-02 08:40 |

Pattern: Each RedeemID has multiple rows (one per required approval group). All recent approvals use RedeemApprovalReasonID=1 (Other - the only defined reason).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ApprovedRedeemID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented. NOT FOR REPLICATION. Uniquely identifies each approval record. |
| 2 | RedeemID | int | NO | - | CODE-BACKED | FK to Billing.Redeem.RedeemID. Identifies the crypto redemption request being approved or rejected. Multiple rows can share a RedeemID (one per approval group). |
| 3 | CID | int | NO | - | CODE-BACKED | Customer ID of the redeem requestor. Denormalised here for query performance (avoids joining Billing.Redeem). Populated from Billing.Redeem.CID at insert time. |
| 4 | UserGroupID | int | NO | - | CODE-BACKED | FK to Dictionary.UserGroup.UserGroupID. Identifies which approval group this row represents. Examples: 2=Operations, 3=Risk. Each group submits one approval row per redeem. |
| 5 | ManagerID | int | NO | - | CODE-BACKED | FK to BackOffice.Manager.ManagerID. The specific back-office manager who submitted this group's approval decision. |
| 6 | RedeemApprovalReasonID | int | NO | - | CODE-BACKED | FK to Dictionary.RedeemApprovalReason.RedeemApprovalReasonID. Reason for the decision. Currently only 1=Other is defined in the lookup table. |
| 7 | Approved | bit | NO | - | CODE-BACKED | 1=This group approved the redeem. 0=This group rejected the redeem. A redeem requires all required groups to have Approved=1 (checked by IsApprovedByAllUserGroups). |
| 8 | Occurred | datetime | NO | GETDATE() | CODE-BACKED | UTC timestamp when this approval decision was recorded. Set to GETUTCDATE() by the SP on insert and on each update. Defaults to GETDATE() for direct inserts. |
| 9 | Comment | varchar(max) | NO | - | CODE-BACKED | Free-text comment provided by the approving/rejecting manager explaining the decision. Required field (NOT NULL). May contain compliance notes or rejection rationale. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemID | Billing.Redeem.RedeemID | FK (FK_BRED_BRAP) | The crypto redemption request being approved |
| ManagerID | BackOffice.Manager.ManagerID | FK (FK_BMNG_BRAP) | The manager who submitted this group's approval |
| UserGroupID | Dictionary.UserGroup.UserGroupID | FK (FK_DUGR_BRAP) | The approval group this decision belongs to |
| RedeemApprovalReasonID | Dictionary.RedeemApprovalReason.RedeemApprovalReasonID | FK (FK_DRAP_BRAP) | Reason classification for the decision |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.RedeemApprovalAdd | INSERT/UPDATE | Writer | Upserts approval decisions and copies to History |
| BackOffice.IsApprovedByAllUserGroups | JOIN | Reader | Checks if all required groups have approved a redeem |
| BackOffice.GetRedeemDisplayData | JOIN | Reader | Fetches approval details for redeem display |
| BackOffice.GetRedeemUserGroupApprovalStatus | FROM | Reader | Returns per-group approval status for a redeem |
| BackOffice.GetCryptoTransactionsApprovals | FROM | Reader | Reads approvals for crypto transaction display |
| History.BackOfficeRedeemApproval | INSERT | History mirror | All changes are logged to this history table |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.RedeemApproval (table)
├── Billing.Redeem (table) [FK_BRED_BRAP]
├── BackOffice.Manager (table) [FK_BMNG_BRAP]
├── Dictionary.UserGroup (table) [FK_DUGR_BRAP]
└── Dictionary.RedeemApprovalReason (table) [FK_DRAP_BRAP]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | FK: RedeemID must exist as a valid redemption request |
| BackOffice.Manager | Table | FK: ManagerID must exist as a valid manager |
| Dictionary.UserGroup | Table | FK: UserGroupID must exist as a valid approval group |
| Dictionary.RedeemApprovalReason | Table | FK: RedeemApprovalReasonID must exist as a valid reason |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RedeemApprovalAdd | Stored Procedure | Writer - upserts approval records |
| BackOffice.IsApprovedByAllUserGroups | Stored Procedure | Reader - determines if all groups approved |
| BackOffice.GetRedeemDisplayData | Stored Procedure | Reader - for redeem detail display |
| BackOffice.GetRedeemUserGroupApprovalStatus | Stored Procedure | Reader - per-group status check |
| BackOffice.GetCryptoTransactionsApprovals | Stored Procedure | Reader - crypto transaction audit |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BRAP | CLUSTERED PK | ApprovedRedeemID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BAPR_OCCURRED | DEFAULT | Occurred defaults to GETDATE() |
| FK_BRED_BRAP | FK | RedeemID -> Billing.Redeem |
| FK_BMNG_BRAP | FK | ManagerID -> BackOffice.Manager |
| FK_DUGR_BRAP | FK | UserGroupID -> Dictionary.UserGroup |
| FK_DRAP_BRAP | FK | RedeemApprovalReasonID -> Dictionary.RedeemApprovalReason |
| ApprovedRedeemID NOT FOR REPLICATION | Identity | Identity not replicated to subscribers |

---

## 8. Sample Queries

### 8.1 Get all approval decisions for a specific redeem

```sql
SELECT
    ra.ApprovedRedeemID, ra.RedeemID, ra.UserGroupID,
    ug.Name AS UserGroup, mgr.UserName AS Manager,
    ra.Approved, ra.Occurred, ra.Comment
FROM BackOffice.RedeemApproval ra WITH (NOLOCK)
JOIN Dictionary.UserGroup ug WITH (NOLOCK) ON ug.UserGroupID = ra.UserGroupID
JOIN BackOffice.Manager mgr WITH (NOLOCK) ON mgr.ManagerID = ra.ManagerID
WHERE ra.RedeemID = 40018
ORDER BY ra.Occurred;
```

### 8.2 Find redeems pending approval from Risk group

```sql
SELECT ra.RedeemID, ra.CID, ra.Occurred, ra.Approved
FROM BackOffice.RedeemApproval ra WITH (NOLOCK)
WHERE ra.UserGroupID = 3  -- Risk
    AND ra.Approved = 0
ORDER BY ra.Occurred;
```

### 8.3 Check if a redeem has been approved by all required groups

```sql
EXEC BackOffice.IsApprovedByAllUserGroups @RedeemIDs = N'40018';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11 (DDL, Live Data, FK Resolution, Procedure Ref, Logic Extraction, Doc Gen)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 5 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.RedeemApproval | Type: Table | Source: etoro/etoro/BackOffice/Tables/BackOffice.RedeemApproval.sql*
