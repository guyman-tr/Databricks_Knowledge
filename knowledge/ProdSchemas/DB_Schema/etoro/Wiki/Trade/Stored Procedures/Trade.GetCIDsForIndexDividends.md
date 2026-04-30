# Trade.GetCIDsForIndexDividends

> Core dividend distribution engine that calculates and applies index/stock dividend payments to eligible customer positions, with transactional processing, Service Broker messaging, and failure reporting.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Processes dividend payments for eligible positions and sends payment messages via Service Broker |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure is the primary dividend distribution engine for the eToro platform. When a stock or index pays a dividend, this procedure identifies all eligible customer positions (both open and recently closed), calculates the dividend amount per position (factoring in buy/sell direction, tax rates, currency conversion, and unit count), applies the fee to each position's EndOfWeekFee column, and sends payment messages via Service Broker to the payment processing system.

The procedure exists because dividend distribution is a complex financial process with multiple business rules: different tax rates for buy vs sell positions, different treatment for real stock vs CFD positions, ex-date timing calculations adjusted for NYSE market close (17:00 + timezone offset), currency conversion for non-USD dividends, and idempotency through the PositionsProcessedForIndexDividnds tracking table. This cannot be a simple query - it requires cursor-like processing with per-customer transaction boundaries and Service Broker messaging.

Data flows through multiple stages: (1) Mark pending dividends as active (Status 0->1), (2) Calculate eligible positions by joining Trade.PositionTbl + History.Position with Trade.IndexDividends + currency conversion, (3) Process each position in a cursor loop applying Customer.SetBalanceClameFee and updating EndOfWeekFee, (4) Send Service Broker messages per customer group to the payment service, (5) Mark dividends as complete (Status 1->2), and (6) Send notification emails via Trade.IndexDividendsEmail.

---

## 2. Business Logic

### 2.1 Dividend Eligibility Rules

**What**: Determines which positions qualify for a dividend payment based on ex-date timing, position type, and open/close status.

**Columns/Parameters Involved**: `ExDate`, `OpenOccurred`, `CloseOccurred`, `IsSettled`, `PositionType`, `StatusID`

**Rules**:
- Real stock positions (IsSettled=1, PositionType=1): Must have been opened at least 2 days before ex-date + 17:00 NYSE close
- CFD positions (IsSettled=0, PositionType=0): Must have been opened before ex-date + 17:00 NYSE close (no 2-day settlement delay)
- Recently closed positions are eligible if they closed AFTER the ex-date + 17:00 NYSE close
- All open positions (StatusID=1) with matching instrument are eligible if open timing criteria met
- Time adjustment uses Maintenance.Feature ID 44 (GMT to NY timezone offset)

### 2.2 Dividend Calculation Formula

**What**: Calculates the dollar fee amount per position based on direction, tax, units, currency, and dividend value.

**Columns/Parameters Involved**: `IsBuy`, `BuyTax`, `SellTax`, `AmountInUnitsDecimal`, `DividendValueInCurrency`, `ShouldConvert`, `IsReciprocal`, `Bid`

**Rules**:
- Buy positions: `(1 - BuyTax) * Units * DividendValue * CurrencyConversion * -1`
- Sell positions: `(-1) * (1 + SellTax) * Units * DividendValue * CurrencyConversion * -1`
- The final `* -1` converts the result to a fee (negative = deduction for sells, positive = credit for buys)
- Currency conversion: 1 if no conversion needed, `1/Bid` if reciprocal, `Bid` otherwise (from Trade.CurrencyPrice via GetMoneyConversionsView)
- Result is ROUNDED to 2 decimal places and CAST to MONEY

### 2.3 Customer-Level Transaction Boundaries

**What**: Processes positions in customer groups with per-customer transaction boundaries and Service Broker messaging.

**Columns/Parameters Involved**: `CID`, `MirrorID`, `InstrumentID`

**Rules**:
- Positions are processed in ORDER BY CID, MirrorID, PositionID, InstrumentID
- Transaction COMMIT occurs when CID or MirrorID or InstrumentID changes (different customer/mirror/instrument group)
- At each group boundary, a Service Broker message is sent to svcPayment with format: `CID;14;SumOfFee;0;MirrorID;IsActive;3;InstrumentID`
  - CreditTypeID = 14 (dividend)
  - FeeType = 3 (DividendFee)
- Failed positions are retried with TryCount tracking

### 2.4 Idempotency via Processed Tracking

**What**: Prevents duplicate dividend processing using the PositionsProcessedForIndexDividnds table.

**Columns/Parameters Involved**: `Trade.PositionsProcessedForIndexDividnds`, `PositionID`, `DividendID`

**Rules**:
- Before processing: DELETE from #CIDsToCharge any positions already in PositionsProcessedForIndexDividnds
- After processing each position: INSERT into PositionsProcessedForIndexDividnds
- If re-run, already-processed positions are automatically skipped

### 2.5 Fee Application to Position Records

**What**: Updates the EndOfWeekFee column on positions to reflect the dividend amount.

**Columns/Parameters Involved**: `EndOfWeekFee`, `PositionID`, `StatusID`

**Rules**:
- Open positions (IsOpen=1): UPDATE Trade.PositionTbl SET EndOfWeekFee += FeeInDollars
- If position closed between calculation and update: falls through to the closed-position path
- Closed positions (IsOpen=0): First tries Trade.PositionTbl (StatusID=2), then falls back to History.Position_Active
- Uses PartitionCol = PositionID % 50 for partition alignment on PositionTbl updates

### 2.6 Failure Handling and Reporting

**What**: Tracks failed positions and sends email notification if any positions could not be processed.

**Columns/Parameters Involved**: `TryCount`, `@FailedPosition`

**Rules**:
- On exception: TryCount is decremented (set to -1) and the position is skipped
- After processing loop: if @FailedPosition > 0, RAISERROR with failure count
- Positions with TryCount=-1 are reported via HTML email to tradingbackend@etoro.com and DBA@etoro.com
- Email includes CID, PositionID, and FeeInDollars for each failed position

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

This procedure has no input parameters. Key internal elements:

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimeDiff | SMALLINT | NO | - | CODE-BACKED | GMT-to-NYSE timezone offset read from Maintenance.Feature ID 44. Used to calculate ex-date cutoff times at 17:00 NY time. |
| 2 | @PositionID | BIGINT | NO | - | CODE-BACKED | Current position being processed in the cursor loop. |
| 3 | @CID | INT | NO | - | CODE-BACKED | Customer ID of the current position. Group boundary tracking. |
| 4 | @MirrorID | INT | NO | - | CODE-BACKED | Mirror ID of the current position. Group boundary tracking. |
| 5 | @FeeInDollars | MONEY | NO | - | CODE-BACKED | Calculated dividend amount for the current position in USD. Negative = fee, positive = credit. |
| 6 | @ParentPositionID | BIGINT | NO | - | CODE-BACKED | Parent position for mirror/copy positions. Passed to SetBalanceClameFee. |
| 7 | @DividendID | INT | NO | - | CODE-BACKED | FK to Trade.IndexDividends. The dividend being processed. |
| 8 | @IsOpen | INT | NO | - | CODE-BACKED | Whether the position is open (1) or closed (0). Determines which table to update. |
| 9 | @IsActive | INT | NO | - | CODE-BACKED | Whether the associated mirror is active. Included in Service Broker message. |
| 10 | @InstrumentID | INT | NO | - | CODE-BACKED | Instrument of current position. Group boundary tracking. |
| 11 | @SumOfFee | MONEY | NO | - | CODE-BACKED | Running total of dividend fees per customer/mirror/instrument group. Sent in Service Broker message. |
| 12 | @FailedPosition | INT | NO | 0 | CODE-BACKED | Counter for positions that failed processing. Used for error reporting. |
| 13 | @Msg | VARCHAR(300) | NO | - | CODE-BACKED | Service Broker message payload: CID;14;SumOfFee;0;MirrorID;IsActive;3;InstrumentID |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (body) | Maintenance.Feature | SELECT FROM | Reads timezone offset (FeatureID=44) |
| (body) | Trade.IndexDividends | UPDATE/SELECT | Dividend records - status lifecycle (0->1->2) |
| (body) | Trade.PositionTbl | SELECT/UPDATE | Open and recently-closed positions - reads for eligibility, updates EndOfWeekFee |
| (body) | History.Position | SELECT FROM | Closed positions for dividend eligibility |
| (body) | Trade.GetMoneyConversionsView | INNER JOIN | Currency conversion mappings |
| (body) | Trade.CurrencyPrice | INNER JOIN | Current currency bid prices for conversion |
| (body) | Trade.Mirror | LEFT JOIN | Mirror activity status for copied positions |
| (body) | Trade.PositionsProcessedForIndexDividnds | SELECT/INSERT/DELETE | Idempotency tracking - prevents duplicate processing |
| (body) | History.Position_Active | UPDATE | Fallback update target for closed positions |
| (body) | Customer.SetBalanceClameFee | EXEC | Applies the dividend fee/credit to customer balance |
| (body) | Trade.IndexDividendsEmail | EXEC | Sends dividend notification emails |
| (body) | svcPayment (Service Broker) | SEND ON CONVERSATION | Payment processing via Service Broker messaging |
| (body) | msdb.dbo.sp_send_dbmail | EXEC | Sends failure report emails for unprocessed positions |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| SQL Agent Job | Scheduled | Job execution | Runs as a scheduled job for dividend processing |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetCIDsForIndexDividends (procedure)
+-- Maintenance.Feature (table)
+-- Trade.IndexDividends (table)
+-- Trade.PositionTbl (table)
+-- History.Position (view)
+-- Trade.GetMoneyConversionsView (view)
+-- Trade.CurrencyPrice (table)
+-- Trade.Mirror (table)
+-- Trade.PositionsProcessedForIndexDividnds (table)
+-- History.Position_Active (table)
+-- Customer.SetBalanceClameFee (procedure)
+-- Trade.IndexDividendsEmail (procedure)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Maintenance.Feature | Table | SELECT - timezone offset |
| Trade.IndexDividends | Table | SELECT/UPDATE - dividend data and status management |
| Trade.PositionTbl | Table | SELECT/UPDATE - open positions and fee updates |
| History.Position | View | SELECT - closed positions for eligibility |
| Trade.GetMoneyConversionsView | View | INNER JOIN - currency conversion rules |
| Trade.CurrencyPrice | Table | INNER JOIN - currency bid prices |
| Trade.Mirror | Table | LEFT JOIN - mirror activity status |
| Trade.PositionsProcessedForIndexDividnds | Table | SELECT/INSERT/DELETE - idempotency tracking |
| History.Position_Active | Table | UPDATE - fee update fallback for closed positions |
| Customer.SetBalanceClameFee | Procedure | EXEC - applies fee to customer balance |
| Trade.IndexDividendsEmail | Procedure | EXEC - sends notification emails |

### 6.2 Objects That Depend On This

No dependents found in SSDT. Called by SQL Agent scheduled job.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

Note: This is a WRITER procedure despite the "Get" prefix. It modifies:
- Trade.IndexDividends (Status updates: 0->1->2)
- Trade.PositionTbl (EndOfWeekFee updates)
- History.Position_Active (EndOfWeekFee updates)
- Trade.PositionsProcessedForIndexDividnds (INSERT tracking records)
- Trade.ExposureIDs (via Service Broker side effects)
- Customer balance (via SetBalanceClameFee)

Uses temp table #CIDsToCharge with clustered and nonclustered indexes for processing performance.

---

## 8. Sample Queries

### 8.1 Execute the dividend processing (production use only)
```sql
-- WARNING: This modifies data. Only run via scheduled job or with DBA supervision.
EXEC Trade.GetCIDsForIndexDividends;
```

### 8.2 Check pending dividends
```sql
SELECT  DividendID, InstrumentID, DividendValueInCurrency, PaymentDate, Status, BuyTax, SellTax, PositionType
FROM    Trade.IndexDividends WITH (NOLOCK)
WHERE   Status = 0
ORDER BY PaymentDate;
```

### 8.3 Check already-processed positions for a dividend
```sql
SELECT  pp.DividendID, pp.PositionID, id.InstrumentID, id.DividendValueInCurrency
FROM    Trade.PositionsProcessedForIndexDividnds pp WITH (NOLOCK)
        INNER JOIN Trade.IndexDividends id WITH (NOLOCK) ON pp.DividendID = id.DividendID
WHERE   id.DividendID = 12345
ORDER BY pp.PositionID;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: 2026-03-16 | Quality: 8.8/10 (Elements: 10.0/10, Logic: 10.0/10, Relationships: 8.0/10, Sources: 4.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetCIDsForIndexDividends | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetCIDsForIndexDividends.sql*
