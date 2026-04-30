# dbo.ReplCheck_FiktivoClosedPositions

> Replication health monitoring table storing the last-checked ID and timestamp for closed position replication validation.

| Property | Value |
|----------|-------|
| **Schema** | dbo |
| **Object Type** | Table |
| **Key Identifier** | ID (int, PK CLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

dbo.ReplCheck_FiktivoClosedPositions monitors replication health for the closed positions data pipeline. The DBA_ReplCheck_Update procedure updates this table with the latest replicated ID and timestamp, enabling operations teams to detect replication lag or failures between the source trading database and the fiktivo affiliate database.

Currently empty (0 rows), suggesting replication monitoring is either not active in this environment or the check has not been initialized.

---

## 2. Business Logic

No complex business logic. Simple key-value watermark for replication monitoring.

---

## 3. Data Overview

Table is empty (0 rows).

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int | NO | - | CODE-BACKED | Last-checked closed position ID for replication validation. Updated by DBA_ReplCheck_Update. |
| 2 | LastUpdated | datetime | NO | - | CODE-BACKED | Timestamp of the last replication check. Used to detect stale replication. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.DBA_ReplCheck_Update | UPDATE | Procedure (WRITER) | Updates replication check watermark |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.DBA_ReplCheck_Update | Stored Procedure | WRITER - updates replication check |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ReplCheck_FiktivoClosedPositions | CLUSTERED PK | ID ASC | - | - | Active (fill 90%, PAGE) |

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Check replication status
```sql
SELECT ID AS LastReplicatedID, LastUpdated,
       DATEDIFF(MINUTE, LastUpdated, GETDATE()) AS MinutesSinceLastCheck
FROM dbo.ReplCheck_FiktivoClosedPositions WITH (NOLOCK)
```

### 8.2 Compare with actual latest position
```sql
SELECT r.ID AS LastChecked, MAX(c.ClosedPositionsID) AS LatestPosition,
       MAX(c.ClosedPositionsID) - r.ID AS Gap
FROM dbo.ReplCheck_FiktivoClosedPositions r WITH (NOLOCK)
CROSS JOIN dbo.ClosedPositionsTbl c WITH (NOLOCK)
GROUP BY r.ID
```

### 8.3 All replication check records
```sql
SELECT * FROM dbo.ReplCheck_FiktivoClosedPositions WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 7.4/10 (Elements: 10/10, Logic: 2/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: dbo.ReplCheck_FiktivoClosedPositions | Type: Table | Source: fiktivo/dbo/Tables/dbo.ReplCheck_FiktivoClosedPositions.sql*
