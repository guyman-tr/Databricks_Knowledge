# Wallet.GetDefinedLimitationConfigurations

> Returns all active limitation definition JSON configurations, excluding deprecated erc20Wave1 category entries, for loading the current limit rules into the application cache.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns distinct active DefinitionJson values |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure retrieves all active transaction limitation configurations. Each limitation is stored as a JSON document defining the classification, type, target, specifications, and attributes of the limit rule. The application loads these at startup or cache refresh to enforce withdrawal limits, send caps, and other transaction restrictions.

Without this procedure, the application could not load the current limit rules, effectively disabling all transaction limiting, which is a critical compliance and risk management control.

The procedure filters out deprecated "erc20Wave1" category entries and returns distinct JSON documents to avoid duplicates.

---

## 2. Business Logic

### 2.1 Deprecated Category Exclusion

**What**: Filters out erc20Wave1 entries that are no longer used.

**Columns/Parameters Involved**: DefinitionJson, JSON_VALUE path $.Specifications.CryptoCategoryName

**Rules**:
- Uses JSON_VALUE to extract CryptoCategoryName from the JSON
- ISNULL wrapper treats NULL categories as empty string
- Excludes entries where CryptoCategoryName = 'erc20Wave1'
- Only returns IsActive = 1 entries

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DefinitionJson | nvarchar(MAX) | NO | - | CODE-BACKED | Complete JSON limitation definition containing Definitions (Classification, Type, Target), Specifications (TransactionType, Scope, CryptoId, CryptoCategoryName, Action), and Attributes (TimePeriodInMinutes, thresholds). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.LimitationsDefinitions | Reader | Source of limitation configs |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetDefinedLimitationConfigurations (procedure)
  └── Wallet.LimitationsDefinitions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON
- SELECT DISTINCT to deduplicate
- JSON_VALUE for category filtering

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetDefinedLimitationConfigurations
```

### 8.2 Count active limitation definitions
```sql
SELECT COUNT(*) FROM Wallet.LimitationsDefinitions WITH (NOLOCK) WHERE IsActive = 1
```

### 8.3 View limitations by category
```sql
SELECT ISNULL(JSON_VALUE(DefinitionJson, '$.Specifications.CryptoCategoryName'), 'General') AS Category, COUNT(*) AS Cnt
FROM Wallet.LimitationsDefinitions WITH (NOLOCK)
WHERE IsActive = 1
GROUP BY JSON_VALUE(DefinitionJson, '$.Specifications.CryptoCategoryName')
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetDefinedLimitationConfigurations | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetDefinedLimitationConfigurations.sql*
