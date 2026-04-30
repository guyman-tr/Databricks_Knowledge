# History.HierarchyAtPointOfTime

> Reconstructs the CopyTrader mirror hierarchy under a given leader at a historical point in time, returning the MirrorID, copier CID, and parent CID for each active relationship in the tree.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ParentCID - the leader whose copy network is being reconstructed |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.HierarchyAtPointOfTime` reconstructs the CopyTrader mirror hierarchy for a given popular investor (leader) as it existed during a specified time window. The eToro CopyTrading system allows copiers to copy leaders, and leaders can themselves copy other leaders, creating multi-level hierarchies. This procedure answers: "Who was copying @ParentCID, and who was copying THEIR copiers, at a given point in time?"

The procedure exists to support historical auditing of copy network structures - for example, to understand who was in a hierarchy at the time of an incident, or to reconstruct the tree for compliance and reporting purposes.

Data comes from `History.Mirror` which logs every mirror operation with timestamps. MirrorOperationID=1 (Register) marks when a mirror was created; MirrorOperationID=2 (UnRegister) marks when it was closed. The procedure identifies mirrors that were active during the date window by finding mirrors that had NOT yet been unregistered before @FromDate.

**Important code note**: The recursive part of the CTE contains a likely defect - the JOIN condition `HM.ParentCID = HM.CID` compares two columns from the same table row (not joining to the recursive CTE result set HAPT), which means the recursive traversal beyond the first level may not behave as intended. The anchor (first level) correctly finds direct copiers of @ParentCID.

---

## 2. Business Logic

### 2.1 Active Mirror Set Construction

**What**: Identifies mirrors that were active (not yet unregistered) at @FromDate using the temp table #t.

**Columns/Parameters Involved**: `@FromDate`, `MirrorID`, `MirrorOperationID`, `ModificationDate`

**Rules**:
- MirrorOperationID = 2 = UnRegister Mirror (end of copy relationship)
- A mirror is excluded from #t if it has a row with MirrorOperationID=2 AND ModificationDate <= @FromDate (it was already closed by the start of the window)
- Mirrors remaining in #t were either never unregistered, or were unregistered AFTER @FromDate - i.e., they were still active during some part of the window
- Index ix_t on MirrorID is created for JOIN performance

### 2.2 Recursive Hierarchy Traversal (with Code Note)

**What**: Builds the tree from @ParentCID downward using a recursive CTE.

**Columns/Parameters Involved**: `@ParentCID`, `@ToDate`, `MirrorOperationID`, `ModificationDate`

**Rules**:
- Anchor: Finds direct first-level copiers of @ParentCID (MirrorOperationID=1, ModificationDate <= @ToDate, MirrorID in active set #t)
- Recursive part: Attempts to extend the tree; the JOIN condition `HM.ParentCID = HM.CID` compares columns from the same row (not to HAPT.CID), which is a likely defect - only rows where Mirror.ParentCID equals Mirror.CID would match (an unusual self-referential condition). In practice this means the recursion may return no additional levels beyond the anchor.
- Both anchor and recursive clauses filter: MirrorOperationID=1 AND ModificationDate <= @ToDate AND MirrorID IN #t

**Diagram**:
```
@ParentCID (leader)
    |
    v
Anchor: Direct copiers (MirrorOperationID=1, ModificationDate <= @ToDate, active at @FromDate)
    |
    v
Recursive: [Likely defect in JOIN condition - may not traverse further levels]
    |
    v
SELECT MirrorID, CID, ParentCID
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of the time window. Used to determine which mirrors were still active: any mirror unregistered (MirrorOperationID=2) ON OR BEFORE @FromDate is excluded from the active set. |
| 2 | @ToDate | DATETIME | NO | - | CODE-BACKED | End of the time window. The hierarchy is built using only mirror registration events (MirrorOperationID=1) with ModificationDate <= @ToDate. Mirrors registered after @ToDate are not included. |
| 3 | @ParentCID | INT | NO | - | CODE-BACKED | The customer ID of the popular investor (leader) whose copy network hierarchy is being reconstructed. The recursive CTE starts from mirrors where ParentCID = @ParentCID. |

**Output columns** (returned by SELECT):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | INT | NO | - | VERIFIED | Unique identifier of the copy-trading mirror relationship. From History.Mirror. One row per active mirror in the hierarchy during the specified window. |
| 2 | CID | INT | NO | - | VERIFIED | The copier's customer ID - the customer who was copying their leader (ParentCID) in this mirror relationship. From History.Mirror.CID. |
| 3 | ParentCID | INT | NO | - | VERIFIED | The leader's customer ID being copied in this mirror relationship. For the anchor set, ParentCID = @ParentCID. For deeper levels, would be the CID of a copier who is also being copied. From History.Mirror.ParentCID. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | History.Mirror | Reads (recursive CTE + temp table) | Source for active mirror operation history and hierarchy reconstruction |

### 5.2 Referenced By (other objects point to this)

No callers found in the etoro SSDT repository.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.HierarchyAtPointOfTime (procedure)
└── History.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Mirror | Table | Queried twice: once for active mirror set (#t construction), once in recursive CTE |

### 6.2 Objects That Depend On This

No dependents found in the etoro SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- Creates temp table `#t (MirrorID INT)` with index `ix_t` on MirrorID for performance
- No NOLOCK on History.Mirror queries (notable difference from most History procedures)
- Recursive CTE: the recursive JOIN condition `HM.ParentCID = HM.CID` references only HM columns (not HAPT), which is a likely defect - intended condition was probably `HM.ParentCID = HAPT.CID`

---

## 8. Sample Queries

### 8.1 Get hierarchy under a leader for a specific time window

```sql
EXEC History.HierarchyAtPointOfTime
    @FromDate = '2024-01-01',
    @ToDate = '2024-06-30',
    @ParentCID = 12345
```

### 8.2 Find direct copiers of a leader at a point in time (direct query equivalent)

```sql
SELECT MirrorID, CID, ParentCID, ModificationDate
FROM History.Mirror WITH (NOLOCK)
WHERE ParentCID = 12345
  AND MirrorOperationID = 1
  AND ModificationDate <= '2024-06-30'
  AND MirrorID NOT IN (
      SELECT MirrorID
      FROM History.Mirror WITH (NOLOCK)
      WHERE MirrorOperationID = 2
        AND ModificationDate <= '2024-01-01'
  )
```

### 8.3 Check mirror operation history for a specific mirror

```sql
SELECT MirrorID, CID, ParentCID, MirrorOperationID, ModificationDate
FROM History.Mirror WITH (NOLOCK)
WHERE MirrorID = 67890
ORDER BY ModificationDate ASC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.5/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 3 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1, 8, 9B, 10, 11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 1 repo / 0 files | Corrections: 0 applied*
*Object: History.HierarchyAtPointOfTime | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.HierarchyAtPointOfTime.sql*
