# dbo.CurrencyBalancesProvidersMapping

> Mapping table linking internal currency balance IDs to provider-side (Tribe) balance identifiers for cross-system reconciliation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

CurrencyBalancesProvidersMapping links each internal currency balance (dbo.FiatCurrencyBalances) to its identifier in the external provider system (Tribe). This mapping is essential for balance reconciliation (BalanceReports) and provider API interactions.

Data is created by dbo.AddCurrencyBalancesProvidersMapping when a currency balance is provisioned with the provider.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Straightforward ID mapping table, same pattern as CardsProvidersMapping and TransactionsProvidersMapping.

---

## 3. Data Overview

N/A - mapping data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. |
| 2 | CurrencyBalanceId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatCurrencyBalances.Id. The internal currency balance being mapped. |
| 3 | ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers. Currently 1=Tribe. See [Provider](../../_glossary.md#provider). |
| 4 | CurrencyBalanceProviderId | nvarchar(128) | NO | - | CODE-BACKED | The provider's identifier for this currency balance. Used for provider API calls and reconciliation. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CurrencyBalanceId | dbo.FiatCurrencyBalances | FK | Internal currency balance |
| ProviderId | Dictionary.Providers | FK | External provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddCurrencyBalancesProvidersMapping | INSERT | Writer | Creates mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.CurrencyBalancesProvidersMapping (table)
└── dbo.FiatCurrencyBalances (table)
    ├── dbo.FiatAccount (table)
    └── dbo.FiatBankAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatCurrencyBalances | Table | FK from CurrencyBalanceId |
| Dictionary.Providers | Table | FK from ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddCurrencyBalancesProvidersMapping | Stored Procedure | Inserts mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_CurrencyBalancesProvidersMapping | CLUSTERED | Id ASC | - | - | Active |
| IX_CurrencyBalancesProvidersMapping_Created | NONCLUSTERED | Created ASC | - | - | Active |
| nci_wi_CurrencyBalancesProvidersMapping_... | NONCLUSTERED | CurrencyBalanceId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_CurrencyBalancesProvidersMapping_CurrencyBalances | FK | CurrencyBalanceId -> dbo.FiatCurrencyBalances.Id |
| FK_CurrencyBalancesProvidersMapping_Providers | FK | ProviderId -> Dictionary.Providers.Id |

---

## 8. Sample Queries

### 8.1 Find Tribe balance ID for a currency balance
```sql
SELECT CurrencyBalanceProviderId FROM dbo.CurrencyBalancesProvidersMapping WITH (NOLOCK) WHERE CurrencyBalanceId = 2135699;
```

### 8.2 Resolve provider balance ID to account
```sql
SELECT a.Gcid, cb.CurrencyISON, m.CurrencyBalanceProviderId
FROM dbo.CurrencyBalancesProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatCurrencyBalances cb WITH (NOLOCK) ON cb.Id = m.CurrencyBalanceId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = cb.AccountId
WHERE m.CurrencyBalanceProviderId = '12345';
```

### 8.3 Count balances per provider
```sql
SELECT p.Name, COUNT(*) AS BalanceCount
FROM dbo.CurrencyBalancesProvidersMapping m WITH (NOLOCK)
JOIN Dictionary.Providers p WITH (NOLOCK) ON p.Id = m.ProviderId
GROUP BY p.Name;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.CurrencyBalancesProvidersMapping | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.CurrencyBalancesProvidersMapping.sql*
