# dbo.etoro_HistoryCreditView

> Synonym pointing to [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView], providing local access to the active credit view via the AO-REAL-DB-ROR linked server without cross-database references.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

dbo.etoro_HistoryCreditView is a synonym that provides a local reference to [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView]. This allows stored procedures and views in the fiktivo.dbo schema to reference the target object using a short name without embedding cross-database or cross-server paths in their code.

The target object resides in the AO-REAL-DB-ROR linked server (a read-only replica of the etoro real-accounts production database) under the History schema. Based on the name, History.ActiveCreditView is a view that surfaces currently active credit balances -- the same logical data as dbo.etoro_HistoryActiveCredit but presented as a view (likely with additional joins or computed columns for ease of consumption). 

Note: dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData is a parallel synonym pointing to the same logical object name (History.ActiveCreditView) but via the RealForAffiliateAggregatedData linked server. The two synonyms allow different parts of the system to consume active credit view data from their respective server connections.

---

## 2. Business Logic

No business logic. This is a name alias.

---

## 3. Data Overview

N/A for synonym. Data resides in the target object: [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView].

---

## 4. Elements

N/A for synonym. See target object documentation.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym target) | [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView] | Synonym | Points to the active credit view on the AO-REAL-DB-ROR linked server |

### 5.2 Referenced By (other objects point to this)

See consuming views and procedures in this schema. Also note that dbo.SYN_History_ActiveCreditView_ForAffiliateAggregatedData is a parallel synonym for the same logical view via a different server.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
dbo.etoro_HistoryCreditView (synonym)
  +-- [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView] (view on linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [AO-REAL-DB-ROR].[etoro].[History].[ActiveCreditView] | View | Synonym target |

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
SELECT TOP 5 * FROM dbo.etoro_HistoryCreditView WITH (NOLOCK)
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'etoro_HistoryCreditView'
```

### 8.3 Check if target is accessible
```sql
SELECT COUNT(*) FROM dbo.etoro_HistoryCreditView WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Quality: 7.4/10*
*Object: dbo.etoro_HistoryCreditView | Type: Synonym | Source: fiktivo/dbo/Synonyms/dbo.etoro_HistoryCreditView.sql*
