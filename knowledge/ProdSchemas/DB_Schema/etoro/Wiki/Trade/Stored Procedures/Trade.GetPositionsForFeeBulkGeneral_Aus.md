# Trade.GetPositionsForFeeBulkGeneral_Aus

> Australian-exchange variant of the overnight/EOW fee engine: calculates and applies holding fees for Sydney exchange (ExchangeID=31) positions only, using AUS Eastern Standard Time for the fee window, Trade.CalculatePositionOvernightFee for fee amounts, and InstrumentToFeeConfigV2 for rates. Includes real-futures (SettlementTypeID=4) and CMT (SettlementTypeID=5) positions in addition to CFD.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Mod INT = 1, @ModResults TINYINT = 0 |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the **Australian-exchange overnight and weekend fee engine**, the counterpart to `Trade.GetPositionsForFeeBulkGeneral` (which excludes Sydney). It processes only positions on the Sydney exchange (ExchangeID=31), uses the Australian Eastern Standard Time timezone for the 5pm market close window, and calculates fee amounts via the `Trade.CalculatePositionOvernightFee` function (vs. the inline CASE logic in the general procedure). It also uses `Trade.InstrumentToFeeConfigV2` for rate lookup (vs. `Trade.InstrumentToFeeConfig`), and includes real-futures (SettlementTypeID=4 with Leverage=1) and CMT (SettlementTypeID=5) positions in addition to standard CFDs - reflecting ASX-specific product types not available on other exchanges.

eToro charges holding fees for leveraged and some non-leveraged positions to account for the cost of capital. Australian exchange positions are excluded from the general procedure and handled here due to different market hours (Sydney close vs. New York close) and different eligible product types. The same WHILE loop / per-row transaction / fallback to History.Position_Active / FeeQueueInMem insert pattern is used as in the general procedure.

Data flows: Called by a scheduled fee collection job, potentially in parallel across multiple worker instances (using @Mod/@ModResults sharding). Phase 1 identifies eligible positions (TPOS0 CTE) for ExchangeID=31 only. Phase 2 filters to a #ValidPositions temp table applying broader settlement type eligibility. Phase 3 calls Trade.CalculatePositionOvernightFee per position to get the fee amount. Phase 4 applies fees row-by-row in a WHILE loop with per-row transactions.

---

## 2. Business Logic

### 2.1 Fee Collection Window (AUS Eastern Time)

**What**: Fees are collected for Australian exchange positions that crossed the Sydney 5pm "market close" time on the current day.

**Columns/Parameters Involved**: `@TimeLimit`, `@ClosingTimeLocal`, `@ExchangeIdConsidered`

**Rules**:
- @ExchangeIdConsidered = 31 (Sydney/ASX exchange).
- @ClosingTimeLocal = '17:00' with 'AUS Eastern Standard Time' (vs. 'Eastern Standard TIME' in the general procedure).
- @TimeLimit = Trade.ConvertTimeLocalToUTC('AUS Eastern Standard Time', '17:00') - Sydney 5pm in UTC.
- If @TimeLimit > GETUTCDATE() (procedure ran before 5pm AEST), @TimeLimit is set to previous day's 5pm.
- Same three position eligibility categories as general: open, partially closed, StatusID=2 closed during processing.

### 2.2 Broader Settlement Type Eligibility

**What**: Australian exchange positions include real-futures and CMT settlement types in addition to CFD, reflecting ASX-listed products.

**Columns/Parameters Involved**: `FRP.IsRealPosition`, `SettlementTypeID`, `Leverage`

**Rules**:
- Eligible if: `FRP.IsRealPosition = 0` (CFD) OR `(SettlementTypeID = 4 AND Leverage = 1)` (real futures, non-leveraged) OR `SettlementTypeID = 5` (CMT).
- Compare to GetPositionsForFeeBulkGeneral: only `FRP.IsRealPosition = 0` (pure CFD, no futures/CMT).
- SettlementTypeID coalesce in #ValidPositions: `ISNULL(SettlementTypeID, cast(IsSettled as tinyint))` handles legacy rows where SettlementTypeID is NULL but IsSettled is populated.
- InstrumentTypeID eligibility: same (1,2,4,5,6,10).

### 2.3 Fee Amount Calculation via Trade.CalculatePositionOvernightFee

**What**: Fee amount is computed by calling the `Trade.CalculatePositionOvernightFee` function (scalar/TVF) rather than inline CASE logic.

**Columns/Parameters Involved**: `Trade.CalculatePositionOvernightFee`, `Trade.InstrumentToFeeConfigV2`

**Rules**:
- Rates sourced from `Trade.InstrumentToFeeConfigV2` (vs. `Trade.InstrumentToFeeConfig` in general procedure). V2 likely includes ASX-specific rate structures.
- `Trade.CalculatePositionOvernightFee` encapsulates the IsBuy/Leverage/SettlementTypeID/fee-type CASE logic, returning FeeInDollars.
- Fee type (overnight=1 vs EOW=2) still determined by Trade.ExchangeInstrumentFeeDefinition for instrument's exchange and current day of week.
- Same eligibility dates: overnight charged if LastOverNightClameDate IS NULL or < @TimeLimit; EOW if LastEOWClameDate IS NULL or < DATEADD(day,-6, GETUTCDATE()).
- Positions with FeeInDollars=0 are excluded from the charge loop.

### 2.4 Fee Type: Overnight vs End-of-Week

**What**: Fee=1 = daily overnight fee; Fee=2 = end-of-week fee (charged on one specific day per week for the ASX).

**Columns/Parameters Involved**: `Trade.ExchangeInstrumentFeeDefinition.Fee`, `LastOverNightClameDate`, `LastEOWClameDate`

**Rules**:
- Same logic as GetPositionsForFeeBulkGeneral but for ExchangeID=31.
- Fee value (1 or 2) is determined by Trade.ExchangeInstrumentFeeDefinition for the instrument's exchange and current day of week.
- ASX may have a different day for EOW fees than US markets.

### 2.5 Exclusions

**What**: Same exclusion categories as the general procedure, scoped to Sydney exchange positions.

**Rules**:
- Real positions (FRP.IsRealPosition=1) without SettlementTypeID=4 or 5 exclusion: excluded.
- Smart Portfolio / fund positions: excluded via Trade.ExcludeFeeByFundID.
- Parent positions of Smart Portfolio: excluded via ParentPositionID NOT IN ExcludeFeeByFundID.
- WeekendFeePrecentage = 0 customer: no fee charged.
- ExchangeID MUST be 31 (Sydney only; all other exchanges handled by GetPositionsForFeeBulkGeneral).

### 2.6 Parallel Sharding by CID Modulo

**What**: Same parallel sharding pattern as the general procedure.

**Columns/Parameters Involved**: `@Mod`, `@ModResults`

**Rules**:
- WHERE CID % @Mod = @ModResults.
- @Mod=1, @ModResults=0 = process all customers (single worker, default).
- Applied to TPOS0 CTE, #ValidPositions, #PositionsToChargeWithFee.

### 2.7 Fail-Safe for Closed Positions

**What**: Same fallback to History.Position_Active as the general procedure.

**Columns/Parameters Involved**: `@@ROWCOUNT`

**Rules**:
- UPDATE Trade.PositionTbl WHERE PositionID = @PositionID AND PartitionCol = @PositionID%50.
- If @@ROWCOUNT = 0: UPDATE History.Position_Active.
- Prevents fee loss when positions close during the fee run.

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
| PositionID | Trade.PositionTbl | READER + WRITER | Reads eligible Sydney positions, updates EndOfWeekFee and fee claim dates |
| PositionID | History.Position_Active | WRITER (fallback) | Updates EndOfWeekFee for positions closed during the fee run |
| PositionID | Trade.PositionTreeInfo | JOIN | Partition-aligned join for PTI.TreeID |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange ID (filter to 31) and InstrumentType lookup |
| InstrumentID | Trade.InstrumentToFeeConfigV2 | JOIN | Per-instrument fee rates for ASX (V2 config table) |
| InstrumentID | Trade.ExchangeInstrumentFeeDefinition | JOIN (UNPIVOT) | Day-of-week fee type (1=overnight, 2=EOW) per exchange/instrument |
| IsSettled, InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Identifies real stock positions; used in eligibility with SettlementTypeID override |
| InstrumentID | Trade.CalculatePositionOvernightFee | Function call | Calculates fee amount per position (encapsulates IsBuy/Leverage/fee-type logic) |
| CID | Customer.Customer | JOIN | WeekendFeePrecentage and Credit for fee calculation |
| MirrorID | Trade.Mirror | LEFT JOIN | Mirror's Amount (MirrorCredit) and IsActive flag |
| CID | Trade.ExcludeFeeByFundID | Anti-join | Smart Portfolio / fund positions excluded |
| InstrumentTypeID | Trade.GetInstrumentTypeIDsForCFDFee | Function | Gets instrument type IDs eligible for CFD fee |
| CID | dbo.SYN_Settings_DictionaryCountryFeeType | Lookup | Country-specific fee type rules |
| CID, @PositionID | Customer.SetBalanceClameFee | EXEC callee | Balance adjustment |
| Various | dbo.FeeQueueInMem | INSERT | Notification queue |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fee collection scheduler | @Mod, @ModResults | External call | Scheduled job that runs fee collection daily for Australian exchange positions |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForFeeBulkGeneral_Aus (procedure, WRITER)
+-- Trade.PositionTbl (table) [read + write]
+-- Trade.PositionTreeInfo (table) [read]
+-- History.Position_Active (table) [write, fallback]
+-- Trade.InstrumentMetaData (table)
+-- Trade.InstrumentToFeeConfigV2 (table) [Aus-specific V2 config]
+-- Trade.ExchangeInstrumentFeeDefinition (table)
+-- Trade.FnIsRealPosition (function)
+-- Trade.CalculatePositionOvernightFee (function) [Aus-specific fee calc]
+-- Trade.GetInstrumentTypeIDsForCFDFee (function)
+-- Trade.ConvertTimeLocalToUTC (function)
+-- Customer.Customer (table)
+-- Customer.SetBalanceClameFee (procedure)
+-- Trade.Mirror (table)
+-- Trade.ExcludeFeeByFundID (table/view)
+-- dbo.SYN_Settings_DictionaryCountryFeeType (synonym/table)
+-- dbo.FeeQueueInMem (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | READER: identifies eligible Sydney positions; WRITER: updates EndOfWeekFee and claim dates |
| Trade.PositionTreeInfo | Table | JOIN for partition-aligned tree linkage |
| History.Position_Active | Table | WRITER fallback for positions closed during fee run |
| Trade.InstrumentMetaData | Table | Exchange ID (filter to ExchangeID=31) and InstrumentType lookup |
| Trade.InstrumentToFeeConfigV2 | Table | Per-instrument fee rates for ASX (V2 table used instead of InstrumentToFeeConfig) |
| Trade.ExchangeInstrumentFeeDefinition | Table | Day-of-week fee type (overnight vs EOW) per exchange/instrument |
| Trade.FnIsRealPosition | Function | CROSS APPLY to classify position settlement; used with SettlementTypeID for broader eligibility |
| Trade.CalculatePositionOvernightFee | Function | Calculates fee amount per position (encapsulates fee direction/leverage/type logic) |
| Trade.GetInstrumentTypeIDsForCFDFee | Function | Returns eligible InstrumentTypeIDs (1,2,4,5,6,10) |
| Trade.ConvertTimeLocalToUTC | Function | Converts AUS Eastern 17:00 to UTC |
| Customer.Customer | Table | WeekendFeePrecentage and Credit |
| Customer.SetBalanceClameFee | Procedure | Applies fee to customer balance |
| Trade.Mirror | Table | Mirror credit and active status |
| Trade.ExcludeFeeByFundID | Table/View | Smart Portfolio CID exclusion list |
| dbo.SYN_Settings_DictionaryCountryFeeType | Table | Country-specific fee type rules |
| dbo.FeeQueueInMem | Table | In-memory notification queue |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee collection scheduler | External job | Calls this with @Mod/@ModResults parameters for parallel execution on Australian exchange positions |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp tables use custom indexes similar to GetPositionsForFeeBulkGeneral).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Optimization | Fresh execution plan each run due to varying @Mod/@ModResults and data volume |
| Sydney exchange only | Business rule | ExchangeID = 31 (only Sydney/ASX; all other exchanges handled by GetPositionsForFeeBulkGeneral) |
| Broader settlement eligibility | Business rule | CFD OR (SettlementTypeID=4 AND Leverage=1) OR SettlementTypeID=5 - includes ASX real-futures and CMT |
| AUS Eastern timezone | Business rule | 'AUS Eastern Standard Time' (vs. 'Eastern Standard TIME' in general procedure) |
| WeekendFeePrecentage > 0 | Business rule | Customers with 0% fee rate are skipped |
| @DictionaryCountryFeeType_RowsCount validation | Guard | Raises error if SYN_Settings_DictionaryCountryFeeType returns 0 rows (configuration error) |
| Per-position transaction | Consistency | Each position fee application is in its own BEGIN TRAN/COMMIT TRAN with ROLLBACK on failure |
| ISNULL(SettlementTypeID, cast(IsSettled as tinyint)) | Data quality | Handles legacy rows where SettlementTypeID is NULL but IsSettled is populated |

---

## 8. Sample Queries

### 8.1 Run Aus fee collection for all customers (single worker)

```sql
EXEC Trade.GetPositionsForFeeBulkGeneral_Aus @Mod = 1, @ModResults = 0;
```

### 8.2 Run Aus fee collection as worker 1 of 4 (parallel)

```sql
EXEC Trade.GetPositionsForFeeBulkGeneral_Aus @Mod = 4, @ModResults = 0;
-- Worker 2: @ModResults = 1, Worker 3: @ModResults = 2, Worker 4: @ModResults = 3
```

### 8.3 Preview eligible Sydney positions for fee collection today (read-only check)

```sql
DECLARE @TimeLimit DATETIME = Trade.ConvertTimeLocalToUTC('AUS Eastern Standard Time', '17:00');
IF @TimeLimit > GETUTCDATE() SET @TimeLimit = DATEADD(day,-1,@TimeLimit);

SELECT TOP 100 TP.PositionID, TP.CID, TP.IsBuy, TP.Leverage, TP.IsSettled, TP.SettlementTypeID, TP.AmountInUnitsDecimal
FROM Trade.PositionTbl TP WITH (NOLOCK)
INNER JOIN Trade.InstrumentMetaData IMD WITH (NOLOCK) ON TP.InstrumentID = IMD.InstrumentID
CROSS APPLY Trade.FnIsRealPosition(TP.IsSettled, TP.InstrumentID) FRP
WHERE TP.StatusID = 1
  AND TP.Occurred < @TimeLimit
  AND IMD.ExchangeID = 31  -- Sydney ONLY
  AND (FRP.IsRealPosition = 0 OR (TP.SettlementTypeID = 4 AND TP.Leverage = 1) OR TP.SettlementTypeID = 5);
```

### 8.4 Compare: Aus vs General fee config tables

```sql
-- Aus uses InstrumentToFeeConfigV2, General uses InstrumentToFeeConfig
-- Check rates for a Sydney instrument in both
SELECT 'V1' AS ConfigVersion, * FROM Trade.InstrumentToFeeConfig WHERE InstrumentID = 1234
UNION ALL
SELECT 'V2' AS ConfigVersion, * FROM Trade.InstrumentToFeeConfigV2 WHERE InstrumentID = 1234;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForFeeBulkGeneral_Aus | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForFeeBulkGeneral_Aus.sql*
