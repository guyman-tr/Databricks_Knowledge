# Schema Overview: Hedge

**Database**: etoro
**Schema**: Hedge
**Generated**: 2026-03-19
**Documentation Status**: Complete (230/230 objects, Phase 12 enrichment applied)

---

## Purpose

The Hedge schema is eToro's **hedge book management layer**. It owns the state, configuration, execution logs, and operational tooling for the firm's hedging activity - the process of offsetting net client exposure to external liquidity providers (LPs) via FX, CFD, and equity instruments.

The schema sits between the trading engine (Trade schema) and external LP connectivity (FIX/EMS). It does not generate orders directly; instead it receives exposure instructions from the HedgeServer application, tracks what was hedged, and provides configuration and reference data the HedgeServer reads at startup and periodically during operation.

---

## Object Inventory

| Type | Count | Notes |
|------|-------|-------|
| Tables | 60 | Core state, configuration, and execution log tables |
| Stored Procedures | 146 | Read, write, archive, and reporting procedures |
| Views | 9 | Operational and reporting views |
| User Defined Types | 12 | TVP types for bulk-insert procedures |
| Synonyms | 2 | Aliases pointing to linked/remote objects |
| Functions | 1 | Scalar function for account status derivation |
| **Total** | **230** | |

---

## Architecture Overview

### Three-Layer Design

```
[HedgeServer Application]
        |
        v
[Hedge Schema - SQL Server]
  - Configuration reads (GetServerConfiguration, GetInstrumentConfiguration, ...)
  - Netting state (Hedge.Netting - the hedge book)
  - Execution logging (Hedge.ExecutionLog, Hedge.HBCExecutionLog)
  - Recovery / reconciliation
        |
        v
[Trade / Dictionary Schemas]
  - Trade.HedgeServer (master server registry)
  - Trade.LiquidityAccounts (LP account registry)
  - Trade.Instrument (instrument master)
```

### Two Execution Paths

| Path | Identifier | Description |
|------|-----------|-------------|
| Legacy / HedgeServer | `ExecutionLog.OrderID > 0` | Original execution path; orders routed by HedgeServer directly |
| EMS / HBC | `ExecutionLog.OrderID = -1` | Hedge-By-Client path; order management via EMS, `EMSOrderID` carries external reference |

Both paths write to the same `Hedge.ExecutionLog` table. Queries must filter or branch on `OrderID` to correctly attribute execution data.

### Netting Book Semantics

`Hedge.Netting` maintains exactly ONE net position per `(LiquidityAccountID, InstrumentID)`. The upsert procedure `Hedge.AddOrUpdateNetting` computes volume-weighted average rate and direction. This is the live hedge book - the single source of truth for what eToro currently holds at each LP for each instrument.

All netting changes are system-versioned: historical rows are archived in `History.Netting_History`.

---

## Key Business Concepts

| Concept | Primary Object | Description |
|---------|---------------|-------------|
| Netting / Hedge Book | Hedge.Netting | One row per (LP account, instrument). Net units and avg rate represent current hedge position. |
| Hedge Order Execution | Hedge.ExecutionLog | Every execution attempt logged with fill details, latency, state. Dual-path (Legacy vs EMS). |
| HBC Execution | Hedge.HBCExecutionLog | Hedge-By-Client path: individual client-level hedge orders via EMS, tied to customer CID. |
| Hedge Server Configuration | Hedge.ServerConfiguration | Per-server parameters loaded at startup: strategy, exposure limits, modes. |
| Liquidity Account Registry | Hedge.Accounts | Hedge-schema account catalog (separate from Trade.LiquidityAccounts). Maps providers to execution and pricing accounts. |
| Instrument Configuration | Hedge.InstrumentConfiguration | Per-instrument hedging parameters: strategy, boundaries, unit conversion, active flag. |
| Exposure Monitoring | Hedge.ExposureBreakdownLog | Detailed per-instrument exposure snapshots; linked to circuit breaker thresholds. |
| Persist Data Buffer | Hedge.PositionsHedgeTbl | SET-and-CLEAR snapshot buffer written by HedgeServer to persist in-memory exposure state to DB. |
| Account Position State | Hedge.AccountStatus | Per-LP-account position summary (open units, P&L). Materialized state for recovery and reconciliation. |
| FIX Connectivity | Hedge.FIXConnections | Session-level FIX connection registry; replicated per instrument group. |
| Provider Tags | Hedge.ProviderExternalTags | Instrument-level tags sent to LP in order messages (e.g., regulatory, product type tags). |
| Execution Cost Reporting | Hedge.HedgeCostReport | Spread and commission cost analysis across executed hedge orders. Used by risk and finance. |
| CES Routing | Hedge.CESInstanceToGroup | Maps CES (Customer Execution System) instances to exchange groups for smart routing. |

---

## Shared Column Patterns

| Column | Pattern | Appears In |
|--------|---------|-----------|
| `HedgeServerID` | FK to `Trade.HedgeServer`. Present in virtually all operational tables. | Netting, ExecutionLog, RecoveryLog, HBCExecutionLog, KPIServerLog, EventLog, ManualOrderExecutionLog |
| `LiquidityAccountID` | FK to `Trade.LiquidityAccounts`. Identifies the LP account for execution. | Netting, ExecutionLog, RecoveryLog, HBCExecutionLog, FIXConnections, HedgeServerToLiquidityAccount |
| `InstrumentID` | Implicit FK to `Trade.Instrument`. High-cardinality. | Netting, ExecutionLog, InstrumentConfiguration, InstrumentBoundaries, HBCAccountConfiguration, KPIInstrumentLog |
| `IsBuy` | 1=Buy (long hedge), 0=Sell (short hedge). From eToro's perspective a buy hedge offsets net short client book. | Netting, ExecutionLog, RecoveryLog, HBCExecutionLog, AccountClosedPositions |
| `Units` / `AmountInUnits` | Quantity to hedge. High-precision decimal (up to 22,8) to support crypto fractional amounts. | Netting, ExecutionLog, HBCExecutionLog, PositionsHedgeTbl |
| `SysStartTime` / `SysEndTime` | Temporal versioning. `SysEndTime = 9999-12-31` = current row. Historical rows in `History.*` shadow tables. | Netting, Accounts, FIXConnections, FIXConnectionDetails |
| `IsActive` | Soft-delete: 1=active, 0=disabled. Operational queries filter `IsActive = 1`. | Accounts, InstrumentConfiguration, ActiveHedgingAccounts |
| `AvgRate` / `ExecutionRate` | `dbo.dtPrice` custom UDT. Volume-weighted average entry price or fill price. | Netting, ExecutionLog, HBCExecutionLog |

---

## Cross-Schema Dependencies

| External Object | Used By | Role |
|----------------|---------|------|
| `Trade.HedgeServer` | All operational tables | Master hedge server registry - FK target for HedgeServerID |
| `Trade.LiquidityAccounts` | Netting, ExecutionLog, FIXConnections, Accounts | LP account master |
| `Trade.Instrument` | InstrumentConfiguration, Netting, ExecutionLog, HBCAccountConfiguration | Instrument master |
| `Trade.LiquidityProviderType` | Accounts, ProviderUnitConversionRatio, ProviderInstrumentConfiguration | Provider type classification |
| `Dictionary.HedgeOrderState` | ExecutionLog | Execution lifecycle states (0-7) |
| `Dictionary.HedgeAccountType` | Accounts | Account type (2=Execution, 4=Pricing) |
| `Dictionary.HedgeRecoveryState` | RecoveryLog | Recovery action type (0-4) |
| `Dictionary.HedgeServerExposureMode` | ServerConfiguration, HedgeServerExposureModeConfiguration | Exposure mode enum (0-3) |
| `Dictionary.HedgeServerExecutionStrategy` | ServerConfiguration | Execution strategy enum |
| `Dictionary.HedgeStrategyMode` | InstrumentConfiguration, HedgeServerInstrumentConfiguration | Hedging strategy selection |
| `Customer.CustomerStatic` | CIDToHedgeServer | Customer-to-server routing via CID |
| `dbo.dtPrice` | Netting, ExecutionLog, RecoveryLog, HBCExecutionLog | Custom high-precision price type |

---

## Temporal Tables (System-Versioned)

| Table | History Table | What Changes |
|-------|-------------|-------------|
| Hedge.Netting | History.Netting_History | Every hedge book position update |
| Hedge.Accounts | History.Accounts | LP account registry edits |
| Hedge.FIXConnections | History.FIXConnections | FIX session state changes |
| Hedge.FIXConnectionDetails | History.FIXConnectionDetails | FIX connection parameter changes |

---

## Key Architectural Patterns

### Pattern 1: Dual Execution Path (Legacy vs EMS)
- Legacy: `ExecutionLog.OrderID > 0`, `ParentOrderID` = GUID, `EMSOrderID` = NULL
- EMS/HBC: `ExecutionLog.OrderID = -1` (sentinel), `EMSOrderID` = `{ExternalID}_{sequence}`
- Affects: ExecutionLog, LogExecution, ExecutionLogInsertBulk, SSRS_Latency_Report, GetExecutionLogData

### Pattern 2: Netting Upsert Semantics
- Exactly ONE row per `(LiquidityAccountID, InstrumentID)` in `Hedge.Netting`
- `AddOrUpdateNetting` performs UPDATE if exists, INSERT if not
- PK has `ValueDate` as third component but UPDATE does not filter on it - design artifact from ValueDate era
- Cleanup hierarchy: `RemoveNetting` (single), `RemoveBadNetting` (single LP exclusion), `RemoveMultiBadNetting` (multi-LP set)

### Pattern 3: Persist Data Buffer
- `Hedge.PositionsHedgeTbl` and `Hedge.PositionsNetOpenDollarTbl` are snapshot buffers
- Written by `SetHedgePersistData` / `SetNetOpenDollarPersistData` via TVP bulk upsert
- Cleared by `ClearHedgeExposuresPersistData` / `ClearNetOpenExposuresPersistData` (TRUNCATE)
- Pruned of zero-rows by `DeleteZeroRowPositionsHedgePersistData` / `DeleteZeroRowNetOpenHedgePersistData`

### Pattern 4: Archive Tables (Pre-Temporal Era)
- `Hedge.NettingOld`, `Hedge.AccountStatusOld`: manual archive tables created before system-versioned temporal tables
- `Hedge.ExposureAlerts`: legacy 2014 alert archive - no longer written to

### Pattern 5: Cross-Server Insert Pattern
- `AddExpsosureAlert_Child`: 3-part name `etoro.Hedge.ExposureAlerts` for cross-database insert on same server
- `AddExpsosureAlert_old`: linked-server insert to `[AO-REAL-DB].etoro.Hedge.ExposureAlerts`
- Reflects legacy multi-server hedge architecture

### Pattern 6: Configuration Hierarchy
- Global defaults -> HedgeServer-level -> InstrumentType-level -> Instrument-level -> Account-level
- `GetServerConfiguration`, `GetInstrumentConfiguration`, `GetProviderInstrumentConfiguration` build this hierarchy for HedgeServer startup

---

## Procedure Functional Groups

| Group | Procedures | Purpose |
|-------|-----------|---------|
| Configuration readers (startup) | GetServerConfiguration, GetInstrumentConfiguration, GetHedgeServerSettings, GetHedgeSupportedInstruments, GetPeriodicConfiguration, GetSmartExecutionConfigurations, GetStrategyExecutionFactorConfiguration, GetOrderTypeConfiguration, GetBoundariesConfiguration | Read by HedgeServer on startup and periodic refresh |
| Netting state | AddOrUpdateNetting, GetNetting, RemoveNetting, RemoveBadNetting, RemoveMultiBadNetting, AddOrUpdateNettingDaily | Manage the live hedge book and daily summaries |
| Execution logging | LogExecution, LogHBCExecution, ExecutionLogInsertBulk, LogHedgeExecutionRequest, LogHedgeExecutionResponse, InsertManualOrderExecutionLog | Write execution records during and after order routing |
| Reference data (reconciliation) | GetReferenceAccountStatus, GetReferenceAccountOpenPositions, GetReferenceCustomerOpenPositions, GetOpenPositionsAmountByHedgeServer | Snapshot procedures for reconciliation against HedgeServer in-memory state |
| Archive / cleanup | ArchiveHedgeTables, ArchiveAccountStatus, DelAccountStatus, DeleteRecordsFromHedgingTables, DeleteZeroRowPositionsHedgePersistData | Periodic maintenance |
| Reporting | HedgeCostReport, HedgeCostReportHistory, SSRS_Latency_Report, Report_TCA, Report_StocksClients, Report_StopLossCrisisAllInstruments | Operational and finance reporting |
| Recovery | LogRecovery, ClearHedgeExposuresPersistData, SetHedgePersistData, SetNetOpenDollarPersistData | HedgeServer crash recovery and reconciliation |

---

## Documentation Statistics

| Metric | Value |
|--------|-------|
| Total objects | 230 |
| Documented | 230 (100%) |
| Average quality score | 8.88 / 10 |
| Batches used | 10 |
| Phase 12 enrichment | Complete (2026-03-19) |
| Semantic index | etoro/Wiki/Hedge/_semantic_index.md |
| Glossary | etoro/Wiki/_glossary.md |

---

*Generated: 2026-03-19 | Schema: Hedge | Database: etoro | etoro/Wiki/Hedge/_schema_overview.md*
