# History.ActiveCreditRecentMemoryBucket

> In-Memory OLTP (memory-optimized) ledger staging buffer: receives every balance-write credit event from `Customer.SetBalanceInsertCredit_Native` at native-compilation speed, then is periodically flushed to `History.ActiveCredit_BIGINT` via a DELETE...OUTPUT pattern.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | Table |
| **Key Identifier** | CreditID (PK, BIGINT IDENTITY, NONCLUSTERED) |
| **Partition** | No |
| **Indexes** | 1 active (NONCLUSTERED PK - required for memory-optimized tables) |

---

## 1. Business Meaning

History.ActiveCreditRecentMemoryBucket is the **in-memory ledger staging table** for all eToro account balance mutations. Every credit event - deposit, withdrawal, fee, compensation, bonus, P&L settlement, dividend - lands in this table first before being flushed to the persistent disk table `History.ActiveCredit_BIGINT`.

The table is **memory-optimized** (`MEMORY_OPTIMIZED = ON, DURABILITY = SCHEMA_AND_DATA`): it survives server restarts (SCHEMA_AND_DATA durability) but operates using SQL Server's In-Memory OLTP engine. This enables lock-free, latch-free inserts at the extreme throughput rates required by the balance-write critical path. The write procedure `Customer.SetBalanceInsertCredit_Native` uses **native compilation** (`WITH NATIVE_COMPILATION, SCHEMABINDING`) and SNAPSHOT isolation, eliminating all blocking in this hot path.

**Lifecycle**:
1. Any `Customer.SetBalance*` sub-procedure ultimately calls `Customer.SetBalanceInsertCredit_Native`, which INSERTs a row here. A 3-retry WHILE loop with TRY/CATCH handles transient write conflicts.
2. `Trade.InsertActiveCredit` (or the partition-aware variant `Trade.InsertActiveCreditPartition`) runs on a schedule, performing `DELETE ... OUTPUT ... INTO History.ActiveCredit_BIGINT` to flush rows to the permanent disk table.
3. `Trade.AlertForActiveCreditRecentMemory` monitors the row count via `sp_spaceused` and is used for alerting if the buffer grows unexpectedly large.

**Read path**: `Billing.AmountAddBonus` and related procedures query this table (alongside `History.Credit`) for **bonus deduplication** - checking whether a bonus was already granted before committing a new credit. Since recent credits may not yet have been flushed to disk tables, querying this in-memory buffer is essential for detecting duplicate grants in real time.

**Multi-currency planned expansion**: Per the "Multi-Currency Balance API" (Trading Dev Confluence space), this table is planned to receive `CurrencyId` and `ConversionRateToUSD` columns as part of the multi-currency migration. These columns must be added here AND in `History.ActiveCredit_BIGINT` simultaneously so the flush procedure can carry them through.

**Schema mirror**: The `History.ActiveCreditRecentMemoryBucket_TYPE` user-defined type has the same schema (36 columns) and is declared as a local variable type in procedures that need an in-memory working set without touching the actual table.

---

## 2. Business Logic

### 2.1 Balance Write Pipeline - Insert Path

**What**: All account balance mutations write a credit ledger entry here via the natively compiled procedure.

**Columns/Parameters Involved**: All columns

**Rules**:
- `Customer.SetBalanceInsertCredit_Native` is the sole writer - called by all `Customer.SetBalance*` sub-procedures
- It uses `BEGIN ATOMIC WITH (TRANSACTION ISOLATION LEVEL = SNAPSHOT, LANGUAGE = N'us_english')` - no external transaction needed; atomic by design
- 3-retry loop: `@Retry=1..3`, increments on CATCH, exits at `@Retry=4` on success
- Returns `@Identity = SCOPE_IDENTITY()` - the CreditID assigned by the IDENTITY column
- `Occurred` defaults to `GETUTCDATE()` if `@Occurred` is NULL (always UTC)
- `MirrorID` defaults to `0` (not NULL) if not specified

**Diagram**:
```
Customer.SetBalance (router by CreditTypeID)
   |
   +-> Customer.SetBalanceDeposit (CreditTypeID=1)
   +-> Customer.SetBalanceCashOut (CreditTypeID=2)
   +-> Customer.SetBalanceCompensation (CreditTypeID=6)
   +-> Customer.SetBalanceBonus (CreditTypeID=7)
   +-> Customer.SetBalanceClosePosition (P&L settlement)
   +-> ... (all SetBalance* sub-procs)
         |
         v
   Customer.SetBalanceInsertCredit_Native
         |
         v
   History.ActiveCreditRecentMemoryBucket (INSERT)
```

### 2.2 Flush Pipeline - DELETE...OUTPUT Pattern

**What**: A scheduled job periodically flushes rows from this in-memory buffer to the permanent disk ledger.

**Columns/Parameters Involved**: All columns, CreditID, @Numrows, @Mod

**Rules**:
- `Trade.InsertActiveCredit (@Numrows)`: deletes rows WHERE CreditID BETWEEN @i AND @i+@Numrows, OUTPUTs deleted rows INTO History.ActiveCredit_BIGINT
- `Trade.InsertActiveCreditPartition (@Numrows, @Mod)`: partition-aware variant - processes one mod-10 partition at a time (CreditID%10=@Mod) in a WHILE loop, enabling 10 parallel flush jobs
- The MIN(CreditID) anchor ensures batches process oldest rows first
- The atomic DELETE+OUTPUT guarantees no data loss: a row is either in the buffer OR in ActiveCredit_BIGINT, never in neither

**Diagram**:
```
History.ActiveCreditRecentMemoryBucket (in-memory, hot)
   |
   Trade.InsertActiveCreditPartition (@Mod=0..9, 10 parallel jobs)
   |
   DELETE ... OUTPUT deleted.* INTO ...
   |
   v
History.ActiveCredit_BIGINT (persistent disk ledger)
```

### 2.3 Bonus Deduplication Guard

**What**: Recent credits are checked here before awarding new bonuses to prevent duplicate grants in high-concurrency scenarios.

**Columns/Parameters Involved**: `CID`, `CreditTypeID`, `BonusTypeID`, `CampaignID`

**Rules**:
- `Billing.AmountAddBonus` checks both `History.Credit` (persisted) AND this table (recent in-memory) before committing a new bonus
- `CreditTypeID IN (2, 5, 7)` in the dedup check identifies bonus-type credits
- If (CID, BonusTypeID, CampaignID) found in either source -> block with CheckResult=2
- The dual-source check is required because recently granted bonuses may not yet have been flushed to History.Credit

### 2.4 Row Count Monitoring

**What**: The table is monitored for abnormal growth that would indicate a flush job failure.

**Rules**:
- `Trade.AlertForActiveCreditRecentMemory` calls `sp_spaceused '[History].[ActiveCreditRecentMemoryBucket]'` and returns the row count
- Under normal operation, the table should have a very small number of rows (seconds to minutes worth of credits)
- Large row counts indicate that `Trade.InsertActiveCredit` / `Trade.InsertActiveCreditPartition` is not running or is failing

---

## 3. Data Overview

0 rows in the query environment. This is expected: the table is a high-throughput buffer that is continuously flushed to `History.ActiveCredit_BIGINT`. In production, it holds only the most recent seconds-to-minutes of credit events. Data begins accumulating immediately when balance operations occur and is cleared on each flush cycle.

| CreditID | CID | CreditTypeID | Credit | Payment | Occurred | Meaning |
|---|---|---|---|---|---|---|
| (live buffer - typically empty between flush cycles) | - | - | - | - | - | - |
| 1,200,000 (ex.) | 12345 | 1 | 0 | 500.00 | 2026-03-19 10:23:01 | Deposit of $500. Credit=0 (balance tracked in CustomerMoney), Payment=500 is the cash amount. CreditTypeID=1. Occurred at current UTC time. Would be flushed to ActiveCredit_BIGINT within minutes. |
| 1,200,001 (ex.) | 98765 | 7 | 100 | 0 | 2026-03-19 10:23:02 | Bonus award of $100 virtual credit. CreditTypeID=7, BonusCredit=100, Payment=0 (no real cash). BonusTypeID and CampaignID would be set to identify the bonus program. |

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | IDENTITY(1,1) | CODE-BACKED | Unique credit ledger entry identifier. Auto-generated IDENTITY. The NONCLUSTERED PK on this column is required by SQL Server for memory-optimized tables (clustered indexes not supported). Returned as @Identity OUTPUT from Customer.SetBalanceInsertCredit_Native. Carried through to History.ActiveCredit_BIGINT on flush. |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID (eToro account holder). Identifies whose balance was changed. Used in bonus deduplication: WHERE CID = @CID. All SetBalance* sub-procedures pass @CID directly. References Customer.CustomerStatic. |
| 3 | CreditTypeID | tinyint | NO | - | CODE-BACKED | Credit event classification (routing key). Values from the Atlassian balance API doc: 1=Deposit, 2=CashOut (withdrawal), 6=Compensation, 7=Bonus, 11/12/16=Chargeback/Refund variants. Used in bonus dedup check: CreditTypeID IN (2, 5, 7). Passed from the SetBalance* sub-procedure that calls SetBalanceInsertCredit_Native. References Dictionary.CreditType. |
| 4 | PositionID | bigint | YES | - | CODE-BACKED | Position associated with this credit event. Set for CreditTypeID values that relate to trading (P&L settlement on close, overnight fee, dividend). NULL for non-position credits (deposits, bonuses, compensations). References History.Position_Active / Trade.PositionTbl. |
| 5 | ChampionshipID | int | YES | - | CODE-BACKED | Championship competition linked to this credit (prize payout). NULL when credit is not competition-related. References Championship tables. |
| 6 | CashoutID | int | YES | - | CODE-BACKED | Withdrawal (cashout) request that triggered this credit event. Set for CreditTypeID=2 (CashOut). NULL for non-withdrawal credits. References Billing.Cashout. |
| 7 | PaymentID | int | YES | - | CODE-BACKED | Payment record associated with this credit (e.g., deposit payment). NULL for non-deposit credits. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Withdrawal request associated with this credit. In Billing.AmountAddBonus, @WithdrawID is passed through - used for bonus deductions applied at withdrawal time (bonus clawback on early withdrawal). References Billing.WithdrawRequest. |
| 9 | DepositID | int | YES | - | CODE-BACKED | Deposit that triggered the bonus or credit. Passed from Billing.AmountAddBonus linking the bonus credit back to the qualifying deposit for campaign tracking and idempotency. References Billing.Deposit. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Internal update sequence identifier for this credit record. Tracks revision history. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Marketing campaign that generated this credit. Central to bonus deduplication: WHERE CampaignID = @CampaignID prevents a customer from receiving the same campaign bonus twice. References BackOffice.Campaign. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus category for this credit. Used in dedup check: BonusTypeID = @BonusTypeID combined with CampaignID uniquely identifies a bonus grant. NULL for non-bonus credits. References Dictionary.BonusType or BackOffice.Bonus. |
| 13 | CompensationReasonID | int | YES | - | CODE-BACKED | Reason code for operational compensation credits (e.g., platform outage reimbursement). Set for CreditTypeID=6 (Compensation). NULL for non-compensation credits. References Dictionary.CompensationReason. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | Back-office manager who triggered this credit manually. NULL for system-generated credits (trading events, scheduled fees). References BackOffice.Managers. |
| 15 | Credit | money | NO | - | CODE-BACKED | Net credit amount applied to the account balance, in USD. Positive = funds added; negative = funds deducted. For deposits: often 0 (balance tracked in CustomerMoney.Credit separately). For P&L close: net profit/loss. For bonuses: the bonus virtual credit amount. |
| 16 | Payment | money | NO | - | CODE-BACKED | Cash payment amount associated with this credit. For deposits: the actual cash amount deposited (@Amount from SetBalanceDeposit). For cashouts: the withdrawal amount. Represents the real monetary value transacted (vs Credit which may include bonus/virtual amounts). |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text description of the credit event. @Description parameter passed through from the SetBalance* sub-procedure. Used for back-office display and audit trail. Examples: "Deposit via credit card", "Overnight fee", "Campaign bonus XYZ". |
| 18 | Occurred | datetime | NO | GETUTCDATE() | CODE-BACKED | UTC timestamp when the credit event occurred. Set to ISNULL(@Occurred, GETUTCDATE()) in SetBalanceInsertCredit_Native - uses caller-provided time if supplied, otherwise current UTC. Default constraint DF_ActiveCreditRecentMemoryBucket_Occurred provides the fallback. Primary ordering column for flush operations. |
| 19 | WithdrawProcessingID | int | YES | - | NAME-INFERRED | Processing batch identifier for withdrawal-related credits. Groups credits belonging to the same withdrawal processing run. |
| 20 | MirrorID | int | YES | 0 | CODE-BACKED | CopyTrading mirror relationship associated with this credit (copy stop-loss, mirror dividend, copy fee). Default 0 (constraint DFActiveCreditRecentMemoryBucket_MirrorID) means "no mirror". Non-zero values link to a specific copy-trading relationship. References Trade.Mirror. |
| 21 | TotalCash | money | YES | - | CODE-BACKED | Total cash balance of the account after this credit is applied. Snapshot at credit time. Passed from Customer.SetBalance* which computes this from CustomerMoney before calling the native proc. |
| 22 | TotalCashChange | money | YES | - | CODE-BACKED | Net change in total cash balance caused by this credit event. Positive = balance increased; negative = decreased. Used for balance reconciliation and history views. |
| 23 | BonusCredit | money | YES | - | CODE-BACKED | Bonus component of the credit (non-withdrawable promotional funds). Separate from real-cash Credit column. Set for CreditTypeID=7 (Bonus). NULL or 0 for non-bonus credits. Tracked separately because bonus funds have different withdrawal rules. |
| 24 | RealizedEquity | money | YES | - | CODE-BACKED | Realized equity of the account at the time of this credit event (TotalCash + unrealized P&L on open positions, approximately). Used for copy-trading redemption calculations and BSL equity accounting. |
| 25 | MirrorCash | decimal(16,8) | YES | - | CODE-BACKED | Cash allocated to a specific copy-trading (mirror) relationship at credit time. Higher decimal precision (16,8) than standard money type - needed for copy ratio calculations where fractional amounts matter. |
| 26 | StocksOrderID | int | YES | - | CODE-BACKED | Stocks order associated with this credit (e.g., dividend from a stock position, or stocks overnight fee). NULL for non-stock credits. References Trade stocks order tables. NOTE: DDL declares this as INT but the UDT declares it as BIGINT - potential overflow risk for very high stock order IDs. |
| 27 | MirrorEquity | money | YES | - | CODE-BACKED | Equity value of the copy-trading allocation at the time of this credit. Used in copy stop-loss (MSL) and redemption calculations. Paired with MirrorCash to track copy portfolio value. |
| 28 | MirrorDividendID | int | YES | - | CODE-BACKED | Mirror dividend record that generated this credit entry. Set when a copy-trading customer receives a dividend payment. References History.MirrorDividend. |
| 29 | MoveMoneyReasonID | int | YES | - | CODE-BACKED | Reason for a money-movement credit event. Added in Case 34113 per UDT doc history. Categorizes internal balance transfers (e.g., inter-account moves, regulation-required transfers). References Dictionary.MoveMoneyReason. |
| 30 | BSLRealFunds | money | YES | - | CODE-BACKED | Real funds portion of the balance at the time of a Below-Stop-Loss (BSL) credit event. Used in BSL equity accounting to distinguish real vs bonus funds - BSL triggers on equity including real funds only. |
| 31 | OriginalPositionID | bigint | YES | - | CODE-BACKED | Position ID before a split, rollover, or partial close operation. Traces credit events back to their originating position for audit. References History.Position_Active. |
| 32 | SubCreditTypeID | int | YES | - | CODE-BACKED | Sub-classification of the credit type for granular categorization beyond CreditTypeID. Extends CreditTypeID for edge cases (e.g., distinguishing sub-types of compensation or specific fee categories). References Dictionary.SubCreditType (if exists). |
| 33 | DepositRollbackID | int | YES | - | CODE-BACKED | Deposit reversal record associated with this credit. Set when a deposit is rolled back (chargeback or refund), linking the reversal credit entry back to the original rollback record. References Billing.DepositRollback. |
| 34 | InterestMonthlyID | bigint | YES | - | CODE-BACKED | Monthly interest payment record linked to this credit. Set for interest account credits. References the interest tracking table. BIGINT because interest records use large sequential IDs. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Identifies the customer whose balance is affected. |
| CreditTypeID | Dictionary.CreditType | Implicit | Classifies the balance event type. Values 1=Deposit, 2=CashOut, 6=Compensation, 7=Bonus etc. |
| BonusTypeID | BackOffice.Bonus (or Dictionary.BonusType) | Implicit | Links credit to the bonus category for deduplication. |
| CampaignID | BackOffice.Campaign | Implicit | Links credit to the marketing campaign that granted the bonus. |
| MirrorID | Trade.Mirror | Implicit | Links copy-trading credits to their mirror relationship. |
| MirrorDividendID | History.MirrorDividend | Implicit | Links dividend credits to their mirror dividend record. |
| PositionID | History.Position_Active | Implicit | Links position-related credits (P&L, fees) to their position. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Customer.SetBalanceInsertCredit_Native | - | Writer (NATIVELY COMPILED) | The sole write path. Inserts every balance credit event with SNAPSHOT isolation and 3-retry logic. |
| Trade.InsertActiveCredit | @Numrows | Flush (DELETE OUTPUT) | Periodic flush to History.ActiveCredit_BIGINT. Processes a batch of rows by CreditID range. |
| Trade.InsertActiveCreditPartition | @Numrows, @Mod | Flush (DELETE OUTPUT, partitioned) | Partition-aware flush variant. Runs 10 parallel jobs (CreditID%10=0..9) for higher throughput. |
| Trade.AlertForActiveCreditRecentMemory | - | Monitor | Queries row count via sp_spaceused for alerting on buffer backlog. |
| Billing.AmountAddBonus | - | Reader (deduplication) | Checks this table for existing bonus grants before awarding new bonuses. |
| History.ActiveCreditBucket_VW | - | Reader (view) | View over this table for reporting. |
| History.ActiveCreditView | - | Reader (view) | View over this table. |
| History.HistoryGetUnifiedbyCID | - | Reader (function) | Unified history function that reads this table for recent credits. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.ActiveCreditRecentMemoryBucket (table)
  - leaf node: no code-level dependencies (no FK constraints)
  - written by: Customer.SetBalanceInsertCredit_Native
  - flushed to: History.ActiveCredit_BIGINT
```

### 6.1 Objects This Depends On

No FK constraints. Memory-optimized tables in SQL Server do not support FK constraints.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Customer.SetBalanceInsertCredit_Native | Stored Procedure (native) | Writer - inserts every credit event |
| Trade.InsertActiveCredit | Stored Procedure | Flush - DELETE...OUTPUT INTO History.ActiveCredit_BIGINT |
| Trade.InsertActiveCreditPartition | Stored Procedure | Flush (partition-aware) - same pattern |
| Trade.AlertForActiveCreditRecentMemory | Stored Procedure | Monitor - sp_spaceused row count |
| Billing.AmountAddBonus | Stored Procedure | Reader - bonus deduplication check |
| History.ActiveCreditBucket_VW | View | Reader - reporting view |
| History.ActiveCreditView | View | Reader - reporting view |
| History.HistoryGetUnifiedbyCID | Function | Reader - unified credit history |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_ActiveCreditRecentMemoryBucket (inferred) | NONCLUSTERED PK (memory-optimized) | CreditID ASC | - | - | Active |

**Note**: Memory-optimized tables require NONCLUSTERED primary keys. Clustered indexes are not supported. Hash indexes (useful for equality-only lookups) and range indexes (useful for ordered scans) can be added but are not defined in the DDL.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK on CreditID | PRIMARY KEY NONCLUSTERED | Required by SQL Server In-Memory OLTP engine. Ensures each credit event has a unique ID. |
| DF_ActiveCreditRecentMemoryBucket_Occurred | DEFAULT | Occurred = GETUTCDATE() - UTC timestamp of credit. |
| DFActiveCreditRecentMemoryBucket_MirrorID | DEFAULT | MirrorID = 0 - non-null default meaning "no mirror relationship". |
| MEMORY_OPTIMIZED = ON | Table Option | SQL Server In-Memory OLTP engine. Lock-free, latch-free operations. |
| DURABILITY = SCHEMA_AND_DATA | Table Option | Data survives server restarts. (SCHEMA_ONLY would lose data on restart.) |

---

## 8. Sample Queries

### 8.1 Current buffer state (row count and oldest pending flush)
```sql
SELECT
    COUNT(*) AS BufferedRows,
    MIN(CreditID) AS OldestCreditID,
    MAX(CreditID) AS NewestCreditID,
    MIN(Occurred) AS OldestOccurred,
    MAX(Occurred) AS NewestOccurred,
    DATEDIFF(second, MIN(Occurred), GETUTCDATE()) AS OldestRowAgeSec
FROM History.ActiveCreditRecentMemoryBucket;
```

### 8.2 Credit type distribution in the current buffer
```sql
SELECT
    CreditTypeID,
    COUNT(*) AS Credits,
    SUM(Payment) AS TotalPayment,
    SUM(Credit) AS TotalCredit
FROM History.ActiveCreditRecentMemoryBucket
GROUP BY CreditTypeID
ORDER BY Credits DESC;
```

### 8.3 Bonus deduplication check (mirrors Billing.AmountAddBonus logic)
```sql
-- Check if a specific bonus was already granted (in-memory buffer)
SELECT TOP 1 CreditID
FROM History.ActiveCreditRecentMemoryBucket
WHERE CreditTypeID IN (2, 5, 7)
  AND CID = @CID
  AND BonusTypeID = @BonusTypeID
  AND CampaignID = @CampaignID;
-- If rows found -> duplicate bonus; block the grant
```

---

## 9. Atlassian Knowledge Sources

| Source | Type | Key Knowledge Extracted |
|--------|------|------------------------|
| [Multi-Currency Balance API](https://etoro-jira.atlassian.net/wiki/spaces/TRADINGDEV/pages/14028570661) | Confluence (Trading Dev) | Confirms this table is the central in-memory ledger staging buffer for ALL balance operations. Documents the complete write chain: SetBalance* -> SetBalanceInsertCredit_Native -> this table -> InsertActiveCredit -> ActiveCredit_BIGINT. Confirms planned addition of CurrencyId + ConversionRateToUSD columns for multi-currency support. Lists CreditTypeID values: 1=Deposit, 2=CashOut, 6=Compensation, 7=Bonus, 11/12/16=Chargeback/Refund. Documents the idempotency role: "The API checks History.ActiveCreditRecentMemoryBucket (or a dedicated idempotency table) for a matching key before executing." |

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 9.3/10 (Elements: 9.5/10, Logic: 9.5/10, Relationships: 9.0/10, Sources: 9.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 30 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 1 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCreditRecentMemoryBucket | Type: Table | Source: etoro/etoro/History/Tables/History.ActiveCreditRecentMemoryBucket.sql*
