# History.SYN_MoveRecsFromDagSyncTslToPass_BCP

> Synonym aliasing the DAG-REAL-Tsl linked server's stored procedure that bulk-copies TSL (Trailing Stop Loss) sync records from the DAG (Data Availability Group) sync table to the pass table, enabling the local History schema to invoke cross-server TSL data migration.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.SYN_MoveRecsFromDagSyncTslToPass_BCP` is a synonym pointing to `[DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP]` on the `DAG-REAL-Tsl` linked server. This is one of the most specifically named synonyms in the History schema - each part of the name encodes technical context:

- **SYN**: Synonym pattern identifier
- **DAG**: SQL Server Availability Group (distributed across nodes)
- **REAL**: Real (production, non-demo) environment
- **Tsl**: Trailing Stop Loss - the data type being synchronized
- **MoveRecsFrom...ToPass_BCP**: BCP (Bulk Copy Protocol/Process) operation moving records from a sync staging table to a "pass" (passed/completed) destination table

The procedure `MoveRecsFromHistorySyncTSLToPass_BCP` moves TSL history records from the DAG sync intermediate table to the pass/archive destination. This is part of the multi-stage TSL data pipeline: TSL events are captured locally, synced via the DAG replication, and then moved by this cross-server procedure from the sync buffer to final storage.

The local synonym `History.MoveRecsFromDagSyncTslToPass` (without `_BCP`) also exists, presumably calling a similar procedure via a different path or with different parameters.

---

## 2. Business Logic

### 2.1 TSL Data Pipeline Stage

**What**: This synonym is one step in the Trailing Stop Loss data movement pipeline from DAG sync to permanent storage.

**Rules**:
- Called when TSL records in the DAG sync buffer need to be moved to the pass (final) table
- `_BCP` suffix indicates bulk copy protocol - higher-throughput than row-by-row inserts
- DAG-REAL-Tsl is the SQL Server AG listener/node holding the TSL sync data
- `History.MoveRecsFromDagSyncTslToPass` (without _BCP) and `History.SYN_MoveRecsFromDagSyncTslToPass_BCP` are two paths for the same logical operation

**Diagram**:
```
TSL events captured locally
    |
    v
DAG replication -> DAG-REAL-Tsl linked server (sync buffer)
    |
    v
History.SYN_MoveRecsFromDagSyncTslToPass_BCP (this synonym)
    -> [DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP]
    -> BCP: sync buffer -> pass/archive table
```

---

## 3. Data Overview

N/A for Synonym. Target is a stored procedure on the DAG-REAL-Tsl linked server.

---

## 4. Elements

N/A for Synonym. Parameters are defined on the target procedure `[DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP]`.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP] | Synonym | Points to the TSL BCP migration procedure on the DAG-REAL-Tsl linked server |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.SYN_MoveRecsFromDagSyncTslToPass_BCP (synonym)
+-- [DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP] (external procedure - DAG-REAL-Tsl linked server)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [DAG-REAL-Tsl].[etoro].[History].[MoveRecsFromHistorySyncTSLToPass_BCP] | External Stored Procedure | Target of this synonym on the DAG-REAL-Tsl linked server |

### 6.2 Objects That Depend On This

No dependents found in local schema analysis.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Check synonym definition

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'SYN_MoveRecsFromDagSyncTslToPass_BCP'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.2 Compare both TSL sync move synonyms

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.name LIKE '%MoveRecs%'
ORDER BY s.name
```

### 8.3 List all DAG-related synonyms in History schema

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.base_object_name LIKE '%DAG%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 7.8/10 (Elements: 10.0/10, Logic: 5.0/10, Relationships: 6.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.SYN_MoveRecsFromDagSyncTslToPass_BCP | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.SYN_MoveRecsFromDagSyncTslToPass_BCP.sql*
