# Wallet.InsertConversionTransaction

> Records a blockchain transaction leg for a conversion, linking it to the parent conversion by CorrelationId with wallet auto-resolution, idempotency protection, and backward-compatible CryptoId resolution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.ConversionTransactions by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a blockchain transaction that is part of a conversion. Each conversion has two legs (from-crypto send and to-crypto receive), and each leg is recorded as a ConversionTransaction. The conversion service calls this for each leg, providing the crypto, wallet, amount, fees, and destination address.

The procedure auto-resolves the WalletId when NULL/empty GUID by looking up the customer's wallet for the specified crypto via the from-wallet's Gcid. It's idempotent: if a ConversionTransaction already exists for this ConversionId + WalletId + CryptoId combination, the INSERT is skipped.

---

## 2. Business Logic

### 2.1 Wallet Auto-Resolution via Conversion Context

**What**: Resolves wallet from the conversion's customer when not provided.

**Columns/Parameters Involved**: `@WalletId`, `@CorrelationId`, `@CryptoId`

**Rules**:
- If @WalletId NULL/empty -> finds FromWalletId from Conversions by CorrelationId -> gets Gcid -> resolves wallet for @CryptoId
- Backward compat: if @CryptoId NULL -> resolves from base-chain entry

### 2.2 Idempotency

**What**: Prevents duplicate transaction records for the same conversion leg.

**Rules**:
- WHERE NOT EXISTS (ConversionTransactions WHERE ConversionId + WalletId + CryptoId match)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Identifies the parent conversion. |
| 2 | @CryptoId | int | YES | - | VERIFIED | Crypto for this leg. Auto-resolved if NULL. |
| 3 | @WalletId | uniqueidentifier | YES | - | CODE-BACKED | Wallet for this leg. Auto-resolved if NULL. |
| 4 | @CryptoRateUsd | decimal(36,18) | NO | - | CODE-BACKED | USD exchange rate at time of transaction. |
| 5 | @ToAddress | nvarchar(512) | NO | - | CODE-BACKED | Destination blockchain address. |
| 6 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Crypto amount for this leg. |
| 7 | @EtoroFeePercentage | decimal(5,2) | NO | - | CODE-BACKED | eToro fee percentage applied. |
| 8 | @EtoroFeeCalculated | decimal(36,18) | NO | - | CODE-BACKED | Calculated eToro fee amount. |
| 9 | @EstimatedBlockChainFee | decimal(36,18) | NO | - | CODE-BACKED | Estimated network fee. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Conversions.CorrelationId | Lookup | Parent conversion |
| - | Wallet.ConversionTransactions | INSERT | Transaction leg record |
| @WalletId | Wallet.CustomerWalletsView | Lookup | Wallet auto-resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Records conversion transaction legs |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertConversionTransaction (procedure)
+-- Wallet.Conversions (table)
+-- Wallet.ConversionTransactions (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Conversions | Table | CorrelationId lookup |
| Wallet.ConversionTransactions | Table | INSERT target + idempotency check |
| Wallet.CustomerWalletsView | View | Wallet auto-resolution |

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

### 8.1 Record a conversion transaction leg
```sql
EXEC Wallet.InsertConversionTransaction @CorrelationId = 'YOUR-GUID', @CryptoId = 1,
    @WalletId = NULL, @CryptoRateUsd = 65000.50, @ToAddress = '0xabc...', @Amount = 0.5,
    @EtoroFeePercentage = 1.00, @EtoroFeeCalculated = 0.005, @EstimatedBlockChainFee = 0.0001;
```

### 8.2 Check conversion transaction legs
```sql
SELECT ct.* FROM Wallet.ConversionTransactions ct WITH (NOLOCK) JOIN Wallet.Conversions c WITH (NOLOCK) ON c.Id = ct.ConversionId WHERE c.CorrelationId = 'YOUR-GUID';
```

### 8.3 Both legs of a conversion
```sql
SELECT c.FromCryptoId, c.ToCryptoId, ct.CryptoId AS LegCrypto, ct.Amount, ct.WalletId
FROM Wallet.Conversions c WITH (NOLOCK) JOIN Wallet.ConversionTransactions ct WITH (NOLOCK) ON c.Id = ct.ConversionId WHERE c.CorrelationId = 'YOUR-GUID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertConversionTransaction | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertConversionTransaction.sql*
