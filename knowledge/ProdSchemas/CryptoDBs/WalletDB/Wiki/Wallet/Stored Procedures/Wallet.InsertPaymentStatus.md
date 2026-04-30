# Wallet.InsertPaymentStatus

> Appends a status event to a payment's lifecycle by CorrelationId lookup, tracking payment progress from initiated through completed or failed.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.PaymentStatuses by CorrelationId |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a payment status change. The conversion service calls this as a fiat payment progresses through its lifecycle (e.g., Started -> Processing -> Completed or Failed). The payment is identified by CorrelationId, resolved to its internal PaymentId. Empty DetailsJson is converted to NULL.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Resolves PaymentId from Payments.CorrelationId, then INSERTs into PaymentStatuses.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business correlation ID to identify the payment. |
| 2 | @PaymentStatusId | tinyint | NO | - | VERIFIED | New status. FK to Dictionary.PaymentStatuses. |
| 3 | @DetailsJson | varchar(max) | YES | - | CODE-BACKED | Optional JSON details. Empty string treated as NULL. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CorrelationId | Wallet.Payments.CorrelationId | Lookup | Resolves PaymentId |
| - | Wallet.PaymentStatuses | INSERT | Appends status event |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| ConversionUser | - | EXECUTE | Payment lifecycle tracking |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertPaymentStatus (procedure)
+-- Wallet.Payments (table)
+-- Wallet.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | CorrelationId lookup |
| Wallet.PaymentStatuses | Table | INSERT target |

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

### 8.1 Update payment status
```sql
EXEC Wallet.InsertPaymentStatus @CorrelationId = 'YOUR-GUID', @PaymentStatusId = 3, @DetailsJson = NULL;
```

### 8.2 Check payment status history
```sql
SELECT ps.* FROM Wallet.PaymentStatuses ps WITH (NOLOCK) JOIN Wallet.Payments p WITH (NOLOCK) ON p.Id = ps.PaymentId WHERE p.CorrelationId = 'YOUR-GUID' ORDER BY ps.Id;
```

### 8.3 Direct equivalent
```sql
INSERT INTO Wallet.PaymentStatuses(PaymentId, PaymentStatusId, DetailsJson) SELECT Id, 3, NULL FROM Wallet.Payments WHERE CorrelationId = 'YOUR-GUID';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertPaymentStatus | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertPaymentStatus.sql*
