# History.LastPostionOperationDateByCID

> Per-customer tracker recording the most recent position operation date and open position status, used to efficiently identify active trading customers for batch calculations and ranking jobs.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CID (int, CLUSTERED PK) |
| **Partition** | No (stored on DICTIONARY filegroup) |
| **Indexes** | 2 active (PK clustered on CID + NC on LastOperationDate) |

---

## 1. Business Meaning

History.LastPostionOperationDateByCID is a per-customer activity tracker that records, for each customer, the timestamp of their most recent position operation (open, close, or modification) and whether they currently have any open positions. With 152,064 customer records (85,782 with open positions as of March 2026), this is a live operational reference table - not a temporal history table despite living in the History schema.

This table enables batch jobs like `Trade.GetPartitionDrawDownActiveCustomers` and `Trade.GetRankingGainPartitionActiveCustomers` to efficiently filter for "active" customers (those with recent operations or open positions) without scanning the entire position tables. It serves as a materialized summary of customer activity status, maintained by `History.UpdateLastPostionOperationDataByCID` via MERGE operations.

The table is continuously updated as customers trade - the stored procedure merges new activity data into this table, upserting per CID. The NC index on `LastOperationDate` supports range queries for "customers active since date X", enabling time-windowed activity analysis.

Note: The name contains a typo "Postion" (missing an 'i') - this is present in the original DDL and is preserved throughout.

---

## 2. Business Logic

### 2.1 Activity Status Tracking

**What**: Maintains a single "most recent activity" record per customer for efficient active-customer filtering.

**Columns/Parameters Involved**: `CID`, `LastOperationDate`, `OpenPositionExists`

**Rules**:
- One row per CID (PK) - always the CURRENT state (not historical)
- LastOperationDate: updated to the most recent position operation timestamp whenever Trade.UpdateLastPostionOperationDataByCID runs
- OpenPositionExists: BIT flag - 1 = customer has at least one open position, 0 = all positions closed
- Updates via MERGE (upsert): existing CIDs update LastOperationDate and OpenPositionExists; new CIDs are inserted
- Live data shows most recent operations are from 2026-03-18, all with OpenPositionExists=TRUE - typical for active trading customers

**Diagram**:
```
Position events occur -> Trade position tables updated
         |
         v
History.UpdateLastPostionOperationDataByCID (scheduled job)
         |
         MERGE INTO History.LastPostionOperationDateByCID
         ON CID match:
           UPDATE: LastOperationDate, OpenPositionExists
         NO match:
           INSERT: new CID row
         |
         v
Batch jobs query LastPostionOperationDateByCID to filter active customers:
  WHERE LastOperationDate > @cutoff AND OpenPositionExists = 1
```

---

## 3. Data Overview

| CID | LastOperationDate | OpenPositionExists | Meaning |
|---|---|---|---|
| 14952810 | 2026-03-18 22:58:59 | TRUE | This customer's most recent trade was late evening March 18 - active trader with open positions |
| 25478197 | 2026-03-18 22:56:08 | TRUE | Similar pattern - active customer with open positions, recent activity |
| 14866508 | 2026-03-18 22:54:06 | TRUE | Multiple CIDs with same minute timestamp likely from a batch close/open cycle |
| 14866496 | 2026-03-18 22:54:06 | TRUE | Same batch moment as above - simultaneous operations on related accounts |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CID | int | NO | - | CODE-BACKED | Customer identifier. Primary key - one row per customer. References the eToro customer account system (same CID used across all trading tables). |
| 2 | LastOperationDate | datetime | YES | - | VERIFIED | UTC timestamp of the customer's most recent position operation (open, close, or modification). NULL for customers with no activity recorded yet. Updated by MERGE from History.UpdateLastPostionOperationDataByCID. NC index enables efficient date-range queries. |
| 3 | OpenPositionExists | bit | YES | - | VERIFIED | Whether the customer currently has at least one open position: 1 = has open positions, 0 = all positions closed. NULL for newly inserted customers before first update. Used to filter for "currently active" vs "historically active" customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | History.Customer | Implicit | Customer whose activity is being tracked. No FK constraint in DDL. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| History.UpdateLastPostionOperationDataByCID | CID | Writer - MERGE | The updater procedure that keeps this table current via upsert |
| Trade.GetPartitionDrawDownActiveCustomers | LastOperationDate, OpenPositionExists | Reader | Queries for active customers in drawdown partition calculations |
| Trade.GetRankingGainPartitionActiveCustomers | LastOperationDate, OpenPositionExists | Reader | Queries for active customers in gain ranking partition calculations |
| Monitor.LastPostionOperationDateByCID | ALL | Reader/Monitor | Monitoring procedure that checks the health/freshness of this table |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

---

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| History.UpdateLastPostionOperationDataByCID | Stored Procedure | Sole writer - MERGE to keep this table current |
| Trade.GetPartitionDrawDownActiveCustomers | Stored Procedure | Reader - filters active customers for drawdown analysis |
| Trade.GetRankingGainPartitionActiveCustomers | Stored Procedure | Reader - filters active customers for gain ranking |
| Monitor.LastPostionOperationDateByCID | Stored Procedure | Monitor - checks freshness of this table |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (PK unnamed) | CLUSTERED (PK) | CID ASC | - | - | Active |
| IX | NONCLUSTERED | LastOperationDate ASC | - | - | Active |

### 7.2 Constraints

None beyond the PK.

---

## 8. Sample Queries

### 8.1 Find customers active in the last 30 days with open positions
```sql
SELECT
    CID,
    LastOperationDate,
    OpenPositionExists
FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
WHERE LastOperationDate > DATEADD(day, -30, GETDATE())
  AND OpenPositionExists = 1
ORDER BY LastOperationDate DESC
```

### 8.2 Find customers who had positions but are now fully closed
```sql
SELECT
    CID,
    LastOperationDate
FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
WHERE OpenPositionExists = 0
  AND LastOperationDate > DATEADD(month, -3, GETDATE())
ORDER BY LastOperationDate DESC
```

### 8.3 Count active vs inactive customers
```sql
SELECT
    OpenPositionExists,
    COUNT(*) AS CustomerCount,
    MIN(LastOperationDate) AS EarliestActivity,
    MAX(LastOperationDate) AS MostRecentActivity
FROM History.LastPostionOperationDateByCID WITH (NOLOCK)
GROUP BY OpenPositionExists
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.LastPostionOperationDateByCID | Type: Table | Source: etoro/etoro/History/Tables/History.LastPostionOperationDateByCID.sql*
