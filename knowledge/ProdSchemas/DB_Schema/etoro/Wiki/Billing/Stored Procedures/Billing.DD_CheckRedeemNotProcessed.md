# Billing.DD_CheckRedeemNotProcessed

> DataDog monitoring check that detects approved crypto redemptions stuck for 5+ business days when multiple redemptions stalled on the same day, alerting the payments team to a systemic processing failure affecting a batch of redemption requests.

| Property | Value |
|----------|-------|
| **Schema** | Billing |
| **Object Type** | Stored Procedure |
| **Key Identifier** | Returns 1-row result: value (count of stuck redeems) + RedeemIDList (CSV of affected RedeemIDs) |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

`Billing.DD_CheckRedeemNotProcessed` is a DataDog synthetic monitor procedure (DBAD-16, October 2022). It detects crypto redemption requests (`Billing.Redeem`) that have been approved (`RedeemStatusID=3`) but have not progressed further for 5 or more **business days**. The procedure is designed to catch a specific failure pattern: multiple redemptions stalling on the same calendar date, which indicates a systemic batch failure rather than isolated individual issues.

`Billing.Redeem` records the lifecycle of a customer's request to convert their crypto position to fiat currency and withdraw the proceeds. Status 3 (Approved) means the redemption has passed operations review and is queued for execution - it should proceed to position closing and blockchain transfer within the same business day. A queue of approved redemptions stuck on the same day for 5+ business days means something went wrong with that day's batch processing.

The business-day calculation is intentional: redemptions submitted on Friday evening might not be processed until Monday, so a simple calendar-day check would produce false alerts over weekends. The formula excludes Saturday and Sunday from the day count, using a standard SQL Server weekend-removal formula.

Returns the COUNT of affected records as `value` (not a 0/1 flag) plus a CSV of the specific `RedeemID` values for immediate investigation.

---

## 2. Business Logic

### 2.1 Business Day Age Calculation

**What**: Measures how many business days have elapsed since a redemption was approved, excluding weekends from the count.

**Columns/Parameters Involved**: `Billing.Redeem.LastModificationDate`, `@DaysThreshold`

**Rules**:
- Business day formula: `DATEDIFF(dd, LastModificationDate, GETUTCDATE()) - (DATEDIFF(wk, LastModificationDate, GETUTCDATE()) * 2) - IIF(DATEPART(dw, LastModificationDate) = 1, 1, 0) + IIF(DATEPART(dw, GETUTCDATE()) = 1, 1, 0)`
- Subtracts 2 calendar days per ISO week (Saturday and Sunday)
- Adjusts for edge case: if start date is Sunday (DATEPART(dw)=1), subtract 1 more
- Adjusts for edge case: if end date (today) is Sunday, add 1 back
- Default threshold: 5 business days - a full work week with no progress is considered a stall

**Example**:
```
Approved Friday 2026-03-13 -> Now: Wednesday 2026-03-18
  DATEDIFF(days) = 5 calendar days
  DATEDIFF(weeks) = 1 week -> -2 weekend days
  Business days = 5 - 2 = 3 business days (Mon, Tue, Wed)
  3 < 5 threshold -> NOT flagged
```

### 2.2 Batch Failure Pattern Detection

**What**: Filters to only alert when multiple redemptions stalled on the same calendar date, identifying systemic failures vs. isolated incidents.

**Columns/Parameters Involved**: `@RedeemsThreshold`, `Billing.Redeem.LastModificationDate` (cast to DATE)

**Rules**:
- The inner query groups redeems by their last modification date (as DATE, truncating time)
- Only dates where COUNT >= @RedeemsThreshold (default: 10) are included
- The outer query then counts and lists all redeems matching those qualifying dates
- Effect: 9 stalled redeems across 9 different dates would NOT alert. 10 stalled redeems all last modified on the same date WOULD alert.
- This pattern distinguishes: individual processing failures (scattered dates, < threshold) vs. batch job failures (many stalled on the same date)

**Diagram**:
```
Billing.Redeem WHERE RedeemStatusID=3 (Approved)
AND business_days_elapsed >= @DaysThreshold (5)
          |
    GROUP BY DATE(LastModificationDate)
          |
    HAVING COUNT >= @RedeemsThreshold (10)
          |
    qualifying_dates = {dates with 10+ stalled redeems}
          |
    Count all redeems matching those dates -> value
    STRING_AGG(RedeemID) -> RedeemIDList
```

---

## 3. Data Overview

N/A for stored procedure.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @DaysThreshold | INT | NO | 5 | CODE-BACKED | Minimum number of BUSINESS DAYS elapsed since LastModificationDate for an approved redemption to be considered stalled. Default of 5 = one full work week. Weekends are excluded from the count via a calendar adjustment formula. |
| 2 | @RedeemsThreshold | INT | NO | 10 | CODE-BACKED | Minimum number of stalled redemptions that must share the same last-modified DATE for that date to trigger the alert. Filters out isolated individual failures (< 10 on a date); targets batch-scale failures (10+ on the same date). |
| 3 | value (output) | INT | NO | - | CODE-BACKED | Count of approved redemptions (RedeemStatusID=3) that are 5+ business days old AND belong to a date where 10+ redeems are stalled. Zero means no systemic batch failure detected. A positive value indicates a batch processing outage. |
| 4 | RedeemIDList (output) | VARCHAR | YES | - | CODE-BACKED | Comma-separated list of RedeemID values for all redeems contributing to the alert count. Enables the payments and crypto operations team to identify and investigate the specific affected redemption requests. NULL when value=0. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| RedeemStatusID=3 filter | Billing.Redeem | Read | Reads Billing.Redeem filtering on RedeemStatusID=3 (Approved) and LastModificationDate. See [Billing.Redeem](../Tables/Billing.Redeem.md). |

### 5.2 Referenced By (other objects point to this)

Not analyzed in this phase. Called externally by DataDog synthetic monitors.

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Billing.DD_CheckRedeemNotProcessed (procedure)
└── Billing.Redeem (table)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Billing.Redeem | Table | Direct read; filters on RedeemStatusID=3 (Approved) and applies business-day age calculation to find batch-stalled redemptions |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| DataDog Synthetic Monitor | External | Calls this procedure on a schedule to detect systemic crypto redemption processing failures |

---

## 7. Technical Details

### 7.1 Indexes

N/A for stored procedure.

### 7.2 Constraints

N/A for stored procedure.

---

## 8. Sample Queries

### 8.1 Run with defaults (5 business days, 10 redeems threshold)

```sql
EXEC Billing.DD_CheckRedeemNotProcessed;
```

### 8.2 More sensitive check: 3 business days, 5 redeems on same date

```sql
EXEC Billing.DD_CheckRedeemNotProcessed
    @DaysThreshold = 3,
    @RedeemsThreshold = 5;
```

### 8.3 Manually investigate approved redeems that are stalled

```sql
SELECT RedeemID,
       RedeemStatusID,
       CAST(LastModificationDate AS DATE) AS StallDate,
       DATEDIFF(DAY, LastModificationDate, GETUTCDATE()) AS CalendarDays,
       -- Business days (approximate)
       DATEDIFF(DAY, LastModificationDate, GETUTCDATE())
           - (DATEDIFF(WEEK, LastModificationDate, GETUTCDATE()) * 2) AS BusinessDays
FROM Billing.Redeem WITH (NOLOCK)
WHERE RedeemStatusID = 3  -- Approved
  AND DATEDIFF(DAY, LastModificationDate, GETUTCDATE()) >= 5
ORDER BY LastModificationDate ASC;
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-18 | Enriched: 2026-03-18 | Quality: 9.0/10 (Elements: 10/10, Logic: 10/10, Relationships: 8/10, Sources: 6/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 4/6 (1, 5, 8, 10 applicable)*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 callers analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Billing.DD_CheckRedeemNotProcessed | Type: Stored Procedure | Source: etoro/etoro/Billing/Stored Procedures/Billing.DD_CheckRedeemNotProcessed.sql*
