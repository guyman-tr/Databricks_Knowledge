# Hedge.AddAccountPositions

> Orchestrator that determines the correct start date from closed position history and delegates open position loading to Hedge.AddAccountPositionsInsert for a given hedge server.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Orchestrator - delegates to Hedge.AddAccountPositionsInsert |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.AddAccountPositions` is a thin orchestration wrapper that answers one question before loading open positions: "where in time should we start?" It queries `Hedge.AccountClosedPositions` for the most recent `OccurredAt` timestamp. If records exist, that timestamp becomes the `@FromDate` passed to `Hedge.AddAccountPositionsInsert`. If no records exist (empty table - fresh install or after a purge), it falls back to the start of the current week (Sunday midnight UTC), calculated via `DATEADD(dw, 0-DATEPART(dw, GETUTCDATE()), GETUTCDATE())`.

This procedure exists to insulate the core insert logic (`AddAccountPositionsInsert`) from the date-determination logic. The separation allows the insert SP to be called directly with an explicit date range when needed, while this wrapper provides the standard automated behavior for the polling job.

Data flow: Called by the hedge server's position synchronization job. It reads the closed position watermark, then calls `Hedge.AddAccountPositionsInsert` which performs the actual query and INSERT into `Hedge.AccountOpenPositions`.

---

## 2. Business Logic

### 2.1 Closed-Position Watermark as Start Anchor

**What**: The most recent closed position timestamp drives how far back open positions are loaded.

**Columns/Parameters Involved**: `@HedgeServerID`, `@FromDate`

**Rules**:
- `@FromDate = MAX(OccurredAt) FROM Hedge.AccountClosedPositions` - uses the last closed event as the anchor
- If `MAX(OccurredAt)` is NULL (no closed positions ever), falls back to: start of current week (Sunday 00:00 UTC)
- `@FromDate` is passed directly to `Hedge.AddAccountPositionsInsert` as the lower bound for position loading

**Diagram**:
```
Hedge.AddAccountPositions(@HedgeServerID)
      |
      v
SELECT MAX(OccurredAt) FROM Hedge.AccountClosedPositions
      |
      +--[has rows]--> @FromDate = MAX(OccurredAt)
      |
      +--[NULL / empty]--> @FromDate = Start of current week (DATEADD logic)
      |
      v
EXEC Hedge.AddAccountPositionsInsert @HedgeServerID, @FromDate
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @HedgeServerID | INT | NO | - | CODE-BACKED | Identifier of the hedge server instance whose positions are being loaded. Passed through directly to Hedge.AddAccountPositionsInsert. FK to Trade.HedgeServer. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.AccountClosedPositions | Lookup | Reads MAX(OccurredAt) to determine the date watermark |
| (calls) | Hedge.AddAccountPositionsInsert | Procedure call | Delegates the actual position load to this procedure |

### 5.2 Referenced By (other objects point to this)

No callers found in the SSDT repository. Called externally by hedge server job or application.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.AddAccountPositions (procedure)
├── Hedge.AccountClosedPositions (table) - watermark read
└── Hedge.AddAccountPositionsInsert (procedure) - delegates to
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.AccountClosedPositions | Table | SELECT MAX(OccurredAt) to compute @FromDate watermark |
| Hedge.AddAccountPositionsInsert | Procedure | Called with (@HedgeServerID, @FromDate) to perform the actual insert |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| (Hedge server job) | External | Invokes this orchestrator periodically to refresh open position data |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

None. The fallback date logic (DATEADD/DATEPART) ensures @FromDate is never NULL.

---

## 8. Sample Queries

### 8.1 Execute: Load positions for hedge server 1

```sql
EXEC Hedge.AddAccountPositions @HedgeServerID = 1
```

### 8.2 Preview: Determine what @FromDate will be computed

```sql
SELECT
    ISNULL(MAX(OccurredAt), DATEADD(dw, 0-DATEPART(dw, GETUTCDATE()), GETUTCDATE())) AS ComputedFromDate
FROM Hedge.AccountClosedPositions WITH (NOLOCK)
```

### 8.3 Verify: Check what AddAccountPositionsInsert received (by checking AccountClosedPositions watermark vs AccountOpenPositions content)

```sql
SELECT TOP 5
    aop.HedgeServerID,
    aop.InstrumentID,
    aop.OccurredAt AS OpenPositionAt,
    acp_max.MaxOccurredAt AS WatermarkUsed
FROM Hedge.AccountOpenPositions aop WITH (NOLOCK)
CROSS JOIN (
    SELECT MAX(OccurredAt) AS MaxOccurredAt FROM Hedge.AccountClosedPositions WITH (NOLOCK)
) acp_max
WHERE aop.HedgeServerID = 1
ORDER BY aop.OccurredAt DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.5/10 (Elements: 9.5/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.AddAccountPositions | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.AddAccountPositions.sql*
