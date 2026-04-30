# Trade.ExposuresForAllHedgeServersLOG

> Change log capturing every incremental update to the exposure table, recording the before/after values and the triggering position operation details.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Table |
| **Key Identifier** | ID (IDENTITY, no PK constraint) |
| **Partition** | No |
| **Indexes** | 0 (heap - no indexes) |

---

## 1. Business Meaning

This table logs every incremental modification made to Trade.ExposuresForAllHedgeServers by the `ExposuresForAllHedgeServers_Update` procedure. Each row captures the before and after exposure values (OpenedBuyInserted/Deleted, OpenedSellInserted/Deleted) along with full context about which position operation triggered the change - including the position ID, action type, buy/sell direction, and lot count.

The table exists for debugging and audit of real-time exposure tracking. While ExposuresForAllHedgeServers_Log captures discrepancies found during batch reconciliation, this table captures the individual incremental changes as they happen. This allows operations to trace exactly how exposure drifted for a specific CID/instrument combination.

Rows are inserted by `Trade.ExposuresForAllHedgeServers_Update` when the @LogChanges flag is set to 1. Currently @LogChanges defaults to 0 (disabled), so the table is empty. It can be enabled for targeted debugging by setting the flag in the procedure.

---

## 2. Business Logic

### 2.1 Before/After Change Tracking

**What**: Each log entry captures the exposure values before and after the update, enabling drift analysis.

**Columns/Parameters Involved**: `OpenedBuyInserted`, `OpenedBuyDeleted`, `OpenedSellInserted`, `OpenedSellDeleted`

**Rules**:
- OpenedBuyInserted/OpenedSellInserted = the NEW values after the update (from OUTPUT INSERTED)
- OpenedBuyDeleted/OpenedSellDeleted = the OLD values before the update (from OUTPUT DELETED)
- For new rows (INSERT rather than UPDATE), the Deleted columns are NULL
- The difference between Inserted and Deleted gives the exact change amount

### 2.2 Position Operation Context

**What**: Full context of the triggering position operation is stored for traceability.

**Columns/Parameters Involved**: `Open_Close`, `ActionType`, `PositionID`, `ParentPositionID`, `IsBuy`, `LotCountDecimal`, `OpenedBuySell`, `SPParameters`

**Rules**:
- Open_Close: 0=Open, 1=Close - which operation direction triggered this exposure change
- ActionType: Matches the action type classification from ExposuresForAllHedgeServers_Update (0=Customer, 1=StopLoss, 2=EndOfWeek, etc.)
- SPParameters: Full serialized string of all input parameters for the update call - allows complete reconstruction of the triggering event
- OpenedBuySell: The computed lot delta (LotCountDecimal * +1 for open or -1 for close)

---

## 3. Data Overview

The table is currently empty (0 rows). Logging is disabled by default (@LogChanges = 0 in ExposuresForAllHedgeServers_Update). Can be enabled for debugging.

| ID | DateChange | ActionType | PositionID | OpenedBuyInserted | OpenedBuyDeleted | Meaning |
|----|-----------|-----------|-----------|------------------|-----------------|---------|
| *(empty)* | *(empty)* | - | - | - | - | No changes logged (logging is disabled by default) |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | ID | int IDENTITY | NO | Auto-increment | CODE-BACKED | Surrogate identity key for the log entry. Auto-incrementing sequence. |
| 2 | DateChange | datetime | NO | getdate() | CODE-BACKED | Timestamp when the exposure change occurred. Defaults to GETDATE() on insert. |
| 3 | CID | int | YES | - | CODE-BACKED | Customer ID whose exposure was modified. References Customer.Customer. NULL if the log row was inserted as a fallback (no OUTPUT rows captured). |
| 4 | ProviderID | int | YES | - | CODE-BACKED | Liquidity provider for the modified exposure row. References Trade.Provider. |
| 5 | InstrumentID | int | YES | - | CODE-BACKED | Financial instrument for the modified exposure row. References Trade.Instrument. |
| 6 | HedgeServerID | int | YES | - | CODE-BACKED | Hedge server for the modified exposure row. References Trade.HedgeServer. |
| 7 | OpenedBuyInserted | decimal(38,6) | YES | - | VERIFIED | New OpenedBuy value AFTER the update (from OUTPUT INSERTED). NULL when inserted as fallback without OUTPUT data. |
| 8 | OpenedBuyDeleted | decimal(38,6) | YES | - | VERIFIED | Old OpenedBuy value BEFORE the update (from OUTPUT DELETED). NULL for new row inserts or fallback entries. |
| 9 | OpenedSellInserted | decimal(38,6) | YES | - | VERIFIED | New OpenedSell value AFTER the update (from OUTPUT INSERTED). NULL when inserted as fallback without OUTPUT data. |
| 10 | OpenedSellDeleted | decimal(38,6) | YES | - | VERIFIED | Old OpenedSell value BEFORE the update (from OUTPUT DELETED). NULL for new row inserts or fallback entries. |
| 11 | Open_Close | bit | YES | - | VERIFIED | Direction of the position operation: 0 = Position Open (adds exposure), 1 = Position Close (reduces exposure). Passed from the @Open_Close parameter of ExposuresForAllHedgeServers_Update. |
| 12 | ActionType | int | YES | - | VERIFIED | Type of close action that triggered the exposure change. 0=Customer, 1=StopLoss, 2=EndOfWeek, 5=TakeProfit, 7=ContractRollover, 8=BackOffice, 9=HierarchicalClose, 10=HierarchicalRecovery, 12=CloseAll, 13=MirrorSL, 14=ManualCloseCopied. |
| 13 | PositionID | bigint | YES | - | CODE-BACKED | ID of the position that triggered the exposure change. References Trade.PositionTbl. |
| 14 | ParentPositionID | bigint | YES | - | CODE-BACKED | Parent position ID for copy-trade hierarchical closes. References Trade.PositionTbl. Used to identify 1st-generation children whose exposure also needs adjustment. |
| 15 | IsBuy | bit | YES | - | CODE-BACKED | Direction of the triggering position: 1 = Buy/Long, 0 = Sell/Short. Determines whether OpenedBuy or OpenedSell is modified. |
| 16 | LotCountDecimal | decimal(16,6) | YES | - | CODE-BACKED | Lot count of the triggering position. The base amount used to calculate the exposure delta. |
| 17 | OpenedBuySell | decimal(38,6) | YES | - | VERIFIED | Computed exposure delta: LotCountDecimal * (1 for open, -1 for close). Represents the exact amount added to or subtracted from the exposure column. |
| 18 | SPParameters | varchar(max) | YES | - | CODE-BACKED | Full serialized string of all input parameters passed to ExposuresForAllHedgeServers_Update. Enables complete reconstruction of the triggering event for debugging. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.Customer | Implicit | Customer whose exposure changed |
| ProviderID | Trade.Provider | Implicit | Liquidity provider context |
| InstrumentID | Trade.Instrument | Implicit | Financial instrument context |
| HedgeServerID | Trade.HedgeServer | Implicit | Hedge server context |
| PositionID | Trade.PositionTbl | Implicit | Position that triggered the change |
| ParentPositionID | Trade.PositionTbl | Implicit | Parent position for hierarchical operations |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.ExposuresForAllHedgeServers_Update | - | Writer | Inserts change log entries when @LogChanges = 1 |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Trade.ExposuresForAllHedgeServers_Update | Stored Procedure | Writes change log entries (when logging is enabled) |

---

## 7. Technical Details

### 7.1 Indexes

This table is a **heap** (no clustered index, no non-clustered indexes). As a debugging log table with logging normally disabled, the absence of indexes is intentional - minimizing write overhead when logging is active.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DF_DateChange | DEFAULT | `getdate()` for DateChange - auto-timestamps each log entry |

---

## 8. Sample Queries

### 8.1 Find recent exposure changes for a customer
```sql
SELECT TOP 20 DateChange, ActionType, PositionID,
       Open_Close, IsBuy, LotCountDecimal, OpenedBuySell,
       OpenedBuyInserted, OpenedBuyDeleted
FROM   Trade.ExposuresForAllHedgeServersLOG WITH (NOLOCK)
WHERE  CID = @CID
ORDER BY DateChange DESC
```

### 8.2 Trace exposure drift for a specific instrument
```sql
SELECT DateChange, CID,
       OpenedBuyInserted - ISNULL(OpenedBuyDeleted, 0) AS BuyDelta,
       OpenedSellInserted - ISNULL(OpenedSellDeleted, 0) AS SellDelta,
       ActionType, PositionID
FROM   Trade.ExposuresForAllHedgeServersLOG WITH (NOLOCK)
WHERE  InstrumentID = @InstrumentID
ORDER BY DateChange
```

### 8.3 Identify hierarchical close events
```sql
SELECT DateChange, CID, PositionID, ParentPositionID,
       ActionType, LotCountDecimal, SPParameters
FROM   Trade.ExposuresForAllHedgeServersLOG WITH (NOLOCK)
WHERE  ActionType IN (0, 8, 9, 10, 12, 13, 14)
ORDER BY DateChange DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-14 | Enriched: - | Quality: 8.3/10 (Elements: 10.0/10, Logic: 7.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 6 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.ExposuresForAllHedgeServersLOG | Type: Table | Source: etoro/etoro/Trade/Tables/Trade.ExposuresForAllHedgeServersLOG.sql*
