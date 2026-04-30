# Billing.UpdatePWMBAddAccountRequest

> Updates the status and optionally the FundingID of a PWMB payment account addition request, while simultaneously archiving the change to History.PWMBAddAccountRequest via the UPDATE...OUTPUT...INTO pattern.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ExternalTransactionID (VARCHAR(15)) - PK of Billing.PWMBAddAccountRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.UpdatePWMBAddAccountRequest` is the state transition procedure for PWMB (Private Wealth Management Business) payment account addition requests. When a PWMB customer submits a request to add a new payment instrument (credit card, bank account), the request is tracked in `Billing.PWMBAddAccountRequest` with an `ExternalTransactionID` assigned by the payment provider. As the provider processes the request (verification, card tokenization, etc.), this SP is called to advance the request's status and, when the account is successfully added, to link the resulting `FundingID` to the request record.

The `UPDATE...OUTPUT...INTO` pattern used here atomically writes the state change and archives the updated record snapshot to `History.PWMBAddAccountRequest` - providing a complete audit trail of every status transition for the account addition request.

Created June 2019 by Adi Cohen (ticket RD-7470). No explicit EXECUTE grant found in SSDT UsersPermissions - likely called via schema-level permissions by the PWMB service.

**Current data state**: The live table has records with Status 4, 6, 7, 8. The history table contains all values 1-8, indicating statuses 1, 2, 3, 5 are transient states overwritten during normal processing. Last activity observed: October 2023.

---

## 2. Business Logic

### 2.1 Status Transition with Atomic History Archival

**What**: Advances the PWMB account request to a new status, optionally recording the FundingID assigned by the provider, while simultaneously inserting the updated snapshot into the history table.

**Columns/Parameters Involved**: `@ExternalTransactionID`, `@FundingID`, `@Status`, `Billing.PWMBAddAccountRequest.FundingID`, `Billing.PWMBAddAccountRequest.Status`, `Billing.PWMBAddAccountRequest.LastModificationTime`

**Rules**:
- Identifies the request by `ExternalTransactionID` (VARCHAR(15), PK CLUSTERED) - the provider's reference for this request
- `FundingID = ISNULL(@FundingID, FundingID)`: FundingID is only set when @FundingID is provided (non-NULL); otherwise retains current value. FundingID represents the Billing.Funding payment instrument created for this customer when the account addition succeeds.
- `Status = ISNULL(@Status, Status)`: Note that @Status has no default (declared as INT, not INT=NULL) - passing NULL for @Status leaves status unchanged; a non-NULL value must be provided for status to update.
- `LastModificationTime = GETUTCDATE()`: always updated on every call
- `OUTPUT INSERTED.*` captures the post-update state and inserts it into `History.PWMBAddAccountRequest` atomically

**Status values** (observed; exact names not in SSDT):

| Status | FundingID State | Observed In | Interpretation |
|--------|----------------|-------------|----------------|
| 1 | Unknown | History only | Initial/submitted state (transient) |
| 2 | Unknown | History only | Processing state (transient) |
| 3 | Unknown | History only | Intermediate verification (transient) |
| 4 | NULL | Live + History | Pending/In-progress; payment instrument not yet assigned |
| 5 | Unknown | History only | Transient state during provider verification |
| 6 | Set | Live + History | Success; FundingID assigned; account added |
| 7 | Set | Live + History | Completed with additional flag (verified/settled) |
| 8 | Unknown | Live + History | Terminal state (declined or expired) |

**Diagram**:
```
PWMB service calls provider to add payment account:
  1. Provider initiates: PWMB service inserts request via separate INSERT SP
     -> ExternalTransactionID assigned (provider reference), Status=1 or 2

  2. Provider processes (status transitions):
     EXEC UpdatePWMBAddAccountRequest
         @ExternalTransactionID='10247XXXXX', @Status=4 [pending]
     -> UPDATE: Status=4, LastModificationTime=now
     -> OUTPUT -> History.PWMBAddAccountRequest (snapshot archived)

  3. Provider confirms success + assigns FundingID:
     EXEC UpdatePWMBAddAccountRequest
         @ExternalTransactionID='10247XXXXX',
         @FundingID=1664434, @Status=6 [completed]
     -> UPDATE: FundingID=1664434, Status=6, LastModificationTime=now
     -> OUTPUT -> History.PWMBAddAccountRequest (snapshot archived)

  4. History table contains full audit trail: Status 1->4->6 with timestamps
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExternalTransactionID | VARCHAR(15) | NO | - | CODE-BACKED | The provider's external transaction reference for this account addition request. PK of `Billing.PWMBAddAccountRequest`. Used to identify which request to update. |
| 2 | @FundingID | INT | YES | NULL | CODE-BACKED | The Billing.Funding payment instrument ID assigned when the payment account is successfully added. Written to `Billing.PWMBAddAccountRequest.FundingID` (FK to Billing.Funding). NULL = leave FundingID unchanged (ISNULL pattern). Non-NULL = link the new payment instrument to this request. |
| 3 | @Status | INT | NO | - | CODE-BACKED | New status for the request. Values 1-8 observed (see status table above). Written to `Billing.PWMBAddAccountRequest.Status`. Note: @Status has no default value - must be provided by caller (though ISNULL(@Status, Status) means an explicit NULL would leave status unchanged). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| WHERE ExternalTransactionID | Billing.PWMBAddAccountRequest | UPDATE | Advances status and optionally sets FundingID for the account addition request |
| OUTPUT INSERTED.* INTO | History.PWMBAddAccountRequest | INSERT via OUTPUT | Atomically archives the updated request state for audit trail |
| @FundingID | Billing.Funding | FK (on target table) | FundingID FK_BillingPWMBAddAccountRequest_BillingFunding enforces valid payment instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| PWMB service | @ExternalTransactionID, @FundingID, @Status | EXEC | Called as provider confirms each stage of the payment account addition process |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.UpdatePWMBAddAccountRequest (procedure)
|- Billing.PWMBAddAccountRequest (table) - UPDATE target
|   |- Billing.Funding (FK on FundingID)
|   `- Customer.CustomerStatic (FK on CID)
`- History.PWMBAddAccountRequest (table) - INSERT via OUTPUT
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.PWMBAddAccountRequest | Table | UPDATE - sets FundingID (if provided) and Status WHERE ExternalTransactionID=@ExternalTransactionID |
| History.PWMBAddAccountRequest | Table | INSERT via OUTPUT...INTO - archives updated state snapshot atomically |
| Billing.Funding | Table | FK constraint on FundingID enforces valid payment instrument reference |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No SQL dependents found in SSDT. | - | Called externally by PWMB service during payment account addition workflow. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. `Billing.PWMBAddAccountRequest` has PK CLUSTERED on `ExternalTransactionID` (ASC, FILLFACTOR=95) - the WHERE clause uses this index for efficient single-row update.

### 7.2 Constraints

N/A for stored procedure. The `OUTPUT INSERTED.*` pattern captures the post-UPDATE state and atomically inserts it into `History.PWMBAddAccountRequest` in the same SQL statement - providing a complete, tamper-proof history of all status transitions with their exact timestamps.

---

## 8. Sample Queries

### 8.1 Advance status without setting FundingID (processing state)
```sql
EXEC Billing.UpdatePWMBAddAccountRequest
    @ExternalTransactionID = '10247XXXXX',
    @Status = 4; -- Pending
```

### 8.2 Mark request as complete and link payment instrument
```sql
EXEC Billing.UpdatePWMBAddAccountRequest
    @ExternalTransactionID = '10247XXXXX',
    @FundingID = 1664434,
    @Status = 6; -- Completed
```

### 8.3 Check current state of an account request
```sql
SELECT ExternalTransactionID, CID, FundingID, Status,
       InsertedTime, LastModificationTime
FROM Billing.PWMBAddAccountRequest WITH (NOLOCK)
WHERE ExternalTransactionID = '10247XXXXX';
```

### 8.4 View full audit trail for an account request
```sql
SELECT ExternalTransactionID, CID, FundingID, Status,
       InsertedTime, LastModificationTime
FROM History.PWMBAddAccountRequest WITH (NOLOCK)
WHERE ExternalTransactionID = '10247XXXXX'
ORDER BY LastModificationTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Internal code comment references ticket RD-7470 (June 2019, Adi Cohen) for the PWMB payment account addition feature.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.UpdatePWMBAddAccountRequest | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.UpdatePWMBAddAccountRequest.sql*
