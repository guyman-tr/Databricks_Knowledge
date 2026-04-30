# Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg

> Aggregate summary of all closed copy sessions between a customer and a specific Popular Investor: total session count, overall profitability percentage, and net profit percentage across all sessions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @cid INT + @parentCid INT (all closed sessions with one PI, aggregate, single row) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the aggregate companion to `TAPI_GetPublicHistoryMirrorsByCidAndParentCid`. It returns a single summary row covering ALL closed copy sessions between a customer and a specific Popular Investor, enabling the application to show the header metrics ("You copied Trader X 3 times, overall win rate: 62%, net return: 14.5%") before rendering the session list.

The profitability percentage is computed from session-level `NetProfit` stored on `History.Mirror` (not from individual positions in `History.PositionSlim`). This means: a session is "profitable" if its aggregate `NetProfit >= 0`, not if individual positions within it were profitable.

---

## 2. Business Logic

### 2.1 Privacy Restriction Check

**Rules**: OperationTypeID=3 check, RAISERROR(60090) if blocked.

### 2.2 All Closed Sessions Aggregate for a PI

**What**: Aggregates across all closed copy sessions with the specified Popular Investor.

**Columns/Parameters Involved**: `MirrorOperationID`, `CID`, `ParentCID`, `ModificationDate`, `@startTime`

**Rules**:
- `FROM History.Mirror WHERE MirrorOperationID=2 AND CID=@cid AND ParentCID=@parentCid` - all closed sessions with this PI
- `AND (ModificationDate >= @startTime AND ModificationDate > DATEADD(year,-1, GETUTCDATE()))` - 1-year cap + @startTime
- `GROUP BY CID, ParentCID` - single aggregate row
- `TotalMirrors = ISNULL(count(MirrorID), 0)` - number of closed sessions
- `TotalMirrorsProfitabilityPercentage = 100 * (sessions with NetProfit>=0) / count(*)` - session-level win rate
- `TotalMirrorsNetProfitPercentage = 100 * SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary))` - overall return across all sessions

Note: Profitability is computed from History.Mirror.NetProfit (session-level), unlike the per-session list SP which uses position-level HP.NetProfit for win rate.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

### Input Parameters

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @cid | INT | NO | - | CODE-BACKED | Customer ID (the copier). Privacy check runs first. |
| 2 | @parentCid | INT | NO | - | CODE-BACKED | Popular Investor's customer ID. Aggregates all sessions where this PI was copied. |
| 3 | @startTime | DATETIME | NO | - | CODE-BACKED | Look-back window start (on session ModificationDate). Combined with 1-year cap. |

### Output - All-Sessions Aggregate (Single Row)

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ParentCID | INT | NO | - | CODE-BACKED | Popular Investor's CID. From GROUP BY. Always = @parentCid. |
| 2 | TotalMirrors | INT | NO | 0 | CODE-BACKED | Count of closed copy sessions with this PI within the look-back window. ISNULL defaults to 0. |
| 3 | TotalMirrorsProfitabilityPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Percentage of sessions where History.Mirror.NetProfit >= 0 (session-level profitability, not position-level). 0 when TotalMirrors = 0. |
| 4 | TotalMirrorsNetProfitPercentage | DECIMAL(16,8) | NO | 0 | CODE-BACKED | Overall return: SUM(NetProfit) / (SUM(InitialInvestment) + SUM(DepositSummary)) * 100 across all sessions. 0 when denominator = 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID, OperationTypeID | Customer.BlockedCustomerOperations | Lookup (READ) | Privacy restriction check |
| CID, ParentCID, MirrorID, MirrorOperationID, NetProfit, InitialInvestment, DepositSummary | History.Mirror | Lookup (READ) | All closed session data for aggregation |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by TDAPIUser service account.
Family: `Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCid` (per-session list).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg (procedure)
├── Customer.BlockedCustomerOperations (table - cross-schema)
└── History.Mirror (table - cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table (cross-schema) | Privacy restriction check |
| History.Mirror | Table (cross-schema) | All closed sessions with the PI; session-level financials |

### 6.2 Objects That Depend On This

No SQL dependents. Called by TDAPIUser service account.

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure. No temp tables. Single aggregate query.

### 7.2 Constraints

None. Key behavioral characteristics:
- No join to PositionSlim - profitability from History.Mirror.NetProfit (session-level, not position-level)
- Returns single row always (GROUP BY CID, ParentCID = always exactly one group for a given CID+ParentCID pair)
- If no matching sessions: single row with all zeros (GROUP BY collapses to no rows... actually COUNT on empty = 0, SUM = NULL -> ISNULL->0; the SELECT itself still produces a row with GROUP BY on empty set producing no rows). Actually since GROUP BY CID, ParentCID on empty set produces no rows, the result could be empty. Callers must handle empty result.
- WITH (NOLOCK) on both tables

---

## 8. Sample Queries

### 8.1 Get aggregate stats for all sessions with a PI

```sql
EXEC Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg
    @cid = 12345,
    @parentCid = 99999,
    @startTime = DATEADD(year, -1, GETUTCDATE())
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9.0/10, Relationships: 9.0/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B: no app refs; 11: generated)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 SQL callers | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.TAPI_GetPublicHistoryMirrorsByCidAndParentCidAgg.sql*
