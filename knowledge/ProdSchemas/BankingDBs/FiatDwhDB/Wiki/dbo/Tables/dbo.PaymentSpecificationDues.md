# dbo.PaymentSpecificationDues

> Tracks individual payment collection events (dues) under a payment specification, each representing a scheduled direct debit collection.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

PaymentSpecificationDues represents individual payment collection events under a direct debit mandate. Each row is a scheduled or executed payment collection - when a direct debit is collected from a customer's balance, a due record is created. Each due has its own lifecycle tracked in PaymentSpecificationDueStatuses.

Data is created by dbo.AddPaymentSpecificationDue.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Each due represents a single collection event within a payment specification.

---

## 3. Data Overview

N/A - querying live payment due data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. Referenced by PaymentSpecificationDueStatuses.DueId. |
| 2 | PaymentSpecificationDueGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique identifier for this payment due. |
| 3 | PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to dbo.PaymentSpecifications.Id. The parent specification this due belongs to. |
| 4 | DueTime | datetime2(7) | NO | - | CODE-BACKED | When this payment is scheduled to be collected. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the due event occurred in the source system. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was written to the DWH. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentSpecificationId | dbo.PaymentSpecifications | FK | Parent specification |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.PaymentSpecificationDueStatuses | DueId | FK | Due status events |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecificationDues (table)
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
| dbo.PaymentSpecificationDueStatuses | Table | FK from DueId |
| dbo.AddPaymentSpecificationDue | Stored Procedure | Writes due records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecificationDues | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentSpecificationDues_...PaymentSpecifications_Id | FK | PaymentSpecificationId -> dbo.PaymentSpecifications.Id |

---

## 8. Sample Queries

### 8.1 Find dues for a specification
```sql
SELECT Id, PaymentSpecificationDueGuid, DueTime, EventTimestamp, Created
FROM dbo.PaymentSpecificationDues WITH (NOLOCK)
WHERE PaymentSpecificationId = 100 ORDER BY DueTime;
```

### 8.2 Find upcoming dues
```sql
SELECT d.Id, d.DueTime, ps.Reference, ps.PaymentSpecificationGuid
FROM dbo.PaymentSpecificationDues d WITH (NOLOCK)
JOIN dbo.PaymentSpecifications ps WITH (NOLOCK) ON ps.Id = d.PaymentSpecificationId
WHERE d.DueTime >= GETUTCDATE() ORDER BY d.DueTime;
```

### 8.3 Get due with latest status
```sql
SELECT d.PaymentSpecificationDueGuid, d.DueTime, ds.DueStatusId, ds.Amount, ds.Created
FROM dbo.PaymentSpecificationDues d WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 * FROM dbo.PaymentSpecificationDueStatuses WITH (NOLOCK)
             WHERE DueId = d.Id ORDER BY Created DESC) ds
WHERE d.PaymentSpecificationId = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationDues | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecificationDues.sql*
