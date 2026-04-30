# History.GetParentCIDByHistoryMirrorID

> Returns the popular investor's CID (ParentCID) for a given MirrorID by looking up the first matching record in History.Mirror - used to identify which popular investor a specific copy-trading relationship was connected to.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MirrorID (INT) - the copy-trading relationship ID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.GetParentCIDByHistoryMirrorID` is a simple lookup procedure that answers one question: "Who is the popular investor (ParentCID) for this MirrorID?" It reads from `History.Mirror` - the audit log of successful copy-trading operations - to retrieve the popular investor's CID associated with a given mirror relationship.

This procedure exists because `MirrorID` is the primary identifier for a copy-trading relationship throughout the trading system, but many processes need to know the ParentCID (the popular investor being copied) for a given MirrorID. Rather than requiring every caller to know the join path or table structure, this procedure provides a clean, reusable lookup.

The procedure uses `SELECT TOP 1` because `History.Mirror` contains multiple rows per MirrorID (one per operation throughout the mirror's lifecycle). Since `ParentCID` is set at registration and does not change, any row from `History.Mirror` for a given MirrorID will return the same `ParentCID`. `TOP 1` simply returns efficiently without needing ORDER BY for this stable column.

---

## 2. Business Logic

### 2.1 MirrorID-to-ParentCID Resolution

**What**: Converts a MirrorID (copy relationship identifier) to a ParentCID (popular investor identifier).

**Columns/Parameters Involved**: `@MirrorID`, `ParentCID`

**Rules**:
- History.Mirror stores the ParentCID in every row for a given MirrorID (captured at registration and maintained consistently)
- TOP 1 is safe here: ParentCID does not change during a mirror's lifecycle
- Uses NOLOCK hint (acceptable for historical audit data)
- If MirrorID does not exist in History.Mirror (e.g., mirror was never registered, or data predates History.Mirror), returns empty result set (no row)

**Diagram**:
```
@MirrorID (INT)
    |
    v
History.Mirror WHERE MirrorID=@MirrorID
    |
    SELECT TOP 1 ParentCID
    |
    v
ParentCID (INT) - the popular investor's CID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MirrorID | INT | - | - | VERIFIED | The copy-trading relationship ID to look up. This is the MirrorID column in History.Mirror, Trade.Mirror, and other mirror-related tables. Identifies a unique copier-to-popular-investor relationship. |

**Output** (single column, at most 1 row):

| # | Output Column | Source | Description |
|---|--------------|--------|-------------|
| 1 | ParentCID | History.Mirror.ParentCID | The popular investor's customer ID (CID). The person being copied in this mirror relationship. Returns no rows if the MirrorID is not found in History.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @MirrorID | History.Mirror | SELECT (NOLOCK) | Reads ParentCID for the given MirrorID |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Application / other procedures | @MirrorID | CALLER | Called when the popular investor's CID needs to be resolved from a MirrorID |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetParentCIDByHistoryMirrorID (procedure)
+-- History.Mirror (table) [SELECT TOP 1 ParentCID WHERE MirrorID=@MirrorID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | SELECT - retrieves ParentCID for the given MirrorID with NOLOCK |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Various callers | Application/Procedure | CALLER - invoked when ParentCID lookup is needed for a MirrorID |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Relevant index on History.Mirror:
- `IX_HistoryMirror_MirrorID_Filtered` (NC on MirrorID WHERE MirrorOperationID=2) - partial coverage
- For best performance on this SP, an index on History.Mirror(MirrorID) INCLUDE (ParentCID) would be optimal

### 7.2 Constraints

N/A for Stored Procedure.

---

## 8. Sample Queries

### 8.1 Look up the popular investor for a mirror

```sql
EXEC History.GetParentCIDByHistoryMirrorID @MirrorID = 1883762
```

### 8.2 Verify the result against History.Mirror directly

```sql
SELECT TOP 1
    m.MirrorID,
    m.CID AS CopierCID,
    m.ParentCID AS PopularInvestorCID,
    m.ParentUserName,
    m.Occurred AS RegisteredAt
FROM History.Mirror m WITH (NOLOCK)
WHERE m.MirrorID = 1883762
  AND m.MirrorOperationID = 1  -- Registration row
```

### 8.3 Batch resolve multiple MirrorIDs to ParentCIDs

```sql
SELECT DISTINCT
    m.MirrorID,
    m.ParentCID
FROM History.Mirror m WITH (NOLOCK)
WHERE m.MirrorID IN (1883762, 1234567, 987654)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.2/10 (Elements: 10.0/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (History.Mirror) | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetParentCIDByHistoryMirrorID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetParentCIDByHistoryMirrorID.sql*
