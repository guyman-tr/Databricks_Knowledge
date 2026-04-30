# Trade.GetPositionsCountForMirrorsInAlignment

> Returns the count of open positions that belong to mirrors currently in "In Alignment" status, used by the mirror calculation engine to monitor alignment state.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns single scalar: PositionsCount INT |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure counts how many open trading positions are currently attached to mirrors that are in the "In Alignment" status (MirrorStatusID=3). When a CopyTrader mirror enters alignment, the system is in the process of synchronizing a copier's portfolio to match the leader's open positions - opening positions the leader has that the copier does not. Knowing how many open positions belong to such mirrors helps the MirrorCalculationApp determine the scale of in-progress alignment work.

The procedure exists as a lightweight health or monitoring query for the CopyTrader alignment process. It gives the calculation application a quick signal of "how many positions are being managed under active alignment." Without this, the application would need to join these tables itself and risk running inconsistent queries against the same base data.

Data flows: Called by the MirrorCalculationApp service (via EXECUTE permission in UsersPermissions/MirrorCalculationApp.sql). Reads Trade.PositionTbl (open positions, StatusID=1) joined to Trade.Mirror (MirrorStatusID=3 = In Alignment). Returns a single integer count.

---

## 2. Business Logic

### 2.1 Mirror "In Alignment" Concept

**What**: MirrorStatusID=3 marks a CopyTrader relationship that is actively reconciling the copier's portfolio to match the leader.

**Columns/Parameters Involved**: `Trade.Mirror.MirrorStatusID`, `Trade.PositionTbl.StatusID`, `Trade.PositionTbl.MirrorID`

**Rules**:
- Only open positions (StatusID=1) are counted - closed positions no longer represent active exposure.
- Only positions linked to a Mirror with MirrorStatusID=3 (In Alignment) are counted - other mirror statuses (Active, Paused, Closed) are excluded.
- The join is on pt.MirrorID = mr.MirrorID, so positions with MirrorID=0 (manual trades) are excluded.

**Diagram**:
```
Trade.PositionTbl (StatusID=1, MirrorID > 0)
        |
        INNER JOIN Trade.Mirror (MirrorStatusID=3 = In Alignment)
        |
        COUNT -> PositionsCount
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | PositionsCount | INT | NO | - | CODE-BACKED | Count of open positions (Trade.PositionTbl.StatusID=1) whose MirrorID links to a Mirror with MirrorStatusID=3 (In Alignment). A value of 0 means no active alignment operations are in progress. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| MirrorID | Trade.PositionTbl | JOIN source | Open positions (StatusID=1) with a non-zero MirrorID |
| MirrorID | Trade.Mirror | JOIN | Filters to mirrors in In Alignment status (MirrorStatusID=3) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| MirrorCalculationApp (application service) | GRANT EXECUTE | Permission | The mirror calculation service monitors alignment state via this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsCountForMirrorsInAlignment (procedure)
├── Trade.PositionTbl (table)
└── Trade.Mirror (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | INNER JOIN source; filtered to StatusID=1 (open positions) |
| Trade.Mirror | Table | INNER JOIN on MirrorID; filtered to MirrorStatusID=3 (In Alignment) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| MirrorCalculationApp (application service) | External application | Reads the count to monitor how many open positions are under active alignment processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Execute the procedure

```sql
EXEC Trade.GetPositionsCountForMirrorsInAlignment;
```

### 8.2 Inline equivalent query with context

```sql
SELECT COUNT(1) AS PositionsCount
FROM Trade.PositionTbl pt WITH (NOLOCK)
INNER JOIN Trade.Mirror mr WITH (NOLOCK) ON pt.MirrorID = mr.MirrorID
WHERE pt.StatusID = 1
  AND mr.MirrorStatusID = 3; -- In Alignment
```

### 8.3 View which mirrors are in alignment with their position counts

```sql
SELECT mr.MirrorID, mr.CID AS CopierCID, mr.MirrorStatusID,
       COUNT(pt.PositionID) AS OpenPositions
FROM Trade.Mirror mr WITH (NOLOCK)
INNER JOIN Trade.PositionTbl pt WITH (NOLOCK) ON pt.MirrorID = mr.MirrorID AND pt.StatusID = 1
WHERE mr.MirrorStatusID = 3
GROUP BY mr.MirrorID, mr.CID, mr.MirrorStatusID
ORDER BY COUNT(pt.PositionID) DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.2/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsCountForMirrorsInAlignment | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsCountForMirrorsInAlignment.sql*
