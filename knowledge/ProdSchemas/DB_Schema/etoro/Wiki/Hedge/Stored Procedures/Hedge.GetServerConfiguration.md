# Hedge.GetServerConfiguration

> Returns the four core execution strategy parameters for a specific hedge server from Hedge.ServerConfiguration, providing the server's fundamental operating mode on startup.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ServerID - identifies which server's configuration to load |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Hedge.GetServerConfiguration` is the hedge server's primary startup configuration loader. When a hedge server instance starts (identified by its @ServerID), it calls this procedure to retrieve its four fundamental operating parameters that govern how it will process trades and manage hedge exposure.

The four returned columns define the server's complete execution personality:
- **AutoExecutionMode**: whether the server automatically submits hedge orders to the LP or requires manual approval
- **ExposureStrategy**: which algorithm computes the "target hedge size" from the customer book (e.g., full offset, partial hedge, net exposure)
- **ConvertToMajors**: whether cross-currency pair exposure should be decomposed into major-pair legs (triggers `Hedge.GetMajorsUnits`)
- **ExposureMode**: whether exposure is computed per-instrument independently or with cross-instrument netting

This procedure uses a TRY/CATCH with THROW pattern identical to `Hedge.GetNetting` - any SQL error during execution is propagated to the caller unchanged rather than silently returning an empty result set. This is critical for startup initialization: a configuration load failure must be a visible error, not a silent default.

**Important note**: The `Hedge.ServerConfiguration` table contains an `ExecutionStrategy` column (distinct from `ExposureStrategy`), but this procedure does NOT return it. `ExecutionStrategy` controls smart execution behavior (TWAP, VWAP, single order) and is loaded separately by the application directly querying the table or via a different path. This projection is intentional.

---

## 2. Business Logic

### 2.1 Single-Server Configuration Load with Error Propagation

**What**: Selects exactly four columns for one server ID. The TRY/CATCH ensures errors are visible rather than silently swallowed.

**Columns/Parameters Involved**: `@ServerID`, `AutoExecutionMode`, `ExposureStrategy`, `ConvertToMajors`, `ExposureMode`

**Rules**:
- WHERE ServerID=@ServerID: exactly one row returned (ServerID is PK of Hedge.ServerConfiguration)
- Four columns selected - `ExecutionStrategy` is intentionally excluded from this projection
- TRY/CATCH with THROW: any error (row not found, lock timeout, schema mismatch) propagates to caller
- No NOLOCK hint: reads at default READ COMMITTED isolation to ensure the configuration is consistent
- Returns 0 rows if @ServerID has no entry - caller must handle the empty result

**Diagram**:
```
Hedge server startup (@ServerID=1):
  GetServerConfiguration(@ServerID=1)
       |
       v
  Returns: AutoExecutionMode=1, ExposureStrategy=2, ConvertToMajors=0, ExposureMode=1

  AutoExecutionMode=1 -> automatic LP order submission enabled
  ExposureStrategy=2  -> specific exposure calculation algorithm
  ConvertToMajors=0   -> cross-pair decomposition disabled (no GetMajorsUnits calls)
  ExposureMode=1      -> per-instrument independent exposure computation
```

### 2.2 ConvertToMajors as GetMajorsUnits Gate

**What**: The `ConvertToMajors` flag returned by this procedure controls whether the hedge engine calls `Hedge.GetMajorsUnits` during order sizing.

**Rules**:
- ConvertToMajors=1: server is configured to decompose cross-currency exposures into major-pair legs. Calls GetMajorsUnits for non-major instruments.
- ConvertToMajors=0: server trades cross-pairs directly without decomposition.
- This flag bridges configuration and execution logic: GetMajorsUnits documentation references this procedure as its activation gate.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ServerID | int | NO | - | VERIFIED | The hedge server ID to load configuration for. FK to Hedge.ServerConfiguration.ServerID. Each physical hedge server instance has one row. Pass the server's own ID on startup. |

**Output columns** (from Hedge.ServerConfiguration):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | AutoExecutionMode | int | YES | - | VERIFIED | Controls whether hedge orders are submitted automatically to the LP (1) or queued for manual approval (0). When automatic, the server places FIX orders directly. When manual, a human operator reviews and approves each order. |
| 3 | ExposureStrategy | int | YES | - | VERIFIED | The algorithm used to compute target hedge exposure from the customer book. Different values select different hedging approaches (e.g., full offset vs partial hedge vs net exposure). Specific strategy values are defined in application code. |
| 4 | ConvertToMajors | bit | YES | - | VERIFIED | Whether to decompose cross-currency exposures into major-pair legs. 1=enabled: activates Hedge.GetMajorsUnits for non-major instruments. 0=disabled: trades cross-pairs directly. |
| 5 | ExposureMode | int | YES | - | VERIFIED | Controls whether exposure is computed per instrument independently or with cross-instrument netting. Specific mode values defined in application logic. Affects how GetOpenPositionsAmountByHedgeServer results are aggregated before hedge order sizing. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (reads) | Hedge.ServerConfiguration | SELECT | Source of the four startup configuration parameters for the specified server. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge server application | - | Caller | Called on startup to load fundamental operating parameters. |
| Hedge.GetMajorsUnits | ConvertToMajors | Indirect dependency | ConvertToMajors=1 returned by this procedure activates GetMajorsUnits calls. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.GetServerConfiguration (procedure)
└── Hedge.ServerConfiguration (table)
      - PK: ServerID
      - Also read by: application directly for ExecutionStrategy (not returned here)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Hedge.ServerConfiguration | Table | SELECTed - source of AutoExecutionMode, ExposureStrategy, ConvertToMajors, ExposureMode for @ServerID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge server application | External | READER - called at startup to initialize the server's execution mode configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure. Hedge.ServerConfiguration has a PK (clustered) on ServerID. The WHERE ServerID=@ServerID produces a single-row index seek.

### 7.2 Constraints

N/A for Stored Procedure. TRY/CATCH with THROW ensures startup failures are propagated. The intentional omission of `ExecutionStrategy` from the SELECT list means changes to that column in the table do not affect callers of this procedure. If ExecutionStrategy needs to be loaded via this procedure, the SELECT list must be extended. The server must handle a 0-row result if @ServerID is not configured in Hedge.ServerConfiguration.

---

## 8. Sample Queries

### 8.1 Load configuration for hedge server 1
```sql
EXEC [Hedge].[GetServerConfiguration] @ServerID = 1;
```

### 8.2 Direct table query including all columns (including excluded ExecutionStrategy)
```sql
SELECT  ServerID,
        AutoExecutionMode,
        ExposureStrategy,
        ExecutionStrategy,   -- NOTE: not returned by the procedure
        ConvertToMajors,
        ExposureMode
FROM    [Hedge].[ServerConfiguration] WITH (NOLOCK)
WHERE   ServerID = 1;
```

### 8.3 List all servers and their operating modes
```sql
SELECT  ServerID,
        AutoExecutionMode,
        ExposureStrategy,
        ConvertToMajors,
        ExposureMode
FROM    [Hedge].[ServerConfiguration] WITH (NOLOCK)
ORDER BY ServerID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 4 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6 applicable*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.GetServerConfiguration | Type: Stored Procedure | Source: etoro/etoro/Hedge/Stored Procedures/Hedge.GetServerConfiguration.sql*
