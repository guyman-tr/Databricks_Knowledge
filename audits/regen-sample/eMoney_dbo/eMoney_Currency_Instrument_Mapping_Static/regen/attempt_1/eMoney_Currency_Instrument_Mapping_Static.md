# eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static

> 145-row static reference table mapping 21 fiat currencies to 90 FX instrument pairs, used across the eMoney pipeline for currency-to-USD conversion rate lookups via Fact_CurrencyPriceWithSplit. Loaded once on 2022-11-21 with no subsequent refreshes. No writer SP identified; table appears manually maintained.

| Property | Value |
|----------|-------|
| **Schema** | eMoney_dbo |
| **Object Type** | Table |
| **Production Source** | Unknown (static / manual load — no writer SP) |
| **Refresh** | None observed; single bulk load on 2022-11-21 |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | _Not_Migrated (no Generic Pipeline mapping found) |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |

---

## 1. Business Meaning

`eMoney_Currency_Instrument_Mapping_Static` is a hand-maintained reference table that maps each supported eMoney fiat currency to every FX instrument pair in which that currency participates. It contains 145 rows spanning 21 distinct currencies (AUD, CAD, CHF, CZK, DKK, EUR, GBP, HKD, HUF, JPY, MXN, NOK, NZD, PLN, RUB, SAR, SEK, SGD, TRY, USD, ZAR) and 90 distinct instrument IDs.

The table's primary purpose is to enable USD-approximate balance and amount calculations across the eMoney pipeline. Consumer SPs (SP_eMoney_Dim_Account, SP_eMoney_Snapshot_Settled_Balance, SP_eMoney_Calculated_Balance, SP_DDR_Fact_MIMO_eMoney_Platform) join to this table on `CurrencyISO` with a filter of `SellCurrencyID = 1` (or `BuyCurrencyID = 1`) to find the specific FX instrument that converts a given currency to USD. The resolved `InstrumentID` is then used to look up the daily Ask/Bid rate from `DWH_dbo.Fact_CurrencyPriceWithSplit`.

Each currency has multiple rows — one per FX pair it participates in (e.g., AUD appears in AUD/USD, EUR/AUD, AUD/JPY, etc.). The `SellCurrencyID = 1` filter isolates the single row per currency where USD is on the quote side, which is the conversion instrument.

No writer SP was found. All 145 rows share the same `UpdateDate` of 2022-11-21 14:12:06, indicating a single bulk load. The table also includes some synthetic/conversion instruments (e.g., `EURUSD_conversion/USD`, `USDHKD_conversion/HKD`) and eToro-specific tokens (`ETORIAN/USD` series, IDs 600–610).

---

## 2. Business Logic

### 2.1 Currency-to-USD Instrument Resolution

**What**: The canonical usage pattern filters this table to find the single FX instrument that converts a currency to USD.
**Columns Involved**: CurrencyISO, SellCurrencyID, InstrumentID, BuyCurrencyID
**Rules**:
- Filter `SellCurrencyID = 1` to find pairs where USD is the quote currency (e.g., EUR/USD, GBP/USD)
- For currencies where USD is the base (e.g., USD/JPY), the same row appears with `BuyCurrencyID = 1`
- The resolved `InstrumentID` is joined to `Fact_CurrencyPriceWithSplit` for Ask/Bid rates
- SP_DDR_Fact_MIMO_eMoney_Platform uses an alternate filter: `BuyCurrencyID = 1` to get `SellCurrencyID` as `CurrencyID`

### 2.2 Multi-Row-Per-Currency Design

**What**: Each currency has multiple rows — one for every FX pair it participates in, not just the USD pair.
**Columns Involved**: Currency, InstrumentID, BuyCurrency, SellCurrency
**Rules**:
- AUD has 9 rows (AUD/USD, EUR/AUD, AUD/JPY, AUD/CHF, AUD/CAD, AUD/NZD, GBP/AUD, AUD/GBP, AUD/EUR)
- USD has the most rows (~40+) since it participates in most pairs
- CZK has only 1 row (USD/CZK)
- Consumers MUST filter by `SellCurrencyID = 1` or `BuyCurrencyID = 1` to get a single row per currency

### 2.3 Synthetic and Conversion Instruments

**What**: The table includes non-standard instrument entries for specific use cases.
**Columns Involved**: InstrumentID, InstrumentName, BuyCurrency
**Rules**:
- Conversion instruments: `EURUSD_conversion/USD` (ID 350), `GBPUSD_conversion/USD` (ID 351), `USDHKD_conversion/HKD` (ID 352), `USDSAR/SAR` (ID 348)
- eToro token instruments: `ETORIAN/USD` (ID 600) through `ETORIAN610/USD` (ID 610), `GBX/USD` (ID 666)
- Regional currency proxies: `CLPUSD/USD` (ID 86), `COPUSD/USD` (ID 87), `PENUSD/USD` (ID 88), `ARSUSD/USD` (ID 89), `QARUSD/USD` (ID 90)

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP index. With only 145 rows the table is fully replicated across all distributions in practice. No performance concerns for any query pattern.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|------------------|---------------------|
| Which instrument converts EUR to USD? | `SELECT InstrumentID, InstrumentName FROM eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static WHERE CurrencyISO = 978 AND SellCurrencyID = 1` |
| List all FX pairs for a currency | `SELECT * FROM eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static WHERE Currency = 'AUD'` |
| How many currencies are supported? | `SELECT COUNT(DISTINCT Currency) FROM eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| eMoney_dbo.eMoney_Account_Mappings | `CurrencyBalanceISON = CurrencyISO AND SellCurrencyID = 1` | Resolve currency balance ISO to currency description |
| DWH_dbo.Fact_CurrencyPriceWithSplit | `InstrumentID = InstrumentID AND OccurredDateID = @DateID` | Look up daily FX rate (Ask/Bid) for USD conversion |
| eMoney_dbo.eMoney_Dim_Account | `CurrencyBalanceISOCode = CurrencyISO AND SellCurrencyID = 1` | USD approximate balance calculation |
| eMoney_dbo.eMoney_Fact_Transaction_Status | `HolderCurrencyISO = CurrencyISO` (via subquery with `BuyCurrencyID = 1`) | MIMO deposit/withdraw currency resolution |

### 3.4 Gotchas

- **Always filter by `SellCurrencyID = 1` or `BuyCurrencyID = 1`**: Without this filter, a JOIN will fan out to multiple rows per currency (up to 40+ for USD), inflating results.
- **DWHInstrumentID = InstrumentID**: In current data these columns are identical. Do not assume they will diverge in the future — always use the column specified in the join target's DDL.
- **Static table — no refresh**: All rows have UpdateDate = 2022-11-21. New currencies or instruments added to the platform after this date will NOT appear here. Verify coverage before relying on completeness.
- **Synthetic instruments**: IDs 600+ are eToro-specific tokens (ETORIAN series). IDs 86–90 are Latin American/Middle Eastern currency proxies. These may not have valid rates in Fact_CurrencyPriceWithSplit.

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verbatim from upstream wiki |
| Tier 2 | Derived from SP code |
| Tier 3 | Grounded in DDL + live data evidence, no upstream wiki or writer SP |
| Tier 4 | Inferred from name only |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Currency | varchar(50) | NO | ISO 4217 three-letter currency code (e.g., USD, EUR, GBP, AUD). Each currency appears in multiple rows — one per FX instrument pair it participates in. 21 distinct values in current data. (Tier 3 — DDL + live data) |
| 2 | CurrencyISO | int | NO | ISO 4217 numeric currency code (e.g., 840=USD, 978=EUR, 826=GBP, 392=JPY). Primary join key used by consumer SPs to match against eMoney_Account_Mappings.CurrencyBalanceISON and eMoney_Fact_Transaction_Status.HolderCurrencyISO. (Tier 3 — DDL + live data) |
| 3 | InstrumentID | int | NO | Internal FX instrument identifier for the currency pair. Joined to DWH_dbo.Fact_CurrencyPriceWithSplit.InstrumentID to retrieve daily Ask/Bid rates for USD conversion. Range: 1 (EUR/USD) to 666 (GBX/USD). (Tier 3 — DDL + live data) |
| 4 | InstrumentName | varchar(50) | NO | Human-readable FX pair name in BASE/QUOTE format (e.g., EUR/USD, GBP/JPY, AUD/CHF). Includes conversion pseudo-instruments (e.g., EURUSD_conversion/USD) and eToro tokens (e.g., ETORIAN/USD). (Tier 3 — DDL + live data) |
| 5 | DWHInstrumentID | int | NO | DWH-level instrument identifier. In all 145 current rows, this value is identical to InstrumentID. May serve as an abstraction layer for potential future divergence between source and DWH instrument numbering. (Tier 3 — DDL + live data) |
| 6 | BuyCurrencyID | int | NO | Internal currency ID for the base (buy) side of the FX pair. Used as a filter — `BuyCurrencyID = 1` selects pairs where USD is the base currency (e.g., USD/JPY, USD/CAD). SP_DDR_Fact_MIMO_eMoney_Platform uses this filter to resolve SellCurrencyID as the deposit/withdraw CurrencyID. (Tier 3 — DDL + live data) |
| 7 | SellCurrencyID | int | NO | Internal currency ID for the quote (sell) side of the FX pair. Canonical filter: `SellCurrencyID = 1` selects the instrument where USD is the quote currency (e.g., EUR/USD, GBP/USD), yielding one row per currency for USD conversion. Used by SP_eMoney_Dim_Account, SP_eMoney_Snapshot_Settled_Balance, and SP_eMoney_Calculated_Balance. (Tier 3 — DDL + live data) |
| 8 | BuyCurrency | varchar(50) | NO | Three-letter code for the base (buy) currency of the FX pair (e.g., EUR in EUR/USD, AUD in AUD/JPY). Includes synthetic codes for conversion instruments (e.g., EURUSD_conversion, CLPUSD) and eToro tokens (e.g., ETORIAN, GBX). (Tier 3 — DDL + live data) |
| 9 | SellCurrency | varchar(50) | NO | Three-letter code for the quote (sell) currency of the FX pair (e.g., USD in EUR/USD, JPY in AUD/JPY). When filtering for USD conversion, this value is USD. Includes non-standard codes for regional proxy currencies (e.g., USDMYR, USDTHB). (Tier 3 — DDL + live data) |
| 10 | UpdateDate | datetime | NO | Timestamp of the last insert or refresh for this row. All 145 rows show 2022-11-21 14:12:06.137, indicating a single bulk load with no subsequent updates. No writer SP refreshes this table. (Tier 3 — DDL + live data) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|-------------------|---------------|-----------|
| Currency | Unknown (static load) | — | None |
| CurrencyISO | Unknown (static load) | — | None |
| InstrumentID | Unknown (static load) | — | None |
| InstrumentName | Unknown (static load) | — | None |
| DWHInstrumentID | Unknown (static load) | — | None |
| BuyCurrencyID | Unknown (static load) | — | None |
| SellCurrencyID | Unknown (static load) | — | None |
| BuyCurrency | Unknown (static load) | — | None |
| SellCurrency | Unknown (static load) | — | None |
| UpdateDate | Unknown (static load) | — | None |

### 5.2 ETL Pipeline

```
Unknown production source (likely manual / one-time script)
  |-- Single bulk INSERT (2022-11-21 14:12:06) ---|
  v
eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static (145 rows, static)
  |
  |-- READ by SP_eMoney_Dim_Account ------> eMoney_dbo.eMoney_Dim_Account
  |-- READ by SP_eMoney_Snapshot_Settled_Balance -> eMoney_dbo.eMoney_Snapshot_Settled_Balance
  |-- READ by SP_eMoney_Calculated_Balance ------> eMoney_dbo.eMoney_Calculated_Balance
  |-- READ by SP_DDR_Fact_MIMO_eMoney_Platform --> BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform
```

No UC Gold target identified. Table is not in the Generic Pipeline mapping.

---

## 6. Relationships

### 6.1 References To (this object points to)

No foreign key references to other tables. This is a self-contained static mapping.

### 6.2 Referenced By (other objects point to this)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CurrencyISO, SellCurrencyID | eMoney_dbo.eMoney_Dim_Account (via SP_eMoney_Dim_Account) | Resolves CurrencyBalanceISON to Currency description |
| CurrencyISO, SellCurrencyID, InstrumentID | eMoney_dbo.eMoney_Snapshot_Settled_Balance (via SP_eMoney_Snapshot_Settled_Balance) | Resolves currency to InstrumentID for Fact_CurrencyPriceWithSplit rate lookup |
| CurrencyISO, SellCurrencyID, InstrumentID | eMoney_dbo.eMoney_Calculated_Balance (via SP_eMoney_Calculated_Balance) | Resolves currency to InstrumentID for daily balance USD approximation |
| CurrencyISO, BuyCurrencyID, SellCurrencyID, Currency | BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform (via SP_DDR_Fact_MIMO_eMoney_Platform) | Resolves HolderCurrencyISO to SellCurrencyID for deposit/withdraw CurrencyID |

---

## 7. Sample Queries

### 7.1 Find the USD Conversion Instrument for a Currency

```sql
-- Get the FX instrument that converts EUR to USD
SELECT InstrumentID, InstrumentName
FROM eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static
WHERE CurrencyISO = 978
  AND SellCurrencyID = 1;
-- Returns: InstrumentID=1, InstrumentName=EUR/USD
```

### 7.2 List All Supported Currencies with Their USD Instruments

```sql
-- One row per supported currency with its USD conversion instrument
SELECT Currency, CurrencyISO, InstrumentID, InstrumentName
FROM eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static
WHERE SellCurrencyID = 1
ORDER BY Currency;
```

### 7.3 USD Approximate Balance Calculation Pattern (as used by consumer SPs)

```sql
-- Replicate the USD balance approximation pattern from SP_eMoney_Calculated_Balance
SELECT mda.AccountID,
       mda.CurrencyBalanceISODesc AS Currency,
       bal.HolderBalance,
       ROUND(bal.HolderBalance * ((fcp.[Ask] + fcp.[Bid]) / 2), 2) AS USDApproxBalance
FROM eMoney_dbo.eMoney_Dim_Account mda
JOIN eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static cmp
  ON mda.CurrencyBalanceISOCode = cmp.CurrencyISO AND cmp.SellCurrencyID = 1
LEFT JOIN DWH_dbo.Fact_CurrencyPriceWithSplit fcp
  ON cmp.InstrumentID = fcp.InstrumentID AND fcp.OccurredDateID = 20260426;
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found for this object.

---

*Generated: 2026-04-27 | Quality: 7.5/10 | Phases: 13/14*
*Tiers: 0 T1, 0 T2, 10 T3, 0 T4, 0 T5 | Elements: 10/10, Logic: 7/10, Lineage: 5/10*
*Object: eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static | Type: Table | Production Source: Unknown (static / manual load)*
