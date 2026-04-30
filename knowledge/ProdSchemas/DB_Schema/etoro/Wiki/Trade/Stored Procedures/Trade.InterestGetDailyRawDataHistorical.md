# Trade.InterestGetDailyRawDataHistorical

> Historical variant of Trade.InterestGetDailyRawData: collects the daily interest eligibility snapshot for a specified historical date, reconstructing point-in-time credit balances from History.ActiveCredit rather than using current Customer.Customer values.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @ListOfCids + @DateOfInterest - CID list and target historical date |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.InterestGetDailyRawDataHistorical is the historical recalculation variant of Trade.InterestGetDailyRawData. While the daily procedure always calculates interest data for yesterday's window, this variant accepts a `@DateOfInterest` parameter and reconstructs what the interest snapshot would have looked like on any past date.

This is used for audits, retroactive corrections, regulatory reporting, and debugging interest discrepancies. The critical distinction is that credit balances are sourced from `History.ActiveCredit` (the underlying credit history table) using a point-in-time OUTER APPLY lookup, rather than reading current values from Customer.Customer. This means the procedure accurately reflects the customer's balance as it existed at 4AM on the target date, not as it exists now.

The output schema is identical to Trade.InterestGetDailyRawData, allowing the same downstream interest eligibility logic to be applied without modification. Execute permission is granted to role `InterestEtoroRO`.

Data flow: Audit or recalculation service -> Trade.InterestGetDailyRawDataHistorical(@ListOfCids, @DateOfInterest) -> same result schema as daily variant -> historical interest amount computation.

---

## 2. Business Logic

### 2.1 Historical Time Window

**What**: The 4AM window boundaries are computed from the caller-supplied @DateOfInterest rather than yesterday.

**Columns/Parameters Involved**: `@DateOfInterest`, `@StartTime`, `@EndTime`

**Rules**:
- `@StartTime = DATEADD(HOUR, 4, CONVERT(DATETIME, @DateOfInterest))` - 4:00AM of the specified date.
- `@EndTime = DATEADD(DAY, 1, @StartTime)` - 4:00AM of the day after @DateOfInterest.
- Caller provides any past date; the 4AM offset is applied automatically.

### 2.2 Point-in-Time Credit Reconstruction

**What**: Reconstructs the credit state as it existed at @StartTime using History.ActiveCredit (the raw history table, not a view).

**Columns/Parameters Involved**: `#HistoryCreditBefore1`, `History.ActiveCredit`, `@StartTime`

**Rules**:
- OUTER APPLY with TOP 1 ... ORDER BY Occurred DESC per CID: fetches the most recent credit, realized equity, and bonus credit record from History.ActiveCredit WHERE Occurred <= @StartTime.
- This gives the exact account state at the start of the historical interest window.
- OUTER APPLY (not INNER): if no history record exists before @StartTime, the row is NULL (customer had no credit history before that date - treated as zero balance).
- Result in #HistoryCreditBefore1 (CID, Credit, RealizedEquity, BonusCredit).
- #Snapshot is then populated using historical values from #HistoryCreditBefore1 (LEFT JOIN), NOT from Customer.Customer's current Credit/RealizedEquity/BonusCredit.

**Difference from non-historical variant**: Trade.InterestGetDailyRawData uses current Customer.Customer.Credit directly. This variant reconstructs historical credit from History.ActiveCredit to accurately reflect past state.

### 2.3 Customer and Account Data (Step 3 + Snapshot)

**What**: Joins CID list to current Customer and BackOffice data for non-financial attributes, then combines with historical credit.

**Rules**:
- #step3: INNER JOIN Customer.Customer + #ListOfCids (same as daily variant) - fetches GCID, CountryID, PlayerLevelID, PlayerStatusID. Note: current values are used for these fields even in historical mode, as they are demographic attributes rather than financial balances.
- #Snapshot INSERT: joins #step3 + BackOffice.Customer (AccountTypeID, RegulationID) + LEFT JOIN #HistoryCreditBefore1 (historical Credit, RealizedEquity, BonusCredit).
- Early exit: IF NOT EXISTS (#Snapshot) RETURN.

### 2.4 Historical Credit Activity Window

**What**: Fetches credit activity events BETWEEN @StartTime AND @EndTime from History.ActiveCredit.

**Rules**:
- Source: `History.ActiveCredit` (direct table, not History.ActiveCreditView used in daily variant).
- Filter: BETWEEN @StartTime AND @EndTime (inclusive) - captures all credit events in the 24-hour historical window.
- Used to: (a) adjust Credit for post-window payments, and (b) compute MinRealMoney.
- Clustered index on (CID, Occurred) for efficient window queries.

### 2.5 Credit Adjustment, MinRealMoney, and Pending Cashouts

**What**: Identical logic to Trade.InterestGetDailyRawData with the same time-based formulas.

**Rules**:
- Credit adjustment: subtract SUM(Payment) WHERE Occurred > @EndTime from #Snapshot.Credit.
- MinRealMoney: MIN(RealizedEquity - BonusCredit) WHERE Occurred < @EndTime, zero-floored.
- Pending cashout CTE: same AllCashoutRecords logic (History.WithdrawToFundingAction + Billing.Withdraw, 30-day lookback, IsFinalStatus filter).
- Final SELECT: SELECT * FROM #Snapshot - identical output schema.

### 2.6 Error Handling

**What**: No TRY/CATCH block - errors propagate natively.

**Rules**:
- Unlike Trade.InterestGetDailyRawData (which uses TRY/CATCH + THROW), this procedure has no explicit error handling.
- SQL errors propagate to the caller as unhandled exceptions.
- This is a known inconsistency between the daily and historical variants.

**Diagram**:
```
@ListOfCids (TVP) + @DateOfInterest (DateTime)
    |
    v
@StartTime = 4AM of @DateOfInterest
@EndTime = 4AM of (@DateOfInterest + 1 day)
    |
    v
#ListOfCids (temp, clustered index on CID)
    |
    v
History.ActiveCredit OUTER APPLY TOP 1 WHERE Occurred <= @StartTime
    -> #HistoryCreditBefore1 (point-in-time credit state)
    |
    v
Customer.Customer JOIN #ListOfCids -> #step3
    |
    v
#step3 + BackOffice.Customer + LEFT JOIN #HistoryCreditBefore1
    -> #Snapshot (historical credit values, current demographic attributes)
    |
    +-- IF #Snapshot empty -> RETURN
    |
    v
History.ActiveCredit WHERE Occurred BETWEEN @StartTime AND @EndTime
    -> #HistoryCredit
    |
    v
UPDATE Credit, MinRealMoney, SumOfPendingCashoutRequests (same as daily variant)
    |
    v
SELECT * FROM #Snapshot
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ListOfCids | Trade.CidList READONLY | NO | - | CODE-BACKED | Input TVP. List of CIDs to compute historical interest data for. Same type as Trade.InterestGetDailyRawData. |
| 2 | @DateOfInterest | DateTime | NO | - | CODE-BACKED | Input. The historical date for which to reconstruct the interest snapshot. 4AM of this date becomes @StartTime. Allows recalculation of any past interest period. |
| RS.1-13 | (same columns as Trade.InterestGetDailyRawData) | - | - | CODE-BACKED | Output schema is identical: CID, GCID, Date, CountryID, PlayerLevelID, AccountTypeID, RegulationID, Credit, RealizedEquity, Bonus, MinRealMoney, SumOfPendingCashoutRequests, PlayerStatusID. See Trade.InterestGetDailyRawData for column descriptions. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| OUTER APPLY (point-in-time) | History.ActiveCredit | Reader | Reconstructs credit state at @StartTime using the most recent history record before the window start |
| JOIN (step3) | Customer.Customer | Reader | Fetches demographic attributes (CountryID, PlayerLevelID, GCID, PlayerStatusID) - current values used even for historical runs |
| JOIN (snapshot) | BackOffice.Customer | Reader | AccountTypeID and RegulationID for account classification |
| JOIN | History.ActiveCredit | Reader | Window activity (BETWEEN @StartTime AND @EndTime) for credit adjustment and MinRealMoney calculation |
| JOIN | History.WithdrawToFundingAction | Reader | Historical cashout status records for pending cashout sum |
| JOIN | Billing.Withdraw | Reader | Pending withdrawal records for cashout deduction |
| JOIN | Dictionary.CashoutStatus | Reader | IsFinalStatus flag for pending vs completed cashout filter |

### 5.2 Referenced By (other objects point to this)

Not discovered in SQL codebase. Called by the interest audit/recalculation service via `InterestEtoroRO` role.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.InterestGetDailyRawDataHistorical (procedure)
├── Trade.CidList (TVP type) - input parameter type
├── History.ActiveCredit (table) - point-in-time credit reconstruction + window activity
├── Customer.Customer (table) - demographic attributes
├── BackOffice.Customer (table) - account type and regulation
├── History.WithdrawToFundingAction (table) - cashout status history
├── Billing.Withdraw (table) - pending withdrawals
└── Dictionary.CashoutStatus (table) - IsFinalStatus classification
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.CidList | User Defined Table Type | Input parameter type for @ListOfCids TVP |
| History.ActiveCredit | Table | Point-in-time credit state (OUTER APPLY TOP 1 <= @StartTime) + window activity (BETWEEN @StartTime AND @EndTime). Uses direct table, not ActiveCreditView. |
| Customer.Customer | Table | Demographic attributes (CountryID, PlayerLevelID, GCID, PlayerStatusID) - current values |
| BackOffice.Customer | Table | AccountTypeID and RegulationID |
| History.WithdrawToFundingAction | Table | Cashout status transition history for pending sum |
| Billing.Withdraw | Table | Pending withdrawal records |
| Dictionary.CashoutStatus | Table | IsFinalStatus for pending cashout filter |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Interest audit/recalculation service | External (Application) | Calls via InterestEtoroRO for historical interest computation |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| WITH RECOMPILE | Performance | Forces plan recompilation per execution; batch size varies |
| No TRY/CATCH | Design gap | Unlike the daily variant, no error handling; errors propagate natively to caller |
| History.ActiveCredit vs ActiveCreditView | Key difference | Uses the raw history table directly (not the view used in daily variant) for both point-in-time and window queries |
| OUTER APPLY (not INNER) | Design | Customers with no history before @DateOfInterest get NULL credit in snapshot rather than being excluded |
| Same output schema as daily variant | Design | Enables same downstream eligibility logic for historical and current runs |
| Execute permission | Security | GRANT EXECUTE ON Trade.InterestGetDailyRawDataHistorical TO InterestEtoroRO |

---

## 8. Sample Queries

### 8.1 Compute historical interest data for a specific date

```sql
DECLARE @CidList Trade.CidList;
INSERT INTO @CidList (CID) VALUES (1001), (1002), (1003);

EXEC Trade.InterestGetDailyRawDataHistorical
    @ListOfCids     = @CidList,
    @DateOfInterest = '2026-01-15'; -- reconstructs 4AM 2026-01-15 to 4AM 2026-01-16 window
```

### 8.2 Check point-in-time credit for a customer

```sql
-- What this proc does internally for point-in-time credit reconstruction:
SELECT TOP 1 Credit, RealizedEquity, BonusCredit
FROM History.ActiveCredit WITH (NOLOCK)
WHERE CID = 1001
  AND Occurred <= DATEADD(HOUR, 4, CONVERT(DATETIME, '2026-01-15'))
ORDER BY Occurred DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: - | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 7/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 13 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/5*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.InterestGetDailyRawDataHistorical | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.InterestGetDailyRawDataHistorical.sql*
