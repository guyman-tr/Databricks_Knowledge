# Dictionary.PaymentActionType

> Lookup table defining the 7 types of payment actions — PreAuthorization, Purchase, Cashout, Refund, Settle, PostBack, and Cancel — classifying each step in payment transaction processing.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | PaymentActionTypeID (INT, PK NONCLUSTERED) |
| **Partition** | DICTIONARY filegroup |
| **Row Count** | 7 (MCP verified) |
| **Indexes** | 2 active (PK nonclustered + unique NC on Name) |

---

## 1. Business Meaning

Dictionary.PaymentActionType classifies the specific operation being performed within a payment transaction. While PaymentActionStatus tracks *where* an action is in its lifecycle (New → InProcess → Closed), PaymentActionType tracks *what kind* of action it is. These two dimensions together fully describe any payment action record in History.PaymentAction and History.DepositAction.

The 7 action types map to standard payment processing operations: pre-authorization (hold funds on card), purchase (capture funds), cashout (withdrawal to customer), refund (return funds to customer), settle (finalize with PSP), postback (PSP callback notification), and cancel (void the transaction). Each deposit/payment procedure in the Billing schema inserts the appropriate action type when recording payment history.

Note: The Name for ID 1 is stored as "PreAuhtorization" (typo preserved from production data — the 'h' and 't' are transposed).

---

## 2. Business Logic

### 2.1 Payment Action Type Classification

**What**: The seven categories of payment operations and when each is used.

**Columns/Parameters Involved**: `PaymentActionTypeID`, `Name`

**Rules**:
- **PreAuthorization (1)**: Initial hold placed on customer's card to verify funds availability. No actual charge. Used in two-step payment flows where authorization precedes capture.
- **Purchase (2)**: Direct fund capture — money is charged to the customer's payment method. Used by Billing.DepositAdd and Billing.DepositProcess (literal 2). The most common action type for deposits.
- **Cashout (3)**: Withdrawal of funds from eToro back to the customer's payment method. Initiated through the cashout flow.
- **Refund (4)**: Return of previously captured funds to the customer. Different from cashout — refunds reverse a specific prior transaction.
- **Settle (5)**: Settlement/reconciliation action with the PSP. Finalizes the financial transaction between eToro and the payment provider.
- **PostBack (6)**: Asynchronous callback notification from the PSP confirming transaction status. Used by Billing.PaymentByPayPalProcess when processing PayPal callbacks.
- **Cancel (7)**: Void/cancellation of a pending transaction. Billing.DepositsCancelByLastDays uses literal 7 for bulk cancellations.

**Diagram**:
```
Deposit Flow Actions:
  PreAuthorization (1) ──► Purchase (2) ──► Settle (5)
                                │
                                ├──► Refund (4)     (reverse)
                                └──► Cancel (7)     (void)

PSP Callback:
  PostBack (6) ──► updates action status

Withdrawal:
  Cashout (3) ──► Settle (5)
```

### 2.2 Action Type in Deposit Procedures

**What**: Which action types are hard-coded in deposit processing procedures.

**Columns/Parameters Involved**: `PaymentActionTypeID`

**Rules**:
- **Billing.DepositAdd**: Inserts literal 2 (Purchase) for new deposits
- **Billing.DepositProcess**: Inserts literal 2 (Purchase) during processing
- **Billing.PaymentByPayPalProcess**: Inserts literal 6 (PostBack) for PayPal callbacks
- **Billing.DepositsCancelByLastDays**: Inserts literal 7 (Cancel) for bulk cancellation
- **Billing.DepositUpdate / DepositActionAdd**: Accept @PaymentActionTypeID as parameter (flexible)
- **Billing.GetResponse**: Reads PaymentActionTypeID from Dictionary.Response to match responses to action types

---

## 3. Data Overview

| PaymentActionTypeID | Name | Meaning |
|---|---|---|
| 1 | PreAuhtorization | Card pre-authorization — temporary hold to verify fund availability without charging. Two-step flow: authorize first, capture later. Note: Name has a known typo ("Auht" instead of "Auth") preserved in production. |
| 2 | Purchase | Direct fund capture/charge to customer's payment method. The primary action type for deposits. Hard-coded in DepositAdd and DepositProcess. |
| 3 | Cashout | Withdrawal of funds from eToro to the customer. Reverse direction from Purchase — money flows out to the customer's method. |
| 4 | Refund | Return of previously captured funds. Unlike Cashout, a Refund is tied to a specific prior Purchase transaction and may be partial or full. |
| 5 | Settle | Financial settlement/reconciliation with the PSP. Finalizes the transaction and triggers actual fund transfer between eToro and the payment provider. |
| 6 | PostBack | Asynchronous notification from PSP confirming transaction outcome. PayPal and other async providers use this callback mechanism. Hard-coded in PaymentByPayPalProcess. |
| 7 | Cancel | Transaction void/cancellation. Releases any pre-authorized hold or cancels a pending transaction. Used in bulk cleanup (DepositsCancelByLastDays). |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentActionTypeID | int | NO | - | VERIFIED | Primary key identifying the payment operation type. 1=PreAuth, 2=Purchase, 3=Cashout, 4=Refund, 5=Settle, 6=PostBack, 7=Cancel. Referenced by History.PaymentAction (explicit FK), History.DepositAction, and Dictionary.Response (explicit FK). Hard-coded values appear in Billing.DepositAdd (2), Billing.DepositProcess (2), Billing.PaymentByPayPalProcess (6), Billing.DepositsCancelByLastDays (7). |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable action type name. Unique constraint prevents duplicates. Note: ID 1 contains typo "PreAuhtorization" in production data. Used in payment audit trails, debugging, and reporting. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PaymentAction | PaymentActionTypeID | Explicit FK (FK_DPAT_HPMA) | Every payment action record classifies its operation type |
| Dictionary.Response | PaymentActionTypeID | Explicit FK (FK_DPAT_DRES) | Payment responses are scoped to specific action types |
| History.DepositAction | PaymentActionTypeID | Implicit | Deposit action history stores action type |
| Billing.PaymentActionAdd | @PaymentActionTypeID | Parameter | Creates payment actions with specified type |
| Billing.DepositAdd | PaymentActionTypeID | INSERT literal 2 | New deposits are Purchase actions |
| Billing.DepositUpdate | @PaymentActionTypeID | Parameter | Deposit update writes action type |
| Billing.DepositActionAdd | @PaymentActionTypeID | Parameter | Adds deposit action with specified type |
| Billing.DepositProcess | PaymentActionTypeID | INSERT literal 2 | Deposit processing is a Purchase action |
| Billing.DepositMatch | PaymentActionTypeID | INSERT from source | Matches deposits using existing action type |
| Billing.DepositCancel | PaymentActionTypeID | INSERT | Cancellation records action type |
| Billing.DepositRollback | PaymentActionTypeID | INSERT | Rollback records action type |
| Billing.DepositPendingCancel | PaymentActionTypeID | INSERT | Pending cancel records action type |
| Billing.DepositsCancelByLastDays | PaymentActionTypeID | INSERT literal 7 | Bulk cancel is a Cancel action |
| Billing.PaymentByPayPalProcess | PaymentActionTypeID | INSERT literal 6 | PayPal callback is a PostBack action |
| Billing.GetResponse | PaymentActionTypeID | SELECT | Reads action type from Response table |
| BackOffice.DepositCancel | PaymentActionTypeID | INSERT | Back-office cancel records action type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.PaymentActionType (table)
  └── referenced by History.PaymentAction (FK_DPAT_HPMA)
  └── referenced by Dictionary.Response (FK_DPAT_DRES)
  └── referenced by History.DepositAction (implicit)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PaymentAction | Table | FK constraint on PaymentActionTypeID |
| Dictionary.Response | Table | FK constraint on PaymentActionTypeID |
| History.DepositAction | Table | Stores PaymentActionTypeID per action |
| Billing.PaymentActionAdd | Stored Procedure | Creates actions with specified type |
| Billing.DepositAdd | Stored Procedure | New deposit → type 2 (Purchase) |
| Billing.DepositProcess | Stored Procedure | Processing → type 2 (Purchase) |
| Billing.PaymentByPayPalProcess | Stored Procedure | PayPal → type 6 (PostBack) |
| Billing.DepositsCancelByLastDays | Stored Procedure | Bulk cancel → type 7 (Cancel) |
| Billing.GetResponse | Stored Procedure | Response lookup by action type |
| BackOffice.DepositCancel | Stored Procedure | Back-office cancel |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_DPAC | NONCLUSTERED PK | PaymentActionTypeID ASC | - | - | Active |
| DPAC_NAME | NONCLUSTERED UNIQUE | Name ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_DPAC | PRIMARY KEY | Unique action type identifier, FILLFACTOR 90, DICTIONARY filegroup |
| DPAC_NAME | UNIQUE INDEX | Ensures no duplicate action type names, FILLFACTOR 90 |

---

## 8. Sample Queries

### 8.1 List all payment action types
```sql
SELECT  PaymentActionTypeID,
        Name
FROM    Dictionary.PaymentActionType WITH (NOLOCK)
ORDER BY PaymentActionTypeID;
```

### 8.2 Count payment actions by type
```sql
SELECT  dpat.Name           AS ActionType,
        COUNT(*)            AS ActionCount
FROM    History.PaymentAction hpa WITH (NOLOCK)
JOIN    Dictionary.PaymentActionType dpat WITH (NOLOCK)
        ON hpa.PaymentActionTypeID = dpat.PaymentActionTypeID
GROUP BY dpat.Name
ORDER BY ActionCount DESC;
```

### 8.3 Find all responses for a specific action type
```sql
SELECT  r.*
FROM    Dictionary.Response r WITH (NOLOCK)
WHERE   r.PaymentActionTypeID = 2  -- Purchase
ORDER BY r.ResponseID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. Business meaning derived from MCP live data and codebase analysis of Billing schema deposit/payment procedures.

---

*Generated: 2026-03-13 | Quality: 9.4/10 (Elements: 10/10, Logic: 10/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 14 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.PaymentActionType | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.PaymentActionType.sql*
