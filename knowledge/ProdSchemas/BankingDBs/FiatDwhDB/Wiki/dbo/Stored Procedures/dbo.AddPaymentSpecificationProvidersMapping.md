# dbo.AddPaymentSpecificationProvidersMapping

> Upsert procedure linking a payment specification to its provider-side (Tribe) identifier, deduplicating on PaymentSpecificationId.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into PaymentSpecificationsProvidersMapping, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddPaymentSpecificationProvidersMapping creates or retrieves the provider mapping for a payment specification. Deduplicates on PaymentSpecificationId with UPDLOCK/HOLDLOCK. Includes an optional AddressId for the provider's payment address.

---

## 2. Business Logic

### 2.1 Idempotent Provider Mapping

**Rules**: Dedup on PaymentSpecificationId. Returns existing Id if already mapped.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AddressId | nvarchar(128) | YES | - | CODE-BACKED | Provider-side payment address ID. |
| 2 | @Created | datetime2 | NO | - | CODE-BACKED | Event timestamp. |
| 3 | @ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers (1=Tribe). |
| 4 | @PaymentSpecificationProviderId | nvarchar(128) | NO | - | CODE-BACKED | Tribe's specification identifier. |
| 5 | @PaymentSpecificationId | bigint | NO | - | CODE-BACKED | FK to PaymentSpecifications.Id. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.PaymentSpecificationsProvidersMapping | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddPaymentSpecificationProvidersMapping (procedure)
└── dbo.PaymentSpecificationsProvidersMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.PaymentSpecificationsProvidersMapping | Table | Upsert target |

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

### 8.1 Create a mapping
```sql
EXEC dbo.AddPaymentSpecificationProvidersMapping @AddressId = 'ADDR-001', @Created = SYSUTCDATETIME(),
    @ProviderId = 1, @PaymentSpecificationProviderId = 'TRIBE-PS-001', @PaymentSpecificationId = 100;
```

### 8.2 Verify
```sql
SELECT * FROM dbo.PaymentSpecificationsProvidersMapping WITH (NOLOCK) WHERE PaymentSpecificationId = 100;
```

### 8.3 Resolve to account
```sql
SELECT a.Gcid, m.PaymentSpecificationProviderId
FROM dbo.PaymentSpecificationsProvidersMapping m WITH (NOLOCK)
JOIN dbo.PaymentSpecifications ps WITH (NOLOCK) ON ps.Id = m.PaymentSpecificationId
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.Id = ps.CurrencyBalanceId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = cb.AccountId
WHERE m.PaymentSpecificationId = 100;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddPaymentSpecificationProvidersMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddPaymentSpecificationProvidersMapping.sql*
