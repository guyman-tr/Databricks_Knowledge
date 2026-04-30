# Billing.DepositLastHourStats_Get

> Returns deposit counts by status for the last 60 minutes, formatted identically to the hourly average baseline - the real-time counterpart to DepositHourlyAverage_Get for side-by-side alerting comparisons.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | No parameters - always queries last 1 hour |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DepositLastHourStats_Get` is the real-time half of the deposit alerting system. It queries `Billing.Deposit` for the last 60 minutes and aggregates results into the exact same column structure as `Billing.DepositHourlyAverage`, so monitoring tools can compare them directly: "What happened in the last hour?" vs. "What is the historical average for this day+hour?"

The intended use is alerting: call `DepositLastHourStats_Get` to get current-hour actuals, call `DepositHourlyAverage_Get` for the same day-of-week, join on (FundingTypeID), and compute `actual / baseline * 100%`. A ratio significantly below 100% indicates a potential payment provider issue.

Created in August 2013 (Alon Nachshon, FB: 15792), it is the real-time companion to the baseline refresh and retrieval procedures from the same feature request. No input parameters - always reflects exactly the last hour from GETDATE().

---

## 2. Business Logic

### 2.1 Last-Hour Aggregation

**What**: Aggregates all deposits in the last 60 minutes by day-of-week, hour, and payment method.

**Columns/Parameters Involved**: `Billing.Deposit.PaymentDate`, `Billing.Deposit.PaymentStatusID`, `Billing.Deposit.RiskManagementStatusID`, `Billing.Funding.FundingTypeID`

**Rules**:
- Time window: `WHERE Dp.PaymentDate >= DATEADD(hh, -1, GETDATE())` - last 60 minutes, rolling.
- Groups by (DayOfWeek, Hour, FundingTypeID) - same as the historical baseline keys.
- Status breakdowns use identical CASE expressions to `DepositHourlyAverage_Update`:
  - `Approved` = PaymentStatusID = 2
  - `Declined` = PaymentStatusID = 3
  - `Technical` = PaymentStatusID = 4
  - `RRE` = PaymentStatusID = 35
  - `KycRRE` = PaymentStatusID = 35 AND RiskManagementStatusID IN (32,33,34,35,37)
  - `Other` = PaymentStatusID NOT IN (2,3,4,35)
- `DistinctDayHours` is **hardcoded to 1**: this is a single actual hour, not an average over multiple week occurrences. This makes the output schema compatible with the baseline table while signalling "no normalization needed."

### 2.2 Alerting Comparison Pattern

**What**: The output is designed to be joined against `DepositHourlyAverage_Get` output for immediate ratio calculation.

**Columns/Parameters Involved**: `DepositDay`, `DepositHour`, `FundingTypeID`, `Approved`, `DistinctDayHours`

**Rules**:
- Join key: `(FundingTypeID, DepositDay, DepositHour)` - matches historical baseline keys.
- Alert ratio: `actual.Approved / (baseline.Approved / baseline.DistinctDayHours)` gives the ratio of this hour to historical average.
- `DistinctDayHours = 1` in this proc's output means no normalization is needed on the actual side.
- Expected result set: typically a few rows (only FundingTypes that had at least one deposit in the last hour).

```
DepositLastHourStats_Get output + DepositHourlyAverage_Get output:

FundingTypeID | Actual.Approved | Baseline.Approved | DistinctDayHours | AvgPerOccurrence | Ratio%
1 (CreditCard) | 45             | 180               | 4                | 45               | 100%   (on pace)
3 (PayPal)     | 2              | 60                | 4                | 15               | 13%    (ALERT!)
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

This procedure has no input parameters.

**Output columns** (matched to `Billing.DepositHourlyAverage` schema):

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | DepositDay | int | NO | - | CODE-BACKED | Day of week for the last-hour window: DATEPART(DW, Dp.PaymentDate). 1=Sunday, 2=Monday, ..., 7=Saturday. Matches the DepositDay key in Billing.DepositHourlyAverage for join-based comparisons. |
| 2 | DepositHour | int | NO | - | CODE-BACKED | Hour of day (0-23 UTC) for the last-hour window: DATEPART(hh, Dp.PaymentDate). Matches the DepositHour key in Billing.DepositHourlyAverage. |
| 3 | FundingTypeID | int | NO | - | CODE-BACKED | Payment method (implicit FK to Dictionary.FundingType). Only funding types with deposits in the last hour appear in the result. Matches the FundingTypeID key in Billing.DepositHourlyAverage. |
| 4 | Approved | int | NO | - | CODE-BACKED | Count of approved deposits (PaymentStatusID=2) in the last 60 minutes. The primary alert metric - compared against `Billing.DepositHourlyAverage.Approved / DistinctDayHours`. |
| 5 | Declined | int | NO | - | CODE-BACKED | Count of declined deposits (PaymentStatusID=3) in the last hour. High ratio of Declined/Approved may indicate issuer issues. |
| 6 | [Approved/Declined] | float (computed) | NO | - | CODE-BACKED | Inline ratio: `1.0 * Approved / ISNULL(NULLIF(Declined, 0), 1)`. Division-by-zero protected. Values > 1.0 indicate more approvals than declines. |
| 7 | Technical | int | NO | - | CODE-BACKED | Count of technical failure deposits (PaymentStatusID=4) in the last hour. Indicates gateway processing errors. |
| 8 | RRE | int | NO | - | CODE-BACKED | Count of Risk Review Exception deposits (PaymentStatusID=35) in the last hour. |
| 9 | KycRRE | int | NO | - | CODE-BACKED | Count of KYC-triggered RRE deposits (PaymentStatusID=35 AND RiskManagementStatusID IN (32,33,34,35,37)) in the last hour. |
| 10 | Other | int | NO | - | CODE-BACKED | Count of deposits with statuses not in (2,3,4,35) in the last hour. |
| 11 | TotalRows | int | NO | - | CODE-BACKED | Total deposit count (all statuses) in the last hour. |
| 12 | DistinctDayHours | int | NO | - | CODE-BACKED | Hardcoded to 1. Signals this is a single actual hour, not a multi-week average. Makes the output schema compatible with Billing.DepositHourlyAverage (which uses DistinctDayHours to normalize counts across multiple week occurrences). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| PaymentDate filter | Billing.Deposit | READ | Source of all last-hour deposit records. Joined to Funding for FundingTypeID. |
| FundingID -> FundingTypeID | Billing.Funding | JOIN | Resolves payment method from deposit record. LEFT JOIN. |
| PaymentStatusID | Dictionary.PaymentStatus | JOIN (vestigial) | LEFT JOINed but no columns selected - present for historical reasons, same pattern as DepositHourlyAverage_Update. |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| (Monitoring / alerting jobs) | - | EXEC | Called by scheduled alert jobs to get current-hour stats for comparison against the baseline. Not referenced by other stored procedures in the SSDT repo. |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DepositLastHourStats_Get (procedure)
├── Billing.Deposit (table)
├── Dictionary.PaymentStatus (table)
└── Billing.Funding (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | Primary data source - last 60 minutes of deposits aggregated by DW + hour + FundingType. |
| Billing.Funding | Table | LEFT JOINed to resolve FundingTypeID from Deposit.FundingID. |
| Dictionary.PaymentStatus | Table | LEFT JOINed (no columns selected - vestigial). |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| No dependents found in SSDT repo. Called by external monitoring/alerting infrastructure. | - | - |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Get current last-hour deposit stats

```sql
EXEC [Billing].[DepositLastHourStats_Get];
```

### 8.2 Compare last-hour actuals against historical baseline

```sql
-- Get last-hour actuals
DECLARE @Actual TABLE (
    DepositDay INT, DepositHour INT, FundingTypeID INT,
    Approved INT, Declined INT, TotalRows INT, DistinctDayHours INT
);
INSERT INTO @Actual
EXEC [Billing].[DepositLastHourStats_Get];

-- Get historical baseline for the same day
DECLARE @Baseline TABLE (
    DepositDay INT, DepositHour INT, FundingTypeID INT,
    Approved INT, DistinctDayHours INT
);
INSERT INTO @Baseline
EXEC [Billing].[DepositHourlyAverage_Get]
    @DepositDay = DATEPART(DW, GETDATE());

-- Compute ratios
SELECT
    a.FundingTypeID,
    a.Approved AS ActualApproved,
    b.Approved AS BaselineTotal,
    b.DistinctDayHours,
    CAST(b.Approved AS float) / NULLIF(b.DistinctDayHours, 0) AS BaselineAvgPerOccurrence,
    CAST(a.Approved AS float) / NULLIF(CAST(b.Approved AS float) / NULLIF(b.DistinctDayHours, 0), 0) * 100 AS RatioPct
FROM @Actual a
JOIN @Baseline b ON a.FundingTypeID = b.FundingTypeID
    AND a.DepositDay = b.DepositDay
    AND a.DepositHour = b.DepositHour;
```

### 8.3 Check if CreditCard approvals are below 50% of historical average

```sql
-- Quick alert check for CreditCard (FundingTypeID = 1)
DECLARE @Actual TABLE (
    FundingTypeID INT, DepositDay INT, DepositHour INT, Approved INT, DistinctDayHours INT
);
INSERT INTO @Actual EXEC [Billing].[DepositLastHourStats_Get];

DECLARE @Baseline TABLE (
    FundingTypeID INT, DepositDay INT, DepositHour INT, Approved INT, DistinctDayHours INT
);
INSERT INTO @Baseline EXEC [Billing].[DepositHourlyAverage_Get]
    @DepositDay = DATEPART(DW, GETDATE());

SELECT
    CASE WHEN a.Approved < (b.Approved / NULLIF(b.DistinctDayHours, 0)) * 0.5
         THEN 'ALERT: CreditCard approvals below 50% of historical average'
         ELSE 'OK'
    END AS AlertStatus
FROM @Actual a
JOIN @Baseline b ON a.FundingTypeID = b.FundingTypeID
    AND a.DepositDay = b.DepositDay AND a.DepositHour = b.DepositHour
WHERE a.FundingTypeID = 1;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.7/10 (Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 12 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DepositLastHourStats_Get | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DepositLastHourStats_Get.sql*
