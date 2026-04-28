# Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee

> 17.9M-row daily Islamic account administrative fee calculation table, recording per-position fee charges for swap-free (Sharia-compliant) accounts across all asset classes (Stocks, Crypto, Commodities, Indices, Currencies, ETF) from 2022-12-30 to present. Loaded daily by SP_Islamic_Administrative_Fee with a DELETE+INSERT per @Date.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table (Fact) |
| **Production Source** | ETL-computed from DWH_dbo.Dim_Position + Dim_Customer + Dim_Instrument + Fact_CurrencyPriceWithSplit + Islamic config tables, via SP_Islamic_Administrative_Fee |
| **Refresh** | Daily (DELETE for @Date, INSERT from SP) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX ([Date] ASC) |
| | |
| **UC Target** | _Pending_ |
| **UC Format** | _Pending_ |
| **UC Partitioned By** | _Pending_ |
| **UC Table Type** | _Pending_ |

---

## 1. Business Meaning

`Dealing_Islamic_Daily_Administrative_Fee` is a daily fact table that calculates the administrative fees charged to Islamic (swap-free) trading accounts on the eToro platform. Islamic accounts do not pay traditional overnight swap/rollover fees (to comply with Sharia law); instead, they pay a flat administrative fee per instrument group after a 7-day grace period.

Each row represents one position held by one Islamic customer on one date, with all the intermediate calculation fields (days open, days to charge, unit price, fee rate) preserved alongside the final fee amount. The table spans from 2022-12-30 to present with ~17.9M rows, covering ~1,078 distinct customers and ~773 distinct instruments in a recent month.

**Islamic account identification**: Customers with `WeekendFeePrecentage = 0` in Dim_Customer AND `IsValidCustomer = 1`.

**Position eligibility**:
- Instruments mapped in `Dealing_Islamic_Instruments_Groups` (Currencies, Commodities, Indices)
- Stock/ETF CFDs with Leverage > 1 and IsBuy = 1 (long only)
- Crypto CFDs (excluding German customers' long leverage-1 positions)
- A hardcoded list of ~26 suspended instruments is excluded

**Fee formula** varies by asset class — see Section 2.1.

**ETL pattern**: SP_Islamic_Administrative_Fee runs daily, parameterized by @Date. It DELETEs all rows for @Date, then INSERTs calculated rows from a multi-step temp table pipeline joining Dim_Position, Dim_Customer, Dim_Instrument, price data, and fee config tables.

---

## 2. Business Logic

### 2.1 Fee Calculation by Asset Class

**What**: The final fee amount depends on the asset class, with different unit normalization formulas.

**Columns Involved**: `Final_Fee`, `InstrumentTypeID`, `AmountInUnitsDecimal`, `USD_Price`, `Admin_Fee_USD`, `Days_To_Charge`, `Units_per_Contract`

**Rules**:
- **Currencies (InstrumentTypeID=1)**: `(ABS(AmountInUnitsDecimal) / 100000) × Admin_Fee_USD × Days_To_Charge × (-1)`
- **Commodities (2)**: `(ABS(AmountInUnitsDecimal) / Units_per_Contract) × Admin_Fee_USD × Days_To_Charge × (-1)`
- **Indices (4)**: `ABS(AmountInUnitsDecimal) × Admin_Fee_USD × Days_To_Charge × (-1)`
- **Stocks (5) / ETF (6)**: `((ABS(AmountInUnitsDecimal) × USD_Price) / 10000) × Admin_Fee_USD × Days_To_Charge × (-1)`
- **Crypto (10)**: Same formula as Stocks/ETF
- All other: 0
- Final value is negated (fee is a charge, stored as negative)

### 2.2 Days Open Counting Logic

**What**: Days_Open uses weighted day counts that vary by exchange type, reflecting when markets are open.

**Columns Involved**: `Days_Open`, `ExchangeID`, `InstrumentID`, `NewOpenOccurred`, `Date`

**Rules**:
- **Commodity instruments (IDs 17,22,339,340,341,343,344) and ExchangeID >= 3 (excl. 8)**: Fridays count as 3 (weekend rollover); Sat/Sun = 0
- **ExchangeID 1 (excl. InstrumentID 62) or ExchangeID 2**: Wednesdays count as 3; Sat/Sun = 0
- **InstrumentID 62 on ExchangeID 1**: Thursdays count as 3; Sat/Sun = 0
- **ExchangeID 8 (Digital Currency)**: Every day counts as 1 (crypto trades 24/7)
- **All others**: Weekdays = 1, Sat/Sun = 0

### 2.3 Days To Charge Logic

**What**: Determines how many days of fee to actually charge on a given date, accounting for the triple-charge day pattern.

**Columns Involved**: `Days_To_Charge`, `Days_Admin_Fee`, `ExchangeID`, `InstrumentID`

**Rules**:
- If ExchangeID = 8 (crypto) and Days_Admin_Fee > 0: charge 1 day
- On the "triple day" (Fri for commodities/Asian, Wed for NYSE/LSE, Thu for InstrumentID=62): charge min(Days_Admin_Fee, 3)
- On regular weekdays: charge 1 if Days_Admin_Fee > 0
- Weekends: charge 0
- `Days_Admin_Fee = Days_Open - GracePeriod` (7-day grace period)

### 2.4 Position Cutoff Time

**What**: The 22:00 GMT cutoff determines whether a position counts as opened on the current or next trading day.

**Columns Involved**: `IsTheDayBefore`, `NewOpenOccurred`, `OpenOccurred`

**Rules**:
- If `CONVERT(time, OpenOccurred) >= 22:00:00` → `IsTheDayBefore = 1` and `NewOpenOccurred` is shifted to the next calendar day
- Otherwise → `IsTheDayBefore = 0` and `NewOpenOccurred = CONVERT(DATE, OpenOccurred)`

### 2.5 USD Price Computation

**What**: Converts the instrument price to USD using the appropriate conversion rate based on position direction.

**Columns Involved**: `USD_Price`, `Bid`, `Ask`, `ConvertRateIsBuy_1`, `ConvertRateIsBuy_0`, `IsBuy`

**Rules**:
- If `IsBuy = 1`: `USD_Price = Bid × ConvertRateIsBuy_1`
- If `IsBuy = 0`: `USD_Price = Ask × ConvertRateIsBuy_0`

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**ROUND_ROBIN** distribution — rows spread evenly across nodes with no co-location. JOINs to HASH-distributed tables (Dim_Position, Dim_Instrument) will require data movement.

**CLUSTERED INDEX on [Date] ASC** — date-range queries are efficient. Always include a `[Date]` or `DateID` filter.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total fees charged on a date | `SELECT SUM(Final_Fee) FROM ... WHERE [Date] = '2026-04-25'` |
| Fees by asset class for a period | `WHERE [Date] BETWEEN ... GROUP BY InstrumentTypeID, InstrumentType` |
| Customer-level fee summary | `WHERE [Date] BETWEEN ... GROUP BY RealCID, UserName` |
| Positions still in grace period | `WHERE Days_To_Charge = 0 AND Days_Open <= 7` |
| Positions actually charged | `WHERE Final_Fee <> 0` (about 54% of rows in a recent month) |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Position | ON PositionID | Full position attributes (Amount, NetProfit, etc.) |
| DWH_dbo.Dim_Customer | ON RealCID = RealCID | Customer demographics, regulation |
| DWH_dbo.Dim_Instrument | ON InstrumentID | Instrument details beyond what is denormalized |
| Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | ON (InstrumentGroup, InstrumentTypeID) | Fee schedule reference |

### 3.4 Gotchas

- **Final_Fee is negative**: Fees are stored as negative values (charges). Use `ABS(Final_Fee)` or `SUM(Final_Fee) * -1` for positive fee reporting.
- **~46% of rows have Final_Fee = 0**: Positions within the grace period or on non-charge days have zero fee. Filter `WHERE Final_Fee <> 0` for actual charges.
- **ClosedOnWeekend is always 0**: The current SP logic filters out weekend rows (`WHERE ClosedOnWeekend = 0`), so this column is always 0 in the output.
- **InstrumentType_ID_InstrumentGroup, InstrumentName_InstrumentGroup, InstrumentGroup, Units_per_Contract are NULL for Stocks/ETF/Crypto**: These columns come from `Dealing_Islamic_Instruments_Groups` / `Dealing_Islamic_Units_Per_Contract` which only map Currencies, Commodities, and Indices. Stock/ETF/Crypto positions are included by SP logic (Leverage > 1 or CFD) but have NULL group columns.
- **Fee_Type_ID is always 1**: Hardcoded in the INSERT statement.
- **Suspended instruments excluded**: ~26 InstrumentIDs are hardcoded as excluded from the fee calculation.
- **German crypto exemption**: CountryID = 79 (Germany), InstrumentTypeID = 10 (Crypto), Leverage = 1, IsBuy = 1 positions are excluded.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Tag | Description |
|------|-----|-------------|
| Tier 1 | (Tier 1 — source) | Verbatim from upstream wiki via dim-lookup passthrough |
| Tier 2 | (Tier 2 — SP_Islamic_Administrative_Fee) | ETL-computed in SP |
| Tier 3 | (Tier 3 — MCP live data) | Confirmed via live sampling |

#### Group A: Date and Identity (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | The fee calculation date — the @Date input parameter to SP_Islamic_Administrative_Fee. One row per position per date. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 2 | DateID | int | YES | Integer representation of Date in YYYYMMDD format. ETL-computed: CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT). (Tier 2 — SP_Islamic_Administrative_Fee) |
| 3 | PositionID | bigint | YES | Primary key. Allocated by Internal.GetPositionID_Bigint. Unique per position. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 4 | RealCID | int | YES | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 5 | GCID | int | YES | Group Customer ID - cross-product identity key linking the same person across eToro products/entities. NULL for older accounts predating GCID introduction. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |
| 6 | UserName | varchar(20) | YES | Customer login username. Unique (case-insensitive, enforced via UserName_LOWER computed column index). Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |

#### Group B: Position Lifecycle (6 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 7 | OpenDateID | int | YES | ETL-computed date int (YYYYMMDD) derived from OpenOccurred. Used for date-range filtering. Passthrough from Dim_Position. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 8 | CloseDateID | int | YES | ETL-computed date int (YYYYMMDD) derived from CloseOccurred. 0=still open, 19000101=ETL transient state, YYYYMMDD=closed. Passthrough from Dim_Position. (Tier 2 — SP_Dim_Position_DL_To_Synapse) |
| 9 | OpenOccurred | datetime | YES | When position was persisted (mapped from Occurred in production). Default getutcdate(). Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 10 | NewOpenOccurred | datetime | YES | Adjusted open date for fee calculation: if position opened after 22:00 GMT, shifted to the next calendar day; otherwise same as OpenOccurred date. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 11 | CloseOccurred | datetime | YES | When close was persisted. Passthrough from Dim_Position. 1900-01-01 for open positions. (Tier 1 — Trade.PositionTbl) |
| 12 | NewCloseOccurred | datetime | YES | Close timestamp carried forward from Dim_Position.CloseOccurred. Currently identical to CloseOccurred (no transformation applied). (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group C: Fee Timing (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 13 | IsTheDayBefore | int | YES | 1 if the position was opened after 22:00 GMT (and thus its NewOpenOccurred is shifted to the next day); 0 otherwise. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 14 | InstrumentTypeID | int | YES | Asset class identifier: 1=Currencies, 2=Commodities, 4=Indices, 5=Stocks, 6=ETF, 10=Crypto. Passthrough from Dim_Instrument. (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group D: Instrument Details (8 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 15 | InstrumentType | varchar(50) | YES | Asset class name (e.g., "Stocks", "Crypto Currencies", "Commodities"). Passthrough from Dim_Instrument. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 16 | InstrumentID | int | YES | FK to Trade.Instrument. Financial instrument being traded. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 17 | InstrumentName | varchar(50) | YES | Instrument display name (e.g., "META/USD", "XAU/USD"). Passthrough from Dim_Instrument.Name. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 18 | InstrumentType_ID_InstrumentGroup | int | YES | Asset class identifier from fee group config. NULL for Stocks/ETF/Crypto (not mapped in Dealing_Islamic_Instruments_Groups). Passthrough from Dealing_Islamic_Instruments_Groups.instrument_type_id. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 19 | InstrumentName_InstrumentGroup | varchar(50) | YES | Instrument name from fee group config. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.name. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 20 | InstrumentGroup | int | YES | Fee tier group (1-4). Maps to Dealing_Islamic_Admin_Fee_Per_Group for fee rate lookup. NULL for Stocks/ETF/Crypto. Passthrough from Dealing_Islamic_Instruments_Groups.instrument_group. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 21 | Units_per_Contract | int | YES | Number of instrument units in one standard contract. Used as divisor in commodity fee calculation. NULL for non-commodity instruments. Passthrough from Dealing_Islamic_Units_Per_Contract. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 22 | Exchange | varchar(80) | YES | Exchange name (e.g., "NYSE", "Nasdaq", "Digital Currency"). Passthrough from Dim_Instrument. (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group E: Exchange and Trade Direction (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 23 | ExchangeID | int | YES | Exchange identifier from Dim_ExchangeInfo. Determines day-counting rules: 1/2=Wed triple, >=3 excl.8=Fri triple, 8=every day (crypto). Passthrough from Dim_ExchangeInfo. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 24 | IsBuy | int | YES | 1 = Long/Buy (profit when price rises), 0 = Short/Sell. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 25 | Leverage | int | YES | Leverage multiplier (1, 5, 10, etc.). Determines margin and settlement type. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 26 | IsSettled | int | YES | 1 = real asset, 0 = CFD asset. Always 0 in this table (only CFD positions are fee-eligible). Passthrough from Dim_Position. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 27 | ClosedOnWeekend | int | YES | Flag for positions closed on weekends. Always 0 in current output (weekend rows filtered out by SP logic). Hardcoded 0. (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group F: Price Data (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 28 | Bid | numeric(36,12) | YES | Raw bid price before spread adjustment. Mid-price reference. Passthrough from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 29 | Ask | numeric(36,12) | YES | Raw ask (offer) price before spread adjustment. Mid-price reference. Passthrough from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 30 | ConvertRateIsBuy_1 | numeric(18,4) | YES | Pre-computed USD conversion rate for buy-side positions (IsBuy=1). Multiply by instrument price to convert to USD. Passthrough from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 31 | ConvertRateIsBuy_0 | numeric(18,4) | YES | Pre-computed USD conversion rate for sell-side positions (IsBuy=0). Multiply by instrument price to convert to USD. Passthrough from Fact_CurrencyPriceWithSplit. (Tier 2 — SP_Fact_CurrencyPriceWithSplit_DL_To_Synapse) |
| 32 | USD_Price | money | YES | Instrument price converted to USD. ETL-computed: if IsBuy=1 then Bid × ConvertRateIsBuy_1, else Ask × ConvertRateIsBuy_0. Used in Stocks/ETF/Crypto fee formula. (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group G: Position Size and Fee Config (3 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 33 | AmountInUnitsDecimal | decimal(16,6) | YES | Position size in instrument units (e.g., shares, crypto coins). Fractional lots. Passthrough from Dim_Position. (Tier 1 — Trade.PositionTbl) |
| 34 | Admin_Fee_USD | money | YES | Administrative fee amount in USD. Applied per unit/contract/10K-USD-value depending on asset class. Ranges: $0.10 (Index group 3) to $80.00 (Currency group 4). Passthrough from Dealing_Islamic_Admin_Fee_Per_Group. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 35 | Days_Open | int | YES | Weighted number of trading days the position has been open, calculated using exchange-specific day-counting rules (triple-day logic for Wed/Thu/Fri depending on exchange). (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group H: Fee Calculation (5 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 36 | GracePeriod | int | YES | Number of trading days before fee starts. Currently 7 for all groups. Passthrough from Dealing_Islamic_Admin_Fee_Per_Group.grace_period. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 37 | Days_Admin_Fee | int | YES | Days past the grace period: Days_Open - GracePeriod. Negative means position is still in grace period. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 38 | Days_To_Charge | int | YES | Number of fee days to charge on this date. 0 = no charge (in grace period or weekend). 1 = standard charge day. Up to 3 on the designated triple-charge day per exchange type. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 39 | Final_Fee | decimal(16,2) | YES | The actual administrative fee amount charged for this position on this date. Stored as NEGATIVE (fee is a charge). Zero when position is in grace period or on a non-charge day. Formula varies by asset class — see Section 2.1. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 40 | Fee_Type_ID | int | YES | Fee type identifier. Always 1 (hardcoded in INSERT). (Tier 2 — SP_Islamic_Administrative_Fee) |

#### Group I: Metadata (2 columns)

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 41 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at SP execution time. (Tier 2 — SP_Islamic_Administrative_Fee) |
| 42 | CountryID | int | YES | Country of residence. FK to Dictionary.Country. Determines regulatory framework, available instruments, and leverage limits. Default=0. Passthrough from Dim_Customer. (Tier 1 — Customer.CustomerStatic) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Date | SP parameter | @Date | Passthrough |
| DateID | SP parameter | @Date | CAST(CONVERT(VARCHAR(8), @Date, 112) AS INT) |
| PositionID | Dim_Position | PositionID | Passthrough |
| RealCID | Dim_Customer | RealCID | Passthrough |
| GCID | Dim_Customer | GCID | Passthrough |
| UserName | Dim_Customer | UserName | Passthrough |
| OpenDateID | Dim_Position | OpenDateID | Passthrough |
| CloseDateID | Dim_Position | CloseDateID | Passthrough |
| OpenOccurred | Dim_Position | OpenOccurred | Passthrough |
| NewOpenOccurred | Dim_Position | OpenOccurred | CASE on time >= 22:00 → next day |
| CloseOccurred | Dim_Position | CloseOccurred | Passthrough |
| NewCloseOccurred | Dim_Position | CloseOccurred | Passthrough (alias) |
| IsTheDayBefore | Dim_Position | OpenOccurred | CASE WHEN time >= 22:00 THEN 1 ELSE 0 |
| InstrumentTypeID | Dim_Instrument | InstrumentTypeID | Passthrough |
| InstrumentType | Dim_Instrument | InstrumentType | Passthrough |
| InstrumentID | Dim_Position | InstrumentID | Passthrough |
| InstrumentName | Dim_Instrument | Name | Passthrough (alias) |
| InstrumentType_ID_InstrumentGroup | Dealing_Islamic_Instruments_Groups | instrument_type_id | Passthrough |
| InstrumentName_InstrumentGroup | Dealing_Islamic_Instruments_Groups | name | Passthrough |
| InstrumentGroup | Dealing_Islamic_Instruments_Groups | instrument_group | Passthrough |
| Units_per_Contract | Dealing_Islamic_Units_Per_Contract | units_per_contract | Passthrough |
| Exchange | Dim_Instrument | Exchange | Passthrough |
| ExchangeID | Dim_ExchangeInfo | ExchangeID | Passthrough |
| IsBuy | Dim_Position | IsBuy | Passthrough |
| Leverage | Dim_Position | Leverage | Passthrough |
| IsSettled | Dim_Position | IsSettled | Passthrough |
| ClosedOnWeekend | SP hardcoded | — | Hardcoded 0 |
| Bid | Fact_CurrencyPriceWithSplit | Bid | Passthrough |
| Ask | Fact_CurrencyPriceWithSplit | Ask | Passthrough |
| ConvertRateIsBuy_1 | Fact_CurrencyPriceWithSplit | ConvertRateIsBuy_1 | Passthrough |
| ConvertRateIsBuy_0 | Fact_CurrencyPriceWithSplit | ConvertRateIsBuy_0 | Passthrough |
| USD_Price | Fact_CurrencyPriceWithSplit | Bid/Ask × ConvertRate | CASE on IsBuy |
| AmountInUnitsDecimal | Dim_Position | AmountInUnitsDecimal | Passthrough |
| Admin_Fee_USD | Dealing_Islamic_Admin_Fee_Per_Group | admin_fee_usd | Passthrough |
| Days_Open | Dim_Date + exchange logic | — | Weighted SUM by exchange type |
| GracePeriod | Dealing_Islamic_Admin_Fee_Per_Group | grace_period | Passthrough |
| Days_Admin_Fee | Computed | Days_Open - grace_period | Arithmetic |
| Days_To_Charge | Computed | CASE on day-of-week + exchange | CASE logic |
| Final_Fee | Computed | Asset-class formula × Days_To_Charge × (-1) | See Section 2.1 |
| Fee_Type_ID | SP hardcoded | — | Hardcoded 1 |
| UpdateDate | SP | GETDATE() | ETL timestamp |
| CountryID | Dim_Customer | CountryID | Passthrough |

### 5.2 ETL Pipeline

```
DWH_dbo.Dim_Position (open + recently closed positions)
  + DWH_dbo.Dim_Customer (Islamic filter: WeekendFeePrecentage=0)
  + DWH_dbo.Dim_Instrument (instrument type, exchange)
  + Dealing_dbo.Dealing_Islamic_Instruments_Groups (fee group mapping)
  + Dealing_dbo.Dealing_Islamic_Units_Per_Contract (commodity contract sizes)
  + DWH_dbo.Dim_ExchangeInfo (exchange ID lookup)
  + DWH_dbo.Dim_Date (day-counting calendar)
  + DWH_dbo.Fact_CurrencyPriceWithSplit (EOD prices + USD rates)
  + Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group (fee rates)
    |
    |-- SP_Islamic_Administrative_Fee(@Date) --|
    |   #Positions → #Positions_Relevant_Inst  |
    |   → #Positions2 (+ prices + days)        |
    |   → #Final_Table_Step2 (+ fee config)    |
    |   → #Final_Table (+ Final_Fee calc)      |
    |   DELETE WHERE Date=@Date                |
    |   INSERT FROM #Final_Table               |
    v
  Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee (17.9M rows)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| PositionID | DWH_dbo.Dim_Position | Position lifecycle and financial data |
| RealCID | DWH_dbo.Dim_Customer | Customer demographics, regulation, account type |
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument name, type, asset class |
| ExchangeID | DWH_dbo.Dim_ExchangeInfo | Exchange metadata |
| CountryID | DWH_dbo.Dim_Country | Country name and region |
| DateID | DWH_dbo.Dim_Date | Calendar dimension |
| InstrumentGroup + InstrumentTypeID | Dealing_dbo.Dealing_Islamic_Admin_Fee_Per_Group | Fee rate schedule |

### 6.2 Referenced By (other objects point to this)

| Source Object | Description |
|--------------|-------------|
| _No known downstream consumers identified_ | This is a terminal output/reporting table |

---

## 7. Sample Queries

### 7.1 Total daily Islamic fees by asset class

```sql
SELECT
    [Date],
    InstrumentType,
    COUNT(*) AS positions,
    SUM(CASE WHEN Final_Fee <> 0 THEN 1 ELSE 0 END) AS charged_positions,
    SUM(Final_Fee) * -1 AS total_fee_usd
FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee]
WHERE [Date] = '2026-04-25'
GROUP BY [Date], InstrumentType
ORDER BY total_fee_usd DESC;
```

### 7.2 Top Islamic customers by total fees in a month

```sql
SELECT TOP 20
    RealCID,
    UserName,
    COUNT(DISTINCT [Date]) AS days_charged,
    COUNT(DISTINCT InstrumentID) AS instruments,
    SUM(Final_Fee) * -1 AS total_fee_usd
FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee]
WHERE [Date] BETWEEN '2026-04-01' AND '2026-04-30'
  AND Final_Fee <> 0
GROUP BY RealCID, UserName
ORDER BY total_fee_usd DESC;
```

### 7.3 Positions in grace period (no fee yet)

```sql
SELECT
    PositionID,
    RealCID,
    InstrumentName,
    InstrumentType,
    Days_Open,
    GracePeriod,
    Days_Admin_Fee
FROM [Dealing_dbo].[Dealing_Islamic_Daily_Administrative_Fee]
WHERE [Date] = '2026-04-25'
  AND Days_Admin_Fee <= 0
ORDER BY Days_Open DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object. (Phase 10 skipped — Atlassian MCP not available in regen harness.)

---

*Generated: 2026-04-27 | Quality: 8.0/10 (★★★★☆) | Phases: 11/14*
*Tiers: 8 T1, 34 T2, 0 T3, 0 T4, 0 T5 | Elements: 42/42, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: Dealing_dbo.Dealing_Islamic_Daily_Administrative_Fee | Type: Table (Fact) | Production Source: SP_Islamic_Administrative_Fee*
