# dbo.PaymentSpecificationDetails

> Stores originator details for payment specifications, capturing who initiated the direct debit mandate.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (+ PK + unique) |

---

## 1. Business Meaning

PaymentSpecificationDetails stores the originator information for each payment specification (direct debit mandate). It captures the name and ID of the party that set up the payment instruction, providing an audit trail for who initiated each direct debit arrangement.

Data is created by dbo.AddPaymentSpecificationDetails. The unique constraint prevents duplicate detail records for the same specification-originator-timestamp combination.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is an originator detail record linked to a payment specification.

---

## 3. Data Overview

N/A - querying live payment spec data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to dbo.PaymentSpecifications.Id. The specification these details belong to. |
| 3 | OriginatorName | nvarchar(128) | NO | - | CODE-BACKED | Name of the party that set up the payment specification (e.g., the direct debit originator company name). |
| 4 | OriginatorId | nvarchar(128) | YES | - | CODE-BACKED | External identifier of the originator. NULL if not provided. |
| 5 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the detail event occurred in the source system. |
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
| dbo.AddPaymentSpecificationDetails | INSERT | Writer | Creates detail records |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecificationDetails (table)
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
| dbo.AddPaymentSpecificationDetails | Stored Procedure | Writes details |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecificationDetails | CLUSTERED | Id ASC | - | - | Active |
| UIX_PaymentSpecificationDetails_... | NC UNIQUE | PaymentSpecificationId, OriginatorName, OriginatorId, EventTimestamp | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentSpecificationDetails_...PaymentSpecifications_Id | FK | PaymentSpecificationId -> dbo.PaymentSpecifications.Id |

---

## 8. Sample Queries

### 8.1 Find details for a payment specification
```sql
SELECT * FROM dbo.PaymentSpecificationDetails WITH (NOLOCK)
WHERE PaymentSpecificationId = 100 ORDER BY EventTimestamp;
```

### 8.2 Find all specifications by originator
```sql
SELECT d.PaymentSpecificationId, d.OriginatorName, d.OriginatorId, d.EventTimestamp
FROM dbo.PaymentSpecificationDetails d WITH (NOLOCK)
WHERE d.OriginatorName LIKE '%Netflix%';
```

### 8.3 Recent detail records
```sql
SELECT TOP 20 d.PaymentSpecificationId, d.OriginatorName, d.Created
FROM dbo.PaymentSpecificationDetails d WITH (NOLOCK)
ORDER BY d.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationDetails | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecificationDetails.sql*
