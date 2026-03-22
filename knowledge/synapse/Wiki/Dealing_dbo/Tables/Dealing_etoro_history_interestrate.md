# Dealing_dbo.Dealing_etoro_history_interestrate

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object** | Dealing_etoro_history_interestrate |
| **Type** | External Table |
| **Data Source** | `internal-sources` → `/Bronze/etoro/History/InterestRate/**` |
| **Columns** | 13 |
| **Primary Source** | etoro production `History.InterestRate` (Bronze layer) |
| **Consuming SPs** | `Dealing_dbo.SP_Islamic_Spot_Price_Adjustment`, `SP_Islamic_Spot_Price_Adjustment_Backup` |
| **Refresh** | Bronze layer loaded by Fivetran/data pipeline; external table definition is static |
| **PII** | NO |
| **Tags** | dealing, overnight-fees, interest-rate, islamic-finance, configuration, external-table, bronze |

---

## 1. Business Meaning

`Dealing_etoro_history_interestrate` is an **external table over the Bronze layer** that provides the full history of overnight fee interest rate configurations from the eToro production `History.InterestRate` table. Each row captures a period during which a specific interest rate configuration was active, bounded by `BeginTime` and `EndTime`.

Interest rates control the overnight/rollover fees charged to CFD positions. The table includes both the base interest rate and markup values for buy and sell directions. These rates are set manually by the Dealing Operations team and vary by `InstrumentTypeID` (e.g., stocks, crypto, commodities) and by settlement type.

While the SP `SP_Islamic_Spot_Price_Adjustment` references `Dealing_staging.External_Fivetran_dealing_overnight_fees` (futures prices), this table provides the underlying interest rate configuration history that can be used for auditing and rate reconstruction.

---

## 2. Business Logic

### Data Model — SCD Type 2 History

Each row represents a validity period for an interest rate configuration:
- `BeginTime`: When this rate became effective
- `EndTime`: When this rate was superseded by a newer one
- Multiple rows per `InterestRateID` capture the full history of changes

### Rate Components

The overnight fee for a position is computed from three components:
- **InterestRate**: The base rate (legacy field, may be deprecated in favor of directional rates)
- **InterestRateBuy / InterestRateSell**: Directional base rates
- **MarkupBuy / MarkupSell**: eToro's spread/markup on top of the base rate

### Operational Context

- **UpdatedByUser**: Records which ops team member changed the rate (e.g., `Konstantinosle`, `arthurgr`, `adamco`, `orankr`)
- **OverNightFeePatternID**: Links to a fee pattern configuration (0 = default)
- **SettlementTypeID**: Distinguishes settlement methods (0 = default)

---

## 3. Relationships

| Related Table | Join Key | Relationship |
|---------------|----------|--------------|
| `DWH_dbo.Dim_Instrument` | `InstrumentTypeID` | Instrument type classification |
| `Dealing_dbo.Dealing_Islamic_Daily_Spot_Price_Adjustment` | Conceptual | Islamic fee calculation output |
| `Dealing_dbo.External_Fivetran_dealing_overnight_fees` | Conceptual | Futures-specific overnight fee pricing |

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 — SP code / DDL | `(Tier 2 — DDL + live data)` |
| ★★ | Tier 3 — live data / structure | `(Tier 3 — live data)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | InterestRateID | int | YES | Identifier for the interest rate configuration group (e.g., 1 = IR USD, 2 = IR EUR, 5 = IR NOK, 10 = IR SAR). Groups rate records by currency. (Tier 2 — DDL + live data) |
| 2 | InterestRateName | varchar(100) | YES | Display name of the interest rate configuration (e.g., `IR USD`, `IR EUR`, `IR NOK`). Format: `IR {CurrencyCode}`. (Tier 2 — DDL + live data) |
| 3 | InterestRate | decimal(16,8) | YES | Legacy base interest rate value. In newer records this is typically 0 (`0E-8`) as directional rates (`InterestRateBuy`/`InterestRateSell`) are used instead. (Tier 3 — live data) |
| 4 | UpdatedByUser | varchar(100) | YES | Username of the ops team member who set this rate configuration (e.g., `Konstantinosle`, `arthurgr`, `orankr`). `initial script` for seed data. (Tier 2 — DDL + live data) |
| 5 | BeginTime | datetime2(7) | YES | Start of the validity period for this rate configuration. SCD Type 2 effective-from timestamp. (Tier 2 — DDL) |
| 6 | EndTime | datetime2(7) | YES | End of the validity period for this rate configuration. SCD Type 2 effective-to timestamp. NULL or far-future for the currently active rate. (Tier 2 — DDL) |
| 7 | InstrumentTypeID | int | YES | Instrument type this rate applies to. FK to Dim_Instrument.InstrumentTypeID. Observed: 5 (Stocks), 6 (Indices). (Tier 2 — DDL + live data) |
| 8 | InterestRateBuy | decimal(16,8) | YES | Base interest rate for buy (long) positions. The actual overnight fee charged includes this rate plus `MarkupBuy`. Negative values (e.g., `-1.0`) indicate legacy/placeholder configurations. (Tier 2 — DDL + live data) |
| 9 | InterestRateSell | decimal(16,8) | YES | Base interest rate for sell (short) positions. The actual overnight fee charged includes this rate plus `MarkupSell`. (Tier 2 — DDL + live data) |
| 10 | MarkupBuy | decimal(16,8) | YES | eToro's spread/markup on buy-side overnight fees, added to `InterestRateBuy`. Typical values around 0.064 (6.4%). Negative values are legacy. (Tier 2 — DDL + live data) |
| 11 | MarkupSell | decimal(16,8) | YES | eToro's spread/markup on sell-side overnight fees, added to `InterestRateSell`. Often 0 for sell-side or a smaller markup. (Tier 2 — DDL + live data) |
| 12 | OverNightFeePatternID | int | YES | Links to a fee pattern configuration. 0 = default pattern. Non-zero values may indicate special fee schedules. (Tier 3 — live data) |
| 13 | SettlementTypeID | int | YES | Settlement method identifier. 0 = default. May differentiate between cash-settled and physically-settled instruments. (Tier 3 — live data) |

---

## 5. Usage Notes

**SCD Type 2 querying**: To get the active rate for a given date, filter `WHERE @Date BETWEEN BeginTime AND EndTime`. For the current rate, use `WHERE EndTime > GETDATE()` or take the MAX(`BeginTime`) row.

**Directional rates**: Prefer `InterestRateBuy`/`InterestRateSell` over the legacy `InterestRate` column. Newer configurations set `InterestRate = 0` and use only the directional fields.

**Bronze layer**: This is raw, unprocessed data from the production `History.InterestRate` table. It contains all historical versions including superseded configurations.

---

## 6. Governance

| Property | Value |
|----------|-------|
| **Source** | etoro production `History.InterestRate` via Bronze data lake |
| **Refresh** | Continuous Bronze ingestion; external table definition is static |
| **PII** | NO |
| **Owner** | Dealing Operations (rate setters), Data Platform (pipeline) |

---

## 7. Quality Score

| Dimension | Score | Notes |
|-----------|-------|-------|
| Structure | 5/5 | Full DDL analyzed |
| Live Data | 5/5 | Sampled with meaningful rate values |
| SP Logic | 4/5 | Consuming SPs analyzed (not direct writer) |
| Upstream Wiki | 2/5 | No upstream wiki for Bronze source |
| Business Context | 3/5 | No specific Atlassian hits; purpose clear from schema and consuming SPs |
| **Total** | **7.5/10** | |

---

*Generated: 2026-03-21 | Batch 19 | Schema: Dealing_dbo*
