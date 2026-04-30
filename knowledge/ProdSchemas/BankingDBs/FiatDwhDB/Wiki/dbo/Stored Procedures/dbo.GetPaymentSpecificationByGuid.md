# dbo.GetPaymentSpecificationByGuid

> Simple lookup that retrieves a payment specification by its PaymentSpecificationGuid. Uses WITH(NOLOCK).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | SELECT from PaymentSpecifications WHERE PaymentSpecificationGuid = @PaymentSpecificationGuid |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

GetPaymentSpecificationByGuid retrieves a payment specification (direct debit mandate) by its GUID. Returns Id, CurrencyBalanceId, PaymentSpecificationGuid, PaymentSpecificationTypeId, ExternalId, Reference, ExternalOriginatorId, EventTimestamp, Created.

---

## 2. Business Logic

No complex logic. Simple GUID lookup with WITH(NOLOCK).

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PaymentSpecificationGuid | uniqueidentifier | NO | - | CODE-BACKED | The payment specification GUID to look up. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | dbo.PaymentSpecifications | Read | GUID lookup |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.GetPaymentSpecificationByGuid (procedure)
└── dbo.PaymentSpecifications (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecifications | Table | SELECT source |

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

### 8.1 Look up a payment specification
```sql
EXEC dbo.GetPaymentSpecificationByGuid @PaymentSpecificationGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.2 Equivalent query
```sql
SELECT Id, CurrencyBalanceId, PaymentSpecificationGuid, PaymentSpecificationTypeId,
       ExternalId, Reference, ExternalOriginatorId, EventTimestamp, Created
FROM dbo.PaymentSpecifications WITH (NOLOCK)
WHERE PaymentSpecificationGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
```

### 8.3 Chain with status lookup
```sql
DECLARE @r TABLE (Id bigint, CurrencyBalanceId bigint, PaymentSpecificationGuid uniqueidentifier, PaymentSpecificationTypeId tinyint, ExternalId nvarchar(128), Reference nvarchar(128), ExternalOriginatorId nvarchar(128), EventTimestamp datetime2, Created datetime2);
INSERT INTO @r EXEC dbo.GetPaymentSpecificationByGuid @PaymentSpecificationGuid = 'A1B2C3D4-0000-0000-0000-000000000001';
SELECT r.*, pss.PaymentSpecificationStatusId FROM @r r
CROSS APPLY (SELECT TOP 1 * FROM dbo.PaymentSpecificationStatuses WITH (NOLOCK) WHERE PaymentSpecificationId = r.Id ORDER BY Created DESC) pss;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.GetPaymentSpecificationByGuid | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.GetPaymentSpecificationByGuid.sql*
