# Dictionary.DesignatedExecutionSystem

> Lookup table defining the execution system types used for instrument trade routing — TradeServer (synchronous) vs Async (asynchronous) execution.

| Property | Value |
|----------|-------|
| **Schema** | Dictionary |
| **Object Type** | Table |
| **Key Identifier** | DesignatedExecutionSystemID (no PK constraint — heap) |
| **Partition** | No — stored on DICTIONARY filegroup |
| **Indexes** | 0 (heap — no clustered or nonclustered indexes) |

---

## 1. Business Meaning

Each tradable instrument on the eToro platform is assigned to an execution system that determines how trade orders are processed. This table defines two execution modes: TradeServer (0) for synchronous real-time execution where the trade is processed immediately on the trading engine, and Async (1) for asynchronous execution where the order is queued and processed by a separate execution service.

Without this table, the platform would have no way to configure which execution path an instrument should use. This is critical for the trading infrastructure — crypto and stock instruments may use asynchronous execution (routed to external exchanges), while CFD instruments may use the synchronous TradeServer for instant execution.

The table is heavily referenced across the trading infrastructure: `Trade.ProviderToInstrument` stores the designated execution system per instrument/provider, `Trade.GetInstrumentDesignatedSystem` retrieves it, `Trade.UpdateInstrumentsTradingConfigurations` and `Trade.UpdateDesignatedExecutionSystemBulk` modify it, and `Trade.GetInstrumentTradingData` view exposes it. The `Trade.DesignatedExecutionSystemUpdate` and `Trade.InstrumentsTradingConfigTbl` UDTs carry it as a parameter.

---

## 2. Business Logic

### 2.1 Execution Mode Selection

**What**: Instruments are routed to different execution engines based on their designated system.

**Columns/Parameters Involved**: `DesignatedExecutionSystemID`, `Name`

**Rules**:
- TradeServer (0) — synchronous execution on the eToro trading engine. Orders are filled immediately at the current price. Used for CFD instruments where eToro acts as market maker
- Async (1) — asynchronous execution via a queue-based system. Orders are routed to external exchanges or execution venues. Used for real stocks, ETFs, and crypto where eToro must place orders on external markets
- The designation is per instrument-provider combination (stored in Trade.ProviderToInstrument)
- Bulk updates are possible via Trade.UpdateDesignatedExecutionSystemBulk using the Trade.DesignatedExecutionSystemUpdate UDT

---

## 3. Data Overview

| DesignatedExecutionSystemID | Name | Meaning |
|---|---|---|
| 0 | TradeServer | Synchronous real-time execution on the eToro trading engine — orders are processed immediately at the quoted price. Typically used for CFD instruments where eToro is the counterparty and can fill instantly |
| 1 | Async | Asynchronous execution via external routing — orders are queued and sent to external exchanges, brokers, or liquidity providers. Used for real stock, ETF, and crypto trades where external market execution is required |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DesignatedExecutionSystemID | tinyint | NO | - | VERIFIED | Identifier for the execution system. 0=TradeServer (sync), 1=Async. Stored in Trade.ProviderToInstrument.DesignatedExecutionSystemID per instrument/provider pair. Used in UDTs Trade.DesignatedExecutionSystemUpdate and Trade.InstrumentsTradingConfigTbl. |
| 2 | Name | varchar(50) | NO | - | VERIFIED | Human-readable execution system name. Displayed in SalesForce instrument reports (SalesForce.GetInstruments) and OpsFlow permission configurations. |

---

## 5. Relationships

### 5.1 References To (this object points to)

This object has no outgoing references.

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ProviderToInstrument | DesignatedExecutionSystemID | Implicit | Stores the execution system per instrument/provider combination |
| Trade.GetInstrumentDesignatedSystem | DesignatedExecutionSystemID | JOIN | Retrieves the designated execution system for a specific instrument |
| Trade.GetInstrumentTradingData | DesignatedExecutionSystemID | JOIN | View exposing instrument trading configuration including execution system |
| Trade.UpdateInstrumentsTradingConfigurations | DesignatedExecutionSystemID | Implicit | Procedure that updates instrument trading config including execution system |
| Trade.UpdateDesignatedExecutionSystemBulk | DesignatedExecutionSystemID | Implicit | Bulk update procedure for changing execution systems across multiple instruments |
| SalesForce.GetInstruments | DesignatedExecutionSystemID | JOIN | SalesForce integration exports instrument execution system |
| Trade.DesignatedExecutionSystemUpdate | DesignatedExecutionSystemID | UDT | Table-valued parameter for bulk execution system updates |
| Trade.InstrumentsTradingConfigTbl | DesignatedExecutionSystemID | UDT | Table-valued parameter for full instrument trading config updates |
| History.TradeProviderToInstrument | DesignatedExecutionSystemID | Implicit | History table tracking changes to provider-instrument configuration |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Dictionary.DesignatedExecutionSystem (table)
```

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ProviderToInstrument | Table | References — per-instrument execution system |
| Trade.GetInstrumentDesignatedSystem | Procedure | Reader — retrieves execution system |
| Trade.GetInstrumentTradingData | View | Reader — exposes execution system |
| Trade.UpdateDesignatedExecutionSystemBulk | Procedure | Writer — bulk updates execution systems |
| Trade.UpdateInstrumentsTradingConfigurations | Procedure | Writer — updates trading config |
| SalesForce.GetInstruments | Procedure | Reader — SalesForce export |

---

## 7. Technical Details

### 7.1 Indexes

No indexes defined. This table is a **heap** (no clustered index). Given its small size (2 rows), this has no performance impact.

### 7.2 Constraints

None. Note: unlike most Dictionary tables, this table has **no PK constraint** defined in the DDL. The DesignatedExecutionSystemID column is functionally unique but not enforced by a constraint.

---

## 8. Sample Queries

### 8.1 List all execution systems
```sql
SELECT  DesignatedExecutionSystemID,
        Name
FROM    Dictionary.DesignatedExecutionSystem WITH (NOLOCK)
ORDER BY DesignatedExecutionSystemID
```

### 8.2 Count instruments by execution system
```sql
SELECT  des.Name AS ExecutionSystem,
        COUNT(*) AS InstrumentCount
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
        JOIN Dictionary.DesignatedExecutionSystem des WITH (NOLOCK) ON pti.DesignatedExecutionSystemID = des.DesignatedExecutionSystemID
GROUP BY des.Name
```

### 8.3 Find instruments using async execution
```sql
SELECT  pti.InstrumentID,
        pti.ProviderID,
        des.Name AS ExecutionSystem
FROM    Trade.ProviderToInstrument pti WITH (NOLOCK)
        JOIN Dictionary.DesignatedExecutionSystem des WITH (NOLOCK) ON pti.DesignatedExecutionSystemID = des.DesignatedExecutionSystemID
WHERE   pti.DesignatedExecutionSystemID = 1  -- Async
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Quality: 9.4/10 (Elements: 10/10, Logic: 5/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 0 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/12*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 9 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Dictionary.DesignatedExecutionSystem | Type: Table | Source: etoro/etoro/Dictionary/Tables/Dictionary.DesignatedExecutionSystem.sql*
