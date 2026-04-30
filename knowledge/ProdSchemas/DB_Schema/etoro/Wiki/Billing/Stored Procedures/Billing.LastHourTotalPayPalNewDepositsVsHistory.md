# Billing.LastHourTotalPayPalNewDepositsVsHistory

> Returns the ratio (as a percentage) of new PayPal deposits initiated in the previous hour compared to the historical hourly average for the same day-of-week and hour - an ops alerting indicator for detecting PayPal deposit flow degradation.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar ratio (unnamed column, FLOAT percentage) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LastHourTotalPayPalNewDepositsVsHistory` is an ops alerting probe that monitors PayPal deposit initiation volume. It tracks deposits with `PaymentStatusID=1` (New/Initiated - deposits that have been submitted to PayPal but not yet confirmed) against the historical "Other" category baseline in `Billing.DepositHourlyAverage`. A sharp drop in new PayPal deposit initiations relative to history can indicate that the PayPal payment widget is failing to load, customers are being blocked from reaching the PayPal flow, or the PayPal API gateway is rejecting requests before deposits reach an approved state.

Note: Unlike `LastHourTotalCreditCardApprovedDepositsVsHistory` which monitors the approval outcome, this procedure monitors the initiation rate (top of funnel for PayPal), making it sensitive to frontend/integration issues rather than backend approval failures.

Data flows: called by the ops monitoring system alongside the credit card and technical failure monitors. No parameters needed.

---

## 2. Business Logic

### 2.1 Last Hour PayPal Initiations vs Historical Average

**What**: Computes (last hour new PayPal deposits) / (historical avg "Other" status deposits per hour for this day+hour) * 100.

**Columns/Parameters Involved**: `FundingTypeID`, `PaymentStatusID`, `PaymentDate`, `DepositDay`, `DepositHour`, `Other`, `DistinctDayHours`

**Rules**:
- `@lastHour = DATEPART(hh, GETDATE()) - 1`: previous hour
- `@currentDayOfWeek = DATEPART(DW, GETDATE())`: 1=Sunday, 2=Monday, ..., 7=Saturday
- Live count filter: `FundingTypeID=3` (PayPal), `PaymentStatusID=1` (New/Initiated), `DATEPART(hh, PaymentDate) = @lastHour AND PaymentDate > DATEADD(hh, -2, GETDATE())`
- Historical baseline: `Billing.DepositHourlyAverage.Other / DistinctDayHours` for `FundingTypeID=3, DepositDay=@currentDayOfWeek, DepositHour=@lastHour`
  - `Other` column captures PaymentStatusID NOT IN (2=Approved, 3=Declined, 4=Technical, 35=RRE), so it includes PaymentStatusID=1 (New) and other interim statuses
- `ISNULL(NULLIF(<avg>, 0), 1)`: prevents division by zero if no historical data for this slot
- Result: unnamed FLOAT column (percentage); 100=normal, significant drop indicates PayPal flow issue
- No SET NOCOUNT ON

**Diagram**:
```
Ops monitoring calls at hourly interval
        |
        v
@lastHour = current hour - 1
@currentDayOfWeek = current day of week
        |
        v
liveCount = COUNT(*) FROM Billing.Deposit JOIN Billing.Funding
  WHERE FundingTypeID=3 AND PaymentStatusID=1 (New/Initiated)
  AND DATEPART(hh, PaymentDate)=@lastHour
  AND PaymentDate > GETDATE()-2h
        |
        v
historicalAvg = Other / DistinctDayHours
  FROM Billing.DepositHourlyAverage
  WHERE FundingTypeID=3 AND DepositDay=@currentDayOfWeek AND DepositHour=@lastHour
        |
        v
Result = (liveCount / historicalAvg) * 100
  100% = normal PayPal initiation rate
  <50% = investigate PayPal integration/gateway
```

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

No input parameters.

### Output Column

| # | Element | Type | Confidence | Description |
|---|---------|------|------------|-------------|
| 1 | (unnamed) | FLOAT | CODE-BACKED | Ratio of last hour's new PayPal deposits to historical average for this day/hour, expressed as a percentage. 100.0 = on pace with history. Significant drops indicate PayPal deposit flow degradation. Column has no alias in the DDL (contrast with SP #11 which has `lastHourApprovedVSavgApprovedPerHour`). |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Live count | Billing.Deposit | READ | Counts new (PaymentStatusID=1) PayPal deposits in previous hour |
| Live count | Billing.Funding | READ | JOINed on FundingID to filter FundingTypeID=3 (PayPal) |
| Historical baseline | Billing.DepositHourlyAverage | READ | Provides Other/DistinctDayHours as historical hourly average for PayPal new-status deposits |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found in the Billing schema. Called from the ops alerting/monitoring system on a scheduled basis.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LastHourTotalPayPalNewDepositsVsHistory (procedure)
├── Billing.Deposit (table - live new deposit count)
├── Billing.Funding (table - FundingType filter)
└── Billing.DepositHourlyAverage (table - historical baseline)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | COUNT of new PayPal deposits in last hour; filtered by PaymentStatusID=1, PaymentDate window |
| Billing.Funding | Table | JOINed on FundingID for FundingTypeID=3 (PayPal) filter |
| Billing.DepositHourlyAverage | Table | Historical average source; Other/DistinctDayHours for current DayOfWeek+Hour+FundingType=3 |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- No `SET NOCOUNT ON`; no parameters
- Output column has no alias (DDL ends the SELECT before adding `AS colName`) - callers receive an unnamed column
- Uses `Other` column from DepositHourlyAverage (not `Approved`), because PaymentStatusID=1 (New) falls in the "Other" bucket (NOT IN 2,3,4,35)
- Same midnight edge case as sibling SP: `DATEPART(hh, GETDATE()) - 1` can produce -1 at midnight
- `ISNULL(NULLIF(..., 0), 1)` prevents division by zero
- Sibling procedures: `LastHourTotalCreditCardApprovedDepositsVsHistory` (CC approvals), `LastHourTotalTechnicalVsHistory` (raw technical count)
- Comment in the DDL comment header: `-------------------------------------paypal new-----------------------------------` and a trailing comment after the GO: `--------------------------------------num of technical-----------------------------` (leftover scaffolding from when these SPs were written as a suite)

---

## 8. Sample Queries

### 8.1 Execute the alert check
```sql
EXEC Billing.LastHourTotalPayPalNewDepositsVsHistory
-- Returns: unnamed FLOAT (percentage vs historical average)
```

### 8.2 View PayPal historical baselines
```sql
SELECT DepositDay, DepositHour,
       Other, DistinctDayHours,
       CAST(Other AS FLOAT) / DistinctDayHours AS AvgOtherPerHour
FROM Billing.DepositHourlyAverage WITH (NOLOCK)
WHERE FundingTypeID = 3
ORDER BY DepositDay, DepositHour
```

### 8.3 Compare all three alert monitors (run together for ops triage)
```sql
EXEC Billing.LastHourTotalCreditCardApprovedDepositsVsHistory  -- CC approvals %
EXEC Billing.LastHourTotalPayPalNewDepositsVsHistory           -- PayPal new deposits %
EXEC Billing.LastHourTotalTechnicalVsHistory                   -- Technical failures (raw)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 7.8/10 (Elements: 8/10, Logic: 8/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 siblings analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LastHourTotalPayPalNewDepositsVsHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LastHourTotalPayPalNewDepositsVsHistory.sql*
