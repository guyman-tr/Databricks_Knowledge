# BI_DB_dbo.BI_DB_EOMExposures

> 344,691-row monthly end-of-month risk exposure snapshot comparing aggregated client net open positions (NOP) against eToro liquidity provider (LP) hedging positions per instrument, covering June 2019 to March 2026 (83 months, 6 asset types). Populated monthly by SP_M_EOMExposures via DELETE+INSERT, computing uncovered exposure as the difference between client and LP positions in USD.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | BI_DB_PositionPnL (client NOP) + Dealing_staging netting tables (LP NOP) + Dim_Instrument via SP_M_EOMExposures |
| **Refresh** | Monthly (SB_Daily schedule, Priority 0) — DELETE WHERE Date=@EndofMonth + INSERT |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

BI_DB_EOMExposures is a monthly risk management snapshot that compares the aggregated client position exposure against eToro's liquidity provider (LP) hedging positions for every tradeable instrument. Each row represents one instrument (or instrument group) on one end-of-month date, showing the client-side NOP in USD (long and short), the LP hedging NOP in USD (long and short), and the uncovered exposure (the unhedged risk gap).

The table covers 344,691 rows spanning 83 month-ends from June 2019 to March 2026. Instruments are classified into 6 major types: Stocks (88%, further broken down by exchange), Crypto Currencies (4.4%), Currencies/FX (2.8%), ETFs (2.2%), Indices (1.5%), and Commodities (0.9%). Stocks are subclassified by exchange into regional groups (US Stocks, Hong Kong Stocks, German Stocks, etc.).

SP_M_EOMExposures runs monthly at EOM and performs a complex multi-step calculation:
1. Builds the instrument universe from Dim_Instrument with exchange-based stock classification
2. Gets latest EOM prices: hourly candle prices for Stocks/ETFs, daily prices for FX/Indices/Commodities/Crypto
3. Computes client NOP from BI_DB_PositionPnL (excluding internal accounts, HedgeServerID<>5000)
4. Computes LP NOP from Dealing_staging netting tables with USD conversion
5. Resolves cross-currency pair aggregation to major USD pairs
6. FULL JOINs client and LP positions to compute uncovered exposure

Internal accounts are excluded from client NOP (PlayerLevelID<>4) except three BVI CIDs (5969870, 5969868, 5969875). For currency pairs where BuyCurrencyID=1 (USD is the base), all position values are sign-flipped in the final output to maintain consistent directionality.

---

## 2. Business Logic

### 2.1 Client NOP Calculation

**What**: Aggregates client net open positions from BI_DB_PositionPnL grouped by instrument, split into long (IsBuy=1) and short (IsBuy=0).

**Columns Involved**: `Aggregated Total USD`, `Aggregated Total USD Short`, `Aggregated Total USD Long`

**Rules**:
- Source: BI_DB_PositionPnL filtered to DateID=@EndofMonth_INT
- Excludes internal accounts (PlayerLevelID<>4) except BVI CIDs 5969870/5969868/5969875
- Excludes HedgeServerID=5000
- NOP_Long = SUM(NOP WHERE IsBuy=1), NOP_Short = SUM(NOP WHERE IsBuy=0)
- For currencies with BuyCurrencyID=1: sign-flipped (Long becomes -Short, Short becomes -Long)

### 2.2 LP NOP Calculation

**What**: Computes eToro liquidity provider hedging positions from Dealing_staging netting tables.

**Columns Involved**: `eToro`, `eToro Short`, `eToro Long`

**Rules**:
- Sources: etoro_History_Netting_History (temporal WHERE SysStartTime<@DayAfterEndofMonth AND SysEndTime>=@DayAfterEndofMonth) UNION etoro_Hedge_Netting (current positions)
- Latest position per (HedgeServerID, InstrumentID) via ROW_NUMBER DESC on UpdateTime
- Converted to USD via same cross-rate triangulation logic as SP_EOD_USD_cr
- Special unit adjustments for InstrumentID 18 (×0.01 if AvgRate>10K), 19 (×0.01 if >100), 22 (×0.001 if >100), 28 (×0.01 if >100K)
- Portfolio conversion configuration applied: maps InstrumentIDToHedge back to original InstrumentID

### 2.3 Uncovered Exposure

**What**: The unhedged risk gap — client exposure not covered by LP positions.

**Columns Involved**: `Uncovered Exposure`

**Rules**:
- Uncovered Exposure = Client NOP (Aggregated Total USD) - LP NOP (eToro)
- Positive = client exposure exceeds LP hedging (risk to eToro)
- Negative = LP hedging exceeds client exposure (over-hedged)
- For currencies with BuyCurrencyID=1: sign-flipped

### 2.4 Exchange-Based Stock Classification

**What**: Stocks (InstrumentTypeID=5) and ETFs (InstrumentTypeID=6) are classified into regional groups based on their exchange.

**Columns Involved**: `InstrumentTypeMajor`, `InstrumentReportFinalName`

**Rules**:
- Nasdaq/NYSE/OTCMKTS/CBOE → US Stocks; Hong Kong Exchanges → Hong Kong Stocks; TYO → Tokyo Stocks; FRA → German Stocks; etc.
- ETFs: US exchanges → ETF-US; LSE → ETF-UK; others → ETF-{Exchange}
- Bond ETFs (InstrumentDisplayName LIKE '%Bond%' or '%Bd%') are included in the non-stock instrument universe
- Three commodity ETFs (United States Gasoline Fund, Teucrium Corn Fund, Teucrium Wheat Fund) reclassified to Commodities

### 2.5 Major Currency Pair Resolution

**What**: For FX/Crypto cross pairs (neither side is USD), positions are aggregated under the major USD pair.

**Columns Involved**: All NOP columns

**Rules**:
- Uses self-joins on #Clients/#LP to find the major USD-paired instrument for each non-USD cross pair
- BuyCurrencyID side resolved for Long aggregation, SellCurrencyID side for Short aggregation
- COALESCE priority: crypto pair match → sell-side USD match → buy-side USD match
- Instruments directly paired with USD (SellCurrencyID=1 or BuyCurrencyID=1) pass through without aggregation

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on Date. Always filter by Date for efficient scans.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Get all exposures for latest EOM | `WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_EOMExposures)` |
| Find largest uncovered exposures | `ORDER BY ABS([Uncovered Exposure]) DESC` with Date filter |
| Exposure by asset type | `GROUP BY InstrumentTypeMajor` with SUM on exposure columns |
| Track exposure trend for an instrument | `WHERE Name = @instrumentName ORDER BY Date` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | ON e.Name = di.InstrumentDisplayName | Resolve InstrumentID, currency pair details |

### 3.4 Gotchas

- **Column names with spaces**: `[Aggregated Total USD]`, `[Aggregated Total USD Short]`, `[Aggregated Total USD Long]`, `[Uncovered Exposure]`, `[eToro Short]`, `[eToro Long]` all require bracket quoting in queries.
- **NULL eToro columns**: Instruments with no LP hedging positions have NULL for `eToro`, `eToro Short`, `eToro Long` — these are unhedged instruments where Uncovered Exposure equals the full client NOP.
- **Sign-flipped currencies**: For currency pairs where BuyCurrencyID=1 (e.g., USD/EUR), all position values are sign-flipped. A positive `Aggregated Total USD Long` for these represents what would normally be a short position.
- **Monthly grain only**: Data exists only for month-end dates. No intra-month snapshots.
- **BVI CID exceptions**: Three BVI CIDs (5969870, 5969868, 5969875) are included in client NOP despite being internal (PlayerLevelID=4).

---

## 4. Elements

### Confidence Tier Legend

| Tier | Source | Confidence |
|------|--------|------------|
| Tier 2 | SP code analysis | High — traced from ETL stored procedure logic |
| Tier 5 | ETL metadata | Standard — system-generated ETL column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | End-of-month snapshot date. One set of rows per EOM date. DELETE+INSERT keyed on this column. 83 distinct dates from June 2019 to March 2026. (Tier 2 — SP_M_EOMExposures) |
| 2 | InstrumentTypeMajor | varchar(50) | YES | Major asset type classification. 6 values: Stocks, Crypto Currencies, Currencies, ETF, Indices, Commodities. Derived from Dim_Instrument.InstrumentType with special override for commodity ETFs (United States Gasoline Fund, Teucrium Corn Fund, Teucrium Wheat Fund → Commodities). (Tier 2 — SP_M_EOMExposures) |
| 3 | InstrumentReportFinalName | varchar(100) | YES | Reporting-level instrument name. For currencies: BuyCurrency name (or SellCurrency if BuyCurrencyID=1, or Symbol for Shiba). For stocks: exchange-based regional group (US Stocks, Hong Kong Stocks, German Stocks, etc.). For others: InstrumentDisplayName from Dim_Instrument. (Tier 2 — SP_M_EOMExposures) |
| 4 | Aggregated Total USD | money | YES | Aggregated client NOP in USD (Long + Short combined). SUM of client positions from BI_DB_PositionPnL on EOM date for non-internal customers. Sign-flipped for currency pairs with BuyCurrencyID=1. (Tier 2 — SP_M_EOMExposures) |
| 5 | Aggregated Total USD Short | money | YES | Client short NOP in USD. SUM of NOP WHERE IsBuy=0 from BI_DB_PositionPnL. Sign-flipped for currency pairs with BuyCurrencyID=1 (becomes -NOP_Long). (Tier 2 — SP_M_EOMExposures) |
| 6 | Aggregated Total USD Long | money | YES | Client long NOP in USD. SUM of NOP WHERE IsBuy=1 from BI_DB_PositionPnL. Sign-flipped for currency pairs with BuyCurrencyID=1 (becomes -NOP_Short). (Tier 2 — SP_M_EOMExposures) |
| 7 | eToro | money | YES | eToro LP total hedging NOP in USD. Computed from Dealing_staging netting tables (latest position per HedgeServerID+InstrumentID). NULL if no LP hedging exists for this instrument. Sign-flipped for BuyCurrencyID=1 currencies. (Tier 2 — SP_M_EOMExposures) |
| 8 | Uncovered Exposure | money | YES | Unhedged risk gap in USD. Computed as Client NOP (Aggregated Total USD) minus LP NOP (eToro). Positive = client exposure exceeds LP hedging. Negative = over-hedged. Sign-flipped for BuyCurrencyID=1 currencies. (Tier 2 — SP_M_EOMExposures) |
| 9 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by the ETL pipeline. Set to GETDATE() at insert time. (Tier 5 — ETL metadata) |
| 10 | Name | varchar(max) | YES | Instrument display name from Dim_Instrument.InstrumentDisplayName. COALESCE from client or LP result sets. Used for human-readable instrument identification. (Tier 2 — SP_M_EOMExposures) |
| 11 | eToro Short | money | YES | eToro LP short hedging NOP in USD. Computed from Dealing_staging netting tables for IsBuy=0 positions. NULL if no LP hedging exists. Sign-flipped for BuyCurrencyID=1 currencies (becomes -NOP_Long). (Tier 2 — SP_M_EOMExposures) |
| 12 | eToro Long | money | YES | eToro LP long hedging NOP in USD. Computed from Dealing_staging netting tables for IsBuy=1 positions. NULL if no LP hedging exists. Sign-flipped for BuyCurrencyID=1 currencies (becomes -NOP_Short). (Tier 2 — SP_M_EOMExposures) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|------------------|---------------|-----------|
| Date | ETL parameter | @EndofMonth | Passthrough |
| InstrumentTypeMajor | DWH_dbo.Dim_Instrument | InstrumentType | CASE — commodity ETF override + ISNULL 'Stocks' fallback |
| InstrumentReportFinalName | DWH_dbo.Dim_Instrument | InstrumentDisplayName / BuyCurrency / SellCurrency | CASE — exchange classification for stocks, currency name for FX |
| Aggregated Total USD | BI_DB_dbo.BI_DB_PositionPnL | NOP | SUM with sign-flip for BuyCurrencyID=1 |
| Aggregated Total USD Short | BI_DB_dbo.BI_DB_PositionPnL | NOP (IsBuy=0) | SUM with sign-flip |
| Aggregated Total USD Long | BI_DB_dbo.BI_DB_PositionPnL | NOP (IsBuy=1) | SUM with sign-flip |
| eToro | Dealing_staging netting | Units × Price × USD rate | SUM with sign-flip |
| Uncovered Exposure | Computed | Client - LP | Subtraction with sign-flip |
| UpdateDate | ETL metadata | GETDATE() | ETL timestamp |
| Name | DWH_dbo.Dim_Instrument | InstrumentDisplayName | COALESCE from client/LP |
| eToro Short | Dealing_staging netting | Units (IsBuy=0) × Price × USD rate | SUM with sign-flip |
| eToro Long | Dealing_staging netting | Units (IsBuy=1) × Price × USD rate | SUM with sign-flip |

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (client positions, EOM date)
  + DWH_dbo.Dim_Customer (exclude PlayerLevelID=4 except BVI)
  + DWH_dbo.Dim_Instrument (instrument universe, classification)
  |-- SUM NOP by instrument, major currency pair resolution ---|
  v
#ClientsFinal (aggregated client NOP in USD)
  FULL JOIN
Dealing_staging.etoro_History_Netting_History + etoro_Hedge_Netting
  + DWH_dbo.Dim_Instrument (USD conversion via cross-rate)
  + External_*_PortfolioConversionConfigurations (instrument mapping)
  |-- Latest position per HedgeServerID+InstrumentID, USD convert, major resolution ---|
  v
#LPFinal (aggregated LP NOP in USD)
  |-- FULL JOIN #ClientsFinal × #LPFinal → Uncovered Exposure ---|
  v
BI_DB_dbo.BI_DB_EOMExposures (344,691 rows)
  DELETE WHERE Date=@EndofMonth + INSERT
  Monthly via SP_M_EOMExposures (SB_Daily, Priority 0)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Name | DWH_dbo.Dim_Instrument | FK — InstrumentDisplayName for instrument identification |

### 6.2 Referenced By (other objects point to this)

| Referencing Object | Relationship | Description |
|-------------------|--------------|-------------|
| SP_IFR_KFactors_Automation_EOMExposure | Reader | Uses EOMExposures data for IFR K-Factors regulatory calculations |

---

## 7. Sample Queries

### 7.1 Get Latest EOM Exposure Summary by Asset Type

```sql
SELECT InstrumentTypeMajor,
       COUNT(*) AS instruments,
       SUM([Aggregated Total USD]) AS total_client_nop,
       SUM([eToro]) AS total_lp_nop,
       SUM([Uncovered Exposure]) AS total_uncovered
FROM BI_DB_dbo.BI_DB_EOMExposures
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_EOMExposures)
GROUP BY InstrumentTypeMajor
ORDER BY ABS(SUM([Uncovered Exposure])) DESC
```

### 7.2 Find Top 10 Largest Uncovered Exposures for Latest Month

```sql
SELECT TOP 10 Name, InstrumentTypeMajor,
       [Aggregated Total USD] AS client_nop,
       [eToro] AS lp_nop,
       [Uncovered Exposure]
FROM BI_DB_dbo.BI_DB_EOMExposures
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_EOMExposures)
ORDER BY ABS([Uncovered Exposure]) DESC
```

### 7.3 Track Exposure Trend for a Specific Instrument

```sql
SELECT Date,
       [Aggregated Total USD] AS client_nop,
       [eToro] AS lp_nop,
       [Uncovered Exposure]
FROM BI_DB_dbo.BI_DB_EOMExposures
WHERE Name = 'Tesla Motors Inc'
ORDER BY Date
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 11 T2, 0 T3, 0 T4, 1 T5 | Elements: 12/12, Logic: 9/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_EOMExposures | Type: Table | Production Source: BI_DB_PositionPnL + Dealing_staging netting via SP_M_EOMExposures*
