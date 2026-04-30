# dbo.TransactionsProvidersMapping

> Mapping table linking internal transaction IDs to provider-side (Tribe) transaction identifiers for cross-system reconciliation and support investigations.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

TransactionsProvidersMapping links each internal financial transaction (dbo.FiatTransactions) to its identifier in the external provider system (Tribe). This mapping is essential for support investigations (matching customer-reported issues to provider records) and transaction reconciliation.

Data is created by dbo.AddTransactionsProvidersMapping. Confluence documents provider transaction IDs as a key lookup in FiatCustodianDB queries.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Straightforward ID mapping table following the same pattern as Cards/CurrencyBalances/PaymentSpecifications provider mappings.

---

## 3. Data Overview

N/A - mapping data.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate PK. |
| 2 | TransactionId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatTransactions.Id. The internal transaction being mapped. |
| 3 | ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers. Currently 1=Tribe. See [Provider](../../_glossary.md#provider). |
| 4 | TransactionProviderId | nvarchar(128) | NO | - | CODE-BACKED | The provider's identifier for this transaction. Used for provider API calls, reconciliation, and support lookups. |
| 5 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this mapping was recorded. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TransactionId | dbo.FiatTransactions | FK | Internal transaction |
| ProviderId | Dictionary.Providers | FK | External provider |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AddTransactionsProvidersMapping | INSERT | Writer | Creates mappings |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.TransactionsProvidersMapping (table)
└── dbo.FiatTransactions (table)
    ├── dbo.FiatAccount (table)
    ├── dbo.FiatCards (table)
    ├── dbo.FiatCurrencyBalances (table)
    ├── dbo.FiatBankAccount (table)
    └── dbo.FiatMerchants (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | FK from TransactionId |
| Dictionary.Providers | Table | FK from ProviderId |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AddTransactionsProvidersMapping | Stored Procedure | Writes mappings |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_TransactionsProvidersMapping | CLUSTERED | Id ASC | - | - | Active |
| IX_TransactionsProvidersMapping_Created | NONCLUSTERED | Created ASC | - | - | Active |
| ix_TransactionsProvidersMapping_TransactionId | NONCLUSTERED | TransactionId ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| FK_TransactionsProvidersMapping_Transactions | FK | TransactionId -> dbo.FiatTransactions.Id |
| FK_TransactionsProvidersMapping_Providers | FK | ProviderId -> Dictionary.Providers.Id |

---

## 8. Sample Queries

### 8.1 Find Tribe transaction ID
```sql
SELECT TransactionProviderId FROM dbo.TransactionsProvidersMapping WITH (NOLOCK)
WHERE TransactionId = 28513721;
```

### 8.2 Resolve provider transaction to account
```sql
SELECT a.Gcid, t.TransactionGuid, m.TransactionProviderId
FROM dbo.TransactionsProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatTransactions t WITH (NOLOCK) ON t.Id = m.TransactionId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = t.AccountId
WHERE m.TransactionProviderId = '12345';
```

### 8.3 Count transactions per provider per day
```sql
SELECT CAST(m.Created AS DATE) AS MappingDate, p.Name, COUNT(*) AS TxnCount
FROM dbo.TransactionsProvidersMapping m WITH (NOLOCK)
JOIN Dictionary.Providers p WITH (NOLOCK) ON p.Id = m.ProviderId
WHERE m.Created >= DATEADD(DAY, -7, GETUTCDATE())
GROUP BY CAST(m.Created AS DATE), p.Name
ORDER BY MappingDate DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Important DB Queries](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290274878) | Confluence | Provider transaction ID (ProviderTransactionId) is used in FiatCustodianDB transaction queries with LEFT JOIN pattern |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.TransactionsProvidersMapping | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.TransactionsProvidersMapping.sql*
