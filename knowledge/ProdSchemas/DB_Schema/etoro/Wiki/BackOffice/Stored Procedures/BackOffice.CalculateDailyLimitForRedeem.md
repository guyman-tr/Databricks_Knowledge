# BackOffice.CalculateDailyLimitForRedeem

> Calculates the average daily redemption amount for a specific instrument, based on Billing.Redeem records from the same day-of-week over the past N weeks, to establish automated approval thresholds for crypto/stock redemptions.

| Property | Value |
|----------|-------|
| **Schema** | BackOffice |
| **Object Type** | Stored Procedure |
| **Key Identifier** | InstrumentID |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

This procedure calculates the historical daily redemption baseline for a specific financial instrument (typically a crypto or real-stock asset), used to set automated approval thresholds for the BackOffice redeem auto-execution system. Like its counterpart CalculateDailyLimitForAutoExecution (cashouts), it uses same-day-of-week averaging to remove weekday seasonality from the baseline.

Redemptions (Billing.Redeem) are customer requests to sell real assets (crypto, stocks, ETFs) back into cash. The procedure returns the average daily redemption volume for a given instrument on the specified day-of-week, providing the auto-execution system with a reference level to detect unusual redemption spikes.

Key difference from CalculateDailyLimitForAutoExecution: this procedure is per-instrument (not per funding type) and requires an explicit @RequestDate parameter (the date being evaluated) rather than using GETDATE(), making it suitable for both real-time and backfill/testing scenarios. Default InstrumentID=100000 (a specific instrument). Created 07/11/2022 by KateM (MIMOPSB-1875).

---

## 2. Business Logic

### 2.1 Same-Day-of-Week Rolling Average for Redeem

**What**: Computes total daily redemption volume for a specific instrument (same weekday only) then averages across the lookback window.

**Tables Involved**: `Billing.Redeem`

**Rules**:
- Day-of-week filter: DATEPART(WEEKDAY, RequestDate) = DATEPART(WEEKDAY, @RequestDate)
- Lookback: @TimePeriodWeeks weeks before @RequestDate (default 4 weeks)
- RequestDate < @RequestDate - excludes the reference date itself (historical data only)
- InstrumentID filter: only the specified instrument's redemptions are included
- No status filter (unlike CalculateDailyLimitForAutoExecution which filters CashoutStatusID=3) - all Redeem records included
- Two-step aggregation: SUM(AmountOnRequest) per day -> AVG(DailyTotal) as final DailyLimit

---

## 3. Data Overview

N/A for Stored Procedure.

---

## 4. Elements

**Input Parameters:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @TimePeriodWeeks | INT | YES | 4 | CODE-BACKED | Number of weeks of history to average. Default=4. Increase for more stable baseline. |
| 2 | @InstrumentID | INT | YES | 100000 | CODE-BACKED | The instrument to calculate the daily limit for. Default=100000 (a specific crypto/stock instrument). References Billing.Redeem.InstrumentID. |
| 3 | @RequestDate | DATETIME2 | NO | - | VERIFIED | The reference date for the calculation. The day-of-week is extracted from this date. Historical data before this date is used. Required - no default. |

**Result Set:**

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 4 | InstrumentID | INT | NO | - | CODE-BACKED | The instrument ID that was calculated (same as @InstrumentID input). |
| 5 | DailyLimit | (decimal) | YES | - | CODE-BACKED | AVG of daily AmountOnRequest totals for this instrument on same-weekday days over the lookback period. NULL if no historical redemption data exists for this instrument/weekday combination. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentID, @RequestDate | Billing.Redeem | READER | Reads redemption records for the specified instrument within the rolling lookback window |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| BackOffice redeem auto-execution system | DailyLimit result | Caller | Uses per-instrument daily limit to evaluate redemption auto-approval thresholds |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
BackOffice.CalculateDailyLimitForRedeem (procedure)
+-- Billing.Redeem (table) [READER - redemption records for specified instrument]
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table (cross-schema) | Source of redemption records; filtered on InstrumentID and same-weekday RequestDate within lookback window |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| BackOffice redeem auto-execution system | External | Calls to retrieve daily redemption limit for specific instruments |

---

## 7. Technical Details

### 7.1 Indexes

N/A for Stored Procedure.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| SET NOCOUNT ON | Performance | Suppresses row-count messages |
| No status filter | Design | Unlike cashout version (CashoutStatusID=3), all Billing.Redeem records included regardless of status |
| Same-weekday filter | Seasonality control | DATEPART(WEEKDAY, RequestDate) = DATEPART(WEEKDAY, @RequestDate) |
| @RequestDate required | Design | No default - caller must supply the evaluation date (allows historical/backfill use unlike GETDATE()) |
| Temp table (#Redeemstmp) | Intermediate | Two-step aggregation; no explicit DROP |
| Created: MIMOPSB-1875 | Change ref | 07/11/2022 KateM - Redeem daily average per InstrumentID |

---

## 8. Sample Queries

### 8.1 Get daily limit for today's redemptions on instrument 100000

```sql
EXEC BackOffice.CalculateDailyLimitForRedeem
    @RequestDate = GETDATE()
-- Returns DailyLimit for InstrumentID=100000 (default)
```

### 8.2 Get daily limit for a specific instrument and date

```sql
EXEC BackOffice.CalculateDailyLimitForRedeem
    @TimePeriodWeeks = 4,
    @InstrumentID = 5001,       -- specific crypto/stock instrument
    @RequestDate = '2026-03-17'
```

### 8.3 Verify redemption history for an instrument

```sql
SELECT
    InstrumentID,
    CAST(RequestDate AS DATE) AS RedeemDate,
    DATEPART(WEEKDAY, RequestDate) AS WeekDay,
    SUM(AmountOnRequest) AS TotalAmount
FROM Billing.Redeem WITH (NOLOCK)
WHERE InstrumentID = 100000
  AND RequestDate >= DATEADD(WEEK, -4, GETDATE())
GROUP BY InstrumentID, CAST(RequestDate AS DATE), DATEPART(WEEKDAY, RequestDate)
ORDER BY RedeemDate DESC
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Created for MIMOPSB-1875 - Jira ticket not accessible via current MCP.)

---

*Generated: 2026-03-17 | Enriched: 2026-03-17 | Quality: 9.0/10 (Elements: 9/10, Logic: 9/10, Relationships: 9/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 1 VERIFIED, 2 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 5/11 (1, 5, 8, 9, 10)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 1 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: BackOffice.CalculateDailyLimitForRedeem | Type: Stored Procedure | Source: etoro/etoro/BackOffice/Stored Procedures/BackOffice.CalculateDailyLimitForRedeem.sql*
