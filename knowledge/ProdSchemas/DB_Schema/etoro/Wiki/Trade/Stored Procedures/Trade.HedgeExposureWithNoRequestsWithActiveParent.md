# Trade.HedgeExposureWithNoRequestsWithActiveParent

> Active-parent variant of Trade.HedgeExposureWithNoRequests. Guards hedge exposure computation: in detail mode, returns -1 if a valid pending request exists; otherwise executes Trade.HedgeExposureQueryWithActiveParent (which excludes orphaned child positions). Summary mode uses Trade.GetHedgeExposureWithActiveParent.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Input: @HedgeServerID, @RequestValidSeconds, @InstrumentID (optional), @HedgedInstrument (optional); Calls: Trade.HedgeExposureQueryWithActiveParent (detail mode); Reads: Trade.GetHedgeExposureWithActiveParent, Trade.GetHedgeRequest |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.HedgeExposureWithNoRequestsWithActiveParent is the **active-parent variant** of Trade.HedgeExposureWithNoRequests. It is structurally identical except it uses:
- `Trade.GetHedgeExposureWithActiveParent` (instead of `Trade.GetHedgeExposure`) in summary mode
- `Trade.HedgeExposureQueryWithActiveParent` (instead of `Trade.HedgeExposureQuery`) in detail mode

The active-parent filter excludes orphaned child copy-trade positions (positions whose parent is no longer in Trade.Position). This produces a more conservative (lower) exposure estimate that excludes stale copy-trade artifacts.

Return codes and gating logic are identical to Trade.HedgeExposureWithNoRequests:
- `-1` = valid pending request found; caller should skip
- `0` = success (summary or detail exposure returned)

Use this variant when accurate hedge decisions require clean exposure data free from both stale pending requests AND orphaned copy-trade positions.

---

## 2. Business Logic

### 2.1 Summary Mode - Active-Parent-Filtered Exposure

**What**: Returns exposure from active-parent view, filtered by request state.

**Rules**:
- `FROM Trade.GetHedgeExposureWithActiveParent THE LEFT JOIN Trade.GetHedgeRequest GHR ON THE.InstrumentID = GHR.InstrumentID`
- `WHERE THE.HedgeServerID = @HedgeServerID AND (GHR.InstrumentID IS NULL OR GHR.Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE()))`
- Identical WHERE logic to Trade.HedgeExposureWithNoRequests.
- RETURN(0) after SELECT.
- The view applies both demo exclusion (PlayerLevelID<>4) and orphan exclusion (active parent check).

### 2.2 Detail Mode - Guard + Active-Parent Exposure Query

**What**: Checks for existing valid request; if none, executes active-parent variant of exposure query.

**Rules**:
- Step 1: `IF EXISTS (SELECT * FROM Trade.GetHedgeRequest WHERE HedgeServerID=@HedgeServerID AND InstrumentID=@InstrumentID AND Occurred >= DATEADD(ss, -@RequestValidSeconds, GETDATE())) -> RETURN(-1)`
- Step 2 (only if no valid request): `EXEC Trade.HedgeExposureQueryWithActiveParent @HedgeServerID, @InstrumentID, @HedgedInstrument`
  - Computes exposure excluding orphaned child positions + logs to History.HedgingBreakdownLog (EntryType=3).
- RETURN(0) after EXEC.

**Key difference from Trade.HedgeExposureWithNoRequests**: Same guard logic, different exposure computation (with active-parent filter applied in the EXEC call).

**Diagram**:
```
HedgeExposureWithNoRequestsWithActiveParent(@HedgeServerID, @RequestValidSeconds, @InstrumentID, @HedgedInstrument)
    |
    IF @InstrumentID IS NULL:
    |   -> SELECT THE.InstrumentID, Difference, Opened, Hedged
    |      FROM Trade.GetHedgeExposureWithActiveParent THE  (not GetHedgeExposure!)
    |      LEFT JOIN Trade.GetHedgeRequest GHR ON THE.InstrumentID = GHR.InstrumentID
    |      WHERE THE.HedgeServerID=@HedgeServerID
    |        AND (GHR.InstrumentID IS NULL OR GHR.Occurred >= now-@RequestValidSeconds)
    |   -> RETURN(0)
    |
    ELSE:
    |   -> EXISTS? Trade.GetHedgeRequest WHERE valid request for @InstrumentID
    |      -> YES: RETURN(-1)
    |      -> NO:  EXEC Trade.HedgeExposureQueryWithActiveParent  (not HedgeExposureQuery!)
    |              RETURN(0)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INTEGER | NO | - | CODE-BACKED | Hedge server to query. Same as Trade.HedgeExposureWithNoRequests. |
| 2 | @RequestValidSeconds | INTEGER | NO | - | CODE-BACKED | Recency window in seconds for request validity check. Same as Trade.HedgeExposureWithNoRequests. |
| 3 | @InstrumentID | INTEGER | YES | NULL | CODE-BACKED | NULL = summary mode with active-parent view. Non-NULL = detail mode with active-parent guard. |
| 4 | @HedgedInstrument | INTEGER | YES | NULL | CODE-BACKED | Passed to HedgeExposureQueryWithActiveParent. Stored in HedgingBreakdownLog.HedgedInstrument. |

**Return codes (via RETURN statement)**:
| Code | Meaning |
|------|---------|
| 0 | Success - summary returned OR detail exposure computed |
| -1 | Valid pending request found - caller should skip |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @HedgeServerID | Trade.GetHedgeExposureWithActiveParent | SELECT (summary mode) | Active-parent-filtered exposure view |
| @InstrumentID | Trade.GetHedgeRequest | LEFT JOIN (summary) / EXISTS (detail) | Pending request state |
| @HedgeServerID, @InstrumentID | Trade.HedgeExposureQueryWithActiveParent | EXEC (detail mode) | Delegates to for exposure with orphan exclusion |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge Server (external) | - | Called by external system | Conservative exposure query with deduplication guard for orphan-free calculations |
| PROD_BIadmins | GRANT EXECUTE | Permission | BI analytics team has execute rights |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.HedgeExposureWithNoRequestsWithActiveParent (procedure)
+-- Trade.GetHedgeExposureWithActiveParent (view) [summary mode]
+-- Trade.GetHedgeRequest (view) [summary LEFT JOIN + detail EXISTS]
+-- Trade.HedgeExposureQueryWithActiveParent (procedure) [detail mode - conditional EXEC]
      +-- Trade.GetHedgeExposureWithActiveParent (view)
      +-- Trade.Position (view) - with self-join active parent check
      +-- Trade.Hedge (table)
      +-- Trade.ProviderToInstrument (table)
      +-- Trade.Provider (table)
      +-- History.HedgingBreakdownLog (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetHedgeExposureWithActiveParent | View | Summary mode exposure with orphan exclusion |
| Trade.GetHedgeRequest | View | Summary mode LEFT JOIN; detail mode EXISTS check |
| Trade.HedgeExposureQueryWithActiveParent | Procedure | Detail mode: delegated to for actual computation |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge Server (external) | External caller | Most conservative exposure query option |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. Structurally identical to Trade.HedgeExposureWithNoRequests; only the delegated objects differ. The summary mode LEFT JOIN on InstrumentID-only carries the same potential for cross-server duplicate rows as its sibling.

---

## 8. Sample Queries

### 8.1 Detail mode with active-parent check

```sql
DECLARE @result INT;
EXEC @result = Trade.HedgeExposureWithNoRequestsWithActiveParent
    @HedgeServerID = 24,
    @RequestValidSeconds = 300,
    @InstrumentID = 1,
    @HedgedInstrument = 1;
-- @result = 0: exposure returned (no orphans included); @result = -1: skip
```

### 8.2 Compare standard vs active-parent exposure with no-request guard

```sql
-- Standard (includes orphaned child positions):
EXEC Trade.HedgeExposureWithNoRequests @HedgeServerID=24, @RequestValidSeconds=300, @InstrumentID=1;

-- Active-parent (excludes orphaned child positions):
EXEC Trade.HedgeExposureWithNoRequestsWithActiveParent @HedgeServerID=24, @RequestValidSeconds=300, @InstrumentID=1;
```

### 8.3 Summary mode with active-parent filter

```sql
EXEC Trade.HedgeExposureWithNoRequestsWithActiveParent
    @HedgeServerID = 24,
    @RequestValidSeconds = 300;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 2/4 (1, 11 - Phase 8: only grants, Phase 10: skipped)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (Trade.HedgeExposureQueryWithActiveParent) | App Code: 0 repos (skipped) | Corrections: 0 applied*
*Object: Trade.HedgeExposureWithNoRequestsWithActiveParent | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.HedgeExposureWithNoRequestsWithActiveParent.sql*
