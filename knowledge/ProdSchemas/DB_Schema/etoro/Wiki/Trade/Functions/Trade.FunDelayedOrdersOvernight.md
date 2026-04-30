# Trade.FunDelayedOrdersOvernight

> Inline TVF that returns delayed open and close orders (limit/stop orders awaiting execution) for a given customer, date range, and optional Apex account, by UNIONing Trade.DelayedOrderForOpen and Trade.DelayedOrderForClose with consistent column shape.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Inline Table-Valued Function |
| **Key Identifier** | Returns TABLE with RequestIdentifier, ApexAccountID, OrderID, CID, PositionID, InstrumentID, Symbol, RequestOccurred, LastUpdate, StatusID, and order-specific columns |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.FunDelayedOrdersOvernight aggregates pending delayed orders from two memory-optimized tables: Trade.DelayedOrderForOpen (limit/stop orders to open positions) and Trade.DelayedOrderForClose (limit/stop orders to close positions). Both branches are filtered by @CID, @lastUpdate date range, and optional @apexAccountID. The result provides a unified view of all overnight delayed orders for a customer or Apex account—useful for BI reporting, reconciliation, and operational dashboards.

This function exists because the platform needs a single queryable interface for "all delayed orders" without duplicating filter logic. Trade.DelayedOrdersOvernight procedure duplicates similar logic; this TVF offers a simpler, reusable pattern for BI/ETL consumers (e.g., BIReader has GRANT SELECT on this function). Column alignment between open and close branches uses NULL for non-applicable columns (e.g., PositionID is NULL for open orders; IsBuy/Leverage/Amount are NULL for close orders).

Data flows: invoked by BI tools and ad-hoc queries. Parameters allow filtering by customer, date, and Apex account. Returns rows from both DelayedOrderForOpen and DelayedOrderForClose with InstrumentMetaData.Symbol and CustomerStatic.ApexID resolved.

---

## 2. Business Logic

### 2.1 UNION Structure with Column Alignment

**What**: Two SELECT branches produce compatible column sets; open-specific columns are NULL in the close branch and vice versa.

**Columns/Parameters Involved**: All output columns

**Rules**:
- **Open branch**: PositionID=NULL, ActionType=NULL. Includes ParentCID, IsBuy, Leverage, Amount, MirrorID, ParentPositionID, TreeID, RootSettlementType, SettlementType, IsCopyFund, OpenActionType, CorrelationID
- **Close branch**: ParentCID, IsBuy, Leverage, Amount, MirrorID, ParentPositionID, TreeID, RootSettlementType, SettlementType, IsCopyFund, OpenActionType, CorrelationID = NULL. Includes PositionID, ActionType
- Both branches join InstrumentMetaData for Symbol and CustomerStatic for ApexID

### 2.2 Filter Logic

**What**: @CID, @lastUpdate, @apexAccountID are optional filters; NULL means "all."

**Rules**:
- @CID: (@CID = dofo.CID OR @CID IS NULL) and same for doc
- @lastUpdate: (LastUpdate BETWEEN @lastUpdate AND DATEADD(day,1,@lastUpdate) OR @lastUpdate IS NULL)
- @apexAccountID: (@apexAccountID = ccs.ApexID OR @apexAccountID IS NULL)

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID filter. NULL = all customers. |
| 2 | @lastUpdate | DATE | NO | - | CODE-BACKED | Date filter for LastUpdate. NULL = no date filter. When set, includes LastUpdate in [@lastUpdate, @lastUpdate+1 day). |
| 3 | @apexAccountID | VARCHAR(100) | NO | - | CODE-BACKED | Apex account ID filter (CustomerStatic.ApexID). NULL = all Apex accounts. |
| 4 | RequestIdentifier (return) | bigint | - | - | CODE-BACKED | PK from DelayedOrderForOpen or DelayedOrderForClose. |
| 5 | ApexAccountID (return) | VARCHAR | YES | - | CODE-BACKED | CustomerStatic.ApexID. Resolved via LEFT JOIN. |
| 6 | OrderID (return) | bigint | - | - | CODE-BACKED | OrderForOpen or OrderForClose OrderID. |
| 7 | OriginalOrderID (return) | bigint | - | - | CODE-BACKED | Original order reference. |
| 8 | CID (return) | INT | YES | - | CODE-BACKED | Customer ID. |
| 9 | PositionID (return) | bigint | YES | - | CODE-BACKED | Position to close (close branch only). NULL for open branch. |
| 10 | InstrumentID (return) | INT | YES | - | CODE-BACKED | Instrument. Implicit FK to Trade.Instrument. |
| 11 | Symbol (return) | varchar | YES | - | CODE-BACKED | InstrumentMetaData.Symbol. Resolved via LEFT JOIN. |
| 12 | RequestOccurred (return) | datetime | YES | - | CODE-BACKED | When the delayed order was requested. |
| 13 | LastUpdate (return) | datetime | YES | - | CODE-BACKED | Last status update time. |
| 14 | ActionType (return) | int | YES | - | CODE-BACKED | ExecutionServicesOperationType (close branch only). NULL for open. |
| 15 | StatusID (return) | int | YES | - | CODE-BACKED | 1=PLACED, 2=FILLED, 3=REMOVED (Dictionary.DelayedOrderStatus). See [Delayed Order Status](_glossary.md#delayed-order-status). |
| 16 | ParentCID (return) | int | YES | - | CODE-BACKED | Leader CID in copy-trading (open branch only). NULL for close. |
| 17 | IsBuy (return) | bit | YES | - | CODE-BACKED | 1=buy, 0=sell (open branch only). NULL for close. |
| 18 | Leverage (return) | int | YES | - | CODE-BACKED | Leverage multiplier (open branch only). NULL for close. |
| 19 | Amount (return) | money | YES | - | CODE-BACKED | Notional amount (open branch only). NULL for close. |
| 20 | MirrorID (return) | int | YES | - | CODE-BACKED | Mirror relationship (open branch only). NULL for close. |
| 21 | ParentPositionID (return) | bigint | YES | - | CODE-BACKED | Parent position (open branch only). NULL for close. |
| 22 | TreeID (return) | bigint | YES | - | CODE-BACKED | Position tree (open branch only). NULL for close. |
| 23 | RootSettlementType (return) | int | YES | - | CODE-BACKED | Root settlement type (open branch only). NULL for close. |
| 24 | SettlementType (return) | int | YES | - | CODE-BACKED | Settlement type (open branch only). NULL for close. |
| 25 | IsCopyFund (return) | bit | YES | - | CODE-BACKED | Copy fund flag (open branch only). NULL for close. |
| 26 | OpenActionType (return) | int | YES | - | CODE-BACKED | Open operation type (open branch only). NULL for close. |
| 27 | CorrelationID (return) | uniqueidentifier | YES | - | CODE-BACKED | Correlation ID (open branch only). NULL for close. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| - | Trade.DelayedOrderForOpen | FROM | Open delayed orders |
| - | Trade.DelayedOrderForClose | FROM | Close delayed orders |
| InstrumentID | Trade.InstrumentMetaData | LEFT JOIN | Symbol lookup |
| CID | Customer.CustomerStatic | LEFT JOIN | ApexID lookup |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BIReader | GRANT SELECT | Permission | BI/ETL read access |
| (Procedure Trade.DelayedOrdersOvernight duplicates logic but does not call this function) | - | - | Parallel implementation |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.FunDelayedOrdersOvernight (function)
├── Trade.DelayedOrderForOpen (table)
├── Trade.DelayedOrderForClose (table)
├── Trade.InstrumentMetaData (table)
└── Customer.CustomerStatic (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.DelayedOrderForOpen | Table | FROM for open delayed orders |
| Trade.DelayedOrderForClose | Table | FROM for close delayed orders |
| Trade.InstrumentMetaData | Table | LEFT JOIN for Symbol |
| Customer.CustomerStatic | Table | LEFT JOIN for ApexID |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BIReader | Database role | GRANT SELECT — BI/ETL consumers |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS TABLE | Return type | Inline TVF with 27 columns |
| UNION (no ALL) | Logic | Deduplicates identical rows; in practice branches are disjoint by design |

---

## 8. Sample Queries

### 8.1 Get overnight delayed orders for a customer

```sql
SELECT  RequestIdentifier, ApexAccountID, OrderID, CID, PositionID, InstrumentID,
        Symbol, RequestOccurred, LastUpdate, StatusID
FROM    Trade.FunDelayedOrdersOvernight(9263423, '2026-03-14', NULL);
```

### 8.2 Get all delayed orders for a date (no CID filter)

```sql
SELECT  RequestIdentifier, CID, InstrumentID, Symbol, StatusID, IsBuy, Amount
FROM    Trade.FunDelayedOrdersOvernight(NULL, '2026-03-14', NULL)
WHERE   StatusID = 1;
```

### 8.3 Filter by Apex account

```sql
SELECT  RequestIdentifier, OrderID, InstrumentID, Symbol, LastUpdate
FROM    Trade.FunDelayedOrdersOvernight(NULL, '2026-03-14', 'APEX_12345');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: 2026-03-15 | Quality: 8.6/10 (Elements: 9/10, Logic: 8/10, Relationships: 7/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: DDL + Table docs*
*Sources: Atlassian: 0 Confluence + 0 Jira | Table docs: DelayedOrderForOpen, DelayedOrderForClose | Corrections: 0 applied*
*Object: Trade.FunDelayedOrdersOvernight | Type: Inline Table-Valued Function | Source: etoro/etoro/Trade/Functions/Trade.FunDelayedOrdersOvernight.sql*
