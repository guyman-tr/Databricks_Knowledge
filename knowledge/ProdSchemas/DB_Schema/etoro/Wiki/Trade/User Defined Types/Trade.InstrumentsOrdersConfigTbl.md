# Trade.InstrumentsOrdersConfigTbl

> TVP for bulk updates of order-related instrument configuration: buy/sell, pending, entry, exit permissions and internal visibility.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | User Defined Type |
| **Key Identifier** | InstrumentID (int) |
| **Partition** | N/A |
| **Indexes** | None (heap) |

---

## 1. Business Meaning

This type carries order-related configuration flags per instrument: whether buy, sell, pending orders, entry orders, and exit orders are allowed, plus whether the instrument is visible internally only. It models the subset of instrument config focused on order permissions.

The type exists to support bulk updates of order configurations via Trade.UpdateInstrumentsTradingOrdersConfigurations. Admin or config services populate the TVP when changing which instruments support which order types across the platform.

Services build the table, pass it as READONLY, and the procedure JOINs against it to apply the new order config flags to Trade.ProviderToInstrument or related tables.

---

## 2. Business Logic

InstrumentID + multi-column boolean group for bulk order configuration. Each row carries AllowBuy, AllowSell, AllowPendingOrders, AllowEntryOrders, AllowExitOrder, and VisibleInternallyOnly; procedures apply only non-null columns.

---

## 3. Data Overview

N/A for User Defined Type. TVPs are transient parameter containers.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | InstrumentID | int | NO | - | CODE-BACKED | References Trade.Instrument; identifies which instrument receives the config. |
| 2 | AllowBuy | bit | YES | - | CODE-BACKED | Whether buy orders are allowed for this instrument. |
| 3 | AllowSell | bit | YES | - | CODE-BACKED | Whether sell orders are allowed for this instrument. |
| 4 | AllowPendingOrders | bit | YES | - | CODE-BACKED | Whether pending/limit orders are allowed. |
| 5 | AllowEntryOrders | bit | YES | - | CODE-BACKED | Whether entry orders are allowed. |
| 6 | AllowExitOrder | bit | YES | - | CODE-BACKED | Whether exit/close orders are allowed. |
| 7 | VisibleInternallyOnly | bit | YES | - | CODE-BACKED | Whether the instrument is visible only to internal users. |

---

## 5. Relationships

### 5.1 References To (this object points to)

InstrumentID semantically references Trade.Instrument but there is no declared FK on the type definition.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.UpdateInstrumentsTradingOrdersConfigurations | @InstrumentNewOrdersConfigTbl | Parameter (TVP) | Receives bulk order config updates and applies to instrument settings |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.UpdateInstrumentsTradingOrdersConfigurations | Stored Procedure | READONLY parameter for bulk order config updates |

---

## 7. Technical Details

### 7.1 Indexes

No indexes. The type is defined as a heap (no clustered index or primary key).

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Declare and pass to update procedure
```sql
DECLARE @Config Trade.InstrumentsOrdersConfigTbl;
INSERT INTO @Config (InstrumentID, AllowBuy, AllowSell, AllowPendingOrders)
VALUES (12345, 1, 1, 1), (12346, 1, 0, 0);
EXEC Trade.UpdateInstrumentsTradingOrdersConfigurations @InstrumentNewOrdersConfigTbl = @Config;
```

### 8.2 Update visibility for selected instruments
```sql
DECLARE @Config Trade.InstrumentsOrdersConfigTbl;
INSERT INTO @Config (InstrumentID, VisibleInternallyOnly)
SELECT InstrumentID, 1 FROM Trade.Instrument WHERE Symbol LIKE 'TEST%';
EXEC Trade.UpdateInstrumentsTradingOrdersConfigurations @InstrumentNewOrdersConfigTbl = @Config;
```

### 8.3 Disable exit orders for specific instrument
```sql
DECLARE @Config Trade.InstrumentsOrdersConfigTbl;
INSERT INTO @Config (InstrumentID, AllowExitOrder) VALUES (99999, 0);
EXEC Trade.UpdateInstrumentsTradingOrdersConfigurations @InstrumentNewOrdersConfigTbl = @Config;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 7.8/10 (Elements: 10/10, Logic: 5/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 7 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 3/3*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InstrumentsOrdersConfigTbl | Type: User Defined Type | Source: etoro/etoro/Trade/User Defined Types/Trade.InstrumentsOrdersConfigTbl.sql*
