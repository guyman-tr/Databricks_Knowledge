# AffiliateCommission.RemoveClosedPositionFromEtoro

> Deletes a staging row from ClosedPositionFromEtoro after the position has been successfully ingested into the commission system via InsertClosedPosition.

| Property | Value |
|----------|-------|
| **Schema** | AffiliateCommission |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Deletes from ClosedPositionFromEtoro by ClosedPositionID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

RemoveClosedPositionFromEtoro is the cleanup step in the eToro closed-position ingestion flow. The ClosedPositionFromEtoro table serves as a staging area where closed positions are landed by an external data feed (typically via ADF or a direct push from the eToro trading platform). GetClosedPositionsFromEtoro reads these staging rows, InsertClosedPosition writes them into the canonical ClosedPosition table, and then this procedure removes the staging row to signal completion.

This staging-then-delete pattern decouples the external data feed from commission processing. If the commission engine is temporarily unavailable, positions accumulate in the staging table without being lost. Once each position is successfully promoted to the main table, the staging row is removed so it is not reprocessed on the next pickup cycle.

The procedure deletes by ClosedPositionID, which is the natural key for a closed position. This ensures the correct staging row is removed even if multiple positions arrive in rapid succession.

---

## 2. Business Logic

### 2.1 Staging Row Cleanup

**What**: Removes a single staging row after successful ingestion into the canonical table.

**Columns/Parameters Involved**: `@ClosedPositionID`, `ClosedPositionFromEtoro.ClosedPositionID`

**Rules**:
- DELETE FROM ClosedPositionFromEtoro WHERE ClosedPositionID = @ClosedPositionID
- Called only after InsertClosedPosition succeeds for this position
- If the row does not exist (already removed or never staged), the DELETE is a no-op
- One row removed per call (ClosedPositionID is unique in staging)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ClosedPositionID | bigint (IN) | NO | - | CODE-BACKED | The closed position identifier. Matches the ClosedPositionID column in the staging table. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ClosedPositionID | AffiliateCommission.ClosedPositionFromEtoro | WRITE (DELETE) | Removes the staging row by ClosedPositionID |

### 5.2 Referenced By (other objects point to this)

No callers found in schema. Called by the commission processing pipeline after InsertClosedPosition.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
AffiliateCommission.RemoveClosedPositionFromEtoro (procedure)
+-- AffiliateCommission.ClosedPositionFromEtoro (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| AffiliateCommission.ClosedPositionFromEtoro | Table | DELETE by ClosedPositionID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Commission pipeline) | External | Cleans staging table after position ingestion |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Remove a processed staging row
```sql
EXEC [AffiliateCommission].[RemoveClosedPositionFromEtoro] @ClosedPositionID = 500123
```

### 8.2 Check if a position is still in staging
```sql
SELECT ClosedPositionID, CID, OpenDate, CloseDate
FROM [AffiliateCommission].[ClosedPositionFromEtoro] WITH (NOLOCK)
WHERE ClosedPositionID = 500123
```

### 8.3 Monitor staging table backlog
```sql
SELECT COUNT(*) AS PendingPositions,
    MIN(CloseDate) AS OldestPosition,
    MAX(CloseDate) AS NewestPosition
FROM [AffiliateCommission].[ClosedPositionFromEtoro] WITH (NOLOCK)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-04-12 | Enriched: 2026-04-12 | Quality: 9.0/10 (Elements: 10/10, Logic: 8/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: AffiliateCommission.RemoveClosedPositionFromEtoro | Type: Stored Procedure | Source: fiktivo/AffiliateCommission/Stored Procedures/AffiliateCommission.RemoveClosedPositionFromEtoro.sql*
