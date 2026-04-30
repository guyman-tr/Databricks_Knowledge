# Trade.SendUnBlockMessage

> Identifies BSL-liquidated customers who now have sufficient equity to be unblocked and inserts MessageType=3 (unblock) records into Trade.ManageBSL and Trade.BSLQueue via RW synonyms (real-env writes), using a two-branch UNION covering customers with and without open positions.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - operates on all eligible BSL-blocked customers |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When eToro's BSL (Balance Stop Loss) system forcibly liquidates a customer's positions (MessageType=2), the customer's account is blocked (`Customer.BlockedCustomerOperations` with BlockReasonID=9, OperationTypeID=21). Once the customer deposits more funds or their equity naturally recovers above the unblock threshold, they should be automatically unblocked.

This procedure is the **unblock detector**: it scans all BSL-blocked customers and evaluates whether each now meets the unblock criteria. Eligible customers receive a MessageType=3 (unblock) message inserted into `Trade.ManageBSL`, which is then processed by `Trade.SendMessagesToBSL` and routed to the BSL SAGA to lift the block.

**Critical design feature**: This procedure writes to `RW_ManageBSL` and `RW_BSLQueue` - these are **synonyms pointing to the real environment's tables** (cross-env write). The procedure runs in one environment but modifies the real env's BSL queue. The `OPENQUERY` call to `[AO-REAL-DB]` retrieves the current max ManageBSL ID to enable the subsequent insert into `RW_BSLQueue` to identify only the newly inserted records.

**Important**: The procedure references `#PnLPerCID` - a temp table that must be pre-created by the caller before this procedure is invoked. The procedure does not create it.

The unblock threshold comes from `Dictionary.BSLOperationThreshold WHERE ID=4` - the configured minimum equity percentage required for unblocking.

---

## 2. Business Logic

### 2.1 Unblock Threshold Lookup

**What**: Loads the minimum equity recovery percentage required before a BSL-blocked customer can be unblocked.

**Columns/Parameters Involved**: `Dictionary.BSLOperationThreshold.ValueInPercent WHERE ID=4`

**Rules**:
- @UnBlockPercent = ValueInPercent from Dictionary.BSLOperationThreshold WHERE ID=4
- Represents the minimum `(Credit - BonusCredit) / Credit * 100` percentage the customer must have recovered

### 2.2 StartID Watermark (Cross-Env ID Boundary)

**What**: Gets the current max ManageBSL ID from the real environment to identify newly inserted unblock messages.

**Columns/Parameters Involved**: `OPENQUERY([AO-REAL-DB], ...)`, `@StartID`

**Rules**:
- OPENQUERY to linked server `[AO-REAL-DB]` to get `MAX(ID)` from `etoro.Trade.ManageBSL`
- Filtered to records from the last 24 hours: `TimeMessageInsertedToQueue BETWEEN GETUTCDATE()-1 AND GETUTCDATE()`
- This @StartID is used later to insert only the newly created unblock records into BSLQueue

### 2.3 Eligibility Criteria - Two Branches

**What**: Identifies BSL-blocked customers eligible for unblocking, split by whether they have open positions.

**Columns/Parameters Involved**: `Customer.BlockedCustomerOperations`, `Customer.CustomerMoney`, `#PnLPerCID`, `Trade.CIDsInLiquidation`

**Common filters for both branches**:
- `BlockReasonID = 9`: Blocked specifically by BSL system
- `OperationTypeID = 21`: The block type corresponding to BSL liquidation
- `(CUST.Credit-CUST.BonusCredit)/CUST.Credit*100 >= @UnBlockPercent`: Net real equity (ex-bonus) is at or above the threshold
- `TCL.CID IS NULL`: NOT currently in active liquidation process (LEFT JOIN CIDsInLiquidation)
- `CUST.Credit - CUST.BonusCredit > 0`: Real funds are positive (net of bonus is > zero; per FB 44763)

**Branch 1 - Customers WITH open positions** (INNER JOIN #PnLPerCID):
- `PnL.PnL + PnL.RealizedEquity - PnL.BonusCredit > 0`: Total equity including unrealized P&L, realized equity, minus bonus is positive
- Uses INNER JOIN so only customers with an entry in #PnLPerCID are included

**Branch 2 - Customers WITHOUT open positions** (LEFT JOIN #PnLPerCID, `PnL.CID IS NULL`):
- No unrealized P&L exists - account has no open positions
- Only the realized equity / credit balance checks apply

### 2.4 MessageType=3 Insertion (Unblock Message)

**What**: Inserts the unblock message into Trade.ManageBSL via RW synonym.

**Columns/Parameters Involved**: `RW_ManageBSL`, output fields

**Rules**:
- MessageType = 3 (unblock)
- WarningType = 0
- UnRealizedEquity is set to `CUST.RealizedEquity` (no unrealized component for unblock)
- TimeMessageInsertedToQueue = GETUTCDATE()
- NOTE: The OUTPUT clause to BSLQueue was removed per FB 49984 - now uses separate INSERT

### 2.5 BSLQueue Population

**What**: Inserts the newly created unblock messages into Trade.BSLQueue with the threshold value.

**Rules**:
- SELECT from RW_ManageBSL WHERE MessageType=3 AND ID > @StartID (only the just-inserted rows)
- Inserts into RW_BSLQueue with PercentThreshold = @UnBlockPercent
- This links the unblock message to the threshold that triggered it

**Diagram**:
```
Input: #PnLPerCID (pre-created by caller)

1. Load @UnBlockPercent from Dictionary.BSLOperationThreshold ID=4
2. Get @StartID = MAX ManageBSL ID (last 24h) via OPENQUERY [AO-REAL-DB]

3. INSERT INTO RW_ManageBSL (MessageType=3):
   Branch 1: BSL-blocked CIDs WITH positions where
     - (Credit-Bonus)/Credit% >= threshold
     - Not in liquidation
     - Credit-Bonus > 0
     - PnL+RealizedEquity-Bonus > 0

   UNION ALL

   Branch 2: BSL-blocked CIDs WITHOUT positions where
     - (Credit-Bonus)/Credit% >= threshold
     - Not in liquidation
     - Credit-Bonus > 0

4. INSERT INTO RW_BSLQueue: newly inserted ManageBSL rows
   WHERE ID > @StartID AND MessageType=3
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters - procedure takes no arguments. The behavior is controlled by `Dictionary.BSLOperationThreshold ID=4` and the pre-existing `#PnLPerCID` temp table.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| (none) | - | - | - | - | - | No input or output parameters. The procedure is called with no arguments and inserts into RW synonyms as a side effect. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Threshold | Dictionary.BSLOperationThreshold | Lookup | ID=4: unblock equity threshold percentage |
| Max ID | OPENQUERY [AO-REAL-DB] etoro.Trade.ManageBSL | Lookup | Gets max ID watermark from real env via linked server |
| Block check | Customer.BlockedCustomerOperations | Lookup | Identifies customers blocked by BSL (BlockReasonID=9, OperationTypeID=21) |
| Equity data | Customer.CustomerMoney | Lookup | Credit, BonusCredit, RealizedEquity, BSLRealFunds per customer |
| PnL data | #PnLPerCID | Lookup | Temp table (pre-created by caller): PnL, RealizedEquity, BonusCredit per CID |
| Liquidation check | Trade.CIDsInLiquidation | Lookup | Excludes customers currently undergoing liquidation |
| Unblock insert | RW_ManageBSL | Writer | Synonym to real env Trade.ManageBSL - inserts MessageType=3 unblock records |
| Queue insert | RW_BSLQueue | Writer | Synonym to real env Trade.BSLQueue - inserts threshold data for new unblock records |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Trade.SendMessagesToBSL | Conceptual | Consumer | Dequeues the MessageType=3 unblock records inserted by this procedure |
| BSL monitoring job | External caller | Caller | Scheduled job that creates #PnLPerCID and calls this procedure |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.SendUnBlockMessage (procedure)
|- Dictionary.BSLOperationThreshold (table - unblock threshold)
|- [AO-REAL-DB] (linked server - max ID watermark)
|- Customer.BlockedCustomerOperations (table - BSL-blocked CID filter)
|- Customer.CustomerMoney (table - equity/credit data)
|- #PnLPerCID (temp table - caller-provided open position PnL)
|- Trade.CIDsInLiquidation (table - active liquidation exclusion)
|- RW_ManageBSL (synonym -> real env Trade.ManageBSL)
|- RW_BSLQueue (synonym -> real env Trade.BSLQueue)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Dictionary.BSLOperationThreshold | Table | ID=4: unblock threshold percentage (ValueInPercent) |
| [AO-REAL-DB] linked server | External | OPENQUERY for max ManageBSL ID watermark |
| Customer.BlockedCustomerOperations | Table | Filter: BlockReasonID=9, OperationTypeID=21 identifies BSL-liquidated customers |
| Customer.CustomerMoney | Table | Credit, BonusCredit, RealizedEquity, BSLRealFunds for equity calculations |
| #PnLPerCID | Temp Table | Pre-created by caller: PnL.PnL, PnL.RealizedEquity, PnL.BonusCredit per CID |
| Trade.CIDsInLiquidation | Table | LEFT JOIN - excludes customers currently in active liquidation |
| RW_ManageBSL | Synonym | Target for MessageType=3 INSERT (writes to real env ManageBSL) |
| RW_BSLQueue | Synonym | Target for BSLQueue INSERT with PercentThreshold (writes to real env BSLQueue) |

### 6.2 Objects That Depend On This

No dependents found - called by BSL monitoring scheduled job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| BSL block filter | Filter | BlockReasonID=9 AND OperationTypeID=21 - only BSL-liquidated customers |
| Real equity check | Validation | Credit - BonusCredit > 0 (per FB 44763) - prevents unblocking customers with negative real equity |
| Threshold check | Calculation | (Credit-Bonus)/Credit*100 >= @UnBlockPercent - minimum equity recovery fraction |
| Active liquidation exclusion | Safety | LEFT JOIN CIDsInLiquidation, TCL.CID IS NULL - prevents unblocking mid-liquidation |
| Caller contract | Pre-condition | #PnLPerCID must exist before calling - not created by this procedure |
| Cross-env writes | Architecture | RW_ManageBSL, RW_BSLQueue are synonyms to real env - direct real-env manipulation |
| StartID watermark | Correctness | OPENQUERY max ID ensures BSLQueue INSERT only includes newly added records |

---

## 8. Sample Queries

### 8.1 Check eligible unblock candidates before running

```sql
DECLARE @UnBlockPercent NUMERIC(5,2)
SELECT @UnBlockPercent = ValueInPercent
FROM Dictionary.BSLOperationThreshold WITH (NOLOCK)
WHERE ID = 4

SELECT BCO.CID,
    CUST.Credit, CUST.BonusCredit,
    (CUST.Credit-CUST.BonusCredit)/CUST.Credit*100 AS RealEquityPct,
    @UnBlockPercent AS RequiredPct
FROM Customer.BlockedCustomerOperations BCO WITH (NOLOCK)
INNER JOIN Customer.CustomerMoney CUST WITH (NOLOCK) ON BCO.CID = CUST.CID
LEFT JOIN Trade.CIDsInLiquidation TCL WITH (NOLOCK) ON TCL.CID = CUST.CID
WHERE BCO.BlockReasonID = 9
    AND BCO.OperationTypeID = 21
    AND (CUST.Credit-CUST.BonusCredit)/CUST.Credit*100 >= @UnBlockPercent
    AND TCL.CID IS NULL
    AND CUST.Credit - CUST.BonusCredit > 0
```

### 8.2 Check the unblock threshold configuration

```sql
SELECT ID, ValueInPercent AS UnblockThreshold, Description
FROM Dictionary.BSLOperationThreshold WITH (NOLOCK)
ORDER BY ID
```

### 8.3 Inspect recent unblock messages inserted

```sql
SELECT TOP 50 ID, MessageType, CID, RealizedEquity, BonusCredit, BSLRealFunds,
    TimeMessageInsertedToQueue, TimeMessageWasRecieved, TimeMessageWasAck
FROM Trade.ManageBSL WITH (NOLOCK)
WHERE MessageType = 3
ORDER BY TimeMessageInsertedToQueue DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.2/10 (Elements: 8/10, Logic: 10/10, Relationships: 10/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 8 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.SendUnBlockMessage | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.SendUnBlockMessage.sql*
