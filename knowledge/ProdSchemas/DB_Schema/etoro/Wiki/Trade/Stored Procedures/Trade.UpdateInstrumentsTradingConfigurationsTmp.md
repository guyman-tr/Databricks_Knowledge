# Trade.UpdateInstrumentsTradingConfigurationsTmp

> Legacy subset variant of Trade.UpdateInstrumentsTradingConfigurations that updates 30 of the 40 trading configuration fields on Trade.ProviderToInstrument using the same null-safe partial update pattern, but excludes newer fields (redeem settings, leveraged SL/TP edit permissions, precision, market range, and designated execution system).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewConfigTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure performs the same function as Trade.UpdateInstrumentsTradingConfigurations but uses a reduced TVP type (InstrumentsTradingConfigTblTmp) that contains 30 configurable fields rather than the full 40. The "Tmp" (temporary) suffix indicates this was created as an interim version before newer fields were added to the full procedure.

The 10 fields present in the full version but absent here are: AllowRedeem, MinPositionUnitsForRedeem, MaxPositionUnitsForRedeem, AllowEditTakeProfitLeveraged, AllowEditStopLossLeveraged, DefaultStopLossPercentageLeveraged, DefaultStopLossPercentageNonLeveraged, Precision, MarketRange, and DesignatedExecutionSystem. These were all added in later iterations of the instrument configuration system.

No internal callers were found within the Trade stored procedure layer, suggesting this procedure is called directly from an external administrative application that has not yet been updated to use the full InstrumentsTradingConfigTbl TVP type. The full version (Trade.UpdateInstrumentsTradingConfigurations) should be preferred for new implementations.

---

## 2. Business Logic

### 2.1 Null-Safe Partial Update Pattern (30 Fields)

**What**: Identical null-safe IIF pattern as the full version - NULL means "leave unchanged," non-null means "apply this value."

**Columns/Parameters Involved**: All 30 nullable fields in `@InstrumentNewConfigTbl`

**Rules**:
- Pattern: `IIF(INCT.Field IS NULL, TPTI.Field, INCT.Field)` for all 30 fields
- NULL input = preserve current value on ProviderToInstrument
- Non-null input = apply new value
- Identical semantics to Trade.UpdateInstrumentsTradingConfigurations for the shared 30 fields

### 2.2 Missing Fields vs Full Version

**What**: Ten fields available in the full version cannot be updated via this procedure.

**Columns/Parameters Involved**: AllowRedeem, MinPositionUnitsForRedeem, MaxPositionUnitsForRedeem, AllowEditTakeProfitLeveraged, AllowEditStopLossLeveraged, DefaultStopLossPercentageLeveraged, DefaultStopLossPercentageNonLeveraged, Precision, MarketRange, DesignatedExecutionSystem

**Rules**:
- These 10 fields cannot be included in the TVP - the type does not have those columns
- If these fields need updating, Trade.UpdateInstrumentsTradingConfigurations must be used instead
- Existing values of these 10 fields on ProviderToInstrument are always preserved

**Diagram**:
```
Fields in Tmp version (30):
  Risk limits: MaxStopLossPercentage, MinStopLossPercentage, MaxTakeProfitPercentage,
               MinTakeProfitPercentage, MaxPositionUnits, MinPositionAmount,
               AllowedRateDiffPercentage
  Order perms: AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders,
               AllowClosePosition, AllowExitOrder, GuaranteeSLTP, AllowEditSLTP
  SL/TP:       AllowEditStopLoss, AllowEditTakeProfit, AllowTrailingStopLoss,
               DefaultTrailingStopLoss, DefaultStopLossPercentage, DefaultTakeProfitPercentage
  Granular:    AllowLeveragedLongSL, AllowNonLeveragedLongSL, AllowLeveragedShortSL,
               AllowNonLeveragedShortSL, AllowLeveragedLongTP, AllowNonLeveragedLongTP,
               AllowLeveragedShortTP, AllowNonLeveragedShortTP, VisibleInternallyOnly

Fields ONLY in full version (10):
  AllowRedeem, MinPositionUnitsForRedeem, MaxPositionUnitsForRedeem
  AllowEditTakeProfitLeveraged, AllowEditStopLossLeveraged
  DefaultStopLossPercentageLeveraged, DefaultStopLossPercentageNonLeveraged
  Precision, MarketRange, DesignatedExecutionSystem
```

### 2.3 Configuration Change Synchronization

**What**: Sync events are inserted into Trade.SyncConfiguration alongside the ProviderToInstrument update.

**Columns/Parameters Involved**: `@InstrumentSyncConfigurationAddTable`

**Rules**:
- Identical to the full version - all rows from the second TVP are inserted verbatim into Trade.SyncConfiguration
- Both the UPDATE and INSERT are in the same transaction

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewConfigTbl | Trade.InstrumentsTradingConfigTblTmp (TVP, READONLY) | NO | - | CODE-BACKED | Batch of instrument trading configuration updates using the legacy 30-field TVP type. InstrumentID is the key; all 30 other fields are nullable (NULL = no change). Subset of the full InstrumentsTradingConfigTbl - missing redeem settings, leveraged SL/TP edit permissions, precision, market range, and designated execution system. See Trade.UpdateInstrumentsTradingConfigurations for the full 40-field version. |
| 2 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Configuration change sync event records. Identical to the full version - rows are inserted verbatim into Trade.SyncConfiguration (InstrumentID, ConfigurationUpdateTypeID, Value). Can be empty. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewConfigTbl.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | 30 configuration fields updated using null-safe IIF pattern |
| @InstrumentSyncConfigurationAddTable | Trade.SyncConfiguration | INSERT | Configuration change events inserted for downstream synchronization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External configuration tooling | Application call | Caller | No internal SP callers found; called directly from an external administrative application using the legacy Tmp TVP type |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsTradingConfigurationsTmp (procedure)
├── Trade.ProviderToInstrument (table) [partial UPDATE - 30 fields with null-safe IIF]
└── Trade.SyncConfiguration (table) [INSERT - sync events]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATEd: 30 trading configuration columns updated using null-safe IIF pattern |
| Trade.SyncConfiguration | Table | INSERTed: configuration change events for downstream sync |
| Trade.InstrumentsTradingConfigTblTmp | User Defined Type | TVP type for @InstrumentNewConfigTbl; legacy 30-field version of InstrumentsTradingConfigTbl |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External application (legacy) | Application | Calls this procedure using the legacy Tmp TVP type; should migrate to Trade.UpdateInstrumentsTradingConfigurations |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Null-safe partial update | Logic | IIF(INCT.Field IS NULL, TPTI.Field, INCT.Field) for all 30 ProviderToInstrument fields |
| Atomic transaction | TRY/CATCH | Both UPDATE and INSERT in single transaction, ROLLBACK on error, COMMIT on nested via THROW |
| Legacy reduced scope | Design | 10 fields from the full procedure are not updatable via this Tmp version; these fields retain their current ProviderToInstrument values |

---

## 8. Sample Queries

### 8.1 Update buy/sell permissions using legacy TVP type

```sql
DECLARE @Config [Trade].[InstrumentsTradingConfigTblTmp]
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell)
VALUES (1234, 0, 0)

DECLARE @Sync [Trade].[SyncConfigurationAdd]
-- Empty

EXEC Trade.UpdateInstrumentsTradingConfigurationsTmp
    @InstrumentNewConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.2 Update risk limits (Tmp version does not support Precision or DesignatedExecutionSystem)

```sql
DECLARE @Config [Trade].[InstrumentsTradingConfigTblTmp]
INSERT INTO @Config (InstrumentID, MaxStopLossPercentage, MaxTakeProfitPercentage)
VALUES (1234, 50.0, 1000.0)

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsTradingConfigurationsTmp
    @InstrumentNewConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.3 Check which fields are missing compared to the full version

```sql
-- Use the full version to update fields not available in Tmp
-- (AllowRedeem, Precision, MarketRange, DesignatedExecutionSystem, etc.)
DECLARE @FullConfig [Trade].[InstrumentsTradingConfigTbl]
INSERT INTO @FullConfig (InstrumentID, AllowRedeem, Precision, MarketRange)
VALUES (1234, 1, 2, 100)

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsTradingConfigurations
    @InstrumentNewConfigTbl = @FullConfig,
    @InstrumentSyncConfigurationAddTable = @Sync
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsTradingConfigurationsTmp | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsTradingConfigurationsTmp.sql*
