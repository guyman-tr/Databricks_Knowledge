# Trade.UpdateFuturesOpsConfigurations

> Orchestrator procedure that atomically applies both futures instrument risk settings (stop/take-profit buffers) and initial margin by provider mapping in a single transaction, ensuring futures configuration is always updated consistently across both stores.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FuturesInstrumentRiskSettings + @FuturesInstrumentsInitialMarginByProviderMapping (two TVPs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Futures instruments require two distinct types of configuration that are typically updated together from the same upstream data source: risk buffer settings (the percentage buffers applied to stop-loss and take-profit thresholds) and initial margin requirements per provider (the minimum capital required to open a futures position with a given liquidity provider).

This procedure acts as a transactional wrapper around the two sub-procedures that handle each data type. Its value is atomicity: either both risk settings and initial margin updates commit together, or neither does. Without this wrapper, a partial update where risk buffers are refreshed but initial margins are not (or vice versa) could create an inconsistent state where the system applies the wrong margin for the new risk parameters.

The procedure is called from the eToro Market Maker (EtoroOps) configuration system, which periodically pushes updated futures parameters from exchange data or risk management decisions to the trading database. Each TVP is independently optional - if either is empty, its corresponding sub-procedure is skipped silently.

---

## 2. Business Logic

### 2.1 Conditional Execution of Sub-Procedures

**What**: Each sub-procedure is only called if its corresponding input TVP is non-empty, allowing the caller to update only one aspect of futures configuration without triggering a no-op in the other.

**Columns/Parameters Involved**: `@FuturesInstrumentRiskSettings`, `@FuturesInstrumentsInitialMarginByProviderMapping`

**Rules**:
- IF EXISTS check on each TVP before the corresponding EXEC
- If @FuturesInstrumentRiskSettings is empty: UpsertFuturesInstrumentRiskSettings is skipped
- If @FuturesInstrumentsInitialMarginByProviderMapping is empty: UpdateFuturesInstrumentsInitialMarginByProviderMapping is skipped
- If both are non-empty: both sub-procedures run in the same transaction
- Both checks use `SELECT TOP 1 1` for efficiency (stops scanning after first row)

**Diagram**:
```
BEGIN TRANSACTION
  |
  +-- @FuturesInstrumentRiskSettings non-empty?
  |     YES --> EXEC Trade.UpsertFuturesInstrumentRiskSettings
  |     NO  --> skip
  |
  +-- @FuturesInstrumentsInitialMarginByProviderMapping non-empty?
        YES --> EXEC Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping
        NO  --> skip
  |
COMMIT (or ROLLBACK on any error)
```

### 2.2 Atomic Cross-Configuration Update

**What**: Risk settings and initial margin values are tightly coupled - they should always be updated atomically to prevent inconsistent margin calculations.

**Columns/Parameters Involved**: `@FuturesInstrumentRiskSettings.StopLossPercentageBuffer`, `@FuturesInstrumentRiskSettings.TakeProfitPercentageBuffer`, `@FuturesInstrumentsInitialMarginByProviderMapping.InitialMargin`

**Rules**:
- If the UpsertFuturesInstrumentRiskSettings sub-procedure fails, the initial margin update is also rolled back
- If the UpdateFuturesInstrumentsInitialMarginByProviderMapping sub-procedure fails, any risk settings changes are also rolled back
- The error handler uses `IF @@TRANCOUNT = 1` before rollback - nested transactions from sub-procedures are handled via the count check

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FuturesInstrumentRiskSettings | Trade.Tv_FuturesInstrumentRiskSettings (TVP, READONLY) | NO | - | CODE-BACKED | Futures instrument risk buffer settings to upsert. Contains InstrumentID (key), StopLossPercentageBuffer (decimal(10,2) - percentage buffer added to stop-loss threshold for futures), and TakeProfitPercentageBuffer (decimal(10,2) - percentage buffer added to take-profit threshold). If empty, UpsertFuturesInstrumentRiskSettings is skipped. Passed directly to Trade.UpsertFuturesInstrumentRiskSettings. |
| 2 | @FuturesInstrumentsInitialMarginByProviderMapping | Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping (TVP, READONLY) | NO | - | CODE-BACKED | Initial margin requirements per provider-instrument combination. Contains InstrumentID + ProviderID (composite key), and InitialMargin (decimal(10,2) - minimum capital percentage required to open a futures position with this provider). If empty, UpdateFuturesInstrumentsInitialMarginByProviderMapping is skipped. Passed directly to Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FuturesInstrumentRiskSettings | Trade.UpsertFuturesInstrumentRiskSettings | EXEC call | Passes the risk settings TVP to the upsert procedure |
| @FuturesInstrumentsInitialMarginByProviderMapping | Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | EXEC call | Passes the initial margin TVP to the update procedure |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| EtoroOps configuration system | External caller | Application call | Called from the futures configuration screen in the eToro Market Maker ops tool (per Atlassian EMM space) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFuturesOpsConfigurations (procedure)
├── Trade.UpsertFuturesInstrumentRiskSettings (procedure) [conditional]
│     └── [see Trade.UpsertFuturesInstrumentRiskSettings.md for full dependency chain]
└── Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping (procedure) [conditional]
      └── [see Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping.md for full dependency chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpsertFuturesInstrumentRiskSettings | Procedure | EXECuted with @FuturesInstrumentRiskSettings TVP (when non-empty) |
| Trade.UpdateFuturesInstrumentsInitialMarginByProviderMapping | Procedure | EXECuted with @FuturesInstrumentsInitialMarginByProviderMapping TVP (when non-empty) |
| Trade.Tv_FuturesInstrumentRiskSettings | User Defined Type | TVP type for @FuturesInstrumentRiskSettings |
| Trade.Tv_FuturesInstrumentsInitialMarginByProviderMapping | User Defined Type | TVP type for @FuturesInstrumentsInitialMarginByProviderMapping |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| EtoroOps.Configurations | External application | Calls this procedure from the Futures configuration management screen |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Conditional sub-procedure calls | Logic | IF EXISTS (SELECT TOP 1 1 FROM TVP) before each EXEC - empty TVPs skip their sub-procedure |
| Atomic transaction | TRY/CATCH | Both sub-procedure EXECs share a single transaction; error in either rolls back both via THROW |
| SET NOCOUNT ON | Session setting | Suppresses row-count messages from sub-procedures |

---

## 8. Sample Queries

### 8.1 Update both risk settings and initial margins in one call

```sql
DECLARE @RiskSettings [Trade].[Tv_FuturesInstrumentRiskSettings]
INSERT INTO @RiskSettings (InstrumentID, StopLossPercentageBuffer, TakeProfitPercentageBuffer)
VALUES (1234, 2.50, 5.00)

DECLARE @InitialMargins [Trade].[Tv_FuturesInstrumentsInitialMarginByProviderMapping]
INSERT INTO @InitialMargins (InstrumentID, ProviderID, InitialMargin)
VALUES (1234, 100, 10.00)

EXEC Trade.UpdateFuturesOpsConfigurations
    @FuturesInstrumentRiskSettings = @RiskSettings,
    @FuturesInstrumentsInitialMarginByProviderMapping = @InitialMargins
```

### 8.2 Update only initial margins (skip risk settings)

```sql
DECLARE @RiskSettings [Trade].[Tv_FuturesInstrumentRiskSettings]
-- Empty - UpsertFuturesInstrumentRiskSettings will be skipped

DECLARE @InitialMargins [Trade].[Tv_FuturesInstrumentsInitialMarginByProviderMapping]
INSERT INTO @InitialMargins (InstrumentID, ProviderID, InitialMargin)
VALUES (1234, 100, 12.50), (5678, 100, 8.00)

EXEC Trade.UpdateFuturesOpsConfigurations
    @FuturesInstrumentRiskSettings = @RiskSettings,
    @FuturesInstrumentsInitialMarginByProviderMapping = @InitialMargins
```

### 8.3 Check current futures risk settings and initial margins

```sql
-- FuturesInstrumentRiskSettings table (documented separately)
SELECT
    firs.InstrumentID,
    firs.StopLossPercentageBuffer,
    firs.TakeProfitPercentageBuffer,
    tpti.Leverage1MaintenanceMargin
FROM Trade.ProviderToInstrument tpti WITH (NOLOCK)
JOIN Trade.Instrument ti WITH (NOLOCK) ON ti.InstrumentID = tpti.InstrumentID
WHERE tpti.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Configuration Screens List](https://etoro-jira.atlassian.net/wiki/spaces/EMM/pages/14053015561/Configuration+Screens+List) | Confluence | UpdateFuturesOpsConfigurations is called from the EtoroOps futures configuration screen in the eToro Market Maker configuration management system |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 2 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFuturesOpsConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFuturesOpsConfigurations.sql*
