# Recurring.GetPayment

> Simple reader that retrieves a single recurring payment record by PaymentId.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single Payment row |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Basic point-lookup procedure that returns all business columns of a single recurring payment by its primary key. Used by application services to load payment details for processing, display, or validation. Uses NOLOCK for read consistency in high-throughput scenarios.

---

## 2. Business Logic

No complex business logic. Simple `SELECT TOP 1 ... WHERE PaymentId = @PaymentId`.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentId | int (IN) | NO | - | CODE-BACKED | PK of the payment to retrieve. |

**Return Columns**: PaymentId, Cid, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, StatusReasonId, RecurringProgramTypeId, AuthenticationId, Generation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | READER | SELECT TOP 1 by PK |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPayment (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT TOP 1 WHERE PaymentId = @PaymentId |

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

### 8.1 Get a payment
```sql
EXEC Recurring.GetPayment @PaymentId = 200820
```

### 8.2 Equivalent ad-hoc
```sql
SELECT TOP 1 PaymentId, Cid, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, StatusReasonId, RecurringProgramTypeId, AuthenticationId, Generation
FROM Recurring.Payment WITH (NOLOCK) WHERE PaymentId = 200820
```

### 8.3 Get payment with resolved lookups
```sql
SELECT p.*, rpt.Name AS ProgramType, sr.Name AS StatusReason
FROM Recurring.Payment p WITH (NOLOCK)
LEFT JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK) ON p.RecurringProgramTypeId = rpt.RecurringProgramTypeID
LEFT JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON p.StatusReasonId = sr.StatusReasonID
WHERE p.PaymentId = 200820
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPayment | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPayment.sql*
