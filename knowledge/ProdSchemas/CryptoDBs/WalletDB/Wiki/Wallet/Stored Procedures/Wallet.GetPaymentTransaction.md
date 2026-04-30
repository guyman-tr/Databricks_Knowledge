# Wallet.GetPaymentTransaction

> Retrieves payment transaction details including exchange rate, fees, and destination address for a given payment correlation ID.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment transaction fee breakdown and amounts |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves the detailed transaction breakdown for a crypto payment, including the exchange rate applied, destination address, transaction amount, and the full fee structure (eToro fees and provider/blockchain fees). This is the detailed companion to `Wallet.GetPayment` which returns the high-level payment record with status history.

Services use this to display the full cost breakdown to customers, reconcile with providers, and verify fee calculations. The separation of fee components (eToro percentage vs calculated, provider percentage vs calculated, estimated blockchain fee) enables transparent fee reporting.

Data comes from `Wallet.Payments` joined to `Wallet.PaymentTransactions` which holds the per-transaction breakdown of each payment.

---

## 2. Business Logic

### 2.1 Fee Structure Breakdown

**What**: Payments have multiple fee components tracked separately.

**Columns/Parameters Involved**: `EtoroFeePercentage`, `EtoroFeeCalculated`, `ProviderFeePercentage`, `ProviderFeeCalculated`, `EstimatedBlockChainFee`

**Rules**:
- EtoroFeePercentage: The configured eToro fee rate (e.g., 0.01 = 1%)
- EtoroFeeCalculated: The actual eToro fee amount after applying the percentage to the transaction amount
- ProviderFeePercentage: The payment provider's fee rate
- ProviderFeeCalculated: The actual provider fee amount
- EstimatedBlockChainFee: Estimated on-chain network fee at time of transaction creation
- Total cost to customer = Amount + EtoroFeeCalculated + ProviderFeeCalculated + EstimatedBlockChainFee

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | Correlation ID linking to the payment in Wallet.Payments. Identifies which payment's transaction details to retrieve. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | Id | BIGINT | NO | - | CODE-BACKED | Payment record ID from Wallet.Payments. |
| 3 | ExchangeRate | DECIMAL | YES | - | CODE-BACKED | The fiat-to-crypto exchange rate applied at time of payment. Used to convert between fiat and crypto amounts. |
| 4 | ToAddress | NVARCHAR | YES | - | CODE-BACKED | Destination blockchain address for the payment transaction. |
| 5 | Amount | DECIMAL | NO | - | CODE-BACKED | Transaction amount in crypto units. The base amount before fees. |
| 6 | EtoroFeePercentage | DECIMAL | YES | - | CODE-BACKED | eToro's fee rate as a decimal (e.g., 0.01 = 1%). Configured per crypto/transaction type. |
| 7 | EtoroFeeCalculated | DECIMAL | YES | - | CODE-BACKED | Actual eToro fee amount in crypto units. Computed: Amount * EtoroFeePercentage. |
| 8 | ProviderFeePercentage | DECIMAL | YES | - | CODE-BACKED | Payment provider's fee rate as a decimal. |
| 9 | ProviderFeeCalculated | DECIMAL | YES | - | CODE-BACKED | Actual provider fee amount in crypto units. |
| 10 | EstimatedBlockChainFee | DECIMAL | YES | - | CODE-BACKED | Estimated on-chain network fee at transaction creation time. May differ from actual fee paid. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CorrelationId | Wallet.Payments | FROM | Payment record lookup |
| PaymentId | Wallet.PaymentTransactions | JOIN | Transaction details and fee breakdown |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by payment service for transaction detail display.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPaymentTransaction (procedure)
+-- Wallet.Payments (table)
+-- Wallet.PaymentTransactions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FROM - payment lookup by CorrelationId |
| Wallet.PaymentTransactions | Table | JOIN - transaction details and fees |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get payment transaction details
```sql
EXEC Wallet.GetPaymentTransaction @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 View recent payment transactions with total fees
```sql
SELECT TOP 10 p.Id, p.CorrelationId, ct.Amount,
       ct.EtoroFeeCalculated + ct.ProviderFeeCalculated + ISNULL(ct.EstimatedBlockChainFee, 0) AS TotalFees
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.PaymentTransactions ct WITH (NOLOCK) ON ct.PaymentId = p.Id
ORDER BY p.Id DESC;
```

### 8.3 Analyze fee percentages across payments
```sql
SELECT p.CryptoId, AVG(ct.EtoroFeePercentage) AS AvgEtoroFee, AVG(ct.ProviderFeePercentage) AS AvgProviderFee
FROM Wallet.Payments p WITH (NOLOCK)
JOIN Wallet.PaymentTransactions ct WITH (NOLOCK) ON ct.PaymentId = p.Id
GROUP BY p.CryptoId;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPaymentTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPaymentTransaction.sql*
