# dbo.SYN_Trade_PositionForExternalUse

> Synonym pointing to [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse], providing local access to the external-use active trading positions view without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.SYN_Trade_PositionForExternalUse is a synonym that provides a local reference to [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the RealForAffiliateAggregatedData linked server under the Trade schema. Based on the name, Trade.PositionForExternalUse is the Trade-schema equivalent of the History.PositionForExternalUse -- a curated, filtered view of the live (open) trading position table prepared for external consumer use. While History objects contain closed positions, Trade schema objects contain currently open positions. This view provides affiliate and reporting systems with current open position data in a safe, external-use format.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse] | Synonym | Points to the external-use open trading positions view in the Trade schema |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.SYN_Trade_PositionForExternalUse (synonym)
  +-- [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse] (view/table on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [RealForAffiliateAggregatedData].[etoro].[Trade].[PositionForExternalUse] | View or Table | Synonym target |

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
SELECT TOP 5 * FROM dbo.SYN_Trade_PositionForExternalUse WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'SYN_Trade_PositionForExternalUse'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.SYN_Trade_PositionForExternalUse WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.SYN_Trade_PositionForExternalUse | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.SYN_Trade_PositionForExternalUse.sql*
