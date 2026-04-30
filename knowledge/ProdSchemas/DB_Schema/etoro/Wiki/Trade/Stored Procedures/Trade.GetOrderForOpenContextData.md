# Trade.GetOrderForOpenContextData

> Returns multi-result-set pre/post-execution context for processing an open order - customer eligibility, account balance, blocked operations, parent position data, waiting-for-market order state, admin position log, and mirror/leverage tier data.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @InstrumentID INT + @CallerService TINYINT |
| **Partition** | dbo.RealOpenPositions: PartitionCol = PositionID%50 (in GetParentData path) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForOpenContextData` is the primary context-loading SP for the open-order execution pipeline. It loads everything needed to process an open order in a single round trip: customer block status, account balance/profile, and (for pre-execution only) pending close order check, parent position data, waiting-for-market order details, admin position log, and leverage tier/mirror credit data. Post-execution gets a smaller context (parent position ratio, mirror credit).

**WHY:** Before executing an open order, the system must verify: Is the customer blocked for this operation? What is the customer's available credit (account balance minus pending orders)? Is there a conflicting pending close? For copy/hierarchical opens, what is the parent position's settlement type and tree? For market-open orders, what is the frozen amount? This SP loads all that context in one query.

**HOW:** `@CallerService` controls which result sets are returned:
- `@CallerService = 0` (PreExecution): full context - all result sets
- `@CallerService = 1` (PostExecution): minimal context - blocked ops (RS1), customer (RS2), parent ratio data (RS8), mirror credit (RS9)

---

## 2. Business Logic

### 2.1 CallerService Branching

**Columns/Parameters Involved:** `@CallerService`

**Rules:**
- 0 = PreExecution: all logic runs
- 1 = PostExecution: RS3-RS7 skipped; RS8 returns PostAdjustmentRatio from ExecutedOpenOrders; RS9 returns MirrorCredit

### 2.2 Result Set 1: Blocked Operations

**What:** Returns any blocking records for the customer. Always returned for both caller services.

**Rules:**
- `Customer.BlockedCustomerOperations JOIN Trade.OperationTypeForBlockingToAtomic`
- Returns: CID, AtomicOperationID, BlockReasonID, OperationTypeID

### 2.3 Result Set 2: Customer Account Profile

**What:** Returns customer account data including available credit (net of pending orders), copy status, and account classification.

**Key computed fields:**
- `Credit - @TotalOrdersAmount` -> net available credit. `@TotalOrdersAmount` = `Trade.GetTotalManualOrdersForOpenAmount(@CID)` (a function that sums pending order amounts)
- `IsCupon = CASE WHEN BackOffice.BonusOnlyCustomers.CID IS NOT NULL THEN 1 ELSE 0 END` -> whether customer is on bonus-only tier
- `IsCopyBlocked = ISNULL(CBO.OperationTypeID, 0)` where CBO is BlockedCustomerOperations for OperationTypeID=1 (copy blocking)
- `IsBeingCopied = 1` if customer has any mirrors as leader AND IsReal=1
- `AccountCurrencyID = 1` (hardcoded USD)
- Cross-schema: Customer.Customer + BackOffice.Customer + BackOffice.BonusOnlyCustomers + Customer.BlockedCustomerOperations (copy block check)

### 2.4 PreExecution RS3: Pending Close Order Check (GetPendingOrders=1)

**Rules:**
- If `@GetPendingOrders = 1`: `TOP 1 Trade.OrderForClose WHERE CID=@CID AND InstrumentID=@InstrumentID AND StatusID=2 AND SettlementTypeID=1`
- Returns: OrderID AS PendingOrderForCloseOnInstrument

### 2.5 PreExecution RS4: Parent Position Data (GetParentData=1)

**What:** For hierarchical/copy opens, fetches the parent position's tree context and flags.

**Rules:**
- Queries `dbo.RealOpenPositions` (a real-time view of open positions) at `@ParentPositionIDToCheck`
- CROSS APPLY to get root TreeID's SettlementTypeID
- `@PositionOpen OUTPUT` set to 1 if found, 0 if not found
- Returns: ParentPositionID, ParentCID, RootHedgeServerID, TreeID, StopRate, LimitRate, RootSettlementType, TrailingStopLossThreshold, IsCopyFund (AccountTypeID=9), IsDiscounted, IsTslEnabled, IsNoStopLoss, IsNoTakeProfit

### 2.6 PreExecution RS5: Waiting-For-Market Order Data (GetWaitingForMarketOrderData=1)

**What:** For StatusID=11 (WaitingForMarket) orders, fetches the frozen amount and order parameters.

**Rules:**
- `Trade.OrderForOpen WHERE OrderID=@OrderID AND StatusID=11`
- Sets local variables: @OperationType, @Amount (ISNULL(FrozenAmount, Amount)), @RequestedSettlementTypeID, etc.
- Returns as scalar row: OperationType, Amount, RequestedSettlementTypeID, RequestedOpenActionType, IsNoStopLoss, IsNoTakeProfit, AdditionalMargin

### 2.7 PreExecution RS6: Admin Position Log (GetAdminPositionLogData=1 OR OperationType=22)

**What:** For admin-initiated opens (OperationType=22 = AdminOrderForOpenWithHedge) or when explicitly requested, returns the AdminPositionLog record.

**Rules:**
- `Trade.AdminPositionLog WHERE OrderID=@OrderID`
- Returns full AdminPositionLog row

### 2.8 PreExecution RS7: Leverage Tiers OR Mirror Credit

**Rules:**
- If `@MirrorID = 0` (self-opened): EXEC `Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection` -> returns leverage tier data
- If `@MirrorID > 0` (copy): `SELECT Amount AS MirrorCredit FROM Trade.Mirror WHERE MirrorID=@MirrorID AND CID=@CID`

### 2.9 PostExecution RS8: Post-Adjustment Ratio

**Rules:**
- If `@ParentOpenCorrelationID IS NULL`: return `1 AS PostAdjustmentRatio, NULL AS ParentPositionID, NULL AS TreeID`
- Otherwise: `SELECT PostAdjustmentRatio, PositionID AS ParentPositionID, TreeID FROM Trade.ExecutedOpenOrders WHERE OpenCorrelationID=@ParentOpenCorrelationID`

### 2.10 PostExecution RS9: Mirror Credit

- `SELECT Amount AS MirrorCredit FROM Trade.Mirror WHERE MirrorID=@MirrorID AND CID=@CID`

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID for all context queries. |
| 2 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument being opened. Used for pending-close check and leverage tiers. |
| 3 | @CallerService | tinyint | NO | - | CODE-BACKED | 0=PreExecution (full context), 1=PostExecution (minimal context). |
| 4 | @MirrorID | int | YES | 0 | CODE-BACKED | Mirror ID for copy opens. 0=self-opened (returns leverage tiers), >0=copy (returns mirror credit). |
| 5 | @ParentOpenCorrelationID | uniqueidentifier | YES | NULL | CODE-BACKED | For PostExecution: GUID of parent open correlation. Used to get PostAdjustmentRatio from ExecutedOpenOrders. |
| 6 | @ParentPositionIDToCheck | bigint | YES | NULL | CODE-BACKED | Parent position to check existence for copy/hierarchical opens. Sets @PositionOpen OUTPUT. |
| 7 | @PositionOpen | bit | YES | NULL OUTPUT | CODE-BACKED | OUTPUT: 1 if parent position found and open, 0 if not found. |
| 8 | @GetParentData | bit | YES | 0 | CODE-BACKED | If 1, fetch parent position data (RS4). |
| 9 | @GetPendingOrders | bit | YES | 1 | CODE-BACKED | If 1, check for pending close orders (RS3). Default 1 = always check. |
| 10 | @GetWaitingForMarketOrderData | bit | YES | 0 | CODE-BACKED | If 1, fetch WaitingForMarket order parameters (RS5). |
| 11 | @GetAdminPositionLogData | bit | YES | 0 | CODE-BACKED | If 1, fetch AdminPositionLog (RS6). Also auto-triggered when OperationType=22. |
| 12 | @OrderID | bigint | YES | 0 | CODE-BACKED | Current open order ID. Used for WaitingForMarket and AdminPositionLog lookup. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.BlockedCustomerOperations | Direct query (RS1) | Blocked operations |
| BlockedOps | Trade.OperationTypeForBlockingToAtomic | JOIN (RS1) | Operation type mapping |
| @CID | Trade.GetTotalManualOrdersForOpenAmount | Function call (RS2) | Pending order amount for net credit |
| @CID | Customer.Customer + BackOffice.Customer | JOIN (RS2) | Customer profile |
| Customer | BackOffice.BonusOnlyCustomers | LEFT JOIN (RS2) | Bonus-only customer flag |
| Customer | Customer.BlockedCustomerOperations | LEFT JOIN (RS2) | Copy block check |
| @CID | Trade.Mirror | Subquery (RS2 + RS7/9) | IsBeingCopied + mirror credit |
| Maintenance.Feature | Maintenance.Feature | Scalar subquery (RS2) | FeatureID=22 IsReal flag |
| @CID, @InstrumentID | Trade.OrderForClose | Direct query (RS3) | Pending placed close order |
| @ParentPositionIDToCheck | dbo.RealOpenPositions | Direct query (RS4) | Parent position existence check |
| dbo.RealOpenPositions | dbo.RealBackOfficeCustomer | JOIN (RS4) | AccountTypeID for IsCopyFund |
| @OrderID | Trade.OrderForOpen | Direct query (RS5) | WaitingForMarket order |
| @OrderID | Trade.AdminPositionLog | Direct query (RS6) | Admin position log |
| @CID, @InstrumentID | Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection | EXEC (RS7) | Leverage tiers |
| @ParentOpenCorrelationID | Trade.ExecutedOpenOrders | Direct query (RS8) | Post-adjustment ratio |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Pre-execution open service | N/A | CALLER | Full context for pre-execution validation |
| Post-execution open service | N/A | CALLER | Minimal context for post-execution ratio adjustment |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForOpenContextData (procedure)
├── Customer.BlockedCustomerOperations (table)
├── Trade.OperationTypeForBlockingToAtomic (table)
├── Trade.GetTotalManualOrdersForOpenAmount (function)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── BackOffice.BonusOnlyCustomers (table)
├── Maintenance.Feature (table)
├── Trade.Mirror (table)
├── Trade.OrderForClose (table)
├── dbo.RealOpenPositions (view)
├── dbo.RealBackOfficeCustomer (view)
├── Trade.OrderForOpen (table)
├── Trade.AdminPositionLog (table)
├── Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection (procedure)
└── Trade.ExecutedOpenOrders (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.BlockedCustomerOperations | Table | RS1: blocked ops |
| Trade.OperationTypeForBlockingToAtomic | Table | RS1: operation mapping |
| Trade.GetTotalManualOrdersForOpenAmount | Function | RS2: net credit computation |
| Customer.Customer | Table | RS2: customer profile |
| BackOffice.Customer | Table | RS2: account type, regulation |
| BackOffice.BonusOnlyCustomers | Table | RS2: bonus-only flag |
| Maintenance.Feature | Table | RS2: IsReal flag |
| Trade.Mirror | Table | RS2/RS7/RS9: IsBeingCopied + mirror credit |
| Customer.BlockedCustomerOperations | Table | RS2: copy block check |
| Trade.OrderForClose | Table | RS3: pending close on instrument |
| dbo.RealOpenPositions | View | RS4: parent position lookup |
| dbo.RealBackOfficeCustomer | View | RS4: AccountTypeID |
| Trade.OrderForOpen | Table | RS5: WaitingForMarket order |
| Trade.AdminPositionLog | Table | RS6: admin position log |
| Trade.GetAggregatedUnitsTiersByLeverageForInstrumentPerDirection | Procedure | RS7: leverage tiers |
| Trade.ExecutedOpenOrders | Table | RS8: post-adjustment ratio |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Open-order execution services (pre + post) | External | Primary context loader for open order processing |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** This is one of the most complex SPs in the Trade schema. It returns up to 9 result sets depending on parameters. Callers must process result sets in order and understand which are present based on @CallerService and flag parameters.

**Note:** `dbo.RealOpenPositions` and `dbo.RealBackOfficeCustomer` are accessed via `dbo` schema - these are likely synonyms or real-time views wrapping Trade.PositionTbl and BackOffice.Customer respectively.

**Note:** The `@PositionOpen` OUTPUT parameter is only meaningful when `@GetParentData = 1`.

---

## 8. Sample Queries

### 8.1 PreExecution context for a self-opened order
```sql
DECLARE @posOpen BIT
EXEC Trade.GetOrderForOpenContextData
    @CID = 9876543,
    @InstrumentID = 1234,
    @CallerService = 0,  -- PreExecution
    @MirrorID = 0,
    @PositionOpen = @posOpen OUTPUT,
    @GetPendingOrders = 1,
    @OrderID = 987654321
```

### 8.2 PostExecution context for a copy order
```sql
DECLARE @posOpen BIT
EXEC Trade.GetOrderForOpenContextData
    @CID = 9876543,
    @InstrumentID = 1234,
    @CallerService = 1,  -- PostExecution
    @MirrorID = 5678901,
    @ParentOpenCorrelationID = 'XXXXXXXX-XXXX-XXXX-XXXX-XXXXXXXXXXXX',
    @PositionOpen = @posOpen OUTPUT
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForOpenContextData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForOpenContextData.sql*
