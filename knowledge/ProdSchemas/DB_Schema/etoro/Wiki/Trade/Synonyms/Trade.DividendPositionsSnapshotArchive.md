# Trade.DividendPositionsSnapshotArchive

> Synonym pointing to the dividend positions snapshot table in the DividendsAzure linked server (Dividends database), providing access to dividend eligibility snapshots stored in the dedicated dividends system.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Synonym |
| **Key Identifier** | Target: [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.DividendPositionsSnapshotArchive provides access to dividend position snapshots stored in the dedicated Dividends database on the DividendsAzure linked server. Unlike Trade.DividendPositionsSnapshot (which points to EtoroArchive), this synonym targets the Dividends-specific database, suggesting a separation between the general archive and the dedicated dividend processing system.

This dual-synonym pattern allows the system to maintain dividend snapshots in both an archival system and the active dividend processing system, supporting different access patterns and retention policies.

No direct consumers found in the SSDT codebase.

---

## 2. Business Logic

No complex multi-column business logic patterns detected. See individual element descriptions in Section 3.

---

## 3. Data Overview

N/A for synonym.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | (synonym target) | Four-part name | - | - | CODE-BACKED | Points to [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot]. Stores dividend position snapshots in the dedicated dividends processing database. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Target | [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] | Synonym target | Cross-database reference to dividend snapshots in Dividends database |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in the SSDT codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.DividendPositionsSnapshotArchive (synonym)
  +-- [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] (remote table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DividendsAzure].[Dividends].[Trade].[DividendPositionsSnapshot] | Remote Table | Synonym target |

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

### 8.1 Query dividend snapshots from Dividends DB
```sql
SELECT TOP 10 * FROM Trade.DividendPositionsSnapshotArchive WITH (NOLOCK) ORDER BY 1 DESC
```

### 8.2 Verify synonym target
```sql
SELECT name, base_object_name FROM sys.synonyms WHERE name = 'DividendPositionsSnapshotArchive' AND schema_id = SCHEMA_ID('Trade')
```

### 8.3 Compare with primary snapshot synonym
```sql
SELECT 'Archive' AS Source, COUNT(*) AS Cnt FROM Trade.DividendPositionsSnapshot WITH (NOLOCK)
UNION ALL
SELECT 'DividendsDB', COUNT(*) FROM Trade.DividendPositionsSnapshotArchive WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 7.0/10 (Elements: 10/10, Logic: 2/10, Relationships: 2/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.DividendPositionsSnapshotArchive | Type: Synonym | Source: etoro/etoro/Trade/Synonyms/Trade.DividendPositionsSnapshotArchive.sql*
