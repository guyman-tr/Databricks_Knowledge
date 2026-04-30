# Wallet.GetPayment

> Retrieves a crypto payment record by either its correlation ID or provider payment ID, including full status history as JSON.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns payment details with status history JSON |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure looks up a specific crypto payment by one of two identifiers: the internal correlation ID (used to track the payment across eToro services) or the provider payment ID (the external identifier from the payment processor). Payments represent fiat-to-crypto or crypto-to-fiat transactions processed through payment providers, distinct from on-chain crypto transfers.

The payment lookup is used by application services to check payment status, display payment details to users, and reconcile payments with external providers. The full status history is returned as JSON to allow the caller to see the complete lifecycle of the payment.

Data comes from `Wallet.Payments` joined to `Wallet.CustomerWalletsView` for customer context, with a subquery to `Wallet.PaymentStatuses` serialized as JSON for the complete status trail.

---

## 2. Business Logic

### 2.1 Dual-Identifier Lookup

**What**: Supports looking up a payment by either internal or external identifier.

**Columns/Parameters Involved**: `@CorrelationId`, `@ProviderPaymentId`

**Rules**:
- At least one identifier must be provided; if both are NULL, RAISERROR with severity 16 is raised
- ISNULL pattern: `p.CorrelationId = ISNULL(@CorrelationId, p.CorrelationId)` means when the parameter is NULL, the condition always matches (no filter on that column)
- When both are provided, both conditions must match (AND logic)
- This allows flexible lookup: by internal ID, by external ID, or by both

### 2.2 Status History as JSON

**What**: Embeds the complete payment status history into the result as a JSON string.

**Columns/Parameters Involved**: `StatusesAsString`, `PaymentStatuses`

**Rules**:
- Subquery: `SELECT PaymentStatusId, DetailsJson FROM PaymentStatuses WHERE PaymentId = p.Id ORDER BY Id FOR JSON AUTO`
- Produces a JSON array of status events in chronological order
- Each entry contains PaymentStatusId (the status type) and DetailsJson (additional details per status transition)
- The caller can deserialize this to show the full payment lifecycle

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Internal correlation ID for the payment. Used by eToro services to track the payment across the system. At least one of @CorrelationId or @ProviderPaymentId must be non-NULL. |
| 2 | @ProviderPaymentId | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | External payment ID from the payment provider. Used to reconcile with provider records. At least one of the two parameters must be non-NULL. |

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 3 | Id | BIGINT | NO | - | CODE-BACKED | Payment record ID from Wallet.Payments. Primary key. |
| 4 | Gcid | BIGINT | NO | - | CODE-BACKED | Global Customer ID from CustomerWalletsView. Identifies the customer who initiated the payment. |
| 5 | CryptoId | INT | NO | - | CODE-BACKED | Cryptocurrency involved in the payment. FK to Wallet.CryptoTypes. |
| 6 | WalletId | UNIQUEIDENTIFIER | NO | - | CODE-BACKED | The wallet associated with this payment. FK to Wallet.Wallets. |
| 7 | ProviderPaymentId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | External payment identifier from the payment provider. |
| 8 | Amount | DECIMAL | NO | - | CODE-BACKED | Payment amount in crypto units. |
| 9 | FiatId | INT | YES | - | CODE-BACKED | Fiat currency identifier for the payment. FK to Wallet.FiatTypes. |
| 10 | CorrelationId | UNIQUEIDENTIFIER | YES | - | CODE-BACKED | Internal correlation ID linking this payment to the broader request flow. |
| 11 | StatusesAsString | NVARCHAR(MAX) | YES | - | CODE-BACKED | JSON array of payment status events. Each element contains PaymentStatusId and DetailsJson. Ordered chronologically by Id. Example: `[{"PaymentStatusId":1,"DetailsJson":"..."},{"PaymentStatusId":2,"DetailsJson":"..."}]`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.Payments | FROM | Primary payment record |
| WalletId + CryptoId | Wallet.CustomerWalletsView | JOIN | Customer context (Gcid) for the payment |
| PaymentId | Wallet.PaymentStatuses | Subquery | Status history serialized as JSON |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by payment service APIs for status lookup and reconciliation.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetPayment (procedure)
+-- Wallet.Payments (table)
+-- Wallet.CustomerWalletsView (view)
+-- Wallet.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FROM - payment records |
| Wallet.CustomerWalletsView | View | JOIN - customer context |
| Wallet.PaymentStatuses | Table | Subquery - status history as JSON |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Parameter validation | RAISERROR | At least one of @CorrelationId or @ProviderPaymentId must be non-NULL, otherwise raises error with severity 16 |

---

## 8. Sample Queries

### 8.1 Look up payment by correlation ID
```sql
EXEC Wallet.GetPayment @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Look up payment by provider payment ID
```sql
EXEC Wallet.GetPayment @ProviderPaymentId = 'F1E2D3C4-B5A6-7890-ABCD-EF1234567890';
```

### 8.3 List recent payments with their latest status
```sql
SELECT TOP 10 p.Id, p.CorrelationId, p.Amount, p.CryptoId,
       (SELECT TOP 1 ps.PaymentStatusId FROM Wallet.PaymentStatuses ps WITH (NOLOCK)
        WHERE ps.PaymentId = p.Id ORDER BY ps.Id DESC) AS LatestStatusId
FROM Wallet.Payments p WITH (NOLOCK)
ORDER BY p.Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetPayment | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetPayment.sql*
