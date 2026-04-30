# Wallet.PaymentStatuses

> Event-sourced status history for fiat payment operations, tracking each step from provider initiation through document handling to final settlement or failure.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Table |
| **Key Identifier** | Id (bigint, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active NC + 1 clustered PK |

---

## 1. Business Meaning

This table tracks the lifecycle of each fiat payment from `Wallet.Payments`. Each row represents a status transition through the multi-step payment flow: PendingProvider -> InitiateStarted -> DocumentCompleted -> InitiateCompleted -> TransferCompleted -> Completed. See [Payment Status](../../_glossary.md#payment-status) for all 11 status values.

Rows are created by `Wallet.InsertPaymentStatus`.

---

## 2. Business Logic

No complex multi-column patterns. Status event log following the payment provider integration lifecycle.

---

## 3. Data Overview

N/A for status event table.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing event identifier. |
| 2 | PaymentId | bigint | NO | - | VERIFIED | Parent payment. FK to Wallet.Payments.Id. |
| 3 | PaymentStatusId | tinyint | NO | - | VERIFIED | Status: 1=PendingProvider through 11=ProviderSubmitted. See [Payment Status](../../_glossary.md#payment-status). FK to Dictionary.PaymentStatuses. |
| 4 | DetailsJson | varchar(max) | YES | - | CODE-BACKED | JSON with status-specific details (provider responses, error info). |
| 5 | Occurred | datetime2(7) | NO | getutcdate() | CODE-BACKED | Timestamp of this status transition. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentId | Wallet.Payments | FK | Parent payment |
| PaymentStatusId | Dictionary.PaymentStatuses | FK | Status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Wallet.InsertPaymentStatus | - | Writer | Appends status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.PaymentStatuses (table)
├── Wallet.Payments (table)
└── Dictionary.PaymentStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.Payments | Table | FK target for PaymentId |
| Dictionary.PaymentStatuses | Table | FK target for PaymentStatusId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Wallet.InsertPaymentStatus | Stored Procedure | Inserts status events |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentStatuses | CLUSTERED PK | Id ASC | - | - | Active |
| IX_...PaymentId_Occurred | NC | PaymentId, Occurred DESC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_...Occurred | DEFAULT | getutcdate() |
| FK_...PaymentId | FK | -> Wallet.Payments.Id |
| FK_...PaymentStatusId | FK | -> Dictionary.PaymentStatuses.Id |

---

## 8. Sample Queries

### 8.1 Status history for a payment
```sql
SELECT ps.PaymentStatusId, dps.Name AS Status, ps.Occurred, ps.DetailsJson
FROM Wallet.PaymentStatuses ps WITH (NOLOCK)
JOIN Dictionary.PaymentStatuses dps WITH (NOLOCK) ON ps.PaymentStatusId = dps.Id
WHERE ps.PaymentId = 123577
ORDER BY ps.Id
```

### 8.2 Failed payments
```sql
SELECT ps.PaymentId, ps.Occurred, ps.DetailsJson
FROM Wallet.PaymentStatuses ps WITH (NOLOCK)
WHERE ps.PaymentStatusId = 8 ORDER BY ps.Occurred DESC
```

### 8.3 Payment processing time
```sql
SELECT ps1.PaymentId, DATEDIFF(MINUTE, ps1.Occurred, ps2.Occurred) AS MinutesToComplete
FROM Wallet.PaymentStatuses ps1 WITH (NOLOCK)
JOIN Wallet.PaymentStatuses ps2 WITH (NOLOCK) ON ps1.PaymentId = ps2.PaymentId
WHERE ps1.PaymentStatusId = 1 AND ps2.PaymentStatusId = 9
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.PaymentStatuses | Type: Table | Source: WalletDB/Wallet/Tables/Wallet.PaymentStatuses.sql*
