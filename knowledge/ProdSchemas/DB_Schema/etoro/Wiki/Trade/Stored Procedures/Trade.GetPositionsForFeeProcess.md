# Trade.GetPositionsForFeeProcess

> Fee calculation coordinator for non-Sydney CFD/futures positions: identifies eligible positions, computes overnight/EOW fees via Trade.CalculatePositionOvernightFee, populates Trade.SYN_FeeNightProcess with StatusID=0 pending records, and delegates to Trade.SYN_ExecuteAllFeeJobs for distributed fee application. Uses a dispatch pattern instead of the direct WHILE-loop used by GetPositionsForFeeBulkGeneral.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | (no parameters) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is an alternative fee calculation entry point that uses a **dispatch/job pattern** instead of the direct per-row WHILE loop of `Trade.GetPositionsForFeeBulkGeneral`. Rather than applying fees directly to positions, it populates a synchronized queue table (`Trade.SYN_FeeNightProcess`) with pending fee records (StatusID=0), then triggers `Trade.SYN_ExecuteAllFeeJobs` to distribute and execute the fee applications across worker nodes. It covers the same non-Sydney exchange scope as GetPositionsForFeeBulkGeneral but uses `Trade.InstrumentToFeeConfigV2` and `Trade.CalculatePositionOvernightFee` (like the Aus variant), and also includes real-futures (SettlementTypeID=4) and CMT (SettlementTypeID=5) positions.

The procedure is a "major change" vs. the original design (per inline comment). The SYN (synchronized) table pattern enables the fee engine to be distributed: the primary node calculates which positions owe fees and how much, then dispatches the actual balance deductions to parallel worker jobs via SYN_ExecuteAllFeeJobs. This separation of "who owes what" from "apply the deduction" allows the fee application workload to be parallelized without CID-modulo sharding at the query level.

Data flows: (1) Build eligible position set (TPOS0 CTE: same 3-union pattern as GetPositionsForFeeBulkGeneral but also reads History.Position_Active for partially-closed branch). (2) Join to ExchangeInstrumentFeeDefinition to get fee type. (3) Call Trade.CalculatePositionOvernightFee per position. (4) Exclude Smart Portfolio positions. (5) Truncate SYN_FeeNightProcess via Trade.SYN_TruncateFeeNightProcess. (6) INSERT eligible fees into Trade.SYN_FeeNightProcess with StatusID=0. (7) EXEC Trade.SYN_ExecuteAllFeeJobs to trigger worker dispatch.

---

## 2. Business Logic

### 2.1 Fee Collection Window (Eastern Standard Time)

**What**: Same New York 5pm fee window as GetPositionsForFeeBulkGeneral.

**Columns/Parameters Involved**: `@TimeLimit`, `@ClosingTimeLocal`, `@ExchangeIdToExclude`

**Rules**:
- @ExchangeIdToExclude = 31 (Sydney excluded; handled by GetPositionsForFeeBulkGeneral_Aus).
- @ClosingTimeLocal = '17:00' with 'Eastern Standard TIME' (New York).
- @TimeLimit = Trade.ConvertTimeLocalToUTC('Eastern Standard TIME', '17:00').
- If @TimeLimit > GETUTCDATE() (before 5pm EST): @TimeLimit = DATEADD(day,-1,@TimeLimit).

### 2.2 Three-Union Position Eligibility

**What**: Builds the candidate position set from three sources, including a separate History.Position_Active branch for partially-closed positions (vs. GetPositionsForFeeBulkGeneral which reads PositionTbl for StatusID=2).

**Columns/Parameters Involved**: `Trade.PositionTbl`, `History.Position_Active`, `FRP.IsRealPosition`, `SettlementTypeID`

**Rules**:
- Branch 1 (Trade.PositionTbl): StatusID=1, Occurred < @TimeLimit, ExchangeID != 31.
- Branch 2 (History.Position_Active): CloseOccurred >= @TimeLimit AND OpenOccurred < @TimeLimit, ExchangeID != 31. Uses CROSS APPLY to History.ActiveCreditView to derive LastEOWClameDate and LastOverNightClameDate from actual credit history (since History.Position_Active lacks these columns).
- Branch 3 (Trade.PositionTbl StatusID=2): StatusID=2, CloseOccurred >= @TimeLimit, Occurred < @TimeLimit, ExchangeID != 31.
- All branches: (FRP.IsRealPosition = 0) OR (SettlementTypeID=4 AND Leverage=1) OR SettlementTypeID=5.
- Sharding (@Mod/@ModResults) is commented out - this procedure does not support parallel sharding; it processes all customers in a single run.

### 2.3 Fee Type and Rate Resolution

**What**: Same fee type lookup via ExchangeInstrumentFeeDefinition UNPIVOT, same dense_rank to resolve instrument-level vs. exchange-level fee configs.

**Columns/Parameters Involved**: `Trade.ExchangeInstrumentFeeDefinition.Fee`, `Rnk`, `Trade.InstrumentToFeeConfigV2`

**Rules**:
- Fee=1 (overnight), Fee=2 (EOW): determined by ExchangeInstrumentFeeDefinition for today's day of week.
- InstrumentID=-999 in EIFD = exchange-level default; DENSE_RANK orders instrument-specific before exchange-level (InstrumentID DESC -> higher instrument ID ranked first).
- Only Rnk=1 and Fee > 0 rows advance to #ValidPositions.
- Rates sourced from Trade.InstrumentToFeeConfigV2 (V2 table, same as Aus variant, unlike GetPositionsForFeeBulkGeneral which uses InstrumentToFeeConfig).
- ISNULL(SettlementTypeID, cast(IsSettled as tinyint)) coalesce applied in #ValidPositions.

### 2.4 Fee Amount Calculation via Trade.CalculatePositionOvernightFee

**What**: Fee is computed by the Trade.CalculatePositionOvernightFee function, not inline CASE logic.

**Columns/Parameters Involved**: `Trade.CalculatePositionOvernightFee`, `WeekendFeePrecentage`

**Rules**:
- Parameters: IsBuy, Leverage, SettlementTypeID, Fee (type), all rate columns from InstrumentToFeeConfigV2, FeeCalculationTypeID, AmountInUnitsDecimal, InitForexRate, InitConversionRate, Amount, WeekendFeePrecentage, IsNonLeveragedBuyCFDFeeApplicable (country whitelist flag).
- ROUND(..., 2): fee rounded to 2 decimal places.
- IsNonLeveragedBuyCFDFeeApplicable: 1 if InstrumentTypeID is in #InstrimentTypesForCFDFee AND customer country is NOT in the NonLeveragedBuyCFD whitelist (#DictionaryCountryFeeType); else 0.
- FeeInDollars = 0 positions are filtered out in #PositionsToChargeWithFee.

### 2.5 Dispatch via SYN_FeeNightProcess

**What**: Instead of directly updating PositionTbl per row, eligible fees are enqueued into Trade.SYN_FeeNightProcess for distributed execution.

**Columns/Parameters Involved**: `Trade.SYN_FeeNightProcess`, `StatusID`, `Trade.SYN_TruncateFeeNightProcess`, `Trade.SYN_ExecuteAllFeeJobs`

**Rules**:
- Trade.SYN_TruncateFeeNightProcess is called first to clear any prior run's data.
- INSERT into Trade.SYN_FeeNightProcess: PositionID, CID, IsBuy, MirrorID, ParentPositionID, FeeInDollars, EndOfWeekFee, Amount, CustomerCredit, MirrorCredit, IsActive, Fee, StatusID=0.
- StatusID=0 = pending/not yet processed by worker jobs.
- CID%10 used as PartitionCol in the SYN table insert (different from PositionTbl's %50 partition).
- Trade.SYN_ExecuteAllFeeJobs triggers the worker dispatch - workers pick up StatusID=0 records and apply fees (balance deductions, PositionTbl updates, FeeQueueInMem inserts).

### 2.6 Smart Portfolio Exclusions

**What**: Same fund/Smart Portfolio exclusion as GetPositionsForFeeBulkGeneral, but uses Trade.Position view (not PositionTbl directly) for the exclusion list.

**Rules**:
- #excludePositionBySmartPortfolioCID: SELECT PositionID FROM Trade.Position WHERE CID IN (SELECT CID FROM Trade.ExcludeFeeByFundID).
- Final filter: CID NOT IN Trade.ExcludeFeeByFundID AND ParentPositionID NOT IN #excludePositionBySmartPortfolioCID.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure takes no parameters.

**Side Effects (writes, not output columns)**

| # | Target | Operation | Description |
|---|--------|-----------|-------------|
| 1 | Trade.SYN_FeeNightProcess | TRUNCATE (via SYN_TruncateFeeNightProcess) + INSERT | Cleared then populated with pending fee records (StatusID=0) for each eligible position |
| 2 | Trade.SYN_ExecuteAllFeeJobs | EXEC | Triggers worker job dispatch to apply the pending fees from SYN_FeeNightProcess |

**Downstream writes (via SYN_ExecuteAllFeeJobs workers):**

| # | Target | Operation | Description |
|---|--------|-----------|-------------|
| 3 | Trade.PositionTbl.EndOfWeekFee | UPDATE | Fee added to accumulated fees; LastOverNightClameDate or LastEOWClameDate updated |
| 4 | History.Position_Active.EndOfWeekFee | UPDATE (fallback) | For positions closed during processing |
| 5 | dbo.FeeQueueInMem | INSERT | Downstream notification records |
| 6 | Customer.SetBalanceClameFee | EXEC (via workers) | Balance deduction per position |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PositionID (branch 1+3) | Trade.PositionTbl | Primary source | Open and StatusID=2 positions eligible for fee |
| PositionID (branch 2) | History.Position_Active | Primary source | Partially closed positions (CloseOccurred >= @TimeLimit) |
| LastEOWClameDate/LastOverNightClameDate | History.ActiveCreditView | CROSS APPLY | Derives fee claim dates from credit history for History.Position_Active branch |
| InstrumentID | Trade.InstrumentMetaData | JOIN | Exchange ID and InstrumentType lookup |
| InstrumentID | Trade.ExchangeInstrumentFeeDefinition | UNPIVOT JOIN | Day-of-week fee type (1=overnight, 2=EOW) |
| IsSettled, InstrumentID | Trade.FnIsRealPosition | CROSS APPLY | Settlement type classification |
| InstrumentID | Trade.InstrumentToFeeConfigV2 | JOIN | Per-instrument fee rates (V2 table) |
| (function call) | Trade.CalculatePositionOvernightFee | Function | Computes FeeInDollars per position |
| InstrumentID | Trade.GetInstrument | JOIN | InstrumentTypeID lookup |
| CID | Customer.Customer | JOIN | WeekendFeePrecentage and Credit |
| MirrorID | Trade.Mirror | LEFT JOIN | Mirror credit and IsActive flag |
| CID | Trade.ExcludeFeeByFundID | Anti-join | Smart Portfolio exclusion |
| InstrumentTypeID | Trade.GetInstrumentTypeIDsForCFDFee | Function | Eligible InstrumentTypeIDs |
| CID | dbo.SYN_Settings_DictionaryCountryFeeType | Lookup | Country-specific fee type rules |
| - | Trade.SYN_TruncateFeeNightProcess | EXEC callee | Clears SYN_FeeNightProcess before insert |
| - | Trade.SYN_FeeNightProcess | INSERT | Fee dispatch queue (StatusID=0 pending records) |
| - | Trade.SYN_ExecuteAllFeeJobs | EXEC callee | Triggers worker dispatch for fee application |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Fee collection scheduler | (no parameters) | External call | Scheduled job that invokes this procedure as the fee calculation coordinator |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetPositionsForFeeProcess (procedure)
+-- Trade.PositionTbl (table) [branches 1 and 3]
+-- History.Position_Active (table) [branch 2]
+-- History.ActiveCreditView (view) [LastEOWClameDate/LastOverNightClameDate derivation for branch 2]
+-- Trade.PositionTreeInfo (table) [partition join for branch 1+3]
+-- Trade.InstrumentMetaData (table)
+-- Trade.FnIsRealPosition (function)
+-- Trade.ExchangeInstrumentFeeDefinition (table)
+-- Trade.InstrumentToFeeConfigV2 (table)
+-- Trade.CalculatePositionOvernightFee (function)
+-- Trade.GetInstrument (view/table)
+-- Customer.Customer (table)
+-- Trade.Mirror (table)
+-- Trade.ExcludeFeeByFundID (table/view)
+-- Trade.Position (view) [for Smart Portfolio exclusion list]
+-- Trade.GetInstrumentTypeIDsForCFDFee (function)
+-- dbo.SYN_Settings_DictionaryCountryFeeType (synonym/table)
+-- Trade.ConvertTimeLocalToUTC (function)
+-- Trade.SYN_TruncateFeeNightProcess (procedure)
+-- Trade.SYN_FeeNightProcess (synonym/table)
+-- Trade.SYN_ExecuteAllFeeJobs (procedure)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | Branches 1 and 3: open and StatusID=2 positions |
| History.Position_Active | Table | Branch 2: partially closed positions |
| History.ActiveCreditView | View | CROSS APPLY to derive LastEOWClameDate and LastOverNightClameDate for History.Position_Active rows |
| Trade.PositionTreeInfo | Table | Partition join (TreeID%50) for PositionTbl branches |
| Trade.InstrumentMetaData | Table | Exchange ID lookup and InstrumentTypeID |
| Trade.FnIsRealPosition | Function | Settlement classification for eligibility filter |
| Trade.ExchangeInstrumentFeeDefinition | Table | Day-of-week fee type (overnight vs EOW) |
| Trade.InstrumentToFeeConfigV2 | Table | Per-instrument fee rates (V2) |
| Trade.CalculatePositionOvernightFee | Function | Fee amount calculation |
| Trade.GetInstrument | View/Table | InstrumentTypeID lookup |
| Customer.Customer | Table | WeekendFeePrecentage and Credit |
| Trade.Mirror | Table | Mirror credit and IsActive |
| Trade.ExcludeFeeByFundID | Table/View | Smart Portfolio CID exclusion |
| Trade.Position | View | Smart Portfolio position exclusion list |
| Trade.GetInstrumentTypeIDsForCFDFee | Function | Eligible InstrumentTypeIDs |
| dbo.SYN_Settings_DictionaryCountryFeeType | Table | Country-specific fee type rules |
| Trade.ConvertTimeLocalToUTC | Function | Eastern 17:00 to UTC conversion |
| Trade.SYN_TruncateFeeNightProcess | Procedure | Clears SYN queue before populate |
| Trade.SYN_FeeNightProcess | Table (SYN) | Fee dispatch queue; receives pending fee records |
| Trade.SYN_ExecuteAllFeeJobs | Procedure | Triggers worker dispatch for fee application |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Fee collection scheduler | External job | Invokes this as the primary non-Aus fee coordinator |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure (temp tables: CLUSTERED INDEX on #step1 (InstrumentID), CLUSTERED INDEX on #TempValidPositions (Rnk), CLUSTERED INDEX on #ValidPositions (InstrumentID,CID,MirrorID), CLUSTERED INDEX on #PositionsToCharge (CID,FeeInDollars) + NONCLUSTERED (ParentPositionID), CLUSTERED INDEX on #excludePositionBySmartPortfolioCID (PositionID)).

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| No sharding support | Design | @Mod/@ModResults commented out; processes all customers in a single pass |
| Sydney excluded | Business rule | ExchangeID != 31 (handled by GetPositionsForFeeBulkGeneral_Aus) |
| Broader settlement eligibility | Business rule | CFD OR (SettlementTypeID=4 AND Leverage=1) OR SettlementTypeID=5 |
| V2 config table | Design | Uses InstrumentToFeeConfigV2 (vs InstrumentToFeeConfig in GetPositionsForFeeBulkGeneral) |
| SYN dispatch pattern | Architecture | Does NOT apply fees directly; populates SYN queue then delegates to SYN_ExecuteAllFeeJobs |
| OPTION(RECOMPILE, MAXDOP 4) | Performance | Used on #TempValidPositions query for plan freshness and parallelism control |
| @DictionaryCountryFeeType_RowsCount | Guard | Validates SYN_Settings_DictionaryCountryFeeType is populated (implicit - same pattern as bulk general) |

---

## 8. Sample Queries

### 8.1 Execute the fee process (no parameters)

```sql
EXEC Trade.GetPositionsForFeeProcess;
```

### 8.2 Preview what would be dispatched to SYN_FeeNightProcess

```sql
-- After running the procedure, check pending fee records
SELECT TOP 100 * FROM Trade.SYN_FeeNightProcess WHERE StatusID = 0;
```

### 8.3 Check fees for partially-closed positions (History.Position_Active branch)

```sql
DECLARE @TimeLimit DATETIME = Trade.ConvertTimeLocalToUTC('Eastern Standard TIME', '17:00');
IF @TimeLimit > GETUTCDATE() SET @TimeLimit = DATEADD(day,-1,@TimeLimit);

SELECT TOP 50 HPA.PositionID, HPA.CID, HPA.IsBuy, HPA.Leverage, HPA.CloseOccurred
FROM History.Position_Active HPA WITH (NOLOCK)
JOIN Trade.InstrumentMetaData IMD ON HPA.InstrumentID = IMD.InstrumentID
CROSS APPLY Trade.FnIsRealPosition(HPA.IsSettled, HPA.InstrumentID) FRP
WHERE HPA.CloseOccurred >= @TimeLimit
  AND HPA.OpenOccurred < @TimeLimit
  AND IMD.ExchangeID != 31
  AND (FRP.IsRealPosition = 0 OR (HPA.SettlementTypeID = 4 AND HPA.Leverage = 1) OR HPA.SettlementTypeID = 5);
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 8/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 14 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetPositionsForFeeProcess | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetPositionsForFeeProcess.sql*
