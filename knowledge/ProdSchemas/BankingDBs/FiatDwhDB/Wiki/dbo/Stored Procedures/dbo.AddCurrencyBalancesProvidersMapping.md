# dbo.AddCurrencyBalancesProvidersMapping

> Upsert procedure linking internal currency balance IDs to provider-side (Tribe) balance identifiers.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into CurrencyBalancesProvidersMapping, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddCurrencyBalancesProvidersMapping creates or retrieves the mapping between an internal currency balance and its Tribe provider identifier. Deduplicates on CurrencyBalanceId with UPDLOCK/HOLDLOCK.

---

## 2. Business Logic

### 2.1 Idempotent Provider Mapping

**Rules**: Transaction with UPDLOCK/HOLDLOCK. Returns existing Id if CurrencyBalanceId already mapped.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. |
| 2 | @ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers (1=Tribe). |
| 3 | @CurrencyBalanceProviderId | nvarchar(128) | NO | - | CODE-BACKED | Tribe's identifier. |
| 4 | @Created | datetime2(7) | NO | - | CODE-BACKED | Event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.CurrencyBalancesProvidersMapping | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddCurrencyBalancesProvidersMapping (procedure)
└── dbo.CurrencyBalancesProvidersMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.CurrencyBalancesProvidersMapping | Table | Upsert target |

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
EXEC dbo.AddCurrencyBalancesProvidersMapping @CurrencyBalanceId = 2135699,
    @ProviderId = 1, @CurrencyBalanceProviderId = 'TRIBE-BAL-5678', @Created = SYSUTCDATETIME();
```

### 8.2 Verify
```sql
SELECT * FROM dbo.CurrencyBalancesProvidersMapping WITH (NOLOCK) WHERE CurrencyBalanceId = 2135699;
```

### 8.3 Resolve to account
```sql
SELECT a.Gcid, m.CurrencyBalanceProviderId
FROM dbo.CurrencyBalancesProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.Id = m.CurrencyBalanceId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = cb.AccountId
WHERE m.CurrencyBalanceId = 2135699;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddCurrencyBalancesProvidersMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddCurrencyBalancesProvidersMapping.sql*
