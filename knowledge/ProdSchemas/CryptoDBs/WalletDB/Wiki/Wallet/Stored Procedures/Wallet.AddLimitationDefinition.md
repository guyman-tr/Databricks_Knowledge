# Wallet.AddLimitationDefinition

> Parses a JSON limitation definition and inserts a new withdrawal/transaction limit configuration by resolving all classification, type, target, scope, and action dimensions from Dictionary lookup tables.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | New row in Wallet.LimitationsDefinitions |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure creates a new transaction limitation rule in the system. Limitations control how much cryptocurrency a customer can withdraw, send, or convert within a given time period. Each limitation is defined along multiple dimensions: classification (what category), type (what kind of limit), target (who is limited), transaction type (what operation), scope (time window), and action (what happens when exceeded).

Without this procedure, the operations team could not configure or update withdrawal limits, daily/monthly send caps, or per-crypto transaction restrictions. These limits are critical for regulatory compliance, risk management, and fraud prevention.

The procedure accepts a JSON definition string, parses it using OPENJSON, resolves all dimension names to their Dictionary IDs via JOINs to six Dictionary tables, and inserts a new row only if no matching configuration already exists (idempotent insert).

---

## 2. Business Logic

### 2.1 JSON-Driven Multi-Dimensional Limit Configuration

**What**: A single JSON document defines all dimensions of a limitation rule, which are resolved against Dictionary lookup tables.

**Columns/Parameters Involved**: `@DefinitionJson`, all Dictionary JOINs

**Rules**:
- JSON structure has nested paths: `$.Definitions.Classification`, `$.Definitions.Type`, `$.Definitions.Target`, `$.Specifications.TransactionType`, `$.Specifications.Scope`, `$.Specifications.Action`
- Each dimension name is resolved to its ID via Dictionary tables (LimitClassifications, LimitTypes, LimitTargets, TransactionTypes, LimitScopes, LimitActions)
- Optional crypto-specific fields: `$.Specifications.CryptoId` and `$.Specifications.CryptoCategoryName` allow per-crypto or per-category limits
- Attributes JSON (including TimePeriodInMinutes) is extracted but stored as part of the parent DefinitionJson

### 2.2 Duplicate Prevention

**What**: Prevents creating identical limitation configurations.

**Columns/Parameters Involved**: All dimension IDs + CryptoId + CryptoCategoryName

**Rules**:
- LEFT JOINs to existing LimitationsDefinitions matching all dimension IDs, CryptoId, CryptoCategoryName, ScopeId, and ActionId
- Only inserts where no matching row exists (ld.Id IS NULL)
- Uses ISNULL for nullable CryptoId and CryptoCategoryName comparisons

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DefinitionJson | nvarchar(MAX) | NO | - | CODE-BACKED | JSON document defining the limitation rule. Contains nested Definitions (Classification, Type, Target), Specifications (TransactionType, Scope, CryptoId, CryptoCategoryName, Action), and Attributes (TimePeriodInMinutes, thresholds). Parsed via OPENJSON. |
| 2 | @LastChangedBy | nvarchar(100) | NO | - | CODE-BACKED | Username or identifier of the person/system creating this limitation. Stored for audit trail in LimitationsDefinitions.LastChangedBy. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Classification | Dictionary.LimitClassifications | JOIN lookup | Resolves classification name to ID |
| Type | Dictionary.LimitTypes | JOIN lookup | Resolves limit type name to ID |
| Target | Dictionary.LimitTargets | JOIN lookup | Resolves target name to ID |
| TransactionType | Dictionary.TransactionTypes | JOIN lookup | Resolves transaction type name to ID |
| Scope | Dictionary.LimitScopes | JOIN lookup | Resolves scope name to ID |
| Action | Dictionary.LimitActions | JOIN lookup | Resolves action name to ID |
| INSERT target | Wallet.LimitationsDefinitions | Writer | Inserts new limit configuration |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase. Called by application admin services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.AddLimitationDefinition (procedure)
  ├── Wallet.LimitationsDefinitions (table)
  ├── Dictionary.LimitClassifications (table)
  ├── Dictionary.LimitTypes (table)
  ├── Dictionary.LimitTargets (table)
  ├── Dictionary.TransactionTypes (table)
  ├── Dictionary.LimitScopes (table)
  └── Dictionary.LimitActions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | INSERT target + duplicate check |
| Dictionary.LimitClassifications | Table | JOIN to resolve classification name |
| Dictionary.LimitTypes | Table | JOIN to resolve type name |
| Dictionary.LimitTargets | Table | JOIN to resolve target name |
| Dictionary.TransactionTypes | Table | JOIN to resolve transaction type name |
| Dictionary.LimitScopes | Table | JOIN to resolve scope name |
| Dictionary.LimitActions | Table | JOIN to resolve action name |

### 6.2 Objects That Depend On This

No dependents found in SQL codebase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- Uses OPENJSON to parse the input JSON
- All six Dictionary JOINs are INNER JOINs - if any dimension name is invalid, the INSERT produces zero rows (silent failure)
- ISNULL comparisons on CryptoId and CryptoCategoryName handle NULL-to-NULL matching

---

## 8. Sample Queries

### 8.1 View all active limitation definitions with resolved names
```sql
SELECT ld.Id, lc.Name AS Classification, lt.Name AS LimitType, lt1.Name AS Target,
       tt.Name AS TransactionType, ls.Name AS Scope, la.Name AS Action,
       ld.CryptoId, ld.CryptoCategoryName, ld.LastChangedBy, ld.LastChanged
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitClassifications lc WITH (NOLOCK) ON lc.Id = ld.LimitClassificationId
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON lt.Id = ld.LimitTypeId
JOIN Dictionary.LimitTargets lt1 WITH (NOLOCK) ON lt1.Id = ld.LimitTargetId
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = ld.TransactionTypeId
JOIN Dictionary.LimitScopes ls WITH (NOLOCK) ON ls.Id = ld.LimitScopeId
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON la.Id = ld.LimitActionId
WHERE ld.IsActive = 1
ORDER BY ld.LastChanged DESC
```

### 8.2 Find limitations for a specific crypto
```sql
SELECT ld.Id, ld.DefinitionJson, ld.CryptoId, ld.LastChangedBy
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
WHERE ld.CryptoId = 1 AND ld.IsActive = 1
```

### 8.3 Check available dimension values
```sql
SELECT 'Classification' AS Dimension, Name, Id FROM Dictionary.LimitClassifications WITH (NOLOCK)
UNION ALL
SELECT 'Type', Name, Id FROM Dictionary.LimitTypes WITH (NOLOCK)
UNION ALL
SELECT 'Target', Name, Id FROM Dictionary.LimitTargets WITH (NOLOCK)
UNION ALL
SELECT 'Scope', Name, Id FROM Dictionary.LimitScopes WITH (NOLOCK)
UNION ALL
SELECT 'Action', Name, Id FROM Dictionary.LimitActions WITH (NOLOCK)
ORDER BY Dimension, Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 9.0/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.AddLimitationDefinition | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.AddLimitationDefinition.sql*
