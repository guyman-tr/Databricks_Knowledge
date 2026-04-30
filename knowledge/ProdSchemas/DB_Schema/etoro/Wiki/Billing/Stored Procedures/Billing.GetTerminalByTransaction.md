# Billing.GetTerminalByTransaction

> Resolves which payment terminal processed a given transaction for a specific customer: joins Billing.Payment to History.PaymentAction on TransactionID + CID and returns TerminalID.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @TransactionID + @CID; returns scalar TerminalID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Billing.GetTerminalByTransaction looks up the payment terminal that processed a specific transaction for a given customer. Given a short transaction code (@TransactionID, CHAR(6)) and a customer ID, it joins the payment record (Billing.Payment) to the payment action history (History.PaymentAction) and returns the TerminalID from the payment record.

Use cases include:
- **Payment dispute / chargeback resolution**: Identify which terminal processed a disputed payment
- **Transaction tracing**: Correlate an external transaction reference to an internal terminal for routing or audit
- **Customer support**: Quickly resolve which terminal/gateway handled a specific transaction for a customer

The CHAR(6) type for @TransactionID suggests this is a short external reference code (e.g., an authorization code or short-form transaction ID from a payment gateway), not the internal PaymentID.

---

## 2. Business Logic

### 2.1 Terminal Resolution via TransactionID

**What**: Joins Payment to PaymentAction on PaymentID to resolve TerminalID from a transaction reference.

**Columns/Parameters Involved**: `@TransactionID`, `@CID`, `History.PaymentAction.TransactionID`, `History.PaymentAction.PaymentID`, `Billing.Payment.PaymentID`, `Billing.Payment.TerminalID`, `Billing.Payment.CID`

**Rules**:
- `Billing.Payment BPAY JOIN History.PaymentAction HPMA ON BPAY.PaymentID = HPMA.PaymentID`
- Filter: `HPMA.TransactionID = @TransactionID AND BPAY.CID = @CID`
- Returns: `BPAY.TerminalID`
- CID filter on Billing.Payment ensures the terminal lookup is scoped to the correct customer (guards against cross-customer TransactionID collisions)
- Uses implicit JOIN syntax (comma-separated FROM clause)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionID | CHAR(6) | NO | - | CODE-BACKED | Short external transaction reference code from the payment gateway or action history. Matched against History.PaymentAction.TransactionID. CHAR(6) suggests a fixed-length authorization or short-form gateway code. |
| 2 | @CID | INTEGER | NO | - | CODE-BACKED | Customer ID. Applied to Billing.Payment.CID to scope the lookup to the correct customer. Prevents cross-customer collisions if TransactionID values are not globally unique. |
| - | TerminalID | INT | YES | - | CODE-BACKED | The payment terminal that processed this transaction. From Billing.Payment.TerminalID. NULL if no matching payment+action record exists for this TransactionID+CID combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentID, TerminalID, CID | Billing.Payment | SELECT | Source of TerminalID; filtered by CID |
| PaymentID, TransactionID | History.PaymentAction | JOIN | Matches the external TransactionID to an internal PaymentID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Payment dispute / routing service | @TransactionID, @CID | EXEC | Terminal lookup for transaction tracing and chargeback resolution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.GetTerminalByTransaction (procedure)
+-- Billing.Payment (table) [TerminalID + CID filter]
+-- History.PaymentAction (table) [TransactionID -> PaymentID join]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Payment | Table | Source of TerminalID; joined on PaymentID; filtered by CID |
| History.PaymentAction | Table | Maps external TransactionID to internal PaymentID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Payment dispute / support tools | External | Terminal resolution for specific transaction references |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| CHAR(6) TransactionID | Type constraint | Fixed-length 6-character transaction code; values shorter than 6 chars will be space-padded |
| CID scoping | Security | Prevents cross-customer data leakage if TransactionIDs are not globally unique |
| No NOLOCK | Concurrency | No WITH (NOLOCK) hint - reads committed data |
| No error if not found | Behavior | Returns empty result set if no match; caller must handle zero rows |

---

## 8. Sample Queries

### 8.1 Resolve terminal for a transaction

```sql
EXEC [Billing].[GetTerminalByTransaction]
    @TransactionID = 'ABC123',
    @CID = 12345
-- Returns: TerminalID (single row), or empty set if not found
```

### 8.2 Equivalent direct query

```sql
SELECT bpay.TerminalID
FROM [Billing].[Payment] bpay WITH (NOLOCK)
INNER JOIN [History].[PaymentAction] hpma WITH (NOLOCK) ON bpay.PaymentID = hpma.PaymentID
WHERE hpma.TransactionID = 'ABC123'
  AND bpay.CID = 12345
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: - | Quality: 8.8/10 (Elements: 8.5/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 7.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/4 (1,8,10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.GetTerminalByTransaction | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.GetTerminalByTransaction.sql*
