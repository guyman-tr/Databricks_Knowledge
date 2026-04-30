# Trade.SynDividendPositionsSnapshot

> Synonym pointing to the DividendPositionsSnapshot table in the DividendsAzure database, enabling the Trade schema to access position snapshots taken at ex-dividend dates for dividend distribution calculations.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.SynDividendPositionsSnapshot is a synonym that provides local access to the DividendPositionsSnapshot table in the DividendsAzure database. This table stores point-in-time snapshots of open positions taken on ex-dividend dates. These snapshots determine which customers are entitled to dividend payments (or charges, for short/CFD positions) based on their holdings at the record time.

The synonym exists because dividend processing is handled in a dedicated Azure database (DividendsAzure) for isolation from the core trading system. The Trade schema may need to reference these snapshots for reconciliation, reporting, or audit purposes.

No direct consumers were found in the Trade schema's stored procedures. This synonym may be used by external processes, ad-hoc queries, or SSRS reports that need to correlate dividend snapshots with live trading data.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. Dividend calculation logic resides in the DividendsAzure database.

---

## 3. Data Overview

N/A for synonym (targets a table in an external database).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot]. A table storing position snapshots taken at ex-dividend dates, used to determine dividend entitlements for each customer's holdings. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] | Synonym target | Cross-database reference to dividend position snapshot data in the DividendsAzure database |

### 5.2 Referenced By (other objects point to this)

No consumers found in Trade schema stored procedures. May be used by external processes or ad-hoc queries.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SynDividendPositionsSnapshot (synonym)
  +-- [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

No dependents found in the Trade schema.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

N/A for synonym.

---

## 8. Sample Queries

### 8.1 Verify synonym target
```sql
SELECT name, base_object_name
FROM   sys.synonyms WITH (NOLOCK)
WHERE  name = 'SynDividendPositionsSnapshot'
       AND schema_id = SCHEMA_ID('Trade')
```

### 8.2 Check if synonym resolves
```sql
SELECT OBJECT_ID('Trade.SynDividendPositionsSnapshot') AS ObjectID
```

### 8.3 Preview dividend position snapshots (if accessible)
```sql
SELECT TOP 10 *
FROM   Trade.SynDividendPositionsSnapshot WITH (NOLOCK)
ORDER BY 1 DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SynDividendPositionsSnapshot | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.SynDividendPositionsSnapshot.sql*
