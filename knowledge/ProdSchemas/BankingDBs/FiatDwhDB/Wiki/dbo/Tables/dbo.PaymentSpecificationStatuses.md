# dbo.PaymentSpecificationStatuses

> Event-sourced status table tracking the lifecycle of payment specifications (New, Active, Cancelled, CancelledPending, Error).

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (+ PK + unique) |

---

## 1. Business Meaning

PaymentSpecificationStatuses records every lifecycle state change for a payment specification (direct debit mandate). Each row captures when a specification transitioned between states - from initial creation (New) through activation (Active) to potential cancellation or error.

Data is created by dbo.AddPaymentSpecificationStatus.

---

## 2. Business Logic

### 2.1 Specification Lifecycle

**What**: Payment specifications progress through a defined lifecycle.

**Columns/Parameters Involved**: `PaymentSpecificationStatusId`, `EventTimestamp`

**Rules**:
- PaymentSpecificationStatusId: 0=New, 1=Active, 2=Cancelled, 3=CancelledPending, 4=Error. See [Payment Specification Status Type](../../_glossary.md#payment-specification-status-type).
- Normal flow: New(0) -> Active(1) -> Cancelled(2)
- Cancellation flow: Active(1) -> CancelledPending(3) -> Cancelled(2)

---

## 3. Data Overview

N/A - querying live specification status data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to dbo.PaymentSpecifications.Id. The specification whose status changed. |
| 3 | PaymentSpecificationStatusId | tinyint | NO | - | CODE-BACKED | Status: 0=New, 1=Active, 2=Cancelled, 3=CancelledPending, 4=Error. See [Payment Specification Status Type](../../_glossary.md#payment-specification-status-type). |
| 4 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the status change occurred in the source system. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentSpecificationId | dbo.PaymentSpecifications | FK | Parent specification |
| PaymentSpecificationStatusId | Dictionary.PaymentSpecificationStatusTypes | Implicit | Status value |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddPaymentSpecificationStatus | INSERT | Writer | Records status changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecificationStatuses (table)
└── dbo.PaymentSpecifications (table)
    └── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecifications | Table | FK from PaymentSpecificationId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddPaymentSpecificationStatus | Stored Procedure | Writes status records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecificationStatuses | CLUSTERED | Id ASC | - | - | Active |
| UIX_PaymentSpecificationStatuses_... | NC UNIQUE | PaymentSpecificationId, PaymentSpecificationStatusId, EventTimestamp | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentSpecificationStatuses_...PaymentSpecifications_Id | FK | PaymentSpecificationId -> dbo.PaymentSpecifications.Id |

---

## 8. Sample Queries

### 8.1 Get status history for a specification
```sql
SELECT pss.PaymentSpecificationStatusId, dst.Name AS Status, pss.EventTimestamp, pss.Created
FROM dbo.PaymentSpecificationStatuses pss WITH (NOLOCK)
JOIN Dictionary.PaymentSpecificationStatusTypes dst WITH (NOLOCK) ON dst.Id = pss.PaymentSpecificationStatusId
WHERE pss.PaymentSpecificationId = 100 ORDER BY pss.EventTimestamp;
```

### 8.2 Find active specifications
```sql
SELECT DISTINCT ps.PaymentSpecificationId
FROM dbo.PaymentSpecificationStatuses ps WITH (NOLOCK)
WHERE ps.PaymentSpecificationStatusId = 1
AND NOT EXISTS (SELECT 1 FROM dbo.PaymentSpecificationStatuses WITH (NOLOCK)
                WHERE PaymentSpecificationId = ps.PaymentSpecificationId AND PaymentSpecificationStatusId IN (2,4));
```

### 8.3 Count specifications by current status
```sql
;WITH Latest AS (
    SELECT PaymentSpecificationId, PaymentSpecificationStatusId,
           ROW_NUMBER() OVER (PARTITION BY PaymentSpecificationId ORDER BY EventTimestamp DESC) AS rn
    FROM dbo.PaymentSpecificationStatuses WITH (NOLOCK)
)
SELECT dst.Name AS Status, COUNT(*) AS Cnt
FROM Latest l
JOIN Dictionary.PaymentSpecificationStatusTypes dst WITH (NOLOCK) ON dst.Id = l.PaymentSpecificationStatusId
WHERE l.rn = 1
GROUP BY dst.Name ORDER BY Cnt DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationStatuses | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecificationStatuses.sql*
