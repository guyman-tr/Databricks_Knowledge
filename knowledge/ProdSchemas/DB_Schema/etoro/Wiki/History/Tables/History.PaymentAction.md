# History.PaymentAction

> Legacy archive of individual payment processor transactions (charges, refunds, cashouts, cancellations) executed against payments from 2007-2011 in the early eToro billing platform.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | PaymentActionID (INT IDENTITY, NONCLUSTERED PK) |
| **Partition** | No (on HISTORY filegroup) |
| **Indexes** | 5 (NONCLUSTERED PK on PaymentActionID, NC on PaymentID, NC on PaymentActionStatusID, NC on PaymentActionTypeID, NC on ResponseID) |

---

## 1. Business Meaning

History.PaymentAction records individual payment processor operations (actions) performed against a payment. Each row represents one action taken by the payment gateway - a charge/purchase, cashout, refund, pre-authorization, settlement, cancellation, or postback notification. A single payment (PaymentID) may have multiple actions over its lifetime.

This table is a legacy archive from the early eToro billing platform (2007-2011). It holds 459,664 rows from that period. Active payment action recording has moved to newer billing infrastructure, but this table is retained for historical audit and reference.

Data was written by Billing.PaymentActionAdd when a payment processor returned a result, and updated by Billing.PaymentActionUpdate when an action's status changed. The Amount is stored in cents (e.g., 100000 = $1,000.00). TransactionID is a 6-character hex string from the payment gateway, and AuthCode is the authorization/confirmation code.

---

## 2. Business Logic

### 2.1 Payment Action Lifecycle

**What**: Payment actions progress through a simple 3-state lifecycle from New to Closed.

**Columns/Parameters Involved**: `PaymentActionStatusID`, `PaymentActionTypeID`, `ResponseID`

**Rules**:
- PaymentActionStatusID: 1=New (action initiated), 2=InProcess (submitted to gateway, awaiting response), 3=Closed (gateway responded, action complete).
- PaymentActionTypeID: 1=PreAuthorization (hold on card without charging), 2=Purchase (actual charge), 3=Cashout (withdrawal from account), 4=Refund (return of funds to customer), 5=Settle (clearing/settlement), 6=PostBack (async callback from gateway), 7=Cancel (cancellation of a previous action).
- ResponseID links to Dictionary.Response for the gateway's response code - indicates success, decline, error type.

### 2.2 Amount Representation

**What**: Amounts are stored in cents (integer), not decimal dollars.

**Columns/Parameters Involved**: `Amount`

**Rules**:
- Amount is in cents: 100000 = $1,000.00; 40000 = $400.00; 26000 = $260.00.
- This integer-cents representation avoids floating-point precision issues for billing calculations.

---

## 3. Data Overview

| PaymentActionID | PaymentID | PaymentActionTypeID | PaymentActionStatusID | Amount | TransactionID | Meaning |
|----------------|-----------|--------------------|-----------------------|--------|---------------|---------|
| 459959 | 389343 | 2 (Purchase) | 3 (Closed) | 100000 ($1,000) | 0A6E13 | A $1,000 credit card purchase transaction, closed by gateway in Jan 2011 |
| 459958 | 389342 | 2 (Purchase) | 3 (Closed) | 40000 ($400) | F790D7 | A $400 purchase, closed with authorization code 91CF0D |
| 459957 | 389341 | 6 (PostBack) | 3 (Closed) | 26000 ($260) | A6BFD5 | A PayPal postback notification for a $260 deposit; long AuthCode format matches PayPal transaction IDs |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PaymentActionID | int IDENTITY(1,1) | NO | - | CODE-BACKED | Surrogate primary key. Auto-incremented; no business meaning beyond row identity. |
| 2 | PaymentID | int | NO | - | CODE-BACKED | The payment this action belongs to. FK to Billing.Payment.PaymentID. A single payment can have multiple actions (e.g., pre-auth followed by purchase). Indexed for fast retrieval of all actions per payment. |
| 3 | PaymentActionStatusID | int | NO | - | CODE-BACKED | Current state of this action: 1=New (just recorded), 2=InProcess (submitted to gateway), 3=Closed (gateway responded, action complete). FK to Dictionary.PaymentActionStatus. |
| 4 | PaymentActionTypeID | int | NO | - | CODE-BACKED | Type of payment operation: 1=PreAuthorization (hold), 2=Purchase (charge), 3=Cashout (withdrawal), 4=Refund, 5=Settle (clearing), 6=PostBack (async gateway notification), 7=Cancel. FK to Dictionary.PaymentActionType. |
| 5 | ResponseID | int | YES | - | CODE-BACKED | Gateway response code for this action. FK to Dictionary.Response. Links to a lookup table of all possible gateway response codes (approved, declined, error codes). NULL when no gateway response has been received yet. |
| 6 | TransactionID | char(6) | NO | - | CODE-BACKED | 6-character hexadecimal transaction identifier assigned by the payment gateway. Unique per transaction within the gateway system. Used for reconciliation and dispute resolution with the payment processor. |
| 7 | Amount | int | NO | - | CODE-BACKED | Transaction amount in cents. Divide by 100 to get the dollar value (e.g., 100000 = $1,000.00). Integer storage avoids floating-point precision issues for financial calculations. |
| 8 | PaymentDate | datetime | NO | - | CODE-BACKED | UTC datetime when the payment action was recorded. |
| 9 | ApprovalNumber | varchar(20) | YES | - | CODE-BACKED | Approval number from the payment processor, if provided (for approved transactions). NULL for declined or in-process actions. |
| 10 | AuthCode | varchar(20) | YES | - | CODE-BACKED | Authorization code returned by the payment gateway confirming the action. Format varies by gateway: 6-char hex for credit card processors, longer strings for PayPal (e.g., "EC-4UU386852R3285728"). NULL when no authorization was issued. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentID | Billing.Payment | FK (FK_BPAY_HPMA) | The parent payment this action belongs to. |
| PaymentActionStatusID | Dictionary.PaymentActionStatus | FK (FK_DPAS_HPMA) | Action lifecycle state: New, InProcess, Closed. |
| PaymentActionTypeID | Dictionary.PaymentActionType | FK (FK_DPAT_HPMA) | Type of action: Purchase, Cashout, Refund, etc. |
| ResponseID | Dictionary.Response | FK (FK_DRSP_HPMA) | Gateway response code for this action. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.PaymentActionAdd | - | Writer | Inserts new action rows when gateway responds. |
| Billing.PaymentActionUpdate | - | Modifier | Updates action status as it progresses. |
| Billing.GetPaymentByTransaction | TransactionID | Reader | Looks up a payment by its transaction ID. |
| Billing.GetTerminalByTransaction | TransactionID | Reader | Looks up the terminal for a given transaction. |
| Billing.CustomerRemove | - | Reader | References payment actions during customer data removal. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PaymentAction (table)
|- Billing.Payment (table) [FK via PaymentID]
|- Dictionary.PaymentActionStatus (table) [FK via PaymentActionStatusID]
|- Dictionary.PaymentActionType (table) [FK via PaymentActionTypeID]
|- Dictionary.Response (table) [FK via ResponseID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | FK constraint - every PaymentID must exist in Billing.Payment |
| Dictionary.PaymentActionStatus | Table | FK constraint - PaymentActionStatusID must be valid |
| Dictionary.PaymentActionType | Table | FK constraint - PaymentActionTypeID must be valid |
| Dictionary.Response | Table | FK constraint - ResponseID must be valid when set |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.PaymentActionAdd | Stored Procedure | WRITER - inserts new action rows |
| Billing.PaymentActionUpdate | Stored Procedure | MODIFIER - updates action status |
| Billing.GetPaymentByTransaction | Stored Procedure | READER - payment lookup by TransactionID |
| Billing.GetTerminalByTransaction | Stored Procedure | READER - terminal lookup by TransactionID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HPMA | NONCLUSTERED PK | PaymentActionID ASC | - | - | Active |
| HPMA_PAYMENT | NONCLUSTERED | PaymentID ASC | - | - | Active |
| HPMA_PAYMENTACTIONSTATUS | NONCLUSTERED | PaymentActionStatusID ASC | - | - | Active |
| HPMA_PAYMENTACTIONTYPE | NONCLUSTERED | PaymentActionTypeID ASC | - | - | Active |
| HPMA_RESPONSE | NONCLUSTERED | ResponseID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HPMA | PRIMARY KEY | Unique per payment action |
| FK_BPAY_HPMA | FOREIGN KEY | PaymentID -> Billing.Payment |
| FK_DPAS_HPMA | FOREIGN KEY | PaymentActionStatusID -> Dictionary.PaymentActionStatus |
| FK_DPAT_HPMA | FOREIGN KEY | PaymentActionTypeID -> Dictionary.PaymentActionType |
| FK_DRSP_HPMA | FOREIGN KEY | ResponseID -> Dictionary.Response |

---

## 8. Sample Queries

### 8.1 Get all payment actions for a specific payment with readable labels

```sql
SELECT pa.PaymentActionID, pat.Name AS ActionType, pas.Name AS Status,
       pa.Amount / 100.0 AS AmountUSD, pa.TransactionID, pa.AuthCode, pa.PaymentDate
FROM History.PaymentAction pa WITH (NOLOCK)
JOIN Dictionary.PaymentActionType pat WITH (NOLOCK) ON pat.PaymentActionTypeID = pa.PaymentActionTypeID
JOIN Dictionary.PaymentActionStatus pas WITH (NOLOCK) ON pas.PaymentActionStatusID = pa.PaymentActionStatusID
WHERE pa.PaymentID = 389343
ORDER BY pa.PaymentDate;
```

### 8.2 Find a payment action by its gateway transaction ID

```sql
SELECT pa.PaymentActionID, pa.PaymentID, pa.TransactionID, pa.Amount / 100.0 AS AmountUSD,
       pa.AuthCode, pa.PaymentDate
FROM History.PaymentAction pa WITH (NOLOCK)
WHERE pa.TransactionID = '0A6E13';
```

### 8.3 Count closed purchase actions by response code

```sql
SELECT dr.ResponseCode, dr.ResponseDescription, COUNT(*) AS ActionCount
FROM History.PaymentAction pa WITH (NOLOCK)
JOIN Dictionary.Response dr WITH (NOLOCK) ON dr.ResponseID = pa.ResponseID
WHERE pa.PaymentActionTypeID = 2  -- Purchase
  AND pa.PaymentActionStatusID = 3  -- Closed
GROUP BY dr.ResponseCode, dr.ResponseDescription
ORDER BY ActionCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PaymentAction | Type: Table | Source: etoro/etoro/History/Tables/History.PaymentAction.sql*
