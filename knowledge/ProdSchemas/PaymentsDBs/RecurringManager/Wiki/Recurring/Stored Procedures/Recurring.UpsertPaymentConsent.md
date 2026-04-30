# Recurring.UpsertPaymentConsent

> Upserts a consent/authorization document for a recurring payment by PaymentId - creates the record if none exists, or updates the existing one if the payment already has a consent.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upserts into PaymentConsent (no return) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure manages consent document records for recurring payments. Each payment can have at most one consent record, so the procedure checks if one exists by PaymentId and either updates it (new document, new timestamp) or inserts a new one. Used when a customer provides or renews authorization for their recurring payment.

---

## 2. Business Logic

### 2.1 Upsert by PaymentId

**What**: Maintains one consent record per payment via existence check.

**Columns/Parameters Involved**: `@PaymentId`, `@DocumentId`, `@DocTypeId`, `@TimeStemp`

**Rules**:
- IF EXISTS (PaymentConsent WHERE PaymentId = @PaymentId): UPDATE DocumentId, DocTypeId, TimeStemp, ModificationDate
- ELSE: INSERT (PaymentId, DocumentId, DocTypeId, TimeStemp) with CreateDate/ModificationDate auto-defaulting
- No return value (SET NOCOUNT ON, no SELECT after)

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | FK to Recurring.Payment. Identifies which payment plan this consent belongs to. |
| 2 | @DocumentId | int (IN) | NO | - | CODE-BACKED | External reference to the consent document. |
| 3 | @DocTypeId | int (IN) | NO | - | CODE-BACKED | Type of consent document. |
| 4 | @TimeStemp | datetime2 (IN) | NO | - | CODE-BACKED | Timestamp of when consent was given. Note: parameter name matches the column's typo ("TimeStemp"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.PaymentConsent | WRITER + MODIFIER | Upsert by PaymentId |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.UpsertPaymentConsent (procedure)
└── Recurring.PaymentConsent (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.PaymentConsent | Table | SELECT for existence, INSERT or UPDATE |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Create or update consent for a payment
```sql
EXEC Recurring.UpsertPaymentConsent @PaymentId = 200820, @DocumentId = 12345,
    @DocTypeId = 1, @TimeStemp = '2026-04-16T10:00:00'
```

### 8.2 Renew consent with new document
```sql
EXEC Recurring.UpsertPaymentConsent @PaymentId = 200820, @DocumentId = 12346,
    @DocTypeId = 1, @TimeStemp = '2026-04-16T12:00:00'
```

### 8.3 Verify consent was saved
```sql
SELECT * FROM Recurring.PaymentConsent WITH (NOLOCK) WHERE PaymentId = 200820
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.UpsertPaymentConsent | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.UpsertPaymentConsent.sql*
