# BackOffice.ConversationAdd

> Logs a new customer support or sales conversation record into History.Conversation, capturing the interaction type, manager, reason, and memo; returns the new ConversationID via OUTPUT parameter.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ConversationID (OUTPUT) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records customer interactions in the CRM conversation history. When a BackOffice manager (account manager, customer support agent) has a phone call, chat, or other interaction with a customer, they log it through this procedure. The resulting record in `History.Conversation` becomes the permanent audit trail of all customer-facing interactions - accessible for compliance reviews, account history lookups, and sales performance tracking.

Each conversation is typed by `ConversationTypeID` (e.g., inbound call, outbound call, email) and categorized by `ConversationReasonID` (e.g., deposit follow-up, withdrawal inquiry, welcome call). The `Answered` flag indicates whether the contact attempt was successful.

The procedure contains commented-out SQL Service Broker code that previously sent a message to a `svcCustomerSupport` service for specific conversation types (TypeID=1, ReasonID=1) - this was an integration with a downstream customer support workflow that has since been removed. The Service Broker logic also excluded test users (PlayerLevelID=4 in Customer.Customer).

---

## 2. Business Logic

### 2.1 Conversation Record Creation

**What**: Inserts a timestamped conversation record and returns the new identity via OUTPUT.

**Columns/Parameters Involved**: All insert fields, `@ConversationID`, `SCOPE_IDENTITY()`

**Rules**:
- INSERT INTO History.Conversation with Occurred = GETDATE() (server local time, not UTC)
- @LocalError = @@ERROR checked after INSERT: if non-zero -> RAISERROR(60000, 16, 1, 'BackOffice.ConversationAdd', @LocalError) and RETURN 60000
- Note: there is a duplicate @@ERROR check block in the source - the second check is a copy-paste artifact with no intervening statement; it will always show @@ERROR=0 if the first check passed
- @ConversationID = SCOPE_IDENTITY() after both error checks
- RETURN 0 on success

### 2.2 Removed: Service Broker Integration (Historical)

**What**: Previously sent XML to 'svcCustomerSupport' service for specific conversation types.

**Rules** (from commented-out code):
- Was triggered only for ConversationTypeID=1 AND ConversationReasonID=1
- Excluded test users: WHERE CID=@CID AND ISNULL(PlayerLevelID, 0) <> 4 (PlayerLevelID=4 = test user in Customer.Customer)
- XML contained: CID, ManagerID, ProviderID, OriginalCID, SerialID, SubSerialID, DownloadID, BannerID, LabelID, FunnelID, PlayerLevelID
- Sent via BEGIN DIALOG CONVERSATION / SEND ON CONVERSATION to 'svcCustomerSupport' service
- This entire block is commented out - Service Broker integration was removed

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. The customer who is the subject of this conversation. FK to Customer.Customer (via the commented-out code reference). Stored in History.Conversation.CID. |
| 2 | @ManagerID | INTEGER | NO | - | CODE-BACKED | The BackOffice manager/agent who conducted or logged the conversation. FK to BackOffice.Manager. Stored in History.Conversation.ManagerID. |
| 3 | @ConversationTypeID | INTEGER | NO | - | CODE-BACKED | Type of interaction (e.g., inbound call, outbound call, email, chat). FK to a ConversationType lookup table. Stored in History.Conversation.ConversationTypeID. |
| 4 | @Answered | BIT | NO | - | CODE-BACKED | Whether the contact attempt was answered/successful. 1=Answered, 0=Unanswered (no-pick-up, voicemail). Stored in History.Conversation.Answered. |
| 5 | @Memo | VARCHAR(MAX) | NO | - | CODE-BACKED | Free-text notes from the conversation. The agent's summary of what was discussed, actions taken, or follow-up needed. Stored in History.Conversation.Memo. |
| 6 | @ConversationReasonID | INTEGER | NO | - | CODE-BACKED | The reason or topic of the conversation (e.g., deposit follow-up, withdrawal question, welcome call, compliance check). FK to a ConversationReason lookup table. Stored in History.Conversation.ConversationReasonID. |

**Output Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 7 | @ConversationID | INTEGER | NO | - | CODE-BACKED | OUTPUT. The auto-generated identity of the newly inserted History.Conversation record. Set via SCOPE_IDENTITY(). |

**Return Value:**

| # | Element | Type | Description |
|---|---------|------|-------------|
| 8 | RETURN | INT | 0 on success; 60000 if the INSERT fails (@@ERROR != 0 after INSERT). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID / @ManagerID / all params | History.Conversation | WRITER (INSERT) | Inserts conversation record with Occurred=GETDATE() (cross-schema) |

### 5.2 Referenced By (other objects point to this)

No SP-to-SP callers found. Called from BackOffice CRM conversation logging UI.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.ConversationAdd (procedure)
+-- History.Conversation (table) [INSERT target - conversation audit trail, cross-schema]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Conversation | Table | INSERT: logs new conversation record with all input parameters and Occurred=GETDATE() |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice CRM UI | External | Calls this to log customer interaction records after phone calls, chats, or other contact events |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Occurred = GETDATE() | Design | Conversation timestamp uses server local time (not GETUTCDATE()). Be aware of timezone implications if comparing to UTC timestamps in other tables. |
| Error code 60000 | Application | Generic BackOffice error raised on INSERT failure; RAISERROR includes the source procedure name and original @@ERROR |
| Duplicate error check | Design | Two identical @@ERROR blocks exist; second is a copy-paste artifact with no logic between them (always 0 if first passed) |
| Removed Service Broker | Historical | Commented-out block previously sent XML to svcCustomerSupport for type=1/reason=1 combinations; integration was removed |

---

## 8. Sample Queries

### 8.1 Log a successful outbound call

```sql
DECLARE @NewConvID INT
EXEC BackOffice.ConversationAdd
    @CID = 12345,
    @ManagerID = 678,
    @ConversationTypeID = 2,    -- outbound call
    @Answered = 1,
    @Memo = 'Called re: pending deposit. Customer confirmed wire transfer sent.',
    @ConversationReasonID = 5,  -- deposit follow-up
    @ConversationID = @NewConvID OUTPUT
SELECT @NewConvID AS NewConversationID
```

### 8.2 Log an unanswered contact attempt

```sql
DECLARE @NewConvID INT
EXEC BackOffice.ConversationAdd
    @CID = 12345,
    @ManagerID = 678,
    @ConversationTypeID = 2,    -- outbound call
    @Answered = 0,              -- no answer
    @Memo = 'No answer. Left voicemail. Will retry tomorrow.',
    @ConversationReasonID = 3,  -- welcome call
    @ConversationID = @NewConvID OUTPUT
```

### 8.3 View conversation history for a customer

```sql
SELECT ConversationID, ManagerID, ConversationTypeID, ConversationReasonID,
    Occurred, Answered, LEFT(Memo, 100) AS MemoPreview
FROM History.Conversation WITH (NOLOCK)
WHERE CID = 12345
ORDER BY Occurred DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.ConversationAdd | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.ConversationAdd.sql*
