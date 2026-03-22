# Dealing_dbo.Dealing_US_Stocks_SmartPortfolio

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_US_Stocks_SmartPortfolio |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_US_Stocks_SmartPortfolio` |
| **Refresh** | Daily (SB_Daily, Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~252.6K |
| **Date Range** | 2022-04-01 → 2026-03-10 (active) |
| **PII** | none |

---

## 1. Business Meaning

Daily Net Open Position (NOP) concentration monitoring for **US SmartPortfolio customers** (AccountTypeID=9) across US-listed stocks. Each row represents one instrument × direction (Buy/Sell) on a given date, showing the total NOP (`Units_NOP`) held by all SmartPortfolio copiers and the NOP as a percentage of the instrument's total shares outstanding (`Units_NOP/Shares Outstanding`).

The Dealing desk uses this to monitor position concentration risk — specifically, the SP sends an **email alert** when any instrument's NOP exceeds 5% of shares outstanding (`Units_NOP/Shares Outstanding > 5`). This is a regulatory concentration threshold for US broker-dealer operations.

SmartPortfolio uses AccountTypeID=9 parent CIDs. The SP traces from parents through `Dim_Mirror` to find all active copier CIDs, then reads their positions from `BI_DB_dbo.BI_DB_PositionPnL` for the given date. Market data (ADV, SharesOutstanding) comes from the `CopyFromLake.Rankings_StockInfo_InstrumentData` external data feed.

Scope: US stocks only (`InstrumentTypeID=5`, `SellCurrencyID=1`), excluding UK/European exchanges (LSE, SIX, Oslo, Euronext Amsterdam).

---

## 2. Business Logic

- **SmartPortfolio identification**: `Dim_Customer.AccountTypeID=9` identifies SmartPortfolio parent CIDs (valid customers only).
- **Copier resolution**: `Dim_Mirror` links copiers to parents — all active mirrors (`OpenDateID ≤ @DateID`, `CloseDateID=0 or > @DateID`, `IsActive=1`) for SmartPortfolio parents.
- **Position data**: `BI_DB_dbo.BI_DB_PositionPnL` filtered to `DateID=@DateID` and copier MirrorIDs in the active set.
- **NOP computation**: `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` per instrument × direction.
- **Market data**: From `CopyFromLake.Rankings_StockInfo_InstrumentData` via `DWH_staging.Rankings_StockInfo_Metadata`:
  - MetadataID 8557 = 'AverageDailyVolumeLast3Months-TTM' → `ADV`
  - MetadataID 8444 = 'SharesOutstandingCurrent-Annual' → `SharesOutStanding`
  - MetadataID 8703 = 'LastClose-TTM' → (used for USD conversion only, not stored)
  - MetadataID 8735 = 'MarketCapitalization-TTM' → (used for computation only, not stored)
- **Exchange normalization**: Nasdaq/NASDAQ → 'Nasdaq'; OTCMKTS/OTC Markets Stock Exchange → 'OTC Markets Stock Exchange'; all others → 'NYSE'.
- **Concentration ratio**: `CAST(100 * ABS(Units_NOP / SharesOutStanding) AS DECIMAL(16,4))` — stored as percentage (e.g., 2.5 = 2.5%).
- **Alert threshold**: SP sends email when concentration > 5%.
- **DELETE+INSERT by Date**: Accumulating, not TRUNCATE.

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `BI_DB_dbo.BI_DB_PositionPnL` | `InstrumentID, DateID` | SmartPortfolio copier positions |
| Source | `DWH_dbo.Dim_Customer` | `RealCID` | AccountTypeID=9 (SmartPortfolio) filter |
| Source | `DWH_dbo.Dim_Mirror` | `CID, ParentCID` | Active mirror/copier relationships |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | Instrument metadata (US filter) |
| Source | `CopyFromLake.Rankings_StockInfo_InstrumentData` | `InstrumentID, MetadataID` | ADV and SharesOutstanding |
| Source | `DWH_staging.Rankings_StockInfo_Metadata` | `MetadataID` | Metric name/key mapping |
| Source | `DWH_dbo.Fact_CurrencyPriceWithSplit` | `InstrumentID, OccurredDateID` | FX rates (for non-USD instruments) |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Date of the NOP snapshot. Clustered index. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `InstrumentID` | int | YES | eToro instrument ID. US stocks only (InstrumentTypeID=5, SellCurrencyID=1). (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `InstrumentDisplayName` | varchar(100) | YES | Instrument display name from Dim_Instrument. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `IsBuy` | bit | YES | Position direction: 1=Buy (long), 0=Sell (short). (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `Symbol` | varchar(100) | YES | Ticker symbol from Dim_Instrument. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `Exchange` | varchar(100) | YES | Normalized exchange name. 'Nasdaq', 'OTC Markets Stock Exchange', or 'NYSE'. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `ADV` | bigint | YES | Average Daily Volume (last 3 months, TTM) from Rankings data. MetadataID 8557 ('AverageDailyVolumeLast3Months-TTM'). (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `Units_NOP` | decimal(38,6) | YES | Net Open Position in units: `SUM((2*IsBuy-1)*AmountInUnitsDecimal)` for all SmartPortfolio copiers. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `SharesOutStanding` | bigint | YES | Total shares outstanding (Annual) from Rankings data. MetadataID 8444 ('SharesOutstandingCurrent-Annual'). (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `Units_NOP/Shares Outstanding` | decimal(16,6) | YES | Concentration ratio: `100 × ABS(Units_NOP / SharesOutStanding)`. Values ≥5 trigger email alerts. Special-character column. (Tier 2 — SP_US_Stocks_SmartPortfolio) |
| `UpdateDate` | datetime | YES | ETL metadata: `GETDATE()` at SP execution time. |

---

## 5. Data Quality Notes

- **Alert threshold**: `[Units_NOP/Shares Outstanding]` values ≥ 5.0 trigger email alerts to the Dealing desk. Do not interpret values > 5 as errors.
- **SmartPortfolio scope only**: Only AccountTypeID=9 positions are included. Regular customer positions are excluded.
- **US instruments only**: Excludes LSE, SIX, Oslo Stock Exchange, Euronext Amsterdam. Includes Nasdaq, NYSE, OTC markets.
- **Rankings data freshness**: ADV and SharesOutstanding come from `CopyFromLake.Rankings_StockInfo_InstrumentData` — confirm how frequently this feed is updated (daily/weekly).
- **Special-character column**: `[Units_NOP/Shares Outstanding]` requires bracket quoting.
- **IsBuy is bit**: Unlike most tables in Dealing schema that use varchar 'Buy'/'Sell', this table stores the raw bit value.

---

## 6. Usage Notes

```sql
-- Latest date available
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_US_Stocks_SmartPortfolio;

-- Stocks above 5% concentration threshold
SELECT [Date], InstrumentDisplayName, Symbol, Exchange,
       Units_NOP, SharesOutStanding, [Units_NOP/Shares Outstanding]
FROM Dealing_dbo.Dealing_US_Stocks_SmartPortfolio
WHERE [Date] = '2026-03-10'
  AND [Units_NOP/Shares Outstanding] >= 5.0
  AND IsBuy = 1
ORDER BY [Units_NOP/Shares Outstanding] DESC;
```

---

## 7. Known Issues

- `[Units_NOP/Shares Outstanding]` requires bracket quoting (special character).
- Rankings data (ADV, SharesOutstanding) has unknown freshness cadence — may lag if the external feed is delayed.
- `IsBuy` stored as bit (0/1), not varchar 'Buy'/'Sell' — unlike most Dealing schema tables.

---

## 8. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_US_Stocks_SmartPortfolio.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_US_Stocks_SmartPortfolio.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |
| Atlassian knowledge scan | P10 | Not available (−3 quality) |

**Quality Score: 7.5/10** — Active table with complete ETL logic. Deducted: no Atlassian scan (−1), external Rankings feed dependency (−0.5), IsBuy bit type inconsistency (−0.5), special-character column (−0.5).
