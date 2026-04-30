# dbo.AddAccountsProviderHoldersMapping

> Upsert procedure that links an internal account to its provider-side (Tribe) holder ID, returning the existing or new mapping ID.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Upsert into AccountsProviderHoldersMapping, returns Results (ID) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

AddAccountsProviderHoldersMapping creates or retrieves the mapping between an internal FiatAccount and the provider's (Tribe) holder identifier. It uses a transaction with upsert logic: if a mapping already exists for the AccountId, it returns the existing ID; otherwise it inserts a new mapping and returns the new ID via SCOPE_IDENTITY().

This idempotent pattern ensures the same AccountId is never mapped twice, which is critical for data consistency between the platform and provider.

---

## 2. Business Logic

### 2.1 Idempotent Upsert Pattern

**What**: Check-then-insert pattern ensuring exactly one mapping per account.

**Columns/Parameters Involved**: `@AccountId`, `@ProviderHolderId`

**Rules**:
- Wraps logic in a TRANSACTION for atomicity
- If a mapping for @AccountId already exists, returns existing Id (no insert)
- If no mapping exists, INSERT and return SCOPE_IDENTITY()
- Returns result as `Results` column

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @AccountId | bigint | NO | - | CODE-BACKED | FK to dbo.FiatAccount.Id. The account to map. |
| 2 | @ProviderHolderId | nvarchar(128) | NO | - | CODE-BACKED | Tribe's holder identifier for this account. |
| 3 | @Created | datetime2(7) | NO | - | CODE-BACKED | Timestamp of the mapping event. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| INSERT/SELECT | dbo.AccountsProviderHoldersMapping | Read/Write | Upsert target |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.AddAccountsProviderHoldersMapping (procedure)
└── dbo.AccountsProviderHoldersMapping (table)
    └── dbo.FiatAccount (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountsProviderHoldersMapping | Table | Upsert target |

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

### 8.1 Call the procedure
```sql
EXEC dbo.AddAccountsProviderHoldersMapping @AccountId = 2135575, @ProviderHolderId = '16588734', @Created = '2026-04-14T13:51:23';
```

### 8.2 Verify the mapping
```sql
SELECT * FROM dbo.AccountsProviderHoldersMapping WITH (NOLOCK) WHERE AccountId = 2135575;
```

### 8.3 Test idempotency (second call returns same ID)
```sql
EXEC dbo.AddAccountsProviderHoldersMapping @AccountId = 2135575, @ProviderHolderId = '16588734', @Created = '2026-04-14T14:00:00';
-- Should return same Results as first call
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-14 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 10/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.AddAccountsProviderHoldersMapping | Type: Stored Procedure | Source: FiatDwhDB/dbo/Stored Procedures/dbo.AddAccountsProviderHoldersMapping.sql*
