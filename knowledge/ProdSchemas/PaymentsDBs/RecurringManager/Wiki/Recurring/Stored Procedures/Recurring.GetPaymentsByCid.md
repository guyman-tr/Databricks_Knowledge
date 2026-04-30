# Recurring.GetPaymentsByCid

> Retrieves all recurring payment plans for a customer, returning complete payment details regardless of status.

| Property | Value |
|----------|-------|
| **Schema** | Recurring |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns set of Payment rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Simple reader that returns all recurring payment plans belonging to a specific customer. No status filtering - returns active, cancelled, blocked, and invalid plans. Used by the application to display a customer's complete recurring payment history and current subscriptions.

---

## 2. Business Logic

No complex business logic. Simple `SELECT ... FROM Recurring.Payment WHERE Cid = @Cid` with NOLOCK.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Cid | int (IN) | NO | - | CODE-BACKED | Customer ID. Returns all payment plans for this customer. |

**Return Columns**: PaymentId, Cid, FundingId, Amount, CurrencyId, StatusId, CreateDate, ModificationDate, StatusReasonId, RecurringProgramTypeId, AuthenticationId, Generation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Recurring.Payment | READER | SELECT WHERE Cid = @Cid |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Recurring.GetPaymentsByCid (procedure)
└── Recurring.Payment (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Recurring.Payment | Table | SELECT WHERE Cid |

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

### 8.1 Get all payments for a customer
```sql
EXEC Recurring.GetPaymentsByCid @Cid = 9252179
```

### 8.2 Equivalent with status names
```sql
SELECT p.*, rpt.Name AS ProgramType, sr.Name AS StatusReason
FROM Recurring.Payment p WITH (NOLOCK)
LEFT JOIN Dictionary.RecurringProgramType rpt WITH (NOLOCK) ON p.RecurringProgramTypeId = rpt.RecurringProgramTypeID
LEFT JOIN Dictionary.StatusReason sr WITH (NOLOCK) ON p.StatusReasonId = sr.StatusReasonID
WHERE p.Cid = 9252179
```

### 8.3 Count by status for a customer
```sql
SELECT p.StatusId, COUNT(*) AS PlanCount
FROM Recurring.Payment p WITH (NOLOCK)
WHERE p.Cid = 9252179
GROUP BY p.StatusId
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-16 | Enriched: 2026-04-16 | Quality: 9.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Recurring.GetPaymentsByCid | Type: Stored Procedure | Source: RecurringManager/Recurring/Stored Procedures/Recurring.GetPaymentsByCid.sql*
