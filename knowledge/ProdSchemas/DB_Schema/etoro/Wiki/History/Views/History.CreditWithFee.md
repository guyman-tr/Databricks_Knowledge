# History.CreditWithFee

> Full-history credit ledger including all fee-type events (identical to History.Credit) - a legacy alias retained because AccountStatement and BackOffice procedures reference this name to explicitly signal that fee-type credit events (cashout fees, weekly fees) are included in the result set.

| Property | Value |
|----------|-------|
| **Schema** | History |
| **Object Type** | View |
| **Key Identifier** | CreditID (bigint, from History.Credit) |
| **Partition** | N/A (view - inherits from History.Credit's 78-source UNION ALL) |
| **Indexes** | N/A (view - base table indexes used per branch) |

---

## 1. Business Meaning

`History.CreditWithFee` is a direct passthrough view over `History.Credit` - the definition is exactly `SELECT * FROM History.Credit`. It exposes every financial event in eToro's complete history (2007 to present): deposits, cashouts, position opens/closes, bonuses, mirror operations, stock orders, fees, compensation, and data fixes. All 35 columns of History.Credit are exposed unchanged.

This view exists as a named alias to serve consumers that need to make explicit in their code that fee-type credit events are intentionally included. Fee-related credit types are CreditTypeID 14 (End Of Week Fee) and 15 (Cashout Fee). By querying `History.CreditWithFee`, calling procedures signal their intent to include these fee events - historically useful when there may have been a `History.Credit` variant that filtered them out. Today both views return identical data.

Consumers are primarily AccountStatement report procedures (which generate customer-facing account statements) and BackOffice tax/activity reports. These consumers need the complete credit event ledger - including fees - to accurately compute tax-reportable totals, transaction summaries, and account statement line items.

---

## 2. Business Logic

### 2.1 Identity Passthrough - No Filtering or Transformation

**What**: This view adds no logic - it is a verbatim SELECT * alias for History.Credit.

**Columns/Parameters Involved**: All 35 columns (see Section 4)

**Rules**:
- Every row returned by `History.CreditWithFee` is also in `History.Credit` and vice versa
- No WHERE clause, no column transformation, no computed columns
- UNION ALL architecture of 78 sources is inherited from History.Credit
- Archive schema normalization (NULL backfills for newer columns) is inherited from History.Credit
- CreditID CAST to bigint is inherited from History.Credit

**Diagram**:
```
History.CreditWithFee (SELECT * FROM ...)
    |
    +--> History.Credit (UNION ALL of 78 branches)
            |--> History.ActiveCredit (2021+ current data)
            |       +--> History.ActiveCredit_BIGINT (partitioned table)
            |--> dbo.Credit_2007 (archive)
            |--> dbo.Credit_2008 (archive)
            |--> ... (75 more archive tables)
            +--> dbo.Credit_2022Q1 (most recent archive)
```

### 2.2 Fee-Inclusion Semantic

**What**: The "WithFee" name encodes an intent declaration - the caller explicitly includes fee-type credit events.

**Columns/Parameters Involved**: `CreditTypeID`

**Rules**:
- CreditTypeID 14 (End Of Week Fee) - weekly fee deductions; included in this view
- CreditTypeID 15 (Cashout Fee) - fees charged at the time of cashout; included
- AccountStatement consumers use this view specifically because account statements must show fees as line items alongside other transactions
- Tax report consumers need fee records for gross-vs-net fee deduction calculations

---

## 3. Data Overview

History.CreditWithFee returns the same data as History.Credit. Direct querying is blocked via MCP (cross-database access required for archive branches in EtoroArchive DB). Sample data is identical to History.Credit - see that view's documentation for representative rows.

Key data characteristics inherited from History.Credit:
- CreditID range: INT range (< 2^31) for pre-2021 archive records; bigint range (2174000000+) for recent 2021+ records
- Oldest data: ~2007 (in dbo.Credit_2007 archive)
- Newest data: current day (in History.ActiveCredit_BIGINT via History.ActiveCredit)
- 33 CreditTypeID values representing the full financial event lifecycle

| CreditTypeID | Description | Includes fee events |
|-------------|-------------|---------------------|
| 1 | Deposit | No |
| 2 | Cashout | No |
| 14 | End Of Week Fee | **YES - fee event** |
| 15 | Cashout Fee | **YES - fee event** |
| (33 types total) | Full lifecycle | All included |

---

## 4. Elements

All 35 columns are inherited unchanged from `History.Credit` (which in turn inherits from `History.ActiveCredit_BIGINT` for the current branch and the dbo.Credit_* archive tables for historical branches). See `History.Credit.md` and `History.ActiveCredit_BIGINT.md` for full business context.

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | CreditID | bigint | NO | - | CODE-BACKED | Unique identifier for this credit event. CAST to bigint in all branches of the underlying UNION ALL. INT range for pre-2021 archive rows; bigint range for 2021+ rows. (Inherited from History.Credit) |
| 2 | CID | int | NO | - | CODE-BACKED | Customer ID - the eToro account this financial event belongs to. Central filter column for account statement queries. (Inherited from History.ActiveCredit_BIGINT) |
| 3 | CreditTypeID | tinyint | NO | - | CODE-BACKED | Classification of the financial event. 33 types: 1=Deposit, 2=Cashout, 3=Open Position, 4=Close Position, 5=Champ Winner, 6=Compensation, 7=Bonus, 8=Reverse cashout, 9=Cashout request, 10=IB sync, 11=Chargeback, 12=Refund, 13=Edit Stop Loss, 14=End Of Week Fee, 15=Cashout Fee, 16=Refund As ChargeBack, 17=FixHistoryCreditChargeBacks, 18=Account balance to mirror, 19=Mirror balance to account, 20=Register new mirror, 21=Unregister mirror, 22=Mirror Hierarchical Close, 23=Hierarchical Open, 24=Close by recovery, 25=Open by recovery, 26=FixBonusCreditRealizedEquity, 27=Detach from mirror, 28=Detach Stock From Mirror, 29=Open Stock Order, 30=Close Stock Order, 31=Data Fix, 32=Reverse Deposit, 33=Cashout Rollback. (Source: Dictionary.CreditType) |
| 4 | PositionID | bigint | YES | - | CODE-BACKED | Linked trade position for position-related types (3, 4, 13, 22-27). NULL for deposits, cashouts, bonuses, fees. |
| 5 | ChampionshipID | int | YES | - | CODE-BACKED | Linked championship for type 5 (Champ Winner). NULL for non-championship events. |
| 6 | CashoutID | int | YES | - | CODE-BACKED | Linked cashout transaction for types 2, 8, 33. Ties to Billing cashout record. NULL otherwise. |
| 7 | PaymentID | int | YES | - | CODE-BACKED | Linked billing payment for types 9, 11, 12, 15, 16. NULL for non-payment events. |
| 8 | WithdrawID | int | YES | - | CODE-BACKED | Linked withdrawal record for types 2, 9, 15. Optimised with filtered index on the base table. NULL for non-cashout events. |
| 9 | DepositID | int | YES | - | CODE-BACKED | Linked deposit transaction for types 1, 12, 32. NULL for non-deposit events. |
| 10 | UpdateID | int | YES | - | NAME-INFERRED | Reference to a generic update operation that triggered this credit event. NULL in most records. |
| 11 | CampaignID | int | YES | - | CODE-BACKED | Linked marketing campaign for bonus type (7). Identifies the promotion that awarded the bonus. NULL for non-campaign events. |
| 12 | BonusTypeID | int | YES | - | CODE-BACKED | Bonus sub-classification for type 7. Application-managed values. NULL for non-bonus events. |
| 13 | CompensationReasonID | int | YES | - | CODE-BACKED | Reason for manual compensation (type 6). Identifies the cause (technical error, goodwill, etc.). NULL for non-compensation events. |
| 14 | ManagerID | int | YES | - | CODE-BACKED | Back-office agent who authorised this event (primarily compensation and manual operations). NULL for system-generated events. |
| 15 | Credit | money | NO | - | VERIFIED | Customer's total credit balance after this event (running total). The new account balance in monetary units. |
| 16 | Payment | money | NO | - | VERIFIED | Signed transaction amount: positive for inflows (deposits, bonuses, profits), negative for outflows (cashouts, fees, losses). Payment = new Credit - previous Credit. |
| 17 | Description | varchar(255) | YES | - | CODE-BACKED | Free-text event description. Often empty for system-generated events; used for manual entries and compensation notes. |
| 18 | Occurred | datetime | NO | GETUTCDATE() | VERIFIED | UTC timestamp when this credit event was recorded. Primary date filter for account statement date range queries. |
| 19 | WithdrawProcessingID | int | YES | - | CODE-BACKED | Links to the withdrawal processing batch for cashout-related events. Part of DWH covering index. |
| 20 | MirrorID | int | NO | 0 | CODE-BACKED | Linked copy-trade portfolio for mirror-related types (18-23, 27-28). Default = 0 (no mirror). |
| 21 | TotalCash | money | YES | - | CODE-BACKED | Total liquid cash component after this event. Distinct from BonusCredit and MirrorCash. NULL for older archive records. |
| 22 | TotalCashChange | money | YES | - | CODE-BACKED | Delta of TotalCash caused by this event. Used in billing reporting queries via covering index. |
| 23 | BonusCredit | money | YES | - | CODE-BACKED | Non-withdrawable bonus portion of the Credit balance. Subject to trading conditions before conversion to real credit. NULL if no bonus component. |
| 24 | RealizedEquity | money | YES | - | CODE-BACKED | Equity realised from closed positions at this point. NULL for event types not affecting realised equity. |
| 25 | MirrorCash | dbo.dtPrice | YES | - | CODE-BACKED | Cash allocated to copy-trade portfolios. NULL if no mirror allocation. |
| 26 | StocksOrderID | int | YES | - | CODE-BACKED | Linked stock order for types 29, 30, 28. NULL for non-stock events. |
| 27 | MirrorEquity | money | YES | - | CODE-BACKED | Unrealised equity in copy-trade portfolios. Complements MirrorCash for full portfolio valuation. NULL in archive branches. |
| 28 | MirrorDividendID | int | YES | - | CODE-BACKED | Linked mirror dividend record. NULL in all archive branches (column added after archives created). |
| 29 | MoveMoneyReasonID | int | YES | - | CODE-BACKED | Reason for manual money movement. FK to Dictionary.MoveMoneyReason: 1=Adjustment, 2=Bonus Abuser, 3=Staking, 5=InternalTransfer Trade, 6=InternalTransfer. NULL in archive branches. |
| 30 | BSLRealFunds | money | YES | - | CODE-BACKED | Balance Sheet Ledger real funds component for regulatory reporting. NULL in archive branches. |
| 31 | OriginalPositionID | bigint | YES | - | CODE-BACKED | Position ID before any reassignment (recovery types 24, 25, 31). In the active branch: ISNULL(OriginalPositionID, PositionID). In all archive branches: PositionID (column didn't exist). |
| 32 | SubCreditTypeID | int | YES | - | NAME-INFERRED | Sub-classification within CreditTypeID. Application-managed values. NULL in archive branches and most live records. |
| 33 | PartitionCol | int | YES | - | CODE-BACKED | Partition routing key from the active branch (CreditID % 10). NULL in all archive branches (computed column not present in archive tables). |
| 34 | DepositRollbackID | int | YES | - | CODE-BACKED | Links to the deposit being reversed (type 32=Reverse Deposit). NULL in archive branches. |
| 35 | InterestMonthlyID | bigint | YES | - | NAME-INFERRED | Reference to a monthly interest payment record. NULL in archive branches. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| (entire view) | History.Credit | View dependency | Direct SELECT * wrapper - all rows and columns from History.Credit |
| CreditTypeID | Dictionary.CreditType | Implicit (inherited) | 33 credit event types including fee types 14 and 15 |
| CID | Customer.Customer | Implicit (inherited) | Every row belongs to a customer account |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| dbo.AccountStatement_GetTransactionsReport | CreditWithFee | Reader | Customer account statement transaction history (all versions: main, v1, v1p, OLD) |
| dbo.AccountStatement_GetUserStatementSummary | CreditWithFee | Reader | Account statement summary totals (v1, v2) |
| dbo.AccountStatement_BPGetTransactions_v1 | CreditWithFee | Reader | BP (Business Partner) account statement transactions |
| dbo.AccountStatement_GetInterest_v1 | CreditWithFee | Reader | Interest calculation report reading credit history |
| BackOffice.AccountStatement_GetTaxReport_v1/v2/v3 | CreditWithFee | Reader | Tax reporting procedures requiring full credit history including fees |
| BackOffice.GetActivityList | CreditWithFee | Reader | Back-office customer activity list |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
History.CreditWithFee (view)
└── History.Credit (view)
      |--> History.ActiveCredit (view)
      |       └── History.ActiveCredit_BIGINT (table - partitioned, 10 buckets)
      |--> dbo.Credit_2007 (table)
      |--> dbo.Credit_2008 (table)
      |--> ... (75 more dbo.Credit_* archive tables)
      └── dbo.Credit_2022Q1 (table)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| History.Credit | View | Direct SELECT * source - provides the full 35-column UNION ALL credit history |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| dbo.AccountStatement_GetTransactionsReport | Stored Procedure | Reader - customer transaction history statements |
| dbo.AccountStatement_GetTransactionsReport_v1 | Stored Procedure | Reader - v1 variant |
| dbo.AccountStatement_GetTransactionsReport_v1p | Stored Procedure | Reader - v1p variant |
| dbo.AccountStatement_GetTransactionsReport_OLD | Stored Procedure | Reader - legacy variant |
| dbo.AccountStatement_GetUserStatementSummary | Stored Procedure | Reader - account summary |
| dbo.AccountStatement_GetUserStatementSummary_v1 | Stored Procedure | Reader - v1 variant |
| dbo.AccountStatement_GetUserStatementSummary_v2 | Stored Procedure | Reader - v2 variant |
| dbo.AccountStatement_BPGetTransactions_v1 | Stored Procedure | Reader - BP transactions |
| dbo.AccountStatement_GetInterest_v1 | Stored Procedure | Reader - interest report |
| BackOffice.AccountStatement_GetTaxReport_v1 | Stored Procedure | Reader - tax report v1 |
| BackOffice.AccountStatement_GetTaxReport_v2 | Stored Procedure | Reader - tax report v2 |
| BackOffice.AccountStatement_GetTaxReport_v2_withDBLogs | Stored Procedure | Reader - tax report v2 with DB logs |
| BackOffice.AccountStatement_GetTaxReport_v3 | Stored Procedure | Reader - tax report v3 |
| BackOffice.GetActivityList | Stored Procedure | Reader - customer activity list |

---

## 7. Technical Details

### 7.1 Indexes

N/A for View. Performance depends entirely on the indexes of the underlying History.ActiveCredit_BIGINT (for current data) and the individual dbo.Credit_* archive tables (for historical data). Always filter by CID and/or date range to avoid cross-branch full scans.

### 7.2 Constraints

N/A for View.

---

## 8. Sample Queries

### 8.1 Get full credit history including fees for a customer

```sql
SELECT
    cwf.CreditID,
    cwf.CreditTypeID,
    cwf.Credit,
    cwf.Payment,
    cwf.PositionID,
    cwf.DepositID,
    cwf.WithdrawID,
    cwf.Occurred
FROM History.CreditWithFee cwf WITH (NOLOCK)
WHERE cwf.CID = 14952810
ORDER BY cwf.Occurred DESC
```

### 8.2 Get only fee events for a customer (the key use case for this view)

```sql
-- Retrieve fee-type credit events (the events that distinguish CreditWithFee from a fee-free variant)
SELECT
    cwf.CreditID,
    cwf.CreditTypeID,
    cwf.Payment AS FeeAmount,
    cwf.Occurred
FROM History.CreditWithFee cwf WITH (NOLOCK)
WHERE cwf.CID = 14952810
  AND cwf.CreditTypeID IN (14, 15)  -- 14=End Of Week Fee, 15=Cashout Fee
ORDER BY cwf.Occurred DESC
```

### 8.3 Account statement summary - deposits, cashouts, and fees for a date range

```sql
-- Pattern used by AccountStatement_GetUserStatementSummary procedures
SELECT
    cwf.CreditTypeID,
    COUNT(*) AS EventCount,
    SUM(cwf.Payment) AS TotalAmount
FROM History.CreditWithFee cwf WITH (NOLOCK)
WHERE cwf.CID = 14952810
  AND cwf.Occurred BETWEEN '2025-01-01' AND '2025-12-31'
  AND cwf.CreditTypeID IN (1, 2, 9, 14, 15)  -- Deposit, Cashout, CashoutReq, Fees
GROUP BY cwf.CreditTypeID
ORDER BY cwf.CreditTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-21 | Enriched: 2026-03-21 | Quality: 8.9/10 (Elements: 8.6/10, Logic: 9.0/10, Relationships: 9.5/10, Sources: 8.0/10)*
*Confidence: 0 EXPERT, 2 VERIFIED, 29 CODE-BACKED, 0 ATLASSIAN-ONLY, 4 NAME-INFERRED | Phases: 5/5 (1, 5, 7, 8, 11) applied*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 14 consumers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: History.CreditWithFee | Type: View | Source: etoro/etoro/History/Views/History.CreditWithFee.sql*
