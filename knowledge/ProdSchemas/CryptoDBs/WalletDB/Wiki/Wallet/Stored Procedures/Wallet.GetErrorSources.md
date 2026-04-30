# Wallet.GetErrorSources

> Returns all error source definitions from the Dictionary, providing the lookup table for categorizing where transaction errors originate.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Dictionary.ErrorSources rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete list of error source categories. Error sources classify where transaction errors originate (e.g., blockchain provider, internal service, AML provider). Used by the error monitoring and reporting system to categorize failures.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table SELECT.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Error source ID. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Error source name (e.g., "BlockchainProvider", "InternalService"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.ErrorSources | Reader | Source of error source definitions |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetErrorSources (procedure)
  └── Dictionary.ErrorSources (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.ErrorSources | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Get all error sources
```sql
EXEC Wallet.GetErrorSources
```

### 8.2 Direct query
```sql
SELECT Id, Name FROM Dictionary.ErrorSources WITH (NOLOCK)
```

### 8.3 Error sources in use
```sql
SELECT Id, Name FROM Dictionary.ErrorSources WITH (NOLOCK) ORDER BY Id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetErrorSources | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetErrorSources.sql*
