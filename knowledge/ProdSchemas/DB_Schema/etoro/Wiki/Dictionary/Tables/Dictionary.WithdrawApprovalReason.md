# Dictionary.WithdrawApprovalReason

> Hierarchical lookup table defining the reasons why a withdrawal request is held for manual approval — from "Awaiting Documents" to "Bonus Abusing" — with parent-child categorization and optional email template linkage for automated customer notifications.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | WithdrawApprovalReasonID (INT, manually assigned) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 (1 clustered PK + 1 unique NC on Name+ParentID) |

---

## 1. Business Meaning

Dictionary.WithdrawApprovalReason defines why a withdrawal request requires manual review before it can be processed. When the withdrawal system flags a cashout for hold (due to compliance requirements, suspicious activity, or missing documentation), the approving officer selects a reason from this table. The reasons are organized hierarchically — top-level categories (e.g., "Awaiting Documents") have sub-reasons (e.g., "CC Docs", "PP Docs", "CO Form") that provide granular detail.

Without this table, the withdrawal approval process would have no structured way to document why requests are held, making it impossible to analyze hold patterns, automate customer notifications, or audit approval decisions. This is critical for regulatory compliance — every held withdrawal must have a documented reason.

The table is consumed by 10+ procedures across BackOffice and Billing: BackOffice.WithdrawApprovalAdd/Get/Upsert (approval workflow management), BackOffice.GetCashOutRequests/GetUnapprovedWithdrawRequests (cashout queue filtering), BackOffice.GetWithdrawApprovalHistory/GetWithdrawApprovalHistoryByID (audit trails), BackOffice.GetCryptoTransferWithdrawApprovalHistory (crypto-specific approvals), and Billing.WithdrawAndWithdrawToFundingAdd/GetWithdrawalHistoryByDate/GetHistory (withdrawal processing and reporting).

---

## 2. Business Logic

### 2.1 Hierarchical Reason Categories

**What**: Approval reasons have a parent-child structure for progressive categorization — broad reason first, then specific sub-reason.

**Columns/Parameters Involved**: `WithdrawApprovalReasonID`, `Name`, `ParentID`

**Rules**:
- Top-level reasons (ParentID = NULL) represent broad hold categories: Awaiting Documents (1), Bonus Abusing (2), Zero Lots Activity (3), Client Call Request (4), Bad/Suspicious Affiliate (5), Scalper Trader (6), Other (7)
- Sub-reasons (ParentID → a top-level ID) provide specific detail within a category: IDs 8-16 are all sub-reasons under "Awaiting Documents" (1)
- The unique index on (Name, ParentID) ensures no duplicate sub-reasons within the same category
- Self-referencing FK (FK_DWAR_DWAR) enforces hierarchy integrity

**Diagram**:
```
Withdrawal Hold Reason Hierarchy:
  Awaiting Documents (1)
  ├── CC Docs (8)
  ├── PP Docs (9)
  ├── CO Form (10)
  ├── Better Copy of Documents (11)
  ├── Copy of Missing Utility Bill (12)
  ├── Copy of Missing CC (13)
  ├── Filled and Signed Withdrawal Form (14)
  ├── Colored Copy of Documents (15)
  └── Documents - Other (16)
  Bonus Abusing (2)
  Zero Lots Activity (3)
  Client Call Request (4)
  Bad\Suspicious Affiliate (5)
  Scalper Trader (6)
  Other (7)
```

### 2.2 Automated Email Notifications

**What**: Some sub-reasons link to email templates that are automatically sent to the customer when the reason is selected.

**Columns/Parameters Involved**: `MailingTemplateID`, `ParentID`

**Rules**:
- MailingTemplateID links to the mailing/template system — when a compliance officer selects this reason, the system automatically sends the corresponding email
- Only sub-reasons (ParentID ≠ NULL) have email templates; top-level categories do not trigger emails
- Example: "CC Docs" (8) → template 875 (requesting credit card documentation), "PP Docs" (9) → template 1122 (requesting PayPal documentation)
- "Documents - Other" (16) has no template (NULL) — freeform reasons require manual customer communication
- This automation ensures consistent, timely customer communication about why their withdrawal is held

---

## 3. Data Overview

| WithdrawApprovalReasonID | Name | ParentID | MailingTemplateID | Meaning |
|---|---|---|---|---|
| 1 | Awaiting Documents | NULL | NULL | Top-level hold category — withdrawal is held because the customer has not provided required documentation. Sub-reasons specify which documents are missing. |
| 2 | Bonus Abusing | NULL | NULL | Customer appears to be exploiting promotional bonuses — withdrawal held pending review of trading activity for bonus abuse patterns. |
| 8 | CC Docs | 1 | 875 | Sub-reason under "Awaiting Documents" — credit card documentation is needed. Auto-sends template 875 requesting the customer upload card images. |
| 14 | Filled and Signed Withdrawal Form | 1 | 1127 | Sub-reason — a signed withdrawal authorization form is required (typically for large amounts or regulatory mandates). Auto-sends template 1127. |
| 5 | Bad\Suspicious Affiliate | NULL | NULL | The customer was referred by a suspicious or blacklisted affiliate partner. Withdrawal held until compliance clears the affiliate relationship. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | WithdrawApprovalReasonID | int | NO | - | CODE-BACKED | Unique identifier for the approval hold reason. IDs 1-7 are top-level categories; IDs 8-16 are sub-reasons. Referenced by 10+ withdrawal approval procedures for recording, filtering, and reporting hold reasons. |
| 2 | Name | varchar(50) | NO | - | CODE-BACKED | Display name of the hold reason (e.g., "Awaiting Documents", "CC Docs", "Bonus Abusing"). Shown in BackOffice approval UI. Unique within each parent category (enforced by DWAR_NAME unique index on Name+ParentID). |
| 3 | ParentID | int | YES | - | CODE-BACKED | Self-referencing FK to WithdrawApprovalReasonID — links sub-reasons to their parent category. NULL for top-level categories (IDs 1-7). FK_DWAR_DWAR enforces referential integrity. Enables hierarchical reason selection in BackOffice UI. |
| 4 | MailingTemplateID | int | YES | - | CODE-BACKED | Foreign key to the mailing template system — identifies which email template to auto-send when this reason is selected. Only populated for sub-reasons (IDs 8-15). NULL means no automated email; compliance must communicate manually. Values: 875, 1122-1128. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ParentID | Dictionary.WithdrawApprovalReason | Self-Reference/FK | Points to the parent category in the reason hierarchy |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.WithdrawApproval | WithdrawApprovalReasonID | Implicit | Stores the hold reason per approval record |
| History.WithdrawApproval | WithdrawApprovalReasonID | Implicit | Historical archive of approval reason assignments |
| BackOffice.WithdrawApprovalAdd | @ReasonID | Reader | Records the selected reason when adding an approval hold |
| BackOffice.WithdrawApprovalGet | ReasonID | Reader | Returns reason details in approval queries |
| BackOffice.WithdrawApprovalUpsert | @ReasonID | Reader | Updates approval records with reason changes |
| BackOffice.GetCashOutRequests | ReasonID | Reader | Filters/displays reasons in cashout queue |
| BackOffice.GetUnapprovedWithdrawRequests | ReasonID | Reader | Shows reasons for unapproved withdrawals |
| BackOffice.GetWithdrawApprovalHistory | ReasonID | Reader | Includes reasons in approval audit trail |
| Billing.WithdrawAndWithdrawToFundingAdd | ReasonID | Reader | Records reason during withdrawal creation |
| Billing.GetHistory | ReasonID | Reader | Returns reason in withdrawal history |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.WithdrawApprovalReason (table)
└── Dictionary.WithdrawApprovalReason (self-reference via ParentID)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.WithdrawApprovalReason | Table | Self-reference — ParentID FK points to own WithdrawApprovalReasonID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.WithdrawApproval | Table | Stores reason ID per approval |
| BackOffice.WithdrawApprovalAdd | Stored Procedure | Records hold reason |
| BackOffice.GetCashOutRequests | Stored Procedure | Displays reasons in queue |
| BackOffice.GetUnapprovedWithdrawRequests | Stored Procedure | Filters by reason |
| BackOffice.GetWithdrawApprovalHistory | Stored Procedure | Audit trail display |
| Billing.WithdrawAndWithdrawToFundingAdd | Stored Procedure | Records reason during creation |
| Billing.GetWithdrawalHistoryByDate | Stored Procedure | Reason in withdrawal history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DWAR | CLUSTERED | WithdrawApprovalReasonID ASC | - | - | Active |
| DWAR_NAME | NC UNIQUE | Name ASC, ParentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_DWAR_DWAR | FK | ParentID → Dictionary.WithdrawApprovalReason(WithdrawApprovalReasonID) — self-referencing FK for hierarchy |

---

## 8. Sample Queries

### 8.1 Show the full reason hierarchy with parent names
```sql
SELECT  r.WithdrawApprovalReasonID,
        r.Name AS ReasonName,
        p.Name AS ParentCategory,
        r.MailingTemplateID
FROM    [Dictionary].[WithdrawApprovalReason] r WITH (NOLOCK)
LEFT JOIN [Dictionary].[WithdrawApprovalReason] p WITH (NOLOCK)
        ON p.WithdrawApprovalReasonID = r.ParentID
ORDER BY ISNULL(r.ParentID, r.WithdrawApprovalReasonID), r.WithdrawApprovalReasonID;
```

### 8.2 List sub-reasons that trigger automated emails
```sql
SELECT  r.Name AS SubReason,
        p.Name AS Category,
        r.MailingTemplateID
FROM    [Dictionary].[WithdrawApprovalReason] r WITH (NOLOCK)
JOIN    [Dictionary].[WithdrawApprovalReason] p WITH (NOLOCK)
        ON p.WithdrawApprovalReasonID = r.ParentID
WHERE   r.MailingTemplateID IS NOT NULL
ORDER BY r.WithdrawApprovalReasonID;
```

### 8.3 List top-level categories only
```sql
SELECT  WithdrawApprovalReasonID,
        Name AS Category
FROM    [Dictionary].[WithdrawApprovalReason] WITH (NOLOCK)
WHERE   ParentID IS NULL
ORDER BY WithdrawApprovalReasonID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 10 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.WithdrawApprovalReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.WithdrawApprovalReason.sql*
