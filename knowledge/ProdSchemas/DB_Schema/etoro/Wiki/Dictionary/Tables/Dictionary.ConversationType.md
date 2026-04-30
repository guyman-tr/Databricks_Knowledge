# Dictionary.ConversationType

> Lookup table defining the 3 channels for customer service conversations — Phone, Chat, and Email.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | ConversationTypeID (int, PK) |
| **Partition** | DICTIONARY filegroup |
| **Indexes** | 2 active (clustered PK + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.ConversationType identifies the communication channel used for a customer service interaction. When a backoffice agent logs a conversation, they record whether it occurred via phone call, live chat, or email. This classification supports channel-based reporting (e.g., what percentage of interactions are phone vs chat), resource planning (staffing for each channel), and SLA tracking (different response time targets per channel).

Together with `Dictionary.ConversationReason`, this table provides the two key dimensions for customer service analytics — the WHY (reason) and the HOW (channel) of each interaction. Both are stored in `History.Conversation` and set via `BackOffice.ConversationAdd`.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Straightforward channel classification with three mutually exclusive options.

---

## 3. Data Overview

| ConversationTypeID | Name | Meaning |
|---|---|---|
| 1 | Phone | Voice call with the customer — real-time synchronous communication. Typically used for complex issues, account management, and sales calls. Higher cost per interaction but best for relationship building. |
| 2 | Chat | Live text chat via the platform's chat widget — real-time but allows agents to handle multiple conversations simultaneously. Primary channel for quick support questions and technical issues. |
| 3 | Email | Asynchronous email communication — used for non-urgent issues, formal correspondence, document requests, and follow-ups. Allows detailed written responses and paper trail. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConversationTypeID | int | NO | - | VERIFIED | Primary key identifying the communication channel. Values: 1=Phone, 2=Chat, 3=Email. Referenced by `History.Conversation.ConversationTypeID` to record which channel was used for each interaction. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Channel name ('Phone', 'Chat', 'Email'). Enforced unique via `DCOT_NAME` index. Used in BackOffice UI dropdowns and conversation reports. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.Conversation | ConversationTypeID | Implicit FK | Each logged conversation records which communication channel was used |
| BackOffice.ConversationAdd | @ConversationTypeID | Procedure parameter | Accepts channel ID when creating a new conversation record |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.Conversation | Table | Stores conversation channel type |
| BackOffice.ConversationAdd | Procedure | Creates conversations with channel ID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DCOT | CLUSTERED PK | ConversationTypeID ASC | - | - | Active |
| DCOT_NAME | UNIQUE NC | Name ASC | - | - | Active |

### 7.2 Constraints

None beyond PK and unique index.

---

## 8. Sample Queries

### 8.1 List all conversation channels
```sql
SELECT  ConversationTypeID,
        Name
FROM    Dictionary.ConversationType WITH (NOLOCK)
ORDER BY ConversationTypeID;
```

### 8.2 Count conversations by channel
```sql
SELECT  CT.ConversationTypeID,
        CT.Name AS Channel,
        COUNT(HC.ConversationID) AS ConversationCount
FROM    Dictionary.ConversationType CT WITH (NOLOCK)
LEFT JOIN History.Conversation HC WITH (NOLOCK)
        ON HC.ConversationTypeID = CT.ConversationTypeID
GROUP BY CT.ConversationTypeID, CT.Name
ORDER BY CT.ConversationTypeID;
```

### 8.3 Show conversations with resolved channel and reason
```sql
SELECT  HC.ConversationID,
        CT.Name AS Channel,
        CR.Name AS Reason
FROM    History.Conversation HC WITH (NOLOCK)
INNER JOIN Dictionary.ConversationType CT WITH (NOLOCK)
        ON CT.ConversationTypeID = HC.ConversationTypeID
INNER JOIN Dictionary.ConversationReason CR WITH (NOLOCK)
        ON CR.ConversationReasonID = HC.ConversationReasonID
ORDER BY HC.ConversationID DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.ConversationType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.ConversationType.sql*
