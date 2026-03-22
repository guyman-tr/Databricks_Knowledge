# Dealing_dbo.Dealing_SpreadsMST

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_SpreadsMST |
| **Type** | Table |
| **ETL SP** | `Dealing_dbo.SP_SpreadsMST` |
| **Refresh** | Daily (Priority 0) |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED on `[Date]` |
| **Rows** | ~8.2M |
| **Date Range** | 2023-08-05 → 2026-03-10 (active) |
| **PII** | none |

---

## 1. Business Meaning

Daily snapshot of bid/ask spreads and Market Spread Threshold (MST) values for all tradable instruments on eToro's platform. Each row represents one instrument on one date, capturing the configured spread type, bid/ask prices, MST threshold, and reference prices used in spread monitoring. Covers Stocks (83%), ETFs (9%), Crypto (2.8%), Commodities (2.4%), Indices (1.3%), and Currencies (1.2%).

This table is the Dealing desk's daily spread audit tool — comparing actual market spreads (Bid/Ask) against the configured Market Spread Threshold (MarketSpreadThreshold) to detect instruments where spreads are excessively wide or where eToro's configured spread deviates from a reference price. `VisibleInternallyOnly=1` (23.5% of rows) flags instruments shown only in internal Dealing dashboards, not on the public eToro platform.

---

## 2. Business Logic

- **Source**: `Dealing_staging.External_Etoro_Trade_InstrumentSpread` (joins to `etoro_Trade_InstrumentMetaData`, `External_Etoro_Dictionary_SpreadType`, `DWH_dbo.Dim_Instrument`)
- **Filter**: `Dim_Instrument.Tradable = 1 AND FeedID = 1` — only primary-feed tradable instruments
- **Write pattern**: DELETE WHERE Date = @Date → INSERT
- **SpreadsType**: Comes from `External_Etoro_Dictionary_SpreadType.Name`. Two observed values: 'PrecentageSpread' (89%, typo for PercentageSpread) and 'SpreadInPips' (11%). The typo originates in the Dictionary source table.
- **SpreadThresholdTypeID**: Always 1 in current data — single threshold type in use.
- **FeedID**: Always 1 in output (filtered in SP). Identifies the primary price feed source.
- **VisibleInternallyOnly**: From `Dim_Instrument.VisibleInternallyOnly`. When 1, the instrument is accessible only through internal tools, not on the public eToro platform.
- **Author**: Arthur Greenberg (created 03-08-2023)

---

## 3. Relationships

| Direction | Table | Join Key | Notes |
|-----------|-------|----------|-------|
| Source | `Dealing_staging.External_Etoro_Trade_InstrumentSpread` | `InstrumentID` | Spread configuration per instrument |
| Source | `Dealing_staging.etoro_Trade_InstrumentMetaData` | `InstrumentID` | Display name, symbol, exchange |
| Source | `Dealing_staging.External_Etoro_Dictionary_SpreadType` | `SpreadTypeID` | Spread type name lookup |
| Source | `DWH_dbo.Dim_Instrument` | `InstrumentID` | InstrumentType, VisibleInternallyOnly, Tradable filter |

---

## 4. Elements

| Column | Type | Nullable | Description |
|--------|------|----------|-------------|
| `Date` | date | YES | Reporting date. Clustered index. |
| `InstrumentID` | int | YES | eToro instrument identifier. |
| `InstrumentDisplayName` | varchar(150) | YES | Instrument display name from `etoro_Trade_InstrumentMetaData`. |
| `Symbol` | varchar(30) | YES | Instrument ticker symbol (e.g., 'AAPL', 'BTC'). |
| `SpreadsType` | varchar(150) | YES | Spread type: 'PrecentageSpread' (89%) or 'SpreadInPips' (11%). **Note: 'PrecentageSpread' is a typo** in the source Dictionary table — preserved. |
| `Bid` | decimal(16,6) | YES | Bid price for the instrument on this date. |
| `Ask` | decimal(16,6) | YES | Ask price for the instrument on this date. |
| `MarketSpreadThreshold` | decimal(16,6) | YES | Maximum acceptable market spread (MST). Spreads exceeding this trigger Dealing alerts. |
| `ReferenceBid` | decimal(16,6) | YES | Reference bid price used as baseline for spread deviation monitoring. |
| `ReferenceAsk` | decimal(16,6) | YES | Reference ask price used as baseline for spread deviation monitoring. |
| `SpreadThresholdTypeID` | int | YES | Threshold type identifier. Always 1 in current data. |
| `FeedID` | decimal(16,6) | YES | Price feed identifier. Always 1 (primary feed filter applied in SP). |
| `Exchange` | varchar(150) | YES | Exchange where instrument trades (e.g., 'NASDAQ', 'NYSE'). |
| `InstrumentType` | varchar(150) | YES | Instrument category: 'Stocks', 'ETF', 'Crypto Currencies', 'Commodities', 'Indices', 'Currencies'. From Dim_Instrument. |
| `VisibleInternallyOnly` | int | YES | 0 = visible on public eToro platform; 1 = internal/Dealing-only instrument (~23.5% of rows). |
| `UpdateDate` | datetime | NOT NULL | ETL metadata: timestamp when this row was last updated by the ETL pipeline. |

---

## 5. Data Quality Notes

- **'PrecentageSpread' typo**: The SpreadsType value 'PrecentageSpread' (for 89% of rows) is a typo from the source Dictionary table (`External_Etoro_Dictionary_SpreadType.Name`). It should be 'PercentageSpread'. Preserved as-is in this table — do not assume correct spelling in filters.
- **FeedID = 1**: SP filters FeedID=1, so only primary-feed instruments appear. Multi-feed instruments (if any) are excluded.
- **SpreadThresholdTypeID always 1**: Only one threshold type in use — field has no variation in current data.
- **Bid/Ask can be 0.0**: Zero bid/ask is observed for some instruments (e.g., delisted stocks, instruments with no active quotes). These are not NULL — they represent a genuine zero spread.

---

## 6. Usage Notes

```sql
-- Latest date
SELECT MAX([Date]) FROM Dealing_dbo.Dealing_SpreadsMST;

-- Instruments with spread above MST threshold (potential alert)
SELECT [Date], InstrumentDisplayName, SpreadsType, Bid, Ask, MarketSpreadThreshold
FROM Dealing_dbo.Dealing_SpreadsMST
WHERE [Date] = '2026-03-10'
  AND (Ask - Bid) > MarketSpreadThreshold
  AND MarketSpreadThreshold > 0
ORDER BY (Ask - Bid - MarketSpreadThreshold) DESC;

-- Internal-only instruments
SELECT InstrumentID, InstrumentDisplayName, InstrumentType
FROM Dealing_dbo.Dealing_SpreadsMST
WHERE [Date] = '2026-03-10' AND VisibleInternallyOnly = 1;
```

---

## 7. Sources & Confidence

| Source | Phase | Confidence |
|--------|-------|------------|
| SSDT DDL (`Dealing_dbo.Dealing_SpreadsMST.sql`) | P1 | High |
| SP Logic (`Dealing_dbo.SP_SpreadsMST.sql`) | P9 | High |
| Live data sample (Synapse MCP) | P2 | High |
| OpsDB orchestration | P9B | High |

**Quality Score: 8.0/10** — Active table with clear ETL, well-documented source SP. Deducted: no Atlassian scan (−1), SpreadsType typo adds confusion (−0.5), limited business context on MST threshold meaning (−0.5).
