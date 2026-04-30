# Trade.GetOrderForCloseContextData

> Returns multi-result-set pre/post-execution context for processing a position close order - customer eligibility, blocked operations, position state, and pending close detection, with behavior branching on CallerService (PreExecution vs PostExecution).

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID INT + @PositionIDs TVP + @CallerService TINYINT |
| **Partition** | PositionTbl: PartitionCol = PositionID%50, PositionTreeInfo: PartitionCol = abs(TreeID%50) |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetOrderForCloseContextData` is the primary context-loading SP for the close-order execution pipeline. It loads all the data an execution service needs in a single round trip: customer block status, customer profile, the positions being closed, and (for pre-execution only) whether a conflicting pending open order exists for the same instrument. It also has a lock mode parameter to support both read-uncommitted (high-throughput) and read-committed (consistency) modes.

**WHY:** Before a close order can be executed, the system must verify: Is the customer blocked? Are the positions still open and in the correct state? Is there a pending open order that might conflict? Are the positions being copied (mirror status)? This SP loads all of that context in one query, avoiding multiple round trips.

**HOW:** Called from the pre-execution and post-execution services. `@CallerService` controls what is returned:
- `@CallerService = 0` (PreExecution): returns blocked operations, full customer profile, position data, AND pending open order check
- `@CallerService = 1` (PostExecution): skips blocked operations check, returns a null-row for blocked operations, skips position's pending close detection, and skips the pending open order check

---

## 2. Business Logic

### 2.1 CallerService Branching

**What:** `@CallerService` is the central control that determines which result sets are returned and how they are populated.

**Columns/Parameters Involved:** `@CallerService`

**Rules:**
- `@CallerService = 0` (PreExecution): Full context - all 4 result sets
- `@CallerService = 1` (PostExecution): Minimal context - result set 1 is empty, result set 2 (customer) returned, result set 3 (positions) returned without pending close detection, result set 4 (pending open) skipped

### 2.2 Result Set 1: Blocked Customer Operations

**What:** Returns blocking records for the customer. Skipped for PostExecution (returns null row instead).

**Rules:**
- `Customer.BlockedCustomerOperations JOIN Trade.OperationTypeForBlockingToAtomic`
- Returns AtomicOperationID, BlockReasonID, OperationTypeID
- If PostExecution: `SELECT null WHERE 1=0` -> empty result

### 2.3 Result Set 2: Customer Profile

**What:** Returns customer account data for eligibility checks.

**Columns/Parameters Involved:** `Maintenance.Feature.FeatureID=22`, `@IsReal`, `@IsBeingCopied`

**Rules:**
- `FeatureID=22` in `Maintenance.Feature` is the "IsReal" flag (live trading environment flag)
- `@IsBeingCopied = 1` if the customer has any active mirrors as a leader (Trade.Mirror WHERE ParentCID=@CID) AND `@IsReal=1` AND `@CallerService != 1`
- Returns: Credit=0 (hardcoded), PlayerStatusID, LabelID, IsCupon=0, PlayerLevelID, RealizedEquity, IsCopyBlocked=0, CopyBlockReasonID=0, IsBeingCopied, CountryID, SerialID AS AffiliateID, GCID, CID, TradingRiskStatusID, RegulationID, AccountCurrencyID=1 (hardcoded USD), DltID, AccountTypeID, MasterAccountCID
- Cross-schema: Customer.Customer + BackOffice.Customer

### 2.4 Result Set 3: Position Data

**What:** Returns all open positions from the input TVP, with their tree data and optional pending close info.

**Rules:**
- PositionTbl + PositionTreeInfo + Mirror (same pattern as GetOpenPositionsData)
- Partition elimination: `PartitionCol = PositionID%50`, `abs(TreeID%50)`
- `ISNULL(SettlementTypeID, ISNULL(IsSettled,0))` -> settlement type fallback to IsSettled (differs from GetOpenPositionsData which reads SettlementTypeID directly)
- Pending close (OUTER APPLY): only when `@CallerService != 1` - for PostExecution the OUTER APPLY conditions on `@CallerService != 1` make it always return NULL
- Returns 47 columns including PnLVersion, InitConversionRate, OpenMarkup, OpenMarketSpread, InitialUnits, OrderID, LotCountDecimal, Commission, FullCommission (more fields than GetOpenPositionsData)

### 2.5 Result Set 4: Pending Open Order (PreExecution Only)

**What:** For PreExecution only, checks if there is a PLACED open order for the same instrument (to flag potential conflict).

**Rules:**
- `@CallerService = 0` only
- `Trade.OrderForOpen WHERE CID=@CID AND InstrumentID=@InstrumentID AND StatusID=2 AND SettlementTypeID=1`
- `StatusID=2` = PLACED, `SettlementTypeID=1` = REAL
- Returns: TOP 1 `OrderID AS PendingOrderForOpenOnInstrument`

### 2.6 Lock Mode

**Rules:**
- `@LockPosition = 1` -> `READ COMMITTED` (shared locks)
- `@LockPosition = 0` (default) -> `READ UNCOMMITTED` (NOLOCK)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | int | NO | - | CODE-BACKED | Customer ID for all context queries. |
| 2 | @PositionIDs | Trade.PositionIDsTbl_MOT READONLY | NO | - | CODE-BACKED | Memory-optimized TVP of PositionIDs to fetch. Uses _MOT variant for performance. |
| 3 | @CallerService | tinyint | NO | - | CODE-BACKED | 0=PreExecution (full context), 1=PostExecution (minimal context, skips pending order check and some result sets). |
| 4 | @LockPosition | bit | YES | 0 | CODE-BACKED | Lock mode: 0=READ UNCOMMITTED (default), 1=READ COMMITTED. |
| 5 | @InstrumentID | int | NO | - | CODE-BACKED | Instrument being closed. Used for pending-open-order check in PreExecution. |
| 6 | @OrderID | bigint | YES | 0 | CODE-BACKED | Current close order ID. Excluded from pending-close detection (OUTER APPLY). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.BlockedCustomerOperations | Direct query (RS1) | Check blocked operations for customer |
| BlockedCustomerOperations | Trade.OperationTypeForBlockingToAtomic | JOIN (RS1) | Map operation type to atomic operation |
| @CID | Customer.Customer | Direct query (RS2) | Customer profile |
| Customer | BackOffice.Customer | INNER JOIN (RS2) | Account type, regulation, risk status |
| @CID check | Trade.Mirror | Subquery (RS2) | Check if customer is being copied |
| @CID, Maintenance.Feature | Maintenance.Feature | Scalar subquery (RS2) | FeatureID=22 IsReal flag |
| @PositionIDs | Trade.PositionTbl | JOIN (RS3) | Position data with partition elimination |
| Trade.PositionTbl.TreeID | Trade.PositionTreeInfo | JOIN (RS3) | Stop/limit rates and tree flags |
| Trade.PositionTbl.MirrorID | Trade.Mirror | LEFT JOIN (RS3) | Mirror active status |
| Trade.PositionTbl.PositionID | Trade.CloseExecutionPlan | OUTER APPLY (RS3) | Pending close detection |
| CloseExecutionPlan | Trade.OrderForClose | JOIN in APPLY (RS3) | Close order status |
| OrderForClose | Dictionary.OrderForExecutionStatus | JOIN in APPLY (RS3) | Non-terminal filter |
| @CID, @InstrumentID | Trade.OrderForOpen | Direct query (RS4) | Pending placed open order check |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Pre-execution close service | N/A | CALLER | Loads full close context before execution |
| Post-execution close service | N/A | CALLER | Loads minimal close context after execution |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetOrderForCloseContextData (procedure)
├── Customer.BlockedCustomerOperations (table)
├── Trade.OperationTypeForBlockingToAtomic (table)
├── Maintenance.Feature (table)
├── Trade.Mirror (table)
├── Customer.Customer (table)
├── BackOffice.Customer (table)
├── Trade.PositionTbl (table)
├── Trade.PositionIDsTbl_MOT (UDT)
├── Trade.PositionTreeInfo (table)
├── Trade.CloseExecutionPlan (table)
├── Trade.OrderForClose (table)
├── Dictionary.OrderForExecutionStatus (table)
└── Trade.OrderForOpen (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionIDsTbl_MOT | User Defined Type | Input TVP parameter type (memory-optimized) |
| Customer.BlockedCustomerOperations | Table | RS1: blocked ops check |
| Trade.OperationTypeForBlockingToAtomic | Table | RS1: operation type mapping |
| Maintenance.Feature | Table | RS2: FeatureID=22 IsReal flag |
| Trade.Mirror | Table | RS2: IsBeingCopied check; RS3: mirror status |
| Customer.Customer | Table | RS2: customer profile |
| BackOffice.Customer | Table | RS2: account type, regulation |
| Trade.PositionTbl | Table | RS3: position data |
| Trade.PositionTreeInfo | Table | RS3: stop/limit rates |
| Trade.CloseExecutionPlan | Table | RS3: pending close detection |
| Trade.OrderForClose | Table | RS3: pending close status |
| Dictionary.OrderForExecutionStatus | Table | RS3: IsTerminal flag |
| Trade.OrderForOpen | Table | RS4: pending placed open order |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Pre/Post-execution close services | External | Primary context loader for close order execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Note:** Uses `Trade.PositionIDsTbl_MOT` (memory-optimized TVP) unlike `GetOpenPositionsData` which uses `Trade.PositionIDsTbl`. The `_MOT` variant is faster for in-memory workloads.

**Note:** `AccountCurrencyID = 1` is hardcoded (USD). This reflects a system design where account currency is always USD for trading purposes even if the customer's display currency differs.

**Note:** Settlement type uses `ISNULL(SettlementTypeID, ISNULL(IsSettled,0))` fallback - same as GetOpenPositionData but differs from GetOpenPositionsData which reads directly.

---

## 8. Sample Queries

### 8.1 PreExecution context for a close
```sql
DECLARE @ids Trade.PositionIDsTbl_MOT
INSERT INTO @ids VALUES (111111111), (222222222)
EXEC Trade.GetOrderForCloseContextData
    @CID = 9876543,
    @PositionIDs = @ids,
    @CallerService = 0,  -- PreExecution
    @LockPosition = 0,
    @InstrumentID = 1234,
    @OrderID = 0
```

### 8.2 PostExecution context (minimal)
```sql
DECLARE @ids Trade.PositionIDsTbl_MOT
INSERT INTO @ids VALUES (111111111)
EXEC Trade.GetOrderForCloseContextData
    @CID = 9876543,
    @PositionIDs = @ids,
    @CallerService = 1,  -- PostExecution
    @LockPosition = 1,  -- shared lock for consistency
    @InstrumentID = 1234,
    @OrderID = 99887766
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9/10, Logic: 9/10, Relationships: 8/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 complete; 9B skipped-no app refs)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetOrderForCloseContextData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetOrderForCloseContextData.sql*
