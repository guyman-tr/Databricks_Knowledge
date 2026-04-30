# dbo.AddPaymentSpecificationDetails

> Upsert procedure that creates a payment specification detail (originator info), deduplicating on PaymentSpecificationId + OriginatorName + OriginatorId + EventTimestamp.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into PaymentSpecificationDetails, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecificationDetails creates or retrieves a detail record (originator information) for a payment specification. Deduplicates on the combination of PaymentSpecificationId + OriginatorName + OriginatorId + EventTimestamp.

---

## 2. Business Logic

### 2.1 Multi-Column Deduplication

**Rules**: UPDLOCK/HOLDLOCK. Dedup on (PaymentSpecificationId, OriginatorName, OriginatorId, EventTimestamp). Returns existing Id or inserts new.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2 | NO | - | CODE-BACKED | DWH recording timestamp. |
| 2 | @OriginatorName | nvarchar(128) | NO | - | CODE-BACKED | Originator company name. |
| 3 | @OriginatorId | nvarchar(128) | YES | - | CODE-BACKED | Originator external ID. |
| 4 | @PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to PaymentSpecifications.Id. |
| 5 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | Source system event time. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.PaymentSpecificationDetails | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecificationDetails (procedure)
└── dbo.PaymentSpecificationDetails (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDetails | Table | Upsert target |

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

### 8.1 Add originator details
```sql
EXEC dbo.AddPaymentSpecificationDetails @Created = SYSUTCDATETIME(),
    @OriginatorName = 'Netflix International', @OriginatorId = 'NFLX-001',
    @PaymentSpecificationId = 100, @EventTimestamp = SYSUTCDATETIME();
```

### 8.2 Verify details
```sql
SELECT * FROM dbo.PaymentSpecificationDetails WITH (NOLOCK) WHERE PaymentSpecificationId = 100;
```

### 8.3 Test idempotency
```sql
EXEC dbo.AddPaymentSpecificationDetails @Created = SYSUTCDATETIME(),
    @OriginatorName = 'Netflix International', @OriginatorId = 'NFLX-001',
    @PaymentSpecificationId = 100, @EventTimestamp = '2026-04-14T13:00:00';
-- Returns existing Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecificationDetails | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecificationDetails.sql*
