# Billing.PaymentActionUpdate

> Updates a legacy payment action record with the payment gateway's response - recording the outcome code, authorization reference, and approval number after gateway processing.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PaymentActionID (PK of History.PaymentAction) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.PaymentActionUpdate` is the gateway-response recorder for legacy payment actions. When the payment gateway responds to a transaction initiated via `Billing.PaymentActionAdd`, the application calls this procedure to update the action record with the gateway's reply: the response classification (ResponseID), the bank's authorization code (AuthCode), and the approval number. The final status transition (New -> InProcess -> Closed) is also applied here.

The procedure exists because payment actions are created before gateway communication and must be updated after the response arrives. The two-step pattern (Add then Update) accommodates asynchronous gateway processing - the action row is created immediately when the request is sent, then updated when the response is received (which may happen in a separate request/callback cycle).

This procedure targets `History.PaymentAction`, the action log for the legacy `Billing.Payment` table (frozen since 2011). It is the counterpart update procedure to `Billing.PaymentActionAdd`. Returns `@@ERROR` for the caller to handle.

---

## 2. Business Logic

### 2.1 Two-Step Gateway Response Recording Pattern

**What**: Records the payment gateway's response to a previously submitted payment action.

**Parameters Involved**: `@PaymentActionID`, `@PaymentActionStatusID`, `@ResponseID`, `@AuthCode`, `@ApprovalNumber`

**Rules**:
- Updates a single row in History.PaymentAction by @PaymentActionID (the identity returned by PaymentActionAdd)
- `@PaymentActionStatusID` transitions the action lifecycle: 1=New -> 2=InProcess -> 3=Closed
- `@ResponseID` maps to Dictionary.Response which links gateway response codes (e.g., "000 = Permitted", "001 = Card blocked") to payment status outcomes and protocol
- `@AuthCode` and `@ApprovalNumber` are gateway-issued references; ApprovalNumber is the issuing bank's approval confirmation, AuthCode is the authorization code for chargebacks/reconciliation
- Returns @@ERROR - non-zero indicates the PaymentActionID was not found or a constraint violation

**Diagram**:
```
PaymentActionAdd                      PaymentActionUpdate
(request sent to gateway)          (gateway response received)
        |                                     |
  INSERT History.PaymentAction         UPDATE History.PaymentAction
  Status=1 (New)                       Status=@PaymentActionStatusID (3=Closed)
  -> returns @PaymentActionID          ResponseID=@ResponseID
                                       AuthCode=@AuthCode
                                       ApprovalNumber=@ApprovalNumber
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentActionID | INTEGER | NO | - | CODE-BACKED | PK of the History.PaymentAction row to update. Must have been created by a prior call to Billing.PaymentActionAdd. |
| 2 | @PaymentActionStatusID | INTEGER | NO | - | VERIFIED | New processing state for the action. FK to Dictionary.PaymentActionStatus: 1=New (initiated), 2=InProcess (at gateway), 3=Closed (finalized). Typically set to 3 (Closed) when gateway responds. |
| 3 | @ResponseID | INTEGER | NO | - | CODE-BACKED | FK to Dictionary.Response. Maps the gateway response code to a structured outcome: includes ResponseCode (e.g., "000" = permitted), ResponseName, linked PaymentStatusID, and ShouldTerminate flag. ResponseID=1 is the success case ("Permitted transaction", Code=000). |
| 4 | @AuthCode | VARCHAR(20) | YES | - | CODE-BACKED | Authorization code issued by the payment gateway or acquiring bank. Used for chargeback resolution and payment reconciliation. Up to 20 characters. May be NULL if the gateway did not provide one (e.g., declined transactions). |
| 5 | @ApprovalNumber | VARCHAR(20) | YES | - | CODE-BACKED | Approval number from the issuing bank confirming the transaction was authorized. Distinct from AuthCode: the approval number is the bank's own reference, the AuthCode is the gateway's reference. Up to 20 characters. |
| 6 | RETURN value | INTEGER | - | - | CODE-BACKED | Returns @@ERROR. 0 = success (row updated). Non-zero = SQL Server error (typically row not found or type mismatch). Caller must check before proceeding. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentActionID | History.PaymentAction | MODIFIER | Updates the action row with gateway response data |
| @PaymentActionStatusID | Dictionary.PaymentActionStatus | Lookup | 1=New, 2=InProcess, 3=Closed |
| @ResponseID | Dictionary.Response | Lookup | Gateway response code mapping (ResponseCode, ResponseName, ShouldTerminate) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| [Billing.PaymentActionAdd](Billing.PaymentActionAdd.md) | Companion | Sequential | PaymentActionAdd creates the row; PaymentActionUpdate updates it after gateway response |
| Application billing service (external) | - | EXEC caller | Called when gateway response arrives after a PaymentActionAdd |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.PaymentActionUpdate (procedure)
└── History.PaymentAction (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentAction | Table | UPDATE target - sets ResponseID, AuthCode, ApprovalNumber, PaymentActionStatusID |
| Dictionary.PaymentActionStatus | Table | FK lookup - PaymentActionStatusID values |
| Dictionary.Response | Table | FK lookup - ResponseID maps gateway codes to payment outcomes |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Application billing service (external) | Application | Calls after gateway response in the legacy payment processing flow |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure. History.PaymentAction FK constraints enforce valid @ResponseID (-> Dictionary.Response) and @PaymentActionStatusID (-> Dictionary.PaymentActionStatus).

---

## 8. Sample Queries

### 8.1 Update a payment action with a successful gateway response

```sql
DECLARE @Err INTEGER;
EXEC @Err = Billing.PaymentActionUpdate
    @PaymentActionID      = 12345,
    @PaymentActionStatusID = 3,      -- Closed
    @ResponseID           = 1,       -- "Permitted transaction" (code 000)
    @AuthCode             = 'AUTH78901',
    @ApprovalNumber       = 'APP00123';
SELECT @Err AS ErrorCode;
```

### 8.2 Find all closed payment actions with their response details

```sql
SELECT
    hpma.PaymentActionID,
    hpma.PaymentID,
    hpma.TransactionID,
    hpma.Amount,
    hpma.PaymentDate,
    hpma.AuthCode,
    hpma.ApprovalNumber,
    r.ResponseCode,
    r.ResponseName,
    r.ShouldTerminate
FROM History.PaymentAction hpma WITH (NOLOCK)
INNER JOIN Dictionary.Response r WITH (NOLOCK) ON r.ResponseID = hpma.ResponseID
WHERE hpma.PaymentActionStatusID = 3  -- Closed
ORDER BY hpma.PaymentDate DESC;
```

### 8.3 Find declined legacy payment actions (ShouldTerminate = true)

```sql
SELECT
    hpma.PaymentActionID,
    hpma.PaymentID,
    hpma.Amount,
    r.ResponseCode,
    r.ResponseName
FROM History.PaymentAction hpma WITH (NOLOCK)
INNER JOIN Dictionary.Response r WITH (NOLOCK) ON r.ResponseID = hpma.ResponseID
WHERE r.ShouldTerminate = 1
ORDER BY hpma.PaymentDate DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 8/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers in SQL | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Billing.PaymentActionUpdate | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.PaymentActionUpdate.sql*
