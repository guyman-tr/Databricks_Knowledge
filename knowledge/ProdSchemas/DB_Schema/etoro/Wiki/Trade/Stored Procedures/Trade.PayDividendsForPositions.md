# Trade.PayDividendsForPositions

> Processes dividend payments for a batch of positions belonging to a single customer/mirror - calling SetBalanceClameFee per position, updating EndOfWeekFee, recording the processed dividend, and queuing a MIMO post-operation notification.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @CID + @DividendID + @positionsTable (payment batch scope) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

When an index dividend event occurs, affected positions must receive a proportional payment. This procedure is the per-customer per-dividend execution unit: it receives a pre-calculated list of positions with their fee amounts (in `@positionsTable`) and applies the dividend payment to each one.

The procedure is idempotent at the position level: it checks `Trade.PositionsProcessedForIndexDividnds` before processing each position, skipping any that have already received this dividend. This allows safe retries without double-paying.

After paying all positions, the procedure queues a MIMO post-operation (ActionID=7) for the customer via `Internal.ActionsToExecute_MIMOOperations`. MIMO (Money In Money Out) is the downstream system that notifies users of balance changes. The result set returned at the end provides the caller with a summary: customer, instrument, mirror status, and total payment amount.

Data flow: For each position in @positionsTable -> check idempotency -> call Customer.SetBalanceClameFee -> update EndOfWeekFee on PositionTbl (or History.Position_Active if closed) -> insert to PositionsProcessedForIndexDividnds -> accumulate sum -> insert MIMO action -> COMMIT -> return summary result set.

---

## 2. Business Logic

### 2.1 Per-Position Idempotency Check

**What**: Prevents double-paying the same position for the same dividend event.

**Columns/Parameters Involved**: `Trade.PositionsProcessedForIndexDividnds.PositionID`, `Trade.PositionsProcessedForIndexDividnds.DividendID`

**Rules**:
- IF NOT EXISTS (SELECT 1 FROM Trade.PositionsProcessedForIndexDividnds WHERE PositionID=@PositionID AND DividendID=@DividendID)
- If already processed: skip (no payment, no update, no insert)
- This is position-level idempotency within the same dividend event

### 2.2 Balance Application via SetBalanceClameFee

**What**: Applies the dividend payment to the customer's balance.

**Columns/Parameters Involved**: `@FeeInDollars`, `@CID`, `@MirrorID`, `@ParentPositionID`, `@Description`

**Rules**:
- EXEC Customer.SetBalanceClameFee @PositionID, @CID, @MirrorID, @FeeInDollars, @ParentPositionID, @Description, @IsFromMirror OUTPUT, @CreditID OUTPUT
- @Description is hardcoded: 'Payment caused by dividend'
- @IsFromMirror OUTPUT indicates if this position is part of a mirror portfolio
- @CreditID OUTPUT is captured for use in the MIMO notification and the processed-dividends record

### 2.3 EndOfWeekFee Update (Live and Closed Positions)

**What**: Accumulates the dividend fee in the position's EndOfWeekFee column, handling both open and recently-closed positions.

**Columns/Parameters Involved**: `Trade.PositionTbl.EndOfWeekFee`, `History.Position_Active.EndOfWeekFee`, `@IsOpen`

**Rules**:
- IF @IsOpen=1: UPDATE Trade.PositionTbl SET EndOfWeekFee += @FeeInDollars WHERE PositionID=@PositionID AND PartitionCol=@PositionID%50
  - If @@ROWCOUNT=0 (position closed since calculation): set @IsOpen=0 and fall through
- IF @IsOpen=0: first try UPDATE Trade.PositionTbl WHERE StatusID=2 (closed but still in active table)
  - If still 0 rows: UPDATE History.Position_Active (fully archived position)
- Ensures the EndOfWeekFee accumulation covers the position regardless of its closure timing

### 2.4 MIMO Post-Operation Notification

**What**: Queues a downstream MIMO system notification for the customer after all position payments are processed.

**Columns/Parameters Involved**: `Internal.ActionsToExecute_MIMOOperations.ActionID`, `Internal.ActionsToExecute_MIMOOperations.Params`

**Rules**:
- Only if @@TRANCOUNT=1 (transaction still open - no errors occurred)
- XML Params: `<Root><CreditID Value="{@CreditID}"/><CreditTypeID Value="6"/><CID Value="{@CID}"/></Root>`
- ActionID=7 = PostOperation on MIMO system
- CurrentTry=0, Status=0, RetVal=0 (fresh queued action)
- @CreditID here is the LAST CreditID from the batch (used as the representative credit for notification)

### 2.5 Summary Result Set

**What**: Returns a summary row after completion for the caller to build notifications or logs.

**Columns/Parameters Involved**: `@PaymentFee`, `@FeeMirrorID`, `@IsActive`, `@CorporateActionTypeId`

**Rules**:
- @PaymentFee = 0 - @SumOfFee (negated: sum of fees paid out)
- @FeeMirrorID = IIF(@IsFromMirror=1, @MirrorID, 0)
- @CorporateActionTypeId = 0 (hard-coded; index dividends use type 0)
- Returns: CID, InstrumentID, FeeMirrorID, IsActive, PaymentFee, CorporateActionTypeId, CurrTime

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | NO | - | CODE-BACKED | Customer ID receiving the dividend payments. Used in SetBalanceClameFee calls and MIMO notification params. |
| 2 | @MirrorID | INT | NO | - | CODE-BACKED | Mirror portfolio ID (0 or NULL if direct customer position). Passed to SetBalanceClameFee; used to determine @FeeMirrorID in the result set. |
| 3 | @DividendID | INT | NO | - | CODE-BACKED | The dividend event ID. Used for idempotency check in Trade.PositionsProcessedForIndexDividnds (PositionID+DividendID uniqueness). |
| 4 | @InstrumentID | INT | NO | - | CODE-BACKED | The instrument for which the dividend is being paid. Returned in the summary result set. Not used for filtering positions (the @positionsTable already contains the filtered list). |
| 5 | @IsActive | BIT | NO | - | CODE-BACKED | Whether the customer's account/mirror is active. Returned in the summary result set for downstream notifications. |
| 6 | @positionsTable | Trade.PositionsForDividendPaymentTbl READONLY | NO | - | CODE-BACKED | TVP containing the positions to pay: PositionID, ParentPositionID, IsOpen, FeeInDollars (pre-calculated dividend amount), BuyTax, SellTax. Each row gets processed independently with idempotency check. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID/@MirrorID | Customer.SetBalanceClameFee | EXEC (CALL) | Applies dividend payment to customer balance per position |
| @PositionID | Trade.PositionTbl | UPDATE (WRITE) | Adds FeeInDollars to EndOfWeekFee for open positions |
| @PositionID | History.Position_Active | UPDATE (WRITE) | Fallback: updates EndOfWeekFee for closed/archived positions |
| @DividendID/@PositionID | Trade.PositionsProcessedForIndexDividnds | READ + INSERT | Idempotency: checks and records per-position dividend processing |
| Internal | Internal.ActionsToExecute_MIMOOperations | INSERT (WRITE) | Queues MIMO PostOperation (ActionID=7) for customer notification after all payments |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PayDividendsForPositions (procedure)
+-- Customer.SetBalanceClameFee (procedure) [EXEC - applies dividend fee to balance per position]
+-- Trade.PositionTbl (table) [UPDATE - EndOfWeekFee accumulation for open positions]
+-- History.Position_Active (table) [UPDATE - EndOfWeekFee for closed/archived positions]
+-- Trade.PositionsProcessedForIndexDividnds (table) [READ + INSERT - idempotency per position+dividend]
+-- Internal.ActionsToExecute_MIMOOperations (table) [INSERT - MIMO notification queue]
+-- Trade.PositionsForDividendPaymentTbl (UDT) [TVP input type]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceClameFee | Stored Procedure | Applies each position's dividend fee to the customer's balance; returns @IsFromMirror, @CreditID |
| Trade.PositionTbl | Table | Updated with EndOfWeekFee += FeeInDollars for live positions |
| History.Position_Active | Table | Fallback EndOfWeekFee update for positions closed before processing |
| Trade.PositionsProcessedForIndexDividnds | Table | Idempotency: skip already-processed position+dividend pairs; insert after processing |
| Internal.ActionsToExecute_MIMOOperations | Table | Receives MIMO PostOperation (ActionID=7) XML payload for customer notification |
| Trade.PositionsForDividendPaymentTbl | User-Defined Table Type | TVP type for @positionsTable input parameter |

### 6.2 Objects That Depend On This

Not analyzed in this phase.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WHILE loop with ROW_NUMBER() | Design pattern | Iterates positions by RuningID; fetches next row at start and after each commit |
| BEGIN TRAN at batch start | Transaction scope | Single transaction wraps all positions; ROLLBACK on any error loses all unpaid positions |
| ROLLBACK + RAISERROR on error | Error handling | CATCH block rolls back entire batch and re-raises with full error context (PositionID;ErrorNum;...) |
| @CorporateActionTypeId=0 | Design constant | Index dividends use CorporateActionTypeId=0 (distinct from airdrop/cash dividend types) |
| @Description='Payment caused by dividend' | Design constant | Fixed description string for all dividend SetBalanceClameFee calls |
| PartitionCol = @PositionID%50 | Partition hint | Required for Trade.PositionTbl updates to target the correct partition |

---

## 8. Sample Queries

### 8.1 Check which positions have been processed for a dividend
```sql
SELECT TOP 20
    ppid.PositionID,
    ppid.DividendID,
    ppid.CreditID,
    ppid.PaymentAmount,
    ppid.BuyTax,
    ppid.SellTax
FROM Trade.PositionsProcessedForIndexDividnds ppid WITH (NOLOCK)
WHERE ppid.DividendID = 12345
ORDER BY ppid.PositionID;
```

### 8.2 Check pending MIMO actions for a customer
```sql
SELECT TOP 10
    ID,
    ActionID,
    Params,
    Status,
    CurrentTry,
    RetVal
FROM Internal.ActionsToExecute_MIMOOperations WITH (NOLOCK)
WHERE Params LIKE '%<CID Value="111222"%'
ORDER BY ID DESC;
```

### 8.3 Verify EndOfWeekFee was updated for dividend positions
```sql
SELECT
    pt.PositionID,
    pt.CID,
    pt.EndOfWeekFee,
    ppid.PaymentAmount AS DividendAmount,
    ppid.DividendID
FROM Trade.PositionTbl pt WITH (NOLOCK)
JOIN Trade.PositionsProcessedForIndexDividnds ppid WITH (NOLOCK)
    ON ppid.PositionID = pt.PositionID
WHERE ppid.DividendID = 12345
  AND pt.CID = 111222;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/6 (1,5,8,9B,10,11)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed (SetBalanceClameFee) | App Code: 2 repos / 0 files | Corrections: 0 applied*
*Object: Trade.PayDividendsForPositions | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PayDividendsForPositions.sql*
