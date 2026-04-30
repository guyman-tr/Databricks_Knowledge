# dbo.AddTransactionsProvidersMapping

> Upsert procedure linking a transaction to its provider-side (Tribe) transaction identifier.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into TransactionsProvidersMapping, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddTransactionsProvidersMapping creates or retrieves the provider mapping for a transaction. Deduplicates on TransactionId with UPDLOCK/HOLDLOCK. Same pattern as Cards/CurrencyBalances provider mapping procedures.

---

## 2. Business Logic

### 2.1 Idempotent Transaction-Provider Mapping

**Rules**: Dedup on TransactionId. Returns existing Id if already mapped.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TransactionId | bigint | NO | - | CODE-BACKED | FK to FiatTransactions.Id. |
| 2 | @ProviderId | tinyint | NO | - | CODE-BACKED | FK to Dictionary.Providers (1=Tribe). |
| 3 | @TransactionProviderId | nvarchar(128) | NO | - | CODE-BACKED | Tribe's transaction identifier. |
| 4 | @Created | datetime2(7) | NO | - | CODE-BACKED | Event timestamp. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.TransactionsProvidersMapping | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddTransactionsProvidersMapping (procedure)
└── dbo.TransactionsProvidersMapping (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.TransactionsProvidersMapping | Table | Upsert target |

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
EXEC dbo.AddTransactionsProvidersMapping @TransactionId = 28513721,
    @ProviderId = 1, @TransactionProviderId = 'TRIBE-TXN-999', @Created = SYSUTCDATETIME();
```

### 8.2 Verify
```sql
SELECT * FROM dbo.TransactionsProvidersMapping WITH (NOLOCK) WHERE TransactionId = 28513721;
```

### 8.3 Resolve to account
```sql
SELECT a.Gcid, m.TransactionProviderId
FROM dbo.TransactionsProvidersMapping m WITH (NOLOCK)
JOIN dbo.FiatTransactions t WITH (NOLOCK) ON t.Id = m.TransactionId
JOIN dbo.FiatAccount a WITH (NOLOCK) ON a.Id = t.AccountId
WHERE m.TransactionId = 28513721;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddTransactionsProvidersMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddTransactionsProvidersMapping.sql*
