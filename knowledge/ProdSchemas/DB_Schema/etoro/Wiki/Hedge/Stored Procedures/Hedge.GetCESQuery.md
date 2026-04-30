# Hedge.GetCESQuery

> CES (Centralized Execution Server) exposure polling procedure: returns current hedged and in-flight exposure snapshot for a specific provider, then atomically allocates a unique ExposureID to correlate the cycle. Returns both a result set and the ExposureID via RETURN.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ProviderID (optional, defaults to 1) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the CES (Centralized Execution Server) exposure polling endpoint. On each execution cycle, the CES calls this procedure to:

1. **Retrieve the current exposure snapshot** - returns hedged + in-flight requested positions per (HedgeServerID, InstrumentID) pair for the specified provider, sourced from the composite view `Hedge.GetExposuresForAllHedgeServers`.

2. **Allocate a unique ExposureID** - inserts a row into `Trade.ExposureIDs` (identity column) and returns the new ID via `RETURN (SCOPE_IDENTITY())`. This ExposureID correlates the snapshot with any downstream processing that needs to reference which query cycle the data came from.

The two actions are atomic within the same call: the CES receives both the exposure data (as a result set) and the cycle correlation ID (as the procedure return value) in a single round-trip. This design prevents race conditions where the snapshot and the ID could become mismatched.

The `@ProviderID` parameter defaults to 1, allowing the procedure to be called without arguments for the primary provider while supporting multi-provider configurations.

---

## 2. Business Logic

### 2.1 Exposure Snapshot (Result Set)

**What**: Returns the net exposure position for each (HedgeServerID, InstrumentID) combination active for the specified provider, combining actual hedge positions and pending in-flight requests.

**Columns/Parameters Involved**: `@ProviderID`, `Hedge.GetExposuresForAllHedgeServers`

**Rules**:
- Reads from `Hedge.GetExposuresForAllHedgeServers` view, which combines:
  - **Hedged**: net of actual LP positions (Trade.Hedge + Hedge.Netting)
  - **Requested**: net of in-flight pending requests (Trade.HedgeRequest within server's ConsiderOpenRequestsSec window)
- Filtered to `ProviderID = @ProviderID` - returns only the rows for the specified liquidity provider
- Both `Hedged` and `Requested` are signed net values (positive=long, negative=short)
- `Requested = NULL -> 0` handled by view logic (ISNULL in the view)

**Diagram**:
```
Hedge.GetExposuresForAllHedgeServers (view)
  <- Trade.Hedge (actual LP positions)
  <- Hedge.Netting (netting positions via HedgeServerToLiquidityAccount)
  <- Trade.HedgeRequest (in-flight requests within ConsiderOpenRequestsSec window)
       |
       | WHERE ProviderID = @ProviderID
       v
  (HedgeServerID, InstrumentID, Hedged, Requested) per active server/instrument pair
```

### 2.2 ExposureID Allocation (Side Effect + Return Value)

**What**: Each call inserts one row into `Trade.ExposureIDs` (an identity generator table) and returns the allocated ID as the procedure return value.

**Columns/Parameters Involved**: `Trade.ExposureIDs.ExposureID` (IDENTITY)

**Rules**:
- `INSERT INTO Trade.ExposureIDs DEFAULT VALUES` - no column specification; the IDENTITY column auto-increments
- `RETURN (SCOPE_IDENTITY())` - the newly allocated ExposureID is returned as the procedure's integer return code
- One ExposureID per procedure call - strictly one row inserted per invocation
- IDs are monotonically increasing; no gaps are filled; no reuse
- The ExposureID correlates this query cycle's snapshot with any downstream consumers that need to reference which batch the data came from

### 2.3 Dual Output Pattern

**What**: The procedure produces two outputs simultaneously: a result set and a return value.

**Rules**:
- **Result set**: `SELECT HedgeServerID, InstrumentID, Hedged, Requested` - the exposure snapshot data
- **RETURN value**: the new ExposureID from `SCOPE_IDENTITY()` - the cycle correlation ID
- Callers must handle both: read the result set rows AND capture the return value
- The INSERT always runs regardless of whether the SELECT returns any rows

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ProviderID | INT | YES | 1 | CODE-BACKED | The liquidity provider to retrieve exposure for. Defaults to 1 (primary provider). Passed as a WHERE filter to `Hedge.GetExposuresForAllHedgeServers`. FK concept to Trade.LiquidityProviders.LiquidityProviderID. |

**Output Columns (Result Set)**:

| Column | Source | Description |
|--------|--------|-------------|
| HedgeServerID | Hedge.GetExposuresForAllHedgeServers | The hedge server managing this instrument's exposure. FK to Trade.HedgeServer. |
| InstrumentID | Hedge.GetExposuresForAllHedgeServers | The instrument for which exposure is reported. FK to Trade.Instrument. |
| Hedged | Hedge.GetExposuresForAllHedgeServers | Net signed exposure from actual LP positions. Positive=net long, negative=net short. Combines Trade.Hedge and Hedge.Netting data. |
| Requested | Hedge.GetExposuresForAllHedgeServers | Net signed exposure from in-flight pending requests. Positive=pending buy, negative=pending sell. Based on Trade.HedgeRequest within server's ConsiderOpenRequestsSec window. |

**Return Value**:

| Return | Description |
|--------|-------------|
| SCOPE_IDENTITY() | The newly allocated ExposureID from Trade.ExposureIDs (IDENTITY integer). Correlates this query cycle's snapshot with downstream consumers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT source | Hedge.GetExposuresForAllHedgeServers | View read | Provider-filtered exposure snapshot combining actual positions and in-flight requests |
| INSERT target | Trade.ExposureIDs | Direct write | Allocates one new ExposureID row per call; returns SCOPE_IDENTITY() as the cycle correlation ID |

### 5.2 Referenced By (other objects point to this)

No SQL-level callers found. Called by the CES (Centralized Execution Server) application on each exposure polling cycle.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetCESQuery (procedure)
├── Hedge.GetExposuresForAllHedgeServers (view) - exposure snapshot source
|   ├── Trade.Hedge (table) - actual LP positions (Hedged)
|   ├── Hedge.Netting (table) - netting positions (Hedged via HedgeServerToLiquidityAccount)
|   └── Trade.HedgeRequest (table) - in-flight requests (Requested)
└── Trade.ExposureIDs (table) - WRITE: INSERT DEFAULT VALUES to allocate ExposureID
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.GetExposuresForAllHedgeServers | View | SELECT HedgeServerID, InstrumentID, Hedged, Requested WHERE ProviderID = @ProviderID |
| Trade.ExposureIDs | Table | INSERT DEFAULT VALUES to allocate a new ExposureID; returns SCOPE_IDENTITY() as procedure return value |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Dual output | Design | Returns both a result set AND a RETURN value (ExposureID). Callers must handle both outputs. |
| Default @ProviderID = 1 | Design | Can be called without arguments for the primary provider; supports multi-provider via explicit parameter |
| INSERT always runs | Behavior | The ExposureID INSERT executes unconditionally, even if the SELECT returns 0 rows |
| SCOPE_IDENTITY() as RETURN | Pattern | The procedure return value carries the ExposureID, not a status code. Callers must capture the return value to retrieve the ExposureID. |
| No NOLOCK | Isolation | No isolation hints applied - default READ COMMITTED for both the view read and the INSERT |

---

## 8. Sample Queries

### 8.1 Get exposure snapshot for primary provider (equivalent scalar query)

```sql
SELECT HedgeServerID, InstrumentID, Hedged, Requested
FROM Hedge.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE ProviderID = 1
ORDER BY HedgeServerID, InstrumentID
```

### 8.2 Check current ExposureID sequence

```sql
SELECT MAX(ExposureID) AS LatestExposureID, COUNT(*) AS TotalAllocations
FROM Trade.ExposureIDs WITH (NOLOCK)
```

### 8.3 Find instruments with large in-flight requests relative to hedged position

```sql
SELECT HedgeServerID, InstrumentID, Hedged, Requested,
       ABS(Requested) / NULLIF(ABS(Hedged), 0) AS RequestedToHedgedRatio
FROM Hedge.GetExposuresForAllHedgeServers WITH (NOLOCK)
WHERE ProviderID = 1
  AND ABS(Requested) > 0
ORDER BY ABS(Requested) DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetCESQuery | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetCESQuery.sql*
