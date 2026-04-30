# Trade.InterestGetDailyRawData

> Collects the daily interest eligibility snapshot for a list of customer IDs: joins Customer and BackOffice account data, reconstructs the minimum real-money balance over the 4AM-to-4AM interest window, and computes pending cashout deductions - returning one row per eligible customer for interest calculation.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ListOfCids - TVP of CIDs to compute interest data for |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InterestGetDailyRawData is the data-extraction layer of the daily interest calculation pipeline. Every night, the interest service identifies customers who may be eligible for interest payments on their uninvested cash. This procedure collects the raw inputs needed to evaluate each candidate: their current credit and realized equity, their regulatory classification (AccountTypeID, RegulationID), their minimum real-money balance during the previous 24-hour window, and the total value of pending cashout requests that reduce their eligible balance.

The procedure is designed for batch execution against a caller-provided CID list (Trade.CidList TVP). It does not determine eligibility itself - that decision is left to the calling service using the returned data. The RECOMPILE hint ensures query plans are optimized for the actual size of each batch rather than a cached estimate, which is critical because the CID list size varies significantly between runs.

The interest window is defined as 4AM previous day to 4AM current day. This convention is standard across eToro's interest, overnight fee, and end-of-week fee calculations. The minimum real-money balance (MinRealMoney = MIN(RealizedEquity - BonusCredit) in the window) is the core interest eligibility metric: interest is only paid on the minimum net-real balance held throughout the period, preventing abuse via late-day deposits.

Data flow: External interest calculation service -> Trade.InterestGetDailyRawData (this procedure) -> result set -> eligibility engine -> interest accrual records. Execute permission is granted to role `InterestEtoroRO`.

---

## 2. Business Logic

### 2.1 Time Window Initialization

**What**: The 24-hour interest calculation window is anchored to 4AM boundaries.

**Columns/Parameters Involved**: `@StartTime`, `@EndTime`

**Rules**:
- `@StartTime = DATEADD(hour, 4, DATEDIFF(DAY, 1, GETDATE()))` - 4:00AM of the previous calendar day.
- `@EndTime = DATEADD(DAY, 1, @StartTime)` - 4:00AM of the current calendar day.
- All historical activity queries use these boundaries for consistent interest period scoping.

### 2.2 Customer Data Fetch (Step 3 + Snapshot Population)

**What**: Joins the CID list against Customer.Customer then BackOffice.Customer to build the base snapshot.

**Columns/Parameters Involved**: `CID`, `GCID`, `CountryID`, `PlayerLevelID`, `AccountTypeID`, `RegulationID`, `Credit`, `RealizedEquity`, `BonusCredit`, `PlayerStatusID`

**Rules**:
- Step 1: CIDs from @ListOfCids are loaded into #ListOfCids with a clustered index on CID for join performance.
- Step 3 (#step3): INNER JOIN Customer.Customer on #ListOfCids - fetches Credit, RealizedEquity, BonusCredit, PlayerStatusID, CountryID, PlayerLevelID, GCID.
- Snapshot: INNER JOIN #step3 + BackOffice.Customer - adds AccountTypeID and RegulationID from the back office.
- Date in #Snapshot is set to CONVERT(date, @StartTime) - the snapshot date is the start of the interest window.
- Early exit: IF NOT EXISTS (SELECT 1 FROM #Snapshot) RETURN - avoids unnecessary work if no customers matched.

### 2.3 Credit Adjustment for Post-Window Payments

**What**: Subtracts payments received after 4AM (current day) from the snapshot Credit, since those payments arrived outside the interest window.

**Columns/Parameters Involved**: `#Snapshot.Credit`, `#HistoryCredit.Payment`, `#HistoryCredit.Occurred`

**Rules**:
- Source: History.ActiveCreditView - provides credit activity history with Occurred timestamps. Filtered to events after @StartTime.
- CROSS APPLY aggregates SUM(Payment) WHERE Occurred > @EndTime (post-window deposits) per CID.
- UPDATE: #Snapshot.Credit -= SumOfPayments. Ensures current Credit reflects only funds present during the interest window.

### 2.4 Minimum Real-Money Balance Computation

**What**: Calculates the minimum value of (RealizedEquity - BonusCredit) over the interest window. This is the eligibility threshold for interest.

**Columns/Parameters Involved**: `#Snapshot.MinRealMoney`, `#HistoryCredit.RealizedEquity`, `#HistoryCredit.BonusCredit`, `#HistoryCredit.Occurred`

**Rules**:
- MIN(RealizedEquity - BonusCredit) from #HistoryCredit WHERE Occurred < @EndTime, grouped by CID.
- IIF(b.MinRealMoney < 0, 0, b.MinRealMoney) - negative MinRealMoney is treated as 0 (no interest on negative balance).
- RIGHT JOIN from #Snapshot - customers with no history activity in the window get MinRealMoney = NULL (not zero), handled downstream.
- This metric prevents interest manipulation via late deposits: interest is on the minimum balance held, not the end balance.

### 2.5 Pending Cashout Request Deductions

**What**: Computes total pending cashout request amounts per customer, which are deducted from eligible balance by the calling service.

**Columns/Parameters Involved**: `#Snapshot.SumOfPendingCashoutRequests`, `History.WithdrawToFundingAction`, `Billing.Withdraw`, `Dictionary.CashoutStatus`

**Rules**:
- Two sources merged via UNION ALL in CTE `AllCashoutRecords`:
  - History.WithdrawToFundingAction (HWTFA) + Billing.Withdraw (BW): historical withdrawal/funding status records from the past 30 days (DATEADD(month, -1, ...) to @EndTime). ROW_NUMBER picks the most recent status record per (WithdrawID, FundingID) pair.
  - Billing.Withdraw (BW) with CashoutStatusID=1: directly pending withdrawals (not yet processed through action history). RequestDate < @EndTime scopes to the window.
- Filter: Dictionary.CashoutStatus.IsFinalStatus = 0 OR NULL - only non-final (pending) cashout statuses are summed.
- ABS(SUM(Amount)) - amounts may be stored as negative; ABS normalizes to positive deduction.
- UPDATE: #Snapshot.SumOfPendingCashoutRequests = computed deduction per CID.

**Diagram**:
```
@ListOfCids (TVP)
    |
    v
#ListOfCids (temp, clustered index on CID)
    |
    v
Customer.Customer JOIN #ListOfCids
    -> #step3 (CID, GCID, CountryID, PlayerLevelID, Credit, RealizedEquity, BonusCredit, PlayerStatusID)
    |
    v
#step3 JOIN BackOffice.Customer
    -> #Snapshot (+ AccountTypeID, RegulationID, Date=@StartTime)
    |
    +-- IF #Snapshot empty -> RETURN (early exit)
    |
    v
History.ActiveCreditView WHERE Occurred > @StartTime
    -> #HistoryCredit (CID, Credit, RealizedEquity, BonusCredit, Payment, Occurred)
    |
    v
UPDATE #Snapshot.Credit -= SUM(Payment) WHERE Occurred > @EndTime
    (remove post-window deposits from current credit)
    |
    v
UPDATE #Snapshot.MinRealMoney = MAX(0, MIN(RealizedEquity-BonusCredit)) WHERE Occurred < @EndTime
    (minimum real money in window - core interest eligibility metric)
    |
    v
CTE AllCashoutRecords (History.WithdrawToFundingAction + Billing.Withdraw)
    -> UPDATE #Snapshot.SumOfPendingCashoutRequests = ABS(SUM non-final cashouts)
    |
    v
SELECT * FROM #Snapshot
```

### 2.6 Error Handling

**What**: Modern TRY/CATCH pattern with THROW for complete error propagation.

**Rules**:
- Full TRY/CATCH wraps all logic.
- BEGIN CATCH: THROW - re-raises the original exception with full details to the caller.
- No error swallowing - any failure propagates to the interest calculation service for alerting.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ListOfCids | Trade.CidList READONLY | NO | - | CODE-BACKED | Input TVP. List of CIDs (customer IDs) to fetch interest data for. Must be non-null; empty list produces an empty result set via early exit. |
| RS.1 | CID | int | NO | - | CODE-BACKED | Output. Customer ID. Primary key of the result set. FK to Customer.Customer. |
| RS.2 | GCID | int | YES | - | CODE-BACKED | Output. Group Customer ID. Groups related customer accounts (e.g., demo + real). From Customer.Customer. |
| RS.3 | Date | date | NO | - | CODE-BACKED | Output. The interest calculation date - set to @StartTime (4AM of previous day, date portion). All rows in a single execution share the same Date value. |
| RS.4 | CountryID | int | YES | - | CODE-BACKED | Output. Customer's country of residence. From Customer.Customer. FK to Dictionary.Country. Determines regulatory jurisdiction for interest eligibility. |
| RS.5 | PlayerLevelID | int | YES | - | CODE-BACKED | Output. Customer tier/VIP level. From Customer.Customer. May affect interest rate or eligibility thresholds. |
| RS.6 | AccountTypeID | int | YES | - | CODE-BACKED | Output. Account type (real/demo/professional). From BackOffice.Customer. FK to Dictionary.AccountType. Interest applies only to real accounts. |
| RS.7 | RegulationID | int | YES | - | CODE-BACKED | Output. Regulatory regime applicable to this customer. From BackOffice.Customer. FK to Dictionary.Regulation. Determines which interest rules apply. |
| RS.8 | Credit | money | YES | - | CODE-BACKED | Output. Customer's current credit balance, adjusted to remove post-window (>4AM today) payments. Represents funds available at the end of the interest window. |
| RS.9 | RealizedEquity | money | YES | - | CODE-BACKED | Output. Realized equity at snapshot time. From Customer.Customer. Base component of MinRealMoney calculation. |
| RS.10 | Bonus | money | YES | - | CODE-BACKED | Output. Bonus credit (BonusCredit from Customer.Customer). Non-real money component subtracted from RealizedEquity to compute MinRealMoney. |
| RS.11 | MinRealMoney | money | YES | - | CODE-BACKED | Output. Minimum value of (RealizedEquity - BonusCredit) over the interest window. Zero-floored (negative values become 0). Core interest eligibility metric - interest is calculated on this minimum balance. NULL if customer had no activity in the window. |
| RS.12 | SumOfPendingCashoutRequests | money | YES | - | CODE-BACKED | Output. Total pending cashout amount (non-final status) from the past 30 days. Deducted from Credit by the calling service to compute the net eligible balance. ABS value (always positive). |
| RS.13 | PlayerStatusID | int | YES | - | CODE-BACKED | Output. Customer account status (active, suspended, etc.). From Customer.Customer. Used downstream to filter ineligible accounts. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN (step3) | Customer.Customer | Reader | Fetches Credit, RealizedEquity, BonusCredit, GCID, CountryID, PlayerLevelID, PlayerStatusID for input CIDs |
| JOIN (snapshot) | BackOffice.Customer | Reader | Fetches AccountTypeID and RegulationID to classify accounts by type and regulatory regime |
| JOIN | History.ActiveCreditView | Reader | Provides credit activity history for the interest window (credit, equity, payment events by timestamp) |
| JOIN | History.WithdrawToFundingAction | Reader | Provides historical withdrawal-to-funding status records for pending cashout computation |
| JOIN | Billing.Withdraw | Reader | Provides pending withdrawal records (CashoutStatusID=1) and joins to History.WithdrawToFundingAction |
| JOIN | Dictionary.CashoutStatus | Reader | IsFinalStatus flag used to filter out completed cashout statuses from the pending sum |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by the interest calculation service via `InterestEtoroRO` role. Also see `Trade.InterestGetDailyRawDataHistorical` and `Trade.InterestGetDailyRawDataNEWELAD` for related variants.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestGetDailyRawData (procedure)
├── Trade.CidList (TVP type) - input parameter type
├── Customer.Customer (table) - primary customer data source
├── BackOffice.Customer (table) - account type and regulation
├── History.ActiveCreditView (view) - credit activity history
├── History.WithdrawToFundingAction (table) - withdrawal status history
├── Billing.Withdraw (table) - pending withdrawal records
└── Dictionary.CashoutStatus (table) - IsFinalStatus classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User Defined Table Type | Input parameter type for @ListOfCids TVP |
| Customer.Customer | Table | Base customer data: Credit, RealizedEquity, BonusCredit, CountryID, PlayerLevelID, GCID, PlayerStatusID |
| BackOffice.Customer | Table | Account classification: AccountTypeID, RegulationID |
| History.ActiveCreditView | View | Credit activity history for the interest window; used to adjust Credit and compute MinRealMoney |
| History.WithdrawToFundingAction | Table | Historical cashout status transitions for pending cashout sum |
| Billing.Withdraw | Table | Direct pending withdrawal records (CashoutStatusID=1) and base for history joins |
| Dictionary.CashoutStatus | Table | IsFinalStatus flag - filters pending vs completed cashout statuses |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Interest calculation service | External (Application) | Calls via InterestEtoroRO role to fetch raw data for daily interest eligibility determination |
| Trade.InterestGetDailyRawDataHistorical | Stored Procedure | Variant of this procedure for historical recalculation |
| Trade.InterestGetDailyRawDataNEWELAD | Stored Procedure | Variant of this procedure (NEWELAD = likely new/alternate calculation branch) |
| Trade.InterestGetDailyRawDataTest | Stored Procedure | Test variant of this procedure |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces plan recompilation per execution; CID list size varies significantly, so a cached plan would be suboptimal |
| TRY/CATCH + THROW | Error handling | Modern error handling; all failures propagate to caller with full exception details |
| 4AM window convention | Business rule | @StartTime = 4AM previous day, @EndTime = 4AM current day; standard eToro interest/fee window |
| Clustered index on #ListOfCids | Performance | CID lookup in INNER JOINs uses clustered index for O(log n) seek |
| Clustered index on #HistoryCredit(CID, Occurred) | Performance | Required for efficient credit adjustment and MinRealMoney queries that filter by CID and Occurred |
| Early exit on empty #Snapshot | Guard | IF NOT EXISTS (#Snapshot) RETURN - prevents expensive downstream queries when no customers matched |
| Zero-floor on MinRealMoney | Business rule | IIF(MinRealMoney < 0, 0, MinRealMoney) - negative min balance treated as zero; no negative-interest scenarios |
| 30-day cashout lookback | Business rule | Pending cashouts from up to 1 month ago are counted as pending deductions |
| Execute permission | Security | GRANT EXECUTE ON Trade.InterestGetDailyRawData TO InterestEtoroRO |

---

## 8. Sample Queries

### 8.1 Execute for a batch of CIDs

```sql
DECLARE @CidList Trade.CidList;
INSERT INTO @CidList (CID) VALUES (1001), (1002), (1003);

EXEC Trade.InterestGetDailyRawData @ListOfCids = @CidList;
```

### 8.2 Check what the current 4AM window boundaries would be

```sql
DECLARE @StartTime DATETIME = DATEADD(hour, 4, DATEDIFF(DAY, 1, GETDATE()));
DECLARE @EndTime DATETIME = DATEADD(DAY, 1, @StartTime);
SELECT @StartTime AS WindowStart, @EndTime AS WindowEnd;
```

### 8.3 Preview customer eligibility data directly (without calling the proc)

```sql
SELECT
    c.CID,
    c.GCID,
    bo.AccountTypeID,
    bo.RegulationID,
    c.Credit,
    c.RealizedEquity,
    c.BonusCredit,
    c.PlayerStatusID
FROM Customer.Customer c WITH (NOLOCK)
JOIN BackOffice.Customer bo WITH (NOLOCK) ON bo.CID = c.CID
WHERE c.CID IN (1001, 1002, 1003);
```

---

## 9. Atlassian Knowledge Sources

Confluence search found a related page titled "Payments in Non-USD - Overnight Fees, Dividends, Interest" (ID: 14039384103, TRAD space) but the page was not accessible (404). This title suggests overnight fee and interest documentation may exist but is restricted.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 1 Confluence (not accessible) + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestGetDailyRawData | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InterestGetDailyRawData.sql*
