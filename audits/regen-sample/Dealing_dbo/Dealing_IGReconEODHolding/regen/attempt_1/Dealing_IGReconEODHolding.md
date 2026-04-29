# Dealing_dbo.Dealing_IGReconEODHolding

> ~7,955-row daily EOD holdings reconciliation between IG (liquidity provider) reported positions and eToro's internal hedge/client positions per instrument and account, spanning 2023-10-27 to present with daily weekday refresh via SP_IGRecon.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Production Source** | SP_IGRecon (Gili Goldbaum, 2023-12-28; updated through 2025-10-23 by Adar) |
| **Refresh** | Daily (SB_Daily, Priority 0); skips Saturday; Sunday runs as Friday |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Pending -- resolved during write-objects_ |
| **UC Format** | _Pending -- resolved during write-objects_ |
| **UC Partitioned By** | _Pending -- resolved during write-objects_ |
| **UC Table Type** | _Pending -- resolved during write-objects_ |

---

## 1. Business Meaning

`Dealing_IGReconEODHolding` is the **end-of-day holdings reconciliation** between IG (the liquidity provider) and eToro's internal records, covering both the hedge position (eToro side) and the aggregated client net open position. Each row represents one instrument for a given IG account on a specific date, comparing IG's reported position size and value against eToro's hedge and client positions. Non-zero `IG-eToro_*` or `IG-Clients_*` difference columns flag holdings breaks requiring investigation.

The table is the **EOD holdings companion** to `Dealing_IGReconTrades` (trade activity recon) -- both are written by `SP_IGRecon` in a single execution. The SP performs a **FULL OUTER JOIN** between the IG position file (`LP_IG_PS_EODPositions`) and eToro's internal EOD recon data (`Dealing_Duco_EODRecon`, filtered to IG hedge servers via Fivetran mappings).

As of 2026-04-28, the table contains ~7,955 rows from 2023-10-27 to 2026-04-24. Distribution: ~34% from HS 35 (account EZW6K), ~14% HS 6, ~14% HS 21, ~13% IG-only rows (no eToro match), ~9% HS 225, ~8% HS 111, ~8% HS 8. Currencies: USD 56%, EUR 21%, HKD 8%, AUD 7%, GBP 4%.

**ETL pattern**: DELETE WHERE Date = @TotalDate + INSERT. Saturday is skipped entirely; Sunday is shifted to Friday (−2 days). The SP also loads `LP_IG_PS_EODPositions_daily` from parquet via COPY INTO before processing, to handle dash-character issues in IG files (Adar's SR-338909 fix).

---

## 2. Business Logic

### 2.1 Weekend Date Adjustment

**What**: The reconciliation date is adjusted so that no data is generated on weekends.

**Columns involved**: `Date`

**Rules**:
- If `@Date` is a Saturday (`DayNumberOfWeek_Sun_Start = 7`): the SP skips entirely (`WHERE @Is_Saturday = 0` prevents INSERT)
- If `@Date` is a Sunday (`DayNumberOfWeek_Sun_Start = 1`): `@TotalDate = @Date − 2` (maps to Friday)
- Otherwise: `@TotalDate = @Date`

### 2.2 IG Position Calculation (LP Side)

**What**: IG's reported holdings are extracted from the EOD position file with instrument-specific adjustments.

**Columns involved**: `IG_Units`, `IG_LocalAmount`, `IG_AmountUSD`, `IG_Rate`, `IG_FXRate`

**Rules**:
- `IG_Units`: `SUM((2*IsBuy−1) × ABS(Position))` -- sign-adjusted by direction (positive=long, negative=short)
- **Oil multiplier**: `Market Name = 'Oil - US Crude ($1)'` gets ×100 on units and local amount
- `IG_Rate`: `TRY_CONVERT(DECIMAL(16,6), Latest)` -- MAX grouped per instrument+account
- `IG_FXRate`: From `LP_IG_PS_EODPositions.[Conversion Rate]`, parsed as float (trailing character stripped); USD hardcoded to 1
- `IG_AmountUSD`: `[Consideration (Base Ccy)]` with sign adjustment, SUM grouped
- `IG_LocalAmount`: `[Current Value]` with oil ×100 multiplier, SUM grouped
- Instrument resolution: via `Dim_Instrument.ISINCode` first, fallback to hardcoded `#MarketNameToID` temp table

### 2.3 eToro Position (Hedge + Client Side)

**What**: eToro's internal positions are sourced from `Dealing_Duco_EODRecon`, filtered to IG liquidity accounts via Fivetran mappings.

**Columns involved**: `eToro_Units`, `eToro_LocalAmount`, `eToro_AmountUSD`, `eToro_Rate`, `eToro_FXRate`, `Clients_Units`, `Clients_AmountUSD`

**Rules**:
- Filtered to IG hedge servers: JOIN to `#Fivetran` on `HedgeServerID + LiquidityAccountID` where `liquidity_provider = 'IG'`
- **GBX normalization**: When `SellCurrency = 'GBX'`, local amount and rate are divided by 100, and CurrencyPrimary is set to `'GBP'`
- Values are SUM/MAX grouped by Date + HedgeServerID + InstrumentID + AccountID

### 2.4 Reconciliation Diff Columns

**What**: Arithmetic differences between IG and eToro/client sides surface holdings breaks.

**Columns involved**: `IG-eToro_Units`, `IG-Clients_Units`, `IG-eToro_LocalAmount`, `IG-eToro_AmountUSD`, `IG-Clients_AmountUSD`, `IG-eToro_Rate`

**Rules**:
- Formula: `ISNULL(IG_value, 0) − ISNULL(eToro_or_Client_value, 0)`
- Non-zero value = reconciliation break requiring investigation
- Zero on both sides (IG_Units = 0, eToro_Units = 0) is possible when a row exists only because of a client position (Clients_Units ≠ 0)

### 2.5 FULL OUTER JOIN Semantics

**What**: The final result is a FULL OUTER JOIN between IG and eToro sides, so rows may have NULL on either side.

**Columns involved**: `HedgeServerID`, `Account_Number`, all IG_* and eToro_* columns

**Rules**:
- `HedgeServerID IS NULL` + `Account_Number IS NOT NULL`: IG-only position (no eToro match) -- ~997 rows
- `Account_Number IS NULL` + `HedgeServerID IS NOT NULL`: eToro-only position (no IG match) -- ~2,726 rows
- Both populated: matched position for reconciliation comparison

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, ROUND_ROBIN distributed with CLUSTERED INDEX on `Date ASC`. Always filter on `Date` first for efficient range scans. At ~8K rows total, full scans are not expensive.

### 3.1b UC (Databricks) Storage & Partitioning

UC target not yet resolved. At ~8K rows, no partitioning needed.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Holdings breaks for a date | `WHERE Date = @d AND ([IG-eToro_Units] <> 0 OR [IG-eToro_AmountUSD] <> 0)` |
| IG-only positions (no eToro match) | `WHERE HedgeServerID IS NULL AND Account_Number IS NOT NULL` |
| eToro-only positions (no IG match) | `WHERE Account_Number IS NULL AND HedgeServerID IS NOT NULL` |
| Largest USD breaks | `ORDER BY ABS([IG-eToro_AmountUSD]) DESC` |
| Rate discrepancies | `WHERE ABS([IG-eToro_Rate]) > 0.01` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| DWH_dbo.Dim_Instrument | InstrumentID | Instrument metadata (type, sector, tradability) |
| Dealing_IGReconTrades | Date + InstrumentID | Pair EOD holdings recon with trade activity recon |
| Dealing_Duco_EODRecon | Date + HedgeServerID + InstrumentID | Trace eToro-side source data |

### 3.4 Gotchas

- **FULL OUTER JOIN NULLs**: `HedgeServerID` is NULL for IG-only rows; `Account_Number` is NULL for eToro-only rows. Always use ISNULL() when aggregating.
- **Exchange = '0'**: IG-only rows have `Exchange = '0'` (from `ISNULL(tse.Exchange, 0)`) -- this is not a real exchange name.
- **Oil multiplier**: IG units and local amounts for `Oil - US Crude ($1)` are multiplied by 100 to normalize contract sizes.
- **GBX normalization**: GBP-pence instruments have rates and local amounts divided by 100 on the eToro side; CurrencyPrimary shows 'GBP' not 'GBX'.
- **Weekend gaps**: No data for Saturday; Sunday data appears under the preceding Friday's date.
- **InstrumentID NULL**: ~997 rows have NULL InstrumentID -- these are IG-only positions where the market name could not be resolved via ISIN or the hardcoded mapping table.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★ | Tier 2 -- SP code | `(Tier 2 -- SP_IGRecon)` |
| ★★ | Tier 3 -- live data / DDL | `(Tier 3 -- DDL/live)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | YES | Reconciliation date (EOD holdings comparison date). Saturday is skipped; Sunday is shifted to the preceding Friday via Dim_Date.DayNumberOfWeek_Sun_Start. (Tier 2 -- SP_IGRecon) |
| 2 | HedgeServerID | int | YES | eToro hedge server identifier for the IG LP. Resolved via Fivetran mapping (`liquidity_provider='IG'`). NULL for IG-only rows where no eToro match exists. Distinct values: 35, 6, 21, 225, 111, 8, 24. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.HedgeServerID) |
| 3 | Account_Number | varchar(50) | YES | IG account number from `LP_IG_PS_EODPositions.[Account ID]`. NULL for eToro-only rows where no IG position exists. Distinct values: EZW6K, RE702, EZL3N, EYZBP, EZW6O. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.[Account ID]) |
| 4 | InstrumentID | int | YES | eToro instrument identifier. On the eToro side: passthrough from Dealing_Duco_EODRecon. On the IG side: resolved via Dim_Instrument.ISINCode or hardcoded #MarketNameToID mapping. NULL when IG market name cannot be resolved. FK to DWH_dbo.Dim_Instrument. (Tier 2 -- SP_IGRecon) |
| 5 | InstrumentDisplayName | varchar(100) | YES | Instrument display name. ISNULL(eToro_side, IG_side) -- prefers eToro's name from Dealing_Duco_EODRecon, falls back to IG-resolved name from Dim_Instrument. (Tier 2 -- SP_IGRecon) |
| 6 | Symbol | varchar(250) | YES | Instrument ticker symbol from the eToro side (Dealing_Duco_EODRecon.Symbol). NULL for IG-only rows. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.Symbol) |
| 7 | ISINCode | varchar(30) | YES | International Securities Identification Number. ISNULL(eToro_side, IG_side) -- prefers Dealing_Duco_EODRecon.ISINCode, falls back to LP_IG_PS_EODPositions.ISIN. (Tier 2 -- SP_IGRecon) |
| 8 | CurrencyPrimary | varchar(50) | YES | Instrument local currency. On the eToro side: GBX is normalized to GBP (`CASE WHEN SellCurrency='GBX' THEN 'GBP'`). On the IG side: Ccy passthrough. ISNULL(eToro, IG). Distinct values: USD (56%), EUR (21%), HKD (8%), AUD (7%), GBP, CHF, MXN, NZD. (Tier 2 -- SP_IGRecon) |
| 9 | Exchange | varchar(80) | YES | Trading venue from the eToro side (Dealing_Duco_EODRecon.Exchange). Defaults to '0' for IG-only rows (ISNULL fallback). Distinct values: CFD (51%), Commodity (28%), 0 (13%), NYSE, LSE, Nasdaq, SIX, FX. (Tier 2 -- SP_IGRecon) |
| 10 | IG_Units | decimal(16,6) | YES | IG's reported EOD position size in units. Computed as `SUM((2*IsBuy−1) × ABS(Position))` from `LP_IG_PS_EODPositions`. Oil instruments (US Crude) are multiplied by 100. ISNULL defaults to 0 for eToro-only rows. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.Position) |
| 11 | eToro_Units | decimal(16,6) | YES | eToro's hedge position units from Dealing_Duco_EODRecon.eToro_Units. SUM grouped by instrument+account. ISNULL defaults to 0 for IG-only rows. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToro_Units) |
| 12 | Clients_Units | decimal(16,6) | YES | Aggregated client NOP units from Dealing_Duco_EODRecon.ClientUnits. SUM grouped by instrument+account. ISNULL defaults to 0 for IG-only rows. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.ClientUnits) |
| 13 | IG-eToro_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(eToro_Units,0)`. Non-zero indicates a holdings break between IG and eToro hedge positions. (Tier 2 -- SP_IGRecon, computed) |
| 14 | IG-Clients_Units | decimal(16,6) | YES | **Recon diff**: `ISNULL(IG_Units,0) − ISNULL(Clients_Units,0)`. Non-zero indicates a break between IG holdings and client NOP. (Tier 2 -- SP_IGRecon, computed) |
| 15 | IG_LocalAmount | money | YES | IG's EOD position value in the instrument's local currency. Computed from `LP_IG_PS_EODPositions.[Current Value]` with TRY_CONVERT; Oil ×100 multiplier applied. SUM grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.[Current Value]) |
| 16 | eToro_LocalAmount | money | YES | eToro's hedge position value in local currency from Dealing_Duco_EODRecon.eToroLocalAmount. GBX instruments divided by 100 for GBP normalization. SUM grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToroLocalAmount) |
| 17 | IG-eToro_LocalAmount | money | YES | **Recon diff**: `ISNULL(IG_LocalAmount,0) − ISNULL(eToro_LocalAmount,0)`. Local currency holdings break. (Tier 2 -- SP_IGRecon, computed) |
| 18 | IG_AmountUSD | money | YES | IG's EOD position value in USD. From `LP_IG_PS_EODPositions.[Consideration (Base Ccy)]` with sign adjustment via (2*IsBuy−1). SUM grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.[Consideration (Base Ccy)]) |
| 19 | eToro_AmountUSD | money | YES | eToro's hedge position value in USD from Dealing_Duco_EODRecon.eToroUSDAmount. SUM grouped by instrument+account. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToroUSDAmount) |
| 20 | Clients_AmountUSD | money | YES | Aggregated client NOP value in USD from Dealing_Duco_EODRecon.ClientAmount. SUM grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.ClientAmount) |
| 21 | IG-eToro_AmountUSD | money | YES | **Recon diff**: `ISNULL(IG_AmountUSD,0) − ISNULL(eToro_AmountUSD,0)`. USD holdings break between IG and eToro. (Tier 2 -- SP_IGRecon, computed) |
| 22 | IG-Clients_AmountUSD | money | YES | **Recon diff**: `ISNULL(IG_AmountUSD,0) − ISNULL(Clients_AmountUSD,0)`. USD break between IG and client NOP. (Tier 2 -- SP_IGRecon, computed) |
| 23 | IG_Rate | decimal(16,6) | YES | IG's EOD position price (latest market price). `TRY_CONVERT(DECIMAL(16,6), Latest)` from `LP_IG_PS_EODPositions`. MAX grouped per instrument+account. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.Latest) |
| 24 | eToro_Rate | decimal(16,6) | YES | eToro's holding rate from Dealing_Duco_EODRecon.eToroRate. GBX instruments divided by 100 for GBP normalization. MAX grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.eToroRate) |
| 25 | IG-eToro_Rate | decimal(16,6) | YES | **Rate diff**: `ISNULL(IG_Rate,0) − ISNULL(eToro_Rate,0)`. Non-zero indicates a pricing discrepancy between IG and eToro. (Tier 2 -- SP_IGRecon, computed) |
| 26 | IG_FXRate | decimal(16,6) | YES | IG's FX rate for local-to-USD conversion. From `LP_IG_PS_EODPositions.[Conversion Rate]` (trailing character stripped, parsed as float). USD hardcoded to 1. MAX grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, LP_IG_PS_EODPositions.[Conversion Rate]) |
| 27 | eToro_FXRate | decimal(16,6) | YES | eToro's FX rate for local-to-USD conversion from Dealing_Duco_EODRecon.FXratetoUSD (ultimately from DWH_dbo.Fact_CurrencyPriceWithSplit). MAX grouped. ISNULL defaults to 0. (Tier 2 -- SP_IGRecon, Dealing_Duco_EODRecon.FXratetoUSD) |
| 28 | UpdateDate | datetime | YES | ETL batch timestamp set to GETDATE() at INSERT time. Does not reflect production modification time. (Tier 3 -- SP_IGRecon, GETDATE()) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---|---|---|---|
| Date | SP_IGRecon @Date | -- | Sunday→Friday−2; Saturday skipped |
| HedgeServerID | Dealing_Duco_EODRecon | HedgeServerID | Passthrough (eToro side) |
| Account_Number | LP_IG_PS_EODPositions | [Account ID] | Passthrough (IG side) |
| InstrumentID | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | InstrumentID / ISIN | eToro passthrough; IG resolved via ISIN or #MarketNameToID |
| InstrumentDisplayName | Dealing_Duco_EODRecon / Dim_Instrument | InstrumentDisplayName | ISNULL(eToro, IG) |
| Symbol | Dealing_Duco_EODRecon | Symbol | Passthrough |
| ISINCode | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | ISINCode / ISIN | ISNULL(eToro, IG) |
| CurrencyPrimary | Dealing_Duco_EODRecon / LP_IG_PS_EODPositions | SellCurrency / Ccy | GBX→GBP normalization (eToro side) |
| Exchange | Dealing_Duco_EODRecon | Exchange | ISNULL(eToro_side, 0) |
| IG_Units | LP_IG_PS_EODPositions | Position | SUM((2*IsBuy−1)×ABS); Oil ×100 |
| eToro_Units | Dealing_Duco_EODRecon | eToro_Units | SUM grouped |
| Clients_Units | Dealing_Duco_EODRecon | ClientUnits | SUM grouped |
| IG-eToro_Units | Computed | -- | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG-Clients_Units | Computed | -- | ISNULL(IG,0)−ISNULL(Clients,0) |
| IG_LocalAmount | LP_IG_PS_EODPositions | [Current Value] | TRY_CONVERT; Oil ×100; SUM |
| eToro_LocalAmount | Dealing_Duco_EODRecon | eToroLocalAmount | GBX÷100; SUM |
| IG-eToro_LocalAmount | Computed | -- | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG_AmountUSD | LP_IG_PS_EODPositions | [Consideration (Base Ccy)] | Sign-adjusted SUM |
| eToro_AmountUSD | Dealing_Duco_EODRecon | eToroUSDAmount | SUM grouped |
| Clients_AmountUSD | Dealing_Duco_EODRecon | ClientAmount | SUM grouped |
| IG-eToro_AmountUSD | Computed | -- | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG-Clients_AmountUSD | Computed | -- | ISNULL(IG,0)−ISNULL(Clients,0) |
| IG_Rate | LP_IG_PS_EODPositions | Latest | TRY_CONVERT; MAX grouped |
| eToro_Rate | Dealing_Duco_EODRecon | eToroRate | GBX÷100; MAX |
| IG-eToro_Rate | Computed | -- | ISNULL(IG,0)−ISNULL(eToro,0) |
| IG_FXRate | LP_IG_PS_EODPositions | [Conversion Rate] | Parse float; USD=1; MAX |
| eToro_FXRate | Dealing_Duco_EODRecon | FXratetoUSD | MAX grouped |
| UpdateDate | SP_IGRecon | GETDATE() | ETL timestamp |

### 5.2 ETL Pipeline

```
LP IG Files (EOD Positions Parquet, Azure Data Lake)
  → COPY INTO Dealing_staging.LP_IG_PS_EODPositions_daily
  → INSERT INTO Dealing_staging.LP_IG_PS_EODPositions (with dash-char fix)
  +
Dealing_staging.External_Fivetran_dealing_active_hs_mappings (liquidity_provider='IG')
  → #Fivetran (latest mapping by update_date)
  +
DWH_dbo.Dim_Instrument (ISIN/name resolution)
  → #MarketNameToID (hardcoded fallback for indices/commodities/forex)
  → #Ins (distinct MarketName→InstrumentID)
  +
Dealing_dbo.Dealing_Duco_EODRecon (eToro hedge + client NOP)
  → #eToroSide_EOD (filtered to IG HS via #Fivetran, GBX normalized)
  → #eToroSide_EOD_Final (SUM/MAX grouped)
  +
LP_IG_PS_EODPositions (IG positions)
  → #IG_EOD (position with sign convention, oil multiplier)
  → #IG_EOD_Final (SUM/MAX grouped by account+instrument)
  +
  → #EOD_Final (FULL OUTER JOIN on InstrumentID + AccountID)
  → SP_IGRecon (DELETE WHERE Date=@TotalDate + INSERT, daily)
  → Dealing_dbo.Dealing_IGReconEODHolding (~8K rows)
```

---

## 6. Relationships

### 6.1 References To

| Element | Related Object | Description |
|---------|---------------|-------------|
| InstrumentID | DWH_dbo.Dim_Instrument | Instrument metadata |
| HedgeServerID | Dealing_Duco_EODRecon | eToro-side EOD holdings source |
| eToro_* columns | Dealing_Duco_EODRecon | eToro hedge and client position data |
| IG_* columns | Dealing_staging.LP_IG_PS_EODPositions | IG LP position file |

### 6.2 Referenced By

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| Dealing_IGReconTrades | Same SP (SP_IGRecon) | Trade activity companion -- same writer SP |

---

## 7. Sample Queries

### 7.1 Holdings breaks on latest date
```sql
SELECT Date, InstrumentID, InstrumentDisplayName, Account_Number,
  IG_Units, eToro_Units, [IG-eToro_Units], [IG-eToro_AmountUSD]
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconEODHolding)
  AND (ABS([IG-eToro_Units]) > 0 OR ABS([IG-eToro_AmountUSD]) > 0)
ORDER BY ABS([IG-eToro_AmountUSD]) DESC
```

### 7.2 IG-only positions (unmatched on eToro side)
```sql
SELECT Date, Account_Number, InstrumentDisplayName, IG_Units, IG_AmountUSD
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE HedgeServerID IS NULL
  AND Date >= DATEADD(DAY, -7, GETDATE())
ORDER BY Date DESC, ABS(IG_AmountUSD) DESC
```

### 7.3 Rate discrepancy analysis
```sql
SELECT Date, InstrumentID, InstrumentDisplayName,
  IG_Rate, eToro_Rate, [IG-eToro_Rate],
  IG_FXRate, eToro_FXRate
FROM Dealing_dbo.Dealing_IGReconEODHolding
WHERE Date = (SELECT MAX(Date) FROM Dealing_dbo.Dealing_IGReconEODHolding)
  AND ABS([IG-eToro_Rate]) > 0.01
ORDER BY ABS([IG-eToro_Rate]) DESC
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found for this object (Phase 10 not available in regen harness mode).

---

*Generated: 2026-04-28 | Quality: 8.0/10 | Phases: P1 P2 P3 P5 P8 P9 P11*
*Tiers: 0 T1, 27 T2, 1 T3, 0 T4, 0 T5 | Elements: 28/28, Logic: 8/10*
*Object: Dealing_dbo.Dealing_IGReconEODHolding | Type: Table | Production Source: SP_IGRecon*
