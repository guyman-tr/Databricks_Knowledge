# dbo.PaymentSpecificationDueStatusType

> User-defined table type for bulk insertion of payment specification due status records into dbo.PaymentSpecificationDueStatuses.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | User Defined Type |
| **Key Identifier** | Table type mirroring dbo.PaymentSpecificationDueStatuses structure (minus Id) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

PaymentSpecificationDueStatusType is a table-valued parameter type that mirrors the structure of dbo.PaymentSpecificationDueStatuses. It enables bulk insertion of payment due status events, such as when multiple direct debit collections are processed simultaneously and their statuses need to be recorded.

This type exists to support efficient batch insertion of due status records. During payment processing cycles, multiple dues may change status at the same time (e.g., a batch of direct debits settling or failing), and recording them individually would be inefficient.

Data flows through this type when the AddPaymentSpecificationDueStatusBulk procedure receives a batch of due status events from the payment processing system and inserts them into the PaymentSpecificationDueStatuses table in a single operation.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a data-transfer type that mirrors the target table structure for bulk insertion.

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DueId | bigint | YES | - | CODE-BACKED | FK to dbo.PaymentSpecificationDues.Id. Identifies which payment due this status event belongs to. Nullable in the type to allow flexible loading patterns. |
| 2 | DueStatusId | tinyint | YES | - | CODE-BACKED | Status of the payment due at this point in time. Business meaning depends on the payment specification lifecycle. |
| 3 | CorrelationId | uniqueidentifier | YES | - | CODE-BACKED | Unique identifier linking this status event to the business operation that triggered it. Enables distributed tracing across services. |
| 4 | EventTimestamp | datetime2(7) | YES | - | CODE-BACKED | Timestamp when the status change occurred in the source system (provider or payment processor). |
| 5 | Created | datetime2(7) | YES | - | CODE-BACKED | Timestamp when this record was created in the database. Typically set by the consuming procedure. |
| 6 | Amount | decimal(36,18) | YES | - | CODE-BACKED | Monetary amount associated with this due status event. Captures the payment amount at the time of status change. All columns nullable for flexible TVP population. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| DueId | dbo.PaymentSpecificationDues | Implicit | Identifies the payment specification due this status belongs to |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddPaymentSpecificationDueStatusBulk | Parameter | Parameter Type | Accepts batch of due status records for bulk insertion |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddPaymentSpecificationDueStatusBulk | Stored Procedure | TVP parameter type for bulk due status insertion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for User Defined Type.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and populate for bulk status insertion
```sql
DECLARE @Statuses dbo.PaymentSpecificationDueStatusType;
INSERT INTO @Statuses (DueId, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
VALUES (1001, 1, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 250.000000000000000000),
       (1002, 2, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), 150.500000000000000000);
EXEC dbo.AddPaymentSpecificationDueStatusBulk @DueStatuses = @Statuses;
```

### 8.2 Populate from a query
```sql
DECLARE @Statuses dbo.PaymentSpecificationDueStatusType;
INSERT INTO @Statuses (DueId, DueStatusId, CorrelationId, EventTimestamp, Created, Amount)
SELECT d.Id, 2, NEWID(), SYSUTCDATETIME(), SYSUTCDATETIME(), ds.Amount
FROM dbo.PaymentSpecificationDues d WITH (NOLOCK)
JOIN dbo.PaymentSpecificationDueStatuses ds WITH (NOLOCK) ON ds.DueId = d.Id
WHERE d.DueTime < DATEADD(DAY, -30, SYSUTCDATETIME());
```

### 8.3 Check the type definition
```sql
SELECT c.name AS ColumnName, t.name AS DataType, c.precision, c.scale, c.is_nullable
FROM sys.table_types tt
JOIN sys.columns c ON c.object_id = tt.type_table_object_id
JOIN sys.types t ON c.system_type_id = t.system_type_id AND c.user_type_id = t.user_type_id
WHERE tt.name = 'PaymentSpecificationDueStatusType' AND tt.schema_id = SCHEMA_ID('dbo')
ORDER BY c.column_id;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationDueStatusType | Type: User Defined Type | Source: FiatDwhDB/dbo/User Defined Types/dbo.PaymentSpecificationDueStatusType.sql*
