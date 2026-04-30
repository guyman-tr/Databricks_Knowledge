# Trade.UpdateFuturesTradingConfigurations

> Orchestrator procedure that atomically applies three aspects of futures instrument configuration - general trading settings (via UpdateInstrumentsTradingConfigurations), margin requirements (via SetInstrumentMarginsForFutures), and leverage maintenance margin (via UpdateProviderToInstrumentLeverageMaintenance) - in a single transaction with conditional execution for each TVP.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Futures instruments have a more complex configuration surface than standard instruments: they require not only the general trading permissions and limits (AllowBuy, MaxStopLossPercentage, etc.) but also futures-specific margin settings (InitialMargin, StopLossMargin in asset currency) and provider-level leverage maintenance margins.

Previously, each of these three configuration aspects would have to be updated via separate procedure calls with separate transactions, risking partial-update inconsistency (e.g., margin limits updated but trading permissions not yet changed). This orchestrator wraps all three in one atomic transaction.

Each of the three sub-procedures is invoked conditionally - only if its corresponding TVP is non-empty. This allows callers to update just one or two aspects in a single call without triggering no-ops in the others.

The procedure is called from the Trading Opstool API (Trading Operations tool), which manages all futures configuration changes from a unified administrative interface.

---

## 2. Business Logic

### 2.1 Conditional Sub-Procedure Execution

**What**: Each of the three sub-procedures is only called if its TVP contains at least one row.

**Columns/Parameters Involved**: `@InstrumentNewConfigTbl`, `@InstrumentSyncConfigurationAddTable`, `@Instruments_NewMargin`, `@LeverageMaintenanceMarginUpdates`

**Rules**:
- UpdateInstrumentsTradingConfigurations: IF EXISTS from @InstrumentNewConfigTbl OR from @InstrumentSyncConfigurationAddTable
- SetInstrumentMarginsForFutures: IF EXISTS from @Instruments_NewMargin
- UpdateProviderToInstrumentLeverageMaintenance: IF EXISTS from @LeverageMaintenanceMarginUpdates
- Uses `SELECT TOP 1 1` for efficiency on the TVP exists checks

**Diagram**:
```
BEGIN TRANSACTION
  |
  +-- @InstrumentNewConfigTbl OR @InstrumentSyncConfigurationAddTable non-empty?
  |     YES -> EXEC UpdateInstrumentsTradingConfigurations (39-field null-safe config update)
  |     NO  -> skip
  |
  +-- @Instruments_NewMargin non-empty?
  |     YES -> EXEC SetInstrumentMarginsForFutures (initial + SL margin in asset currency)
  |     NO  -> skip
  |
  +-- @LeverageMaintenanceMarginUpdates non-empty?
        YES -> EXEC UpdateProviderToInstrumentLeverageMaintenance (Leverage1MaintenanceMargin)
        NO  -> skip
  |
COMMIT (or ROLLBACK on any error)
```

### 2.2 Atomic Futures Configuration Update

**What**: All three sub-procedures share one transaction; any failure rolls back all changes.

**Rules**:
- IF @@TRANCOUNT > 0 -> ROLLBACK on error in CATCH
- THROW re-raises after rollback for caller visibility
- Ensures futures instrument configuration is always internally consistent across the three data stores

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Instruments_NewMargin | Trade.InstrumentsIDListSetMarginTbl (TVP, READONLY) | NO | - | CODE-BACKED | Futures margin settings: InstrumentID (int NOT NULL), InitialMarginInAssetCurrency (dtPrice NULL - minimum capital to open position in asset's currency), StopLossMarginInAssetCurrency (dtPrice NULL - margin level at which position is stopped out). Passed to Trade.SetInstrumentMarginsForFutures. If empty, SetInstrumentMarginsForFutures is skipped. |
| 2 | @InstrumentNewConfigTbl | Trade.InstrumentsTradingConfigTbl (TVP, READONLY) | NO | - | CODE-BACKED | Full 39-field instrument trading configuration (null-safe). Same TVP used by Trade.UpdateInstrumentsTradingConfigurations. Key: InstrumentID. If empty (and @InstrumentSyncConfigurationAddTable also empty), UpdateInstrumentsTradingConfigurations is skipped. |
| 3 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Configuration change sync events for Trade.SyncConfiguration. Passed to UpdateInstrumentsTradingConfigurations. An empty @InstrumentNewConfigTbl but non-empty @InstrumentSyncConfigurationAddTable still triggers the UpdateInstrumentsTradingConfigurations call. |
| 4 | @LeverageMaintenanceMarginUpdates | Trade.Leverage1MaintenanceMarginUpdate (TVP, READONLY) | NO | - | CODE-BACKED | Leverage maintenance margin updates: ProviderID (int NOT NULL), InstrumentID (int NOT NULL), Leverage1MaintenanceMargin (decimal(5,2) NOT NULL). Passed to Trade.UpdateProviderToInstrumentLeverageMaintenance. If empty, that procedure is skipped. |
| 5 | @AppLoginName | varchar(50) | YES | '' | CODE-BACKED | Username or service name. Passed to Trade.SetInstrumentMarginsForFutures for audit trail. Not passed to the other two sub-procedures. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTbl + @InstrumentSyncConfigurationAddTable | Trade.UpdateInstrumentsTradingConfigurations | EXEC call (conditional) | 39-field null-safe configuration update + sync events |
| @Instruments_NewMargin | Trade.SetInstrumentMarginsForFutures | EXEC call (conditional) | Futures-specific margin settings in asset currency |
| @LeverageMaintenanceMarginUpdates | Trade.UpdateProviderToInstrumentLeverageMaintenance | EXEC call (conditional) | Leverage1MaintenanceMargin update by provider+instrument |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trading Opstool API | Application call | Caller | No internal SP callers found; called from the Trading Operations tool's unified futures configuration management screen (per Atlassian TDD) |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateFuturesTradingConfigurations (procedure)
|- Trade.UpdateInstrumentsTradingConfigurations (procedure) [conditional EXEC - 39-field config]
|     +-- [see Trade.UpdateInstrumentsTradingConfigurations.md for full chain]
|- Trade.SetInstrumentMarginsForFutures (procedure) [conditional EXEC - futures margin settings]
+-- Trade.UpdateProviderToInstrumentLeverageMaintenance (procedure) [conditional EXEC - leverage maintenance]
      +-- [see Trade.UpdateProviderToInstrumentLeverageMaintenance.md for chain]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsTradingConfigurations | Procedure | EXECuted (when config or sync TVPs non-empty): 39-field null-safe update of Trade.ProviderToInstrument |
| Trade.SetInstrumentMarginsForFutures | Procedure | EXECuted (when @Instruments_NewMargin non-empty): updates futures margin settings |
| Trade.UpdateProviderToInstrumentLeverageMaintenance | Procedure | EXECuted (when @LeverageMaintenanceMarginUpdates non-empty): updates Leverage1MaintenanceMargin |
| Trade.InstrumentsIDListSetMarginTbl | User Defined Type | TVP type for @Instruments_NewMargin |
| Trade.InstrumentsTradingConfigTbl | User Defined Type | TVP type for @InstrumentNewConfigTbl |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |
| Trade.Leverage1MaintenanceMarginUpdate | User Defined Type | TVP type for @LeverageMaintenanceMarginUpdates |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trading Opstool API | Application | Calls for atomic multi-aspect futures instrument configuration |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Conditional execution | Logic | SELECT TOP 1 1 check before each EXEC - empty TVPs skip their sub-procedure |
| Atomic transaction | TRY/CATCH | All three sub-procedures share one transaction; error in any rolls back all |
| ROLLBACK guard | Catch | IF @@TRANCOUNT > 0 before ROLLBACK - safe for nested transaction contexts |
| SET NOCOUNT ON | Session | Suppresses row-count messages from sub-procedures |

---

## 8. Sample Queries

### 8.1 Update all three aspects of a futures instrument configuration

```sql
DECLARE @Margins [Trade].[InstrumentsIDListSetMarginTbl]
INSERT INTO @Margins (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES (1234, 5000.0, 2500.0)

DECLARE @Config [Trade].[InstrumentsTradingConfigTbl]
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell, MaxStopLossPercentage)
VALUES (1234, 1, 1, 50.0)

DECLARE @Sync [Trade].[SyncConfigurationAdd]

DECLARE @LevMaint [Trade].[Leverage1MaintenanceMarginUpdate]
INSERT INTO @LevMaint (ProviderID, InstrumentID, Leverage1MaintenanceMargin)
VALUES (100, 1234, 5.00)

EXEC Trade.UpdateFuturesTradingConfigurations
    @Instruments_NewMargin = @Margins,
    @InstrumentNewConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync,
    @LeverageMaintenanceMarginUpdates = @LevMaint,
    @AppLoginName = 'trdops_admin'
```

### 8.2 Update only margin settings (skip trading config and leverage)

```sql
DECLARE @Margins [Trade].[InstrumentsIDListSetMarginTbl]
INSERT INTO @Margins (InstrumentID, InitialMarginInAssetCurrency, StopLossMarginInAssetCurrency)
VALUES (1234, 6000.0, 3000.0)

DECLARE @EmptyConfig [Trade].[InstrumentsTradingConfigTbl]
DECLARE @EmptySync [Trade].[SyncConfigurationAdd]
DECLARE @EmptyLev [Trade].[Leverage1MaintenanceMarginUpdate]

EXEC Trade.UpdateFuturesTradingConfigurations
    @Instruments_NewMargin = @Margins,
    @InstrumentNewConfigTbl = @EmptyConfig,
    @InstrumentSyncConfigurationAddTable = @EmptySync,
    @LeverageMaintenanceMarginUpdates = @EmptyLev,
    @AppLoginName = 'trdops_admin'
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Trading Opstool API TDD](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/12817367145) | Confluence | Confirms this procedure is called from the Trading Opstool API which provides backend for managing trading configurations |

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.2/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 5 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateFuturesTradingConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateFuturesTradingConfigurations.sql*
