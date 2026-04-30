# Trade.GetMarketCloseTimeByExDate

> Returns the last market close datetime (UTC) before a given ex-date for an exchange/instrument, with special handling for futures instruments that have their own close hours.

| Property | Value |
|----------|-------|
| **Schema** | Trade |
| **Object Type** | Scalar Function |
| **Return Type** | DATETIME |
| **Partition** | N/A |
| **Indexes** | N/A |

---

## 1. Business Meaning

Trade.GetMarketCloseTimeByExDate determines the exact UTC datetime of the last market close before a corporate action ex-date (e.g., dividend, stock split). This timestamp is critical for corporate actions processing: it defines the snapshot time at which position holdings are evaluated to determine eligibility for the corporate action.

The function handles two distinct instrument categories:
1. **Futures instruments**: Use a dedicated close hour from `Trade.FutureInstruments`, computed as one day before the ex-date plus the instrument's specific UTC close time
2. **Regular instruments (including indices)**: Look up the last actual market close from `Trade.GetMarketTimes` (which reads `Trade.MergedDailySchedules`)

Returns NULL if the close time hasn't occurred yet (still in the future), ensuring corporate actions are only processed after the market has actually closed.

---

## 2. Business Logic

### 2.1 Futures Close Time Resolution

**What**: Futures instruments bypass schedule lookup and use their own `CloseHourUTC` from `Trade.FutureInstruments`.

**Rules**:
- Look up `CloseHourUTC` for the instrument in `Trade.FutureInstruments`
- If found: close datetime = (ExDate - 1 day) + CloseHourUTC
- Only return if `@CloseDateTimeUTC < GETUTCDATE()` (must be in the past)
- Returns NULL if close hasn't happened yet

### 2.2 Regular Instrument Close Time Resolution

**What**: Uses `Trade.GetMarketTimes` to find the last actual market close before the ex-date.

**Rules**:
- Query `Trade.GetMarketTimes(@ExchangeId, @InstrumentId)` for open days (`IsOpen=1`) before `@ExDate`
- Order by Date DESC, CloseTimeUTC DESC to get the most recent close
- Take TOP 1 result
- Return NULL if: no close time exists in the table, OR the close time is still in the future

### 2.3 Time Safety Guard

**What**: All paths return NULL if the computed close time is in the future.

**Rules**:
- Futures: `@CloseDateTimeUTC < GETUTCDATE()` must be true
- Regular: `@LastCloseDatetimeUTCBeforeExDate > GETUTCDATE()` causes NULL return
- Prevents premature processing of corporate actions

---

## 3. Data Overview

N/A for function.

---

## 4. Elements

| # | Element | Type | Nullable | Default | Confidence | Description |
|---|---------|------|----------|---------|------------|-------------|
| 1 | @ExchangeId | INT | NO | - | CODE-BACKED | Exchange identifier. Used to query market schedules. |
| 2 | @InstrumentId | INT | YES | NULL | CODE-BACKED | Instrument identifier. Required for indices (InstrumentTypeID=4) and futures. NULL for standard instruments using exchange-level schedules. |
| 3 | @ExDate | DATE | NO | - | CODE-BACKED | Corporate action ex-date. The function finds the last market close BEFORE this date. |
| 4 | Return value | DATETIME | YES | - | CODE-BACKED | UTC datetime of the last market close before the ex-date. NULL if not yet occurred or no data available. |

---

## 5. Relationships

### 5.1 References To (this object points to)

| Element | Related Object | Relationship Type | Description |
|---------|---------------|-------------------|-------------|
| @InstrumentId | Trade.FutureInstruments | SELECT | Looks up futures-specific CloseHourUTC |
| @ExchangeId, @InstrumentId | Trade.GetMarketTimes | Function call | Gets market schedule data for regular instruments |

### 5.2 Referenced By (other objects point to this)

| Source Object | Source Element | Relationship Type | Description |
|--------------|---------------|-------------------|-------------|
| Corporate actions procedures | Parameter | Function call | Determines snapshot time for position eligibility |

---

## 6. Dependencies

### 6.0 Dependency Chain

```
Trade.GetMarketCloseTimeByExDate (function)
  ├── Trade.FutureInstruments (table)
  └── Trade.GetMarketTimes (function)
        └── Trade.MergedDailySchedules (synonym → cross-schema)
```

### 6.1 Objects This Depends On

| Object | Type | How Used |
|--------|------|----------|
| Trade.FutureInstruments | Table | Reads CloseHourUTC for futures instruments |
| Trade.GetMarketTimes | Function | Gets market schedule for regular instruments |

### 6.2 Objects That Depend On This

| Object | Type | How Used |
|--------|------|----------|
| Corporate actions / dividend procedures | Procedures | Called to determine snapshot time for eligibility |

---

## 7. Technical Details

### 7.1 Indexes

N/A for function.

### 7.2 Constraints

| Constraint | Type | Expression / Meaning |
|-----------|------|---------------------|
| RETURNS DATETIME | Return type | Scalar function returning nullable datetime |
| Future-time guard | Safety | Returns NULL if computed close time is still in the future |
| TOP 1 with ORDER BY DESC | Resolution | Gets the most recent close before ex-date |

### 7.3 Developer Notes (from source comments)

- `MergedDailySchedules`: `Date` is in exchange local time; do NOT rely on `OpenTime`/`CloseTime` (local, have bugs) — use only `OpenTimeUTC`/`CloseTimeUTC`
- Indices always expect instrument-override data in the schedule; their exchange usually has no exchange-level default
- Multiple rows per day + instrument may indicate trading slots with breaks; only the last slot matters for close time
- Futures patch added 2021-05-18 by Adam & Shany for indices that are Futures, refined 2021-05-30 with specific UTC times per futures instrument

---

## 8. Sample Queries

### 8.1 Get close time for a stock dividend ex-date

```sql
SELECT  Trade.GetMarketCloseTimeByExDate(1, NULL, '2026-03-15') AS CloseTimeUTC;
```

### 8.2 Get close time for an index instrument

```sql
SELECT  Trade.GetMarketCloseTimeByExDate(1, 5001, '2026-03-15') AS CloseTimeUTC;
```

### 8.3 Get close time for a futures instrument

```sql
SELECT  Trade.GetMarketCloseTimeByExDate(1, 7001, '2026-03-15') AS CloseTimeUTC;
-- Uses FutureInstruments.CloseHourUTC if instrument 7001 is a future
```

---

## 9. Atlassian Knowledge Sources

No Atlassian sources found for this object.

---

*Generated: 2026-03-15 | Enriched: - | Quality: 8.5/10 (Elements: 10/10, Logic: 10/10, Relationships: 7/10, Sources: 5/10)*
*Confidence: 0 EXPERT, 0 VERIFIED, 4 CODE-BACKED, 0 ATLASSIAN-ONLY, 0 NAME-INFERRED | Phases: 7/7*
*Sources: Atlassian: 0 Confluence + 0 Jira | Procedures: 0 analyzed | App Code: 0 repos / 0 files | Corrections: 0 applied*
*Object: Trade.GetMarketCloseTimeByExDate | Type: Scalar Function | Source: etoro/etoro/Trade/Functions/Trade.GetMarketCloseTimeByExDate.sql*
