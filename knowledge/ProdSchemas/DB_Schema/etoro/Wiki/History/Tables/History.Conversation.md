# History.Conversation

> Back-office CRM log of customer conversations (phone, chat, email) by eToro account managers from 2008-2013 - 359,650 interactions across 127,365 customers and 120 managers, majority Phone type for Sale and Support purposes.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | ConversationID - int IDENTITY PK CLUSTERED |
| **Partition** | No |
| **Temporal** | No |
| **Indexes** | 4 (1 PK clustered + 3 nonclustered on CID, ConversationTypeID, ManagerID), FILLFACTOR=90, on [HISTORY] |

---

## 1. Business Meaning

History.Conversation is the CRM conversation log for eToro's back-office operations. It records every interaction between an account manager (BackOffice.Manager) and a customer (BackOffice.Customer) - whether by phone call, live chat, or email. Each row captures who contacted whom, when, what channel was used, why (the business reason), and a free-text memo of what was discussed.

This is legacy data spanning July 2008 to October 2013 (359,650 rows). The back-office CRM function was active in eToro's early retail brokerage era when managers proactively called customers for sales and retention. The table has been inactive since late 2013, replaced by modern CRM tooling.

**Key distributions:**
- Phone calls dominate: 298,722 rows (83%) - managers calling customers
- Email: 35,672 rows (10%)
- Chat: 25,256 rows (7%)
- Answered: 182,994 (51%) - about half of outbound contacts reached the customer
- Dominant reason: Sale (ConversationReasonID=1), with Support (3), Account Management (4), and Risk (2)

---

## 2. Business Logic

### 2.1 Conversation Recording

**What**: Logs each manager-customer interaction with channel, reason, answer status, and memo.

**Columns/Parameters Involved**: `CID`, `ManagerID`, `ConversationTypeID`, `ConversationReasonID`, `Occurred`, `Answered`, `Memo`

**Rules**:
- ConversationID is auto-incremented (IDENTITY) - no business key
- Occurred = UTC timestamp when the conversation took place
- Answered = 1 if the customer was reached; 0 if the attempt was not answered (unanswered call/message)
- Memo = free text written by the manager summarizing the conversation (varchar(max) - can be long notes)
- One row per conversation attempt - multiple rows per CID/ManagerID pair are normal

### 2.2 Channel Distribution

| ConversationTypeID | Name | Row Count | % |
|-------------------|------|-----------|---|
| 1 | Phone | 298,722 | 83% |
| 3 | Email | 35,672 | 10% |
| 2 | Chat | 25,256 | 7% |

### 2.3 Conversation Reason Distribution

| ConversationReasonID | Name | Description |
|--------------------|------|-------------|
| 1 | Sale | Sales-motivated outreach - convincing customer to deposit or trade |
| 2 | Risk | Risk management - addressing leverage, exposure, or account risk |
| 3 | Support | Customer support - resolving issues (password, deposits, platform) |
| 4 | Account Management | General account management and retention |

---

## 3. Data Overview

| Metric | Value |
|--------|-------|
| **Total Rows** | 359,650 |
| **Date Range** | 2008-07-22 to 2013-10-21 |
| **Distinct Customers** | 127,365 |
| **Distinct Managers** | 120 |
| **Answered Rate** | 51% (182,994 of 359,650) |
| **Status** | Inactive since October 2013 |

Sample conversations:

| ConversationID | CID | ManagerID | Type | Reason | Occurred | Answered | Memo (snippet) |
|---------------|-----|----------|------|--------|----------|---------|----------------|
| 359679 | 2932283 | 489 | Phone | Support | 2013-10-21 | Yes | "called and told her will send her the steps to change her password" |
| 359678 | 1096331 | 300 | Phone | Sale | 2012-09-04 | Yes | "he asked about the western union told him i'm following the issue" |
| 359677 | 2290960 | 300 | Phone | Sale | 2012-08-27 | Yes | "she sent money through from western union" |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ConversationID | int IDENTITY | NO | - | VERIFIED | Auto-incremented unique ID for each conversation record. PK. NOT FOR REPLICATION flag prevents identity value replication in subscriber databases. |
| 2 | CID | int | NO | - | VERIFIED | Customer ID. FK to BackOffice.Customer(CID). The customer who was contacted. |
| 3 | ManagerID | int | NO | - | VERIFIED | Back-office manager ID. FK to BackOffice.Manager(ManagerID). The eToro employee who initiated or conducted the conversation. |
| 4 | ConversationTypeID | int | NO | - | VERIFIED | Channel of communication. FK to Dictionary.ConversationType. Values: 1=Phone (83%), 2=Chat (7%), 3=Email (10%). |
| 5 | Occurred | datetime | NO | - | VERIFIED | UTC timestamp when the conversation took place or was attempted. |
| 6 | Answered | bit | NO | - | VERIFIED | Whether the customer was reached. 1=answered/responded; 0=no answer (missed call, no reply). ~51% answered. |
| 7 | Memo | varchar(max) | YES | - | VERIFIED | Free-text notes written by the manager summarizing the conversation content. Can be NULL (no notes recorded). Examples: "called and told her...", "he asked about western union...". Stored in TEXTIMAGE_ON [HISTORY] filegroup. |
| 8 | ConversationReasonID | int | NO | - | VERIFIED | Business reason for the conversation. FK to Dictionary.ConversationReason. Values: 1=Sale, 2=Risk, 3=Support, 4=Account Management. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FK (FK_BCST_HCON) | The customer who was contacted. |
| ManagerID | BackOffice.Manager | FK (FK_BMNG_HCON) | The manager who conducted the conversation. |
| ConversationTypeID | Dictionary.ConversationType | FK (FK_DCOT_HCON) | Channel: 1=Phone, 2=Chat, 3=Email. |
| ConversationReasonID | Dictionary.ConversationReason | FK (FK_DCOR_HCON) | Business reason: 1=Sale, 2=Risk, 3=Support, 4=Account Management. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.Conversation (table)
  -> BackOffice.Customer (FK - customer identity)
  -> BackOffice.Manager (FK - manager identity)
  -> Dictionary.ConversationType (FK - channel lookup)
  -> Dictionary.ConversationReason (FK - reason lookup)
```

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Options |
|-----------|------|-------------|-----------------|---------|
| PK_HCON | CLUSTERED PK | ConversationID ASC | - | FILLFACTOR=90, on [HISTORY] |
| HCON_CID | NONCLUSTERED | CID ASC | - | FILLFACTOR=90, on [HISTORY] |
| HCON_CONVERSATIONTYPE | NONCLUSTERED | ConversationTypeID ASC | - | FILLFACTOR=90, on [HISTORY] |
| HCON_MANAGER | NONCLUSTERED | ManagerID ASC | - | FILLFACTOR=90, on [HISTORY] |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HCON | PRIMARY KEY CLUSTERED | ConversationID, FILLFACTOR=90 |
| FK_BCST_HCON | FOREIGN KEY | CID -> BackOffice.Customer(CID) |
| FK_BMNG_HCON | FOREIGN KEY | ManagerID -> BackOffice.Manager(ManagerID) |
| FK_DCOR_HCON | FOREIGN KEY | ConversationReasonID -> Dictionary.ConversationReason(ConversationReasonID) |
| FK_DCOT_HCON | FOREIGN KEY | ConversationTypeID -> Dictionary.ConversationType(ConversationTypeID) |

---

## 8. Sample Queries

### 8.1 Get all conversations for a customer
```sql
SELECT c.ConversationID, c.Occurred, c.Answered,
       ct.Name AS Type, cr.Name AS Reason,
       c.Memo
FROM History.Conversation c WITH (NOLOCK)
INNER JOIN Dictionary.ConversationType ct ON c.ConversationTypeID = ct.ConversationTypeID
INNER JOIN Dictionary.ConversationReason cr ON c.ConversationReasonID = cr.ConversationReasonID
WHERE c.CID = 2932283
ORDER BY c.Occurred DESC;
```

### 8.2 Manager activity summary
```sql
SELECT c.ManagerID, COUNT(*) AS TotalConversations,
       SUM(CASE WHEN c.Answered=1 THEN 1 ELSE 0 END) AS Answered,
       COUNT(DISTINCT c.CID) AS UniqueCustomers
FROM History.Conversation c WITH (NOLOCK)
GROUP BY c.ManagerID
ORDER BY TotalConversations DESC;
```

### 8.3 Conversation distribution by type and reason
```sql
SELECT ct.Name AS Type, cr.Name AS Reason, COUNT(*) AS Cnt
FROM History.Conversation c WITH (NOLOCK)
INNER JOIN Dictionary.ConversationType ct ON c.ConversationTypeID = ct.ConversationTypeID
INNER JOIN Dictionary.ConversationReason cr ON c.ConversationReasonID = cr.ConversationReasonID
GROUP BY ct.Name, cr.Name
ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specific to this object. Table represents legacy CRM data from 2008-2013 back-office operations.

---

*Generated: 2026-03-19 | Quality: 9.2/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.5/10, Sources: 6.5/10)*
*Confidence: 0 EXPERT, 7 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Dictionary lookups verified via live data (ConversationType, ConversationReason)*
*Object: History.Conversation | Type: Table | Source: etoro/etoro/History/Tables/History.Conversation.sql*
