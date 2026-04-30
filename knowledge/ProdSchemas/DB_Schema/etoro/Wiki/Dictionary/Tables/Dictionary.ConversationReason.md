# Dictionary.ConversationReason

> Lookup table defining the 4 reasons for customer service conversations — Sale, Risk, Support, and Account Management.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ConversationReasonID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.ConversationReason classifies why a customer service interaction was initiated. When a backoffice agent logs a conversation with a customer (phone, chat, or email), they record the primary reason from this table. This categorization enables reporting on conversation volume by reason, helps identify trends (e.g., spike in risk-related calls), and supports operational planning.

The table is referenced by `History.Conversation` (which stores the conversation log records) and `BackOffice.ConversationAdd` (the procedure that inserts new conversation entries). Together with `Dictionary.ConversationType`, these tables form the customer service interaction tracking system.

---

## 2. Business Logic

### 2.1 Conversation Reason Categories

**What**: Four business reasons for initiating customer contact.

**Columns/Parameters Involved**: `ConversationReasonID`, `Name`

**Rules**:
- **Sale (ID=1)**: Conversation initiated for sales/retention purposes — upselling products, encouraging deposits, or onboarding new customers. Handled by the sales team.
- **Risk (ID=2)**: Conversation initiated due to risk or compliance concerns — suspicious activity, KYC issues, account restrictions. Handled by risk/compliance team.
- **Support (ID=3)**: Conversation initiated for general customer support — technical issues, platform questions, account inquiries. Handled by support team.
- **Account Management (ID=4)**: Conversation initiated for ongoing account relationship management — premium customer check-ins, portfolio reviews, VIP service. Handled by account managers.

---

## 3. Data Overview

| ConversationReasonID | Name | Meaning |
|---|---|---|
| 1 | Sale | Sales or retention outreach — agent contacts customer to encourage deposits, explain products, or retain a customer considering leaving. Tracked for sales performance metrics. |
| 2 | Risk | Risk/compliance-driven contact — agent reaches out about suspicious activity, missing KYC documents, or account restrictions. Often triggered by automated risk alerts. |
| 3 | Support | General customer support — customer contacted with a question, technical issue, or service request. Most common conversation type by volume. |
| 4 | Account Management | Relationship management for premium or high-value customers — proactive check-ins, portfolio discussions, or VIP service requests. Typically initiated by dedicated account managers. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConversationReasonID | int | NO | - | VERIFIED | Primary key identifying the conversation reason. Values 1-4. Referenced by `History.Conversation.ConversationReasonID` to classify why the interaction occurred. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Reason label ('Sale', 'Risk', 'Support', 'Account Management'). Enforced unique via `DCOR_NAME` index. Used in BackOffice UI dropdowns and conversation reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Conversation | ConversationReasonID | Implicit FK | Each logged conversation stores the reason for the interaction |
| BackOffice.ConversationAdd | @ConversationReasonID | Procedure parameter | Accepts reason ID when creating a new conversation record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Conversation | Table | Stores conversation reason |
| BackOffice.ConversationAdd | Procedure | Creates conversations with reason ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCOR | CLUSTERED PK | ConversationReasonID ASC | - | - | Active |
| DCOR_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all conversation reasons
```sql
SELECT  ConversationReasonID,
        Name
FROM    Dictionary.ConversationReason WITH (NOLOCK)
ORDER BY ConversationReasonID;
```

### 8.2 Count conversations by reason
```sql
SELECT  CR.ConversationReasonID,
        CR.Name AS Reason,
        COUNT(HC.ConversationID) AS ConversationCount
FROM    Dictionary.ConversationReason CR WITH (NOLOCK)
LEFT JOIN History.Conversation HC WITH (NOLOCK)
        ON HC.ConversationReasonID = CR.ConversationReasonID
GROUP BY CR.ConversationReasonID, CR.Name
ORDER BY CR.ConversationReasonID;
```

### 8.3 Find risk-related conversations
```sql
SELECT  HC.*
FROM    History.Conversation HC WITH (NOLOCK)
WHERE   HC.ConversationReasonID = 2
ORDER BY HC.ConversationID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConversationReason | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ConversationReason.sql*
