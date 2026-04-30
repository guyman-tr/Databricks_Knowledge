# dbo.PaymentSpecifications

> Stores payment specifications (direct debit mandates) linked to currency balances, tracking the setup and lifecycle of automated payment instructions.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

PaymentSpecifications stores direct debit mandates and other automated payment instructions linked to a customer's currency balance. Each specification defines a recurring or automated payment arrangement (e.g., a SEPA Direct Debit mandate) that authorizes third parties to collect payments from the customer's balance.

Data is created by dbo.AddPaymentSpecification. Child tables track specification statuses, payment dues, due statuses, details, and provider mappings.

---

## 2. Business Logic

### 2.1 Payment Specification Lifecycle

**What**: Direct debit mandates go through a lifecycle: New -> Active -> Cancelled/Error.

**Columns/Parameters Involved**: `PaymentSpecificationTypeId`, `PaymentSpecificationGuid`, `CreationStatus`, `ErrorReason`

**Rules**:
- PaymentSpecificationTypeId: 0=Unknown, 1=DirectDebit. See [Payment Specification Type](../../_glossary.md#payment-specification-type).
- CreationStatus tracks the initial setup result
- ErrorReason captures why a specification failed to set up
- Status progression tracked in dbo.PaymentSpecificationStatuses

---

## 3. Data Overview

N/A - querying live payment specification data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. The balance this specification draws from. |
| 3 | PaymentSpecificationGuid | uniqueidentifier | NO | - | CODE-BACKED | External-facing unique identifier for this specification. |
| 4 | PaymentSpecificationTypeId | tinyint | NO | - | CODE-BACKED | Type: 0=Unknown, 1=DirectDebit. See [Payment Specification Type](../../_glossary.md#payment-specification-type). |
| 5 | ExternalId | nvarchar(128) | YES | - | CODE-BACKED | Provider's external ID for this specification. |
| 6 | Reference | nvarchar(128) | NO | - | CODE-BACKED | Payment reference string identifying this mandate. |
| 7 | ExternalOriginatorId | nvarchar(128) | YES | - | CODE-BACKED | ID of the external party that initiated the specification (e.g., the direct debit originator). |
| 8 | EventTimestamp | datetime2(7) | NO | - | CODE-BACKED | When the specification event occurred in the source system. |
| 9 | Created | datetime2(7) | NO | - | CODE-BACKED | When this record was created in the DWH. |
| 10 | CreationStatus | nvarchar(50) | YES | - | CODE-BACKED | Result of the initial specification setup (e.g., "Success", "Failed"). |
| 11 | ErrorReason | nvarchar(100) | YES | - | CODE-BACKED | Error description if specification setup failed. NULL on success. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyBalanceId | dbo.FiatCurrencyBalances | FK | Balance this specification draws from |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.PaymentSpecificationDetails | PaymentSpecificationId | FK | Specification details |
| dbo.PaymentSpecificationDues | PaymentSpecificationId | FK | Payment dues/collections |
| dbo.PaymentSpecificationStatuses | PaymentSpecificationId | FK | Lifecycle statuses |
| dbo.PaymentSpecificationsProvidersMapping | PaymentSpecificationId | FK | Provider ID mapping |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecifications (table)
└── dbo.FiatCurrencyBalances (table)
    ├── dbo.FiatAccount (table)
    └── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | FK from CurrencyBalanceId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationDetails | Table | FK from PaymentSpecificationId |
| dbo.PaymentSpecificationDues | Table | FK from PaymentSpecificationId |
| dbo.PaymentSpecificationStatuses | Table | FK from PaymentSpecificationId |
| dbo.PaymentSpecificationsProvidersMapping | Table | FK from PaymentSpecificationId |
| dbo.AddPaymentSpecification | Stored Procedure | Inserts specifications |
| dbo.GetPaymentSpecificationByGuid | Stored Procedure | Reads by GUID |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecifications | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_PaymentSpecifications_CurrencyBalanceId_FiatCurrencyBalances_Id | FK | CurrencyBalanceId -> dbo.FiatCurrencyBalances.Id |

---

## 8. Sample Queries

### 8.1 Find specifications for a currency balance
```sql
SELECT ps.Id, ps.PaymentSpecificationGuid, pst.Name AS Type, ps.Reference, ps.CreationStatus, ps.Created
FROM dbo.PaymentSpecifications ps WITH (NOLOCK)
JOIN Dictionary.PaymentSpecificationTypes pst WITH (NOLOCK) ON pst.Id = ps.PaymentSpecificationTypeId
WHERE ps.CurrencyBalanceId = 730092 ORDER BY ps.Created DESC;
```

### 8.2 Find specifications with errors
```sql
SELECT Id, PaymentSpecificationGuid, CreationStatus, ErrorReason, Created
FROM dbo.PaymentSpecifications WITH (NOLOCK)
WHERE ErrorReason IS NOT NULL ORDER BY Created DESC;
```

### 8.3 Get specification with current status
```sql
SELECT ps.PaymentSpecificationGuid, ps.Reference,
       pss.PaymentSpecificationStatusId, dst.Name AS Status, pss.Created AS StatusDate
FROM dbo.PaymentSpecifications ps WITH (NOLOCK)
CROSS APPLY (SELECT TOP 1 * FROM dbo.PaymentSpecificationStatuses WITH (NOLOCK)
             WHERE PaymentSpecificationId = ps.Id ORDER BY Created DESC) pss
JOIN Dictionary.PaymentSpecificationStatusTypes dst WITH (NOLOCK) ON dst.Id = pss.PaymentSpecificationStatusId
WHERE ps.CurrencyBalanceId = 730092;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecifications | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecifications.sql*
