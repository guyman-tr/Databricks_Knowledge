# Trade.PositionsHedgeServerChangeLog_INT_2021Junk

> Archived hedge server change log from 2021 using int PositionID (pre-bigint migration). Kept in SSDT for schema reference; table does not exist in live database.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | (OperationSummaryID, PositionID) |
| **Partition** | HISTORY filegroup |
| **Live DB** | Does not exist (dropped from live, only in SSDT) |
| **Indexes** | PK clustered, IDX_TPHSCL_ADM_DATE |

---

## 1. Business Meaning

Trade.PositionsHedgeServerChangeLog_INT_2021Junk is an archived version of the hedge server change log that predates the PositionID bigint migration. The "_INT_2021Junk" suffix indicates it stored data from 2021 using `int` for PositionID, before the schema was updated to `bigint`. "Junk" in the name denotes disposable historical data kept only in SSDT for schema reference.

Each row records one position's migration from one hedge server (FromHedgeServerID) to another (ToHedgeServerID), with optional root-level server IDs and RuleID. All rows link to a parent summary via OperationSummaryID -> Trade.PositionsHedgeServerChangeSummaryLog(ID). The current Trade.PositionsHedgeServerChangeLog uses `bigint` PositionID and has replaced this table.

The table does not exist in live production; it was dropped after migration. SSDT retains the definition for historical and migration documentation.

---

## 2. Business Logic

### 2.1 Operation Summary Link

**What**: Every detail row references a parent bulk operation.

**Columns/Parameters Involved**: `OperationSummaryID`

**Rules**:
- OperationSummaryID is an FK to Trade.PositionsHedgeServerChangeSummaryLog(ID)
- Each summary row groups multiple position changes from a single reroute batch

### 2.2 int vs bigint PositionID

**What**: This archive used int PositionID; the current Trade.PositionsHedgeServerChangeLog uses bigint.

**Columns/Parameters Involved**: `PositionID`

**Rules**:
- PositionID is int here (historical limit). Live system migrated to bigint.

---

## 3. Data Overview

| OperationSummaryID | PositionID | ADM_DATE | FromHedgeServerID | ToHedgeServerID | Meaning |
|-------------------|------------|----------|-------------------|-----------------|---------|
| N/A | - | - | - | - | Table not in live. No rows. Historical schema only. |

**Note**: This table does not exist in the live database. Data, if any, would have been archived before the table was dropped.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OperationSummaryID | int | NO | - | CODE-BACKED | FK to Trade.PositionsHedgeServerChangeSummaryLog(ID). Groups per-position changes. |
| 2 | PositionID | int | NO | - | CODE-BACKED | Position identifier (int - pre-bigint). Historical schema. |
| 3 | ADM_DATE | datetime | NO | getutcdate() | CODE-BACKED | When this change was logged. |
| 4 | FromHedgeServerID | int | NO | - | CODE-BACKED | Source hedge server before migration. |
| 5 | ToHedgeServerID | int | NO | - | CODE-BACKED | Target hedge server after migration. |
| 6 | FromRootHedgeServerID | int | YES | - | NAME-INFERRED | Root-level source hedge server. |
| 7 | ToRootHedgeServerID | int | YES | - | NAME-INFERRED | Root-level target hedge server. |
| 8 | RuleID | int | YES | - | NAME-INFERRED | Rule that triggered or governed the migration. |

---

## 5. Relationships

### 5.1 References To

- Trade.PositionsHedgeServerChangeSummaryLog (OperationSummaryID -> ID) - Parent operation summary

### 5.2 Referenced By

- None in live (table dropped). SSDT only.

---

## 6. Dependencies

### 6.0 Dependency Chain

Trade.PositionsHedgeServerChangeSummaryLog -> Trade.PositionsHedgeServerChangeLog_INT_2021Junk (SSDT only)

### 6.1 Objects This Depends On

Trade.PositionsHedgeServerChangeSummaryLog

### 6.2 Objects That Depend On This

None (table not in live).

---

## 7. Technical Details

### 7.1 Indexes

- PK_TradePositionsHedgeServerChangeLog: CLUSTERED (OperationSummaryID, PositionID) WITH DATA_COMPRESSION=PAGE ON [HISTORY]
- IDX_TPHSCL_ADM_DATE: NC (ADM_DATE) ON [HISTORY]

### 7.2 Constraints

- PK_TradePositionsHedgeServerChangeLog: PRIMARY KEY (OperationSummaryID, PositionID)
- FK: OperationSummaryID -> Trade.PositionsHedgeServerChangeSummaryLog(ID)

---

*Generated: 2026-03-14 | Quality: 6.5/10*
