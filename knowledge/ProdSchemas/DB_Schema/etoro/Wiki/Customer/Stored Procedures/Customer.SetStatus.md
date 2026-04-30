# Customer.SetStatus

> Changes a customer's player status, writes an audit record to History.PlayerStatus, syncs the blocked flag to the STS authentication system, and optionally kicks the customer from the session if they are currently online.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID (input) - the customer being status-changed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Customer.SetStatus` is the authoritative procedure for changing a customer's account status in the eToro platform. Status changes have immediate security and operational consequences: blocked customers cannot log in, trade-blocked customers cannot open positions, and chat-blocked customers lose social features. The procedure enforces these consequences atomically by coordinating four systems in a single transaction.

This procedure is called when compliance, fraud investigation, customer support, or automated processes need to change a customer's access level - from normal operations to various blocked states or back. It replaces the SetBalance pattern with a status-focused workflow: read current state, update Customer.Customer, write audit trail, sync to STS authentication server, and optionally send a real-time notification to an online customer.

The cross-system write to `dbo.STS_User` (Security Token Service) is critical: this table controls whether the customer's existing sessions are treated as blocked. Without this update, a customer could remain logged in and trading even after being blocked in Customer.Customer.

---

## 2. Business Logic

### 2.1 Player Status System

**What**: 15 distinct account states controlling platform access, each with an IsBlocked flag for authentication blocking.

**Columns/Parameters Involved**: `@PlayerStatusID`, `Dictionary.PlayerStatus.IsBlocked`

**Rules**:
- PlayerStatusID values (Dictionary.PlayerStatus):
  - 1 = Normal (IsBlocked=0) - full access
  - 2 = Blocked (IsBlocked=1) - general compliance block
  - 3 = Chat Blocked (IsBlocked=0) - social features only blocked
  - 4 = Blocked Upon Request (IsBlocked=1) - self-requested or support block
  - 5 = Warning (IsBlocked=0) - flagged but not blocked
  - 6 = Blocked - Under Investigation (IsBlocked=1) - investigation hold
  - 7 = Scalpers Block (IsBlocked=1) - scalping/arbitrage abuse detected
  - 8 = Blocked - PayPal Investigation (IsBlocked=1) - payment dispute hold
  - 9 = Trade & MIMO Blocked (IsBlocked=0) - trading blocked, login allowed
  - 10 = Deposit Blocked (IsBlocked=0) - deposits blocked, trading allowed
  - 11 = Social Index (IsBlocked=0) - social index designation
  - 12 = Copy Block (IsBlocked=0) - copy trading blocked
  - 13 = Pending Verification (IsBlocked=0) - awaiting KYC/identity verification
  - 14 = Blocked - Failed Verification (IsBlocked=1) - failed KYC
  - 15 = Block Deposit & Trading (IsBlocked=0) - both deposit and trading blocked

### 2.2 Cross-System Block Sync

**What**: IsBlocked flag is propagated to the STS authentication system to enforce login blocking.

**Columns/Parameters Involved**: `@IsBlocked`, `dbo.STS_User.Blocked`, `@GCID`

**Rules**:
- After updating Customer.Customer, reads Dictionary.PlayerStatus.IsBlocked for the new status.
- Updates `dbo.STS_User.Blocked = @IsBlocked WHERE GCID = @GCID`.
- STS_User is the Security Token Service user table - controls active session validity.
- For statuses with IsBlocked=1 (2, 4, 6, 7, 8, 14): customer's active sessions are immediately invalidated.
- For statuses with IsBlocked=0: customer remains able to authenticate.

### 2.3 Real-Time Online Customer Notification

**What**: If the customer is currently online, sends an immediate message via the message queue to notify them of the status change.

**Columns/Parameters Involved**: `@MessageTemplateID`, `Customer.LoggedCustomer`, `@IsBlocked`, `@PlayerStatusID`

**Rules**:
- Only fires if customer EXISTS in Customer.LoggedCustomer (currently active session).
- Template selection:
  - IsBlocked = 1: Template 14 (kick login) - fired for all blocked states
  - PlayerStatusID = 3: Template 15 (kick chat) - chat blocked
  - PlayerStatusID = 9: Template 17 (trade block) - trade & MIMO blocked
  - All other statuses: no message sent (NULL template)
- Message sent via Customer.SendMessage with no parameter list (NULL @ParamList) - template is self-describing.
- If SendMessage fails: transaction is rolled back entirely and error 60000 is raised.

```
Status change:
  Update Customer.Customer.PlayerStatusID
  -> Audit: INSERT History.PlayerStatus
  -> Sync:  UPDATE dbo.STS_User.Blocked
  -> Notify (if online):
       IsBlocked=1       -> Template 14 (kick login)
       PlayerStatusID=3  -> Template 15 (kick chat)
       PlayerStatusID=9  -> Template 17 (trade block)
       other             -> no notification
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID whose status is being changed. Read from Customer.Customer to get current PlayerStatusID (for audit) and GCID (for STS sync). |
| 2 | @PlayerStatusID | INT | NO | - | VERIFIED | New player status to apply. FK to Dictionary.PlayerStatus: 1=Normal, 2=Blocked, 3=Chat Blocked, 4=Blocked Upon Request, 5=Warning, 6=Blocked-Investigation, 7=Scalpers Block, 8=Blocked-PayPal, 9=Trade & MIMO Blocked, 10=Deposit Blocked, 11=Social Index, 12=Copy Block, 13=Pending Verification, 14=Blocked-Failed Verification, 15=Block Deposit & Trading. |
| 3 | @ManagerID | INT | NO | - | CODE-BACKED | ID of the manager or system process that initiated the status change. Written to History.PlayerStatus.ChangedBy for audit traceability. |
| 4 | @Comment | VARCHAR(MAX) | NO | - | CODE-BACKED | Reason or notes for the status change. Written to History.PlayerStatus.Comment. Provides human-readable context for the audit record (e.g., "Compliance block - AML investigation", "Customer request"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer | READ + UPDATE | Reads current status for audit; updates to new PlayerStatusID |
| @PlayerStatusID | Dictionary.PlayerStatus | Lookup | Reads IsBlocked flag for STS sync and notification routing |
| @GCID | dbo.STS_User | UPDATE | Syncs IsBlocked to authentication system |
| (INSERT) | History.PlayerStatus | INSERT | Audit trail of all status changes |
| (EXEC) | Customer.SendMessage | Callee | Sends real-time notification to online customers (templates 14, 15, 17) |
| (CHECK) | Customer.LoggedCustomer | READ | Checks if customer is currently online before sending notification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice.GetCustomersForStatusChange | EXEC | Caller | Bulk status changes for compliance or administrative operations |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetStatus (procedure)
├── Customer.Customer (view) [READ current status + GCID; UPDATE PlayerStatusID]
├── History.PlayerStatus (table) [INSERT audit record]
├── Dictionary.PlayerStatus (table) [READ IsBlocked for new status]
├── dbo.STS_User (table) [UPDATE Blocked flag]
├── Customer.LoggedCustomer (view) [READ - check if customer is online]
└── Customer.SendMessage (procedure) [EXEC - kick notification if online]
      ├── Maintenance.MessageTemplate (table)
      ├── Dictionary.PromotionType (table)
      ├── Internal.GetMessageQueueID (procedure)
      ├── Internal.ConvertListToTable (function)
      ├── Customer.MessageQueue (table)
      └── Customer.CustomerToMessageQueue (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | View | READ current PlayerStatusID + GCID; UPDATE to new PlayerStatusID |
| History.PlayerStatus | Table | INSERT audit trail row |
| Dictionary.PlayerStatus | Table | READ IsBlocked flag for the new status |
| dbo.STS_User | Table | UPDATE Blocked column to enforce authentication blocking |
| Customer.LoggedCustomer | View | READ - EXISTS check for online customer presence |
| Customer.SendMessage | Procedure | EXEC - sends real-time notification to online customer |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.GetCustomersForStatusChange | Procedure | Calls SetStatus for bulk administrative status changes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Transaction wrapper | Transaction | All writes (Customer.Customer, History.PlayerStatus, STS_User, SendMessage) are atomic |
| RAISERROR 60000 | Error | Any intermediate failure rolls back and raises error 60000 |
| Online-only notification | Application | Customer.SendMessage is only called if customer EXISTS in Customer.LoggedCustomer |

---

## 8. Sample Queries

### 8.1 View status change history for a customer

```sql
SELECT
    ps.CID,
    ps.OldPlayerStatusID,
    old_s.Name AS OldStatusName,
    ps.NewPlayerStatusID,
    new_s.Name AS NewStatusName,
    ps.ChangedBy,
    ps.Occurred,
    ps.Comment
FROM History.PlayerStatus ps WITH (NOLOCK)
JOIN Dictionary.PlayerStatus old_s WITH (NOLOCK) ON old_s.PlayerStatusID = ps.OldPlayerStatusID
JOIN Dictionary.PlayerStatus new_s WITH (NOLOCK) ON new_s.PlayerStatusID = ps.NewPlayerStatusID
WHERE ps.CID = 12345
ORDER BY ps.Occurred DESC
```

### 8.2 Find all currently blocked customers by status type

```sql
SELECT
    c.CID,
    c.PlayerStatusID,
    ps.Name AS StatusName,
    ps.IsBlocked
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = c.PlayerStatusID
WHERE ps.IsBlocked = 1
ORDER BY c.PlayerStatusID, c.CID
```

### 8.3 Verify STS sync consistency - blocked in Customer but not in STS

```sql
SELECT
    c.CID,
    c.PlayerStatusID,
    ps.Name AS StatusName,
    su.Blocked AS STS_Blocked
FROM Customer.Customer c WITH (NOLOCK)
JOIN Dictionary.PlayerStatus ps WITH (NOLOCK) ON ps.PlayerStatusID = c.PlayerStatusID
JOIN dbo.STS_User su WITH (NOLOCK) ON su.GCID = c.GCID
WHERE ps.IsBlocked = 1
  AND su.Blocked = 0
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 5.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetStatus | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetStatus.sql*
