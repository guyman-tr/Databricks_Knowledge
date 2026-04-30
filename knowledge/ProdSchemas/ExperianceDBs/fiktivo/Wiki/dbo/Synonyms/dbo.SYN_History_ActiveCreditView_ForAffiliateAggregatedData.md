# dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData

> Synonym pointing to [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView], providing local access to the active credit view in the History schema for affiliate aggregation without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData is a synonym that provides a local reference to [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the RealForAffiliateAggregatedData linked server under the History schema. Based on the name, ActiveCreditView is a view that exposes currently active (outstanding) credit balances in customer accounts. In the trading context, credit refers to bonus or promotional funds loaded into customer accounts. This view feeds affiliate aggregation processes to assess active promotional credit exposure per affiliate's customer base, which is relevant for net revenue and chargeback calculations.

Note: dbo.etoro_HistoryCreditView is a separate synonym that also points to [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView] -- a different source server but the same logical object name.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView] | Synonym | Points to the active credit view for affiliate aggregation |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData (synonym)
  +-- [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView] (view on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [RealForAffiliateAggregatedData].[etoro].[History].[ActiveCreditView] | View | Synonym target |

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
SELECT TOP 5 * FROM dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'SYN_History_ActiveCreditView_ForAffiliateAggregatedData'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData.sql*
