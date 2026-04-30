# Trade.GetDailyActiveMirrors

> Identifies active copy-trade (mirror) relationships within a date range for US-regulated customers, returning MirrorID, CID, and parent trader username.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @StartDate + @EndDate (date range filter) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetDailyActiveMirrors finds all copy-trade (mirror) relationships that had trading activity within a specified date range, restricted to customers under US regulations. A mirror is considered "active" if any position was opened or closed during the period. This is used for US regulatory reporting on copy-trade activity.

This procedure exists because US regulations require specific reporting on copy-trade relationships. The procedure identifies mirrors that had real activity (not just passive holding) during the reporting window.

Data flow: First identifies US-regulated customers from BackOffice.Customer via Dictionary.Regulation (IsUSA=1). Then finds mirrors with activity in two ways: (1) positions closed during the range in History.PositionSlim with ActionType IN (9, 23) - copy-related close types, and (2) positions opened during the range in Trade.PositionTbl with OpenActionType IN (1, 16) and StatusID=1 - copy-related open types. Results are deduplicated via UNION and enriched with ParentUserName from Trade.Mirror.

---

## 2. Business Logic

### 2.1 US-Regulated Customer Scope

**What**: Restricts to customers under US regulation only.

**Columns/Parameters Involved**: `RegulationID`, `IsUSA`

**Rules**:
- BackOffice.Customer.RegulationID -> Dictionary.Regulation WHERE IsUSA=1
- Only US-regulated customers are included in the activity scan
- #CIDs temp table with clustered index for performance

### 2.2 Mirror Activity Detection

**What**: Identifies mirrors with real trading activity during the date range.

**Columns/Parameters Involved**: `ActionType`, `OpenActionType`, `MirrorID`, `@StartDate`, `@EndDate`

**Rules**:
- Closed positions: ActionType IN (9, 23) - copy-related close action types from History.PositionSlim
- Opened positions: OpenActionType IN (1, 16) AND StatusID=1 - copy-related open action types from Trade.PositionTbl
- Date filtering: CloseOccurred or Occurred within [@StartDate, @EndDate)
- UNION deduplicates across both sources

**Diagram**:
```
BackOffice.Customer -> Dictionary.Regulation (IsUSA=1)
  -> #CIDs (US customers)
  |
  +-- History.PositionSlim (closed copy positions in range)
  |     ActionType IN (9, 23)
  |
  +-- Trade.PositionTbl (opened copy positions in range)
  |     OpenActionType IN (1, 16), StatusID=1
  |
  UNION -> #ActiveMirrors (MirrorID, CID)
  |
  JOIN Trade.Mirror -> ParentUserName
  |
  Output: MirrorID, CID, ParentUserName
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

### Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @StartDate | datetime | NO | - | CODE-BACKED | Start of the reporting period (inclusive). |
| 2 | @EndDate | datetime | NO | - | CODE-BACKED | End of the reporting period (exclusive). |

### Output Columns

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | MirrorID | int | NO | - | CODE-BACKED | Copy-trade mirror relationship ID. FK to Trade.Mirror. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID of the copier (the customer who copies another trader). |
| 3 | ParentUserName | nvarchar | YES | - | CODE-BACKED | Username of the trader being copied (the "parent" in the copy relationship). From Trade.Mirror. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | BackOffice.Customer | FROM | Customer regulation lookup |
| RegulationID | Dictionary.Regulation | JOIN | US regulation filter (IsUSA=1) |
| CID | History.PositionSlim | JOIN | Closed copy positions in date range |
| CID | Trade.PositionTbl | JOIN | Open copy positions in date range |
| MirrorID | Trade.Mirror | JOIN | Mirror details including parent username |

### 5.2 Referenced By (other objects point to this)

No callers found in the SQL codebase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetDailyActiveMirrors (procedure)
+-- BackOffice.Customer (table)
+-- Dictionary.Regulation (table)
+-- History.PositionSlim (table)
+-- Trade.PositionTbl (table)
+-- Trade.Mirror (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| BackOffice.Customer | Table | FROM - US-regulated customer identification |
| Dictionary.Regulation | Table | JOIN - US regulation filter |
| History.PositionSlim | Table | CTE - closed copy positions in date range |
| Trade.PositionTbl | Table | CTE - opened copy positions in date range |
| Trade.Mirror | Table | JOIN - parent username enrichment |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (none found) | - | No SQL callers discovered |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Creates temp table indexes: clustered IX on #CIDs(CID) and #ActiveMirrors(MirrorID).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get daily active mirrors for yesterday

```sql
EXEC Trade.GetDailyActiveMirrors
    @StartDate = '2026-03-15',
    @EndDate = '2026-03-16';
```

### 8.2 Get active mirrors for a full month

```sql
EXEC Trade.GetDailyActiveMirrors
    @StartDate = '2026-02-01',
    @EndDate = '2026-03-01';
```

### 8.3 Inline check for US-regulated customers with copy activity

```sql
SELECT  DISTINCT m.MirrorID, m.ParentUserName
FROM    Trade.Mirror m WITH (NOLOCK)
INNER JOIN Trade.PositionTbl p WITH (NOLOCK) ON p.MirrorID = m.MirrorID
INNER JOIN BackOffice.Customer bc WITH (NOLOCK) ON p.CID = bc.CID
INNER JOIN Dictionary.Regulation r WITH (NOLOCK) ON bc.RegulationID = r.ID
WHERE   r.IsUSA = 1
        AND p.StatusID = 1
        AND p.OpenActionType IN (1, 16);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 7.8/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 5.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetDailyActiveMirrors | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetDailyActiveMirrors.sql*
