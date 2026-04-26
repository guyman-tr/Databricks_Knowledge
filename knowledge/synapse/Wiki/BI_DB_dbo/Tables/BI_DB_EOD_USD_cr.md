# BI_DB_dbo.BI_DB_EOD_USD_cr

> 17.56M-row daily end-of-day USD conversion rate table storing per-instrument long (bid-based) and short (ask-based) USD conversion rates from January 2015 to present (4,119 trading days, 15,415 instruments). Populated daily by SP_EOD_USD_cr via DELETE+INSERT from DWH_dbo.Fact_CurrencyPriceWithSplit with cross-currency triangulation through Dim_Instrument currency pairs.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | DWH_dbo.Fact_CurrencyPriceWithSplit + DWH_dbo.Dim_Instrument via SP_EOD_USD_cr |
| **Refresh** | Daily (SB_Daily, Priority 0) — DELETE WHERE DateID=@ddINT + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (DateID ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_EOD_USD_cr provides end-of-day USD conversion rates for every tradeable instrument in the eToro platform. Each row represents one instrument on one trading day, storing two conversion rates: `USD_cr_Long` (buy-side, derived from Bid prices) and `USD_cr_Short` (sell-side, derived from Ask prices). These rates convert instrument-denominated values into USD.

The table covers 17.56M rows spanning January 2015 through April 2026 (4,119 distinct trading days, 15,415 distinct instruments). It is a Priority 0 base-layer table in the SB_Daily schedule with no intra-schema dependencies.

The ETL pattern is daily DELETE+INSERT keyed on DateID: SP_EOD_USD_cr deletes any existing rows for the target date, then inserts fresh conversion rates computed from Fact_CurrencyPriceWithSplit. The SP was authored by Amir Gurewitz (2020-06-15) and migrated to Synapse by Adi Miedan (2024-01-01).

No downstream BI_DB consumers were found in the SSDT repo — this table appears to be consumed externally (reporting tools, ad-hoc queries) rather than by other BI_DB SPs.

---

## 2. Business Logic

### 2.1 USD Conversion Rate Computation

**What**: Converts each instrument's price to a USD-equivalent rate using a three-tier CASE logic based on the instrument's currency pair (BuyCurrencyID/SellCurrencyID from Dim_Instrument).

**Columns Involved**: `USD_cr_Long`, `USD_cr_Short`, `InstrumentID`

**Rules**:
- If `SellCurrencyID = 1` (USD is the quote/sell currency): rate = 1.00 (already USD-denominated)
- If `BuyCurrencyID = 1` (USD is the base/buy currency): Long = 1/Bid, Short = 1/Ask
- If neither currency is USD: cross-rate triangulation — find an intermediate instrument where one side is USD (CurrencyID=1), then use that pair's Bid/Ask for conversion
- CurrencyID = 1 represents USD in the eToro system

### 2.2 Long vs Short Rate Distinction

**What**: Two separate conversion rates reflect the bid-ask spread impact on position valuation.

**Columns Involved**: `USD_cr_Long`, `USD_cr_Short`

**Rules**:
- `USD_cr_Long` uses Bid prices — appropriate for valuing long (buy) positions
- `USD_cr_Short` uses Ask prices — appropriate for valuing short (sell) positions
- The difference between the two reflects the currency spread cost
- NULL rates (2,858 rows, 0.016%) occur when no cross-rate path to USD could be determined

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on DateID. No hash key — any column can be used in JOINs without distribution skew concerns. DateID is the natural filter column; the clustered index supports efficient date-range scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get USD conversion rate for a specific instrument on a date | `WHERE DateID = @dateID AND InstrumentID = @instrumentID` |
| Get all conversion rates for a date | `WHERE DateID = @dateID` — returns ~4,200 rows per day |
| Find instruments with NULL conversion rates | `WHERE USD_cr_Long IS NULL` — indicates no USD cross-rate path |
| Compare long vs short spread for an instrument | `SELECT InstrumentID, USD_cr_Long - USD_cr_Short AS spread WHERE DateID = @dateID` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON e.InstrumentID = di.InstrumentID | Resolve instrument name, symbol, asset class |
| DWH_dbo.Fact_CurrencyPriceWithSplit | ON e.InstrumentID = f.InstrumentID AND e.DateID = f.OccurredDateID | Cross-reference raw Bid/Ask prices |

### 3.4 Gotchas

- **NULL conversion rates**: 2,858 rows (0.016%) have NULL USD_cr_Long and USD_cr_Short — these are instruments where no direct or cross-rate USD conversion path exists. Always handle NULLs in calculations.
- **CurrencyID=1 is USD**: The conversion logic assumes CurrencyID=1 is USD throughout the eToro system. This is hardcoded in the SP.
- **Cross-rate triangulation**: For non-USD pairs, the SP self-joins the #prices temp table to find an intermediate USD pair. If no intermediate exists, both rates are NULL.
- **No consumers in SSDT**: No BI_DB stored procedures reference this table as a source. It is likely consumed by external reporting tools or ad-hoc queries.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 1 | Upstream wiki (production DB documentation) | Highest — verified against source system docs |
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 5 | ETL metadata | Standard — system-generated ETL column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Calendar date for the conversion rate snapshot. Passthrough of the SP input parameter @dd. One row per (Date, InstrumentID) pair. (Tier 2 — SP_EOD_USD_cr) |
| 2 | DateID | int | YES | Integer date key in YYYYMMDD format. Computed via BI_DB_dbo.DateToDateID(@dd). Clustered index column — use for date-range filtering. (Tier 2 — SP_EOD_USD_cr) |
| 3 | InstrumentID | int | YES | Tradeable instrument pair identifier. FK to Dim_Instrument. Allocated by Trade.InstrumentAdd during instrument creation. 15,415 distinct instruments in this table. (Tier 1 — Trade.Instrument) |
| 4 | USD_cr_Long | float | YES | USD conversion rate for long (buy) positions. Derived from Bid prices: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Bid; otherwise cross-rate via intermediate USD pair. NULL (2,858 rows) when no USD conversion path exists. (Tier 2 — SP_EOD_USD_cr) |
| 5 | USD_cr_Short | float | YES | USD conversion rate for short (sell) positions. Derived from Ask prices: if SellCurrencyID=1 then 1.00; if BuyCurrencyID=1 then 1/Ask; otherwise cross-rate via intermediate USD pair. NULL (2,858 rows) when no USD conversion path exists. (Tier 2 — SP_EOD_USD_cr) |
| 6 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | ETL parameter | @dd | Passthrough — SP input date |
| DateID | ETL-computed | DateToDateID(@dd) | Function — date to YYYYMMDD integer |
| InstrumentID | DWH_dbo.Fact_CurrencyPriceWithSplit | InstrumentID | Passthrough via #prices temp table |
| USD_cr_Long | DWH_dbo.Fact_CurrencyPriceWithSplit | Bid | CASE — 3-tier USD conversion using Bid prices |
| USD_cr_Short | DWH_dbo.Fact_CurrencyPriceWithSplit | Ask | CASE — 3-tier USD conversion using Ask prices |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_CurrencyPriceWithSplit (15K instruments × 4,119 dates)
  + DWH_dbo.Dim_Instrument (BuyCurrencyID, SellCurrencyID)
  |-- JOIN on InstrumentID → #prices temp table ---|
  |-- Self-JOIN #prices × 3 (b, c, d) for cross-currency triangulation ---|
  v
BI_DB_dbo.BI_DB_EOD_USD_cr (17.56M rows)
  DELETE WHERE DateID=@ddINT + INSERT
  Daily via SP_EOD_USD_cr (SB_Daily, Priority 0)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | FK — resolves instrument name, symbol, asset class, currency pair |

### 6.2 Referenced By (other objects point to this)

No BI_DB_dbo stored procedures reference this table as a source. Likely consumed by external reporting tools or ad-hoc queries.

---

## 7. Sample Queries

### 7.1 Get USD Conversion Rate for a Specific Instrument and Date

```sql
SELECT Date, InstrumentID, USD_cr_Long, USD_cr_Short
FROM BI_DB_dbo.BI_DB_EOD_USD_cr
WHERE DateID = 20260412
  AND InstrumentID = 1013131
```

### 7.2 Find Instruments with No USD Conversion Path

```sql
SELECT DateID, InstrumentID
FROM BI_DB_dbo.BI_DB_EOD_USD_cr
WHERE USD_cr_Long IS NULL
  AND DateID >= 20260101
ORDER BY DateID DESC
```

### 7.3 Compare Long vs Short Spread Over Time for an Instrument

```sql
SELECT DateID,
       USD_cr_Long,
       USD_cr_Short,
       USD_cr_Long - USD_cr_Short AS spread
FROM BI_DB_dbo.BI_DB_EOD_USD_cr
WHERE InstrumentID = 1013131
  AND DateID >= 20250101
ORDER BY DateID
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 1 T1, 4 T2, 0 T3, 0 T4, 1 T5 | Elements: 6/6, Logic: 8/10, Lineage: 9/10*
*Object: BI_DB_dbo.BI_DB_EOD_USD_cr | Type: Table | Production Source: DWH_dbo.Fact_CurrencyPriceWithSplit via SP_EOD_USD_cr*
