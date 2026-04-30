# Customer.InsertTwoFactorVerificationDetails

> Creates a new 2FA OTP challenge record in Customer.TwoFactorVerificationDetails when a verification code is dispatched to a customer via SMS or voice call.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @referenceID, @gcid -> INSERT into Customer.TwoFactorVerificationDetails |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Customer.InsertTwoFactorVerificationDetails is the writer half of the 2FA OTP lifecycle. Each time the system dispatches an OTP code to a customer (via SMS or voice call), this procedure creates a new row in Customer.TwoFactorVerificationDetails capturing the challenge. The application generates the ReferenceID (a session GUID) and the VerificationCode before calling this procedure; the procedure stores them alongside the delivery channel type.

The @sendMethodTypeID parameter was added on 06/12/2017 by Geri Reshef (ticket 49718) to record whether the code was sent via SMS (1) or voice call (2), enabling channel-specific analytics and debugging.

Data flows: The application generates the OTP code and ReferenceID, then calls this procedure. Default values in Customer.TwoFactorVerificationDetails supply VerificationDate=GETUTCDATE(), Success=0, and VerificationTries=0. The application retains the ReferenceID for subsequent calls to Customer.GetTwoFactorVerificationDetails (to retrieve and compare the entered code) and Customer.UpdateTwoFactorVerificationTries or Customer.UpdateTwoFactorVerificationDetails (to update the attempt state).

---

## 2. Business Logic

### 2.1 OTP Lifecycle - Initial State on INSERT

**What**: This procedure creates the initial state of a 2FA challenge with Success=0 and VerificationTries=0 (via table defaults).

**Columns/Parameters Involved**: `ReferenceID`, `GCID`, `VerificationCode`, `VerificationSendMethodTypeID`, `VerificationDate` (default), `Success` (default), `VerificationTries` (default)

**Rules**:
- VerificationDate defaults to GETUTCDATE() - the exact moment the code was dispatched
- Success defaults to 0 (BIT) - challenge starts as unverified
- VerificationTries defaults to 0 - no wrong attempts yet
- @sendMethodTypeID = NULL is valid for older callers that pre-date the channel parameter
- See Customer.TwoFactorVerificationDetails Section 2.1 for the full OTP lifecycle diagram

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @gcid | int | NO | - | VERIFIED | Group Customer ID of the customer receiving the OTP challenge. Written to TwoFactorVerificationDetails.GCID. Part of the CLUSTERED index on the target table. |
| 2 | @referenceID | uniqueidentifier | NO | - | VERIFIED | Application-generated GUID uniquely identifying this 2FA challenge session. Written to TwoFactorVerificationDetails.ReferenceID (NONCLUSTERED PK). The application must retain this value to retrieve or update the challenge later. |
| 3 | @verificationCode | varchar(32) | NO | - | VERIFIED | The OTP code string (typically a 6-digit number) to be sent to the customer. Stored for later comparison against the customer's entered value. Security-sensitive: should not be logged externally. |
| 4 | @sendMethodTypeID | int | YES | NULL | VERIFIED | Delivery channel: 1=SMS (text message), 2=call (automated voice call). NULL for callers predating this parameter (added 06/12/2017, ticket 49718). FK to Dictionary.TwoFactorVerificationSendMethodType. Written to TwoFactorVerificationDetails.VerificationSendMethodTypeID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| All params | Customer.TwoFactorVerificationDetails | Writer (INSERT) | Creates a new OTP challenge row with Success=0, Tries=0, VerificationDate=GETUTCDATE() |

### 5.2 Referenced By (other objects point to this)

No callers found in the codebase. Called externally by the application authentication service.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.InsertTwoFactorVerificationDetails (procedure)
└── Customer.TwoFactorVerificationDetails (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.TwoFactorVerificationDetails | Table | INSERT target - creates the OTP challenge record |

### 6.2 Objects That Depend On This

No dependents found in the codebase. Called externally.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. No transaction wrapper - relies on the INSERT being atomic by default.

---

## 8. Sample Queries

### 8.1 Create a new 2FA OTP challenge (SMS delivery)
```sql
EXEC Customer.InsertTwoFactorVerificationDetails
    @gcid = 12345678,
    @referenceID = 'A3F8D1C2-1234-5678-ABCD-9E0F12345678',
    @verificationCode = '742853',
    @sendMethodTypeID = 1;  -- 1 = SMS
```

### 8.2 Create a challenge with voice call delivery
```sql
EXEC Customer.InsertTwoFactorVerificationDetails
    @gcid = 12345678,
    @referenceID = NEWID(),
    @verificationCode = '391847',
    @sendMethodTypeID = 2;  -- 2 = call
```

### 8.3 Verify the inserted challenge record
```sql
SELECT ReferenceID, GCID, VerificationCode, VerificationDate, Success, VerificationTries, VerificationSendMethodTypeID
FROM Customer.TwoFactorVerificationDetails WITH (NOLOCK)
WHERE GCID = 12345678
ORDER BY VerificationDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| Ticket 49718 | Jira | Geri Reshef added @sendMethodTypeID parameter on 06/12/2017 to record OTP delivery channel (SMS vs voice) |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,5,8,10,11*
*Sources: Atlassian: 0 Confluence + 1 Jira (from SP comment) | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Customer.InsertTwoFactorVerificationDetails | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.InsertTwoFactorVerificationDetails.sql*
