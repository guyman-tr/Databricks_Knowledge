# Trade.GetInterestDaily_for_Azure

> Calculates daily interest accrual for Diamond and Platinum+ customers by iterating day-by-day over a date range, tracking credit changes, pending cashouts, and applying yearly interest percentages.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Daily interest calculation loop writing to Trade.Syn_InterestDaily_July |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetInterestDaily_for_Azure is a batch calculation procedure that computes daily interest for eligible high-tier customers (Diamond and Platinum+ player levels 6, 7). It processes a date range day-by-day, performing these steps each day:

1. **Customer eligibility**: Filters to PlayerLevelID 6/7 (or whitelist overrides), where PlayerStatus.GetsInterest = 1, excluding country 250 and employee/fund account types (7,8,9,10,11,13)
2. **Credit snapshot**: For each day, finds the last credit change from History.ActiveCredit and records Credit, RealizedEquity, BonusCredit
3. **Gap filling**: If no credit change occurred that day, carries forward the previous day's values
4. **Pending cashouts**: Sums open withdrawal requests (CreditTypeID 9,15) that haven't been closed (CreditTypeID 2,8) by that day's end
5. **Interest calculation**: FundsForInterest = Credit - BonusCredit + ABS(SumOfPendingCashoutRequests), then DailyInterest = FundsForInterest * (YearlyPercentage / 36500) if positive

Results are written to `Trade.Syn_InterestDaily_July` (a staging/synth table). The interest day boundary starts at 04:00 UTC (likely aligned with end-of-day processing).

---

## 2. Business Logic

### 2.1 Customer Eligibility

**What**: Identifies customers who qualify for daily interest.

**Rules**:
- PlayerLevelID IN (6, 7) directly or via Trade.InterestWhitelist override
- PlayerStatus must have GetsInterest = 1
- Country 250 excluded (likely a regulatory exclusion)
- AccountTypeID NOT IN (7,8,9,10,11,13) - excludes employee and fund accounts

### 2.2 Interest Rate Tiers (Hardcoded)

**What**: Yearly interest percentages by player level.

**Rules**:
- PlayerLevelID 7 (Diamond): 1.8% yearly
- PlayerLevelID 6 (Platinum+): 1.8% yearly
- Rates are hardcoded in the procedure via table variable, not read from configuration

### 2.3 Funds for Interest Calculation

**What**: Determines the base amount that earns interest.

**Columns/Parameters Involved**: `Credit`, `BonusCredit`, `SumOfPendingCashoutRequests`

**Formula**: `FundsForInterest = Credit - BonusCredit + ABS(SumOfPendingCashoutRequests)`
- Bonus credit is excluded (not real deposited money)
- Pending cashout amounts are added back (money is still in the account until withdrawal completes)
- If FundsForInterest <= 0, DailyInterest = 0

### 2.4 Daily Interest Formula

**Formula**: `DailyInterest = FundsForInterest * (YearlyInterestPercentage / 36500)`
- Uses simple interest (not compound)
- 365 days * 100 to convert percentage to daily rate
- Comment in code: "Consult Elad for rounding"

### 2.5 Day Boundary

**What**: Interest day starts at 04:00 UTC.

**Rules**:
- @StartTime = DATEADD(HOUR, 4, @FromDate)
- Each day window: @StartTime to @EndTime (24h later)
- If @ToDate is NULL, defaults to GETUTCDATE()

### 2.6 Cashout Tracking

**What**: Tracks pending withdrawal requests that affect interest base.

**Rules**:
- Open cashouts: CreditTypeID IN (9, 15) with Payment < 0
- Closed cashouts: CreditTypeID IN (2, 8) - Cashout completed or reversed
- Only cashouts from the past month (DATEADD(MONTH, -1, @StartTime)) are tracked
- Pending = opened but not yet closed by the current day's end time

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FromDate | DATE | NO | - | CODE-BACKED | Start date for interest calculation range. Day boundary starts at 04:00 UTC. |
| 2 | @ToDate | DATE | YES | NULL (→ GETUTCDATE()) | CODE-BACKED | End date for calculation range (exclusive). Defaults to current UTC date if NULL. |

**Temp Tables**:

| # | Table | Key Columns | Purpose |
|---|-------|-------------|---------|
| T1 | #CIDList_temp | CID (PK) | Eligible customers with GCID, CountryID, PlayerLevelID, AccountTypeID, RegulationID |
| T2 | #cashouts_temp | WithdrawID (PK), NCI on (CID, OpenOccurred, CloseOccurred) INCLUDE (Amount) | Pending withdrawal tracking |

**Output** (written to Trade.Syn_InterestDaily_July):

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| R1 | CID | int | CODE-BACKED | Customer identifier. |
| R2 | GCID | int | CODE-BACKED | Global customer identifier. |
| R3 | DayOfInterest | date | CODE-BACKED | Calendar date for interest record. |
| R4 | CountryID | int | CODE-BACKED | Customer country. |
| R5 | PlayerLevelID | int | CODE-BACKED | Customer tier (6=Platinum+, 7=Diamond). |
| R6 | AccountTypeID | int | CODE-BACKED | Account classification. |
| R7 | RegulationID | int | CODE-BACKED | Regulatory jurisdiction. |
| R8 | Interest | money | CODE-BACKED | Initially 0, potentially updated later. |
| R9 | MinRealMoney | money | CODE-BACKED | Initially 0. |
| R10 | Credit | money | CODE-BACKED | Customer credit balance snapshot. |
| R11 | RealizedEquity | money | CODE-BACKED | Realized equity snapshot. |
| R12 | BonusCredit | money | CODE-BACKED | Bonus credit to exclude from interest base. |
| R13 | StatusID | int | CODE-BACKED | Processing status (starts at 0). |
| R14 | SumOfPendingCashoutRequests | money | CODE-BACKED | Total pending withdrawal amount for the day. |
| R15 | YearlyInterestPercentage | decimal(5,2) | CODE-BACKED | Hardcoded yearly rate (1.8%). |
| R16 | FundsForInterest | money | CODE-BACKED | Computed: Credit - BonusCredit + ABS(PendingCashouts). |
| R17 | DailyInterest | money | CODE-BACKED | Computed: FundsForInterest * (Rate / 36500) if positive, else 0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| JOIN | Customer.Customer | Read | Customer data, PlayerLevelID, CountryID |
| JOIN | BackOffice.Customer | Read | AccountTypeID, RegulationID |
| JOIN | Dictionary.PlayerStatus | Read | GetsInterest eligibility flag |
| LEFT JOIN | Trade.InterestWhitelist | Read | PlayerLevelID override for interest eligibility |
| FROM | History.ActiveCredit | Read | Credit change history, cashout tracking |
| INSERT/UPDATE | Trade.Syn_InterestDaily_July | Write | Daily interest calculation results |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetInterestDaily_for_Azure (procedure)
+-- Customer.Customer (table, cross-schema)
+-- BackOffice.Customer (table, cross-schema)
+-- Dictionary.PlayerStatus (table, cross-schema)
+-- Trade.InterestWhitelist (table)
+-- History.ActiveCredit (table, cross-schema)
+-- Trade.Syn_InterestDaily_July (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Customer.Customer | Table | JOIN - customer demographics and tier |
| BackOffice.Customer | Table | JOIN - account type and regulation |
| Dictionary.PlayerStatus | Table | JOIN - GetsInterest filter |
| Trade.InterestWhitelist | Table | LEFT JOIN - tier override |
| History.ActiveCredit | Table | Read - credit snapshots and cashout events |
| Trade.Syn_InterestDaily_July | Table | INSERT/UPDATE - stores calculated daily interest |

---

## 7. Technical Details

### 7.1 Performance Notes

- Uses `SET TRAN ISOLATION LEVEL READ UNCOMMITTED` for all reads
- Two `OPTION (RECOMPILE)` hints on History.ActiveCredit queries with comment "Need fix, missing indexes on History.ActiveCredit"
- WHILE loop iterates day-by-day: O(n) where n = date range in days
- Each iteration performs multiple INSERT/UPDATE operations against Trade.Syn_InterestDaily_July

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Calculate interest for a specific date range

```sql
EXEC Trade.GetInterestDaily_for_Azure @FromDate = '2026-03-01', @ToDate = '2026-03-16';
```

### 8.2 Check calculated results

```sql
SELECT  TOP 100 CID, DayOfInterest, Credit, BonusCredit,
        SumOfPendingCashoutRequests, FundsForInterest,
        YearlyInterestPercentage, DailyInterest
FROM    Trade.Syn_InterestDaily_July WITH (NOLOCK)
ORDER BY DayOfInterest DESC, DailyInterest DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-16 | Enriched: - | Quality: 8.8/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 17 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetInterestDaily_for_Azure | Type: Stored Procedure | Source: etoro/etoro/Trade/Stored Procedures/Trade.GetInterestDaily_for_Azure.sql*
