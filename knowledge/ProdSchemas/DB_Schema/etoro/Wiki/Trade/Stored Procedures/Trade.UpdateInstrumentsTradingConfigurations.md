# Trade.UpdateInstrumentsTradingConfigurations

> Performs a partial update of instrument trading configuration fields on Trade.ProviderToInstrument for a batch of instruments, applying only the non-null fields from the input TVP, and records each configuration change in Trade.SyncConfiguration for downstream synchronization.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTbl.InstrumentID - identifies instruments to update |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the central workhorse for updating instrument trading configuration parameters stored in Trade.ProviderToInstrument. It controls every risk, permission, and order-type setting for how an instrument can be traded: from stop-loss and take-profit percentages, to whether buy/sell orders are allowed, to precision and market range settings. With 39 configurable fields across ProviderToInstrument, this procedure provides fine-grained control over instrument trading rules.

The procedure uses a null-safe partial update pattern: every field in the input TVP is nullable, and a NULL value means "leave this field unchanged." This design allows callers to update just one or a few fields without providing a full configuration record, reducing the risk of accidentally overwriting unrelated settings.

The second input TVP (@InstrumentSyncConfigurationAddTable) triggers synchronization events. For every configuration change, a record is inserted into Trade.SyncConfiguration with the update type and new value. This table is polled or processed by downstream services to propagate configuration changes to connected trading systems in near real-time.

---

## 2. Business Logic

### 2.1 Null-Safe Partial Update Pattern

**What**: Any field left NULL in the input TVP is silently preserved at its current value. Only explicitly provided (non-null) values are applied.

**Columns/Parameters Involved**: All 39 configuration fields in `@InstrumentNewConfigTbl`

**Rules**:
- Pattern: `IIF(INCT.Field IS NULL, TPTI.Field, INCT.Field)` applied to every column
- A null input value = "don't change this field" - the existing value is preserved
- A non-null input value = "update this field" - the new value is applied
- This allows callers to send sparse updates without risk of zeroing out unrelated configuration

**Diagram**:
```
For each instrument in @InstrumentNewConfigTbl:
  For each of 39 config fields:
    INCT.Field IS NULL?
      YES --> Keep TPTI.Field (no change)
      NO  --> Set TPTI.Field = INCT.Field (apply new value)
```

### 2.2 Configuration Change Synchronization

**What**: Every call to this procedure records the configuration changes in Trade.SyncConfiguration, triggering downstream trading system updates.

**Columns/Parameters Involved**: `@InstrumentSyncConfigurationAddTable.InstrumentID`, `@InstrumentSyncConfigurationAddTable.ConfigurationUpdateTypeID`, `@InstrumentSyncConfigurationAddTable.Value`

**Rules**:
- The second TVP is inserted verbatim into Trade.SyncConfiguration without any transformation
- ConfigurationUpdateTypeID identifies what type of configuration changed (looked up from a dictionary table)
- Value stores the new configuration value as a string (up to 1000 chars)
- The INSERT and the ProviderToInstrument UPDATE are in the same transaction - either both commit or neither does
- If @InstrumentSyncConfigurationAddTable is empty, no SyncConfiguration rows are inserted (but the ProviderToInstrument update still runs)

**Diagram**:
```
BEGIN TRANSACTION
  UPDATE ProviderToInstrument (partial, null-safe)
  INSERT INTO SyncConfiguration (all rows from second TVP)
COMMIT -- or ROLLBACK on any error
```

### 2.3 Risk Limit Fields

**What**: Controls the boundaries within which positions can be opened or stopped.

**Columns/Parameters Involved**: `MaxStopLossPercentage`, `MinStopLossPercentage`, `MaxTakeProfitPercentage`, `MinTakeProfitPercentage`, `MaxPositionUnits`, `MinPositionAmount`, `MarketRange`, `AllowedRateDiffPercentage`

**Rules**:
- MaxStopLossPercentage / MinStopLossPercentage: define the allowed range for SL distance from entry price
- MaxTakeProfitPercentage / MinTakeProfitPercentage: define the allowed range for TP distance
- MaxPositionUnits: maximum units a customer can hold for this instrument
- MinPositionAmount: minimum dollar amount per position
- MarketRange: maximum price slippage allowed on order execution
- AllowedRateDiffPercentage: maximum rate difference allowed between order creation and execution

### 2.4 Order Permission Flags

**What**: Controls which order types are allowed for this instrument-provider combination.

**Columns/Parameters Involved**: `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowClosePosition`, `AllowExitOrder`, `AllowEditSLTP`, `AllowEditTakeProfit`, `AllowEditStopLoss`, `AllowEditTakeProfitLeveraged`, `AllowEditStopLossLeveraged`, `AllowTrailingStopLoss`, `AllowRedeem`

**Rules**:
- AllowBuy = 0: no long positions can be opened for this instrument
- AllowSell = 0: no short positions can be opened for this instrument
- AllowPendingOrders: controls whether market-range/limit orders are permitted
- AllowEntryOrders: controls whether entry orders (stop/limit entry) are permitted
- AllowClosePosition: when 0, existing positions cannot be manually closed
- AllowRedeem: controls whether physical redemption of stock is allowed
- Leveraged/NonLeveraged variants (AllowLeveragedLongSL etc.) provide granular control per position type

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTbl | Trade.InstrumentsTradingConfigTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of instrument trading configuration updates. InstrumentID is the key; all 39 other fields are nullable. NULL value = preserve current setting; non-null value = apply update. See Trade.ProviderToInstrument documentation for full field meanings. |
| 2 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Sync event records to insert into Trade.SyncConfiguration after the ProviderToInstrument update. Contains InstrumentID, ConfigurationUpdateTypeID (type of change), and Value (new value as string). Inserted verbatim in same transaction. Can be empty (no sync events generated). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTbl.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | All 39 configuration fields updated using null-safe IIF pattern |
| @InstrumentSyncConfigurationAddTable | Trade.SyncConfiguration | INSERT | Configuration change events inserted for downstream synchronization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateFuturesTradingConfigurations | EXEC call | Caller | Calls this procedure as part of the futures-specific trading configuration update flow |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsTradingConfigurations (procedure)
├── Trade.ProviderToInstrument (table) [partial UPDATE - 39 fields with null-safe IIF]
└── Trade.SyncConfiguration (table) [INSERT - sync events for downstream systems]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATEd: 39 trading configuration columns updated using null-safe IIF pattern |
| Trade.SyncConfiguration | Table | INSERTed: configuration change events recorded for downstream sync processing |
| Trade.InstrumentsTradingConfigTbl | User Defined Type | TVP type for @InstrumentNewConfigTbl |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateFuturesTradingConfigurations | Procedure | Calls this procedure to apply futures-specific trading configuration changes |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Null-safe partial update | Logic | IIF(INCT.Field IS NULL, TPTI.Field, INCT.Field) for all 39 ProviderToInstrument fields. NULL in TVP means preserve current value. |
| Atomic transaction | TRY/CATCH | Both the ProviderToInstrument UPDATE and SyncConfiguration INSERT are in a single transaction. ROLLBACK on any error via THROW. |
| SET NOCOUNT ON | Session setting | Suppresses row-count messages for performance in batch contexts. |

---

## 8. Sample Queries

### 8.1 Disable buy and sell orders for an instrument

```sql
DECLARE @Config [Trade].[InstrumentsTradingConfigTbl]
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell)
VALUES (1234, 0, 0)  -- Only these two fields; all others remain unchanged

DECLARE @Sync [Trade].[SyncConfigurationAdd]
INSERT INTO @Sync (InstrumentID, ConfigurationUpdateTypeID, [Value])
VALUES (1234, 1, 'AllowBuy=0'), (1234, 2, 'AllowSell=0')

EXEC Trade.UpdateInstrumentsTradingConfigurations
    @InstrumentNewConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.2 Update risk limits for multiple instruments with no sync events

```sql
DECLARE @Config [Trade].[InstrumentsTradingConfigTbl]
INSERT INTO @Config (InstrumentID, MaxStopLossPercentage, MaxTakeProfitPercentage)
VALUES
    (1234, 50.0, 1000.0),
    (5678, 25.0, 500.0)

DECLARE @Sync [Trade].[SyncConfigurationAdd]
-- Empty - no sync events

EXEC Trade.UpdateInstrumentsTradingConfigurations
    @InstrumentNewConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.3 Verify current trading configuration for an instrument

```sql
SELECT
    tpti.InstrumentID,
    tpti.AllowBuy,
    tpti.AllowSell,
    tpti.MaxStopLossPercentage,
    tpti.MinStopLossPercentage,
    tpti.MaxPositionUnits,
    tpti.MinPositionAmount,
    tpti.AllowRedeem,
    tpti.GuaranteeSLTP,
    tpti.AllowTrailingStopLoss
FROM Trade.ProviderToInstrument tpti WITH (NOLOCK)
WHERE tpti.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsTradingConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsTradingConfigurations.sql*
