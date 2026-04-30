# Wallet.GetEtoroLegalEntites

> Returns all eToro legal entities from the Dictionary, providing the list of regulated entities under which crypto wallet services operate.

| Property | Value |
|----------|-------|
| **Schema** | Wallet |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns all Dictionary.EtoroLegalEntities rows |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure returns the complete list of eToro legal entities. eToro operates under multiple regulated entities across jurisdictions (e.g., eToro USA LLC, eToro (Europe) Ltd, eToro (UK) Ltd). Each entity has its own regulatory requirements, licensing, and compliance rules that affect wallet operations, limits, and available cryptocurrencies.

Without this procedure, the application could not determine which legal entity a customer belongs to, preventing proper jurisdiction-based compliance enforcement.

Note: The procedure name has a typo ("Entites" instead of "Entities") - this is intentional to match the existing naming.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Simple full-table SELECT from Dictionary.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | Id | int | NO | - | CODE-BACKED | Legal entity ID. |
| 2 | Name | varchar | NO | - | CODE-BACKED | Internal name of the legal entity (e.g., "eToroUSA", "eToroEurope"). |
| 3 | DisplayName | varchar | NO | - | CODE-BACKED | Human-readable name (e.g., "eToro USA LLC", "eToro (Europe) Ltd"). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Dictionary.EtoroLegalEntities | Reader | Source of legal entity data |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Wallet.GetEtoroLegalEntites (procedure)
  └── Dictionary.EtoroLegalEntities (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.EtoroLegalEntities | Table | SELECT source |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

- NOLOCK hint, SET NOCOUNT ON

---

## 8. Sample Queries

### 8.1 Get all legal entities
```sql
EXEC Wallet.GetEtoroLegalEntites
```

### 8.2 Direct query
```sql
SELECT Id, Name, DisplayName FROM Dictionary.EtoroLegalEntities WITH (NOLOCK)
```

### 8.3 Find entity by name
```sql
SELECT * FROM Dictionary.EtoroLegalEntities WITH (NOLOCK) WHERE Name LIKE '%USA%'
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-15 | Enriched: - | Quality: 8.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Wallet.GetEtoroLegalEntites | Type: Stored Procedure | Source: WalletDB/Wallet/Stored Procedures/Wallet.GetEtoroLegalEntites.sql*
