# dbo.FiatMerchants

> Stores merchant descriptions from card transactions, providing a lookup for merchant identification in transaction reporting.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | Id (BIGINT, IDENTITY, CLUSTERED) |
| **Partition** | No |
| **Indexes** | 2 active (+ PK) |

---

## 1. Business Meaning

FiatMerchants is a lookup/reference table that stores merchant descriptions extracted from card transactions. Each record represents a unique merchant (or merchant description string) that has appeared in transaction processing. Merchants include retail stores, online shops, ATM locations, and any entity that accepts card payments.

This table exists because the fiat platform needs to display meaningful merchant information to customers in their transaction history. When a card transaction is processed by the provider (Tribe), it includes a merchant description string. This table normalizes those descriptions so multiple transactions at the same merchant can reference a single merchant record.

Data is created by the dbo.AddFiatMerchants stored procedure when a new merchant description appears in transaction processing. The merchant's Id is then referenced by dbo.FiatTransactions.MerchantId to link transactions to their merchants.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a simple lookup table with auto-generated IDs and merchant descriptions.

---

## 3. Data Overview

| Id | Description | Created | Meaning |
|---|---|---|---|
| 2365365 | JOHN DAVIDSONS ONLINE HTTPS://WWW.JGB | 2026-04-14 | Online merchant - web store purchase |
| 2365364 | BOUCH ISTANBUL RENNES FR | 2026-04-14 | Physical merchant in Rennes, France - in-store card payment |
| 2365363 | Youssef Semati | 2026-04-14 | Person-to-person or small business payment |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Auto-incrementing surrogate primary key. Referenced by dbo.FiatTransactions.MerchantId. |
| 2 | Description | nvarchar(256) | YES | - | CODE-BACKED | Merchant description string from the payment network. Contains the merchant name and sometimes location/URL. Format varies by payment processor and merchant. Indexed for lookup queries. |
| 3 | Created | datetime2(7) | NO | - | CODE-BACKED | UTC timestamp when this merchant record was first created in the data warehouse. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.FiatTransactions | MerchantId | FK | Transactions reference their merchant for display and reporting |
| dbo.AddFiatMerchants | INSERT | Writer | Creates new merchant records from transaction processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.FiatTransactions | Table | FK from MerchantId |
| dbo.AddFiatMerchants | Stored Procedure | Inserts new merchant records |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_FiatMerchants | CLUSTERED | Id ASC | - | - | Active |
| IX_FiatMerchants_Created | NONCLUSTERED | Created ASC | - | - | Active |
| ix_FiatMerchants_Description | NONCLUSTERED | Description ASC | - | - | Active |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Find a merchant by description
```sql
SELECT Id, Description, Created
FROM dbo.FiatMerchants WITH (NOLOCK)
WHERE Description LIKE '%AMAZON%'
ORDER BY Created DESC;
```

### 8.2 Get recent merchants
```sql
SELECT TOP 20 Id, Description, Created
FROM dbo.FiatMerchants WITH (NOLOCK)
ORDER BY Created DESC;
```

### 8.3 Join transactions with merchant details
```sql
SELECT t.Id AS TransactionId, t.TransactionGuid, m.Description AS MerchantName, t.Created
FROM dbo.FiatTransactions t WITH (NOLOCK)
JOIN dbo.FiatMerchants m WITH (NOLOCK) ON m.Id = t.MerchantId
WHERE t.Created >= DATEADD(DAY, -1, GETUTCDATE())
ORDER BY t.Created DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Banking Database](https://etoro-jira.atlassian.net/wiki/spaces/~935552433/pages/13290242096) | Confluence | FiatDwhDB stores reporting data including transaction details |

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 8/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.FiatMerchants | Type: Table | Source: FiatDwhDB/dbo/Tables/dbo.FiatMerchants.sql*
