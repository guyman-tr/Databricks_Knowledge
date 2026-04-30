# Billing.CountTransactionsWithTimeLimitForStatus

> Counts deposits and withdrawals per funding-type/status combination within time windows (days or hours), applying weekend non-working day adjustments; used for quota and rate-limit enforcement.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | @FundingTypeStatusLimits TVP (rule set) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.CountTransactionsWithTimeLimitForStatus` evaluates a set of transaction limit rules in a single batch query. Each rule defines: a payment method (`FundingTypeId`), a transaction status to count (`StatusId`), a lookback window size (`Limit`), whether the window is in days or hours (`IsByDays`), and whether to count deposits or withdrawals (`IsDeposit`). The procedure returns the transaction count per rule, which the calling service compares against the configured threshold to determine if a quota has been reached.

The procedure exists to support configurable rate-limiting and quota enforcement for payment processing. For example, a rule might say "count Visa credit card withdrawals in status Processed (3) in the last 7 business days" - if the count exceeds the threshold, the system may throttle further withdrawals. Rules are defined in the application and passed dynamically as a TVP, allowing the procedure to evaluate many rules in one trip to the database.

Important exclusion: customers with `PlayerLevelID=4` (internal/test accounts) are excluded from all counts to prevent test traffic from triggering quotas.

---

## 2. Business Logic

### 2.1 Weekend Non-Working Day Adjustment

**What**: When the time window is specified in calendar days (`IsByDays=1`), the procedure adjusts the window to skip weekends (non-working days), ensuring the effective business-day count is accurate.

**Parameters/Columns Involved**: `IsByDays`, `Limit`, `@ScopeDays`

**Rules**:
- `DATEFIRST` is set to `@monday (1)` at the start of each call to ensure consistent weekday numbering.
- Current weekday is captured as `@endPeriodWeekDay = DATEPART(WEEKDAY, GETUTCDATE())`.
- `NotWorkingDaysCount` per rule:
  - If today is Sunday (`@endPeriodWeekDay = 7`): `NotWorkingDaysCount = 1`
  - If `Limit - @endPeriodWeekDay >= 0` (the lookback window reaches across a weekend): `NotWorkingDaysCount = 2`
  - Otherwise: `NotWorkingDaysCount = 0`
- For `IsByDays=1`: window is `DATEADD(DAY, -(@ScopeDays + NotWorkingDaysCount), GETUTCDATE())` to `DATEADD(DAY, -(Limit), GETUTCDATE()) - NotWorkingDaysCount`
- For `IsByDays=0`: window is `DATEADD(DAY, -@ScopeDays, GETUTCDATE())` to `DATEADD(HOUR, -Limit, GETUTCDATE())` (no weekend adjustment)

**Diagram**:
```
@ScopeDays=7, today=Wednesday
  Window: [7+0 days ago] to [Limit days ago]

@ScopeDays=7, today=Sunday
  Window: [7+1=8 days ago] to [Limit days ago + 1]

@ScopeDays=7, today=Friday (Limit=5 crosses weekend)
  Window: [7+2=9 days ago] to [Limit days ago + 2]
```

### 2.2 Dual-Direction Count (Deposits + Withdrawals)

**What**: A single call can evaluate rules for both deposits and withdrawals. The UNION combines two query branches.

**Parameters Involved**: `IsDeposit`, `FundingTypeId`, `StatusId`

**Rules**:
- `IsDeposit=0` branch: JOINs `Billing.Funding` -> `Billing.WithdrawToFunding` (WHERE CashoutStatusID=StatusId), then to `Billing.Withdraw` and `Customer.CustomerStatic`. Excludes `PlayerLevelID=4`.
- `IsDeposit=1` branch: JOINs `Billing.Funding` -> `Billing.Deposit` (WHERE PaymentStatusID=StatusId), then to `Customer.CustomerStatic`. Excludes `PlayerLevelID=4`.
- Results are combined via UNION (removes duplicates, though rules are typically distinct).
- Output columns: `IsDeposit`, `FundingTypeId`, `StatusId`, `RowsNumber`.

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @FundingTypeStatusLimits | [Billing].[FundingTypeStatusLimitList] READONLY | NO | - | VERIFIED | TVP carrying the set of limit rules to evaluate. Each row defines one rule: FundingTypeId (payment method), StatusId (transaction status to count), Limit (window size in days or hours), IsByDays (0=hours, 1=days), IsDeposit (0=withdrawals, 1=deposits). See [Billing.FundingTypeStatusLimitList](../User Defined Types/Billing.FundingTypeStatusLimitList.md). |
| 2 | @ScopeDays | INT | YES | 7 | CODE-BACKED | The outer lookback scope in days: how far back in time to search for transactions. The `Limit` in each rule is the inner boundary (transactions OLDER than Limit are not counted; transactions NEWER than ScopeDays are in scope). DEFAULT=7 days. Used with weekend adjustment when IsByDays=1. |

**Result set columns**:

| # | Column | Type | Description |
|---|--------|------|-------------|
| 1 | IsDeposit | BIT | 0=withdrawal count, 1=deposit count. Identifies which direction this rule counts. |
| 2 | FundingTypeId | INT | Payment method ID from the input TVP row. |
| 3 | StatusId | INT | Transaction status ID from the input TVP row. |
| 4 | RowsNumber | INT | Count of transactions matching the rule's FundingType+Status within the adjusted time window, excluding PlayerLevelID=4 customers. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @FundingTypeStatusLimits | Billing.FundingTypeStatusLimitList | TVP Input | Rule definitions driving both query branches |
| FundingTypeId | Billing.Funding | JOIN | Resolves funding type to specific FundingIDs for transaction lookup |
| IsDeposit=0 | Billing.WithdrawToFunding | Read | Counts withdrawal records matching FundingType+Status within window |
| IsDeposit=0 | Billing.Withdraw | JOIN | Links WithdrawToFunding to CID for PlayerLevel exclusion |
| IsDeposit=1 | Billing.Deposit | Read | Counts deposit records matching FundingType+Status within window |
| (both) | Customer.CustomerStatic | JOIN | Filters out PlayerLevelID=4 (internal/test accounts) |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Quota enforcement service | @FundingTypeStatusLimits | Caller | Passes configured limit rules; compares RowsNumber against thresholds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.CountTransactionsWithTimeLimitForStatus (procedure)
+-- Billing.FundingTypeStatusLimitList (type) [TVP input]
+-- Billing.Funding (table) [JOIN: resolves FundingTypeID to FundingID]
+-- Billing.WithdrawToFunding (table) [READ: withdrawal transactions, IsDeposit=0]
+-- Billing.Withdraw (table) [JOIN: CID lookup for PlayerLevel filter]
+-- Billing.Deposit (table) [READ: deposit transactions, IsDeposit=1]
+-- Customer.CustomerStatic (table) [JOIN: excludes PlayerLevelID=4]
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.FundingTypeStatusLimitList | User Defined Type | TVP input type |
| Billing.Funding | Table | Maps FundingTypeID to FundingID |
| Billing.WithdrawToFunding | Table | Withdrawal transaction count source |
| Billing.Withdraw | Table | Provides CID for test account exclusion |
| Billing.Deposit | Table | Deposit transaction count source |
| Customer.CustomerStatic | Table | PlayerLevelID filter (excludes level 4) |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in Billing SP layer. | - | Called by application quota service. |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Performance note**: `DATEFIRST` is set to `1` (Monday) at the start of each call - this is a session-level setting that affects the call scope. Uses `WITH (NOLOCK)` on all table reads.

---

## 8. Sample Queries

### 8.1 Simulate the procedure - count processed CC withdrawals in last 7 days

```sql
-- Equivalent to calling CountTransactionsWithTimeLimitForStatus with:
-- (FundingTypeId=1, StatusId=3, Limit=3, IsByDays=1, IsDeposit=0), @ScopeDays=7
SELECT
    0 AS IsDeposit,
    F.FundingTypeID,
    WF.CashoutStatusID AS StatusId,
    COUNT(WF.ID) AS RowsNumber
FROM Billing.Funding F WITH (NOLOCK)
JOIN Billing.WithdrawToFunding WF WITH (NOLOCK)
    ON F.FundingID = WF.FundingID AND WF.CashoutStatusID = 3
    AND WF.ModificationDate > DATEADD(DAY, -7, GETUTCDATE())
    AND WF.ModificationDate < DATEADD(DAY, -3, GETUTCDATE())
JOIN Billing.Withdraw W WITH (NOLOCK) ON W.WithdrawID = WF.WithdrawID
JOIN Customer.CustomerStatic CS WITH (NOLOCK) ON CS.CID = W.CID
WHERE F.FundingTypeID = 1 AND CS.PlayerLevelID != 4
GROUP BY F.FundingTypeID, WF.CashoutStatusID
```

### 8.2 Count approved deposits in last 24 hours for PayPal

```sql
SELECT
    1 AS IsDeposit,
    F.FundingTypeID,
    D.PaymentStatusID AS StatusId,
    COUNT(D.DepositID) AS RowsNumber
FROM Billing.Funding F WITH (NOLOCK)
JOIN Billing.Deposit D WITH (NOLOCK)
    ON F.FundingID = D.FundingID AND D.PaymentStatusID = 2
    AND D.ModificationDate > DATEADD(HOUR, -24, GETUTCDATE())
JOIN Customer.CustomerStatic CS WITH (NOLOCK) ON CS.CID = D.CID
WHERE F.FundingTypeID = 3 AND CS.PlayerLevelID != 4
GROUP BY F.FundingTypeID, D.PaymentStatusID
```

### 8.3 Inspect FundingTypeStatusLimitList TVP structure

```sql
SELECT c.name, t.name AS type_name, c.max_length, c.is_nullable
FROM sys.table_types tt WITH (NOLOCK)
JOIN sys.columns c WITH (NOLOCK) ON c.object_id = tt.type_table_object_id
JOIN sys.types t WITH (NOLOCK) ON t.user_type_id = c.user_type_id
WHERE tt.schema_id = SCHEMA_ID('Billing')
  AND tt.name = 'FundingTypeStatusLimitList'
ORDER BY c.column_id
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.3/10 (Elements: 10/10, Logic: 10/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 6 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 1,8,9,9B(skip),10,11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers | App Code: 0 repos | Corrections: 0 applied*
*Object: Billing.CountTransactionsWithTimeLimitForStatus | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.CountTransactionsWithTimeLimitForStatus.sql*
