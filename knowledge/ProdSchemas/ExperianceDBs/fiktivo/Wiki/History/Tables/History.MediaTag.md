# History.MediaTag

> SQL Server temporal history table that stores all historical versions of media tag records, tracking changes to marketing tag definitions used for affiliate tracking links.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table (Temporal History) |
| **Key Identifier** | TagID (int) - identifies the media tag across versions |
| **Partition** | No |
| **Indexes** | 1 active (clustered on ValidTo, ValidFrom) |

---

## 1. Business Meaning

History.MediaTag is the system-versioned temporal history table for dbo.MediaTag. It automatically captures every previous version of a media tag record whenever the base table is modified (INSERT, UPDATE, DELETE). Media tags are used to categorize and label marketing creatives (banners, links) in the affiliate tracking system, enabling affiliates and managers to filter and organize marketing assets.

This table exists because SQL Server's temporal tables (SYSTEM_VERSIONING) require a paired history table to store superseded row versions. It enables point-in-time queries (FOR SYSTEM_TIME AS OF) to see what any media tag looked like at any moment in the past, which is critical for audit trails and investigating historical affiliate tracking configurations.

Data flows into this table automatically via SQL Server's temporal mechanism. When a row in dbo.MediaTag is updated or deleted, the previous version is moved here with its ValidFrom/ValidTo timestamps. The Trace column captures session context (hostname, application name, stored procedure name) for each change. Key operations that trigger history entries include UpdateMediaTag and RemoveMediaTags (visible in the Trace JSON).

---

## 2. Business Logic

### 2.1 Temporal Versioning Pattern

**What**: SQL Server system-versioned temporal table that automatically tracks all historical versions of media tag records.

**Columns/Parameters Involved**: `ValidFrom`, `ValidTo`, `Trace`

**Rules**:
- ValidFrom = timestamp when this version became active in the base table
- ValidTo = timestamp when this version was superseded (replaced by a newer version)
- For any given TagID, the history rows form a non-overlapping timeline
- The Trace column is a JSON string containing: HostName (Kubernetes pod), AppName (AffiliateAdminBack), SUserName, SPID, DBName, ObjectName (the stored procedure that caused the change)
- Rows appear here only when the base table (dbo.MediaTag) is modified - the current/active version stays in dbo.MediaTag

**Diagram**:
```
dbo.MediaTag (current version)
    | UPDATE/DELETE triggers temporal versioning
    v
History.MediaTag (all previous versions)
    ValidFrom -------- ValidTo
    v1: 2025-01-01 --- 2025-06-15  (original creation)
    v2: 2025-06-15 --- 2026-02-17  (after first update)
    v3: 2026-02-17 --- 2026-02-17  (short-lived test version)
```

---

## 3. Data Overview

| TagID | TagName | TranslationKey | Trace (ObjectName) | ValidFrom | ValidTo | Meaning |
|---|---|---|---|---|---|---|
| 130 | IJAAIJDDEF | AUTOMATIONTESTUPDATETAGTEST | UpdateMediaTag | 2026-02-17 21:52:54 | 2026-02-17 21:52:54 | Automated test tag that was updated and immediately superseded - very short-lived version (0.28 seconds) |
| 128 | HIBFKKHJDJ | AUTOMATIONTESTDELETETAGTEST | RemoveMediaTags | 2026-02-17 21:52:52 | 2026-02-17 21:52:53 | Test tag created specifically to test deletion - removed via RemoveMediaTags procedure |
| 127 | KAGEGJCFFI | AUTOMATIONTESTSECONDCREATETAGREQUEST | RemoveMediaTags | 2026-02-17 21:52:52 | 2026-02-17 21:52:52 | Second tag in a multi-tag creation test sequence, removed immediately after creation as part of test cleanup |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | TagID | int | NO | - | CODE-BACKED | Identifier of the media tag. Same value as dbo.MediaTag.TagID. Multiple rows can share the same TagID - each represents a different historical version of that tag. |
| 2 | TagName | nvarchar(500) | NO | - | CODE-BACKED | Display name of the media tag at the time of this version. Used for organizing and filtering marketing creatives in the affiliate console. |
| 3 | TranslationKey | varchar(128) | NO | - | CODE-BACKED | Localization key used to display the tag name in the affiliate's preferred language. Maps to the affiliate platform's translation system. |
| 4 | Trace | nvarchar(733) | NO | - | CODE-BACKED | JSON string capturing the session context when this version was created. Contains: HostName (Kubernetes pod name, e.g., "aff-admin-b-794c77957-dvp8r"), AppName ("AffiliateAdminBack"), SUserName (database user), SPID (session ID), DBName ("fiktivo"), ObjectName (the stored procedure that caused the change, e.g., "UpdateMediaTag", "RemoveMediaTags"). |
| 5 | ValidFrom | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version of the row became active in dbo.MediaTag. Set automatically by SQL Server's temporal mechanism. |
| 6 | ValidTo | datetime2(7) | NO | - | CODE-BACKED | Timestamp when this version was superseded by a newer version (or deleted). Set automatically by SQL Server's temporal mechanism. Used as the first key in the clustered index for efficient temporal range queries. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| TagID | dbo.MediaTag | Temporal History | This table stores historical versions of dbo.MediaTag rows. The current/active version remains in dbo.MediaTag. |

### 5.2 Referenced By (other objects point to this)

This table is not directly referenced by stored procedures, views, or functions. It is accessed implicitly via temporal queries (FOR SYSTEM_TIME) on dbo.MediaTag.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.MediaTag (table)
```

This table has no code-level dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.MediaTag | Table | SYSTEM_VERSIONING - SQL Server automatically moves superseded row versions from dbo.MediaTag into this history table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| ix_MediaTag | CLUSTERED | ValidTo ASC, ValidFrom ASC | - | - | Active |

### 7.2 Constraints

None. History tables managed by SYSTEM_VERSIONING do not carry their own PK, FK, or check constraints. Data integrity is enforced on the base table (dbo.MediaTag).

Note: Uses PAGE compression.

---

## 8. Sample Queries

### 8.1 View the complete change history for a specific tag
```sql
SELECT TagID, TagName, TranslationKey, ValidFrom, ValidTo
FROM dbo.MediaTag FOR SYSTEM_TIME ALL WITH (NOLOCK)
WHERE TagID = 130
ORDER BY ValidFrom
```

### 8.2 See what all tags looked like at a specific point in time
```sql
SELECT TagID, TagName, TranslationKey
FROM dbo.MediaTag FOR SYSTEM_TIME AS OF '2025-06-01T00:00:00' WITH (NOLOCK)
ORDER BY TagID
```

### 8.3 Find recently changed tags with the stored procedure that changed them
```sql
SELECT TagID, TagName,
       JSON_VALUE(Trace, '$.ObjectName') AS ChangedBy,
       JSON_VALUE(Trace, '$.HostName') AS ServerPod,
       ValidFrom, ValidTo
FROM History.MediaTag WITH (NOLOCK)
ORDER BY ValidTo DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: - | Quality: 8.5/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 9/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.MediaTag | Type: Table | Source: fiktivo/History/Tables/History.MediaTag.sql*
