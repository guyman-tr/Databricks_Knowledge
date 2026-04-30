# Trade.GetMarketCloseTimeByExDate_SS

> Scalar function that returns the UTC datetime of the last market close before a given ex-dividend date, used for dividend processing and corporate action scheduling.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Key Identifier** | Returns DATETIME |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMarketCloseTimeByExDate_SS determines the exact UTC datetime when a market last closed before a given ex-dividend date. This is critical for corporate action processing (dividends, stock splits) because positions must be evaluated at market close on the business day preceding the ex-date to determine entitlement.

The function exists because dividend eligibility depends on whether a customer held a position at the close of the trading day before the ex-date. Without this function, the system could not accurately determine the snapshot time for position eligibility checks. The "_SS" suffix likely stands for "Server Side" or "Shany's Special" (code comment references developer "Shany").

The function queries Trade.GetMarketTimes (a table-valued function that returns market schedules from Trade.MergedDailySchedules) filtered by exchange and optionally by instrument (for indices which have instrument-level overrides). It first validates that the ex-date is not further away than the next market open, then finds the last CloseTimeUTC before the ex-date.

---

## 2. Business Logic

### 2.1 Future Ex-Date Guard

**What**: Validation that prevents returning a close time for ex-dates that are too far in the future.

**Columns/Parameters Involved**: `@ExDate`, `@CurrentDatetime`, `@NextOpenDate`

**Rules**:
- If @ExDate is in the future relative to GETUTCDATE(), the function checks if it falls before or on the next market open date
- Finds the next date where IsOpen=1 and OpenTimeUTC >= current UTC time
- If no next open date is found, or if @ExDate is beyond the next open date, returns NULL
- This prevents processing dividends for ex-dates that have not yet been reached in the market calendar

**Diagram**:
```
  Current UTC --> Next Market Open Date --> Ex-Date
      |                  |                    |
      |  if ExDate <= NextOpenDate: VALID     |
      |  if ExDate >  NextOpenDate: NULL      |
      |  if ExDate is past: SKIP validation   |
```

### 2.2 Last Close Time Resolution

**What**: Finds the most recent market close datetime (UTC) before the ex-date.

**Columns/Parameters Involved**: `@ExDate`, `CloseTimeUTC`, `IsOpen`, `Date`

**Rules**:
- Queries Trade.GetMarketTimes for dates where IsOpen=1 and Date < @ExDate
- Orders by Date DESC and takes TOP 1 to get the latest close before ex-date
- Uses CloseTimeUTC (UTC times are authoritative; local times OpenTime/CloseTime have known bugs per code comments)
- For instruments that are indices (InstrumentTypeID=4), instrument-level overrides exist in MergedDailySchedules; the @InstrumentId parameter enables this

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeId | INT | NO | - | CODE-BACKED | The exchange identifier for market schedule lookup. Determines which market calendar to use (e.g., NYSE, LSE, TASE). Passed to Trade.GetMarketTimes to filter schedules by exchange. |
| 2 | @InstrumentId | INT | YES | NULL | CODE-BACKED | Optional instrument identifier for index-specific schedule overrides. Per code comments: "Should have a value only for indices (InstrumentTypeID = 4)" because indices often have instrument-level schedule overrides rather than exchange-level defaults. |
| 3 | @ExDate | DATE | NO | - | CODE-BACKED | The ex-dividend date (or corporate action effective date) for which the preceding market close time is needed. This is the date on which a stock begins trading without the value of its next dividend/corporate action. |
| 4 | Return value | DATETIME | YES | - | CODE-BACKED | The UTC datetime of the last market close before @ExDate. Returns NULL if: (a) @ExDate is in the future and beyond the next market open date, or (b) no matching open-market date is found before @ExDate. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @ExchangeId, @InstrumentId | Trade.GetMarketTimes | Function call | Called to retrieve market open/close schedule filtered by exchange and optional instrument override |

### 5.2 Referenced By (other objects point to this)

No direct consumers found in the codebase. This appears to be a standalone variant (the primary version is Trade.GetMarketCloseTimeByExDate without the _SS suffix).

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMarketCloseTimeByExDate_SS (function)
  +-- Trade.GetMarketTimes (function)
        +-- Trade.MergedDailySchedules (synonym -> CalendarDB.Market.MergedDailySchedules)
```

---

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.GetMarketTimes | Function | Called with @ExchangeId and @InstrumentId to retrieve market schedules. Queried twice: once for next-open validation, once for last-close resolution. |

### 6.2 Objects That Depend On This

No dependents found.

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

None.

---

## 8. Sample Queries

### 8.1 Get market close time before a specific ex-date for an exchange
```sql
SELECT Trade.GetMarketCloseTimeByExDate_SS(1, NULL, '2026-03-10') AS LastCloseBeforeExDate
```

### 8.2 Get market close time for an index instrument with override
```sql
SELECT Trade.GetMarketCloseTimeByExDate_SS(1, 1001, '2026-03-10') AS LastCloseBeforeExDate
```

### 8.3 Validate against multiple ex-dates for dividend processing
```sql
SELECT ExDate,
       Trade.GetMarketCloseTimeByExDate_SS(ExchangeID, NULL, ExDate) AS MarketCloseUTC
FROM   (VALUES ('2026-03-10'), ('2026-03-15'), ('2026-03-20')) AS D(ExDate)
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found specifically for this _SS variant function.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 7/10, Relationships: 5/10, Sources: 4/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 6/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMarketCloseTimeByExDate_SS | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetMarketCloseTimeByExDate_SS.sql*
