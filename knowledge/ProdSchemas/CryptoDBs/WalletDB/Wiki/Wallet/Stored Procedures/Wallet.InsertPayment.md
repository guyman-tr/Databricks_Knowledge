# Wallet.InsertPayment

> Creates a new fiat payment record with idempotency protection via CorrelationId, auto-resolving the wallet from Gcid+CryptoId, and atomically inserting the initial payment status within a transaction.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.Payments + PaymentStatuses (transactional) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new fiat payment record - representing a crypto-to-fiat or fiat-to-crypto payment via providers like Simplex or MoonPay. The conversion service calls this when a customer initiates a fiat payment. Like InsertConversion, it's transactional and idempotent: duplicate CorrelationIds are rejected with RAISERROR. The initial payment status (PaymentStatusId=1, Started) is inserted atomically.

The procedure auto-resolves WalletId from Gcid+CryptoId when not provided (or when empty GUID), and supports backward-compatible CryptoId resolution from base-chain wallet.

---

## 2. Business Logic

### 2.1 Idempotent Transactional Creation

**What**: Creates payment + initial status atomically, rejecting duplicates.

**Columns/Parameters Involved**: `@CorrelationId`, `Payments`, `PaymentStatuses`

**Rules**:
- WHERE NOT EXISTS (Payments WHERE CorrelationId = @CorrelationId)
- If duplicate detected (SCOPE_IDENTITY IS NULL), RAISERROR
- Initial PaymentStatusId = 1 (Started)
- Transaction ensures both inserts succeed or both roll back

### 2.2 Wallet Auto-Resolution

**What**: Resolves WalletId from Gcid+CryptoId when not provided.

**Rules**:
- If @WalletId NULL or empty GUID -> resolve from CustomerWalletsView(Gcid, CryptoId)
- If @CryptoId NULL -> resolve from base-chain entry (backward compat)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Gcid | bigint | NO | - | VERIFIED | Customer initiating the payment. |
| 2 | @CryptoId | int | YES | - | VERIFIED | Cryptocurrency. Auto-resolved if NULL. |
| 3 | @WalletId | uniqueidentifier | YES | - | CODE-BACKED | Customer wallet. Auto-resolved if NULL/empty. |
| 4 | @ProviderPaymentId | uniqueidentifier | NO | - | VERIFIED | Payment provider's reference ID (e.g., Simplex transaction ID). |
| 5 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Crypto amount for the payment. |
| 6 | @FiatId | int | NO | - | VERIFIED | Fiat currency ID (e.g., USD, EUR). FK to Wallet.FiatTypes. |
| 7 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Idempotency key. Must be unique. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Payments | INSERT | Creates payment record |
| - | Wallet.PaymentStatuses | INSERT | Creates initial status |
| @Gcid + @CryptoId | Wallet.CustomerWalletsView | Lookup | Wallet resolution |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Creates fiat payment records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertPayment (procedure)
+-- Wallet.Payments (table)
+-- Wallet.PaymentStatuses (table)
+-- Wallet.CustomerWalletsView (view)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | INSERT target |
| Wallet.PaymentStatuses | Table | Initial status INSERT |
| Wallet.CustomerWalletsView | View | Wallet resolution |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| ConversionUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. Uses BEGIN/COMMIT TRANSACTION.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Create a payment
```sql
EXEC Wallet.InsertPayment @Gcid=30351701, @CryptoId=1, @WalletId=NULL,
    @ProviderPaymentId='SIMPLEX-GUID', @Amount=0.5, @FiatId=1, @CorrelationId='NEW-GUID';
```

### 8.2 Check payment status
```sql
SELECT p.*, ps.PaymentStatusId FROM Wallet.Payments p WITH (NOLOCK)
    JOIN Wallet.PaymentStatuses ps WITH (NOLOCK) ON ps.PaymentId = p.Id
WHERE p.CorrelationId = 'YOUR-GUID' ORDER BY ps.Id DESC;
```

### 8.3 Verify idempotency
```sql
-- Second call with same CorrelationId will raise error: "Payment with CorrelationId already exists"
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertPayment | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertPayment.sql*
