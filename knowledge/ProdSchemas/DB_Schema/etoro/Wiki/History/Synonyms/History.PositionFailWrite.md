# History.PositionFailWrite

> Synonym aliasing History.PositionFailLocal (within the same schema), providing an abstraction layer between writer processes and the physical position failure table so the storage target can be changed without modifying writer code.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Synonym |
| **Key Identifier** | N/A - pointer to [History].[PositionFailLocal] (local table) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.PositionFailWrite` is a synonym pointing to `[History].[PositionFailLocal]` - a local table within the same schema and database. Unlike all other History-schema synonyms which point to external databases, this synonym targets a local table.

The purpose is pure abstraction: all writer processes (`History.PostPositionFail`, `History.AdminPositionFailInfo` via `History.PositionFailInfo`, Trade-schema procedures) INSERT into `History.PositionFailWrite` rather than directly into `History.PositionFailLocal`. This indirection means that if the physical storage target ever needs to change (e.g., routing writes to the Azure database directly instead of a local staging table), only the synonym definition needs to be updated - not every stored procedure that writes position failures.

This is the local write path in the three-tier PositionFail storage architecture:
1. **Write**: `History.PositionFailWrite` -> `History.PositionFailLocal` (immediate, local)
2. **Transfer to Azure**: `History.InsertFailPositionToAzure` -> `History.PositionFailInsert` -> Azure primary
3. **Read from Azure**: `History.PositionFail` -> Azure secondary replica

See [History.PositionFailLocal](../Tables/History.PositionFailLocal.md) for the full table documentation.

---

## 2. Business Logic

### 2.1 Write Abstraction Pattern

**What**: `PositionFailWrite` decouples writers from the physical table name.

**Rules**:
- All INSERT operations use `History.PositionFailWrite` as the target
- Currently resolves to `History.PositionFailLocal`
- If storage target changes, update only the synonym definition
- `History.PostPositionFail` is the primary writer via XML payload
- `History.AdminPositionFailInfo` (via `History.PositionFailInfo`) is the admin-path writer

**Diagram**:
```
Writers -> History.PositionFailWrite (synonym)
                         |
                         v
               History.PositionFailLocal (physical table)
                         |
                async transfer
                         |
                         v
               History.PositionFailInsert -> Azure Primary
```

---

## 3. Data Overview

N/A for Synonym. Data is in [History.PositionFailLocal](../Tables/History.PositionFailLocal.md).

---

## 4. Elements

N/A for Synonym. All elements are defined on [History.PositionFailLocal](../Tables/History.PositionFailLocal.md).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (synonym) | History.PositionFailLocal | Synonym | Local alias pointing to the physical position fail staging table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.PostPositionFail | INSERT | PRIMARY WRITER | Writes all position failures from trade engine via XML payload |
| History.PositionFailInfo | INSERT (via PositionFailWrite) | WRITER | Standard position fail logging procedure |
| History.AdminPositionFailInfo | EXEC PositionFailInfo | INDIRECT WRITER | Admin path - calls PositionFailInfo which writes here |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.PositionFailWrite (synonym)
+-- History.PositionFailLocal (local table - physical target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.PositionFailLocal | Table | Physical target of all writes - synonym resolves to this table |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.PostPositionFail | Stored Procedure | PRIMARY WRITER - all trade engine failures written here |
| History.PositionFailInfo | Stored Procedure | WRITER - standard fail logging |
| History.AdminPositionFailInfo | Stored Procedure | INDIRECT WRITER - via PositionFailInfo |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Synonym.

### 7.2 Constraints

N/A for Synonym.

---

## 8. Sample Queries

### 8.1 Query current data (read via PositionFailLocal)

```sql
-- Use PositionFailLocal for reads, not PositionFailWrite
SELECT TOP 10 *
FROM History.PositionFailLocal WITH (NOLOCK)
ORDER BY FailOccurred DESC
```

### 8.2 Check the synonym target

```sql
SELECT s.name, s.base_object_name
FROM sys.synonyms s WITH (NOLOCK)
WHERE s.name = 'PositionFailWrite'
  AND SCHEMA_NAME(s.schema_id) = 'History'
```

### 8.3 Confirm PositionFailWrite resolves to PositionFailLocal

```sql
-- These should return the same count:
SELECT COUNT(*) AS ViaWrite FROM History.PositionFailWrite WITH (NOLOCK)
SELECT COUNT(*) AS ViaLocal FROM History.PositionFailLocal WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 8.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.PositionFailWrite | Type: Synonym | Source: etoro/etoro/History/Synonyms/History.PositionFailWrite.sql*
