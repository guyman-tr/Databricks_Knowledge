# History.PositionFailInsert

> Synonym aliasing the primary writable Azure replica of the PositionFailReal database's position failure table, used exclusively for INSERT operations to write position failure records to the Azure long-term store.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [PositionFailRealAzure].[PositionFailReal].[History].[PositionFail] |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionFailInsert` is a synonym pointing to `[PositionFailRealAzure].[PositionFailReal].[History].[PositionFail]` - the primary writable replica of the `PositionFailReal` database on Azure. This is the write path for moving position failure records from the local `History.PositionFailLocal` staging table to the Azure long-term store.

The naming convention ("Insert") confirms this synonym's read/write role: it is used exclusively for INSERT operations, while `History.PositionFail` (pointing to the secondary replica) handles SELECTs. The `History.InsertFailPositionToAzure` procedure reads from `History.PositionFailLocal` and writes through `History.PositionFailInsert` to transfer local failures to Azure storage.

This pattern implements a two-stage failure persistence:
1. Immediate local write via `History.PositionFailWrite` -> `History.PositionFailLocal`
2. Async batch transfer via `History.InsertFailPositionToAzure` -> `History.PositionFailInsert` -> Azure primary

---

## 2. Business Logic

### 2.1 Read vs Write Replica Pattern

**What**: `PositionFailInsert` is the write endpoint; `PositionFail` is the read endpoint.

**Rules**:
- `History.PositionFailInsert` -> `PositionFailRealAzure` (PRIMARY - accepts writes)
- `History.PositionFail` -> `PositionFailRealAzureSecondary` (READ-ONLY - secondary replica)
- Only `History.InsertFailPositionToAzure` should INSERT through this synonym
- Never query (SELECT) through `PositionFailInsert` - use `PositionFail` for reads

**Diagram**:
```
Local staging:
  Trade Engine -> History.PositionFailWrite -> History.PositionFailLocal

Azure transfer (async):
  History.InsertFailPositionToAzure
    SELECT FROM History.PositionFailLocal
    INSERT INTO History.PositionFailInsert -> PositionFailRealAzure (PRIMARY write)

Query path:
  SELECT FROM History.PositionFail -> PositionFailRealAzureSecondary (READ)
```

---

## 3. Data Overview

N/A for Synonym. Data resides in the target: `[PositionFailRealAzure].[PositionFailReal].[History].[PositionFail]`. Schema matches `History.PositionFailLocal` - see [History.PositionFailLocal](../Tables/History.PositionFailLocal.md).

---

## 4. Elements

N/A for Synonym. All elements mirror those in `History.PositionFailLocal` - see [History.PositionFailLocal](../Tables/History.PositionFailLocal.md) for the full column definitions.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | [PositionFailRealAzure].[PositionFailReal].[History].[PositionFail] | Synonym | Points to the Azure primary (writable) position fail table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.InsertFailPositionToAzure | INSERT | WRITER | The only procedure that should INSERT through this synonym |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFailInsert (synonym)
+-- [PositionFailRealAzure].[PositionFailReal].[History].[PositionFail] (external table - Azure primary)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| [PositionFailRealAzure].[PositionFailReal].[History].[PositionFail] | External Table | Azure primary (write) target |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.InsertFailPositionToAzure | Stored Procedure | WRITER - INSERTs local position fail records to Azure via this synonym |

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
WHERE s.name = 'PositionFailInsert'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.2 All PositionFail synonyms and their targets

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE SCHEMA_NAME(s.schema_id) = 'History'
  AND s.name LIKE 'PositionFail%'
ORDER BY s.name
```

### 8.3 Monitor local staging queue pending Azure transfer

```sql
-- Rows in local staging awaiting Azure transfer
SELECT COUNT(*) AS PendingTransfer
FROM History.PositionFailLocal pfl WITH (NOLOCK)
WHERE NOT EXISTS (
    SELECT 1 FROM History.PositionFail pf WITH (NOLOCK)
    WHERE pf.PositionFailID = pfl.PositionFailID
)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.3/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFailInsert | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.PositionFailInsert.sql*
