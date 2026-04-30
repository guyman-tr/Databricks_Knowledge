# dbo.AddPaymentSpecificationDue

> Upsert procedure that creates a payment due (scheduled collection event), deduplicating on PaymentSpecificationDueGuid.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into PaymentSpecificationDues, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecificationDue creates or retrieves a payment due record. Deduplicates on PaymentSpecificationDueGuid with UPDLOCK/HOLDLOCK.

---

## 2. Business Logic

### 2.1 Idempotent Due Creation

**Rules**: Dedup on PaymentSpecificationDueGuid. Returns existing Id if present.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentSpecificationDueGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external identifier. |
| 2 | @PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to PaymentSpecifications.Id. |
| 3 | @DueTime | datetime2 | NO | - | CODE-BACKED | Scheduled collection time. |
| 4 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | Source system event time. |
| 5 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.PaymentSpecificationDues | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecificationDue (procedure)
└── dbo.PaymentSpecificationDues (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDues | Table | Upsert target |

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

### 8.1 Create a payment due
```sql
EXEC dbo.AddPaymentSpecificationDue @PaymentSpecificationDueGuid = NEWID(),
    @PaymentSpecificationId = 100, @DueTime = '2026-05-01T00:00:00',
    @EventTimestamp = SYSUTCDATETIME(), @Created = SYSUTCDATETIME();
```

### 8.2 Verify
```sql
SELECT * FROM dbo.PaymentSpecificationDues WITH (NOLOCK) WHERE PaymentSpecificationId = 100;
```

### 8.3 Test idempotency
```sql
DECLARE @guid UNIQUEIDENTIFIER = 'A1B2C3D4-E5F6-7890-ABCD-EF1234567890';
EXEC dbo.AddPaymentSpecificationDue @PaymentSpecificationDueGuid = @guid,
    @PaymentSpecificationId = 100, @DueTime = '2026-05-01T00:00:00',
    @EventTimestamp = SYSUTCDATETIME(), @Created = SYSUTCDATETIME();
-- Second call returns existing Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecificationDue | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecificationDue.sql*
