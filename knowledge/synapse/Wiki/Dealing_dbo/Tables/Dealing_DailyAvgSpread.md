# Dealing_dbo.Dealing_DailyAvgSpread

> Hourly, daily, and trailing-year average spread comparison between raw LP (Price Provider) spread and eToro client-visible spread per instrument, enabling spread quality and markup monitoring.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | Derived — DWH_dbo.Dim_Position open/close spread data |
| **Refresh** | Daily |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending — resolved during write-objects_ |

---

## 1. Business Meaning

Dealing_DailyAvgSpread compares the raw LP/market spread (PP = Price Provider) with the eToro client-visible spread (which includes eToro's spread markup) at three time horizons: hourly, daily, and trailing year (YTD).

Each row represents one instrument at one hour on a given day. The PP/eToro ratio indicates what fraction of the client-visible spread is the raw market spread vs. eToro's revenue component. A ratio close to 1.0 means eToro adds minimal markup; a low ratio means significant spread markup.

Data source: `DWH_dbo.Dim_Position` — every position opened or closed that day contributes two spread observations (at open from `InitForex_*` columns and at close from `EndForex_*` columns). Filtered to valid customers. ~32M rows since 2020.

---

## 2. Business Logic

### 2.1 PP Spread vs eToro Spread

**What**: Measures the raw market spread and eToro's enhanced spread.

**Columns Involved**: `*PPSpread`, `*EtoroSpread`

**Rules**:
- PPSpread = `ABS(Ask - Bid)` — the raw LP/price-provider spread (no markup)
- EtoroSpread = `ABS(AskSpreaded - BidSpreaded)` — the spread shown to eToro clients (includes eToro's spread markup)
- Both positions opened AND closed on the date contribute observations (UNION)
- InitForex_* for open events, EndForex_* for close events

### 2.2 Time Horizons

**What**: Three aggregation levels for trend analysis.

**Rules**:
- **Hourly**: AVG per instrument per hour — granular intraday patterns
- **Daily**: AVG per instrument for the full day — rolled up from all hourly data
- **YTD**: AVG per instrument over trailing 365 days — long-term benchmark
- The ratio columns (`*_DividedByEtoroSpread`) = PPSpread / EtoroSpread

### 2.3 Trade Count

**What**: Number of trades (position opens/closes) providing spread observations.

**Rules**: Count of non-null PPSpread values per aggregation window. NULL PPSpread means no Ask/Bid available.

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN with CLUSTERED INDEX on Date. ~32M rows. Always filter by Date.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Spread quality for an instrument | `WHERE Date = @Date AND InstrumentID = @ID ORDER BY Hour` |
| Instruments with highest eToro markup | `WHERE Date = @Date AND DailyPPSpread_DividedByEtoroSpread IS NOT NULL ORDER BY DailyPPSpread_DividedByEtoroSpread ASC` |
| Hourly spread pattern | `WHERE Date = @Date AND InstrumentName = 'EURUSD' ORDER BY Hour` |

### 3.3 Gotchas

- **Many NULL rows**: Instruments with no trades in an hour have NULL spread values and NumberofTrades=0
- **Daily and YTD columns are repeated** on every hourly row for the same instrument — they are denormalized for convenience
- **"YTD" is actually trailing 365 days**, not calendar year-to-date
- **PP = Price Provider**, not "percentage points"

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reporting date. (Tier 2 — SP_DailyAvgSpread) |
| 2 | InstrumentID | int | YES | Instrument identifier from `Dim_Position.InstrumentID`. (Tier 2 — SP_DailyAvgSpread) |
| 3 | InstrumentName | varchar(50) | YES | Instrument ticker from `Dim_Instrument.Name`. (Tier 2 — SP_DailyAvgSpread) |
| 4 | InstrumentType | varchar(50) | YES | Asset class from `Dim_Instrument.InstrumentType`. (Tier 2 — SP_DailyAvgSpread) |
| 5 | Hour | datetime | YES | Hour bucket. `DATEADD(hour, DATEDIFF(hour,0,OpenOccurred/CloseOccurred), 0)` — truncated to hour boundary. (Tier 2 — SP_DailyAvgSpread) |
| 6 | HourlyAvg_PPSpread | decimal(16,8) | YES | Avg raw LP spread for this instrument in this hour. `AVG(ABS(Ask-Bid))` from open+close events. (Tier 2 — SP_DailyAvgSpread) |
| 7 | HourlyAvg_EtoroSpread | decimal(16,8) | YES | Avg eToro client-visible spread for this hour. `AVG(ABS(AskSpreaded-BidSpreaded))`. Includes eToro's spread markup. (Tier 2 — SP_DailyAvgSpread) |
| 8 | NumberofTradesHourly | int | YES | Count of trades with non-null PPSpread in this hour. (Tier 2 — SP_DailyAvgSpread) |
| 9 | HourlyPPSpread_DividedByEtoroSpread | float | YES | `HourlyAvg_PPSpread / HourlyAvg_EtoroSpread`. Ratio of raw spread to client spread. Close to 1.0 = low markup. (Tier 2 — SP_DailyAvgSpread) |
| 10 | DailyAvg_PPSpread | decimal(16,8) | YES | Full-day average raw LP spread for this instrument. Same value on all hourly rows. (Tier 2 — SP_DailyAvgSpread) |
| 11 | DailyAvg_EtoroSpread | decimal(16,8) | YES | Full-day average eToro spread. Denormalized onto hourly grain. (Tier 2 — SP_DailyAvgSpread) |
| 12 | NumberofTradesDaily | int | YES | Total trades for this instrument for the full day. (Tier 2 — SP_DailyAvgSpread) |
| 13 | DailyPPSpread_DividedByEtoroSpread | float | YES | `DailyAvg_PPSpread / DailyAvg_EtoroSpread`. Daily ratio. (Tier 2 — SP_DailyAvgSpread) |
| 14 | YTDAvg_PPSpread | decimal(16,8) | YES | Trailing 365-day average raw LP spread. (Tier 2 — SP_DailyAvgSpread) |
| 15 | YTDAvg_EtoroSpread | decimal(16,8) | YES | Trailing 365-day average eToro spread. (Tier 2 — SP_DailyAvgSpread) |
| 16 | YTDPPSpread_DividedByEtoroSpread | float | YES | `YTDAvg_PPSpread / YTDAvg_EtoroSpread`. Long-term spread quality ratio. (Tier 2 — SP_DailyAvgSpread) |
| 17 | UpdateDate | datetime | YES | ETL load timestamp. (Tier 2 — SP_DailyAvgSpread) |

---

## 5. Lineage

Full lineage: see [Dealing_DailyAvgSpread.lineage.md](Dealing_DailyAvgSpread.lineage.md)

| Step | Object | Description |
|------|--------|-------------|
| Source | DWH_dbo.Dim_Position | Position open/close forex rates (Init/End Forex Ask/Bid/Spreaded) |
| Source | DWH_dbo.Dim_Instrument | Instrument names and types |
| Source | DWH_dbo.Dim_Customer | IsValidCustomer filter |
| ETL | SP_DailyAvgSpread | Compute hourly, daily, YTD spreads and ratios |
| Target | Dealing_DailyAvgSpread | Daily spread analysis by instrument per hour |

---

*Generated: 2026-03-21 | Quality: 7.5/10 (★★★★☆) | Phases: 9/14*
*Tiers: 0 T1, 17 T2, 0 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 5/10, Sources: 7/10*
*Object: Dealing_dbo.Dealing_DailyAvgSpread | Type: Table | Production Source: Derived (Dim_Position spread data)*
