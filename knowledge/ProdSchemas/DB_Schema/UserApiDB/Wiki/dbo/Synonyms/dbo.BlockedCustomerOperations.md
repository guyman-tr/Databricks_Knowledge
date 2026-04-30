# dbo.BlockedCustomerOperations

> Synonym pointing to [etoro].[Customer].[BlockedCustomerOperations]. Cross-database pointer.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Target** | [etoro].[Customer].[BlockedCustomerOperations] |
| **Category** | Cross-database pointer |

---

## 1. Business Meaning

dbo.BlockedCustomerOperations is a database synonym that provides a local alias for [etoro].[Customer].[BlockedCustomerOperations]. This enables stored procedures and views in UserApiDB to reference external objects without hardcoding the full four-part name, simplifying cross-database queries and enabling environment-specific configuration.

---

## 2. Business Logic

No business logic. Pure pointer/alias to external object.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

N/A for synonym. See target object for structure.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | [etoro].[Customer].[BlockedCustomerOperations] | Synonym target | External object this points to |

### 5.2 Referenced By (other objects point to this)

Referenced by UserApiDB procedures and views that need cross-database access.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.BlockedCustomerOperations (synonym)
  +-- [etoro].[Customer].[BlockedCustomerOperations] (external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [etoro].[Customer].[BlockedCustomerOperations] | External | Synonym target |

### 6.2 Objects That Depend On This

Various UserApiDB procedures reference this synonym.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Use the synonym
```sql
SELECT TOP 10 * FROM BlockedCustomerOperations WITH (NOLOCK)
```

### 8.2 Check synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'BlockedCustomerOperations'
```

### 8.3 Verify synonym resolves
```sql
SELECT OBJECT_ID('dbo.BlockedCustomerOperations') AS ObjectID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: dbo.BlockedCustomerOperations | Type: Synonym | Source: UserApiDB/UserApiDB/dbo/Synonyms/dbo.BlockedCustomerOperations.sql*
