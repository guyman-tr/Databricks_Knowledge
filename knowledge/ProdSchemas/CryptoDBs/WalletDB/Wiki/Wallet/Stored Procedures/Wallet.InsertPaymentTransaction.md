# Wallet.InsertPaymentTransaction

> Records a blockchain transaction leg for a fiat payment, including exchange rate, fees, and destination address, with idempotency protection against duplicate transaction records.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.PaymentTransactions by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records the blockchain execution details for a fiat payment. After a payment is created (via InsertPayment), the actual blockchain transfer details - exchange rate, destination address, amounts, and fee breakdowns - are recorded here. The conversion service calls this once the payment execution begins. Idempotent: skips INSERT if a PaymentTransaction already exists for the same PaymentId.

---

## 2. Business Logic

### 2.1 Idempotent Transaction Recording

**What**: Prevents duplicate transaction records for the same payment.

**Rules**:
- Resolves PaymentId from Payments.CorrelationId
- WHERE NOT EXISTS (PaymentTransactions WHERE PaymentId = c.Id)
- Silent skip if duplicate (no error raised)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Identifies the parent payment. |
| 2 | @ExchangeRate | decimal(36,18) | NO | - | CODE-BACKED | Crypto-to-fiat exchange rate. |
| 3 | @ToAddress | nvarchar(512) | NO | - | CODE-BACKED | Destination blockchain address. |
| 4 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Crypto amount for this transaction. |
| 5 | @EtoroFeePercentage | decimal(5,2) | NO | - | CODE-BACKED | eToro fee percentage. |
| 6 | @EtoroFeeCalculated | decimal(36,18) | NO | - | CODE-BACKED | Calculated eToro fee amount. |
| 7 | @ProviderFeePercentage | decimal(5,2) | NO | - | CODE-BACKED | Provider fee percentage. |
| 8 | @ProviderFeeCalculated | decimal(36,18) | NO | - | CODE-BACKED | Calculated provider fee. |
| 9 | @EstimatedBlockChainFee | decimal(36,18) | NO | - | CODE-BACKED | Estimated network fee. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Payments | Lookup | Resolves PaymentId |
| - | Wallet.PaymentTransactions | INSERT | Transaction record |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Records payment execution details |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertPaymentTransaction (procedure)
+-- Wallet.Payments (table)
+-- Wallet.PaymentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | CorrelationId lookup |
| Wallet.PaymentTransactions | Table | INSERT target + idempotency check |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a payment transaction
```sql
EXEC Wallet.InsertPaymentTransaction @CorrelationId='YOUR-GUID', @ExchangeRate=65000.50, @ToAddress='0xabc...', @Amount=0.5, @EtoroFeePercentage=1.00, @EtoroFeeCalculated=0.005, @ProviderFeePercentage=0.50, @ProviderFeeCalculated=0.0025, @EstimatedBlockChainFee=0.0001;
```

### 8.2 Check payment transactions
```sql
SELECT pt.* FROM Wallet.PaymentTransactions pt WITH (NOLOCK) JOIN Wallet.Payments p WITH (NOLOCK) ON p.Id = pt.PaymentId WHERE p.CorrelationId = 'YOUR-GUID';
```

### 8.3 Full payment lifecycle
```sql
-- 1. InsertPayment (creates payment + initial status)
-- 2. InsertPaymentTransaction (records execution details - this SP)
-- 3. InsertPaymentStatus (tracks status changes)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertPaymentTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertPaymentTransaction.sql*
