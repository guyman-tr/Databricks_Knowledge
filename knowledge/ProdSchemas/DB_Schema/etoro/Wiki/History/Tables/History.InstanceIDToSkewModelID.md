# History.InstanceIDToSkewModelID

> SQL Server temporal history table storing prior row versions of Price.InstanceIDToSkewModelID, capturing every change to the mapping between pricing engine instances and their assigned skew models.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | No PK - temporal history table; CLUSTERED on (SysEndTime ASC, SysStartTime ASC) |
| **Partition** | No |
| **Indexes** | 1 (clustered on temporal system columns) |

---

## 1. Business Meaning

History.InstanceIDToSkewModelID is the SQL Server system-versioning history table for Price.InstanceIDToSkewModelID, declared as `HISTORY_TABLE = [History].[InstanceIDToSkewModelID]` in the Price.InstanceIDToSkewModelID DDL. Whenever a row in Price.InstanceIDToSkewModelID is updated or deleted, the prior version is written here automatically by SQL Server's temporal engine.

Price.InstanceIDToSkewModelID maps each pricing engine instance (InstanceId) to its assigned skew model (ModelID). Skew models control how the bid/ask spread is adjusted per instrument on a given pricing server - a key parameter in eToro's price calculation pipeline. The history table provides a complete audit trail of when each instance's skew model assignment changed, enabling investigation of price behavior anomalies by correlating model switches with price quality metrics.

Currently the table holds 0 rows. This is consistent with the insert trigger pattern (TRG_T_InstanceIDToSkewModelID) - even on INSERT the trigger fires a no-op UPDATE to force a temporal version cut, but in this case no rows have been inserted into the live Price table in this environment, or all insert-triggered history rows have been cleaned.

---

## 2. Business Logic

### 2.1 SQL Server Temporal Versioning Mechanics

**What**: SQL Server automatically writes superseded row versions from Price.InstanceIDToSkewModelID into this table on UPDATE or DELETE.

**Columns/Parameters Involved**: `SysStartTime`, `SysEndTime`

**Rules**:
- On UPDATE to Price.InstanceIDToSkewModelID: the old (InstanceId, ModelID) assignment is written here with SysEndTime = the update timestamp
- On DELETE: the deleted assignment is written here
- The CLUSTERED INDEX on (SysEndTime ASC, SysStartTime ASC) optimizes FOR SYSTEM_TIME AS OF queries
- INSERT trigger TRG_T_InstanceIDToSkewModelID does a no-op UPDATE after each INSERT, producing an immediate history record (SysStartTime = SysEndTime)

### 2.2 Skew Model Assignment Versioning

**What**: Tracks which skew model was active for each pricing instance at any point in time.

**Columns/Parameters Involved**: `InstanceId`, `ModelID`, `SysStartTime`, `SysEndTime`

**Rules**:
- InstanceId identifies the Price service instance (a running pricing server or partition)
- ModelID identifies the skew model assigned to that instance - FK to Price.SkewModels in source table
- A given InstanceId can have different ModelIDs at different points in time; the history table preserves all prior assignments
- To reconstruct which model was active at a specific time: SELECT from Price.InstanceIDToSkewModelID FOR SYSTEM_TIME AS OF '{timestamp}'

### 2.3 Computed Columns Materialized in History

**What**: Price.InstanceIDToSkewModelID has DbLoginName and AppLoginName as computed columns (non-persisted). In this history table they are stored as regular nullable columns.

**Columns/Parameters Involved**: `DbLoginName`, `AppLoginName`

**Rules**:
- DbLoginName: suser_name() - identifies the SQL login that performed the change
- AppLoginName: context_info() - application-layer login context, typically NULL for automated pricing service writes

---

## 3. Data Overview

0 rows (no temporal versions generated in this environment). A representative history row would appear when a pricing instance's skew model assignment is changed:

| InstanceId | ModelID | DbLoginName | SysStartTime | SysEndTime | Meaning |
|-----------|---------|-------------|-------------|-----------|---------|
| (no rows) | - | - | - | - | No temporal versions have been generated for Price.InstanceIDToSkewModelID in this environment |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstanceId | int | NO | - | VERIFIED | ID of the pricing engine instance (a running Price server or partition). Composite PK component in source table (Price.InstanceIDToSkewModelID). Multiple history rows for the same InstanceId capture its model assignment history. |
| 2 | ModelID | int | NO | - | VERIFIED | ID of the skew model assigned to this instance. FK to Price.SkewModels in source table. The skew model defines the spread/skew calculation algorithm applied by this pricing instance for bid/ask price generation. |
| 3 | DbLoginName | nvarchar(128) | YES | - | CODE-BACKED | Materialized snapshot of suser_name() at the time this row version was closed. Identifies the DB login that performed the UPDATE or DELETE that superseded this assignment. Computed in source table; stored here. |
| 4 | AppLoginName | varchar(500) | YES | - | CODE-BACKED | Materialized snapshot of context_info() at version close time. Typically NULL - pricing service writes generally do not set context_info. Computed in source table; stored here. |
| 5 | SysStartTime | datetime2(7) | NO | - | VERIFIED | Start of the validity window for this historical assignment version. Set by SQL Server temporal engine to the SysStartTime of the Price.InstanceIDToSkewModelID row at version close. Rows where SysStartTime = SysEndTime are insert artifacts from TRG_T_InstanceIDToSkewModelID. |
| 6 | SysEndTime | datetime2(7) | NO | - | VERIFIED | End of the validity window for this assignment version. Set by SQL Server temporal engine to the timestamp of the UPDATE/DELETE. CLUSTERED INDEX ordered (SysEndTime, SysStartTime) for temporal range scan performance. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| ModelID | Price.SkewModels | Implicit (from source FK) | The skew model assigned to the instance in this history version. Source has explicit FK to Price.SkewModels. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Price.InstanceIDToSkewModelID | (SYSTEM_VERSIONING) | Temporal - HISTORY_TABLE | All closed row versions from Price.InstanceIDToSkewModelID flow here automatically. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.InstanceIDToSkewModelID (table)
  - leaf node: no code-level dependencies (auto-managed by SQL Server temporal engine)
```

### 6.1 Objects This Depends On

No dependencies. Managed exclusively by SQL Server temporal versioning.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Price.InstanceIDToSkewModelID | Table | Declares this as its HISTORY_TABLE via SYSTEM_VERSIONING. All temporal version rows flow here. |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_InstanceIDToSkewModelID | CLUSTERED | SysEndTime ASC, SysStartTime ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DATA_COMPRESSION = PAGE | Storage option | Page-level compression applied to all data and index pages. |

---

## 8. Sample Queries

### 8.1 Check which skew model was assigned to a pricing instance at a specific point in time
```sql
SELECT InstanceId, ModelID, SysStartTime, SysEndTime
FROM Price.InstanceIDToSkewModelID WITH (NOLOCK)
FOR SYSTEM_TIME AS OF '2025-01-01 00:00:00'
WHERE InstanceId = 1;
```

### 8.2 Get the full assignment history for a pricing instance (live + history)
```sql
SELECT InstanceId, ModelID, SysStartTime, SysEndTime,
       DATEDIFF(HOUR, SysStartTime, SysEndTime) AS HoursActive,
       'History' AS Source
FROM History.InstanceIDToSkewModelID WITH (NOLOCK)
WHERE InstanceId = 1
UNION ALL
SELECT InstanceId, ModelID, SysStartTime, SysEndTime,
       NULL AS HoursActive, 'Current' AS Source
FROM Price.InstanceIDToSkewModelID WITH (NOLOCK)
WHERE InstanceId = 1
ORDER BY SysStartTime;
```

### 8.3 Find all model assignment changes on a given date
```sql
SELECT InstanceId, ModelID, SysStartTime, SysEndTime, DbLoginName
FROM History.InstanceIDToSkewModelID WITH (NOLOCK)
WHERE CAST(SysEndTime AS date) = '2025-06-15'
  AND SysStartTime != SysEndTime  -- exclude insert artifacts
ORDER BY SysEndTime;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 7/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.InstanceIDToSkewModelID | Type: Table | Source: etoro/etoro/History/Tables/History.InstanceIDToSkewModelID.sql*
