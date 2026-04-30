# Wallet.GetCustomerPaymentById

> Retrieves a fiat-to-crypto payment record by provider payment ID, returning customer details, payment status (including chargeback overrides), timing, and original fiat amount with a unified status code.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment details by ProviderPaymentId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves a fiat-to-crypto payment (buy) transaction by the external payment provider's ID. It provides a unified view including the customer, payment timing (initiation and last modification), original fiat amount and currency, and a computed TransactionStatus that accounts for chargebacks. This is used by the payment reconciliation service to check payment outcomes.

Without this procedure, the system could not look up payment status by provider reference, breaking the reconciliation loop with external payment providers.

The procedure uses two CTEs: one to resolve the payment with status timestamps, and another to check for chargebacks. The final SELECT merges these with a CASE expression that overrides the payment status when a chargeback exists.

---

## 2. Business Logic

### 2.1 Unified Transaction Status with Chargeback Override

**What**: Computes a single TransactionStatus integer that prioritizes chargeback status over payment status.

**Columns/Parameters Involved**: PaymentStatuses, Chargebacks, Dictionary.ChargebackStatuses, Dictionary.PaymentStatuses

**Rules**:
- If a chargeback exists: ChargeBack=6, Refund=7, RefundAsChargeback=8
- If no chargeback: Completed=2, Failed=3, PendingTransaction=5, anything else=4
- Chargeback status always overrides payment status
- InitiationTime = first occurrence of PaymentStatusId=2
- ModificationTime = first occurrence of PaymentStatusId=6

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderPaymentId | varchar(128) | NO | - | CODE-BACKED | External payment provider's transaction identifier. Used to match the payment in Wallet.Payments. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Payments | Reader | Core payment data |
| - | Wallet.PaymentStatuses | Reader | Payment status history |
| - | Wallet.CustomerWalletsView | Reader | Resolves customer from wallet |
| - | Wallet.FiatTypes | Reader | Resolves fiat currency name |
| - | Wallet.Chargebacks | Reader | Checks for chargebacks |
| - | Dictionary.ChargebackStatuses | Reader | Resolves chargeback status name |
| - | Dictionary.PaymentStatuses | Reader | Resolves payment status name |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetCustomerPaymentById (procedure)
  ├── Wallet.Payments (table)
  ├── Wallet.PaymentStatuses (table)
  ├── Wallet.CustomerWalletsView (view)
  ├── Wallet.FiatTypes (table)
  ├── Wallet.Chargebacks (table)
  ├── Dictionary.ChargebackStatuses (table)
  └── Dictionary.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | CTE source |
| Wallet.PaymentStatuses | Table | Status timestamps |
| Wallet.CustomerWalletsView | View | Customer resolution |
| Wallet.FiatTypes | Table | Currency name lookup |
| Wallet.Chargebacks | Table | Chargeback check |
| Dictionary.ChargebackStatuses | Table | Chargeback status name |
| Dictionary.PaymentStatuses | Table | Payment status name |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Two CTEs: Payment and Chargeback
- Complex CASE expression for unified status
- NOLOCK hints on all tables
- LEFT JOIN for chargeback (may not exist)

---

## 8. Sample Queries

### 8.1 Get payment by provider ID
```sql
EXEC Wallet.GetCustomerPaymentById @ProviderPaymentId = 'PAY-12345-ABCDE'
```

### 8.2 Find payments with chargebacks
```sql
SELECT p.Id, p.ProviderPaymentId, p.Amount, cb.ChargebackStatusId
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.Chargebacks cb WITH (NOLOCK) ON cb.PaymentId = p.Id
ORDER BY cb.Id DESC
```

### 8.3 Payment status distribution
```sql
SELECT ps.Name, COUNT(*) AS Cnt
FROM Wallet.Payments p WITH (NOLOCK)
CROSS APPLY (
    SELECT TOP 1 PaymentStatusId FROM Wallet.PaymentStatuses WITH (NOLOCK) WHERE PaymentId = p.Id ORDER BY Id DESC
) latest
JOIN Dictionary.PaymentStatuses ps WITH (NOLOCK) ON ps.Id = latest.PaymentStatusId
GROUP BY ps.Name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetCustomerPaymentById | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetCustomerPaymentById.sql*
