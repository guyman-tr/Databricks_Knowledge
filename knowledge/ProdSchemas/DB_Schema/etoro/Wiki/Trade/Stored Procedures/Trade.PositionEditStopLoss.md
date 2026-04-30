# Trade.PositionEditStopLoss

> Core stop-loss edit executor that validates position modifiability, applies SL credit adjustments via Billing.AmountSubstract, updates PositionTbl, and propagates the new stop rate through Trade.UpdateTree. Returns SLManualVer/Timestamp for optimistic concurrency.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @PositionID BIGINT |
| **Partition** | PositionCol = @PositionID % 50 |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.PositionEditStopLoss is the transactional core of the stop-loss editing workflow. When a customer (or system) modifies the stop loss level on an open position, this SP performs all the durable actions: validates that the position can be modified, calls Trade.UpdateTree to apply the new stop rate to the position tree, updates the position's Amount field to reflect any credit adjustment, and charges/credits the billing system via Billing.AmountSubstract.

The SP returns two OUTPUT parameters (@SLManualVer, @SLManualVerTimestamp) that form an optimistic concurrency token. The caller can use these to detect concurrent SL modifications between the time this SP ran and when a subsequent operation (e.g., PostEditStopLossPosition) is invoked.

**Key validation chain**:
1. Read MirrorID, ParentPositionID, TreeID, CID, CurrencyID, Amount from Trade.PositionTbl (StatusID=1, partition-aware)
2. Block user-initiated edits on mirrored positions (@ParentPositionID > 0 AND @MirrorID > 0 AND @IsInitiatedByUser != 0) -> error 60084
3. Block if position not found (MirrorID IS NULL) -> error 60115
4. Credit sufficiency check (if @Amount != 0 and user-initiated or standalone): Customer.Credit - @Credit >= 0 -> error 60054
5. Validation of amount consistency via Trade.PositionEditStopLoss_Validation
6. UpdateTree -> PositionTbl update -> Billing.AmountSubstract

The @Amount parameter is passed in CENTS (integer) and converted to dollars: @Credit = CAST(@Amount AS MONEY)/100.

---

## 2. Business Logic

### 2.1 Position State Read (Pre-Validation)

**What**: Reads position attributes needed for all subsequent validation and operations.

**Rules**:
- SELECT MirrorID, ParentPositionID, TreeID, CID, CurrencyID, Amount=@CurrentDBAmount FROM Trade.PositionTbl
- WHERE PositionID=@PositionID AND @PositionID%50=PartitionCol AND StatusID=1 (open only)
- If no row found: @MirrorID remains NULL -> error 60115 path

### 2.2 Mirror Modification Guard

**What**: Blocks user modifications to mirrored (copied) positions.

**Rules**:
- IF @ParentPositionID > 0 AND @MirrorID > 0 AND @IsInitiatedByUser <> 0
- RAISERROR(60084, 16, 1) -> "mirrored position cannot be modified by user"
- System-initiated edits (@IsInitiatedByUser=0) bypass this check - allows mirror system to adjust SL programmatically
- @IsInitiatedByUser default = 1

### 2.3 Credit Sufficiency Check

**What**: Ensures the customer has sufficient credit for the SL adjustment margin.

**Rules**:
- Only runs when @Amount != 0 (no-credit SL moves skip this)
- Only runs when @IsInitiatedByUser=1 OR @MirrorID=0 (user-initiated or standalone position)
- IF NOT EXISTS (Trade.Position JOIN Customer.Customer WHERE PositionID=@PositionID AND (@Credit < 0 OR Credit - @Credit >= 0))
- @Credit < 0 = credit is returned (SL moving to reduce margin required) - always allowed
- @Credit >= 0: customer must have Credit - @Credit >= 0 (sufficient balance)
- RAISERROR(60054, 16, 1) on failure -> "not enough money"

### 2.4 Amount Consistency Validation (Trade.PositionEditStopLoss_Validation)

**What**: Delegates amount consistency check to Trade.PositionEditStopLoss_Validation before applying changes.

**Rules**:
- @SLManualVerTimestamp = GETUTCDATE() (set before validation - used as the timestamp token)
- EXEC Trade.PositionEditStopLoss_Validation @PositionID, @CurrentAmount
- PositionEditStopLoss_Validation compares @CurrentAmount vs Trade.PositionTbl.Amount with XLOCK+ROWLOCK
- On amount mismatch: RAISERROR(60126) propagates up, caught by inner TRY, rethrowing with THROW
- Ensures no partial close occurred between client snapshot and SL edit execution

### 2.5 Tree Update (Trade.UpdateTree)

**What**: Propagates the new stop rate through the position tree structure.

**Rules**:
- EXEC Trade.UpdateTree @TreeID=@TreeID, @StopRate=@StopRate, @FromEditProd=1, @Credit=@Credit, @SessionID=@SessionID, @LastOpPriceRate, @LastOpPriceRateID, @LastOpConversionRate, @LastOpConversionRateID, @SLManualVerTimestamp, @IsManualOperation=1, @NextThresHold, @SLManualVer OUTPUT, @ClientRequestGuid, @IsNoStopLoss
- @SLManualVer OUTPUT is populated by UpdateTree and returned to caller
- @IsNoStopLoss BIT: when 1 (passed through from caller), removes the stop loss entirely (sets StopRate to NULL/0)

### 2.6 PositionTbl Amount Update

**What**: Applies the credit delta to the position's stored amount.

**Rules**:
- UPDATE Trade.PositionTbl SET Amount = Amount + @Credit, LastOpPriceRate, LastOpPriceRateID, LastOpConversionRate, LastOpConversionRateID WHERE PositionID=@PositionID AND @PositionID%50=PartitionCol AND StatusID=1
- @rc = @@ROWCOUNT (checked after)
- If @Amount != 0 AND @rc=1: proceed to Billing.AmountSubstract

### 2.7 Billing Charge (Billing.AmountSubstract)

**What**: Records the SL margin adjustment in the billing system.

**Rules**:
- Only called when @Amount != 0 AND @rc=1
- OperationTypeID = 13 (edit stop loss)
- @Amount passed in CENTS (integer) to billing
- @CheckResult OUTPUT: billing validation result
- @MirrorID, @IsInitiatedByUser passed through
- Description = 'edit stop loss by customer'
- If Billing.AmountSubstract returns non-zero: RAISERROR(@Answer, 16, 6)
- All steps within BEGIN TRANSACTION / COMMIT TRANSACTION

### 2.8 Error Handling

**Rules**:
- Inner TRY/CATCH (within the outer transaction): on CATCH: IF @@TRANCOUNT=1 ROLLBACK; IF @@TRANCOUNT>1 COMMIT; THROW
- Outer TRY/CATCH: builds @ErrOut with Step, ERROR_NUMBER, ERROR_LINE, ERROR_MESSAGE; ROLLBACK (or COMMIT if nested); RAISERROR(@ErrOut, 16, 1)
- @Step variable tracks which operation was executing when the error occurred (0=start, 70=billing, 80=post-billing)

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @PositionID | BIGINT | NO | - | CODE-BACKED | The position to edit. Used for partition lookup: PartitionCol = @PositionID%50. |
| 2 | @StopRate | dtPrice | NO | - | CODE-BACKED | The new stop loss rate to apply. Passed to Trade.UpdateTree. |
| 3 | @Amount | INTEGER | NO | - | CODE-BACKED | SL margin adjustment in CENTS (integer). Converted to dollars: @Credit = @Amount/100. Positive = additional margin required; negative = margin returned. 0 = rate change only, no credit adjustment. |
| 4 | @NetProfit | MONEY | NO | 0 | CODE-BACKED | Net profit in cents. Declared but not currently used in the implementation body. Retained for API compatibility. |
| 5 | @XMLResult | XML | YES | NULL | CODE-BACKED | OUTPUT. Not populated in current implementation. Reserved for future structured result return. |
| 6 | @CheckResult | INTEGER | YES | NULL | CODE-BACKED | OUTPUT. Set to 0 at start; populated by Billing.AmountSubstract as billing validation result. |
| 7 | @LastOpPriceRate | dtPrice | YES | NULL | CODE-BACKED | Last operation price rate. Passed to UpdateTree and stored in PositionTbl. |
| 8 | @LastOpPriceRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID for @LastOpPriceRate. |
| 9 | @LastOpConversionRate | dtPrice | YES | NULL | CODE-BACKED | Conversion rate at time of SL edit. |
| 10 | @LastOpConversionRateID | BIGINT | YES | NULL | CODE-BACKED | Rate ID for @LastOpConversionRate. |
| 11 | @IsInitiatedByUser | INT | NO | 1 | CODE-BACKED | 1=user-initiated (blocks mirrored position edits, enforces credit check). 0=system-initiated (mirror system, bypasses guards). |
| 12 | @SessionID | BIGINT | YES | NULL | CODE-BACKED | Session ID passed to Trade.UpdateTree for audit. |
| 13 | @NextThresHold | dtPrice | YES | NULL | CODE-BACKED | Next TSL threshold rate. Passed to Trade.UpdateTree for trailing stop loss adjustment. |
| 14 | @SLManualVer | INT | NO | - | CODE-BACKED | OUTPUT. Version counter returned by Trade.UpdateTree after SL update. Optimistic concurrency token for SL edits. |
| 15 | @SLManualVerTimestamp | DATETIME | NO | - | CODE-BACKED | OUTPUT. Set to GETUTCDATE() before validation. Timestamp half of the concurrency token pair. |
| 16 | @ClientRequestGuid | UNIQUEIDENTIFIER | YES | NULL | CODE-BACKED | Client-side request GUID for idempotency and audit. Passed to Trade.UpdateTree. |
| 17 | @CurrentAmount | MONEY | NO | - | CODE-BACKED | The position amount as known by the client. Passed to Trade.PositionEditStopLoss_Validation for consistency check. Error 60126 if mismatch. |
| 18 | @IsNoStopLoss | BIT | YES | NULL | CODE-BACKED | When 1: removes the stop loss entirely (no rate). Passed to Trade.UpdateTree. When NULL/0: normal SL rate update. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| SELECT | Trade.PositionTbl | DML read | Position state read (MirrorID, ParentPositionID, TreeID, CID, CurrencyID) |
| UPDATE | Trade.PositionTbl | DML write | Applies @Credit to Amount; updates LastOpPriceRate/Rate IDs |
| IF NOT EXISTS | Trade.Position | DML read | Credit sufficiency check (NOLOCK) |
| IF NOT EXISTS | Customer.Customer | DML read | Credit balance check (NOLOCK) |
| EXEC | Trade.PositionEditStopLoss_Validation | Procedure call | Amount consistency validation with XLOCK (error 60126 on mismatch) |
| EXEC | Trade.UpdateTree | Procedure call | Propagates new @StopRate through position tree; returns @SLManualVer |
| EXEC | Billing.AmountSubstract | Procedure call | Records SL margin adjustment in billing system (OperationTypeID=13) |

### 5.2 Referenced By (other objects point to this)

Called by Trade.PositionEditStopLoss_Validation is a dependency of this SP. Post-execution, Trade.PostEditStopLossPosition records the change log.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.PositionEditStopLoss (procedure)
+-- Trade.PositionTbl (table) - position state read + Amount update
+-- Trade.Position (view/table) - credit check
+-- Customer.Customer (table) - credit balance
+-- Trade.PositionEditStopLoss_Validation (procedure) - amount consistency [#9 in batch]
+-- Trade.UpdateTree (procedure) - tree-wide SL rate propagation
+-- Billing.AmountSubstract (procedure) - billing charge/credit
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.PositionTbl | Table | SELECT MirrorID, ParentPositionID, TreeID, CID, CurrencyID (StatusID=1, partition-aware); UPDATE Amount + rate fields |
| Trade.Position | View/Table | NOLOCK credit sufficiency check (JOIN with Customer.Customer) |
| Customer.Customer | Table | NOLOCK credit balance read for sufficiency check |
| Trade.PositionEditStopLoss_Validation | Stored Procedure | XLOCK amount consistency validation before applying changes |
| Trade.UpdateTree | Stored Procedure | Propagates @StopRate tree-wide; returns @SLManualVer OUTPUT |
| Billing.AmountSubstract | Stored Procedure | Records SL margin credit/debit in billing (OperationTypeID=13, in CENTS) |

### 6.2 Objects That Depend On This

Trade.PostEditStopLossPosition (called after this SP to write the change log).

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

- @Amount is passed in CENTS (INTEGER); converted to dollars via @Credit = CAST(@Amount AS MONEY)/100
- Error codes: 60084=mirror modification blocked, 60115=position not found, 60054=insufficient credit, 60126=amount mismatch (from Validation SP)
- @Step tracking: 70=at billing call, 80=post-billing; used in outer CATCH for diagnostic RAISERROR
- Inner TRY/CATCH rethrowing pattern (THROW): preserves original error number and message through transaction handling
- The commented-out code at the end (SELECT @SLManualVer, @SLManualVerTimestamp FROM Trade.PositionTreeInfo) shows the original approach was to re-read from the table; now populated via UpdateTree OUTPUT
- @NetProfit declared and defaulted to 0 but never used in the body - API artifact for backward compatibility

---

## 8. Sample Queries

### 8.1 User-initiated SL rate edit with credit adjustment

```sql
DECLARE @SLManualVer INT, @SLManualVerTimestamp DATETIME, @CheckResult INT, @XMLResult XML;
EXEC Trade.PositionEditStopLoss
    @PositionID = 123456789,
    @StopRate = 1.1200,
    @Amount = 5000,         -- 50 USD in cents
    @NetProfit = 0,
    @IsInitiatedByUser = 1,
    @SessionID = 999,
    @SLManualVer = @SLManualVer OUTPUT,
    @SLManualVerTimestamp = @SLManualVerTimestamp OUTPUT,
    @CheckResult = @CheckResult OUTPUT,
    @CurrentAmount = 1000;
SELECT @SLManualVer AS ManualVer, @SLManualVerTimestamp AS ManualVerTimestamp;
```

### 8.2 Remove stop loss entirely

```sql
DECLARE @SLManualVer INT, @SLManualVerTimestamp DATETIME, @CheckResult INT;
EXEC Trade.PositionEditStopLoss
    @PositionID = 123456789,
    @StopRate = 0,
    @Amount = 0,
    @IsNoStopLoss = 1,
    @SLManualVer = @SLManualVer OUTPUT,
    @SLManualVerTimestamp = @SLManualVerTimestamp OUTPUT,
    @CheckResult = @CheckResult OUTPUT,
    @CurrentAmount = 1000;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.2/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 10 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos searched / 0 files | Corrections: 0 applied*
*Object: Trade.PositionEditStopLoss | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.PositionEditStopLoss.sql*
