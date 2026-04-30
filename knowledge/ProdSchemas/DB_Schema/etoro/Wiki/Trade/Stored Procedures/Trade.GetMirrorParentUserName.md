# Trade.GetMirrorParentUserName

> Returns the leader's username for a given mirror, checking Trade.Mirror first and falling back to History.Mirror if the mirror has been closed or archived. Used by the SSE service.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID - identifies the CopyTrader mirror |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Trade.GetMirrorParentUserName` resolves the leader's (parent user's) username for a given mirror ID. It first queries `Trade.Mirror` for the active mirror record; if no `ParentUserName` is found there (NULL - meaning the mirror may have been closed or removed), it falls back to `History.Mirror` to retrieve the historical record.

This procedure exists to support the SSE (Server-Sent Events) service, which needs to identify the leader associated with a mirror event in real-time. Because mirrors can be closed (and moved to History.Mirror) while SSE events are still in flight, the dual-table fallback ensures the username is always resolvable even after mirror closure.

Data flows: Called by the SSE service when processing mirror-related events. Returns a single-row, single-column result: `ParentUserName VARCHAR(50)`. If the mirror exists in neither table (very unlikely), returns an empty result set.

---

## 2. Business Logic

### 2.1 Active-to-History Fallback

**What**: The procedure tries the live mirror table first, then history - ensuring leader identity is always resolvable.

**Columns/Parameters Involved**: `@MirrorID`, `ParentUserName`

**Rules**:
- First lookup: `Trade.Mirror WHERE MirrorID = @MirrorID` - covers active mirrors.
- If `ParentUserName IS NULL` (mirror not found or row has NULL username): fall back to `History.Mirror WHERE MirrorID = @MirrorID`.
- The `TOP (1)` in both queries indicates MirrorID should be unique but the guard prevents errors if duplicates exist.
- Only the username is returned - no other mirror data.

**Diagram**:
```
@MirrorID
    |
    v
Trade.Mirror -> ParentUserName found?
    YES -> return ParentUserName
    NO (NULL) -> History.Mirror -> return ParentUserName (or empty if not there either)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | NO | - | CODE-BACKED | The mirror identifier to look up. Corresponds to `Trade.Mirror.MirrorID` (active mirrors) or `History.Mirror.MirrorID` (closed mirrors). |

**Output columns** (result set):

| # | Column | Source | Description |
|---|--------|--------|-------------|
| 1 | ParentUserName | Trade.Mirror or History.Mirror | The username of the leader (parent/portfolio owner) associated with this mirror. VARCHAR(50). NULL-safe via the fallback logic. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | Trade.Mirror | Lookup | Primary lookup for active mirror's leader username. |
| @MirrorID | History.Mirror | Lookup (fallback) | Secondary lookup when mirror is no longer in the active table. |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMirrorParentUserName (procedure)
├── Trade.Mirror (table)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.Mirror | Table | Primary SELECT - TOP 1 ParentUserName WHERE MirrorID = @MirrorID |
| History.Mirror | Table (cross-schema) | Fallback SELECT - TOP 1 ParentUserName WHERE MirrorID = @MirrorID, used when active mirror not found |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Get leader username for a mirror

```sql
EXEC Trade.GetMirrorParentUserName @MirrorID = 12345;
```

### 8.2 Check whether a mirror is active or in history

```sql
SELECT
    CASE
        WHEN m.MirrorID IS NOT NULL THEN 'Active - ' + m.ParentUserName
        WHEN hm.MirrorID IS NOT NULL THEN 'History - ' + hm.ParentUserName
        ELSE 'Not found'
    END AS MirrorStatus
FROM (SELECT 12345 AS MirrorID) x
LEFT JOIN Trade.Mirror m WITH (NOLOCK) ON m.MirrorID = x.MirrorID
LEFT JOIN History.Mirror hm WITH (NOLOCK) ON hm.MirrorID = x.MirrorID;
```

### 8.3 Find all mirrors for a given leader username

```sql
SELECT MirrorID, ParentUserName, CID
FROM Trade.Mirror WITH (NOLOCK)
WHERE ParentUserName = 'leaderusername';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 7.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 6/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMirrorParentUserName | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetMirrorParentUserName.sql*
