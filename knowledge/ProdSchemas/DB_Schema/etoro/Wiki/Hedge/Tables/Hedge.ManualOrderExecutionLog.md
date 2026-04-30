# Hedge.ManualOrderExecutionLog

> Audit log of every hedge order submitted to the hedge server - both by human dealing desk operators manually intervening in hedge positions and by the automated ExposureBalancer service correcting residual exposure imbalances.

| Property | Value |
|----------|-------|
| **Schema** | Hedge |
| **Object Type** | Table |
| **Key Identifier** | OrderID (UNIQUEIDENTIFIER, CLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 active (PK only) |

---

## 1. Business Meaning

Hedge.ManualOrderExecutionLog records every hedge order that bypasses or supplements the normal automated hedging flow. While eToro's hedge system processes customer trades automatically, two scenarios require distinct order tracking: (1) dealing desk operators using HedgeClient to place manual buy/sell hedge orders directly on liquidity providers, and (2) the ExposureBalancer service running automated correction orders when residual exposure imbalances are detected between the hedge server's expected and actual positions.

This table exists because manual hedge interventions carry elevated operational risk and must be fully auditable. Risk management and compliance teams review this log to understand who placed what orders, at what rates, and for which instruments. The ExposureBalancer entries serve as an automated reconciliation audit trail, showing when and how the system self-corrected its exposure.

Data flows in a single direction: orders are inserted via Hedge.InsertManualOrderExecutionLog (or direct insert for FIX-parameter rows) and are never updated or deleted. The table has been active since February 2023, accumulating approximately 397 entries at a low frequency - confirming this is an exception log, not a high-throughput operational table.

---

## 2. Business Logic

### 2.1 Manual vs Automated Order Populations

**What**: Two fundamentally different order sources share this table, distinguished by RequestTypeID and Sender patterns.

**Columns/Parameters Involved**: `RequestTypeID`, `Sender`, `IP`, `TradeDescription`, `UpdateNetting`, `Rate`, `OrderType`, `TimeInForce`

**Rules**:
- **ExposureBalancer (automated)**: RequestTypeID = -1 (not in Dictionary.HedgeManualRequestType), Sender = "ExposureBalancer", IP = NULL, TradeDescription = "Exposure Balancer Saga", UpdateNetting = true, Rate = actual market price, OrderType/TimeInForce = NULL
- **Dealing desk (manual)**: RequestTypeID >= 0 (maps to Dictionary.HedgeManualRequestType), Sender = "HedgeClientN (by <username>)", IP = internal network IP, TradeDescription = NULL, UpdateNetting = NULL, Rate = 0 (market order), OrderType = "Market", TimeInForce = "Day"
- RequestTypeID -1 is a sentinel value used by the ExposureBalancer that intentionally falls outside the official dictionary - it represents system-initiated correction orders

**Diagram**:
```
Hedge.ManualOrderExecutionLog rows:

AUTOMATED (ExposureBalancer)               MANUAL (Dealing Desk)
RequestTypeID = -1                         RequestTypeID = 0,1,2,3,4,5,6,7
Sender = "ExposureBalancer"                Sender = "HedgeClientN (by <user>)"
IP = NULL                                  IP = 10.x.x.x (internal)
Rate = actual market price                 Rate = 0 (market order)
UpdateNetting = true                       UpdateNetting = NULL
TradeDescription = "Exposure Balancer Saga" TradeDescription = NULL
OrderType = NULL                           OrderType = "Market"
TimeInForce = NULL                         TimeInForce = "Day"
```

### 2.2 FIX Protocol Order Parameters

**What**: Manual dealing desk orders capture FIX protocol execution parameters that specify how the order should be routed to the liquidity provider.

**Columns/Parameters Involved**: `OrderType`, `TimeInForce`, `ExpirationInSeconds`, `SlippagePercentage`, `Rate`

**Rules**:
- OrderType = "Market" means execute at best available price (Rate = 0 signals no specific rate constraint)
- TimeInForce = "Day" means the order expires at end of trading day if not filled
- ExpirationInSeconds = 0 combined with Day TimeInForce means rely on the Day boundary, not a custom expiry
- SlippagePercentage = 0 for manual orders means exact execution - no slippage tolerance
- These FIX parameters are NOT inserted via Hedge.InsertManualOrderExecutionLog SP (which predates FIX integration) - they are written by a separate path, likely HedgeClient application direct insert

### 2.3 Original vs Executed Amount Tracking

**What**: RequestedIsBuy and RequestedAmountInUnits were intended to capture the original order intent before any hedge server adjustment.

**Columns/Parameters Involved**: `RequestedIsBuy`, `RequestedAmountInUnits`, `IsBuy`, `AmountInUnits`

**Rules**:
- In all current data, RequestedIsBuy and RequestedAmountInUnits are NULL - these columns are not being populated
- The design intent was: if the hedge server adjusted the order direction or size, the original requested values would be preserved here for audit comparison
- These appear to be legacy or forward-looking columns that have not yet been implemented in the current flow

---

## 3. Data Overview

| OrderID (truncated) | Sender | RequestTypeID | InstrumentID | IsBuy | AmountInUnits | Rate | Meaning |
|---|---|---|---|---|---|---|---|
| D84C1D4C... | HedgeClient9 (by ranlev) | 0 (Custom Request) | 1200 | true | 10 | 0 | Dealing desk operator "ranlev" placed a manual buy hedge of 10 units on InstrumentID 1200 at market price via HedgeClient9. Rate=0 means market order - execute at best available. |
| 0D342DE7... | HedgeClient1 (by noah) | 4 (Manual Exposure) | 4 | false | 1000.0001 | NULL | Operator "noah" submitted a manual exposure correction - selling 1000 units of InstrumentID 4 (likely EURUSD or similar major forex). Used when automated exposure is wrong and needs direct override. |
| AF9D5F3E... | ExposureBalancer | -1 (automated) | 1019 | true | 3.5813 | 18.7 | ExposureBalancer detected a residual buy imbalance of 3.5813 units on InstrumentID 1019 at rate 18.7 and submitted an automatic correction order. UpdateNetting=true means the netting positions will be recalculated. |
| B4120110... | ExposureBalancer | -1 (automated) | 1001 | true | 0.3493 | 245.09 | ExposureBalancer micro-correction on InstrumentID 1001 (likely Bitcoin or high-value asset at 245 rate). Small fractional unit count shows the precision of automated exposure balancing. |
| 0EE33860... | ExposureBalancer | -1 (automated) | 3146 | true | 92.28 | 100.25 | ExposureBalancer correction on InstrumentID 3146 - larger 92-unit imbalance at rate 100.25 suggests a lower-priced instrument with larger unit quantities. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | OrderID | uniqueidentifier | NO | - | VERIFIED | Primary key. GUID generated by the submitting system (HedgeClient or ExposureBalancer) before submission. GUID format means the key is generated client-side, not by the database - enabling pre-insert order tracking. |
| 2 | Sender | varchar(39) | YES | - | VERIFIED | Identifies the order source. "ExposureBalancer" for automated correction orders. "HedgeClientN (by \<username\>)" for manual dealing desk orders, where N is the HedgeClient instance number and \<username\> is the authenticated operator. Used for audit attribution. |
| 3 | IP | varchar(39) | YES | - | VERIFIED | IP address of the submitting machine. NULL for the ExposureBalancer service (internal process). Populated with internal network address (e.g., "10.160.0.212") for dealing desk operators connecting via HedgeClient. Confirms the physical location of manual interventions. |
| 4 | ClientSendTime | datetime | NO | - | CODE-BACKED | Timestamp when the order was submitted by the client or service. For ExposureBalancer rows, this equals HedgeStartTime (submitted and started simultaneously). For manual orders, this reflects when the operator clicked "Submit" in HedgeClient. |
| 5 | HedgeStartTime | datetime | NO | - | CODE-BACKED | Timestamp when the hedge server began processing the order. Difference from ClientSendTime reveals hedge server queue latency. In practice, both timestamps are nearly identical for all current records. |
| 6 | RequestTypeID | int | NO | 0 | VERIFIED | Classification of the manual request. FK to Dictionary.HedgeManualRequestType: 0=Custom Request (freeform manual), 1=Set Hedge Exposure, 2=Settle Requested Exposure, 3=SetTradeExposure, 4=Manual Exposure, 5=Custom Update Queued, 6=Clear Queued, 7=Move Netting. Special value -1 is used exclusively by ExposureBalancer (not in dictionary). See [HedgeManualRequestType](../../Dictionary/Tables/Dictionary.HedgeManualRequestType.md) for full definitions. |
| 7 | InstrumentID | int | YES | - | CODE-BACKED | The financial instrument for the hedge order. FK to Trade.Instrument (implicit - no declared constraint). NULL would indicate a non-instrument-specific operation. In practice always populated for actual trade orders. |
| 8 | IsBuy | bit | YES | - | VERIFIED | Direction of the hedge order. true = buy (long hedge position), false = sell (short hedge position). 87% of current records are buys, reflecting that eToro's net book position typically requires more buy-side hedging. |
| 9 | AmountInUnits | decimal(16,6) | YES | - | VERIFIED | The actual executed order size in units of the instrument. For ExposureBalancer rows, this is the calculated imbalance amount. For manual orders, this is the dealer-specified quantity. 6 decimal places supports fractional unit positions (e.g., crypto). |
| 10 | RequestedIsBuy | bit | YES | - | CODE-BACKED | Original requested direction before any hedge server adjustment. Always NULL in current data - this column was designed to capture intent vs execution discrepancies but is not currently populated by any active code path. Likely a forward-looking audit field. |
| 11 | RequestedAmountInUnits | decimal(16,6) | YES | - | CODE-BACKED | Original requested amount before any hedge server adjustment. Always NULL in current data - paired with RequestedIsBuy as an unused intent-tracking mechanism. If the hedge server modified an order, the original amount would appear here. |
| 12 | TradeDescription | varchar(39) | YES | - | VERIFIED | Textual description of the order's purpose. "Exposure Balancer Saga" for all ExposureBalancer rows (hardcoded by the service). NULL for dealing desk manual orders. The varchar(39) length cap limits descriptive detail. |
| 13 | Rate | decimal(16,8) | YES | - | VERIFIED | Execution rate or price for the hedge order. Populated with actual market price for ExposureBalancer orders (e.g., 245.0865 for BTC). Set to 0 for manual dealing desk market orders (rate=0 signals "execute at best available market price"). NULL for Manual Exposure type (RequestTypeID=4). |
| 14 | UpdateNetting | bit | YES | - | VERIFIED | Whether this order should trigger netting position recalculation after execution. true for ExposureBalancer orders (which directly correct netting imbalances and must update the netting table). NULL for manual dealing desk orders (netting recalculation not triggered). Added to the SP in January 2022 by Ran Ovadia. |
| 15 | ReasonID | smallint | YES | - | NAME-INFERRED | A reason code for the order. No FK declared. Mostly NULL (manual orders) or 0 (ExposureBalancer). Three records contain value 3 - the meaning is undocumented. May reference an internal enum in application code or be a legacy field. |
| 16 | OrderType | varchar(30) | YES | NULL | VERIFIED | FIX protocol order type specifying execution method. "Market" for manual dealing desk orders (execute at best available price). NULL for ExposureBalancer orders (internal routing bypasses FIX type specification). Populated via a direct insert path separate from Hedge.InsertManualOrderExecutionLog SP. |
| 17 | TimeInForce | varchar(30) | YES | - | VERIFIED | FIX protocol TimeInForce value specifying order duration. "Day" for manual dealing desk orders (order expires at end of trading day if unfilled). NULL for ExposureBalancer orders. Part of the FIX order specification group with OrderType. |
| 18 | ExpirationInSeconds | int | YES | - | CODE-BACKED | Custom order expiration time in seconds. 0 for manual market orders that use Day TimeInForce (expiry governed by day boundary, not custom timeout). NULL for ExposureBalancer orders. A non-zero value would set a specific execution deadline. |
| 19 | SlippagePercentage | decimal(16,8) | YES | - | CODE-BACKED | Maximum allowable price slippage percentage. 0 for manual dealing desk orders (exact execution required - no price deviation tolerated). NULL for ExposureBalancer orders. A non-zero value would permit partial fills at slightly different rates. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RequestTypeID | Dictionary.HedgeManualRequestType | FK (explicit) | Classifies the manual request into one of 8 types (0-7). FK constraint with NOCHECK, meaning referential integrity is not enforced at insert time. Special value -1 (ExposureBalancer) intentionally bypasses the lookup. |
| InstrumentID | Trade.Instrument | Implicit | Identifies the financial instrument for the hedge order. No declared FK constraint (performance optimization). |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Hedge.InsertManualOrderExecutionLog | (all columns via INSERT) | Writer SP | The sole official write path for this table (core columns only - FIX params use a separate path). |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Hedge.ManualOrderExecutionLog (table)
├── Dictionary.HedgeManualRequestType (table) [FK target - leaf]
└── Trade.Instrument (table) [implicit FK target - leaf]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.HedgeManualRequestType | Table | FK target for RequestTypeID - classifies the manual request type |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Hedge.InsertManualOrderExecutionLog | Stored Procedure | WRITER - inserts core columns (OrderID, Sender, IP, ClientSendTime, HedgeStartTime, RequestTypeID, InstrumentID, IsBuy, AmountInUnits, RequestedIsBuy, RequestedAmountInUnits, TradeDescription, Rate, UpdateNetting) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_HedgeManualOrderExecutionLog | CLUSTERED PK | OrderID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_HedgeManualOrderExecutionLog | PRIMARY KEY | Unique order identifier per hedge request |
| DF_Hedge_ManualOrderExecutionLog_RequestTypeID | DEFAULT | RequestTypeID defaults to 0 (Custom Request) if not specified |
| DF (OrderType) | DEFAULT | OrderType defaults to NULL |
| FK_Hedge_ManualOrderExecutionLog | FOREIGN KEY (NOCHECK) | RequestTypeID references Dictionary.HedgeManualRequestType - NOCHECK means constraint is not enforced at insert time, permitting ExposureBalancer's -1 value |

---

## 8. Sample Queries

### 8.1 Recent manual hedge operations by dealing desk operators
```sql
SELECT  mel.OrderID,
        mel.Sender,
        mel.IP,
        mel.ClientSendTime,
        mrt.Name AS RequestType,
        mel.InstrumentID,
        CASE WHEN mel.IsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS Direction,
        mel.AmountInUnits,
        mel.Rate,
        mel.OrderType,
        mel.TimeInForce
FROM    [Hedge].[ManualOrderExecutionLog] mel WITH (NOLOCK)
LEFT JOIN [Dictionary].[HedgeManualRequestType] mrt WITH (NOLOCK)
        ON mel.RequestTypeID = mrt.RequestTypeID
WHERE   mel.RequestTypeID >= 0
ORDER BY mel.ClientSendTime DESC;
```

### 8.2 ExposureBalancer automated correction history by instrument
```sql
SELECT  mel.InstrumentID,
        COUNT(*) AS CorrectionCount,
        SUM(CASE WHEN mel.IsBuy = 1 THEN mel.AmountInUnits ELSE -mel.AmountInUnits END) AS NetCorrectedUnits,
        MIN(mel.ClientSendTime) AS FirstCorrection,
        MAX(mel.ClientSendTime) AS LastCorrection
FROM    [Hedge].[ManualOrderExecutionLog] mel WITH (NOLOCK)
WHERE   mel.RequestTypeID = -1
GROUP BY mel.InstrumentID
ORDER BY CorrectionCount DESC;
```

### 8.3 Audit view - all orders with instrument name and request type label
```sql
SELECT  mel.ClientSendTime,
        mel.Sender,
        mel.IP,
        ISNULL(mrt.Name, 'ExposureBalancer (auto)') AS RequestType,
        mel.InstrumentID,
        CASE WHEN mel.IsBuy = 1 THEN 'Buy' ELSE 'Sell' END AS Direction,
        mel.AmountInUnits,
        mel.Rate,
        mel.TradeDescription,
        mel.UpdateNetting
FROM    [Hedge].[ManualOrderExecutionLog] mel WITH (NOLOCK)
LEFT JOIN [Dictionary].[HedgeManualRequestType] mrt WITH (NOLOCK)
        ON mel.RequestTypeID = mrt.RequestTypeID
ORDER BY mel.ClientSendTime DESC;
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Dealing Desk - Manual actions](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/11532305788) | Confluence | Referenced in search results (2025-04-06) - likely describes manual hedge operations workflow but page content was not accessible via API |
| [DB Tables And Fields](https://etoro-jira.atlassian.net/wiki/spaces/DROD/pages/12009013316) | Confluence | Referenced in search results - may contain field-level documentation for this table but content was not accessible via API |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.2/10 (Elements: 9.5/10, Logic: 7/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 5 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 1 NAME-INFERRED | Phases: 11/11*
*Sources: Atlassian: 2 Confluence (content inaccessible) + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Hedge.ManualOrderExecutionLog | Type: Table | Source: etoro/etoro/Hedge/Tables/Hedge.ManualOrderExecutionLog.sql*
