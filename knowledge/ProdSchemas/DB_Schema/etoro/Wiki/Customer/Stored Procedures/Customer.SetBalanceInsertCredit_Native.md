# Customer.SetBalanceInsertCredit_Native

> Natively compiled, memory-optimized stored procedure that inserts a single credit (balance transaction) record into History.ActiveCreditRecentMemoryBucket; serves as the low-level INSERT worker for all SetBalance* procedures.

| Property | Value |
|----------|-------|
| **Schema** | Customer |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @Identity OUTPUT (BIGINT) - the new CreditID assigned by identity |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Every financial transaction affecting a customer's balance - deposits, withdrawals, position open/close, bonuses, chargebacks, compensation, fees - must be logged as a credit record. `SetBalanceInsertCredit_Native` is the single, high-performance INSERT endpoint for these records. It writes directly to `History.ActiveCreditRecentMemoryBucket`, a memory-optimized (In-Memory OLTP) table designed for the extremely high write throughput required by real-time trading operations.

This procedure exists as the natively compiled "inner" worker called by all specialized `SetBalance*` orchestrators. It is never called directly by application code; instead, procedures like `Customer.SetBalanceDeposit`, `Customer.SetBalanceClosePosition`, `Customer.SetBalanceBonus`, and others funnel their resolved parameters into this single insertion point. The "Native" suffix signals its compilation mode: unlike interpreted T-SQL, this procedure is compiled to native machine code at creation time, eliminating interpreter overhead on the critical insert path.

Data flows in from 18+ caller procedures. Each caller computes the credit-type-specific fields (e.g., PositionID for position closes, DepositID for deposits, CampaignID for bonuses), then invokes this procedure to atomically insert the record and return the new CreditID via @Identity. The returned ID is used by callers to link back to this credit from application-layer notifications and service broker messages.

---

## 2. Business Logic

### 2.1 Retry Loop with SNAPSHOT Isolation

**What**: Ensures insertion reliability under high-concurrency conditions using SNAPSHOT isolation and up to 3 automatic retries.

**Columns/Parameters Involved**: `@Retry`, `@em` (internal), all input parameters

**Rules**:
- The procedure runs inside `BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')` - this is mandated by In-Memory OLTP natively compiled procedures.
- A WHILE loop retries up to 3 times on transient failures (caught via BEGIN CATCH).
- On success, `@Retry` is set to 4 to break the loop, and SCOPE_IDENTITY() is captured into @Identity.
- On catch, the error message is returned (SELECT ERROR_MESSAGE()) and @Retry is incremented.
- This pattern handles contention on the in-memory table without pessimistic locking.

```
@Retry = 1
WHILE @Retry <= 3
  TRY:
    INSERT into History.ActiveCreditRecentMemoryBucket
    @Retry = 4 (exit loop)
    @Identity = SCOPE_IDENTITY()
  CATCH:
    SELECT ERROR_MESSAGE()
    @Retry = @Retry + 1
```

### 2.2 Credit Type System

**What**: The CreditTypeID parameter determines which type of financial event this record represents.

**Columns/Parameters Involved**: `@CreditTypeID`

**Rules**:
- CreditTypeID is a TINYINT matching Dictionary.CreditType (1-33 values).
- This procedure accepts ANY CreditTypeID; business routing by type is handled upstream in Customer.SetBalance.
- High-frequency types in production: 1=Deposit, 9=Cashout request, 15=Cashout Fee.

```
CreditTypeID value map (Dictionary.CreditType):
  1  = Deposit                          18 = Account balance to mirror
  2  = Cashout                          19 = Mirror balance to account
  3  = Open Position                    20 = Register new mirror
  4  = Close Position                   21 = Unregister mirror
  5  = Champ Winner                     22 = Mirror Hierarchical Close position
  6  = Compensation                     23 = Hierarchical Open position
  7  = Bonus                            24 = Close position by recovery
  8  = Reverse cashout                  25 = Open position by recovery
  9  = Cashout request                  26 = FixBonusCreditRealizedEquity
 10  = IB synchronization               27 = Detach position from mirror
 11  = Chargeback                       28 = Detach Stock From Mirror
 12  = Refund                           29 = Open Stock Order
 13  = Edit Stop Loss                   30 = Close Stock Order
 14  = End Of Week Fee                  31 = Data Fix
 15  = Cashout Fee                      32 = Reverse Deposit
 16  = Refund As ChargeBack             33 = Cashout Rollback
 17  = FixHistoryCreditChargeBacks
```

### 2.3 Nullable Reference ID Pattern

**What**: The procedure accepts numerous nullable reference IDs, each relevant only for specific CreditTypeIDs.

**Columns/Parameters Involved**: `@PositionID`, `@ChampionshipID`, `@CashoutID`, `@PaymentID`, `@WithdrawID`, `@DepositID`, `@UpdateID`, `@CampaignID`, `@BonusTypeID`, `@CompensationReasonID`, `@MirrorID`, `@StocksOrderID`, `@MirrorDividendID`, `@DepositRollbackID`, `@InterestMonthlyID`

**Rules**:
- All reference IDs are NULL by default; callers populate only the IDs relevant to their credit type.
- Example: SetBalanceDeposit populates @DepositID; SetBalanceClosePosition populates @PositionID.
- This design avoids multiple insert procedures - one procedure covers all event types.
- @Occurred defaults to GETUTCDATE() via ISNULL(@Occurred, GETUTCDATE()) in the INSERT.

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @CID | INT | YES | null | CODE-BACKED | Customer ID of the account whose balance is being affected. FK to Customer.Customer (the view). |
| 2 | @CreditTypeID | TINYINT | YES | null | VERIFIED | Type of financial event: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 10=IB synchronization, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close, 23=Hierarchical Open, 24=Close by recovery, 25=Open by recovery, 26=FixBonusCreditRealizedEquity, 27=Detach position from mirror, 28=Detach Stock From Mirror, 29=Open Stock Order, 30=Close Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Dictionary.CreditType) |
| 3 | @PositionID | BIGINT | YES | null | CODE-BACKED | Trading position linked to this credit event. Populated for credit types involving positions: 3=Open, 4=Close, 13=Edit SL, 22=Mirror Hierarchical Close, 23=Hierarchical Open, etc. NULL for non-position events (deposits, withdrawals). |
| 4 | @ChampionshipID | INT | YES | null | CODE-BACKED | Championship event ID linked to this credit. Populated for type 5=Champ Winner. NULL otherwise. |
| 5 | @CashoutID | INT | YES | null | CODE-BACKED | Cashout request ID for cashout-related credits (type 2=Cashout). Links to the cashout record being processed. |
| 6 | @PaymentID | INT | YES | null | CODE-BACKED | PSP payment ID for deposit-related credits. Links to the payment gateway transaction. |
| 7 | @WithdrawID | INT | YES | null | CODE-BACKED | Withdrawal request ID. Populated for type 2=Cashout and 33=Cashout Rollback. Links to Billing schema withdrawal records. |
| 8 | @DepositID | INT | YES | null | CODE-BACKED | Deposit transaction ID. Populated for type 1=Deposit, 7=Bonus, 11=Chargeback, 12=Refund, 16=Refund As ChargeBack. Links to Billing schema deposit records. |
| 9 | @UpdateID | INT | YES | null | CODE-BACKED | Internal update/event reference ID for traceability. Usage varies by credit type. |
| 10 | @CampaignID | INT | YES | null | CODE-BACKED | Marketing campaign ID, populated for bonus credits (type 7=Bonus) to track which campaign triggered the bonus. |
| 11 | @BonusTypeID | INT | YES | null | CODE-BACKED | Bonus category ID for type 7=Bonus credits. Differentiates between bonus sub-types (welcome bonus, deposit bonus, etc.). |
| 12 | @CompensationReasonID | INT | YES | null | CODE-BACKED | Reason code for compensation credits (type 6=Compensation). Identifies why the compensation was issued. |
| 13 | @ManagerID | INT | YES | null | CODE-BACKED | ID of the manager/admin who initiated manual credit types (compensation, data fix). NULL for automated system credits. |
| 14 | @Credit | MONEY | YES | null | CODE-BACKED | Credit component of the balance change - the non-cash bonus credit amount. Distinct from @Payment (real cash). |
| 15 | @Payment | MONEY | YES | null | CODE-BACKED | Cash payment amount of the balance change. The real money component. Positive = money added, negative = money removed. |
| 16 | @Description | VARCHAR(255) | YES | null | CODE-BACKED | Human-readable description of the credit event, used in customer-facing history and support lookups. |
| 17 | @Occurred | DATETIME | YES | null | CODE-BACKED | Timestamp of the financial event. If NULL, defaults to GETUTCDATE() (UTC time of insertion). Callers may supply a specific occurrence time for backdated corrections. |
| 18 | @WithdrawProcessingID | INT | YES | null | CODE-BACKED | Processing batch/reference ID for withdrawal operations. Links to Billing withdrawal processing records. |
| 19 | @MirrorID | INT | YES | null | CODE-BACKED | Copy-trading mirror ID when the credit relates to a mirror (copy) position. Defaults to 0 (no mirror) in the target table. Types 18-23 involve mirror balance transfers. |
| 20 | @TotalCash | MONEY | YES | null | CODE-BACKED | Total cash balance of the customer's account captured at time of transaction. Used for account snapshot in the credit record. |
| 21 | @TotalCashChange | MONEY | YES | null | CODE-BACKED | Delta change to total cash resulting from this credit event. Positive = cash increase, negative = cash decrease. |
| 22 | @BonusCredit | MONEY | YES | null | CODE-BACKED | Bonus credit amount affected by this event. Separate from real cash (@Payment) - tracks non-withdrawable bonus balance changes. |
| 23 | @RealizedEquity | MONEY | YES | null | CODE-BACKED | Realized equity value at time of the transaction. Captured for position close events to record the equity state at close time. |
| 24 | @MirrorCash | DECIMAL(16,8) | YES | null | CODE-BACKED | Cash balance within the copy-trading mirror at time of event. Higher precision (16,8) than MONEY for mirror balance accuracy. |
| 25 | @StocksOrderID | INT | YES | null | CODE-BACKED | Stock order reference ID for stock-related credits (types 29=Open Stock Order, 30=Close Stock Order). Links to the stocks order system. |
| 26 | @MirrorEquity | MONEY | YES | null | CODE-BACKED | Equity value within the copy-trading mirror at time of event. Recorded alongside @MirrorCash for mirror position snapshots. |
| 27 | @MirrorDividendID | INT | YES | null | CODE-BACKED | Dividend payment ID when the credit is a mirror dividend distribution. Links to dividend records in the Trade schema. |
| 28 | @MoveMoneyReasonID | INT | YES | null | CODE-BACKED | Reason code for internal money movement operations. Added in FB 33991 to trace why inter-account transfers occurred. |
| 29 | @BSLRealFunds | MONEY | YES | null | CODE-BACKED | Bonus stop-loss real funds amount. Represents the real-money component affected by BSL (Bonus Stop-Loss) rules. Added in FB 43262 for bonus modification tracking. |
| 30 | @OriginalPositionID | BIGINT | YES | null | CODE-BACKED | For re-opened or recovered positions, the original position ID before re-open/recovery. Links to the prior position record. |
| 31 | @SubCreditTypeID | INT | YES | null | CODE-BACKED | Sub-classification of the credit type for more granular categorization within a CreditTypeID group. |
| 32 | @DepositRollbackID | INT | YES | null | CODE-BACKED | ID of the original deposit being reversed/rolled back. Populated for types 11=Chargeback, 12=Refund, 16=Refund As ChargeBack. Added MIMOPSA-7307. |
| 33 | @InterestMonthlyID | BIGINT | YES | null | CODE-BACKED | Monthly interest payment record ID. Links to interest billing records when credit type represents an interest charge or payment. |
| 34 | @Identity | BIGINT | NO (OUTPUT) | - | CODE-BACKED | OUTPUT parameter. Returns the CreditID (SCOPE_IDENTITY()) of the newly inserted History.ActiveCreditRecentMemoryBucket record. Callers use this to link back to the credit from notifications and service messages. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @CID | Customer.Customer (view) | Implicit | Customer whose balance is being transacted |
| @CreditTypeID | Dictionary.CreditType | Lookup | Defines the category of financial event (1-33 values) |
| @PositionID | Trade.PositionTbl | Implicit | Trading position linked to position-type credits |
| @DepositID | Billing schema deposits | Implicit | Deposit record for deposit/chargeback/refund credits |
| @WithdrawID | Billing schema withdrawals | Implicit | Withdrawal record for cashout credits |
| @MirrorID | Trade mirrors | Implicit | Copy-trading mirror for mirror-type credits |
| (all params) | History.ActiveCreditRecentMemoryBucket | INSERT target | All parameters are inserted into this memory-optimized table |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalance | EXEC | Caller (via specialized procs) | Orchestrator that routes to specialized SetBalance* procs |
| Customer.SetBalanceDeposit | EXEC | Caller | Deposit credit insertion |
| Customer.SetBalanceBonus | EXEC | Caller | Bonus credit insertion |
| Customer.SetBalanceCashOut | EXEC | Caller | Cashout credit insertion |
| Customer.SetBalanceCashoutRollback | EXEC | Caller | Cashout rollback credit insertion |
| Customer.SetBalanceChangeCredit | EXEC | Caller | Credit adjustment insertion |
| Customer.SetBalanceChangeMirrorAmount | EXEC | Caller | Mirror amount change credit |
| Customer.SetBalanceChargeBack | EXEC | Caller | Chargeback credit insertion |
| Customer.SetBalanceClameFee | EXEC | Caller | Fee claim credit insertion |
| Customer.SetBalanceClosePosition | EXEC | Caller | Position close credit insertion |
| Customer.SetBalanceCompensation | EXEC | Caller | Compensation credit insertion |
| Customer.SetBalanceDataFix | EXEC | Caller | Data fix credit insertion |
| Customer.SetBalanceDataFixDebug | EXEC | Caller | Debug data fix credit insertion |
| Customer.SetBalanceOpenPosition | EXEC | Caller | Position open credit insertion |
| Customer.SetBalanceRefund | EXEC | Caller | Refund credit insertion |
| Customer.SetBalanceRefundAsChargeBack | EXEC | Caller | Refund-as-chargeback credit insertion |
| History.ActiveCredit_CashoutRollbackSet | EXEC | Caller | Cashout rollback set via History schema |
| Trade.DetachPositionsFromMirror | EXEC | Caller | Credit written when positions detach from a mirror |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Customer.SetBalanceInsertCredit_Native (procedure)
└── History.ActiveCreditRecentMemoryBucket (table) [memory-optimized, INSERT target]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.ActiveCreditRecentMemoryBucket | Table | INSERT target - all credit records are written here |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceDeposit | Procedure | Calls this to log deposit credits |
| Customer.SetBalanceBonus | Procedure | Calls this to log bonus credits |
| Customer.SetBalanceCashOut | Procedure | Calls this to log cashout credits |
| Customer.SetBalanceCashoutRollback | Procedure | Calls this to log cashout rollback credits |
| Customer.SetBalanceChangeCredit | Procedure | Calls this to log credit change events |
| Customer.SetBalanceChangeMirrorAmount | Procedure | Calls this to log mirror amount changes |
| Customer.SetBalanceChargeBack | Procedure | Calls this to log chargebacks |
| Customer.SetBalanceClameFee | Procedure | Calls this to log fee claims |
| Customer.SetBalanceClosePosition | Procedure | Calls this to log position-close credits |
| Customer.SetBalanceCompensation | Procedure | Calls this to log compensation credits |
| Customer.SetBalanceDataFix | Procedure | Calls this to log data fix operations |
| Customer.SetBalanceDataFixDebug | Procedure | Calls this to log debug data fix operations |
| Customer.SetBalanceOpenPosition | Procedure | Calls this to log position-open credits |
| Customer.SetBalanceRefund | Procedure | Calls this to log refunds |
| Customer.SetBalanceRefundAsChargeBack | Procedure | Calls this to log refund-as-chargeback credits |
| History.ActiveCredit_CashoutRollbackSet | Procedure | Calls this for cashout rollback credit insertion |
| Trade.DetachPositionsFromMirror | Procedure | Calls this to log credits when positions detach from mirrors |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH native_compilation | Compile option | Procedure is compiled to native machine code at creation - eliminates T-SQL interpreter overhead for maximum INSERT throughput |
| WITH schemabinding | Compile option | Required for natively compiled procedures; schema must not change while procedure exists |
| EXECUTE AS OWNER | Security | Runs under the schema owner's security context |
| BEGIN ATOMIC WITH SNAPSHOT | Transaction | Memory-optimized tables require ATOMIC blocks with explicit isolation level; SNAPSHOT avoids read-write conflicts |

---

## 8. Sample Queries

### 8.1 Find recent credits inserted by this procedure for a customer

```sql
SELECT TOP 20
    CreditID,
    CID,
    CreditTypeID,
    ct.Name AS CreditTypeName,
    Credit,
    Payment,
    Description,
    Occurred
FROM History.ActiveCreditRecentMemoryBucket acmb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acmb.CreditTypeID
WHERE acmb.CID = 12345
ORDER BY Occurred DESC
```

### 8.2 Verify the inserted credit using the returned @Identity

```sql
-- After calling Customer.SetBalanceInsertCredit_Native, verify the record
DECLARE @NewCreditID BIGINT = 987654321 -- from @Identity OUTPUT

SELECT
    CreditID,
    CID,
    CreditTypeID,
    Credit,
    Payment,
    TotalCash,
    TotalCashChange,
    Occurred
FROM History.ActiveCreditRecentMemoryBucket WITH (NOLOCK)
WHERE CreditID = @NewCreditID
```

### 8.3 Analyze credit distribution by type in the memory bucket

```sql
SELECT
    acmb.CreditTypeID,
    ct.Name AS CreditTypeName,
    COUNT(*) AS RecordCount,
    SUM(acmb.Payment) AS TotalPayment,
    MIN(acmb.Occurred) AS EarliestOccurred,
    MAX(acmb.Occurred) AS LatestOccurred
FROM History.ActiveCreditRecentMemoryBucket acmb WITH (NOLOCK)
JOIN Dictionary.CreditType ct WITH (NOLOCK) ON ct.CreditTypeID = acmb.CreditTypeID
GROUP BY acmb.CreditTypeID, ct.Name
ORDER BY RecordCount DESC
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14028570661/Multi-Currency+Balance+API) | Confluence | Adjacent context on balance API design; no direct content about this procedure |
| [Multi-Currency Database Schema Changes](https://etoro-jira.atlassian.net/wiki/spaces/TRAD/pages/14019264620/Multi-Currency+Database+Schema+Changes) | Confluence | Adjacent schema change context; no direct content about this procedure |

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.5/10 (Elements: 9.0/10, Logic: 8.0/10, Relationships: 9.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 34 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/4*
*Sources: Atlassian: 2 Confluence + 0 Jira | Procedures: 18 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Customer.SetBalanceInsertCredit_Native | Type: Stored Procedure | Source: etoro/etoro/Customer/Stored Procedures/Customer.SetBalanceInsertCredit_Native.sql*
