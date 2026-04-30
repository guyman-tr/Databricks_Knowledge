# History.UpdateLastPostionOperationDataByCID

> Near-real-time maintenance procedure that refreshes History.LastPostionOperationDateByCID for all customers with trading activity in the last 2 days - aggregating max open/close dates from Trade.PositionTbl (open positions) and History.PositionSlim (recent closed positions) and upserting via MERGE.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | N/A - no parameters; processes all customers active in the last 2 days |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`History.UpdateLastPostionOperationDataByCID` is a near-real-time refresh job that maintains the `History.LastPostionOperationDateByCID` lookup table. That table stores, for each customer, their most recent position operation date and whether they currently have open positions - enabling batch jobs like `Trade.GetPartitionDrawDownActiveCustomers` and `Trade.GetRankingGainPartitionActiveCustomers` to efficiently filter for active trading customers.

The procedure runs without parameters and uses a 2-day lookback window (getdate()-2). It aggregates data from two sources:
1. **Trade.PositionTbl**: Currently open positions (StatusID=1) opened in the last 2 days - provides OpenOccurred (open date) and optionally CloseOccurred (for positions with pending close)
2. **History.PositionSlim**: Recent closed positions with OpenOccurred or CloseOccurred in the last 2 days

The two sources are combined, MAX dates taken per CID, and the result is MERGEd into `History.LastPostionOperationDateByCID` (upsert). OpenPositionExists=1 is set for customers whose CID appears in the recent open-position set (#a); all others get NULL.

**Important scope limitation**: Only customers with activity in the last 2 days are processed. Customers with open positions from more than 2 days ago are NOT updated by this procedure. The `OpenPositionExists` flag is 1 only for customers with positions opened within the last 2 days - older open positions do not set this flag.

Note: The name contains the original DDL typo "Postion" (not "Position") preserved throughout all identifiers.

Data flow: (1) SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED for all reads; (2) SELECT max dates per CID from Trade.PositionTbl (last 2 days, StatusID=1) into #a + UNIQUE CLUSTERED INDEX; (3) SELECT max dates per CID from History.PositionSlim (last 2 days) into #b; (4) UNION ALL #a and #b -> MAX per CID into #c + UNIQUE CLUSTERED INDEX; (5) compute LastOperationDate=MAX(OpenOccurred,CloseOccurred) + OpenPositionExists via OUTER APPLY on #a into #CID + UNIQUE CLUSTERED INDEX; (6) MERGE into History.LastPostionOperationDateByCID; (7) END.

---

## 2. Business Logic

### 2.1 Data Sources and 2-Day Window

**What**: Two complementary sources cover open and recently-closed positions.

**Columns/Parameters Involved**: `Trade.PositionTbl.Occurred`, `Trade.PositionTbl.StatusID`, `History.PositionSlim.OpenOccurred`, `History.PositionSlim.CloseOccurred`

**Rules**:
- Trade.PositionTbl filter: `Occurred > getdate()-2 AND StatusID=1` - open positions opened in last 2 days
  - OpenOccurred = MAX(Occurred), CloseOccurred = ISNULL(MAX(CloseOccurred), '2010-01-01')
  - CloseOccurred defaults to '2010-01-01' for positions with no close date (NULL) yet
- History.PositionSlim filter: `OpenOccurred > getdate()-2 OR CloseOccurred > getdate()-2` - any position with recent open or close
  - OpenOccurred = MAX(OpenOccurred), CloseOccurred = MAX(CloseOccurred)
- UNION ALL then MAX per CID to combine both sources

### 2.2 LastOperationDate Derivation

**What**: The most recent position operation date is whichever of OpenOccurred or CloseOccurred is later.

**Columns/Parameters Involved**: `OpenOccurred`, `CloseOccurred`, `LastOperationDate`

**Rules**:
- `CASE WHEN OpenOccurred > CloseOccurred THEN OpenOccurred ELSE CloseOccurred END`
- Handles the case where CloseOccurred is '2010-01-01' (default) for pure open positions - OpenOccurred will be more recent

### 2.3 OpenPositionExists Determination

**What**: Indicates whether the customer has an open position that was opened in the last 2 days.

**Columns/Parameters Involved**: `OpenPositionExists`, `#a` (Trade.PositionTbl recent open positions)

**Rules**:
- OUTER APPLY: `SELECT TOP 1 1 AS OpenPositionExists FROM #a WHERE a.CID = b.CID`
- Returns 1 if the customer's CID exists in #a (has a recently-opened open position)
- Returns NULL if not in #a (no open position opened in last 2 days)
- **Scope limitation**: Only positions opened in the last 2 days qualify; older open positions do NOT set OpenPositionExists=1

### 2.4 MERGE Upsert Pattern

**What**: #CID data is merged into History.LastPostionOperationDateByCID as an upsert (insert or update).

**Columns/Parameters Involved**: `History.LastPostionOperationDateByCID.CID`, `LastOperationDate`, `OpenPositionExists`

**Rules**:
- WHEN MATCHED: UPDATE LastOperationDate and OpenPositionExists
- WHEN NOT MATCHED: INSERT (CID, LastOperationDate, OpenPositionExists) - new customer in the table
- READ UNCOMMITTED on source tables; MERGE itself runs at standard isolation

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. It operates on all recently-active customers via the 2-day lookback filter.

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Occurred, StatusID | Trade.PositionTbl | READER | Reads recent open positions (last 2 days, StatusID=1) for OpenOccurred and CloseOccurred |
| OpenOccurred, CloseOccurred | History.PositionSlim | READER (view) | Reads recent closed positions (last 2 days by either date) |
| CID, LastOperationDate, OpenPositionExists | History.LastPostionOperationDateByCID | MERGE (UPSERT) | Target table - upserts per-customer activity summary |

### 5.2 Referenced By (other objects point to this)

No callers found in SSDT repository. Called by a scheduled background job.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.UpdateLastPostionOperationDataByCID (procedure)
+-- Trade.PositionTbl (table, cross-schema)
+-- History.PositionSlim (view)
|     +-- History.Position_Active, History.Position_Active_BIGINT, History.Position_Active_New
+-- History.LastPostionOperationDateByCID (table - MERGE target)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table (cross-schema) | SELECT open positions (StatusID=1) opened in last 2 days for open date and OpenPositionExists flag |
| History.PositionSlim | View | SELECT closed positions with recent open or close dates |
| History.LastPostionOperationDateByCID | Table | MERGE target for upserted CID activity data |

### 6.2 Objects That Depend On This

No dependents found in SSDT repository.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| READ UNCOMMITTED | Isolation | SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED for all reads; accepts dirty reads for performance |
| 2-day lookback window | Scope | Only customers with activity in last 2 days are processed; older open positions are not refreshed |
| OpenPositionExists scope | Behavioral | Only positions opened in the last 2 days qualify for OpenPositionExists=1; older positions do not count |
| CloseOccurred default '2010-01-01' | Fallback | ISNULL on Trade.PositionTbl.CloseOccurred sets '2010-01-01' to ensure it's always lower than OpenOccurred for pure-open positions |
| Unique clustered indexes on temp tables | Performance | Three temp tables (#a, #c, #CID) each get UNIQUE CLUSTERED INDEX on CID for efficient MERGE and OUTER APPLY |
| MERGE upsert | Idempotency | Safe to run multiple times; WHEN MATCHED updates, WHEN NOT MATCHED inserts - no duplicate risk |
| Typo "Postion" | DDL | All identifiers (table name, procedure name) use "Postion" not "Position" - preserved from original DDL |

---

## 8. Sample Queries

### 8.1 Execute the refresh

```sql
EXEC History.UpdateLastPostionOperationDataByCID
```

### 8.2 Check customers updated in the last refresh

```sql
SELECT COUNT(*) AS UpdatedCustomers,
       SUM(CASE WHEN OpenPositionExists = 1 THEN 1 ELSE 0 END) AS WithOpenPositions,
       MIN(LastOperationDate) AS EarliestActivity,
       MAX(LastOperationDate) AS LatestActivity
FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
WHERE LastOperationDate > DATEADD(day, -2, GETDATE())
```

### 8.3 Find active customers for batch jobs

```sql
SELECT CID, LastOperationDate, OpenPositionExists
FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
WHERE LastOperationDate > DATEADD(day, -7, GETDATE())
ORDER BY LastOperationDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 8.5/10, Logic: 9.5/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 16 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5 (1,5,8,9,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.UpdateLastPostionOperationDataByCID | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.UpdateLastPostionOperationDataByCID.sql*
