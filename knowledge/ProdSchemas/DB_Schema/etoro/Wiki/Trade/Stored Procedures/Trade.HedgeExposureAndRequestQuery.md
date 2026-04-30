# Trade.HedgeExposureAndRequestQuery

> Returns per-instrument hedge exposure combined with pending open requests for a given hedge server, using a UNION LEFT+RIGHT JOIN pattern to achieve full outer join semantics.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @RequestValidSeconds; Joins: Trade.GetHedgeExposure + Trade.GetHedgeRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureAndRequestQuery provides the hedge server with a unified view of its current state: per-instrument net exposure (how much is unhedged) combined with whether an open hedge request is already pending for that instrument. This answers: "For each instrument, what is the net exposure gap AND is there already a pending open request in flight?"

The hedge server uses this combined view to decide what actions to take. If Difference != 0 but RequestPending=1, the hedge server knows a request is already in progress and should wait. If RequestPending=0 and Difference != 0, it needs to initiate a new hedge open request. If an open request exists in GetHedgeRequest (within the valid window) but GetHedgeExposure has no matching row, the instrument still appears (from the RIGHT JOIN side), so pending requests are never missed.

The `@RequestValidSeconds` parameter defines a recency window for pending requests. Requests submitted more than `@RequestValidSeconds` seconds ago are considered stale and excluded - preventing the hedge server from treating old, potentially orphaned requests as still "in flight".

The procedure uses a UNION of LEFT JOIN + RIGHT JOIN because SQL Server lacks a FULL OUTER JOIN shorthand in this query pattern; the UNION (with implicit DISTINCT) achieves the full outer join: instruments with only exposure (LEFT), instruments with both (both halves), and instruments with only pending requests (RIGHT).

---

## 2. Business Logic

### 2.1 Full Outer Join via UNION LEFT+RIGHT JOIN

**What**: Combines exposure gap data with pending request data for all instruments on a hedge server.

**Columns/Parameters Involved**: `@HedgeServerID`, `@RequestValidSeconds`, `InstrumentID`, `Difference`, `Opened`, `Hedged`, `RequestPending`

**Rules**:
- LEFT JOIN half: All exposure rows for @HedgeServerID LEFT JOINed to GetHedgeRequest WHERE Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE()) AND same InstrumentID + HedgeServerID. DISTINCT applied.
- RIGHT JOIN half: All requests within validity window RIGHT JOINed to GetHedgeExposure WHERE diffView.HedgeServerID = @HedgeServerID (ensures RIGHT side also scoped to this server).
- UNION merges both halves with implicit DISTINCT to eliminate any cross-contamination duplicates.
- RequestPending = 1 ONLY when InstrumentID IS NOT NULL from reqView AND RequestType = 1 (open request). RequestType=2 (close requests) do not trigger RequestPending.
- If no matching request exists (NULL reqView.InstrumentID), RequestPending = 0.
- Difference/Opened/Hedged come entirely from GetHedgeExposure (NULL if instrument only has a request but no exposure row).

**Diagram**:
```
HedgeExposureAndRequestQuery(@HedgeServerID, @RequestValidSeconds)
    |
    +-- LEFT JOIN half (exposure-anchored):
    |       FROM Trade.GetHedgeExposure diffView
    |       LEFT JOIN Trade.GetHedgeRequest reqView
    |           ON diffView.InstrumentID = reqView.InstrumentID
    |           AND diffView.HedgeServerID = reqView.HedgeServerID
    |           AND reqView.Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE())
    |       WHERE diffView.HedgeServerID = @HedgeServerID
    |       -> All exposure instruments; RequestPending=1 where open request exists
    |
    +-- UNION (DISTINCT)
    |
    +-- RIGHT JOIN half (request-anchored):
    |       FROM Trade.GetHedgeExposure diffView
    |       RIGHT JOIN Trade.GetHedgeRequest reqView
    |           ON same conditions
    |       WHERE diffView.HedgeServerID = @HedgeServerID
    |           AND reqView.Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE())
    |       -> Instruments with only a pending request (no exposure row); RequestPending=1
    |
    -> Combined: all instruments with exposure or active pending requests or both
```

### 2.2 Request Validity Window

**What**: `@RequestValidSeconds` scopes which pending requests are considered "still in flight".

**Rules**:
- Applied via: `reqView.Occurred >= DATEADD(ss, 0-@RequestValidSeconds, GETDATE())`
- Note: `0-@RequestValidSeconds` is equivalent to `-@RequestValidSeconds` (legacy style, not a bug).
- Typical usage: hedge server passes a window (e.g., 300 seconds = 5 minutes) to ignore stale requests that were never cleaned up.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server to query. Filters both Trade.GetHedgeExposure and Trade.GetHedgeRequest to this server. Corresponds to Trade.HedgeServer.HedgeServerID. |
| 2 | @RequestValidSeconds | INTEGER | NO | - | CODE-BACKED | Recency window in seconds. Only requests submitted within this window (Occurred >= now - @RequestValidSeconds) are considered pending. Prevents stale requests from showing as in-flight. |
| 3 | InstrumentID | INTEGER | YES | - | CODE-BACKED | Output. Financial instrument. NULL on the RIGHT JOIN side if GetHedgeExposure has no matching row (instrument with pending request but no computed exposure). |
| 4 | Difference | DECIMAL | YES | - | CODE-BACKED | Output. From Trade.GetHedgeExposure: Opened - Hedged. Net unhedged exposure in lots. NULL if the row came only from the RIGHT JOIN side (request with no exposure). |
| 5 | Opened | DECIMAL | YES | - | CODE-BACKED | Output. From Trade.GetHedgeExposure: net open position lots (buy - sell) for this instrument. NULL if no exposure row. |
| 6 | Hedged | DECIMAL | YES | - | CODE-BACKED | Output. From Trade.GetHedgeExposure: net hedge lots (buy - sell) for this instrument. NULL if no exposure row. |
| 7 | RequestPending | BIT (computed as 0/1) | NO | 0 | CODE-BACKED | Output. 1 if a RequestType=1 (open) request exists for this instrument within @RequestValidSeconds; 0 otherwise. Close requests (RequestType=2) do NOT set this flag. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID, InstrumentID | Trade.GetHedgeExposure | FROM / LEFT+RIGHT JOIN | Net exposure per instrument |
| @HedgeServerID, InstrumentID, Occurred | Trade.GetHedgeRequest | LEFT JOIN / RIGHT JOIN | Pending hedge requests within validity window |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Hedge server calls this to get a combined exposure+request picture per polling cycle |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureAndRequestQuery (procedure)
+-- Trade.GetHedgeExposure (view) [leaf for this SP]
|     +-- Trade.Position (view)
|     +-- Customer.Customer (x-schema table)
|     +-- Trade.Hedge (table)
|     +-- Trade.GetInstrument (view)
+-- Trade.GetHedgeRequest (view) [leaf for this SP]
      +-- Trade.HedgeRequest (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposure | View | Provides per-instrument exposure data (Difference, Opened, Hedged) |
| Trade.GetHedgeRequest | View | Provides pending hedge requests; joined on InstrumentID + HedgeServerID + Occurred |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Calls each polling cycle to determine which instruments need new hedge open requests |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. No transaction, no error handling, no DML. Pure SELECT UNION query. The UNION LEFT+RIGHT JOIN is the SQL Server idiom for a full outer join when dealing with view-based sources.

---

## 8. Sample Queries

### 8.1 Get exposure and request state for a hedge server (5-min validity window)

```sql
EXEC Trade.HedgeExposureAndRequestQuery
    @HedgeServerID = 24,
    @RequestValidSeconds = 300;
```

### 8.2 Find instruments needing new hedge requests (exposure gap, no pending request)

```sql
-- Instruments where Difference != 0 but no open request is pending
SELECT InstrumentID, Difference, Opened, Hedged
FROM (
    EXEC Trade.HedgeExposureAndRequestQuery @HedgeServerID = 24, @RequestValidSeconds = 300
) t
WHERE RequestPending = 0 AND ABS(Difference) > 0;
```

### 8.3 Verify current hedge exposure for a server directly

```sql
SELECT InstrumentID, HedgeServerID, Opened, Hedged, Difference
FROM Trade.GetHedgeExposure WITH (NOLOCK)
WHERE HedgeServerID = 24
  AND (ABS(Difference) > 0 OR Opened <> 0 OR Hedged <> 0);
```

### 8.4 Check pending requests that would affect RequestPending flag

```sql
SELECT HedgeID, InstrumentID, HedgeServerID, RequestType, Occurred
FROM Trade.GetHedgeRequest WITH (NOLOCK)
WHERE HedgeServerID = 24
  AND RequestType = 1
  AND Occurred >= DATEADD(ss, -300, GETDATE());
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureAndRequestQuery | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureAndRequestQuery.sql*
