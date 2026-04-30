# dbo.PaymentSpecificationsProvidersMapping

> Mapping table linking internal payment specification IDs to provider-side (Tribe) identifiers, including the provider's address ID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 0 active (PK only) |

---

## 1. Business Meaning

PaymentSpecificationsProvidersMapping links each internal payment specification (direct debit mandate) to its identifier in the external provider system (Tribe). It also stores the provider's address ID, which references the payment address or endpoint within Tribe's system.

Data is created by dbo.AddPaymentSpecificationProvidersMapping.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Straightforward ID mapping table following the same pattern as Cards/CurrencyBalances/Transactions provider mappings.

---

## 3. Data Overview

N/A - mapping data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to dbo.PaymentSpecifications.Id. The internal specification being mapped. |
| 3 | ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers. Currently 1=Tribe. See [Provider](../../_glossary.md#provider). |
| 4 | PaymentSpecificationProviderId | nvarchar(128) | NO | - | CODE-BACKED | The provider's identifier for this payment specification in their system. |
| 5 | AddressId | nvarchar(128) | YES | - | CODE-BACKED | Provider-side payment address/endpoint ID. Identifies the payment destination within Tribe's system. NULL if not applicable. |
| 6 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentSpecificationId | dbo.PaymentSpecifications | FK | Internal specification |
| ProviderId | Dictionary.Providers | FK | External provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddPaymentSpecificationProvidersMapping | INSERT | Writer | Creates mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.PaymentSpecificationsProvidersMapping (table)
└── dbo.PaymentSpecifications (table)
    └── dbo.FiatCurrencyBalances (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecifications | Table | FK from PaymentSpecificationId |
| Dictionary.Providers | Table | FK from ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddPaymentSpecificationProvidersMapping | Stored Procedure | Writes mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_PaymentSpecificationsProvidersMapping | CLUSTERED | Id ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_...PaymentSpecificationId_PaymentSpecifications_Id | FK | PaymentSpecificationId -> dbo.PaymentSpecifications.Id |
| FK_..._Providers | FK | ProviderId -> Dictionary.Providers.Id |

---

## 8. Sample Queries

### 8.1 Find provider ID for a specification
```sql
SELECT PaymentSpecificationProviderId, AddressId
FROM dbo.PaymentSpecificationsProvidersMapping WITH (NOLOCK)
WHERE PaymentSpecificationId = 100;
```

### 8.2 Resolve provider specification to account
```sql
SELECT a.Gcid, cb.CurrencyISON, m.PaymentSpecificationProviderId
FROM dbo.PaymentSpecificationsProvidersMapping m WITH (NOLOCK)
JOIN dbo.PaymentSpecifications ps WITH (NOLOCK) ON ps.Id = m.PaymentSpecificationId
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.Id = ps.CurrencyBalanceId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = cb.AccountId
WHERE m.PaymentSpecificationProviderId = '12345';
```

### 8.3 Count specifications per provider
```sql
SELECT p.Name, COUNT(*) AS SpecCount
FROM dbo.PaymentSpecificationsProvidersMapping m WITH (NOLOCK)
JOIN Dictionary.Providers p WITH (NOLOCK) ON p.Id = m.ProviderId
GROUP BY p.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.PaymentSpecificationsProvidersMapping | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.PaymentSpecificationsProvidersMapping.sql*
