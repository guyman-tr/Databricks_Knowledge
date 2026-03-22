# Dealing_dbo.External_Fivetran_dealing_overnight_fees

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | External_Fivetran_dealing_overnight_fees |
| **Type** | Table |
| **Distribution** | ROUND_ROBIN |
| **Index** | CLUSTERED COLUMNSTORE |
| **Columns** | 9 |
| **Primary Source** | Fivetran connector (Bloomberg futures price data) |
| **Consuming SPs** | `Dealing_dbo.SP_Islamic_Spot_Price_Adjustment` (via `Dealing_staging` alias) |
| **Refresh** | Fivetran sync (continuous) |
| **PII** | NO |
| **Tags** | dealing, fivetran, overnight-fees, futures, islamic-finance, bloomberg, pricing |

---

## 1. Business Meaning

`External_Fivetran_dealing_overnight_fees` is a **Fivetran-loaded table** containing Bloomberg futures contract closing prices used to calculate Islamic account spot price adjustment fees. Each row represents one futures contract ticker's closing price for a given date.

For Islamic (Sharia-compliant) accounts, overnight rollover fees cannot be charged as interest. Instead, eToro uses a **spot price adjustment** based on the futures curve contango/backwardation. The fee is derived from the price difference between the front-month (`Front`) and next-month (`Next`) futures contracts, divided by the days between their expirations.

This table is the critical pricing input for `SP_Islamic_Spot_Price_Adjustment`, which reads it through the `Dealing_staging` schema alias to compute daily fees for Islamic account holders with open positions in specific commodity/energy instruments (InstrumentIDs 17, 22, 339, 340, 341, 343, 344).

---

## 2. Business Logic

### Fivetran Load Pattern

Data is synced continuously by the Fivetran connector. The `_fivetran_synced` column records the sync timestamp. The `_row` column serves as Fivetran's internal row identifier.

### How SP_Islamic_Spot_Price_Adjustment Uses This Table

1. **#Futures_Prices**: Selects all rows for `@Date`, deduplicates using `DENSE_RANK() OVER (PARTITION BY date ORDER BY update_date DESC)` to get the latest update per date. Then ranks by ticker within each `future_short_cut` to assign `Front/Next` designation (`ROW_NUMBER() OVER (PARTITION BY future_short_cut ORDER BY ticker)`).
2. **Fee calculation**: `Final_Fee = Direction × ((Next_Close - Front_Close) / Days_Between_Expiration) × Units × Days_To_Charge`
3. **Email alert**: If no pricing data exists for `@Date` on a non-weekend day, an alert row is inserted into `Dealing_Islamic_Daily_Spot_Price_Adjustment_Email`.

### Key Instruments

The `future_short_cut` field maps to Bloomberg futures root tickers:
- `CL` → WTI Crude Oil (InstrumentID 17)
- `NG` → Natural Gas (InstrumentID 22)
- `LL` → LME Copper (InstrumentID 339)
- `LX` → LME Zinc (InstrumentID 340)
- Other commodity tickers for InstrumentIDs 341, 343, 344

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment` | `instrument_id` → `InstrumentID` | Fee output table |
| `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment_Email` | Conceptual | Alert when no data available |
| `DWH_dbo.Dim_Instrument` | `instrument_id` → `InstrumentID` | Instrument metadata |
| `DWH_dbo.Dim_Date` | `date` → `FullDate` | Weekend/holiday detection |
| `Dealing_dbo.Dealing_overnight_fees` | Conceptual | Existing overnight fees table (non-Islamic) |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — SP_Islamic_Spot_Price_Adjustment)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | _row | bigint | YES | Fivetran internal row identifier. Auto-assigned by the Fivetran connector. Not meaningful for business queries. (Tier 3 — Fivetran metadata) |
| 2 | _fivetran_synced | datetime2(7) | YES | Timestamp when Fivetran synced this row to Synapse. Used for freshness tracking. Example: `2025-04-23 13:55:00`. (Tier 3 — Fivetran metadata) |
| 3 | future_short_cut | nvarchar(4000) | YES | Bloomberg futures root ticker symbol identifying the commodity group (e.g., `NG` = Natural Gas, `CL` = WTI Crude Oil, `LL` = LME Copper, `LX` = LME Zinc). Used by the SP to partition front/next contracts. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 4 | ticker | nvarchar(4000) | YES | Full Bloomberg ticker for the specific futures contract (e.g., `NG1 COMB Comdty`, `LL4 Comdty`, `LX3 Comdty`). Sorted within each `future_short_cut` to determine front (rank 1) vs next (rank 2) contract. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 5 | days | int | YES | Days between front and next contract expirations. Used as the denominator in the fee formula: `(Next - Front) / days`. NULL for some contracts (e.g., metals without explicit expiry gaps). (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 6 | close | float | YES | Closing price of the futures contract on the given date. The price difference between front and next contracts drives the Islamic spot price adjustment fee. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 7 | instrument_id | int | YES | eToro InstrumentID mapped to this futures contract. FK to `DWH_dbo.Dim_Instrument`. Expected values: 17 (WTI), 22 (NatGas), 339, 340, 341, 343, 344. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 8 | date | datetime2(7) | YES | The trading date for this closing price. The SP filters `WHERE CAST(date AS DATE) = @Date` to get daily prices. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |
| 9 | update_date | datetime2(7) | YES | Timestamp of the data update from the source. Used for deduplication: `DENSE_RANK() OVER (... ORDER BY update_date DESC)` takes the latest update when multiple syncs exist for the same date. (Tier 2 — SP_Islamic_Spot_Price_Adjustment) |

---

## 5. Usage Notes

**Schema alias**: `SP_Islamic_Spot_Price_Adjustment` reads this table from `Dealing_staging` schema (`[Dealing_staging].[External_Fivetran_dealing_overnight_fees]`), not `Dealing_dbo`. The `Dealing_dbo` copy may be a synonym or a replicated copy — verify which is authoritative.

**Deduplication required**: Multiple rows can exist per instrument per date due to intraday Fivetran syncs. Always use `DENSE_RANK() OVER (PARTITION BY CAST(date AS DATE) ORDER BY update_date DESC)` and filter `WHERE Rank = 1`.

**Front/Next determination**: The SP assigns `ROW_NUMBER() OVER (PARTITION BY future_short_cut ORDER BY ticker)` — the alphabetically first ticker is "Front" (rank 1) and the second is "Next" (rank 2). This works because Bloomberg ticker naming conventions sort front-month first.

**NULL days**: Some commodity contracts (e.g., metals like `LL4 Comdty`) have NULL `days` values. The SP uses `Days_Between_Expiration` from the front-month contract join — verify NULL handling in edge cases.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | Fivetran connector → Bloomberg futures data |
| **Refresh** | Continuous Fivetran sync |
| **PII** | NO |
| **SP Author** | Gili Goldbaum (2024-03-07) |
| **Owner** | Dealing / Quantitative Analytics |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Active data with recent prices |
| SP Logic | 5/5 | Full SP_Islamic_Spot_Price_Adjustment analyzed (377 lines) |
| Upstream Wiki | 2/5 | No upstream wiki for Fivetran source |
| Business Context | 3/5 | Islamic finance context clear from SP and related tables |
| **Total** | **8.0/10** | |

---

*Generated: 2026-03-21 | Batch 19 | Schema: Dealing_dbo*
