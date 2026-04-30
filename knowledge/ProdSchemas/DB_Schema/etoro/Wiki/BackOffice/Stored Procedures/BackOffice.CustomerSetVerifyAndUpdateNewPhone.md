# BackOffice.CustomerSetVerifyAndUpdateNewPhone

> Atomically updates a customer's phone verification status and replaces their phone number on record, supporting BackOffice phone change workflows.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID - internal customer identifier |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

BackOffice.CustomerSetVerifyAndUpdateNewPhone is a dual-update procedure used when a customer's phone number is changed as part of a BackOffice-initiated verification workflow. It performs two operations in sequence: (1) sets the phone verification result flag on the BackOffice compliance profile, and (2) updates the customer's phone number in the core identity table. The combination represents a "verify and replace" action - a BackOffice agent has confirmed a new phone number is valid and is simultaneously marking it as verified and recording it.

The procedure is notably bare: no BEGIN/END block, no transaction, no error handling. If the first UPDATE succeeds but the second fails, the state will be partially applied. This design suggests the procedure is called in an already-transactional context from the application layer, or it predates stricter error handling standards.

Unlike `BackOffice.CustomerSetPhoneVerified_JunkNoga240325`, this procedure also updates the actual phone number (`Customer.Customer.Phone`), making it a more complete phone-change handler.

---

## 2. Business Logic

### 2.1 Two-Step Phone Verification and Number Update

**What**: Sets verification status first, then replaces the phone number - a combined "verify new phone" operation.

**Columns/Parameters Involved**: `@CID`, `@PhoneVerifiedID`, `@Phone`, `BackOffice.Customer.PhoneVerifiedID`, `Customer.Customer.Phone`

**Rules**:
- Step 1: UPDATE `BackOffice.Customer.PhoneVerifiedID = @PhoneVerifiedID` WHERE CID = @CID.
- Step 2: UPDATE `Customer.Customer.Phone = @Phone` WHERE CID = @CID.
- No transaction wrapping - the two UPDATEs execute independently. If step 2 fails after step 1 succeeds, BackOffice.Customer.PhoneVerifiedID is updated but the phone number is not changed.
- No return value - any errors propagate as SQL exceptions to the caller.
- Trigger on BackOffice.Customer (CustomerHistoryUpdate) records the PhoneVerifiedID change in History.BackOfficeCustomer.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INTEGER | NO | - | CODE-BACKED | Internal Customer ID. Used in both UPDATE statements to target the same customer across BackOffice.Customer and Customer.Customer. |
| 2 | @PhoneVerifiedID | INTEGER | NO | - | CODE-BACKED | The phone verification result to apply. Written to BackOffice.Customer.PhoneVerifiedID. Represents whether the new phone was successfully verified (e.g., via OTP/SMS confirmation). Lookup values in application/Dictionary layer. |
| 3 | @Phone | VARCHAR(24) | NO | - | CODE-BACKED | The new phone number to record for the customer. Written to Customer.Customer.Phone. Replaces any previously stored phone number. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | BackOffice.Customer | Modifier | UPDATE PhoneVerifiedID - sets the verification result on the compliance profile. |
| @CID | Customer.Customer | Modifier | UPDATE Phone - replaces the customer's stored phone number with the new verified number. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice tooling / phone change workflow | EXEC | Caller | Called when a BackOffice agent processes a phone number change request and marks the new number as verified. No SQL-layer callers found. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CustomerSetVerifyAndUpdateNewPhone (procedure)
├── BackOffice.Customer (table) - UPDATE PhoneVerifiedID
└── Customer.Customer (table) - UPDATE Phone
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | UPDATE - sets PhoneVerifiedID = @PhoneVerifiedID WHERE CID = @CID |
| Customer.Customer | Table | UPDATE - sets Phone = @Phone WHERE CID = @CID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice phone change workflow | External | EXEC - called to confirm and record a new verified phone number |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No transaction | Risk | Two independent UPDATEs with no BEGIN TRAN - partial failure leaves BackOffice.Customer.PhoneVerifiedID updated but phone number unchanged. |
| No error handling | Risk | Bare procedure body - no TRY/CATCH or RETURN @@ERROR. Exceptions propagate directly to caller. |
| No BEGIN/END | Style | Procedure body consists of two raw UPDATE statements without a BEGIN/END block - valid SQL Server syntax but non-standard. |

---

## 8. Sample Queries

### 8.1 Set verification status and update phone number
```sql
EXEC BackOffice.CustomerSetVerifyAndUpdateNewPhone
    @CID = 12345678,
    @PhoneVerifiedID = 2,
    @Phone = '+1-555-123-4567'
```

### 8.2 Verify the update was applied to both tables
```sql
SELECT
    bc.CID,
    bc.PhoneVerifiedID,
    cc.Phone
FROM BackOffice.Customer bc WITH (NOLOCK)
JOIN Customer.Customer cc WITH (NOLOCK) ON cc.CID = bc.CID
WHERE bc.CID = 12345678
```

### 8.3 Find customers whose BackOffice phone verification and Customer.Customer phone were recently changed
```sql
SELECT TOP 20
    h.CID,
    h.ValidFrom,
    h.PhoneVerifiedID
FROM History.BackOfficeCustomer h WITH (NOLOCK)
WHERE h.ValidFrom >= DATEADD(DAY, -1, GETUTCDATE())
    AND h.PhoneVerifiedID IS NOT NULL
ORDER BY h.ValidFrom DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CustomerSetVerifyAndUpdateNewPhone | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CustomerSetVerifyAndUpdateNewPhone.sql*
