# dbo.SYN_History_PositionForExternalUse

> Synonym pointing to [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse], providing local access to the external-use closed position history view without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.SYN_History_PositionForExternalUse is a synonym that provides a local reference to [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the RealForAffiliateAggregatedData linked server under the History schema. Based on the name, PositionForExternalUse is a filtered or projected version of the closed position history that has been prepared for sharing with external consumers -- such as affiliate platforms, reporting systems, or third-party integrations. It likely exposes a curated set of columns from the full position history, omitting sensitive or internal fields while providing the data needed for affiliate performance reporting and commission calculation.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse] | Synonym | Points to the external-use closed position view in the History schema |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.SYN_History_PositionForExternalUse (synonym)
  +-- [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse] (view/table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [RealForAffiliateAggregatedData].[etoro].[History].[PositionForExternalUse] | View or Table | Synonym target |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes
N/A for synonym.

### 7.2 Constraints
N/A for synonym.

---

## 8. Sample Queries

### 8.1 Query through the synonym
```sql
SELECT TOP 5 * FROM dbo.SYN_History_PositionForExternalUse WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'SYN_History_PositionForExternalUse'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.SYN_History_PositionForExternalUse WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.SYN_History_PositionForExternalUse | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.SYN_History_PositionForExternalUse.sql*
