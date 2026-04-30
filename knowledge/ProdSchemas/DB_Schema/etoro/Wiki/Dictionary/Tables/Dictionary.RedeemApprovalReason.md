# Dictionary.RedeemApprovalReason

> Lookup table defining CopyTrading redeem manual approval reasons — currently only 1 value ("Other") — used by BackOffice.RedeemApproval for manual redeem review justifications.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | RedeemApprovalReasonID (INT, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 1 active (PK clustered) |

---

## 1. Business Meaning

Dictionary.RedeemApprovalReason provides the list of reasons a BackOffice operator can select when manually approving or reviewing a CopyTrading redeem (fund withdrawal from a copy relationship). When a copier redeems funds from a copied trader, certain cases require manual BackOffice intervention, and the operator must select a reason.

Currently contains only 1 reason ("Other"), suggesting this is either a recently simplified table or one that was designed for extensibility but only the catch-all option was ever populated.

Referenced by BackOffice.RedeemApproval (stores the reason), BackOffice.RedeemApprovalAdd (writer), BackOffice.GetRedeemDisplayData (reader for UI), BackOffice.GetCryptoTransactionsApprovals (reader), and History.BackOfficeRedeemApproval (audit trail).

---

## 2. Business Logic

### 2.1 Approval Reason Selection

**What**: BackOffice operators select a reason when approving a manual redeem request.

**Columns/Parameters Involved**: `RedeemApprovalReasonID`, `Name`

**Rules**:
- **1 = Other** — Generic catch-all reason. Operator provides additional context in free-text fields.
- The table is designed for extensibility — additional reasons can be added without schema changes.

---

## 3. Data Overview

| RedeemApprovalReasonID | Name | Meaning |
|---|---|---|
| 1 | Other | Generic approval reason for manual redeem review. Operator provides context in accompanying notes. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | RedeemApprovalReasonID | int | NO | - | VERIFIED | Primary key. Currently only value 1. Referenced by BackOffice.RedeemApproval. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable reason label. Displayed in BackOffice redeem approval screens. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.RedeemApproval | RedeemApprovalReasonID | Implicit | Stores the selected approval reason |
| History.BackOfficeRedeemApproval | RedeemApprovalReasonID | Implicit | Audit trail of approval reasons |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.RedeemApproval | Table | Stores approval reason per redeem review |
| History.BackOfficeRedeemApproval | Table | Historical audit of approvals |
| BackOffice.RedeemApprovalAdd | Stored Procedure | Writer — creates approval records |
| BackOffice.GetRedeemDisplayData | Stored Procedure | Reader — displays redeem data with reason |
| BackOffice.GetCryptoTransactionsApprovals | Stored Procedure | Reader — crypto redeem approvals |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DRAR | CLUSTERED PK | RedeemApprovalReasonID ASC | - | - | Active (FF=90) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DRAR | PRIMARY KEY | Unique reason identifier |

---

## 8. Sample Queries

### 8.1 List all approval reasons
```sql
SELECT  RedeemApprovalReasonID,
        Name
FROM    [Dictionary].[RedeemApprovalReason] WITH (NOLOCK)
ORDER BY RedeemApprovalReasonID;
```

### 8.2 Count approvals by reason
```sql
SELECT  rar.Name AS Reason,
        COUNT(*) AS ApprovalCount
FROM    [BackOffice].[RedeemApproval] ra WITH (NOLOCK)
JOIN    [Dictionary].[RedeemApprovalReason] rar WITH (NOLOCK) ON ra.RedeemApprovalReasonID = rar.RedeemApprovalReasonID
GROUP BY rar.Name;
```

### 8.3 Find recent approvals with reason
```sql
SELECT  TOP 10 ra.*, rar.Name AS Reason
FROM    [BackOffice].[RedeemApproval] ra WITH (NOLOCK)
JOIN    [Dictionary].[RedeemApprovalReason] rar WITH (NOLOCK) ON ra.RedeemApprovalReasonID = rar.RedeemApprovalReasonID
ORDER BY ra.RedeemApprovalReasonID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.RedeemApprovalReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.RedeemApprovalReason.sql*
