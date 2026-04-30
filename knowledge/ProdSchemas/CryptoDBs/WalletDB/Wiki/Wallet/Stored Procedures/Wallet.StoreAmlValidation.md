# Wallet.StoreAmlValidation

> Records an AML/KYT validation result for a blockchain transaction, capturing the provider's decision, address screened, amount, and optional details with backward-compatible CryptoId resolution.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.AmlValidations |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records an AML (Anti-Money Laundering) validation result from a screening provider. The AML service calls this after each address/transaction screening, recording whether the provider approved or flagged the transaction. Each record captures the provider, direction (send/receive), address, amount, provider's status verdict, positive/negative decision, and optional blockchain hash and details JSON. Backward-compatible CryptoId resolution from base-chain wallet.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT with backward-compatible CryptoId auto-resolution from CustomerWalletsView when NULL.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AmlProviderId | int | NO | - | VERIFIED | AML screening provider. FK to Dictionary.AmlProviders. |
| 2 | @IsSend | bit | NO | - | VERIFIED | Transaction direction: 1=outbound send, 0=inbound receive. |
| 3 | @Address | varchar(512) | NO | - | CODE-BACKED | Blockchain address that was screened. |
| 4 | @WalletId | uniqueidentifier | NO | - | VERIFIED | Wallet involved in the transaction. |
| 5 | @CryptoId | int | YES | NULL | VERIFIED | Cryptocurrency. Auto-resolved from base-chain if NULL. |
| 6 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Transaction amount screened. |
| 7 | @ProviderStatus | varchar(50) | NO | - | CODE-BACKED | Provider's status verdict (e.g., 'PASS', 'FLAG', 'BLOCK'). |
| 8 | @IsPositiveDecision | bit | NO | - | VERIFIED | 1=approved, 0=flagged/blocked. |
| 9 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID. |
| 10 | @BlockchainTransactionId | nvarchar(100) | YES | NULL | CODE-BACKED | On-chain hash if available at screening time. |
| 11 | @DetailsJson | varchar(max) | YES | NULL | CODE-BACKED | Optional JSON with screening details. |
| 12 | @CategoryId | int | YES | NULL | CODE-BACKED | Risk category classification. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.AmlValidations | INSERT | AML validation record |
| @WalletId | Wallet.CustomerWalletsView | Lookup | CryptoId resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| AmlUser | - | EXECUTE | AML validation recording |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.StoreAmlValidation (procedure)
+-- Wallet.AmlValidations (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.AmlValidations | Table | INSERT target |
| Wallet.CustomerWalletsView | View | CryptoId resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| AmlUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record an AML validation
```sql
EXEC Wallet.StoreAmlValidation @AmlProviderId=1, @IsSend=1, @Address='1A1zP1eP5...', @WalletId='WALLET-GUID', @CryptoId=1, @Amount=0.5, @ProviderStatus='PASS', @IsPositiveDecision=1, @CorrelationId='GUID';
```

### 8.2 Check AML history for a wallet
```sql
SELECT * FROM Wallet.AmlValidations WITH (NOLOCK) WHERE WalletId = 'WALLET-GUID' ORDER BY Id DESC;
```

### 8.3 Find flagged transactions
```sql
SELECT * FROM Wallet.AmlValidations WITH (NOLOCK) WHERE IsPositiveDecision = 0 ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.StoreAmlValidation | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.StoreAmlValidation.sql*
