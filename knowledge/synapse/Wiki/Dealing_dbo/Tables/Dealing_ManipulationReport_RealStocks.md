# Dealing_dbo.Dealing_ManipulationReport_RealStocks

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_ManipulationReport_RealStocks |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `Date` |
| **Columns** | 14 |
| **Primary Source** | Multi-source: DWH_dbo.Dim_Position, CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo, DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted |
| **ETL SP** | `Dealing_dbo.SP_ManipulationReport_RealStocks` |
| **Refresh** | Daily per @dd date |
| **PII** | none (instrument-level aggregate only) |
| **Tags** | dealing, market-manipulation, compliance, real-stocks, regulation, surveillance |

---

## 1. Business Meaning

`Dealing_ManipulationReport_RealStocks` is a **daily market manipulation surveillance report** for real (settled) stock and ETF positions at eToro. It identifies instruments where client trading activity exhibits patterns associated with potential market manipulation, based on multiple KPI flags computed by `SP_ManipulationReport_RealStocks`.

**Scope**: Real assets only (`IsSettled=1`), Stocks and ETFs (`InstrumentTypeID IN 5,6`), manual positions only (not copy-trading, `MirrorID=0`), valid customers in regulated jurisdictions (RegulationID IN 1,2,4 = CySEC, FCA, ASIC-equivalent). Data is filtered to weekdays only.

Each row represents an **instrument flagged under a specific KPI** for the reporting date. The same instrument can appear multiple times with different KPI values if it triggers multiple manipulation signals. The data is used by the Dealing/Compliance team for regulatory surveillance, with results typically reviewed the following morning.

**Related table**: `Dealing_ManipulationReport_RealStocks_CID` provides the same analysis at the individual customer level (CID granularity).

---

## 2. Business Logic

### ETL Pattern — Daily Delete + Insert per Date

`SP_ManipulationReport_RealStocks(@dd)` is a comprehensive surveillance SP (700+ lines, author: Amir Gurewitz, 2019, migrated to Synapse 2024):

#### Data Preparation

1. **Market Data** (`#StocksInfo`): From `CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo`, reads 90-day trailing window — MetadataID 8735 = MarketCapital, MetadataID 8708 = DailyVolume (exchange-level daily trading volume).

2. **Market Cap Ranking** (`#StocksInfo_KPIs_Calc/KPIs`): Computes:
   - `MA_10Days`: 10-day moving average of exchange daily volume (window function over 9 preceding rows)
   - `RN_MktCap`: Rank by market cap ascending — instruments with RN_MktCap ≤ 20 are flagged `IsLowMktCap=1`

3. **Market Hours** (`#MarketHours`): From `DWH_staging.etoro_Trade_InstrumentMetaData`, computes exchange opening/closing hours per instrument based on ExchangeID groups (European exchanges open ~07:00-15:30 UTC, US exchanges open ~13:30-20:00 UTC).

4. **Intraday Price Range** (`#MaxToMinChange`): From `Dim_GetSpreadedPriceCandle60MinSplitted`, computes `(MAX(BidMax) / MIN(BidMin)) - 1` = max-to-min price change percentage for the day.

5. **Position Universe** (`#positions`, `#TreePositions`): Loads all real stock/ETF positions opened or closed on `@dd` for valid customers in regulated regions. Groups positions by their tree root (manual position = root with `MirrorID=0`; partial close children aggregated into parent). Flags First10Min/Last10Min based on whether position time falls within 10 minutes of exchange open/close.

6. **30-Day Average Volumes** (`#AvgDailyKPIs`): From Dim_Position, computes trailing 30 working-day average volume per instrument (`OpenVolume30Days / 30`).

#### KPI Segments (UNION of 8+ patterns)

| KPI | Detection Pattern | Threshold |
|-----|-------------------|-----------|
| `Top20_Volume` | Top 20 instruments by total client USD volume (non-low-market-cap) | Top 20 per Regulation × IsLowMktCap |
| `Top20_Volume_LowMktCap` | Same but for low-market-cap stocks (RN_MktCap ≤ 20) | Top 20 |
| `Top20_Volume_20Min` | Top 20 by volume where position duration ≤ 20 minutes (closed within 20 min of open) | Top 20 per Regulation × IsLowMktCap |
| `Top20_Volume_20Min_LowMktCap` | Same, low-market-cap variant | Top 20 |
| `First10Minutes` | Instruments with client volume in first 10 minutes of exchange hours > 2× 30-day daily average | Volume > 2× AvgDailyVolumeAll |
| `Last10Minutes` | Instruments with client volume in last 10 minutes of exchange hours > 2× 30-day daily average | Volume > 2× AvgDailyVolumeAll |
| `Flag2` | Instruments where client units ÷ exchange daily volume ≥ threshold, joined with price data | Must join StocksInfo_KPIs; optional MaxToMinChange ≥ 20% filter |
| `AvgVolume` | Instruments where client volume exceeds 30-day average (percentage difference ranking) | Top 20 per Regulation × IsLowMktCap |

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Position` | `PositionID, InstrumentID` | Client position source |
| `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument filter (stocks/ETFs) |
| `DWH_dbo.Dim_Customer` | `RealCID` | Valid customer filter |
| `DWH_dbo.Fact_SnapshotCustomer` | `RealCID` | Customer country, manager, regulation, player level |
| `DWH_dbo.Dim_Range` | `DateRangeID` | Date-range validity for snapshot |
| `DWH_dbo.Dim_Country` | `CountryID` | Country enrichment |
| `DWH_dbo.Dim_Manager` | `ManagerID` | Account manager enrichment |
| `DWH_dbo.Dim_Regulation` | `DWHRegulationID` | Regulation filter (RegulationID IN 1,2,4) |
| `DWH_dbo.Dim_PlayerLevel` | `PlayerLevelID` | Player club level |
| `DWH_dbo.Dim_GetSpreadedPriceCandle60MinSplitted` | `InstrumentID, DateFrom` | Intraday price range |
| `CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo` | `InstrumentID, Occurred` | Market cap + exchange daily volume |
| `DWH_staging.etoro_Trade_InstrumentMetaData` | `InstrumentID` | Exchange ID → market hours |
| `Dealing_dbo.Dealing_ManipulationReport_RealStocks_CID` | `Date, InstrumentID, KPI` | Customer-level breakdown of same signals |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_ManipulationReport_RealStocks)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The reporting date (weekdays only). All rows in a batch share the same Date. Clustered index key. Corresponds to `@dd` SP parameter. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 2 | KPI | varchar(100) | YES | The manipulation signal category. Values: `First10Minutes`, `Last10Minutes`, `Flag2`, `Top20_Volume`, `Top20_Volume_LowMktCap`, `Top20_Volume_20Min`, `Top20_Volume_20Min_LowMktCap`, `AvgVolume`. Each KPI detects a different behavioral pattern. An instrument may appear in multiple KPI rows for the same date. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 3 | InstrumentID | int | YES | Instrument identifier for the flagged stock or ETF. FK to DWH_dbo.Dim_Instrument. Only real stocks/ETFs (InstrumentTypeID 5,6, IsSettled=1). (Tier 2 — SP_ManipulationReport_RealStocks) |
| 4 | InstrumentDisplayName | varchar(max) | YES | User-facing display name of the instrument from Dim_Instrument.InstrumentDisplayName (e.g., 'Apple Inc.', 'Implanet SA'). Used for reporting and review. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 5 | InstrumentType | varchar(50) | YES | Text category: 'Stocks' or 'ETF'. From Dim_Instrument.InstrumentType. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 6 | Regulation | varchar(50) | YES | Regulatory entity overseeing the flagged activity. From Dim_Regulation.Name. Values: 'CySEC', 'FCA', or related regulators (RegulationID IN 1,2,4). The report is segmented by regulation since different regulators have different reporting obligations. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 7 | RN | int | YES | Rank number within the KPI segment, ordered by Volume descending (within Regulation × IsLowMktCap grouping). Populated for Top20_Volume* KPIs (1–20); NULL for other KPIs (First10Minutes, Last10Minutes, Flag2, AvgVolume). (Tier 2 — SP_ManipulationReport_RealStocks) |
| 8 | Volume | bigint | YES | Total client USD trading volume (opens + closes) for this instrument on `Date`, from Dim_Position (Volume + VolumeOnClose). Cast to BIGINT. Represents the size of client activity in this stock. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 9 | Units | float | YES | Total client position units (shares) traded for this instrument on `Date` (AmountInUnitsDecimal summed across opens and closes). Represents the number of shares, not USD value. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 10 | Last30DaysAvgVolume | bigint | YES | Average daily client USD volume over the trailing 30 working days, computed from Dim_Position. Used as baseline for volume anomaly detection. The ratio `Volume / Last30DaysAvgVolume` indicates how unusual today's activity is. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 11 | ExchangeUnitsVolume | bigint | YES | Official exchange-reported daily trading volume in shares (units), sourced from `CopyFromLake.Rankings_StockInfo_DailyInstrumentInfo` MetadataID=8708. Represents total market activity for this stock on this exchange. Used to compute `Units / ExchangeUnitsVolume` = eToro's share of exchange volume (potential market impact signal). (Tier 2 — SP_ManipulationReport_RealStocks) |
| 12 | MA_10Days | float | YES | 10-day moving average of exchange daily volume (in shares), computed from 90-day trailing window of Rankings StockInfo data. Used for trend-adjusted comparison: an instrument with Volume well above MA_10Days suggests unusually active market conditions. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 13 | MaxToMinChange | float | YES | Maximum intraday price range: `(MAX(BidMax) / MIN(BidMin)) - 1` across all 60-minute candles for the day, from Dim_GetSpreadedPriceCandle60MinSplitted. Expressed as a decimal fraction (e.g., 0.025 = 2.5% intraday range). High values (≥0.20 = 20%) indicate significant price volatility, which in combination with large eToro client volume may indicate manipulative trading. (Tier 2 — SP_ManipulationReport_RealStocks) |
| 14 | UpdateDate | datetime | YES | ETL metadata: `GETDATE()` at time SP ran. Not a business timestamp. (Tier 2 — SP_ManipulationReport_RealStocks) |

---

## 5. Usage Notes

**Reading the KPI column**: Each row is one flagged signal for one instrument. To understand ALL signals on a given date, query with `WHERE Date = @date GROUP BY KPI` or pivot on KPI.

**Volume vs Units**: `Volume` is in USD; `Units` is in shares. For market impact analysis, use `Units / ExchangeUnitsVolume` (eToro's fraction of total exchange turnover). This ratio is particularly important for low-market-cap stocks where eToro activity can represent a meaningful portion of daily exchange volume.

**RN usage**: For Top20_Volume* KPIs, `RN` gives the rank (1=highest volume). Filter `WHERE KPI = 'Top20_Volume' AND RN <= 5` to see top 5 instruments. For other KPIs, `RN` is NULL.

**Regulation segmentation**: Each KPI is computed separately per regulation entity. The same instrument can appear in the same KPI for multiple regulations if it has clients under multiple regulatory regimes.

**IsLowMktCap not stored**: The `IsLowMktCap` flag (RN_MktCap ≤ 20 in the most-recent StocksInfo data) determines the KPI suffix `_LowMktCap`. This flag is NOT stored in the output — it's embedded in the KPI name. Low-market-cap instruments are flagged separately because small-cap manipulation has different risk profiles.

**Weekday filter**: The SP has `DATEPART(dw, @Yesterday) BETWEEN 2 AND 6` for market hours derivation. Market data is only available for weekdays; weekend data may be absent.

**Distribution**: ROUND_ROBIN, clustered on Date. Always filter on `Date` first for performance.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Dim_Position (Trade.PositionTbl), Rankings StockInfo (market data), Dim_GetSpreadedPriceCandle60MinSplitted (price) |
| **Refresh** | Daily per weekday via `SP_ManipulationReport_RealStocks(@dd)` |
| **SP Author** | Amir Gurewitz (2019); Synapse migration 2024 |
| **PII** | none — instrument-level aggregates, no customer IDs |
| **Compliance** | Used for market manipulation surveillance under CySEC/FCA regulatory obligations |
| **Related** | `Dealing_ManipulationReport_RealStocks_CID` for customer-level breakdown |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Sample up to 2025-12-30 (active) |
| SP Logic | 4/5 | 700+ line SP fully traced; 8+ KPI patterns documented |
| Upstream Wiki | 2/5 | Multi-source; no single production upstream wiki |
| Business Context | 2/5 | Atlassian MCP unavailable; compliance purpose inferred from SP |
| **Total** | **7.5/10** | |

---

*Generated: 2026-03-21 | Batch 4 | Schema: Dealing_dbo*
