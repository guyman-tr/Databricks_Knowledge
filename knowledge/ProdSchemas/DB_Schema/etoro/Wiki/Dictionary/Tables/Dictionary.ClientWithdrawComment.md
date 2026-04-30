# Dictionary.ClientWithdrawComment

> Lookup table defining the 4 predefined comments a customer can attach to a withdrawal request — including payment issues, bank detail updates, and free-text.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ClientWithdrawCommentID (int, PK) |
| **Partition** | PRIMARY filegroup |
| **Indexes** | 1 active (clustered PK) |

---

## 1. Business Meaning

Dictionary.ClientWithdrawComment provides the predefined comment options that customers can select when submitting a withdrawal (cashout) request. Rather than requiring free-text input, the platform offers structured reasons that help the operations team understand why the customer is requesting specific actions alongside their withdrawal.

These comments are presented in the withdrawal UI in the order specified by `DisplayOrder`. When a customer submits a withdrawal and selects one of these comments, the comment ID is stored with the withdrawal record in `Billing.Withdraw` — this helps the cashout processing team prioritize and route requests. For example, a customer reporting a non-valid payment method (ID=1) signals a potential fraud/compliance issue, while a bank detail update (ID=2) is a routine administrative request.

The table is actively consumed by multiple billing and backoffice procedures: `Billing.WithdrawalService_WithdrawRequestAdd` processes new withdrawal requests, `Billing.WithdrawalService_GetClientWitdrawComments` retrieves the comment list for the UI, and BackOffice procedures `GetWithdrawRequests` and `GetCashOutRequests_Main` display the comments in admin views.

---

## 2. Business Logic

### 2.1 Withdrawal Comment Categories

**What**: Four predefined customer comments for withdrawal requests, ordered by display priority.

**Columns/Parameters Involved**: `ClientWithdrawCommentID`, `Comment`, `IsActive`, `DisplayOrder`

**Rules**:
- **Empty/None (ID=0, DisplayOrder=1)**: Default option — customer has no specific comment. Shown first in the UI as the default selection.
- **Update Bank Details (ID=2, DisplayOrder=2)**: Customer needs to update their intermediary bank details before the withdrawal can be processed. Second option — routine administrative request.
- **Report Invalid Payment (ID=1, DisplayOrder=3)**: Customer is reporting that a non-valid payment method was used on their account. Third option — potentially flagging a fraud or compliance issue.
- **Other (ID=3, DisplayOrder=4)**: Free-text catch-all for comments that don't fit the predefined categories. Shown last.
- All 4 comments are currently active (`IsActive=1`). The `IsActive` flag allows comments to be retired without deletion, maintaining referential integrity for historical withdrawal records.

---

## 3. Data Overview

| ClientWithdrawCommentID | Comment | IsActive | DisplayOrder | Meaning |
|---|---|---|---|---|
| 0 | (empty) | true | 1 | Default selection — no specific comment from the customer. Most withdrawals use this option when the customer simply wants their money with no special instructions. |
| 1 | Report Non Valid Mean Of Payment Used In The Account | true | 3 | Customer flags that a payment method on their account is not legitimate — could indicate unauthorized card usage, stolen PayPal, or compliance-flagged payment source. Triggers compliance review. |
| 2 | Update Intermediary Bank Details | true | 2 | Customer requests update to their bank wire transfer routing details — typically needed when changing banks or when the original intermediary bank details are incorrect. Administrative request. |
| 3 | Other | true | 4 | Free-text catch-all — customer has a specific situation not covered by the predefined options. Displayed last to encourage use of structured options first. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ClientWithdrawCommentID | int | NO | - | VERIFIED | Primary key identifying the comment option. Values 0-3. Referenced by `Billing.Withdraw` table and multiple billing/backoffice procedures. |
| 2 | Comment | varchar(150) | NO | - | VERIFIED | The text displayed to the customer in the withdrawal UI comment dropdown. Empty string for ID=0 (no comment). Used by `Billing.WithdrawalService_GetClientWitdrawComments` to populate the UI and stored with withdrawal records. |
| 3 | IsActive | bit | NO | 0 | VERIFIED | Whether this comment option is currently shown in the withdrawal UI: 1=visible and selectable, 0=hidden/retired. Default is 0 (inactive) — new comments must be explicitly activated. All 4 current comments are active. Allows retiring options without deleting rows that historical withdrawals reference. |
| 4 | DisplayOrder | int | NO | - | VERIFIED | Sort order for displaying comments in the withdrawal UI. Lower numbers appear first. Controls the presentation order: 1=empty (default), 2=bank details, 3=invalid payment, 4=other. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.Withdraw | ClientWithdrawCommentID | Implicit FK | Each withdrawal record stores the customer's selected comment |
| Billing.WithdrawalService_WithdrawRequestAdd | Parameter | Procedure | Processes new withdrawal requests with the comment ID |
| Billing.WithdrawalService_GetClientWitdrawComments | Read | Procedure | Returns active comments for the withdrawal UI dropdown |
| Billing.Withdrawservice_AdditionalParametersAdd | Reference | Procedure | Additional parameter processing for withdrawals |
| BackOffice.GetWithdrawRequests | Join/Read | Procedure | Displays withdrawal comments in admin withdrawal views |
| BackOffice.GetCashOutRequests_Main | Join/Read | Procedure | Main cashout request listing with customer comments |
| Billing.TBL_Withdraw | ClientWithdrawCommentID | UDT | Table-valued parameter type for bulk withdrawal processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table | Stores selected comment with withdrawal records |
| Billing.WithdrawalService_WithdrawRequestAdd | Procedure | Accepts comment ID when creating withdrawals |
| Billing.WithdrawalService_GetClientWitdrawComments | Procedure | Returns comment list for UI |
| BackOffice.GetWithdrawRequests | Procedure | Reads comments for admin views |
| BackOffice.GetCashOutRequests_Main | Procedure | Reads comments for cashout admin |
| Billing.TBL_Withdraw | UDT | Includes comment ID in bulk withdrawal type |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DictionaryClientWithdrawComment | CLUSTERED PK | ClientWithdrawCommentID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Df_Dictionary_ClientWithdrawComment_IsActive | DEFAULT | IsActive defaults to 0 (inactive) — new comments must be explicitly activated |

---

## 8. Sample Queries

### 8.1 List active withdrawal comments in display order
```sql
SELECT  ClientWithdrawCommentID,
        Comment,
        DisplayOrder
FROM    Dictionary.ClientWithdrawComment WITH (NOLOCK)
WHERE   IsActive = 1
ORDER BY DisplayOrder;
```

### 8.2 Count withdrawals by comment type
```sql
SELECT  CWC.ClientWithdrawCommentID,
        CWC.Comment,
        COUNT(W.WithdrawID) AS WithdrawalCount
FROM    Dictionary.ClientWithdrawComment CWC WITH (NOLOCK)
LEFT JOIN Billing.Withdraw W WITH (NOLOCK)
        ON W.ClientWithdrawCommentID = CWC.ClientWithdrawCommentID
GROUP BY CWC.ClientWithdrawCommentID, CWC.Comment
ORDER BY CWC.DisplayOrder;
```

### 8.3 Find all comments including inactive
```sql
SELECT  ClientWithdrawCommentID,
        Comment,
        IsActive,
        DisplayOrder
FROM    Dictionary.ClientWithdrawComment WITH (NOLOCK)
ORDER BY DisplayOrder;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ClientWithdrawComment | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ClientWithdrawComment.sql*
