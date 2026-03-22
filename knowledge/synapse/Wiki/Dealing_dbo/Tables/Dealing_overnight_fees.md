# Dealing_dbo.Dealing_overnight_fees

> Futures overnight fee reference data synced via Fivetran — contains Bloomberg closing prices and days-to-expiry for futures contract rollover calculations.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | External (Fivetran connector — likely Bloomberg/Google Sheets) |
| **Refresh** | Fivetran-managed (see _fivetran_synced) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED COLUMNSTORE INDEX |

---

## 1. Business Meaning

This table stores overnight fee reference data for futures instruments. It contains Bloomberg futures contract tickers (e.g., CL1 COMB Comdty = Crude Oil front month), closing prices, and days-to-expiry values used to calculate overnight/rollover fees for CFD positions on futures-based instruments.

The data is loaded externally via Fivetran (evidenced by `_row` and `_fivetran_synced` columns), not by a Synapse stored procedure. It serves as a reference input for Islamic spot price adjustment calculations (referenced by `SP_Islamic_Spot_Price_Adjustment_Backup`).

Sample data shows commodities: CL (Crude Oil), NG (Natural Gas), LN (Nickel). Tickers follow Bloomberg convention with "COMB Comdty" suffix for combined futures.

---

## 2. Business Logic

### 2.1 Futures Contract Structure

**What**: Each row represents a futures contract for an instrument on a specific date.

**Rules**:
- `future_short_cut` is the commodity code (CL, NG, LN)
- `ticker` is the full Bloomberg ticker (e.g., CL1 = front month, CL2 = second month)
- `days` = days to expiry/rollover for the front-month contract; NULL for back-month contracts
- `close` = end-of-day closing price from Bloomberg
- Multiple rows per instrument per date (front month + back month)

### 2.2 Downstream Usage

Referenced by `SP_Islamic_Spot_Price_Adjustment_Backup` for Islamic account overnight fee calculations. The close prices and days-to-expiry are used to compute rollover cost adjustments.

---

## 3. Query Advisory

### 3.1 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Latest futures prices | `WHERE date = (SELECT MAX(date) FROM Dealing_dbo.Dealing_overnight_fees)` |
| Front month vs back month spread | `WHERE future_short_cut = 'CL' AND date = @date` (CL1 vs CL2) |
| Price history for an instrument | `WHERE instrument_id = @id ORDER BY date` |

### 3.2 Gotchas

- **Fivetran sync timing**: _fivetran_synced reflects when Fivetran loaded the data, not when the data was generated.
- **_row column**: Both _row and _fivetran_synced may be NULL (observed in sample data). These are Fivetran infrastructure columns.
- **Not loaded by SP**: No Synapse ETL procedure writes to this table. It's externally managed.
- **Last data**: Sample shows data up to 2024-03-22. Verify if Fivetran sync is still active.

---

## 4. Elements

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | _row | bigint | YES | Fivetran row identifier. Infrastructure column, not business-relevant. (Tier 3 — DDL) |
| 2 | _fivetran_synced | datetime2(7) | YES | Fivetran sync timestamp. When Fivetran loaded this record. (Tier 3 — DDL) |
| 3 | future_short_cut | nvarchar(4000) | YES | Futures contract shortcut code. Identifies the underlying commodity: CL=Crude Oil, NG=Natural Gas, LN=Nickel. (Tier 3 — live data) |
| 4 | ticker | nvarchar(4000) | YES | Bloomberg futures ticker. Format: {Code}{MonthNumber} [{Type}] {AssetClass}. E.g., "CL1 COMB Comdty" = Crude Oil front month combined futures commodity. (Tier 3 — live data) |
| 5 | days | int | YES | Days to contract expiry or rollover. Present for front-month contracts, NULL for back-month. Used in overnight fee calculation. (Tier 3 — live data) |
| 6 | close | float | YES | End-of-day closing price from Bloomberg. Used as reference for overnight fee and Islamic spot price adjustments. (Tier 3 — live data) |
| 7 | instrument_id | int | YES | Internal instrument ID. FK to DWH_dbo.Dim_Instrument. Maps Bloomberg ticker to platform instrument. (Tier 3 — live data) |
| 8 | date | datetime2(7) | YES | Business date of the price/contract data. (Tier 3 — live data) |
| 9 | update_date | datetime2(7) | YES | Source-side update timestamp. When the external data provider last updated this record. (Tier 3 — live data) |

---

## 5. Lineage

### 5.1 ETL Pipeline

```
External Bloomberg/Sheets source → Fivetran → Dealing_overnight_fees
```

No Synapse SP manages this data. Fivetran connector handles extraction and loading.

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| instrument_id | DWH_dbo.Dim_Instrument | Maps to platform instrument definition |

### 6.2 Referenced By

| Source Object | Description |
|--------------|-------------|
| SP_Islamic_Spot_Price_Adjustment_Backup | Uses overnight fee data for Islamic account adjustments |

---

*Generated: 2026-03-21 | Quality: 6.0/10 (★★★☆☆) | Phases: 5/14*
*Tiers: 0 T1, 0 T2, 9 T3, 0 T4, 0 T5 | Elements: 8/10, Logic: 5/10, Relationships: 5/10, Sources: 4/10*
*Object: Dealing_dbo.Dealing_overnight_fees | Type: Table | Production Source: External (Fivetran)*
