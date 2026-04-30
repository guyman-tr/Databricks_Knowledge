# History.ActiveCreditRecentMemoryBucket_TYPE

> Memory-optimized table-valued parameter type mirroring the schema of the ActiveCreditRecentMemoryBucket in-memory table, used to pass or hold credit record snapshots in OLTP-critical billing and balance procedures.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | User Defined Type |
| **Key Identifier** | CreditID (bigint, NONCLUSTERED PK) |
| **Partition** | No |
| **Indexes** | 1 (NONCLUSTERED PK on CreditID) |

---

## 1. Business Meaning

This UDT defines the row structure for in-memory table variables that mirror `History.ActiveCreditRecentMemoryBucket` - the memory-optimized staging table for recent credit events. Procedures declare local variables of this type to hold a working set of credit rows in memory during balance update operations, enabling fast deduplication checks without repeated reads from the large `History.Credit` table.

The type exists because SQL Server's memory-optimized tables require a matching memory-optimized TVP type to pass rows in and out via OUTPUT or local variable patterns. It allows procedures operating in the critical bonus and balance-update path to work with in-memory credit data using native compilation and lock-free concurrency.

Data flows from `History.ActiveCreditRecentMemoryBucket` (the real in-memory table) into local variables of this type for transient in-procedure use. The canonical usage pattern in `Billing.AmountAddBonus` is: declare a local variable of this type, then query the real in-memory table to check whether a bonus was already granted to a customer before committing a new credit.

---

## 2. Business Logic

### 2.1 Bonus Deduplication Guard

**What**: Prevents double-payment of campaign bonuses in high-concurrency scenarios.

**Columns/Parameters Involved**: `CreditID`, `CID`, `CreditTypeID`, `BonusTypeID`, `CampaignID`

**Rules**:
- A local variable of this type is used alongside `History.Credit` to check for prior bonus grants
- `CreditTypeID IN (2, 5, 7)` identifies bonus-type credits (deposit bonus, campaign bonus, referral bonus)
- The COALESCE pattern checks `History.Credit` first, then `History.ActiveCreditRecentMemoryBucket` - covering both persisted and recently in-memory credits
- If either source contains a matching (CID, BonusTypeID, CampaignID) record, the duplicate is blocked (`@CheckResult = 2`)

**Diagram**:
```
Billing.AmountAddBonus called
       |
       v
Check History.Credit (persisted)     --> found? -> block (CheckResult=2)
       |
       v (not found)
Check History.ActiveCreditRecentMemoryBucket (in-memory recent)
       |
       +-- found? -> block (CheckResult=2)
       |
       v (not found)
Proceed with bonus INSERT + Customer.SetBalance
```

### 2.2 Memory-Optimized Performance Pattern

**What**: Uses MEMORY_OPTIMIZED=ON to enable lock-free, latch-free access in high-throughput bonus/balance paths.

**Columns/Parameters Involved**: All columns

**Rules**:
- The `WITH (MEMORY_OPTIMIZED = ON)` declaration makes this type usable only with memory-optimized local variables
- NONCLUSTERED PK is required by SQL Server for memory-optimized table types
- Procedures that use this type benefit from in-memory speed when working with recent credit snapshots before committing to disk tables

---

## 3. Data Overview

N/A for User Defined Type.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Primary key. Unique credit event identifier. Mirrors `History.Credit.CreditID` - the canonical credit record ID used for deduplication. NONCLUSTERED PK on this column. |
| 2 | CID | int | YES | - | CODE-BACKED | Customer ID (eToro account identifier). Used in the bonus deduplication check: `WHERE CID = @CID AND BonusTypeID = @BonusTypeID AND CampaignID = @CampaignID`. References Customer.CustomerStatic. |
| 3 | CreditTypeID | tinyint | YES | - | CODE-BACKED | Credit event classification. In bonus dedup check: `CreditTypeID IN (2, 5, 7)` targets bonus credit types (deposit bonus, campaign, referral). See glossary for full value map. (Dictionary.CreditType) |
| 4 | PositionID | bigint | YES | - | NAME-INFERRED | Position associated with this credit event (e.g., P&L adjustment, dividend). NULL for non-position credits such as deposits and bonuses. References History.Position_Active. |
| 5 | ChampionshipID | int | YES | - | NAME-INFERRED | Championship competition linked to this credit (e.g., prize payout). NULL when credit is not competition-related. References History.Championship. |
| 6 | CashoutID | int | YES | - | NAME-INFERRED | Withdrawal (cashout) request that triggered this credit event. NULL for non-withdrawal credits. References Billing.Cashout or similar. |
| 7 | PaymentID | int | YES | - | NAME-INFERRED | Deposit payment that triggered this credit (e.g., first-deposit bonus). NULL for non-deposit credits. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Withdrawal request associated with this credit. In `Billing.AmountAddBonus`, `@WithdrawID` is passed through and stored - used for bonus deductions applied at withdrawal time (e.g., bonus clawback on early withdrawal). |
| 9 | DepositID | int | YES | - | CODE-BACKED | Deposit that triggered the bonus. In `Billing.AmountAddBonus`, `@DepositID` is passed and stored, linking the bonus credit back to the qualifying deposit for campaign tracking. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Internal update sequence identifier for this credit record. Tracks revision history within the in-memory store. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Marketing campaign that generated this credit. Central to bonus deduplication: `WHERE CampaignID = @CampaignID` prevents a customer from receiving the same campaign bonus twice. References BackOffice.Campaign. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus category for this credit. Used in dedup check: `BonusTypeID = @BonusTypeID`. Combined with CampaignID uniquely identifies the bonus grant. References Dictionary.BonusType or BackOffice.Bonus. |
| 13 | CompensationReasonID | int | YES | - | NAME-INFERRED | Reason code for operational compensation credits (e.g., platform outage reimbursement). NULL for standard bonus/deposit credits. |
| 14 | ManagerID | int | YES | - | NAME-INFERRED | Back-office manager who manually triggered this credit. NULL for system-generated credits. References BackOffice.Managers or similar. |
| 15 | Credit | money | YES | - | NAME-INFERRED | Net credit amount applied to the account balance, in account currency. Positive = funds added; negative = funds deducted. |
| 16 | Payment | money | YES | - | CODE-BACKED | Cash payment amount associated with this credit. In `Billing.AmountAddBonus`, `@Amount` maps to Payment via `Customer.SetBalance`. Represents the actual monetary value credited/debited. |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text description of the credit event. In `Billing.AmountAddBonus`, `@Description` parameter is passed through. Used for back-office display and audit trail. Latin1_General_BIN collation. |
| 18 | Occurred | datetime | YES | - | NAME-INFERRED | Timestamp when the credit event occurred (UTC). The primary ordering column for recent credit lookups in the in-memory bucket. |
| 19 | WithdrawProcessingID | int | YES | - | NAME-INFERRED | Processing batch identifier for withdrawal-related credits. Used to group credits belonging to the same withdrawal processing run. |
| 20 | MirrorID | int | YES | - | NAME-INFERRED | CopyTrading mirror relationship associated with this credit (e.g., copy stop-loss triggered bonus). NULL for non-copy credits. References Trade.Mirror. |
| 21 | TotalCash | money | YES | - | NAME-INFERRED | Total cash balance of the account after this credit event is applied. Snapshot value at credit time. |
| 22 | TotalCashChange | money | YES | - | NAME-INFERRED | Net change in total cash balance caused by this credit event. Positive = balance increased; negative = balance decreased. |
| 23 | BonusCredit | money | YES | - | NAME-INFERRED | Bonus component of the credit (non-withdrawable promotional funds). Separate from real cash credit. Used in bonus balance tracking. |
| 24 | RealizedEquity | money | YES | - | NAME-INFERRED | Realized equity of the account at the time of this credit event. Used for copy-trading redemption and bonus eligibility calculations. |
| 25 | MirrorCash | decimal(16,8) | YES | - | NAME-INFERRED | Cash allocated to a specific copy-trading (mirror) relationship at the time of this credit. Higher precision (16,8) than standard money for copy ratio calculations. |
| 26 | StocksOrderID | bigint | YES | - | NAME-INFERRED | Stocks order associated with this credit (e.g., dividend from a stock position). NULL for non-stock credits. References Trade or History stocks order tables. |
| 27 | MirrorEquity | money | YES | - | NAME-INFERRED | Equity value of the copy-trading allocation at the time of this credit. Used in copy stop-loss and redemption calculations. |
| 28 | MirrorDividendID | int | YES | - | NAME-INFERRED | Mirror dividend record that generated this credit entry. Used for copy-trading dividend distribution tracking. References History.MirrorDividend. |
| 29 | MoveMoneyReasonID | int | YES | - | CODE-BACKED | Reason for a money-movement credit event. In `Billing.AmountAddBonus`, `@MoveMoneyReasonID` is passed through (added in Case 34113). Categorizes internal balance transfers. |
| 30 | BSLRealFunds | money | YES | - | NAME-INFERRED | Real funds portion of the balance at the time of a Below-Stop-Loss (BSL) credit event. Used in BSL equity accounting to distinguish real vs bonus funds. |
| 31 | OriginalPositionID | bigint | YES | - | NAME-INFERRED | Position ID before a split, rollover, or partial close operation. Traces credit events back to their originating position. |
| 32 | SubCreditTypeID | int | YES | - | NAME-INFERRED | Sub-classification of the credit type for more granular categorization. Extends CreditTypeID for edge cases not covered by the main type. |
| 33 | DepositRollbackID | int | YES | - | NAME-INFERRED | Deposit reversal record associated with this credit. Used when a deposit is rolled back and a corresponding credit entry must record the reversal. |
| 34 | InterestMonthlyID | bigint | YES | - | NAME-INFERRED | Monthly interest payment record linked to this credit. Used for interest account credit tracking. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| CID | Customer.CustomerStatic | Implicit | Identifies the account holder whose balance is affected |
| CreditTypeID | Dictionary.CreditType | Implicit | Classifies the type of credit event |
| BonusTypeID | BackOffice.Bonus | Implicit | Links credit to the bonus category |
| CampaignID | BackOffice.Campaign | Implicit | Links credit to the marketing campaign |
| MirrorID | Trade.Mirror | Implicit | Links copy-trading credits to their mirror relationship |
| MirrorDividendID | History.MirrorDividend | Implicit | Links dividend credits to their mirror dividend record |
| PositionID | History.Position_Active | Implicit | Links position-related credits |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.AmountAddBonus | @ActiveCreditLocal | Local variable | Declared to hold in-memory credit snapshot for bonus deduplication |
| Billing.WithdrawalService_EstimateBonusDeduction | (local var) | Local variable | Used in bonus deduction estimation during withdrawal processing |
| Billing.WithdrawRequestReverse | (local var) | Local variable | Used when reversing a withdrawal to track affected credits |
| Billing.WithdrawRequestToReverse | (local var) | Local variable | Used in withdrawal reversal candidate detection |
| BackOffice.GetCustomerByCID | (local var) | Local variable | Used in customer balance retrieval to include recent in-memory credits |

---

## 6. Dependencies

### 6.0 Dependency Chain

This object has no dependencies.

### 6.1 Objects This Depends On

No dependencies.

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.AmountAddBonus | Stored Procedure | Declares local variable of this type; queries History.ActiveCreditRecentMemoryBucket for bonus dedup |
| Billing.WithdrawalService_EstimateBonusDeduction | Stored Procedure | Uses type for bonus deduction estimation at withdrawal time |
| Billing.WithdrawRequestReverse | Stored Procedure | Uses type during withdrawal reversal processing |
| Billing.WithdrawRequestToReverse | Stored Procedure | Uses type to identify reversible withdrawals |
| BackOffice.GetCustomerByCID | Stored Procedure | Uses type for customer credit snapshot retrieval |
| Customer.RAFCompensationProcess_NogaJunk210725 | Stored Procedure | Uses type in RAF compensation processing (deprecated/junk SP) |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| (unnamed PK) | NONCLUSTERED (memory-optimized) | CreditID ASC | - | - | Active |

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PRIMARY KEY on CreditID | PRIMARY KEY NONCLUSTERED | Required by SQL Server for MEMORY_OPTIMIZED table types. Ensures each credit event appears at most once in any local variable of this type. |
| MEMORY_OPTIMIZED = ON | Table Option | Enables lock-free, latch-free in-memory storage for variables of this type. Used in high-throughput bonus and balance-update procedures. |

---

## 8. Sample Queries

### 8.1 Declare and use in bonus deduplication check

```sql
DECLARE @ActiveCreditLocal AS History.[ActiveCreditRecentMemoryBucket_TYPE];

-- Check recent in-memory credits for existing bonus grant
SELECT TOP 1 1
FROM History.ActiveCreditRecentMemoryBucket WITH (NOLOCK)
WHERE CreditTypeID IN (2, 5, 7)
  AND CID = @CID
  AND BonusTypeID = @BonusTypeID
  AND CampaignID = @CampaignID;
```

### 8.2 Inspect the type definition

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON c.user_type_id = t.user_type_id
WHERE tt.schema_id = SCHEMA_ID('History')
  AND tt.name = 'ActiveCreditRecentMemoryBucket_TYPE'
ORDER BY c.column_id;
```

### 8.3 Find all procedures using this type

```sql
SELECT OBJECT_SCHEMA_NAME(o.object_id) + '.' + o.name AS ProcedureName
FROM sys.sql_modules m WITH (NOLOCK)
JOIN sys.objects o WITH (NOLOCK) ON m.object_id = o.object_id
WHERE m.definition LIKE '%ActiveCreditRecentMemoryBucket_TYPE%'
  AND o.type IN ('P', 'FN', 'IF', 'TF');
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-19 | Enriched: 2026-03-19 | Quality: 8.3/10 (Elements: 8.2/10, Logic: 9.0/10, Relationships: 8.0/10, Sources: 6.0/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 23 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 3 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.ActiveCreditRecentMemoryBucket_TYPE | Type: User Defined Type | Source: etoro/etoro/History/User Defined Types/History.ActiveCreditRecentMemoryBucket_TYPE.sql*
