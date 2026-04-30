# Trade Schema - Overview

> The Trade schema is the core transactional and configuration schema of the eToro platform. It owns the position lifecycle (open, live, close), order processing, instrument configuration, pricing, fee structures, copy trading mechanics, and US regulatory reporting. It is the largest schema in the etoro database.

---

## Schema Identity

| Property | Value |
|----------|-------|
| **Database** | etoro |
| **Schema** | Trade |
| **Total Objects** | 1,422 |
| **Documentation Complete** | 2026-03-18 |
| **Total Batches** | 53 |

---

## Object Inventory

| Type | Count | Description |
|------|-------|-------------|
| Tables | 167 | Core transactional, configuration, and queue tables |
| Views | 117 | Reporting, aggregation, and convenience projections |
| Functions | 66 | Scalar, inline TVF, and multi-statement TVF helpers |
| Stored Procedures | 923 | All write operations, reporting, and business logic |
| Synonyms | 23 | Cross-schema/cross-DB name aliases |
| User Defined Types | 126 | TVP types (table parameters) and scalar types |

---

## Domain Map

The Trade schema covers 8 major business domains:

### 1. Position Lifecycle
The central domain. A position is a leveraged or non-leveraged trade by a customer on a financial instrument.

**Key Tables**: `Trade.PositionTbl` (live positions), `History.PositionSlim` (closed - cross-schema), `Trade.Position` (queryable view-like table)

**Key SPs**: `Trade.PositionOpen`, `Trade.PositionClose`, `Trade.OrderForOpenCreate`, `Trade.OrderForCloseCreate`

**Key Views**: `Trade.vw_LivePositions*` (various), `Trade.vw_HistoryPositions*`

**Lifecycle**:
```
Customer request -> OrderForOpen/Close -> ExecutionPlan -> ExecutedOrders -> PositionTbl
                                                                          |
                                         (position closed) -> History.PositionSlim
```

### 2. Order Processing
The two-phase execution model: orders are created, planned, and executed.

**Key Tables**: `Trade.OrderForOpen`, `Trade.OrderForClose`, `Trade.OpenExecutionPlan`, `Trade.CloseExecutionPlan`, `Trade.ExecutedOpenOrders`, `Trade.ExecutedCloseOrders`

**Historical archive**: `DB_Logs.History.*` mirrors (cross-DB)

**Bulk orders**: A single OrderID triggers multiple positions (copy trading, Close All). See `Trade.ViewBulkOrders`.

### 3. Copy Trading (Mirror System)
eToro's social trading feature where copiers automatically replicate leaders' trades.

**Key Tables**: `Trade.Mirror` (active copy relationships), `Trade.PositionTreeInfo` (copy tree rates), `Trade.DemoTreeToSplitFromReal` (stock split propagation queue)

**Key SPs**: `Trade.RegisterMirror`, `Trade.MirrorPauseCopy`, `Trade.MirrorReopen`, `Trade.UpdateTreeFromRealForSplit`

**Concepts**: MirrorID (0 = self-directed, non-0 = copy position), TreeID (copy relationship hierarchy), NtileTreeID (parallel processing partition)

### 4. Instrument Configuration
All configuration for tradable instruments: metadata, pricing, fees, leverage, spread groups.

**Key Tables**: `Trade.InstrumentMetaData`, `Trade.ProviderToInstrument`, `Trade.SpreadGroup`, `Trade.FeeInPercentageConfigurations`, `Trade.FixPerLotConfigurations`

**Key Configuration SPs**: `Trade.UpdateInstrumentsTradingConfigurations`, `Trade.UpdateProviderToInstrumentOverNightFee`, `Trade.ValidateFeeInPercentageConfigurations`, `Trade.ValidateFixPerLotConfigurations`

**Instrument types** (InstrumentTypeID from Dictionary): 10=Crypto, others for stocks, forex, indices, commodities

**Exchange mapping**: ExchangeID 4+5 = US exchanges (NYSE/NASDAQ)

### 5. Fee System
Three fee mechanisms operate in parallel:

| Mechanism | Table | Description |
|-----------|-------|-------------|
| Overnight/Rollover Fee | `Trade.ProviderToInstrument.BuyOverNightFee/SellOverNightFee` | Daily charge for holding leveraged positions |
| Fee In Percentage | `Trade.FeeInPercentageConfigurations` | Fee as % of trade value, keyed by Instrument/Type/Group x IsSettled x FeeOperationTypeID |
| Fix Per Lot | `Trade.FixPerLotConfigurations` | Fixed fee per lot/unit, same keying structure |

Overnight fee updates are guarded by `Trade.UpdateProviderToInstrumentOverNightFee` (10%/400% day-of-week thresholds).

### 6. Liquidity Provider & Routing
Manages how orders are routed to external market liquidity.

**Key Tables**: `Trade.LiquidityProvider`, `Trade.LiquidityProviderContract`, `Trade.TradonomiContract`, `Trade.TradonomiToLiquidityProviderContracts`

**Key SPs**: `Trade.SetTradonomiToLPContracts`, `Trade.UpdateTradonomiToLiquidityProviderContracts`, `Trade.SetNextLiquidityProviderID`

**Routing model**: Tradonomi contracts (internal agreements) map to Liquidity Provider contracts (external agreements). See `Trade.UpdateTradonomiToLiquidityProviderContracts` for the XML-driven batch update pattern.

### 7. US Regulatory & Compliance
Reports and monitoring for US-regulated customers (Apex Clearing integration).

**Key SPs**: `Trade.USAggregatePositionBySymbol`, `Trade.USAggregatePositionBySymbolForMonitor`, `Trade.UsUsersCryptoStat`

**US customer identification**: Customer.CustomerStatic.ApexID IS NOT NULL (Apex Clearing account required), CountryGroupID=4 (US country group)

**Apex limits monitored**: $4M daily gross notional value, 40,000 shares per instrument

### 8. Admin & Operations Tooling
Procedures used by the OPS/BI admin layer for configuration management and diagnostics.

**Pattern**: XML-driven or TVP-driven batch updates with CONTEXT_INFO audit trail for caller identity

**Key SPs**: `Trade.UpdateTradingInstrumentGroupName` (CONTEXT_INFO + TVP), all `Trade.Update*Configurations*` procedures (OpsFlowAPI / trading-opstool-api)

**JUNK prefix**: Procedures prefixed with `JUNK_` (e.g., `Trade.JUNK_ChangeMirrorAmount`) are deprecated/decommissioned but retained for historical reference.

---

## Key Cross-Schema Dependencies

| External Schema | Nature of Dependency |
|----------------|---------------------|
| Dictionary | Lookup tables for all enum/status/type columns (InstrumentType, PositionStatus, OrderType, CountryGroup, etc.) |
| Customer | CustomerStatic (CID/ApexID/CountryID), BlockedCustomerOperations (public/private status) |
| History | PositionSlim, PositionFail, PositionSplit (closed position archive, cross-schema) |
| DB_Logs.History | Order archive tables (OrderForOpen/Close, ExecutedOrders, ExecutionPlans) in separate database |

---

## Key Patterns

### XML-Driven Batch Updates
Several configuration SPs use XML as the input protocol, e.g.:
```sql
<ROOT>
  <ADD TradonomiContractID="1" LiquidityProviderContractID="3"/>
  <DELETE TradonomiContractID="1" LiquidityProviderContractID="2"/>
</ROOT>
```
All XML-driven SPs use BEGIN TRY/COMMIT + CATCH/ROLLBACK with RETURN(0/-1).

### TVP-Driven Batch Updates
More modern SPs use Table-Valued Parameters (Trade.*Tbl, Trade.*List, Trade.*Table types). The 126 User Defined Types in this schema are predominantly TVP types supporting this pattern.

### CONTEXT_INFO Audit Trail
OPS-facing SPs accept `@AppLoginName VARCHAR(50)` and set `CONTEXT_INFO = CAST(@AppLoginName AS VARBINARY(128))` for trigger-based auditing.

### Parallel Processing via NtileTreeID
The copy tree split propagation uses NtileTreeID (1..N) to partition work across parallel SQL Agent jobs, each calling `Trade.UpdateTreeFromRealForSplit` with a different @ParallelID.

### Fee Conflict Prevention
The 6-rule validation pattern (used in both `ValidateFeeInPercentageConfigurations` and `ValidateFixPerLotConfigurations`) prevents conflicting IsSettled x FeeOperationTypeID combinations using NULL-safe scope matching.

---

## API Consumers

| API / Service | Permission Pattern | Key SPs |
|--------------|-------------------|---------|
| OpsFlowAPI | EXECUTE grants | UpdateTradingInstrumentGroupName, all Ops config SPs |
| trading-opstool-api | EXECUTE grants | UpdateTradingInstrumentGroupName, instrument config SPs |
| TDAPIUserProd / TDAPIUser | EXECUTE grants | VerifyPublicUser, TAPI_Get* SPs, TDAPI_Get* SPs |
| PROD_BIadmins | EXECUTE grants | UpdateProviderToInstrumentOverNightFee, UpdateTradonomiToLiquidityProviderContracts, admin SPs |
| Nagios monitoring | EXECUTE grants | UsUsersCryptoStat, monitoring SPs |

---

## Documentation Statistics

| Metric | Value |
|--------|-------|
| Objects documented | 1,422 / 1,422 (100%) |
| Average quality score | 9.0 / 10 |
| Total documentation batches | 53 |
| Documentation started | 2026-03-18 |
| Documentation completed | 2026-03-18 |
| Phase 12 enrichment | 2026-03-18 |

---

*Schema Overview Generated: 2026-03-18 | Trade Schema Documentation Complete*
