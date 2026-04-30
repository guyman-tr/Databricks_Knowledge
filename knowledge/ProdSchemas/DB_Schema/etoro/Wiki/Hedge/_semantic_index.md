# Semantic Index - Hedge Schema

> Cross-object knowledge map for the Hedge schema. Links business concepts to their primary objects and shows where shared elements and patterns appear across the schema.

*Generated: 2026-03-19 | Objects: 230 | Schema: Hedge | Database: etoro*

---

## Business Concepts

| Concept | Primary Object | Related Objects |
|---------|---------------|-----------------|
| Netting / Hedge Book Position | Hedge.Netting | Hedge.AddOrUpdateNetting, Hedge.GetNetting, Hedge.RemoveNetting, Hedge.RemoveBadNetting, Hedge.RemoveMultiBadNetting, Hedge.NettingDaily, Hedge.NettingOld, Hedge.CalculateAccountStatusFromNetting, Hedge.GetExposuresForAllHedgeServers, History.Netting_History |
| Hedge Order Execution | Hedge.ExecutionLog | Hedge.LogExecution, Hedge.ExecutionLogInsertBulk, Hedge.ExecutionRequestBreakdownLog, Hedge.ExecutionResponseBreakdownLog, Hedge.GetExecutionLogData, Hedge.ViewExecutionLog_isnull, Hedge.ListUnsupportedInstruments |
| HBC (Hedge-By-Client) Execution | Hedge.HBCExecutionLog | Hedge.HBCOrderLog, Hedge.LogHBCExecution, Hedge.HBCAccountConfiguration, Hedge.GetHBCAccountConfiguration, Hedge.GetHBCEstimationsDiscrepencies, Hedge.GetAllHBCAccountConfigurations |
| Hedge Server Configuration | Hedge.ServerConfiguration | Hedge.HedgeServersModes, Hedge.HedgeServerInstrumentConfiguration, Hedge.HedgeServerExposureModeConfiguration, Hedge.GetServerConfiguration, Hedge.UpdateServerConfiguration, Hedge.GetHedgeServerSettings, Hedge.GetHedgeServerInfo, Hedge.GetHedgeServerMetaData |
| Liquidity Provider / Account Registry | Hedge.Accounts | Hedge.HedgeServerToLiquidityAccount, Hedge.ActiveHedgingAccounts, Hedge.GetActiveProviderLiquidityAccounts, Hedge.GetActiveLiquidityAccounts, Hedge.SyncLiquidityAccounts, Hedge.CheckAccountUsernameExists |
| Instrument Configuration | Hedge.InstrumentConfiguration | Hedge.InstrumentTypeConfiguration, Hedge.InstrumentGroups, Hedge.InstrumentGroupsMapping, Hedge.InstrumentBoundaries, Hedge.InactiveInstruments, Hedge.GetInstrumentConfiguration, Hedge.GetAllInstrumentConfigurations, Hedge.GetHedgeSupportedInstruments |
| Exposure Monitoring / Circuit Breaker | Hedge.ExposureBreakdownLog | Hedge.ExposureAlerts, Hedge.ExposureCircuitBreakerThresholds, Hedge.GetCurrentOpenExposure, Hedge.GetCircuitBreakerInstrumentThresholds, Hedge.GetServerCircuitBreakerThresholds |
| KPI Monitoring | Hedge.KPIServerLog | Hedge.KPIInstrumentLog, Hedge.InsertKPIData, Hedge.HedgeServerInstrumentActivity |
| Hedge Recovery / Reconciliation | Hedge.RecoveryLog | Hedge.LogRecovery, Hedge.ClearHedgeExposuresPersistData, Hedge.ClearNetOpenExposuresPersistData |
| Account Position State (Customer Book) | Hedge.AccountStatus | Hedge.AccountStatusOld, Hedge.AccountClosedPositions, Hedge.AccountTransactions, Hedge.AddAccountStatus, Hedge.GetReferenceAccountStatus, Hedge.DelAccountStatus, Hedge.ArchiveAccountStatus |
| Persist Data (Snapshot Buffer) | Hedge.PositionsHedgeTbl | Hedge.PositionsNetOpenDollarTbl, Hedge.SetHedgePersistData, Hedge.SetNetOpenDollarPersistData, Hedge.ClearHedgeExposuresPersistData, Hedge.DeleteZeroRowPositionsHedgePersistData |
| FIX Protocol Connections | Hedge.FIXConnections | Hedge.FIXConnectionDetails, Hedge.GetFIXConnections, Hedge.GetFIXConnectionDetails |
| Provider Tag Management | Hedge.ProviderExternalTags | Hedge.ProviderConditionalTags, Hedge.ConditionalTagsConditions, Hedge.GetProviderExternalTags, Hedge.GetConditionalTags |
| Execution Cost Reporting | Hedge.HedgeCostReport | Hedge.HedgeCostReportHistory, Hedge.HedgeCostReportHistoryPerDay, Hedge.HedgeCostReportHistoryPerHour, Hedge.HedgeCostReportHistoryShell |
| Execution Latency Reporting | Hedge.SSRS_Latency_Report | Hedge.ExecutionLog, Hedge.Report_PriceLatencyTickByTick |
| Open Position Management (Redeem) | Hedge.RedeemedPositions | Hedge.GetListenerRedeemPosition, Hedge.UpdateRedeemedPositions, Hedge.ListenerRedeemPosition (synonym) |
| Manual Hedge Orders | Hedge.ManualOrderExecutionLog | Hedge.InsertManualOrderExecutionLog |
| CES (Customer Execution System) Routing | Hedge.CESInstanceToGroup | Hedge.ExchangeGroups, Hedge.GetCESQuery |
| Customer-Server Routing | Hedge.CIDToHedgeServer | Hedge.GetDefaultHedgeServers |
| Boundary-Based Hedging | Hedge.BoundariesConfiguration | Hedge.InstrumentBoundaries, Hedge.GetBoundariesConfiguration, Hedge.GetInstrumentBoundaries (view), Hedge.GetLimitActiveThresholds |
| Execution Strategy Models | Hedge.ExecutionStrategyModels | Hedge.ExecutionStrategyModelConfigurations, Hedge.ExecutionFactorConfiguration, Hedge.GetSmartExecutionConfigurations, Hedge.GetStrategyExecutionFactorConfiguration |
| Event Logging | Hedge.EventLog | Hedge.InsertHedgeEventLog |
| Open Position Bulk Insert | Hedge.OpenPositionsBulkParameters (UDT) | Hedge.OpenPositionsWithCommissionBulkParameters (UDT), Hedge.InsertOpenPosition, Hedge.InsertOpenPositionBulk, Hedge.InsertOpenPositionBulk_MW |
| Portfolio Conversion (Major Pairs) | Hedge.PortfolioConversionConfigurations | Hedge.ServerConfiguration (ConvertToMajors flag), Hedge.GetPortfolioConversionConfigurations, Hedge.GetMajorsUnits |

---

## Shared Elements

| Element Name | Appears In (Key Objects) | Description |
|-------------|--------------------------|-------------|
| HedgeServerID | Hedge.Netting, Hedge.ExecutionLog, Hedge.RecoveryLog, Hedge.HBCExecutionLog, Hedge.KPIServerLog, Hedge.EventLog, Hedge.ManualOrderExecutionLog | FK to Trade.HedgeServer. Identifies the hedge server instance involved in any operation. Present in virtually all operational tables and logs. |
| LiquidityAccountID | Hedge.Netting, Hedge.ExecutionLog, Hedge.RecoveryLog, Hedge.HBCExecutionLog, Hedge.FIXConnections, Hedge.HedgeServerToLiquidityAccount | FK to Trade.LiquidityAccounts. Identifies the specific LP account used for execution. Different from Hedge.Accounts.ID which is the Hedge-schema account registry. |
| InstrumentID | Hedge.Netting, Hedge.ExecutionLog, Hedge.InstrumentConfiguration, Hedge.InstrumentBoundaries, Hedge.HBCAccountConfiguration, Hedge.KPIInstrumentLog | Implicit FK to Trade.Instrument. The financial instrument being traded or configured. High-cardinality key across all execution and configuration tables. |
| IsBuy | Hedge.Netting, Hedge.ExecutionLog, Hedge.RecoveryLog, Hedge.HBCExecutionLog, Hedge.AccountClosedPositions | Direction of the hedge order/position: 1=Buy (long), 0=Sell (short). From eToro's perspective - a buy hedge offsets a net short customer book. |
| Units / AmountInUnits | Hedge.Netting, Hedge.ExecutionLog, Hedge.HBCExecutionLog, Hedge.PositionsHedgeTbl | Quantity of the instrument being hedged. High-precision decimal (22,8 in ExecutionLog, 16,2 in Netting) to support crypto fractional quantities. |
| SysStartTime / SysEndTime | Hedge.Netting, Hedge.Accounts, Hedge.FIXConnections, Hedge.FIXConnectionDetails | Temporal versioning columns. SysEndTime=9999-12-31 indicates the current (live) row; historical versions archived in History.* shadow tables. |
| LogTime / Time | Hedge.ExecutionLog, Hedge.EventLog, Hedge.RecoveryLog, Hedge.ManualOrderExecutionLog | DB server UTC timestamp at row insert. Used as clustered index keys for time-ordered append logs. Set to GETUTCDATE() server-side. |
| IsActive | Hedge.Accounts, Hedge.InstrumentConfiguration, Hedge.ActiveHedgingAccounts | Soft-delete flag: 1=active (included in operational queries), 0=disabled (retained for history). Pattern used across registry tables. |
| AvgRate / ExecutionRate | Hedge.Netting, Hedge.ExecutionLog, Hedge.HBCExecutionLog | Custom `dbo.dtPrice` type. Volume-weighted average entry rate for netting positions; fill price in execution logs. Used in PnL calculation: `SUM(Units * ExecutionRate) / SUM(Units)`. |
| RecoveryID | Hedge.RecoveryLog | GUID grouping all log entries from one recovery session. App-generated (not IDENTITY). Enables full replay and analysis of a specific reconciliation event. |

---

## Cross-Schema Dependencies

| External Object | Schema | Used By (Hedge Objects) | Role |
|----------------|--------|------------------------|------|
| Trade.HedgeServer | Trade | Virtually all Hedge tables and SPs | Master hedge server registry - FK target for HedgeServerID everywhere |
| Trade.LiquidityAccounts | Trade | Hedge.Netting, Hedge.ExecutionLog, Hedge.RecoveryLog, Hedge.HBCExecutionLog, Hedge.FIXConnections, Hedge.Accounts | LP account master - FK target for LiquidityAccountID |
| Trade.Instrument | Trade | Hedge.InstrumentConfiguration, Hedge.Netting, Hedge.ExecutionLog, Hedge.HBCAccountConfiguration | Instrument master - implicit FK for InstrumentID |
| Trade.LiquidityProviderType | Trade | Hedge.Accounts, Hedge.ProviderUnitConversionRatio, Hedge.ProviderInstrumentConfiguration | Provider type classification |
| Dictionary.HedgeOrderState | Dictionary | Hedge.ExecutionLog | Execution lifecycle states (0-7) |
| Dictionary.HedgeAccountType | Dictionary | Hedge.Accounts | Account type classification (2=Execution, 4=Pricing) |
| Dictionary.HedgeRecoveryState | Dictionary | Hedge.RecoveryLog | Recovery action type (0-4) |
| Dictionary.HedgeServerExposureMode | Dictionary | Hedge.ServerConfiguration, Hedge.HedgeServerExposureModeConfiguration | Exposure mode enum (0-3) |
| Dictionary.HedgeServerExecutionStrategy | Dictionary | Hedge.ServerConfiguration | Execution strategy enum (0-1) |
| Dictionary.HedgeStrategyMode | Dictionary | Hedge.InstrumentConfiguration, Hedge.HedgeServerInstrumentConfiguration | Hedging strategy selection |
| Customer.CustomerStatic | Customer | Hedge.CIDToHedgeServer | Customer-to-server routing (via CID) |
| dbo.dtPrice | dbo | Hedge.Netting, Hedge.ExecutionLog, Hedge.RecoveryLog, Hedge.HBCExecutionLog | Custom high-precision price UDT |

---

## Temporal Tables (System-Versioned)

| Table | History Table | Key Temporal Concept |
|-------|--------------|---------------------|
| Hedge.Netting | History.Netting_History | Current hedge book positions - every position change archived |
| Hedge.Accounts | History.Accounts | LP account registry - every account update archived |
| Hedge.FIXConnections | (History schema) | FIX connection state changes |
| Hedge.FIXConnectionDetails | (History schema) | FIX connection parameter history |

---

## Key Architectural Patterns

### Pattern 1: Execution Dual Path (Legacy vs EMS)
- **Legacy/HedgeServer path**: `ExecutionLog.OrderID > 0`, `ParentOrderID` = GUID, `EMSOrderID` = NULL
- **EMS/HBC path**: `ExecutionLog.OrderID = -1` (sentinel), `EMSOrderID` = `{ExternalID}_{sequence}`
- Affects: Hedge.ExecutionLog, Hedge.LogExecution, Hedge.ExecutionLogInsertBulk, Hedge.SSRS_Latency_Report, Hedge.GetExecutionLogData

### Pattern 2: Netting Upsert Semantics
- Hedge.Netting maintains exactly ONE position per (LiquidityAccountID, InstrumentID) via AddOrUpdateNetting
- PK has ValueDate as 3rd component but UPDATE does not filter on ValueDate - the PK uniqueness on 3 columns is a design artifact
- Cleanup: RemoveNetting (single row), RemoveBadNetting (single LP exclusion), RemoveMultiBadNetting (multi-LP set exclusion)

### Pattern 3: Persist Data Buffer Pattern
- Hedge.PositionsHedgeTbl and Hedge.PositionsNetOpenDollarTbl are SET-and-CLEAR snapshot buffers
- Written by SetHedgePersistData / SetNetOpenDollarPersistData (bulk upsert via TVP)
- Cleared by ClearHedgeExposuresPersistData / ClearNetOpenExposuresPersistData (TRUNCATE)
- Pruned by DeleteZeroRowPositionsHedgePersistData

### Pattern 4: Archive Tables (not System-Versioned)
- Hedge.NettingOld, Hedge.AccountStatusOld: manual archive tables (pre-temporal-versioning era)
- Hedge.ExposureAlerts: legacy 2014 archive table - no longer written

### Pattern 5: Cross-Server Insert Pattern
- AddExpsosureAlert_Child: 3-part name (`etoro.Hedge.ExposureAlerts`) for cross-database insert on same server
- AddExpsosureAlert_old: linked-server insert to `[AO-REAL-DB].etoro.Hedge.ExposureAlerts`
- Reflects multi-server hedge architecture history

---

*Generated: 2026-03-19 | Phase 12 Cross-Object Enrichment | etoro Hedge Schema*
