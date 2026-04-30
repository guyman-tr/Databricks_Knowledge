# Trade.HedgeExposureWithNoRequests

> Guards hedge exposure computation: in detail mode, returns -1 (skip) if a valid pending request already exists for the instrument, otherwise executes Trade.HedgeExposureQuery to compute and log exposure. In summary mode, returns exposure for all instruments with no stale-only requests.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @RequestValidSeconds, @InstrumentID (optional), @HedgedInstrument (optional); Calls: Trade.HedgeExposureQuery (detail mode); Reads: Trade.GetHedgeExposure, Trade.GetHedgeRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureWithNoRequests is a **gating wrapper** around Trade.HedgeExposureQuery. Its primary purpose in detail mode is: "only compute exposure if no valid pending request already exists for this instrument." This prevents the hedge server from querying exposure and sending a new hedge open request when one is already in-flight.

The hedge server uses this SP instead of calling Trade.HedgeExposureQuery directly when it wants to avoid double-sending hedge open requests. The return code signals whether to proceed: 0 = exposure computed and returned; -1 = skip (existing valid request found).

**Return codes**:
- `0` = success (exposure data returned or summary returned)
- `-1` = existing valid request found for @InstrumentID; caller should NOT send a new hedge request

**Two modes**:
- **Summary mode** (`@InstrumentID IS NULL`): LEFT JOINs exposure with requests to return instruments without stale-only requests. Does not call Trade.HedgeExposureQuery; returns directly.
- **Detail mode** (`@InstrumentID specified`): Checks for existing valid request; if found returns -1; otherwise calls Trade.HedgeExposureQuery (which logs to HedgingBreakdownLog and returns exposure values).

---

## 2. Business Logic

### 2.1 Summary Mode - Exposure Filtered by Request State

**What**: Returns per-instrument exposure for the hedge server, joined with pending request state.

**Rules**:
- `FROM Trade.GetHedgeExposure THE LEFT JOIN Trade.GetHedgeRequest GHR ON THE.InstrumentID = GHR.InstrumentID`
- `WHERE THE.HedgeServerID = @HedgeServerID AND (GHR.InstrumentID IS NULL OR GHR.Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE()))`
- Includes: instruments with no pending request (GHR.InstrumentID IS NULL) OR instruments with a recent valid request (Occurred within validity window).
- Excludes: instruments that have ONLY stale requests (older than @RequestValidSeconds) - these would be orphaned requests that should be cleaned up.
- Note: LEFT JOIN is on InstrumentID only (not HedgeServerID). If requests exist for the same InstrumentID across multiple hedge servers, the join may produce extra rows. DISTINCT is absent.
- RETURN(0) after the SELECT.

### 2.2 Detail Mode - Guard Check + Conditional Execution

**What**: Returns -1 if valid request already pending; otherwise executes Trade.HedgeExposureQuery.

**Rules**:
- Step 1: `IF EXISTS (SELECT * FROM Trade.GetHedgeRequest WHERE HedgeServerID=@HedgeServerID AND InstrumentID=@InstrumentID AND Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE())) -> RETURN(-1)`
- If RETURN(-1): no exposure query, no logging, no result set returned. Caller knows to skip.
- Step 2 (only if no valid request): `EXEC Trade.HedgeExposureQuery @HedgeServerID, @InstrumentID, @HedgedInstrument`
  - This logs to History.HedgingBreakdownLog (EntryType=3) and returns (InstrumentID, Difference, Opened, Hedged).
- RETURN(0) after EXEC.

**Diagram**:
```
HedgeExposureWithNoRequests(@HedgeServerID, @RequestValidSeconds, @InstrumentID, @HedgedInstrument)
    |
    IF @InstrumentID IS NULL:
    |   -> SELECT THE.InstrumentID, Difference, Opened, Hedged
    |      FROM Trade.GetHedgeExposure THE
    |      LEFT JOIN Trade.GetHedgeRequest GHR ON THE.InstrumentID = GHR.InstrumentID
    |      WHERE THE.HedgeServerID=@HedgeServerID
    |        AND (GHR.InstrumentID IS NULL OR GHR.Occurred >= now-@RequestValidSeconds)
    |   -> RETURN(0)
    |
    ELSE:
    |   -> EXISTS? Trade.GetHedgeRequest WHERE HedgeServerID=@HedgeServerID
    |              AND InstrumentID=@InstrumentID AND Occurred >= now-@RequestValidSeconds
    |      -> YES: RETURN(-1) [valid request already in flight; skip]
    |      -> NO:  EXEC Trade.HedgeExposureQuery @HedgeServerID, @InstrumentID, @HedgedInstrument
    |              RETURN(0) [exposure computed and logged]
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server to query. Used in both existence check and Trade.HedgeExposureQuery call. |
| 2 | @RequestValidSeconds | INTEGER | NO | - | CODE-BACKED | Recency window in seconds. Requests older than this are considered stale; a stale-only instrument is not guarded. |
| 3 | @InstrumentID | INTEGER | YES | NULL | CODE-BACKED | NULL = summary mode. Non-NULL = detail mode: check for existing request, then conditionally compute exposure. |
| 4 | @HedgedInstrument | INTEGER | YES | NULL | CODE-BACKED | Passed through to Trade.HedgeExposureQuery as @HedgeInstrument. Stored in HedgingBreakdownLog.HedgedInstrument. |

**Return codes (via RETURN statement)**:
| Code | Meaning |
|------|---------|
| 0 | Success - summary returned OR detail exposure computed and returned |
| -1 | Valid pending request found for @InstrumentID - caller should skip sending new request |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.GetHedgeExposure | SELECT (summary mode) | Exposure per instrument |
| @InstrumentID | Trade.GetHedgeRequest | LEFT JOIN (summary) / EXISTS check (detail) | Pending request state |
| @HedgeServerID, @InstrumentID | Trade.HedgeExposureQuery | EXEC (detail mode, no pending request) | Delegates to for actual exposure computation |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Used as the preferred exposure query when idempotency is required (don't double-request) |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureWithNoRequests (procedure)
+-- Trade.GetHedgeExposure (view) [summary mode]
+-- Trade.GetHedgeRequest (view) [summary mode LEFT JOIN + detail mode EXISTS]
+-- Trade.HedgeExposureQuery (procedure) [detail mode - conditional EXEC]
      +-- Trade.Position (view)
      +-- Trade.Hedge (table)
      +-- Trade.ProviderToInstrument (table)
      +-- Trade.Provider (table)
      +-- History.HedgingBreakdownLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposure | View | Summary mode exposure |
| Trade.GetHedgeRequest | View | Summary mode LEFT JOIN; detail mode EXISTS check |
| Trade.HedgeExposureQuery | Procedure | Detail mode: delegated to for actual computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Preferred exposure query with deduplication guard |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. The summary mode LEFT JOIN is only on InstrumentID (not HedgeServerID), which could produce duplicate rows if multiple hedge servers have requests for the same instrument. No DISTINCT. Error handling: none (no TRY/CATCH).

---

## 8. Sample Queries

### 8.1 Detail mode - get exposure only if no request pending

```sql
DECLARE @result INT;
EXEC @result = Trade.HedgeExposureWithNoRequests
    @HedgeServerID = 24,
    @RequestValidSeconds = 300,
    @InstrumentID = 1,
    @HedgedInstrument = 1;
-- @result = 0: exposure was computed; @result = -1: skip (request in flight)
```

### 8.2 Summary mode - all instruments without stale-only requests

```sql
EXEC Trade.HedgeExposureWithNoRequests
    @HedgeServerID = 24,
    @RequestValidSeconds = 300;
```

### 8.3 Verify pending requests for a specific instrument

```sql
SELECT HedgeID, InstrumentID, HedgeServerID, RequestType, Occurred
FROM Trade.GetHedgeRequest WITH (NOLOCK)
WHERE HedgeServerID = 24
  AND InstrumentID = 1
  AND Occurred >= DATEADD(ss, -300, GETDATE());
-- Empty result -> HedgeExposureWithNoRequests would proceed with EXEC
-- Non-empty -> would RETURN(-1)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeExposureQuery) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureWithNoRequests | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureWithNoRequests.sql*
