# History.GetHistoryDataForAll

> Orchestrator for the HistoryData bulk-export family: routes a date range query to one of four age-optimized shard procedures based on the number of calendar days in the range.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FromDate/@ToDate; routes to 1To3Days, 4To9Days, 10To19Days, or MoreThen20Days based on DATEDIFF |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **entry point and router** for the legacy `GetHistoryDataForAll*` family. Callers pass a date range (`@FromDate`, `@EndDate`) and this procedure calculates the number of calendar days (`DATEDIFF(dd,...)`) and dispatches to the appropriate age-range shard. The sharding strategy allows each variant to be independently optimized (query plan, index hints) for its expected data volume.

The header comment `// public List<HistoryDataForAll> getHistoryReportForAll(string db, DateTime from, DateTime to)` identifies this as the Java/.NET web service method `getHistoryReportForAll` - the API entry point for bulk closed-position exports.

---

## 2. Business Logic

### 2.1 Age-Based Routing

**What**: Routes to one of four shard procedures based on `DATEDIFF(dd, @FromDate, @EndDate)`.

**Routing table**:

| NumOfDays | Routed To | Credit Source |
|-----------|-----------|---------------|
| < 4 | History.GetHistoryDataForAll1To3Days | History.ActiveCredit |
| >= 4 AND < 10 | History.GetHistoryDataForAll4To9Days | History.Credit |
| >= 10 AND < 20 | History.GetHistoryDataForAll10To19Days | History.Credit |
| >= 20 | History.GetHistoryDataForAllMoreThen20Days | History.Credit |
| Negative (fallback) | History.GetHistoryDataForAll1To3Days WITH RECOMPILE | Empty result |

**Why different shards**: Positions aged 0-3 days may still have credits in `History.ActiveCredit` (not yet migrated to `History.Credit`). The 1To3Days variant handles this edge case. The other three shards are structurally identical but kept separate for potential per-shard tuning.

### 2.2 Fallback Empty Result

**What**: If `@FromDate > @EndDate` (negative day count), no IF branch matches. Procedure falls through to `EXEC History.GetHistoryDataForAll1To3Days WITH RECOMPILE` (no parameters).

**Rules**: `WITH RECOMPILE` and no `@FromDate/@ToDate` parameters - the shard executes with NULL date parameters, returning an empty result set (no positions match NULL date filter).

Comment: `--If I got here then there is a good chance that @FromDate was greater then @EndDate. In that case I still return an empty recordset`

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATETIME | NO | - | CODE-BACKED | Start of CloseOccurred date range. Used to compute @NumOfDays and passed to the selected shard. |
| 2 | @EndDate | DATETIME | NO | - | CODE-BACKED | End of CloseOccurred date range. Note parameter name is @EndDate here (vs @ToDate in the shard procedures). |

**Result set columns**: Inherited from the routed shard procedure. All four shards return the same 25-column schema (PositionID, GameName, IsBuy, CurrencyBuy/Sell, Abbreviations, TypeIDs, OpenDate, CloseDate, Amount, Units, OpenRate, CloseRate, Spread, Profit, Gain, LimitRate, StopRate, CID, ParentPositionID, OrigParentPositionID, MirrorID, Leverage, Credit, CloseOnEndOfWeek).

Exception: When routed to `GetHistoryDataForAll1To3Days`, `GameName` is always `''` (empty string).

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| EXEC | History.GetHistoryDataForAll1To3Days | Procedure call | Routed when NumOfDays < 4; also used as empty-result fallback. |
| EXEC | History.GetHistoryDataForAll4To9Days | Procedure call | Routed when NumOfDays 4-9. |
| EXEC | History.GetHistoryDataForAll10To19Days | Procedure call | Routed when NumOfDays 10-19. |
| EXEC | History.GetHistoryDataForAllMoreThen20Days | Procedure call | Routed when NumOfDays >= 20. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Legacy HistoryData API (application) | EXEC | Direct call | getHistoryReportForAll web service method for bulk closed position export. |
| PROD\BIadmins | VIEW DEFINITION | Monitoring | BI admins can inspect the definition. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.GetHistoryDataForAll (procedure)
├── History.GetHistoryDataForAll1To3Days (procedure)
├── History.GetHistoryDataForAll4To9Days (procedure)
├── History.GetHistoryDataForAll10To19Days (procedure)
└── History.GetHistoryDataForAllMoreThen20Days (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.GetHistoryDataForAll1To3Days | Procedure | Delegate for 0-3 day ranges and fallback. |
| History.GetHistoryDataForAll4To9Days | Procedure | Delegate for 4-9 day ranges. |
| History.GetHistoryDataForAll10To19Days | Procedure | Delegate for 10-19 day ranges. |
| History.GetHistoryDataForAllMoreThen20Days | Procedure | Delegate for 20+ day ranges. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Legacy HistoryData API (application) | External | Bulk history export entry point. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses rowcount messages from the EXEC'd shard. |
| Parameter name mismatch | Caller note | This procedure accepts @EndDate; the shard procedures accept @ToDate. The orchestrator passes positionally, not by name. |
| No validation | Design | No check that @FromDate <= @EndDate before computing DATEDIFF. Relies on fallback for invalid ranges. |

---

## 8. Sample Queries

### 8.1 Get history for various range sizes

```sql
-- 2-day range -> routes to 1To3Days
EXEC History.GetHistoryDataForAll @FromDate = '2026-03-19', @EndDate = '2026-03-21';

-- 7-day range -> routes to 4To9Days
EXEC History.GetHistoryDataForAll @FromDate = '2026-03-14', @EndDate = '2026-03-21';

-- Monthly range -> routes to MoreThen20Days
EXEC History.GetHistoryDataForAll @FromDate = '2026-02-01', @EndDate = '2026-02-28';
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/11 (1, 5, 8, 10, 11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.GetHistoryDataForAll | Type: Stored Procedure | Source: etoro/etoro/History/Stored Procedures/History.GetHistoryDataForAll.sql*
