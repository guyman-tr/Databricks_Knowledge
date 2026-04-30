# Trade.DividendPositionsSnapshot

> Synonym pointing to the dividend positions snapshot table in the EtoroArchive database, used for historical dividend eligibility lookups.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [EtoroArchive].[Trade].[DividendPositionsSnapshot] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DividendPositionsSnapshot is a synonym providing local access to the DividendPositionsSnapshot table in the EtoroArchive database. This table stores point-in-time snapshots of trading positions taken at market close before ex-dividend dates, capturing which positions were held and their sizes at the moment that determines dividend entitlement.

The synonym exists because dividend eligibility requires knowing exactly what positions a customer held at the close of trading on the day before the ex-date. These snapshots are archived separately from the main trading database to keep the transactional database lean while preserving the historical records needed for dividend audit and reconciliation.

No direct consumers found in the current SSDT codebase - the synonym may be used by ad-hoc queries or external processes.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. This is a synonym - a transparent alias to an archive table.

---

## 3. Data Overview

N/A for synonym. Data resides in EtoroArchive database.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Three-part name | - | - | CODE-BACKED | Points to [EtoroArchive].[Trade].[DividendPositionsSnapshot]. Stores historical position snapshots used for dividend eligibility determination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [EtoroArchive].[Trade].[DividendPositionsSnapshot] | Synonym target | Cross-database reference to archived dividend snapshot table |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in the SSDT codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendPositionsSnapshot (synonym)
  +-- [EtoroArchive].[Trade].[DividendPositionsSnapshot] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [EtoroArchive].[Trade].[DividendPositionsSnapshot] | Remote Table | Synonym target |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for synonym.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Query archived dividend snapshots
```sql
SELECT TOP 10 * FROM Trade.DividendPositionsSnapshot WITH (NOLOCK) ORDER BY 1 DESC
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'DividendPositionsSnapshot' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Check connectivity
```sql
SELECT TOP 1 1 AS IsReachable FROM Trade.DividendPositionsSnapshot WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendPositionsSnapshot | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.DividendPositionsSnapshot.sql*
