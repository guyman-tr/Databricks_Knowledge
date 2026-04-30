# Billing.LastHourTotalCreditCardApprovedDepositsVsHistory

> Returns the ratio (as a percentage) of credit card approved deposits in the previous hour compared to the historical hourly average for the same day-of-week and hour - an ops alerting indicator for detecting credit card payment provider outages.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns scalar ratio (lastHourApprovedVSavgApprovedPerHour) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.LastHourTotalCreditCardApprovedDepositsVsHistory` is an ops alerting probe that answers: "Is credit card deposit approval volume normal right now?" It computes the ratio of actual approved credit card deposits in the previous hour against the historical hourly average for that same day-of-week/hour slot, returning the result as a percentage.

A result near 100% means approval volume is on pace with history. A significant drop (e.g., below 50%) indicates that fewer credit card deposits are being approved than expected for this time period - a potential signal of a payment provider outage, processing degradation, or routing failure. Operations teams use this alongside `Billing.LastHourTotalPayPalNewDepositsVsHistory` and `Billing.LastHourTotalTechnicalVsHistory` as a suite of payment health monitors.

Data flows: called by the ops monitoring system or dashboard on a scheduled basis (typically hourly). The procedure reads from `Billing.Deposit` for the live count and from `Billing.DepositHourlyAverage` for the historical baseline. No parameters are needed - the time window is computed internally.

---

## 2. Business Logic

### 2.1 Last Hour vs Historical Average Ratio

**What**: Computes (last hour approved CC deposits) / (historical avg approved per hour for this day+hour) * 100.

**Columns/Parameters Involved**: `FundingTypeID`, `PaymentStatusID`, `PaymentDate`, `DepositDay`, `DepositHour`, `Approved`, `DistinctDayHours`

**Rules**:
- `@lastHour = DATEPART(hh, GETDATE()) - 1`: previous hour (0-23). Note: at midnight (hour=0), this produces -1 - edge case not handled in the DDL
- `@currentDayOfWeek = DATEPART(DW, GETDATE())`: 1=Sunday, 2=Monday, ..., 7=Saturday (SQL Server convention)
- Live count filter: `FundingTypeID=1` (Credit Card), `PaymentStatusID=2` (Approved), `DATEPART(hh, PaymentDate) = @lastHour AND PaymentDate > DATEADD(hh, -2, GETDATE())` - the 2-hour window prevents midnight boundary issues
- Historical baseline: `Billing.DepositHourlyAverage.Approved / DistinctDayHours` for `FundingTypeID=1, DepositDay=@currentDayOfWeek, DepositHour=@lastHour`
- `ISNULL(NULLIF(<avg>, 0), 1)`: if historical average is 0 (no history for this slot), use 1 as denominator to avoid division by zero
- Result column: `lastHourApprovedVSavgApprovedPerHour` (FLOAT, percentage: 100=normal, <50=potential issue)
- No parameters; no SET NOCOUNT ON

**Diagram**:
```
Called at hourly interval by ops monitoring
        |
        v
@lastHour = current hour - 1
@currentDayOfWeek = current day of week
        |
        v
liveCount = COUNT(*) FROM Billing.Deposit JOIN Billing.Funding
  WHERE FundingTypeID=1 AND PaymentStatusID=2
  AND DATEPART(hh, PaymentDate)=@lastHour
  AND PaymentDate > GETDATE()-2h
        |
        v
historicalAvg = Approved / DistinctDayHours
  FROM Billing.DepositHourlyAverage
  WHERE FundingTypeID=1 AND DepositDay=@currentDayOfWeek AND DepositHour=@lastHour
        |
        v
Result = (liveCount / historicalAvg) * 100
  100% = normal volume
  <50% = investigate payment provider
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
| 1 | lastHourApprovedVSavgApprovedPerHour | FLOAT | CODE-BACKED | Ratio of last hour's approved CC deposits to historical average for this day/hour, expressed as a percentage. 100.0 = exactly on pace with history. Values significantly below 100 (e.g., <50) indicate potential credit card payment processing issues. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| Live count | Billing.Deposit | READ | Counts approved (PaymentStatusID=2) CC deposits in previous hour (PaymentDate window) |
| Live count | Billing.Funding | READ | JOINed on FundingID to filter FundingTypeID=1 (Credit Card) |
| Historical baseline | Billing.DepositHourlyAverage | READ | Provides Approved/DistinctDayHours as historical hourly average for the current day+hour+FundingType slot |

### 5.2 Referenced By (other objects point to this)

No stored procedure callers found in the Billing schema. Called from the ops alerting/monitoring system on a scheduled basis to detect payment provider health anomalies.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.LastHourTotalCreditCardApprovedDepositsVsHistory (procedure)
├── Billing.Deposit (table - live approved deposit count)
├── Billing.Funding (table - FundingType filter)
└── Billing.DepositHourlyAverage (table - historical baseline)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Deposit | Table | COUNT of approved CC deposits in last hour; filtered by PaymentStatusID=2, PaymentDate window |
| Billing.Funding | Table | JOINed on FundingID for FundingTypeID=1 (Credit Card) filter |
| Billing.DepositHourlyAverage | Table | Historical average source; Approved/DistinctDayHours for current DayOfWeek+Hour+FundingType |

### 6.2 Objects That Depend On This

No dependents found within the Billing schema stored procedures.

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

N/A for Stored Procedure.

**Implementation notes**:
- No `SET NOCOUNT ON` - row count messages are emitted
- No parameters - time window is computed dynamically from `GETDATE()`
- `DATEPART(hh, GETDATE()) - 1` edge case at midnight: produces `@lastHour = -1` (no deposits will match, result will be 0/historicalAvg; callers should handle midnight edge case)
- The 2-hour window `PaymentDate > DATEADD(hh, -2, GETDATE())` is wider than the hour slot filter to guard against clock skew or boundary deposits
- `ISNULL(NULLIF(avg, 0), 1)` prevents division by zero for time slots with no historical data (new hours, low-traffic periods)
- Sibling procedures: `LastHourTotalPayPalNewDepositsVsHistory` (FundingTypeID=3), `LastHourTotalTechnicalVsHistory` (raw count)

---

## 8. Sample Queries

### 8.1 Execute the alert check
```sql
EXEC Billing.LastHourTotalCreditCardApprovedDepositsVsHistory
-- Returns: lastHourApprovedVSavgApprovedPerHour FLOAT
-- 100.0 = on pace, <50.0 = investigate
```

### 8.2 Manual equivalent for a specific hour/day
```sql
DECLARE @lastHour INT = DATEPART(hh, GETDATE()) - 1
DECLARE @currentDayOfWeek INT = DATEPART(DW, GETDATE())

SELECT (
    (SELECT CAST(COUNT(*) AS FLOAT)
     FROM Billing.Deposit bd WITH (NOLOCK)
     JOIN Billing.Funding bf WITH (NOLOCK) ON bd.FundingID = bf.FundingID
     WHERE bf.FundingTypeID = 1
       AND bd.PaymentStatusID = 2
       AND DATEPART(hh, bd.PaymentDate) = @lastHour
       AND bd.PaymentDate > DATEADD(hh, -2, GETDATE()))
    /
    ISNULL(NULLIF(
        (SELECT CAST(Approved / DistinctDayHours AS FLOAT)
         FROM Billing.DepositHourlyAverage WITH (NOLOCK)
         WHERE FundingTypeID = 1
           AND DepositDay = @currentDayOfWeek
           AND DepositHour = @lastHour), 0), 1)
) * 100 AS lastHourApprovedVSavgApprovedPerHour
```

### 8.3 View current historical baselines for credit cards
```sql
SELECT DepositDay, DepositHour,
       Approved, DistinctDayHours,
       CAST(Approved AS FLOAT) / DistinctDayHours AS AvgApprovedPerHour
FROM Billing.DepositHourlyAverage WITH (NOLOCK)
WHERE FundingTypeID = 1
ORDER BY DepositDay, DepositHour
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this specific procedure. Context derived from `Billing.DepositHourlyAverage` documentation which explicitly documents this procedure as a primary consumer.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 8.0/10 (Elements: 8/10, Logic: 9/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 1 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/6*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 2 siblings analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.LastHourTotalCreditCardApprovedDepositsVsHistory | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.LastHourTotalCreditCardApprovedDepositsVsHistory.sql*
