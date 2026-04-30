# Trade.GetPayedDividendsAndPositions

> Returns three result sets covering all dividend payment records for a time range and optional CID list: index dividend credits, closed positions that received dividends, and stock dividends from admin position log.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @MinDate/@MaxDate + @CIDs (optional CID filter list) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

**WHAT:** `GetPayedDividendsAndPositions` fetches dividend payment records in three categories for a given time range and optional CID filter. It serves dividend reconciliation, reporting, and statement generation workflows that need to show customers what dividends they received and on which positions.

**WHY:** eToro pays dividends on positions held through ex-dividend dates for both index instruments (ETFs/index CFDs) and real stocks. Three different data sources track different dividend types: (1) index dividends recorded in Trade.PositionsProcessedForIndexDividnds + History.ActiveCredit, (2) closed positions that had dividends, and (3) stock dividends via Trade.AdminPositionLog. A single SP avoids multiple round-trips from the caller.

**HOW:** Builds `#DividendsPositionsPayed` temp table from Trade.PositionsProcessedForIndexDividnds (optionally filtered by @CIDs via Trade.GetPositionData join). Indexes on PositionID and CreditID for efficient joins. Then returns three result sets: (1) live/open positions with credits via History.ActiveCredit; (2) closed dividend-receiving positions via History.Position_Active; (3) stock dividends via Trade.AdminPositionLog + Trade.GetPositionDataSlim + History.ActiveCredit + Trade.FnIsRealPosition.

---

## 2. Business Logic

### 2.1 CID Filter Branching

**What:** When @CIDs is empty, the SP processes ALL customers in the time window. When @CIDs has entries, it filters to only those customers.

**Columns/Parameters Involved:** `@CIDs`, `@CIDsCount`

**Rules:**
- `@CIDsCount = (SELECT COUNT(1) FROM @CIDs)`
- If @CIDsCount = 0: No CID filter - all PositionsProcessedForIndexDividnds in time range
- If @CIDsCount > 0: Filter by joining to Trade.GetPositionData and requiring CID in @CIDs
- The same CID filter is applied in the final result sets via `WHERE @CIDsCount = 0 OR CID IN (@CIDs)`

### 2.2 Result Set 1 - Index Dividend Credits (CreditType = 14)

**What:** Returns dividend cash credits for positions that received index dividend payments, joined to History.ActiveCredit for CID resolution.

**Columns/Parameters Involved:** `CreditID`, `PositionID`, `ProcessTime`, `PaymentAmount`, `CreditType = 14`

**Rules:**
- `#DividendsPositionsPayed JOIN History.ActiveCredit ON CreditID`
- `CreditType = 14` hardcoded - identifies index dividend credit type
- `Occurred` column = ProcessTime from the dividend processing record
- `TotalCashChange` = PaymentAmount (the dividend cash amount credited)

### 2.3 Result Set 2 - Closed Positions with Dividends (CreditType = 4)

**What:** Returns positions that received dividends AND are now closed (exist in History.Position_Active).

**Columns/Parameters Involved:** `PositionID`, `CloseOccurred`, `CreditType = 4`

**Rules:**
- `#DividendsPositionsPayed JOIN History.Position_Active ON PositionID`
- `CreditType = 4` hardcoded - closed position dividend credit type
- `CreditID = 0` (no specific credit record, position-level aggregation)
- `TotalCashChange = 0` (amount not available at this level - caller uses other sources)
- `DISTINCT` applied to avoid duplicates from multiple dividend events per position

### 2.4 Result Set 3 - Stock Dividends (CreditType = 3)

**What:** Returns real-stock dividends from Trade.AdminPositionLog where the open action type = 4 (dividend reinvestment or stock dividend event). Includes instrument and position direction for price data merging by the application.

**Columns/Parameters Involved:** `apl.OpenActionType = 4`, `CreditTypeID = 3`, `IsRealPosition`, `InstrumentID`, `AmountInUnitsDecimal`, `IsBuy`

**Rules:**
- `Trade.AdminPositionLog WHERE OpenActionType = 4` - stock dividend events
- Joined to Trade.GetPositionDataSlim for position direction and units
- Joined to History.ActiveCredit WHERE CreditTypeID = 3 AND Occurred BETWEEN @MinDate AND @MaxDate
- CROSS APPLY Trade.FnIsRealPosition(IsSettled, InstrumentID) to determine if real stock
- Comment: "This data will be merged to Price Data from History.CurrencyPriceMaxDate by Application"
- `CreditType = 3` - stock dividend credit type

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @MinDate | DATETIME | NO | - | CODE-BACKED | Start of the dividend processing time window. Applied to ProcessTime, ExecutionOccurred, Occurred, and OpenOccurred. |
| 2 | @MaxDate | DATETIME | NO | - | CODE-BACKED | End of the dividend processing time window (inclusive via BETWEEN). |
| 3 | @CIDs | Trade.CidList | YES | empty | CODE-BACKED | Optional list of CIDs to filter results. READONLY table-valued parameter. If empty (count=0), returns all customers. |

**Output - Result Set 1 (Index Dividend Credits, CreditType=14):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | CID | INT | NO | - | CODE-BACKED | Customer ID from History.ActiveCredit. |
| 5 | CreditID | BIGINT | YES | - | CODE-BACKED | Credit record ID from History.ActiveCredit. Links to the specific dividend credit entry. |
| 6 | PositionID | BIGINT | YES | - | CODE-BACKED | Position that received the dividend. |
| 7 | Occurred | DATETIME | YES | - | CODE-BACKED | ProcessTime from PositionsProcessedForIndexDividnds - when the dividend was processed. |
| 8 | TotalCashChange | MONEY | YES | - | CODE-BACKED | PaymentAmount - the dividend cash amount credited to the customer. |
| 9 | CreditType | INT | NO | 14 | CODE-BACKED | Hardcoded 14 = index dividend credit type. |

**Output - Result Set 2 (Closed Positions with Dividends, CreditType=4):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 10 | CID | INT | NO | - | CODE-BACKED | Customer ID from History.Position_Active. |
| 11 | CreditID | BIGINT | NO | 0 | CODE-BACKED | Always 0 - position-level aggregation, no specific credit record. |
| 12 | PositionID | BIGINT | YES | - | CODE-BACKED | The closed position that received dividends. |
| 13 | Occurred | DATETIME | YES | - | CODE-BACKED | CloseOccurred from History.Position_Active. |
| 14 | TotalCashChange | MONEY | NO | 0 | CODE-BACKED | Always 0 - amount not provided at this level. |
| 15 | CreditType | INT | NO | 4 | CODE-BACKED | Hardcoded 4 = closed position dividend credit type. |

**Output - Result Set 3 (Stock Dividends, CreditType=3):**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 16 | CID | INT | NO | - | CODE-BACKED | Customer ID from Trade.AdminPositionLog. |
| 17 | CreditID | BIGINT | YES | - | CODE-BACKED | Credit ID from History.ActiveCredit (CreditTypeID=3). |
| 18 | PositionID | BIGINT | NO | - | CODE-BACKED | Position that received the stock dividend. |
| 19 | Occurred | DATETIME | YES | - | CODE-BACKED | ExecutionOccurred from Trade.AdminPositionLog. |
| 20 | AmountInUnitsDecimal | DECIMAL | YES | - | CODE-BACKED | Units of the position at time of dividend. For price merging by application. |
| 21 | IsBuy | BIT | YES | - | CODE-BACKED | Direction of the position (1=Long, 0=Short). For price merging by application. |
| 22 | IsRealPosition | BIT | YES | - | CODE-BACKED | Whether the position is a real stock position. From Trade.FnIsRealPosition(IsSettled, InstrumentID). |
| 23 | CreditType | INT | NO | 3 | CODE-BACKED | Hardcoded 3 = stock dividend credit type. |
| 24 | InstrumentID | INT | YES | - | CODE-BACKED | Instrument of the position. For merging with History.CurrencyPriceMaxDate by application. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionsProcessedForIndexDividnds | Lookup | Index dividend processing records |
| PositionID | Trade.GetPositionData | Lookup | CID lookup for @CIDs filter (when CIDs provided) |
| CreditID | History.ActiveCredit | Lookup | Credit record for CID resolution and type=14/type=3 |
| PositionID | History.Position_Active | Lookup | Closed position records for type=4 result set |
| PositionID | Trade.AdminPositionLog | Lookup | Stock dividend events (OpenActionType=4) |
| PositionID | Trade.GetPositionDataSlim | Lookup | Position direction, units, settlement for type=3 |
| IsSettled + InstrumentID | Trade.FnIsRealPosition | Function | Real vs CFD position classification |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called by dividend reporting and statement services.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPayedDividendsAndPositions (procedure)
|- Trade.PositionsProcessedForIndexDividnds (table) - index dividend processing log
|- Trade.GetPositionData (view/proc) - CID filter for optional @CIDs
|- History.ActiveCredit (table) - credit records
|- History.Position_Active (table) - closed positions
|- Trade.AdminPositionLog (table) - stock dividend events
|- Trade.GetPositionDataSlim (view) - position metadata for stock dividends
|- Trade.FnIsRealPosition (function) - real/CFD classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionsProcessedForIndexDividnds | Table | Index dividend processing records (stage 1 filter) |
| Trade.GetPositionData | View/Proc | CID lookup when @CIDs filter is active |
| History.ActiveCredit | Table | Credit CID resolution (type 14 and 3) |
| History.Position_Active | Table | Closed positions for type-4 result set |
| Trade.AdminPositionLog | Table | Stock dividend events (OpenActionType=4) |
| Trade.GetPositionDataSlim | View | Position AmountInUnitsDecimal, IsBuy, IsSettled, InstrumentID |
| Trade.FnIsRealPosition | Function | IsRealPosition flag for stock dividends |
| Trade.CidList | User Defined Type | Table-valued parameter type for @CIDs |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT. | - | Called by dividend reporting services |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| IX_PositionID on #DividendsPositionsPayed | NONCLUSTERED | PositionID | - | - | Temp (session) |
| IX_CreditID on #DividendsPositionsPayed | NONCLUSTERED | CreditID | - | - | Temp (session) |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| DROP TABLE IF EXISTS #DividendsPositionsPayed | Safety | Prevents error on re-run in same session |
| @CIDsCount = 0 branch | Conditional | All-customer vs specific-customer path |
| OpenActionType = 4 | Filter | Only stock dividend admin log entries |
| CreditTypeID = 3 | Filter | Only stock dividend credits in History.ActiveCredit |
| UNION ALL in final SELECT | Dedup | UNION ALL (not UNION) - sets are non-overlapping by CreditType |
| WITH (NOLOCK) on all tables | Performance | Dirty read acceptable for reporting queries |

---

## 8. Sample Queries

### 8.1 All dividends for a date range (all customers)

```sql
DECLARE @emptyCIDs Trade.CidList
EXEC Trade.GetPayedDividendsAndPositions
    @MinDate = '2024-01-01',
    @MaxDate = '2024-01-31',
    @CIDs = @emptyCIDs
```

### 8.2 Dividends for specific customers

```sql
DECLARE @cids Trade.CidList
INSERT @cids VALUES (1001), (1002), (1003)

EXEC Trade.GetPayedDividendsAndPositions
    @MinDate = '2024-01-01',
    @MaxDate = '2024-01-31',
    @CIDs = @cids
```

### 8.3 Count dividend records by type

```sql
-- Result set 1 has CreditType=14, result set 2 has CreditType=4, result set 3 has CreditType=3
-- Caller separates by CreditType column value
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 10.0/10, Logic: 9.0/10, Relationships: 8.5/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 24 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPayedDividendsAndPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPayedDividendsAndPositions.sql*
