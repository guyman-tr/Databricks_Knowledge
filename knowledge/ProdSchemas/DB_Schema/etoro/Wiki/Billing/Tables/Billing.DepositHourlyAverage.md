# Billing.DepositHourlyAverage

> Pre-aggregated deposit statistics by day-of-week, hour, and payment method - provides historical hourly deposit volume baselines for ops alerting and deposit pattern monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Table |
| **Key Identifier** | (DepositDay, DepositHour, FundingTypeID) - composite clustered PK |
| **Partition** | No (MAIN filegroup, FILLFACTOR 90) |
| **Indexes** | 1 (PK clustered) |

---

## 1. Business Meaning

`Billing.DepositHourlyAverage` is a pre-aggregated rolling statistics table used to establish historical deposit volume baselines for each combination of day-of-week (1-7), hour (0-23), and payment method. It is the data source for real-time ops alerting that compares the current hour's deposit volume against the historical average for that same day/hour/payment-method slot.

The primary use case: if CreditCard approvals in the last hour are significantly below the historical average for "Fridays at 14:00", this may indicate a payment provider outage. The alert procedures `Billing.LastHourTotalCreditCardApprovedDepositsVsHistory` and `Billing.LastHourTotalPayPalNewDepositsVsHistory` query this table to compute the ratio (actual/average * 100%) and alert when it drops below acceptable thresholds.

The table is refreshed by `Billing.DepositHourlyAverage_Update` from the last 28 days of `Billing.Deposit` data. The `DistinctDayHours` column normalizes the averages - it counts how many distinct occurrences of that day+hour slot have appeared in the 28-day window (typically 4 for most slots), so callers can compute `Approved / DistinctDayHours` = average approvals per occurrence.

Current data covers 7 days x up to 24 hours x 12 funding types = 1,608 rows. Friday (day 5) is the busiest day (8,856 total deposits in baseline), Sunday (day 1) the quietest (3,298 deposits).

---

## 2. Business Logic

### 2.1 Historical Baseline Calculation

**What**: Stores cumulative deposit counts per day-of-week + hour + funding type, refreshed from the last 28 days.

**Columns/Parameters Involved**: `DepositDay`, `DepositHour`, `FundingTypeID`, `Approved`, `Declined`, `Technical`, `RRE`, `KycRRE`, `Other`, `TotalRows`, `DistinctDayHours`

**Rules**:
- `DepositDay` = `DATEPART(DW, PaymentDate)`: 1=Sunday, 2=Monday, ..., 7=Saturday (SQL Server DW convention).
- `DepositHour` = `DATEPART(hh, PaymentDate)`: 0-23 UTC.
- `Approved` = deposits with `PaymentStatusID = 2`.
- `Declined` = deposits with `PaymentStatusID = 3`.
- `Technical` = deposits with `PaymentStatusID = 4` (technical failure).
- `RRE` = deposits with `PaymentStatusID = 35` (Risk Review Exception - held for review).
- `KycRRE` = deposits where `PaymentStatusID = 35 AND RiskManagementStatusID IN (32, 33, 34, 35, 37)` (RRE caused specifically by KYC check failure).
- `Other` = deposits where `PaymentStatusID NOT IN (2, 3, 4, 35)` (all other statuses).
- `TotalRows` = all deposits in that slot.
- `DistinctDayHours` = number of distinct week occurrences for that (DayOfWeek, Hour) combination in the 28-day window. Used to normalize: `Approved / DistinctDayHours` = average approvals per occurrence.

### 2.2 Alert: Last Hour vs Historical Average

**What**: Alert procedures compare current hour deposits against this table's historical averages.

**Columns/Parameters Involved**: `DepositDay`, `DepositHour`, `FundingTypeID`, `Approved`, `DistinctDayHours`

**Rules**:
- `LastHourTotalCreditCardApprovedDepositsVsHistory` queries FundingTypeID=1 (CreditCard):
  ```sql
  SELECT (lastHourApproved / avgApprovedPerHour) * 100 AS ratio
  -- where avgApprovedPerHour = Approved / DistinctDayHours for current DayOfWeek + Hour
  ```
- Returns a percentage: 100% = on pace with history, <50% may indicate provider issues.
- `LastHourTotalPayPalNewDepositsVsHistory` does the same for FundingTypeID=3 (PayPal).
- Both procedures are alert-oriented: called by monitoring jobs to detect anomalies.

### 2.3 Update Pattern (UPSERT)

**What**: DepositHourlyAverage_Update refreshes the table from the last 28 days of deposit data.

**Columns/Parameters Involved**: All columns

**Rules**:
- `@NumDays` (default 28): lookback window in days from current time.
- Two-step UPSERT: UPDATE existing rows, then INSERT new rows (new day/hour/funding type combinations not yet seen).
- Runs as a scheduled job. Frequency not specified in code but typically daily or hourly.

---

## 3. Data Overview

| DepositDay | Day Name | HourSlots | TotalDeposits (28d) | TotalApproved | Approx Approval Rate |
|-----------|----------|-----------|---------------------|---------------|---------------------|
| 1 | Sunday | 232 | 3,298 | 1,849 | 56% |
| 2 | Monday | 239 | 7,398 | 4,283 | 58% |
| 3 | Tuesday | 235 | 6,852 | 4,091 | 60% |
| 4 | Wednesday | 233 | 7,229 | 4,403 | 61% |
| 5 | Friday | 228 | 8,856 | 5,342 | 60% |
| 6 | Saturday | 225 | 7,506 | 4,507 | 60% |
| 7 | Saturday* | 216 | 2,447 | 1,307 | 53% |

*SQL Server DATEPART(DW) returns 1=Sunday through 7=Saturday by default.
Total: 1,608 rows | 12 unique FundingTypeIDs | 7 day slots

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositDay | int | NO | - | CODE-BACKED | Day of week: DATEPART(DW, PaymentDate). 1=Sunday, 2=Monday, 3=Tuesday, 4=Wednesday, 5=Thursday, 6=Friday, 7=Saturday (SQL Server default DW convention). Part of composite PK. Used by alert procedures: `WHERE DepositDay = @currentDayOfWeek`. |
| 2 | DepositHour | int | NO | - | CODE-BACKED | Hour of day: DATEPART(hh, PaymentDate). 0-23 UTC. Part of composite PK. Combined with DepositDay to identify the specific hour slot in the week. Used by alert procedures: `AND DepositHour = @lastHour`. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method for this baseline row. Implicit FK to Dictionary.FundingType. 12 distinct values in current data. Part of composite PK. Alert procedures filter on specific values: FundingTypeID=1 (CreditCard), FundingTypeID=3 (PayPal). |
| 4 | Approved | int | NO | - | CODE-BACKED | Count of deposits with PaymentStatusID=2 (Approved) in this day+hour+fundingtype slot over the 28-day window. Divided by DistinctDayHours to get average approvals per occurrence. Core metric for the alerting baseline. |
| 5 | Declined | int | NO | - | CODE-BACKED | Count of deposits with PaymentStatusID=3 (Declined) in this slot. High Declined count relative to Approved may indicate card issuer or provider issues. |
| 6 | Technical | int | NO | - | CODE-BACKED | Count of deposits with PaymentStatusID=4 (Technical failure) in this slot. Technical failures typically indicate gateway-side processing errors vs. issuer declines. |
| 7 | RRE | int | NO | - | CODE-BACKED | Count of deposits with PaymentStatusID=35 (Risk Review Exception) in this slot. These deposits are held for manual review by the risk team. |
| 8 | KycRRE | int | NO | - | CODE-BACKED | Count of RRE deposits caused specifically by KYC checks: PaymentStatusID=35 AND RiskManagementStatusID IN (32, 33, 34, 35, 37). Subset of RRE. Tracks KYC-triggered holds separately from other risk holds. |
| 9 | Other | int | NO | - | CODE-BACKED | Count of deposits with PaymentStatusID NOT IN (2, 3, 4, 35) in this slot. Catch-all for all other statuses (pending, cancelled, refunded, etc.). |
| 10 | TotalRows | int | NO | - | CODE-BACKED | Total deposit count (all statuses) in this slot. Sum of Approved + Declined + Technical + RRE + Other. Used as the denominator for approval rate calculations. |
| 11 | DistinctDayHours | int | NO | - | CODE-BACKED | Number of distinct occurrences of this (DayOfWeek, Hour) slot in the 28-day lookback window. Typically 4 (four Mondays, Tuesdays, etc. in 28 days). Used to normalize: Approved / DistinctDayHours = average approvals per occurrence of this day+hour. The alert procedure uses: `Approved / DistinctDayHours AS avgApprovedPerHour`. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| FundingTypeID | Dictionary.FundingType | Implicit FK | Identifies the payment method for each baseline row. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Billing.DepositHourlyAverage_Update | All columns | WRITER | Refreshes the table via UPSERT from last 28 days of Billing.Deposit. Scheduled job. |
| Billing.DepositHourlyAverage_Get | DepositDay | READER | Returns all baseline rows for a specified day of week. |
| Billing.LastHourTotalCreditCardApprovedDepositsVsHistory | FundingTypeID=1, DepositDay, DepositHour, Approved, DistinctDayHours | READER | Computes CreditCard last-hour approval ratio vs historical average. Alert procedure. |
| Billing.LastHourTotalPayPalNewDepositsVsHistory | FundingTypeID, DepositDay, DepositHour | READER | Computes PayPal last-hour deposit ratio vs historical average. Alert procedure. |

---

## 6. Dependencies

### 6.0 Dependency Chain

Billing.Deposit -> Billing.DepositHourlyAverage (populated from Deposit data)

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Source data for the Update procedure (last 28 days of deposits aggregated by DW+hour+FundingType). |
| Billing.Funding | Table | Joined in Update to resolve FundingTypeID from FundingID. |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Billing.DepositHourlyAverage_Update | Stored Procedure | WRITER - refreshes all baseline data via UPSERT |
| Billing.DepositHourlyAverage_Get | Stored Procedure | READER - returns rows for a specific day-of-week |
| Billing.LastHourTotalCreditCardApprovedDepositsVsHistory | Stored Procedure | READER - CreditCard alert: current hour vs historical avg |
| Billing.LastHourTotalPayPalNewDepositsVsHistory | Stored Procedure | READER - PayPal alert: current hour vs historical avg |

---

## 7. Technical Details

### 7.1 Indexes

| Index Name | Type | Key Columns | Included Columns | Filter | Status |
|-----------|------|-------------|-----------------|--------|--------|
| PK_BDHA | CLUSTERED PK | DepositDay ASC, DepositHour ASC, FundingTypeID ASC | - | - | Active |

MAIN filegroup. FILLFACTOR=90.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| PK_BDHA | PRIMARY KEY | (DepositDay, DepositHour, FundingTypeID) - unique baseline per day/hour/payment-method |

No DEFAULT constraints - all values explicitly populated by the Update procedure.

---

## 8. Sample Queries

### 8.1 Get historical average for CreditCard on a specific day and hour

```sql
SELECT DepositDay, DepositHour,
    Approved, Declined, TotalRows,
    CAST(Approved AS float) / NULLIF(DistinctDayHours, 0) AS AvgApprovedPerOccurrence,
    CAST(Approved AS float) / NULLIF(TotalRows, 0) * 100 AS ApprovalRatePct
FROM [Billing].[DepositHourlyAverage] WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
  AND DepositDay = DATEPART(DW, GETDATE())
  AND DepositHour = DATEPART(hh, GETDATE()) - 1;
```

### 8.2 View approval rates by day of week across all funding types

```sql
SELECT DepositDay,
    SUM(Approved) AS TotalApproved, SUM(TotalRows) AS TotalAll,
    CAST(SUM(Approved) AS float) / NULLIF(SUM(TotalRows), 0) * 100 AS ApprovalRatePct
FROM [Billing].[DepositHourlyAverage] WITH (NOLOCK)
GROUP BY DepositDay
ORDER BY DepositDay;
```

### 8.3 Identify busiest hours for a payment method

```sql
SELECT DepositHour, SUM(TotalRows) AS TotalDeposits, SUM(Approved) AS TotalApproved
FROM [Billing].[DepositHourlyAverage] WITH (NOLOCK)
WHERE FundingTypeID = 1  -- CreditCard
GROUP BY DepositHour
ORDER BY TotalDeposits DESC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 8.8/10 (Elements: 10/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 11 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 8/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 4 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositHourlyAverage | Type: Table | Source: etoro/etoro/Billing/Tables/Billing.DepositHourlyAverage.sql*
