# Wallet.GetLimitationsConfigurations

> Returns all active limitation/restriction definitions as enriched JSON, resolving ID-based configuration into named classifications, types, targets, scopes, and actions.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns DefinitionJson (JSON) for each active limitation |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure loads the complete set of active withdrawal/transaction limitation rules configured in the system. Limitations define restrictions on crypto operations - such as daily send limits, per-transaction maximums, or crypto-specific caps - used to enforce compliance, risk management, and business policies. Each limitation has a classification, type, target, transaction type, scope, and action that together define what is restricted, how, and what happens when the limit is exceeded.

The application's limitation engine calls this at startup or on configuration refresh to build its in-memory rule set. Without it, the platform would have no enforced limits on crypto transactions, exposing the system to unlimited withdrawal risk.

Data is sourced from `Wallet.LimitationsDefinitions` (the master configuration table) joined to six Dictionary tables that resolve IDs to human-readable names. The output is re-serialized as JSON using FOR JSON PATH, incorporating both resolved names and raw attributes from the original DefinitionJson column. Only active definitions (IsActive=1) are returned.

---

## 2. Business Logic

### 2.1 Limitation Rule Structure

**What**: Each limitation is a multi-dimensional rule combining classification, type, target, transaction type, scope, and action.

**Columns/Parameters Involved**: `LimitClassificationId`, `LimitTypeId`, `LimitTargetId`, `TransactionTypeId`, `LimitScopeId`, `LimitActionId`

**Rules**:
- Classification (Dictionary.LimitClassifications): Categorizes the limitation (e.g., regulatory, business, risk)
- Type (Dictionary.LimitTypes): The kind of limit (e.g., amount, count, frequency)
- Target (Dictionary.LimitTargets): What entity is limited (e.g., user, wallet, address)
- TransactionType (Dictionary.TransactionTypes): Which transaction types the limit applies to
- Scope (Dictionary.LimitScopes): Time or scope window (e.g., daily, monthly, per-transaction)
- Action (Dictionary.LimitActions): What happens when the limit is exceeded (e.g., block, alert, require approval)
- Only IsActive=1 definitions are included - inactive rules are ignored

### 2.2 JSON Output Structure

**What**: The output is a JSON document per limitation with named fields instead of raw IDs.

**Columns/Parameters Involved**: `DefinitionJson`, all Dictionary name columns

**Rules**:
- FOR JSON PATH, WITHOUT_ARRAY_WRAPPER produces one JSON object per row
- `Definitions.Classification`, `Definitions.Type`, `Definitions.Target` are resolved names from Dictionary tables
- `Specifications.TransactionType`, `Specifications.CryptoId`, `Specifications.CryptoCategoryName`, `Specifications.Scope`, `Specifications.Action` define the rule's applicability
- `Specifications.Operation` and `Specifications.Direction` are extracted from the raw DefinitionJson for backward compatibility
- `Attributes` is passed through as raw JSON from DefinitionJson (contains threshold values, amounts, etc.)
- `SpecDirection` is duplicated at root level from DefinitionJson
- DISTINCT eliminates any duplicate JSON strings from the re-serialization

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

This procedure has no input parameters.

### Return Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DefinitionJson | NVARCHAR(MAX) | YES | - | CODE-BACKED | Complete limitation rule as a JSON object. Contains: `Definitions.Classification` (limit category name), `Definitions.Type` (limit kind name), `Definitions.Target` (limited entity name), `Specifications.TransactionType` (applicable transaction type name), `Specifications.CryptoId` (applicable crypto or NULL for all), `Specifications.Operation` (legacy backward-compat field from raw JSON), `Specifications.Direction` (legacy backward-compat field), `Specifications.CryptoCategoryName` (crypto category or NULL), `Specifications.Scope` (time window name), `Specifications.Action` (enforcement action name), `Attributes` (raw JSON with threshold values), `SpecDirection` (direction duplicate). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Wallet.LimitationsDefinitions | FROM | Master table of limitation rules |
| LimitClassificationId | Dictionary.LimitClassifications | JOIN | Resolves classification ID to name |
| LimitTypeId | Dictionary.LimitTypes | JOIN | Resolves limit type ID to name |
| LimitTargetId | Dictionary.LimitTargets | JOIN | Resolves target ID to name |
| TransactionTypeId | Dictionary.TransactionTypes | JOIN | Resolves transaction type ID to name |
| LimitScopeId | Dictionary.LimitScopes | JOIN | Resolves scope ID to name |
| LimitActionId | Dictionary.LimitActions | JOIN | Resolves action ID to name |

### 5.2 Referenced By (other objects point to this)

No direct SQL callers found. Called by the application's limitation engine at startup to load the active rule set.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetLimitationsConfigurations (procedure)
+-- Wallet.LimitationsDefinitions (table)
+-- Dictionary.LimitClassifications (table)
+-- Dictionary.LimitTypes (table)
+-- Dictionary.LimitTargets (table)
+-- Dictionary.TransactionTypes (table)
+-- Dictionary.LimitScopes (table)
+-- Dictionary.LimitActions (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Wallet.LimitationsDefinitions | Table | FROM - master limitation configuration |
| Dictionary.LimitClassifications | Table | JOIN - classification name resolution |
| Dictionary.LimitTypes | Table | JOIN - limit type name resolution |
| Dictionary.LimitTargets | Table | JOIN - target name resolution |
| Dictionary.TransactionTypes | Table | JOIN - transaction type name resolution |
| Dictionary.LimitScopes | Table | JOIN - scope name resolution |
| Dictionary.LimitActions | Table | JOIN - action name resolution |

### 6.2 Objects That Depend On This

No dependents found in the SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure
```sql
EXEC Wallet.GetLimitationsConfigurations;
```

### 8.2 View active limitations with resolved names (without JSON)
```sql
SELECT ld.Id, lc.Name AS Classification, lt.Name AS LimitType, lt1.Name AS Target,
       tt.Name AS TransactionType, ld.CryptoId, ls.Name AS Scope, la.Name AS Action, ld.IsActive
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitClassifications lc WITH (NOLOCK) ON lc.Id = ld.LimitClassificationId
JOIN Dictionary.LimitTypes lt WITH (NOLOCK) ON lt.Id = ld.LimitTypeId
JOIN Dictionary.LimitTargets lt1 WITH (NOLOCK) ON lt1.Id = ld.LimitTargetId
JOIN Dictionary.TransactionTypes tt WITH (NOLOCK) ON tt.Id = ld.TransactionTypeId
JOIN Dictionary.LimitScopes ls WITH (NOLOCK) ON ls.Id = ld.LimitScopeId
JOIN Dictionary.LimitActions la WITH (NOLOCK) ON la.Id = ld.LimitActionId
WHERE ld.IsActive = 1
ORDER BY lc.Name, lt.Name;
```

### 8.3 Count active limitations by classification
```sql
SELECT lc.Name AS Classification, COUNT(*) AS RuleCount
FROM Wallet.LimitationsDefinitions ld WITH (NOLOCK)
JOIN Dictionary.LimitClassifications lc WITH (NOLOCK) ON lc.Id = ld.LimitClassificationId
WHERE ld.IsActive = 1
GROUP BY lc.Name
ORDER BY RuleCount DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: 2026-04-15 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetLimitationsConfigurations | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetLimitationsConfigurations.sql*
