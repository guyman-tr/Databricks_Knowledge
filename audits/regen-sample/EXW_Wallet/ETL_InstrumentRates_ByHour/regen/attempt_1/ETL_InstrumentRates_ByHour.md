# EXW_Wallet.ETL_InstrumentRates_ByHour

> 6.7M-row hourly instrument rate aggregation table tracking average ask and bid rates per instrument per hour from April 2018 to present. Populated by `SP_ETL_InstrumentRates_ByHour` from `EXW_Currency.vInstrumentRatesForWeek`, refreshed daily with a delete-and-reinsert pattern covering the previous day and current day.

| Property | Value |
|----------|-------|
| **Schema** | EXW_Wallet |
| **Object Type** | Table |
| **Production Source** | Unknown (no resolvable upstream wiki; data originates from `EXW_Currency.vInstrumentRatesForWeek` which is a Synapse-internal staging table for currency/instrument rate feeds) |
| **Refresh** | Daily — `SP_ETL_InstrumentRates_ByHour @date` deletes from `@prevdateid` onward and reinserts for previous day + current day |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC, InstrumentID ASC) |
| **UC Target** | _Not_Migrated |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`ETL_InstrumentRates_ByHour` is an intermediate ETL table that stores hourly-aggregated instrument rates (ask and bid) for the eXw (eToroX/Wallet) currency domain. It contains approximately 6.7 million rows spanning from April 2018 to present, covering ~193 distinct instruments in recent data.

The table is populated by `EXW_Wallet.SP_ETL_InstrumentRates_ByHour`, which reads from `EXW_Currency.vInstrumentRatesForWeek` — a staging table holding raw instrument rate snapshots with `DateFrom`/`DateTo` validity windows. The SP aggregates these raw rates into hourly buckets using `AVG()` on ask and bid rates, grouped by instrument and hour.

The load pattern is a **sliding two-day window**: the SP deletes all rows with `DateID >= @prevdateid` (yesterday), then inserts aggregated rows for both the previous day and the current day in two separate INSERT blocks. This ensures rates are recalculated for the prior day (to capture late-arriving rate entries) and extended to the current day.

The table serves as an upstream source for `EXW_Wallet.SP_Prices`, which joins it with instrument-to-crypto mappings to produce the final `EXW_Wallet.EXW_Price` and `EXW_Wallet.EXW_PriceDaily` tables used by the wallet pricing domain.

---

## 2. Business Logic

### 2.1 Hourly Rate Aggregation

**What**: Raw instrument rates from `vInstrumentRatesForWeek` are averaged into hourly buckets.
**Columns Involved**: AskRateAvg, BidRateAvg, InstrumentID, DateHour
**Rules**:
- `AskRateAvg = AVG(AskRate)` grouped by InstrumentId and hour bucket
- `BidRateAvg = AVG(BidRate)` grouped by InstrumentId and hour bucket
- The hour bucket is derived from `DateFrom` using `DATEADD(HOUR, DATEPART(HOUR, DateFrom), ...)`, truncating to the start of the hour

### 2.2 Date Boundary Handling

**What**: Rates that span midnight are assigned to the correct date using CASE logic.
**Columns Involved**: DateHour, Date, DateID
**Rules**:
- If `CAST(DateFrom AS DATE)` falls within the target day range (`>= @date` and `< @date + 1`), the actual `DateFrom` date and hour are used
- If `DateFrom` falls outside the target day (edge case for rates spanning midnight), the rate is assigned to the target date at midnight (the day boundary)
- Rows are excluded where `DateFrom` equals the day before the previous day and `DateTo` equals the previous day (stale entries)
- The WHERE clause ensures only overlapping rates are captured: `DateFrom < DATEADD(D,1,@date) AND DateTo > @date`

### 2.3 Two-Pass Daily Load

**What**: The SP processes two windows per execution — previous day and current day.
**Columns Involved**: All columns
**Rules**:
- First INSERT block: aggregates rates for `@prevdate` (yesterday)
- Second INSERT block: aggregates rates for `@date` (today)
- Both use identical logic but with different date parameters
- DELETE removes all rows with `DateID >= @prevdateid` before insertion, ensuring idempotent reprocessing

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

- **ROUND_ROBIN** distribution — no co-location benefit; any join will require data movement
- **CLUSTERED INDEX on (DateID, InstrumentID)** — optimal for range queries on DateID with optional InstrumentID filter
- Always filter on `DateID` first for best performance

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| What was the average hourly rate for instrument X on date Y? | `WHERE InstrumentID = X AND DateID = Y` |
| What is the bid-ask spread trend for an instrument? | `SELECT DateHour, AskRateAvg - BidRateAvg AS Spread WHERE InstrumentID = X AND DateID BETWEEN ...` |
| How many instruments have rate data on a given day? | `SELECT COUNT(DISTINCT InstrumentID) WHERE DateID = Y` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|----------------|---------|
| EXW_Currency.Instruments | InstrumentID = Instruments.Id | Resolve instrument names and currency pairs |
| EXW_Wallet.EXW_Price | InstrumentID + DateHour = DateFrom | Compare hourly aggregates with final price table |

### 3.4 Gotchas

- **DateHour is not always the actual hour**: for rates spanning midnight boundaries, `DateHour` may be set to the target date at 00:00:00 rather than the actual timestamp hour
- **Bid-Ask spread is narrow**: the ~0.01 spread visible in sample data is expected for most instruments; anomalies may indicate low-liquidity hours
- **UpdateDate is ETL run time**, not the time the rate was recorded — do not use it for rate validity
- **Two-day overlap**: rows for yesterday are deleted and reinserted on every run; do not assume a row's UpdateDate reflects its first insertion

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code / ETL logic |
| Tier 3 | No traceable source; grounded in DDL |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InstrumentID | int | YES | Instrument identifier, passthrough from `EXW_Currency.vInstrumentRatesForWeek.InstrumentId`. Identifies the currency pair or crypto instrument whose rates are aggregated. (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 2 | AskRateAvg | numeric(36,18) | YES | Hourly average of the ask (offer) rate. Computed as `AVG(AskRate)` from `EXW_Currency.vInstrumentRatesForWeek`, grouped by instrument and hour bucket. (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 3 | BidRateAvg | numeric(36,18) | YES | Hourly average of the bid rate. Computed as `AVG(BidRate)` from `EXW_Currency.vInstrumentRatesForWeek`, grouped by instrument and hour bucket. (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 4 | DateHour | datetime | YES | Start of the hourly bucket for the aggregated rates. Derived from `DateFrom` via `DATEADD(HOUR, DATEPART(HOUR, DateFrom), CAST(...))`. For rates spanning the date boundary, set to the target date at midnight (00:00:00). (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 5 | Date | date | YES | Calendar date of the rate record. Derived from `DateFrom` via `CAST(DateFrom AS DATE)` when within the target day; otherwise set to the target date parameter. (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 6 | DateID | int | YES | Integer date key in YYYYMMDD format. Derived from `DateFrom` via `CONVERT(VARCHAR(8), CAST(DateFrom AS DATE), 112)` when within the target day; otherwise set to the target date as integer. Used as the leading clustered index column. (Tier 2 — EXW_Currency.vInstrumentRatesForWeek) |
| 7 | UpdateDate | datetime | YES | Timestamp of the ETL execution that inserted the row. Set to `GETDATE()` at insert time by `SP_ETL_InstrumentRates_ByHour`. Not the rate observation time. (Tier 2 — SP_ETL_InstrumentRates_ByHour) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| InstrumentID | EXW_Currency.vInstrumentRatesForWeek | InstrumentId | Passthrough |
| AskRateAvg | EXW_Currency.vInstrumentRatesForWeek | AskRate | AVG() by instrument + hour |
| BidRateAvg | EXW_Currency.vInstrumentRatesForWeek | BidRate | AVG() by instrument + hour |
| DateHour | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE + DATEADD(HOUR, ...) |
| Date | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE + CAST AS DATE |
| DateID | EXW_Currency.vInstrumentRatesForWeek | DateFrom | CASE + CONVERT(VARCHAR(8), ..., 112) |
| UpdateDate | SP_ETL_InstrumentRates_ByHour | — | GETDATE() |

### 5.2 ETL Pipeline

```
EXW_Currency.vInstrumentRatesForWeek (staging table — raw instrument rate snapshots)
  |-- SP_ETL_InstrumentRates_ByHour @date ---|
  |   DELETE WHERE DateID >= @prevdateid     |
  |   INSERT AVG rates by instrument + hour  |
  v
EXW_Wallet.ETL_InstrumentRates_ByHour (~6.7M rows, hourly aggregates)
  |-- SP_Prices @dt ---|
  |   JOIN with instrument-to-crypto mapping |
  v
EXW_Wallet.EXW_Price (hourly crypto prices)
EXW_Wallet.EXW_PriceDaily (daily crypto prices)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|----------------|-------------|
| InstrumentID | EXW_Currency.vInstrumentRatesForWeek | Source of instrument rate data |
| InstrumentID | EXW_Currency.Instruments | Instrument master data (Id, BuyCurrencyId, SellCurrencyId) |

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|----------------|-------------|
| InstrumentID, AskRateAvg, BidRateAvg, DateHour | EXW_Wallet.SP_Prices | Reads hourly rates to build EXW_Price and EXW_PriceDaily |

---

## 7. Sample Queries

### 7.1 Hourly Rate History for a Specific Instrument

```sql
SELECT InstrumentID, DateHour, AskRateAvg, BidRateAvg,
       AskRateAvg - BidRateAvg AS Spread
FROM EXW_Wallet.ETL_InstrumentRates_ByHour
WHERE InstrumentID = 196
  AND DateID = 20260425
ORDER BY DateHour;
```

### 7.2 Daily Average Rate Across All Hours

```sql
SELECT InstrumentID, Date,
       AVG(AskRateAvg) AS DailyAvgAsk,
       AVG(BidRateAvg) AS DailyAvgBid,
       COUNT(*) AS HourBuckets
FROM EXW_Wallet.ETL_InstrumentRates_ByHour
WHERE DateID BETWEEN 20260401 AND 20260430
GROUP BY InstrumentID, Date
ORDER BY InstrumentID, Date;
```

### 7.3 Instruments with Widest Bid-Ask Spread

```sql
SELECT TOP 20 InstrumentID, DateID,
       MAX(AskRateAvg - BidRateAvg) AS MaxSpread
FROM EXW_Wallet.ETL_InstrumentRates_ByHour
WHERE DateID >= 20260401
GROUP BY InstrumentID, DateID
ORDER BY MaxSpread DESC;
```

---

## 8. Atlassian Knowledge Sources

No Jira or Confluence sources found for this object.

---

*Generated: 2026-04-30 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 7 T2, 0 T3, 0 T4, 0 T5 | Elements: 7/7, Logic: 7/10, Lineage: complete*
*Object: EXW_Wallet.ETL_InstrumentRates_ByHour | Type: Table | Production Source: Unknown (EXW_Currency.vInstrumentRatesForWeek — Synapse-internal staging)*
