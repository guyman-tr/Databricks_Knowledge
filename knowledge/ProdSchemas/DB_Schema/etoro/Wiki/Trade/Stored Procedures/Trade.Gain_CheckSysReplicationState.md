# Trade.Gain_CheckSysReplicationState

> Checks if the database replica has replicated credit data past a given date by looking for the first History.Credit record after that date.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MaxDate - replication checkpoint |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is a replication health check used by the Gain (P&L calculation) system. Before processing customer gains, the system needs to ensure the database replica it is reading from has received all credit transactions up to the required date. If the replica is lagging, processing would produce incorrect results.

The procedure checks whether any `History.Credit` record exists with an `Occurred` date after `@MaxDate`. If a row is returned, it confirms the replica has data past that date and is sufficiently up-to-date. If no rows are returned, the replica may be lagging.

---

## 2. Business Logic

### 2.1 Replication Lag Detection

**What**: Verifies data freshness by checking for recent credit records.

**Columns/Parameters Involved**: `@MaxDate`, `History.Credit.Occurred`

**Rules**:
- Returns TOP 1 record from History.Credit where Occurred > @MaxDate, ordered by CreditID ASC
- Returns the Occurred timestamp of that record (confirming how far the replica has caught up)
- Empty result set = replica has NOT yet replicated data past @MaxDate (lagging)
- The Gain system should wait or retry if no row is returned

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MaxDate | datetime | NO | - | CODE-BACKED | Checkpoint date to verify replication against. The Gain system needs data up to this date to be present on the replica before processing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | History.Credit | READER | Reads first credit record after @MaxDate to verify replication freshness |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Gain calculation service | EXEC | Caller | Called before processing to verify replica is up-to-date |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.Gain_CheckSysReplicationState (procedure)
+-- History.Credit (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | Table | SELECT TOP 1 - checks for records past @MaxDate |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found. | - | Called by external Gain service |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check Replication State for Today

```sql
EXEC Trade.Gain_CheckSysReplicationState @MaxDate = '2026-03-16'
```

### 8.2 Check Latest Credit Record

```sql
SELECT TOP 1 CreditID, Occurred
  FROM History.Credit WITH (NOLOCK)
 ORDER BY CreditID DESC
```

### 8.3 Check Credit Data Freshness

```sql
SELECT MAX(Occurred) AS LatestCredit, DATEDIFF(MINUTE, MAX(Occurred), GETUTCDATE()) AS MinutesBehind
  FROM History.Credit WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.0/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 8.0/10, Sources: 2.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.Gain_CheckSysReplicationState | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.Gain_CheckSysReplicationState.sql*
