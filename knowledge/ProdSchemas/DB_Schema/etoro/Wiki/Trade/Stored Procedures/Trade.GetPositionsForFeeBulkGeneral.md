# Trade.GetPositionsForFeeBulkGeneral

> Calculates and applies overnight and end-of-week fees to all eligible CFD positions (excluding Sydney/Australian exchange), updating Trade.PositionTbl and enqueuing balance adjustments. Runs with CID-modulo sharding for parallel execution.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Mod INT = 1, @ModResults TINYINT = 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **core overnight and weekend fee engine** for all CFD positions on non-Australian exchanges. It calculates the appropriate holding fee (overnight or end-of-week) for each eligible position and applies it in a per-row transaction loop. The fee is deducted from the customer's balance (via `Customer.SetBalanceClameFee`) and accumulated on the position (via `UPDATE Trade.PositionTbl.EndOfWeekFee`). Each batch is also enqueued in `dbo.FeeQueueInMem` for downstream notification/processing.

eToro charges holding fees for leveraged and some non-leveraged CFD positions to account for the cost of capital. These fees are collected daily (overnight fee) or weekly (end-of-week fee). Australian exchange positions are excluded here and handled separately by `Trade.GetPositionsForFeeBulkGeneral_Aus`, which uses Sydney market hours and a different fee config table.

Data flows: Called by a scheduled fee collection job, potentially in parallel across multiple worker instances (using @Mod/@ModResults sharding). Phase 1 identifies eligible positions (TPOS0 CTE: open positions + positions closed during the fee window + positions flagged StatusID=2 that closed during the window). Phase 2 joins to ExchangeInstrumentFeeDefinition to get fee type (Fee=1=overnight, Fee=2=EOW) for today's day of week. Phase 3 calculates the fee amount per position (inline CASE logic based on IsBuy, Leverage, fee type, and country). Phase 4 applies fees row-by-row in a WHILE loop with per-row transactions.

---

## 2. Business Logic

### 2.1 Fee Collection Window

**What**: Fees are collected for positions that crossed the New York 5pm "market close" time on the current day.

**Columns/Parameters Involved**: `@TimeLimit`, `@ClosingTimeLocal`

**Rules**:
- @TimeLimit = Trade.ConvertTimeLocalToUTC('Eastern Standard TIME', '17:00') - New York 5pm in UTC.
- If @TimeLimit > GETUTCDATE() (procedure ran before 5pm EST), @TimeLimit is set to previous day's 5pm.
- Open positions: Occurred < @TimeLimit (position opened before the fee window).
- Partially closed positions: CloseOccurred >= @TimeLimit AND OpenOccurred < @TimeLimit (were open at fee time).
- Positions closed during processing: StatusID=2 AND CloseOccurred >= @TimeLimit AND Occurred < @TimeLimit.

### 2.2 Fee Type: Overnight vs End-of-Week

**What**: Fee=1 = daily overnight fee; Fee=2 = end-of-week fee (charged on one specific day per week, typically Wednesday in US market convention).

**Columns/Parameters Involved**: `Trade.ExchangeInstrumentFeeDefinition.Fee`, `LastOverNightClameDate`, `LastEOWClameDate`

**Rules**:
- Fee=1 (overnight): charged daily. Eligible if LastOverNightClameDate IS NULL or LastOverNightClameDate < @TimeLimit.
- Fee=2 (EOW): charged weekly. Eligible if LastEOWClameDate IS NULL or LastEOWClameDate < DATEADD(day,-6, GETUTCDATE()).
- Fee value (1 or 2) is determined by Trade.ExchangeInstrumentFeeDefinition for the instrument's exchange and current day of week.

### 2.3 Fee Amount Calculation

**What**: Fee amount depends on direction (IsBuy), leverage (Leverage=1 vs >1), settlement type (SettlementTypeID), fee type (1=overnight, 2=EOW), and customer country-specific fee rules.

**Columns/Parameters Involved**: `IsBuy`, `Leverage`, `IsSettled`, `SettlementTypeID`, `AmountInUnitsDecimal`, `WeekendFeePrecentage`

**Rules**:
- TRS (SettlementTypeID=2) Buy non-leveraged: FeeInDollars = 0 (no overnight fee for TRS buy).
- Leveraged Buy, overnight: `LeveragedBuyOverNightFee * AmountInUnits * WeekendFeePrecentage/100`.
- Leveraged Sell, overnight: `LeveragedSellOverNightFee * AmountInUnits * WeekendFeePrecentage/100`.
- Non-leveraged Buy, overnight: If IsSettled=0 AND country in whitelist (NonLeveragedBuyCFDOverNightFee) use NonLeveragedBuyCFDOverNightFee; otherwise NonLeveragedBuyOverNightFee.
- Non-leveraged Sell, overnight: `NonLeveragedSellOverNightFee * AmountInUnits * WeekendFeePrecentage/100`.
- EOW variants: uses LeveragedBuyEndOfWeekFee, LeveragedSellEndOfWeekFee, NonLeveragedBuyEndOfWeekFee, NonLeveragedSellEndOfWeekFee.
- Only InstrumentTypeIDs (1,2,4,5,6,10) are eligible.
- Positions with FeeInDollars=0 are excluded from the charge loop.

### 2.4 Exclusions

**What**: Several position categories are excluded from fee collection.

**Rules**:
- Real positions (FRP.IsRealPosition=1): excluded. Only CFD positions charged.
- Sydney exchange (ExchangeID=31): excluded. Handled by GetPositionsForFeeBulkGeneral_Aus.
- Smart Portfolio / fund positions: excluded via Trade.ExcludeFeeByFundID.
- Parent positions of Smart Portfolio: excluded via ParentPositionID NOT IN ExcludeFeeByFundID.
- WeekendFeePrecentage = 0 customer: no fee charged (fee is 0% for this customer).

### 2.5 Parallel Sharding by CID Modulo

**What**: Multiple fee workers run concurrently, each processing a distinct shard of customers.

**Columns/Parameters Involved**: `@Mod`, `@ModResults`

**Rules**:
- WHERE CID % @Mod = @ModResults.
- @Mod=1, @ModResults=0 = process all customers (single worker, default).
- Example: 4 workers: @Mod=4, @ModResults=0/1/2/3.
- Applied consistently throughout: TPOS0 CTE, #PositionsToCharge build, #PositionsToChargeWithFee.

### 2.6 Fail-Safe for Closed Positions

**What**: A position may be closed by another transaction between when it is identified and when the fee UPDATE runs. A fallback to History.Position_Active handles this.

**Columns/Parameters Involved**: `@@ROWCOUNT`

**Rules**:
- UPDATE Trade.PositionTbl WHERE PositionID = @PositionID AND PartitionCol = @PositionID%50.
- If @@ROWCOUNT = 0 (position no longer in PositionTbl): UPDATE History.Position_Active.
- This prevents fee loss when positions close during the fee run.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @Mod | INT | YES | 1 | CODE-BACKED | Modulo denominator for CID-based sharding. Default 1 = process all customers. Set to number of parallel workers for distributed execution. |
| 2 | @ModResults | TINYINT | YES | 0 | CODE-BACKED | Expected CID % @Mod result for this worker's shard. Identifies which customer slice this instance processes. |

**Side Effects (writes, not output columns)**

| # | Target | Operation | Description |
|---|--------|-----------|-------------|
| 3 | Trade.PositionTbl.EndOfWeekFee | UPDATE | Fee amount added to accumulated fees on the position. Also updates LastOverNightClameDate or LastEOWClameDate. |
| 4 | History.Position_Active.EndOfWeekFee | UPDATE (fallback) | Applied when position was closed between identification and update. |
| 5 | dbo.FeeQueueInMem | INSERT | Notification record per CID/MirrorID group: CreditTypeID=14 (weekend fee) or -14 (overnight fee), fee amount, mirror info. |
| 6 | Customer.SetBalanceClameFee | EXEC | Deducts fee from customer's balance credit. Parameters: PositionID, CID, MirrorID, FeeInDollars, ParentPositionID, Description ('Weekend fee' or 'Over night fee'). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID | Trade.PositionTbl | READER + WRITER | Reads eligible positions, updates EndOfWeekFee and fee claim dates |
| PositionID | History.Position_Active | WRITER (fallback) | Updates EndOfWeekFee for positions closed during the fee run |
| PositionID | Trade.PositionTreeInfo | JOIN | Partition-aligned join for PTI.TreeID |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange ID and InstrumentType lookup |
| InstrumentID | Trade.InstrumentToFeeConfig | JOIN | Per-instrument fee rates (Leveraged/NonLeveraged, Buy/Sell, Overnight/EOW) |
| InstrumentID | Trade.ExchangeInstrumentFeeDefinition | JOIN (UNPIVOT) | Day-of-week fee type (1=overnight, 2=EOW) per exchange/instrument |
| IsSettled, InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Identifies real stock positions to exclude |
| CID | Customer.Customer | JOIN | WeekendFeePrecentage and Credit for fee calculation |
| MirrorID | Trade.Mirror | LEFT JOIN | Mirror's Amount (MirrorCredit) and IsActive flag |
| CID | Trade.ExcludeFeeByFundID | Anti-join | Smart Portfolio / fund positions excluded |
| InstrumentTypeID | Trade.GetInstrumentTypeIDsForCFDFee | Function | Gets instrument type IDs eligible for CFD fee |
| CID | dbo.SYN_Settings_DictionaryCountryFeeType | Lookup | Country-specific fee type rules (NonLeveragedBuyCFD whitelist) |
| CID, @PositionID | Customer.SetBalanceClameFee | EXEC callee | Balance adjustment |
| Various | dbo.FeeQueueInMem | INSERT | Notification queue |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fee collection scheduler | @Mod, @ModResults | External call | Scheduled job that runs fee collection daily, potentially with multiple workers |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForFeeBulkGeneral (procedure, WRITER)
├── Trade.PositionTbl (table) [read + write]
├── Trade.PositionTreeInfo (table) [read]
├── History.Position_Active (table) [write, fallback]
├── Trade.InstrumentMetaData (table)
├── Trade.InstrumentToFeeConfig (table)
├── Trade.ExchangeInstrumentFeeDefinition (table)
├── Trade.FnIsRealPosition (function)
├── Trade.GetInstrumentTypeIDsForCFDFee (function)
├── Trade.ConvertTimeLocalToUTC (function)
├── Customer.Customer (table)
├── Customer.SetBalanceClameFee (procedure)
├── Trade.Mirror (table)
├── Trade.ExcludeFeeByFundID (table/view)
├── dbo.SYN_Settings_DictionaryCountryFeeType (synonym/table)
└── dbo.FeeQueueInMem (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | READER: identifies eligible positions; WRITER: updates EndOfWeekFee and claim dates |
| Trade.PositionTreeInfo | Table | JOIN for partition-aligned tree linkage |
| History.Position_Active | Table | WRITER fallback for positions closed during fee run |
| Trade.InstrumentMetaData | Table | Exchange ID (for exclusion) and InstrumentType lookup |
| Trade.InstrumentToFeeConfig | Table | Per-instrument fee rates per direction/leverage |
| Trade.ExchangeInstrumentFeeDefinition | Table | Day-of-week fee type (overnight vs EOW) per exchange/instrument |
| Trade.FnIsRealPosition | Function | CROSS APPLY to exclude real stock positions |
| Trade.GetInstrumentTypeIDsForCFDFee | Function | Returns eligible InstrumentTypeIDs |
| Trade.ConvertTimeLocalToUTC | Function | Converts Eastern 17:00 to UTC |
| Customer.Customer | Table | WeekendFeePrecentage and Credit |
| Customer.SetBalanceClameFee | Procedure | Applies fee to customer balance |
| Trade.Mirror | Table | Mirror credit and active status |
| Trade.ExcludeFeeByFundID | Table/View | Smart Portfolio CID exclusion list |
| dbo.SYN_Settings_DictionaryCountryFeeType | Table | Country-specific fee type rules |
| dbo.FeeQueueInMem | Table | In-memory notification queue |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee collection scheduler | External job | Calls this with @Mod/@ModResults parameters for parallel execution |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp tables use custom indexes: ic on (InstrumentID,CID,MirrorID), ix on (ParentPositionID), clustered on (CID,FeeInDollars)).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Optimization | Fresh execution plan each run due to varying @Mod/@ModResults and data volume |
| Exclude Sydney exchange | Business rule | ExchangeID != 31 (handled by GetPositionsForFeeBulkGeneral_Aus) |
| CFD only | Business rule | FRP.IsRealPosition = 0 (real stocks excluded) |
| WeekendFeePrecentage > 0 | Business rule | Customers with 0% fee rate are skipped |
| @DictionaryCountryFeeType_RowsCount validation | Guard | Raises error if SYN_Settings_DictionaryCountryFeeType returns 0 rows (configuration error) |
| Per-position transaction | Consistency | Each position fee application is in its own BEGIN TRAN/COMMIT TRAN with ROLLBACK on failure |

---

## 8. Sample Queries

### 8.1 Run fee collection for all customers (single worker)

```sql
EXEC Trade.GetPositionsForFeeBulkGeneral @Mod = 1, @ModResults = 0;
```

### 8.2 Run fee collection as worker 1 of 4 (parallel)

```sql
EXEC Trade.GetPositionsForFeeBulkGeneral @Mod = 4, @ModResults = 0;
-- Worker 2: @ModResults = 1, Worker 3: @ModResults = 2, Worker 4: @ModResults = 3
```

### 8.3 Preview eligible positions for fee collection today (read-only check)

```sql
DECLARE @TimeLimit DATETIME = Trade.ConvertTimeLocalToUTC('Eastern Standard TIME', '17:00');
IF @TimeLimit > GETUTCDATE() SET @TimeLimit = DATEADD(day,-1,@TimeLimit);

SELECT TOP 100 TP.PositionID, TP.CID, TP.IsBuy, TP.Leverage, TP.IsSettled, TP.SettlementTypeID, TP.AmountInUnitsDecimal
FROM Trade.PositionTbl TP WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON TP.InstrumentID = IMD.InstrumentID
CROSS APPLY Trade.FnIsRealPosition(TP.IsSettled, TP.InstrumentID) FRP
WHERE TP.StatusID = 1
  AND TP.Occurred < @TimeLimit
  AND FRP.IsRealPosition = 0
  AND IMD.ExchangeID != 31;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForFeeBulkGeneral | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForFeeBulkGeneral.sql*
