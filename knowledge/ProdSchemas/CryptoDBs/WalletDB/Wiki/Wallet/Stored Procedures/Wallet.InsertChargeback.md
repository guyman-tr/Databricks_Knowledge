# Wallet.InsertChargeback

> Records a chargeback event for a fiat payment transaction, capturing the reversal amount, date, verification code, and refund details in the Chargebacks table.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | INSERT into Wallet.Chargebacks |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure records a chargeback event when a fiat payment is reversed. Chargebacks occur when a payment provider (e.g., Simplex, MoonPay) reports a reversal - typically due to fraud, customer dispute, or compliance action. The back-office API calls this to persist the chargeback details including the payment reference, reversal amount, date, verification code, cashout refund amount, and description.

Each chargeback is linked to its parent payment via PaymentId and correlated to the business operation via CorrelationId. The ChargebackStatusId tracks the chargeback's processing state.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Direct INSERT into Chargebacks with all parameters mapped to columns.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | bigint | NO | - | VERIFIED | Parent payment being charged back. FK to Wallet.Payments.Id. |
| 2 | @Status | varchar(10) | NO | - | CODE-BACKED | Chargeback status identifier. Inserted as ChargebackStatusId. |
| 3 | @Amount | decimal(36,18) | NO | - | CODE-BACKED | Chargeback amount in crypto. |
| 4 | @RollbackDate | datetime2(7) | NO | - | CODE-BACKED | Date of the chargeback/reversal. |
| 5 | @VerificationCode | varchar(20) | NO | - | CODE-BACKED | Provider's chargeback verification reference. |
| 6 | @CashoutRefundAmount | decimal(36,18) | NO | - | CODE-BACKED | Fiat amount refunded to the payment provider. |
| 7 | @Description | varchar(256) | NO | - | CODE-BACKED | Reason/description for the chargeback. |
| 8 | @CorrelationId | uniqueidentifier | NO | - | VERIFIED | Business operation correlation ID for tracing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @PaymentId | Wallet.Chargebacks.PaymentId | INSERT | Links to parent payment |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackApiUser | - | EXECUTE | Records chargeback events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.InsertChargeback (procedure)
+-- Wallet.Chargebacks (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Chargebacks | Table | INSERT target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackApiUser | Service Account | EXECUTE grant |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Record a chargeback
```sql
EXEC Wallet.InsertChargeback
    @PaymentId = 12345,
    @Status = 'Active',
    @Amount = 0.5,
    @RollbackDate = '2026-04-15',
    @VerificationCode = 'CB-12345',
    @CashoutRefundAmount = 250.00,
    @Description = 'Fraud dispute - customer denies transaction',
    @CorrelationId = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
```

### 8.2 Check chargebacks for a payment
```sql
SELECT * FROM Wallet.Chargebacks WITH (NOLOCK) WHERE PaymentId = 12345;
```

### 8.3 Recent chargebacks
```sql
SELECT TOP 10 * FROM Wallet.Chargebacks WITH (NOLOCK) ORDER BY Id DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.InsertChargeback | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.InsertChargeback.sql*
