# History.PositionFail

> Synonym aliasing the Azure secondary replica of the PositionFailReal database's position failure table, providing History-schema read access to the high-availability read copy of position failure records from the dedicated Azure position-fail storage system.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionFail` is a synonym pointing to `[PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail]` - the read-only secondary replica of the `PositionFailReal` database on Azure. This is distinct from `History.PositionFailInsert` which points to the primary writable Azure replica.

The `PositionFailReal` database is a dedicated Azure SQL database specifically for position failure records in real (non-demo) accounts. The system maintains two replicas:
- **Secondary (read)**: `PositionFailRealAzureSecondary` - used for all SELECT queries (this synonym)
- **Primary (write)**: `PositionFailRealAzure` - used for INSERT operations (`History.PositionFailInsert`)

This read/write split is an important performance and availability pattern: reads are served from the secondary replica to avoid contention with writes on the primary, and the secondary continues to serve reads even during primary maintenance windows.

`History.PositionFailLocal` is the local staging table; `History.PositionFailWrite` is the local write synonym. The Azure path (`PositionFailReal`) is the authoritative long-term store, while the local path serves as the immediate write buffer.

---

## 2. Business Logic

### 2.1 Read vs Write Replica Pattern

**What**: Two synonyms with different targets enable read/write separation for the Azure position fail store.

**Columns/Parameters Involved**: (All - this is a pointer to the full table)

**Rules**:
- `History.PositionFail` -> `PositionFailRealAzureSecondary` (READ ONLY - secondary replica)
- `History.PositionFailInsert` -> `PositionFailRealAzure` (WRITE - primary replica)
- All SELECT queries should use `History.PositionFail` (secondary)
- All INSERT operations go through `History.PositionFailInsert` -> `History.InsertFailPositionToAzure` procedure

**Diagram**:
```
READS:   History.PositionFail -> PositionFailRealAzureSecondary (read-only replica)
WRITES:  History.PositionFailInsert -> PositionFailRealAzure (primary)
LOCAL:   History.PositionFailWrite -> History.PositionFailLocal (local cache/buffer)
```

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail]`. For schema reference, see `History.PositionFailLocal` (local equivalent with identical structure).

---

## 4. Elements

N/A for Synonym. All elements mirror those in `History.PositionFailLocal` - see [History.PositionFailLocal](../Tables/History.PositionFailLocal.md) for the full column definitions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail] | Synonym | Points to the Azure read-replica of the position fail table |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFail (synonym)
+-- [PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail] (external table - Azure secondary)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [PositionFailRealAzureSecondary].[PositionFailReal].[History].[PositionFail] | External Table | Azure read-only secondary replica target |

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

### 8.1 Query position failures from Azure secondary

```sql
SELECT TOP 10 *
FROM History.PositionFail WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.2 Compare Azure vs local position fail records

```sql
-- Azure secondary (long-term store):
SELECT COUNT(*) AS AzureCount FROM History.PositionFail WITH (NOLOCK)
-- Local (staging buffer):
SELECT COUNT(*) AS LocalCount FROM History.PositionFailLocal WITH (NOLOCK)
```

### 8.3 Check synonym definitions for all PositionFail variants

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.name LIKE 'PositionFail%'
ORDER BY s.name
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.2/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 7.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFail | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.PositionFail.sql*
