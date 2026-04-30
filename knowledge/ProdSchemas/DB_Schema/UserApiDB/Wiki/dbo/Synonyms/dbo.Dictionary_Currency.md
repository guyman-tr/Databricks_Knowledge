# dbo.Dictionary_Currency

> Synonym pointing to [etoro].[Dictionary].[Currency]. Cross-database pointer.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Target** | [etoro].[Dictionary].[Currency] |
| **Category** | Cross-database pointer |

---

## 1. Business Meaning

dbo.Dictionary_Currency is a database synonym that provides a local alias for [etoro].[Dictionary].[Currency]. This enables stored procedures and views in UserApiDB to reference external objects without hardcoding the full four-part name, simplifying cross-database queries and enabling environment-specific configuration.

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
| - | [etoro].[Dictionary].[Currency] | Synonym target | External object this points to |

### 5.2 Referenced By (other objects point to this)

Referenced by UserApiDB procedures and views that need cross-database access.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.Dictionary_Currency (synonym)
  +-- [etoro].[Dictionary].[Currency] (external)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [etoro].[Dictionary].[Currency] | External | Synonym target |

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
SELECT TOP 10 * FROM Dictionary_Currency WITH (NOLOCK)
```

### 8.2 Check synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'Dictionary_Currency'
```

### 8.3 Verify synonym resolves
```sql
SELECT OBJECT_ID('dbo.Dictionary_Currency') AS ObjectID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 2/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Object: dbo.Dictionary_Currency | Type: Synonym | Source: UserApiDB/UserApiDB/dbo/Synonyms/dbo.Dictionary_Currency.sql*
