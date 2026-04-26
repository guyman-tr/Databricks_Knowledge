# Lineage: BI_DB_dbo.BI_DB_InstrumentsAlerts

**Writer SP**: `SP_InstrumentsAlerts`
**Scope**: All tradeable instrument types (Stocks/ETFs, Crypto, FX/Commodities/Indices, Copy, Copy Fund); activity measured from BI_DB_First5Actions
**Pattern**: DELETE WHERE FullDate=@Date + INSERT (incremental, date-keyed)
**UC Target**: Not Migrated

## Column Lineage

| # | DWH Column | Source Table | Source Column | Transform | Tier |
|---|-----------|-------------|--------------|-----------|------|
| 1 | FullDate | DWH_dbo.Dim_Date | FullDate | Passthrough — date of the alert; derived from BI_DB_First5Actions.FirstActionDate | Tier 2 |
| 2 | DayNumberOfWeek_Sun_Start | DWH_dbo.Dim_Date | DayNumberOfWeek_Sun_Start | Passthrough | Tier 2 |
| 3 | FirstAction | BI_DB_dbo.BI_DB_First5Actions | FirstAction | Passthrough — instrument category of the customer's first trading action | Tier 2 |
| 4 | FirstInstrument | BI_DB_dbo.BI_DB_First5Actions | FirstInstrument | Passthrough — instrument identifier string (ticker or popular investor username for Copy) | Tier 2 |
| 5 | InstrumentDisplayName | DWH_dbo.Dim_Instrument | InstrumentDisplayName | LEFT JOIN Dim_Instrument ON Name=FirstInstrument; NULL for Copy rows where FirstInstrument is a username | Tier 2 |
| 6 | InstrumentID | DWH_dbo.Dim_Instrument / Dim_Customer | InstrumentID / RealCID | ISNULL(Dim_Instrument.InstrumentID, Dim_Customer.RealCID) — for Copy rows, falls back to Popular Investor's RealCID when Dim_Instrument.InstrumentID is NULL | Tier 2 |
| 7 | Industry | DWH_dbo.Dim_Instrument | Industry | Passthrough via Dim_Instrument JOIN | Tier 2 |
| 8 | Exchange | DWH_dbo.Dim_Instrument | Exchange | CASE normalization (NASDAQ→Nasdaq, Bolsa De Madrid→Bolsa de Madrid, HEL→Helsinki Stock Exchange, OSE→Oslo Stock Exchange, STO→Stockholm Stock Exchange); all others passthrough | Tier 2 |
| 9 | Actions | BI_DB_dbo.BI_DB_First5Actions | — | COUNT(*) grouped by (Date, FirstAction, FirstInstrument, InstrumentID, Industry, Exchange) — first-action event count for that instrument on @Date | Tier 2 |
| 10 | avg7d_past | Computed | Actions | ROUND(AVG(ISNULL(Actions,0)) OVER (PARTITION BY FirstInstrument ORDER BY FullDate ROWS BETWEEN 7 PRECEDING AND 1 PRECEDING), 1) — rolling 7-business-day average excluding @Date | Tier 2 |
| 11 | avg14d_past | Computed | Actions | Same window pattern, 14 preceding | Tier 2 |
| 12 | avg30d_past | Computed | Actions | Same window pattern, 30 preceding | Tier 2 |
| 13 | UpdateDate | ETL | GETDATE() | ETL run timestamp | Tier 3 |
| 14 | Tier | Computed | FirstAction, Exchange, InstrumentID, Dim_Customer.GuruStatusID | Business importance tier 0–4 per asset class: Stocks/ETFs by exchange tier, Crypto by InstrumentID list, FX by InstrumentID list, Copy by GuruStatusID, Copy Fund → always 0 | Tier 2 |

**Important**: Column `[Tier]` is a business-domain field (instrument importance tier) — NOT a wiki documentation confidence tier.

## Source Objects

| Source | Role |
|--------|------|
| BI_DB_dbo.BI_DB_First5Actions | Primary activity source — first trading actions per customer per date |
| DWH_dbo.Dim_Date | Date dimension — supplies FullDate and DayNumberOfWeek_Sun_Start; weekday filter for non-Crypto pipeline |
| DWH_dbo.Dim_Instrument | Instrument metadata — InstrumentDisplayName, InstrumentID, Industry, Exchange |
| DWH_dbo.Dim_Customer | Popular Investor lookup for Copy rows: UserName match, GuruStatusID for Tier logic, RealCID fallback for InstrumentID |

## Rolling Average Window Logic

The SP uses a 1-month lookback window to compute rolling averages:
1. `#Instruments` — actual action counts per instrument on each date in [dateadd(m,-1,@Date), @Date+1day]
2. `#Instrument_dist_date` — FULL OUTER JOIN with Dim_Date (all weekdays in window) × @Date instruments (ON 1=1, WHERE i.Date=@Date) — creates a date-instrument scaffold with NULLs on days with no activity
3. `#Avg_Instrument` — window functions over the scaffold, treating NULL action days as 0 (ISNULL(Actions,0))
4. INSERT only rows WHERE FullDate=@Date — only today's alerts inserted; historical rows used only for window computation

Non-Crypto: weekdays only (Dim_Date IsWeekend='N'); Crypto: all days (crypto trades on weekends).

## Tier CASE Logic (business Tier column)

| FirstAction | Tier=1 | Tier=2 | Tier=3 | Tier=4 |
|-------------|--------|--------|--------|--------|
| Stocks/ETFs | Nasdaq, NYSE | Euronext Paris, FRA, LSE | Hong Kong Exchanges, Borsa Italiana, SIX, Euronext Amsterdam | All other exchanges |
| Crypto | InstrumentID IN (100000,100001,100003) | 6 specific IDs | 7 specific IDs | All others |
| FX/Commodities/Indices | InstrumentID IN (17,18) | 8 specific IDs | 15 specific IDs | All others |
| Copy | GuruStatusID=5 | GuruStatusID=4 or 2/3 | — | All others |
| Copy Fund | — | — | — | always 0 (ELSE branch) |

## ETL Pipeline

```
BI_DB_dbo.BI_DB_First5Actions (customer first-action history)
  |
  +-- SP_InstrumentsAlerts @Date ---|
  |   Two pipelines (non-Crypto, Crypto) |
  |   Window AVG over Dim_Date scaffold   |
  |   DELETE WHERE FullDate=@Date         |
  |   UNION INSERT                         |
  v
BI_DB_dbo.BI_DB_InstrumentsAlerts (642K rows, Dec 2019–Apr 2026, instrument alert feed)
```

## Tier Summary

| Tier | Count | Columns |
|------|-------|---------|
| Tier 2 | 13 | FullDate, DayNumberOfWeek_Sun_Start, FirstAction, FirstInstrument, InstrumentDisplayName, InstrumentID, Industry, Exchange, Actions, avg7d_past, avg14d_past, avg30d_past, Tier |
| Tier 3 | 1 | UpdateDate |
