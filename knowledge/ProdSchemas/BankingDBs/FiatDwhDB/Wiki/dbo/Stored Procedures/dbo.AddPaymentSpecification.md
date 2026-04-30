# dbo.AddPaymentSpecification

> Upsert procedure that creates a payment specification (direct debit mandate), deduplicating on PaymentSpecificationGuid.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into PaymentSpecifications, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecification creates or retrieves a payment specification (direct debit mandate). Deduplicates on PaymentSpecificationGuid with UPDLOCK/HOLDLOCK. Supports optional parameters for error handling (CreationStatus, ErrorReason) and external references (ExternalId, ExternalOriginatorId).

---

## 2. Business Logic

### 2.1 Idempotent Specification Creation

**Rules**: Deduplicates on PaymentSpecificationGuid. Returns existing Id if already present. Optional fields default to NULL for backward compatibility.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Created | datetime2 | NO | - | CODE-BACKED | Event timestamp. |
| 2 | @PaymentSpecificationGuid | uniqueidentifier | NO | - | CODE-BACKED | Unique external identifier. |
| 3 | @PaymentSpecificationTypeId | tinyint | NO | - | CODE-BACKED | Type: 0=Unknown, 1=DirectDebit. See [Payment Specification Type](../../_glossary.md#payment-specification-type). |
| 4 | @EventTimestamp | datetime2 | NO | - | CODE-BACKED | Source system event time. |
| 5 | @ExternalId | nvarchar(128) | YES | NULL | CODE-BACKED | Provider's external ID. |
| 6 | @ExternalOriginatorId | nvarchar(128) | YES | NULL | CODE-BACKED | Originator's external ID. |
| 7 | @Reference | nvarchar(128) | NO | - | CODE-BACKED | Payment reference string. |
| 8 | @CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to FiatCurrencyBalances.Id. |
| 9 | @CreationStatus | nvarchar(50) | YES | NULL | CODE-BACKED | Setup result (e.g., "Success", "Failed"). |
| 10 | @ErrorReason | nvarchar(100) | YES | NULL | CODE-BACKED | Error description if setup failed. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.PaymentSpecifications | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecification (procedure)
└── dbo.PaymentSpecifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecifications | Table | Upsert target |

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

### 8.1 Create a direct debit specification
```sql
EXEC dbo.AddPaymentSpecification @Created = SYSUTCDATETIME(),
    @PaymentSpecificationGuid = NEWID(), @PaymentSpecificationTypeId = 1,
    @EventTimestamp = SYSUTCDATETIME(), @Reference = 'DD-REF-001',
    @CurrencyBalanceId = 730092;
```

### 8.2 Create with error
```sql
EXEC dbo.AddPaymentSpecification @Created = SYSUTCDATETIME(),
    @PaymentSpecificationGuid = NEWID(), @PaymentSpecificationTypeId = 1,
    @EventTimestamp = SYSUTCDATETIME(), @Reference = 'DD-REF-002',
    @CurrencyBalanceId = 730092, @CreationStatus = 'Failed', @ErrorReason = 'Invalid mandate';
```

### 8.3 Verify
```sql
SELECT * FROM dbo.PaymentSpecifications WITH (NOLOCK) WHERE CurrencyBalanceId = 730092 ORDER BY Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecification | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecification.sql*
