# Wallet.Chargebacks

> Records chargeback and refund events against fiat payments, tracking the reversal amount, type, verification details, and the original payment being disputed.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active NC (1 unique) + 1 clustered PK |

---

## 1. Business Meaning

This table records chargeback and refund events against fiat payments from `Wallet.Payments`. When a customer disputes a fiat-to-crypto payment with their bank, or when eToro initiates a refund, a record is created here linking the chargeback to the original payment. This is critical for financial reconciliation and dispute management.

Each chargeback has a type (ChargeBack, Refund, or RefundAsChargeback) and a correlation ID for end-to-end tracking. The `CashoutRefundAmount` may differ from the original `Amount` for partial chargebacks.

Rows are created by `Wallet.InsertChargeback`.

---

## 2. Business Logic

### 2.1 Chargeback Classification

**What**: Chargebacks are classified by their origin and type.

**Columns/Parameters Involved**: `ChargebackStatusId`, `Amount`, `CashoutRefundAmount`

**Rules**:
- ChargebackStatusId=1 (ChargeBack): Initiated by customer's bank - full dispute
- ChargebackStatusId=2 (Refund): Voluntary refund initiated by eToro
- ChargebackStatusId=3 (RefundAsChargeback): Refund processed through chargeback mechanism
- See [Chargeback Status](../../_glossary.md#chargeback-status). Implicit reference to Dictionary.ChargebackStatuses.

---

## 3. Data Overview

N/A - Financial dispute records. Contains payment ID, amounts, and chargeback classification.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing primary key. |
| 2 | PaymentId | bigint | YES | - | VERIFIED | The payment being disputed/refunded. FK to Wallet.Payments.Id. NULL for chargebacks not linked to a specific payment record. |
| 3 | ChargebackStatusId | tinyint | YES | - | CODE-BACKED | Type of chargeback: 1=ChargeBack, 2=Refund, 3=RefundAsChargeback. See [Chargeback Status](../../_glossary.md#chargeback-status). |
| 4 | Amount | decimal(36,18) | NO | - | CODE-BACKED | Chargeback amount in the payment's original fiat currency. |
| 5 | RollbackDate | datetime2(7) | YES | - | CODE-BACKED | Date when the chargeback/refund was processed by the payment provider. |
| 6 | VerificationCode | varchar(20) | YES | - | CODE-BACKED | Provider's verification/authorization code for the chargeback. |
| 7 | CashoutRefundAmount | decimal(36,18) | YES | - | CODE-BACKED | Actual refund amount if different from the chargeback amount (e.g., partial refunds). |
| 8 | Description | varchar(256) | YES | - | CODE-BACKED | Free-text description of the chargeback reason or dispute details. |
| 9 | CorrelationId | uniqueidentifier | NO | - | CODE-BACKED | Unique chargeback correlation ID. Unique constraint. Used for idempotency and cross-service tracking. |
| 10 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp when the chargeback was recorded in the system. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentId | Wallet.Payments | FK | The payment being disputed |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertChargeback | - | Writer | Creates chargeback records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.Chargebacks (table)
└── Wallet.Payments (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FK target for PaymentId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertChargeback | Stored Procedure | Creates records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_Chargebacks | CLUSTERED PK | Id ASC | - | - | Active |
| IX_Wallet_Chargebacks__CorrelationId | NC UNIQUE | CorrelationId ASC | - | - | Active |
| IX_Wallet_Chargebacks__PaymentId | NC | PaymentId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_Wallet_Chargebacks__Occurred | DEFAULT | getutcdate() |
| FK_...PaymentId | FK | -> Wallet.Payments.Id |

---

## 8. Sample Queries

### 8.1 Get chargebacks for a payment
```sql
SELECT cb.Id, cb.ChargebackStatusId, cb.Amount, cb.CashoutRefundAmount, cb.Description, cb.RollbackDate
FROM Wallet.Chargebacks cb WITH (NOLOCK)
WHERE cb.PaymentId = 123577
```

### 8.2 Recent chargebacks
```sql
SELECT TOP 20 cb.Id, cb.PaymentId, cb.Amount, cb.ChargebackStatusId, cb.Description, cb.Occurred
FROM Wallet.Chargebacks cb WITH (NOLOCK)
ORDER BY cb.Occurred DESC
```

### 8.3 Chargeback summary by type
```sql
SELECT cb.ChargebackStatusId, COUNT(*) AS Count, SUM(cb.Amount) AS TotalAmount
FROM Wallet.Chargebacks cb WITH (NOLOCK)
GROUP BY cb.ChargebackStatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 9 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.Chargebacks | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.Chargebacks.sql*
