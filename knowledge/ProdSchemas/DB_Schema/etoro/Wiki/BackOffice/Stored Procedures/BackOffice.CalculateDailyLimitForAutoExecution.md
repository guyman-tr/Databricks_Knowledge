# BackOffice.CalculateDailyLimitForAutoExecution

> Calculates the average daily cashout amount per payment funding type, based on completed withdrawals from the same day-of-week over the past N weeks, to establish automated approval thresholds.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | FundingTypeID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates the historical daily cashout baseline per payment method type (FundingTypeID), used to set automated approval limits for the BackOffice cashout auto-execution system. The logic compares same-day-of-week data from the past N weeks to produce a representative daily average - for example, if today is a Tuesday, it averages the total cashout amount across all prior Tuesdays in the lookback window. This removes day-of-week seasonality from the baseline calculation.

The result set (one row per FundingTypeID with its average daily cashout volume) is used by the auto-execution system to determine when aggregate cashout volumes on a given day/funding method have reached or exceeded historical norms, triggering additional review or throttling. Created 19/09/2022 by KateM (MIMOPSA-7672).

---

## 2. Business Logic

### 2.1 Same-Day-of-Week Rolling Average

**What**: Computes total cashout volume per FundingTypeID per day (for same weekdays only), then averages across the lookback period.

**Tables Involved**: `Billing.Withdraw`, `Billing.WithdrawToFunding`, `Billing.Funding`

**Rules**:
- Lookback window: @TimePeriodWeeks weeks back from today (default: last 4 weeks)
- Day-of-week filter: DATEPART(WEEKDAY, RequestDate) = DATEPART(WEEKDAY, GETDATE()) - only includes days with the same weekday as today
- CashoutStatusID filter: w.CashoutStatusID = 3 - only completed/approved cashouts are included in the baseline (in-progress or rejected cashouts excluded)
- Date range: RequestDate >= N weeks ago AND < @CurrentDate (excludes today - historical data only)
- JOIN chain: Billing.Withdraw -> Billing.WithdrawToFunding -> Billing.Funding to get FundingTypeID
- Two-step aggregation: SUM(Amount) per FundingTypeID per day into temp table, then AVG(DailyTotal) per FundingTypeID as final result

**Diagram**:
```
Step 1: For each matching day in lookback window ->
    GROUP BY FundingTypeID, RequestDate
    -> TotalAmount per type per day

Step 2: AVG(TotalAmount) per FundingTypeID
    -> DailyLimit (historical average for this weekday)
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimePeriodWeeks | INT | YES | 4 | CODE-BACKED | Number of weeks back to include in the historical average. Default=4 (last 4 same-weekday occurrences). Increase for more stable baseline; decrease for more recent-weighted. |

**Result Set:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 2 | FundingTypeID | INT | NO | - | CODE-BACKED | Payment method type identifier (from Billing.Funding). Groups results by funding type for per-method daily limits. |
| 3 | DailyLimit | (decimal) | YES | - | CODE-BACKED | AVG of total cashout amounts for this FundingTypeID on same-weekday days over the lookback period. Represents the expected daily cashout volume for this payment method. NULL if no historical data exists for this weekday. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Billing.Withdraw | CashoutStatusID=3, RequestDate | READER | Reads completed cashout records within the rolling lookback window |
| Billing.WithdrawToFunding | WithdrawID | READER | Bridge table: maps withdrawals to their funding methods |
| Billing.Funding | FundingTypeID | READER | Provides the funding type classification for each withdrawal |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice cashout auto-execution system | DailyLimit result | Caller | Uses per-FundingType daily limit to set/evaluate auto-approval thresholds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CalculateDailyLimitForAutoExecution (procedure)
|- Billing.Withdraw (table) [READER - completed cashouts, same weekday filter]
|- Billing.WithdrawToFunding (table) [READER - withdraw-to-funding bridge]
+-- Billing.Funding (table) [READER - provides FundingTypeID]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Withdraw | Table (cross-schema) | Source of cashout records; filtered on CashoutStatusID=3 (completed) and RequestDate |
| Billing.WithdrawToFunding | Table (cross-schema) | JOIN bridge linking withdraw records to their funding method |
| Billing.Funding | Table (cross-schema) | Provides FundingTypeID for grouping results |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice auto-execution system | External | Calls to retrieve current daily limit thresholds per payment method |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| CashoutStatusID = 3 | Filter | Only completed/approved cashouts contribute to the baseline (in-progress excluded) |
| Same-weekday filter | Seasonality control | DATEPART(WEEKDAY) match removes day-of-week seasonality from the average |
| RequestDate < today | Historical only | Excludes today's in-progress data from the baseline |
| Temp table (#Withdrawstmp) | Intermediate | Two-step aggregation via session temp table - no explicit DROP (cleaned up at end of session) |
| Created: MIMOPSA-7672 | Change ref | 19/09/2022 KateM - cashout daily average amount calculation per PaymentTypeID |

---

## 8. Sample Queries

### 8.1 Run with default 4-week lookback

```sql
EXEC BackOffice.CalculateDailyLimitForAutoExecution
-- Returns: FundingTypeID | DailyLimit
-- One row per funding type with historical average
```

### 8.2 Run with extended 8-week lookback for more stable baseline

```sql
EXEC BackOffice.CalculateDailyLimitForAutoExecution @TimePeriodWeeks = 8
```

### 8.3 Check what funding types exist in recent withdrawals

```sql
SELECT DISTINCT f.FundingTypeID, COUNT(*) AS WithdrawCount
FROM Billing.Withdraw w WITH (NOLOCK)
JOIN Billing.WithdrawToFunding wtf WITH (NOLOCK) ON w.WithdrawID = wtf.WithdrawID
JOIN Billing.Funding f WITH (NOLOCK) ON f.FundingID = wtf.FundingID
WHERE w.CashoutStatusID = 3
  AND w.RequestDate >= DATEADD(WEEK, -4, GETDATE())
GROUP BY f.FundingTypeID
ORDER BY f.FundingTypeID
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Created for MIMOPSA-7672 - Jira ticket not accessible via current MCP.)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 3 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CalculateDailyLimitForAutoExecution | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CalculateDailyLimitForAutoExecution.sql*
