# Trade.UpdateInstrumentsTradingOrdersConfigurations

> Focused update procedure that sets only the six order-type permission flags on Trade.ProviderToInstrument (AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, AllowExitOrder, VisibleInternallyOnly) for a batch of instruments, using null-safe partial update semantics and recording sync events.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @InstrumentNewOrdersConfigTbl.InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure provides a targeted update path for the six order-type permission flags on ProviderToInstrument. Unlike the broad Trade.UpdateInstrumentsTradingConfigurations (which updates 40 fields), this procedure has a narrow, intentional scope: controlling which order types are allowed for a given instrument and whether the instrument is visible to the public or internal-only.

The six fields managed here represent the core "can this instrument be traded, and in what ways" decision point: AllowBuy/AllowSell control direction, AllowPendingOrders/AllowEntryOrders control order types, AllowExitOrder controls whether stop orders on existing positions can be placed, and VisibleInternallyOnly determines if the instrument is accessible to all customers or only to internal eToro accounts.

This procedure is designed for high-frequency operational use cases such as emergency instrument halts (quickly disable AllowBuy and AllowSell), visibility restrictions, or order-type restrictions imposed by regulatory requirements or market conditions. The focused TVP type InstrumentsOrdersConfigTbl makes the call site explicit about what is being changed.

---

## 2. Business Logic

### 2.1 Null-Safe Order Permission Update

**What**: Each of the 6 permission flags can be updated independently; NULL values leave the current setting unchanged.

**Columns/Parameters Involved**: `AllowBuy`, `AllowSell`, `AllowPendingOrders`, `AllowEntryOrders`, `AllowExitOrder`, `VisibleInternallyOnly`

**Rules**:
- IIF(INOC.Field IS NULL, TPTI.Field, INOC.Field) applied to all 6 fields
- Caller can pass just AllowBuy = 0 with all other fields NULL to halt buy orders for an instrument
- All six fields are BIT (0/1) in the TVP and on ProviderToInstrument

**Diagram**:
```
Order permission flags (all null-safe):
  AllowBuy:             1 = customers can open long positions
                        0 = long order entry is blocked
  AllowSell:            1 = customers can open short positions
                        0 = short order entry is blocked
  AllowPendingOrders:   1 = market-range/pending orders allowed
                        0 = pending orders blocked
  AllowEntryOrders:     1 = entry (stop/limit entry) orders allowed
                        0 = entry orders blocked
  AllowExitOrder:       1 = exit orders (SL/TP as standalone orders) allowed
                        0 = exit orders blocked
  VisibleInternallyOnly: 1 = instrument hidden from public customers
                          0 = instrument visible to all
```

### 2.2 Configuration Change Synchronization

**What**: Sync events are inserted into Trade.SyncConfiguration alongside the permission changes.

**Columns/Parameters Involved**: `@InstrumentSyncConfigurationAddTable`

**Rules**:
- Identical to Trade.UpdateInstrumentsTradingConfigurations: rows from second TVP inserted verbatim into SyncConfiguration
- Both operations share one transaction

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @InstrumentNewOrdersConfigTbl | Trade.InstrumentsOrdersConfigTbl (TVP, READONLY) | NO | - | CODE-BACKED | Batch of order permission updates. InstrumentID is the required key; all 6 permission fields (AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, AllowExitOrder, VisibleInternallyOnly) are nullable BIT. NULL = preserve current value; 0 = disable; 1 = enable. Focused subset of the full InstrumentsTradingConfigTbl - updates only order-type permission flags. |
| 2 | @InstrumentSyncConfigurationAddTable | Trade.SyncConfigurationAdd (TVP, READONLY) | NO | - | CODE-BACKED | Configuration change sync event records. Rows inserted verbatim into Trade.SyncConfiguration (InstrumentID, ConfigurationUpdateTypeID, Value). Can be empty. Both the permission update and sync insert are in the same transaction. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentNewOrdersConfigTbl.InstrumentID | Trade.ProviderToInstrument | Implicit JOIN | 6 order permission flags updated using null-safe IIF pattern |
| @InstrumentSyncConfigurationAddTable | Trade.SyncConfiguration | INSERT | Configuration change events recorded for downstream synchronization |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| External configuration tooling | Application call | Caller | No internal SP callers found; called from operational tooling for targeted order-permission changes |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.UpdateInstrumentsTradingOrdersConfigurations (procedure)
├── Trade.ProviderToInstrument (table) [UPDATE - 6 order permission flags]
└── Trade.SyncConfiguration (table) [INSERT - sync events]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | UPDATEd: AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, AllowExitOrder, VisibleInternallyOnly |
| Trade.SyncConfiguration | Table | INSERTed: configuration change events |
| Trade.InstrumentsOrdersConfigTbl | User Defined Type | TVP type for @InstrumentNewOrdersConfigTbl |
| Trade.SyncConfigurationAdd | User Defined Type | TVP type for @InstrumentSyncConfigurationAddTable |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| External operational tooling | Application | Calls this procedure for targeted order-permission updates (emergency halts, regulatory restrictions) |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| Null-safe partial update | Logic | IIF(INOC.Field IS NULL, TPTI.Field, INOC.Field) for all 6 permission flags |
| Atomic transaction | TRY/CATCH | UPDATE and INSERT in single transaction; ROLLBACK on error, COMMIT on nested transactions |
| Narrow scope | Design | Only 6 fields vs 40 in the full procedure - intentional design for targeted order-permission updates |

---

## 8. Sample Queries

### 8.1 Halt trading on an instrument (disable buy and sell)

```sql
DECLARE @Config [Trade].[InstrumentsOrdersConfigTbl]
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell)
VALUES (1234, 0, 0)  -- Only these two; other fields remain unchanged

DECLARE @Sync [Trade].[SyncConfigurationAdd]

EXEC Trade.UpdateInstrumentsTradingOrdersConfigurations
    @InstrumentNewOrdersConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.2 Restrict to internal visibility only

```sql
DECLARE @Config [Trade].[InstrumentsOrdersConfigTbl]
INSERT INTO @Config (InstrumentID, VisibleInternallyOnly)
VALUES (1234, 1)  -- Hide from public customers

DECLARE @Sync [Trade].[SyncConfigurationAdd]
INSERT INTO @Sync (InstrumentID, ConfigurationUpdateTypeID, [Value])
VALUES (1234, 5, 'VisibleInternallyOnly=1')

EXEC Trade.UpdateInstrumentsTradingOrdersConfigurations
    @InstrumentNewOrdersConfigTbl = @Config,
    @InstrumentSyncConfigurationAddTable = @Sync
```

### 8.3 Check current order permission flags

```sql
SELECT
    tpti.InstrumentID,
    tpti.AllowBuy,
    tpti.AllowSell,
    tpti.AllowPendingOrders,
    tpti.AllowEntryOrders,
    tpti.AllowExitOrder,
    tpti.VisibleInternallyOnly
FROM Trade.ProviderToInstrument tpti WITH (NOLOCK)
WHERE tpti.InstrumentID = 1234
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.UpdateInstrumentsTradingOrdersConfigurations | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.UpdateInstrumentsTradingOrdersConfigurations.sql*
