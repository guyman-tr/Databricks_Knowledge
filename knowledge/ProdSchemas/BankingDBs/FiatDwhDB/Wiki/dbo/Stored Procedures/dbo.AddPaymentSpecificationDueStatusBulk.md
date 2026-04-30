# dbo.AddPaymentSpecificationDueStatusBulk

> Bulk INSERT procedure that inserts multiple payment due status records from the PaymentSpecificationDueStatusType TVP in a single operation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Bulk INSERT into PaymentSpecificationDueStatuses from TVP |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecificationDueStatusBulk performs a bulk INSERT of payment due status records from the PaymentSpecificationDueStatusType TVP. Unlike upsert procedures, this has no deduplication logic - it relies on the unique constraint on the target table to prevent duplicates. Returns the last SCOPE_IDENTITY().

---

## 2. Business Logic

No complex logic. Direct bulk INSERT from TVP to table. The unique constraint (DueId, DueStatusId, CorrelationId, EventTimestamp) on PaymentSpecificationDueStatuses provides dedup at the constraint level.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentSpecificationDueStatuses | PaymentSpecificationDueStatusType | NO | READONLY | CODE-BACKED | TVP containing batch of due status records. See dbo.PaymentSpecificationDueStatusType. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT | dbo.PaymentSpecificationDueStatuses | Write | Bulk insert target |
| @param | dbo.PaymentSpecificationDueStatusType | Type | TVP parameter type |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecificationDueStatusBulk (procedure)
├── dbo.PaymentSpecificationDueStatuses (table)
└── dbo.PaymentSpecificationDueStatusType (type)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDueStatuses | Table | INSERT target |
| dbo.PaymentSpecificationDueStatusType | UDT | TVP parameter type |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Bulk insert due statuses
```sql
DECLARE @Statuses dbo.PaymentSpecificationDueStatusType;
INSERT INTO @Statuses (DueId, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
VALUES (100, 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 50.00),
       (101, 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 75.00);
EXEC dbo.AddPaymentSpecificationDueStatusBulk @PaymentSpecificationDueStatuses = @Statuses;
```

### 8.2 Verify insertions
```sql
SELECT * FROM dbo.PaymentSpecificationDueStatuses WITH (NOLOCK) WHERE DueId IN (100, 101) ORDER BY Created DESC;
```

### 8.3 Count recent due statuses
```sql
SELECT COUNT(*) FROM dbo.PaymentSpecificationDueStatuses WITH (NOLOCK) WHERE Created >= DATEADD(HOUR, -1, GETUTCDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecificationDueStatusBulk | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecificationDueStatusBulk.sql*
