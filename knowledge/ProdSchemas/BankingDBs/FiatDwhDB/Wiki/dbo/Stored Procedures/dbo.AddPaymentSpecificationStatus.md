# dbo.AddPaymentSpecificationStatus

> Upsert procedure recording a payment specification status change, deduplicating on PaymentSpecificationId + StatusId + EventTimestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into PaymentSpecificationStatuses, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecificationStatus records a specification lifecycle event. Deduplicates on (PaymentSpecificationId, PaymentSpecificationStatusId, EventTimestamp) with UPDLOCK/HOLDLOCK. Returns existing Id if duplicate, otherwise inserts and returns new Id.

---

## 2. Business Logic

### 2.1 Triple-Key Deduplication

**Rules**: Dedup on (PaymentSpecificationId + StatusId + EventTimestamp). Prevents duplicate status events for the same specification at the same timestamp.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to PaymentSpecifications.Id. |
| 2 | @PaymentSpecificationStatusId | tinyint | NO | - | CODE-BACKED | Status: 0=New, 1=Active, 2=Cancelled, 3=CancelledPending, 4=Error. See [Payment Specification Status Type](../../_glossary.md#payment-specification-status-type). |
| 3 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | Source system event time. Part of dedup key. |
| 4 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.PaymentSpecificationStatuses | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecificationStatus (procedure)
└── dbo.PaymentSpecificationStatuses (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationStatuses | Table | Upsert target |

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

### 8.1 Record specification activation
```sql
EXEC dbo.AddPaymentSpecificationStatus @PaymentSpecificationId = 100,
    @PaymentSpecificationStatusId = 1, @EventTimestamp = SYSUTCDATETIME(), @Created = SYSUTCDATETIME();
```

### 8.2 Record cancellation
```sql
EXEC dbo.AddPaymentSpecificationStatus @PaymentSpecificationId = 100,
    @PaymentSpecificationStatusId = 2, @EventTimestamp = SYSUTCDATETIME(), @Created = SYSUTCDATETIME();
```

### 8.3 Verify status history
```sql
SELECT PaymentSpecificationStatusId, EventTimestamp FROM dbo.PaymentSpecificationStatuses WITH (NOLOCK)
WHERE PaymentSpecificationId = 100 ORDER BY EventTimestamp;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecificationStatus | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecificationStatus.sql*
