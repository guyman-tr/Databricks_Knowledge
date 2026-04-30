# BI_DB_dbo.BI_DB_QSR_Balance_New

> ~130M-row quarterly customer balance snapshot for the CySEC Quarterly Statistics Report (QSR), containing end-of-period liabilities, realized/unrealized PnL, and sustainability-stamped equity breakdowns per customer — duplicated in USD and EUR for regulatory submission. Loaded by SP_Q_QSR_New, spanning Q1 2020 to Q4 2023 (last refresh 2024-01-30).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source aggregate via SP_Q_QSR_New (V_Liabilities, Fact_SnapshotCustomer, Fact_CustomerUnrealized_PnL, Dim_Position, BI_DB_PositionPnL, BI_DB_ECB_RateExtractFromAPI) |
| **Refresh** | On-demand quarterly via SP_Q_QSR_New @sdate (DELETE+INSERT per quarter) |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Quarter ASC) |
| | |
| **UC Target** | _Not_Migrated |
| **UC Format** | N/A |
| **UC Partitioned By** | N/A |
| **UC Table Type** | N/A — not in Generic Pipeline mapping |

---

## 1. Business Meaning

`BI_DB_QSR_Balance_New` is the balance component of the Quarterly Statistics Report (QSR), a regulatory submission to CySEC and other financial authorities. The report captures every customer's end-of-quarter financial position: total liabilities (what eToro owes the customer), realized PnL from closed positions during the quarter, unrealized PnL from open positions, and asset-class breakdowns separating CFD, real crypto, real stocks (sustainable vs non-sustainable), and stock margin positions.

The SP author (Guy Manova, 2020-07-22) notes the report is "extremely sensitive" compared to the Client Balance (CB) report. All rows are duplicated: once in USD (original amounts) and once in EUR (divided by the ECB EUR/USD exchange rate at quarter-end), enabling easy toggling in Tableau since CySEC requires EUR submission but internal checks use USD.

Key design decisions documented in the SP:
- **Sustainability ratio**: Rather than computing sustainable/non-sustainable equity directly from BI_DB_PositionPnL, the SP applies a proportional ratio (EquityInSustainables / TotalEquity) to V_Liabilities totals, ensuring alignment with the CB report.
- **Snapshot date**: Customer attributes (regulation, MiFID tier, player status) are taken from Fact_SnapshotCustomer as of the quarter-end date, not the position open/close date.
- **Known bug**: `RealizedCFDWithBugPre2021Q2` subtracts stocks twice due to a copy-paste error preserved for backward compatibility.

As of Q4 2023 (latest data): 5.45M distinct customers per currency, 12 regulations, 9 player statuses. The table has not been refreshed since 2024-01-30.

---

## 2. Business Logic

### 2.1 Dual-Currency Duplication

**What**: Every customer row is written twice — once in USD, once in EUR — for regulatory reporting flexibility.

**Columns Involved**: `ReportCurrency`, `Rate`, all monetary columns

**Rules**:
- USD rows: all monetary values in original USD
- EURO rows: all monetary values divided by the ECB EUR/USD exchange rate at quarter-end (from BI_DB_ECB_RateExtractFromAPI)
- `Rate` stores the ECB rate used for conversion (same for all rows in a quarter)
- Non-monetary columns (CID, Regulation, Country, etc.) are identical across both currency rows

### 2.2 Sustainability Ratio Split

**What**: Stock liabilities are split into sustainable vs non-sustainable using a proportional equity ratio rather than position-level attribution.

**Columns Involved**: `LiabilitiesStocksSustainable`, `LiabilitiesStocksNonSustainable`, `LiabilitiesStocksRealSustainable`, `LiabilitiesStocksRealNonSustainable`, `HasSustainableEquityEOP`

**Rules**:
- SustainablesRatio = EquityInSustainables / (EquityInSustainables + EquityInNonSustainables)
- EquityInSustainables = SUM(Amount + PositionPnL) for positions in stocks (InstrumentTypeID IN 5,6) where InstrumentID is in BI_DB_EquitiesWithSustainabilityStamp
- `LiabilitiesStocksSustainable` = TotalStockLiabilities × SustainablesRatio
- `LiabilitiesStocksRealSustainable` = LiabilitiesStockReal × SustainablesRatio
- `HasSustainableEquityEOP` = 'HasSustainableEquity' if LiabilitiesTotalStockSustainable > 0

### 2.3 Client Balance Decomposition

**What**: Total client balance is decomposed into CFD, real crypto, and real stock components.

**Columns Involved**: `ClientBalanceEnd`, `ClientBalanceEndRealCrypto`, `ClientBalanceEnd_CFD`, `TotalStockLiabilities`

**Rules**:
- `ClientBalanceEnd` = V_Liabilities.Liabilities (what eToro owes the customer)
- `ClientBalanceEndRealCrypto` = V_Liabilities.LiabilitiesCryptoReal
- `ClientBalanceEnd_CFD` = Liabilities - LiabilitiesCryptoReal - LiabilitiesStockReal (residual)
- `TotalStockLiabilities` = TotalStockPositionAmount + StocksPositionPnL (from V_Liabilities)

### 2.4 Realized PnL Aggregation

**What**: Realized PnL is summed from positions closed during the quarter, broken down by asset class.

**Columns Involved**: `RealizedPnL`, `RealizedCFD`, `RealizedPnLRealCrypto`, `RealizedPnLRealStocks`

**Rules**:
- `RealizedPnL` = SUM(NetProfit) from Dim_Position WHERE CloseDateID in quarter
- `RealizedPnLRealCrypto` = SUM(NetProfit) WHERE InstrumentTypeID=10 AND IsSettled=1
- `RealizedPnLRealStocks` = SUM(NetProfit) WHERE InstrumentTypeID IN (5,6) AND IsSettled=1
- `RealizedCFD` = RealizedPnL - RealizedPnLRealCrypto - RealizedPnLRealStocks

### 2.5 IsEtoroBVI — Internal Account Classification

**What**: Flags eToro's own house accounts and trading group accounts, separating them from real users in regulatory reporting.

**Columns Involved**: `IsEtoroBVI`

**Rules**:
- CIDs 2244852, 2283663, 2283668 → 'eToro Group'
- CIDs 5969868, 5969870, 5969875, 5969866 → 'eToro Trading Group'
- All others → 'RealUser'

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on Quarter ASC. With ~130M rows, always filter by Quarter to leverage the clustered index. Since rows are duplicated per currency, always include `ReportCurrency = 'USD'` or `'EURO'` to avoid double-counting.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Customer balance for a specific quarter | `WHERE Quarter = 202304 AND ReportCurrency = 'USD' AND CID = @cid` |
| Total platform liabilities by regulation | `WHERE Quarter = 202304 AND ReportCurrency = 'EURO' GROUP BY Regulation` |
| Sustainability equity breakdown | `WHERE Quarter = 202304 AND ReportCurrency = 'USD' AND HasSustainableEquityEOP = 'HasSustainableEquity'` |
| Zero-balance customer count | `WHERE Quarter = 202304 AND IsZeroBalance = 'ZeroBalanceEndPeriod' AND ReportCurrency = 'USD'` |
| Quarter-over-quarter unrealized PnL change | Compare `UnrealizedEnd` across consecutive Quarter values |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_QSR_Volume_New | ON b.CID = v.CID AND b.Quarter = v.Quarter AND b.ReportCurrency = v.ReportCurrency | Combine balance with volume/revenue for full QSR |
| DWH_dbo.Dim_Customer | ON b.CID = dc.RealCID | Additional customer attributes not in QSR snapshot |

### 3.4 Gotchas

- **Dual-currency rows**: Every CID appears TWICE per quarter (USD + EURO). Always filter by `ReportCurrency` to avoid double-counting in aggregations.
- **`RealizedCFDWithBugPre2021Q2`**: Contains a known copy-paste bug — subtracts stocks twice: `QuarterRealizedPnLRealStocks - QuarterRealizedPnLRealCrypto - QuarterRealizedPnLRealStocks`. Preserved for backward compatibility with pre-Q2 2021 reports. Use `RealizedCFD` for the correct calculation.
- **`Rate` is ECB rate, not market rate**: The Rate column is the official ECB EUR/USD exchange rate at quarter-end, used only for EUR conversion. It is NOT a trading rate.
- **Stale data**: All rows show UpdateDate = 2024-01-30. The table has not been refreshed since then (data stops at Q4 2023).
- **`IsCreditReportValidCB` is a varchar**: Despite the name suggesting a boolean, this column contains descriptive strings ('CreditReportCB_Valid' / 'CreditReportCB_InValid'), not integers.
- **`PlayerStatus` trailing spaces**: Some PlayerStatus values (e.g., 'Blocked') have trailing whitespace inherited from Dim_PlayerStatus. Use RTRIM() for string comparisons.
- **`IsEtoroBVI` is misleading name**: Does not indicate BVI regulation. It flags eToro's own house accounts ('eToro Group', 'eToro Trading Group') vs 'RealUser'.
- **`StockMargin`**: Added in 2025-10 (Markos Ch). Appears mostly NULL/empty in current data, likely not yet populated for historical quarters.
- **`MifidCategory` column name**: Named `MifidCategory` in DDL but `MifidCategory` in SP, mapped from Dim_MifidCategorization.Name. Not to be confused with Fact_SnapshotCustomer.MifidCategorizationID (integer).

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★★☆ | Tier 1 — Upstream wiki verbatim | `(Tier 1 — source)` |
| ★★★☆☆ | Tier 2 — SP code / ETL-computed | `(Tier 2 — source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Quarter | int | YES | Reporting quarter as YYYYQQ integer (e.g., 202304 = Q4 2023). ETL-computed: YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate). Clustered index key. (Tier 2 — SP_Q_QSR_New) |
| 2 | ReportCurrency | varchar(100) | YES | Currency denomination for all monetary values in this row. 'USD' = original dollar amounts, 'EURO' = amounts divided by ECB EUR/USD rate. Every CID appears twice per quarter (once per currency). (Tier 2 — SP_Q_QSR_New) |
| 3 | Rate | money | YES | ECB EUR/USD exchange rate at quarter-end, sourced from BI_DB_ECB_RateExtractFromAPI. Used to convert USD amounts to EUR. Same value for all rows within a quarter. (Tier 2 — BI_DB_ECB_RateExtractFromAPI) |
| 4 | CID | int | YES | Customer ID. The real-account customer identifier. Sourced from V_Liabilities.CID, which traces to Fact_SnapshotEquity.CID. (Tier 2 — V_Liabilities / Fact_SnapshotEquity) |
| 5 | IsCreditReportValidCB | varchar(100) | YES | Credit report validation eligibility flag as descriptive string. 'CreditReportCB_Valid' when Fact_SnapshotCustomer.IsCreditReportValidCB = 1, 'CreditReportCB_InValid' otherwise. See Fact_SnapshotCustomer §2.3 for the underlying computation rules (PlayerLevelID, AccountTypeID, LabelID, CountryID). (Tier 2 — Fact_SnapshotCustomer) |
| 6 | Regulation | varchar(100) | YES | Short code for the regulatory authority governing this customer at quarter-end. Dim-lookup passthrough from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. 12 values: CySEC, FCA, BVI, ASIC & GAML, FinCEN+FINRA, FinCEN, ASIC, FSA Seychelles, eToroUS, FSRA, NFA, None. (Tier 1 — Dictionary.Regulation) |
| 7 | PlayerStatus | varchar(100) | YES | Account restriction state label at quarter-end. Dim-lookup passthrough from Dim_PlayerStatus.Name via Fact_SnapshotCustomer.PlayerStatusID. 9 values observed: Normal, Blocked, Block Deposit & Trading, Pending Verification, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning, Copy Block. Note: some values have trailing spaces. (Tier 1 — Dictionary.PlayerStatus) |
| 8 | Country | varchar(100) | YES | Full country name in English at quarter-end. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 9 | CountryFormatted | varchar(100) | YES | Country display string combining name and ISO alpha-2 code. CONCAT(Dim_Country.Name, ',', Dim_Country.Abbreviation) — e.g., 'Germany,DE', 'Italy,IT'. (Tier 2 — Dim_Country) |
| 10 | IsEtoroBVI | varchar(100) | YES | Internal account classification flag. CASE on hardcoded CID lists: 'eToro Group' (CIDs 2244852, 2283663, 2283668), 'eToro Trading Group' (CIDs 5969868, 5969870, 5969875, 5969866), 'RealUser' (all others). Despite the name, does not indicate BVI regulation. (Tier 2 — SP_Q_QSR_New) |
| 11 | ClientBalanceEnd | money | YES | Total client liabilities at quarter-end — what eToro owes the customer (real money, excluding promotional credit). ISNULL(V_Liabilities.Liabilities, 0). EUR rows divided by ECB Rate. (Tier 1 — V_Liabilities) |
| 12 | RealizedPnL | money | YES | Total realized PnL from all positions closed during the quarter. SUM(Dim_Position.NetProfit) WHERE CloseDateID in quarter range. EUR rows divided by ECB Rate. (Tier 2 — Dim_Position) |
| 13 | UnrealizedEnd | money | YES | Total unrealized PnL across all open positions at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnL, 0) at quarter-end DateModified. EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 14 | ClientBalanceEndRealCrypto | money | YES | Liabilities from real (settled) crypto positions at quarter-end. ISNULL(V_Liabilities.LiabilitiesCryptoReal, 0). EUR rows divided by ECB Rate. (Tier 1 — V_Liabilities) |
| 15 | ClientBalanceEnd_CFD | money | YES | Liabilities from CFD positions at quarter-end (residual). Computed: Liabilities - LiabilitiesCryptoReal - LiabilitiesStockReal. EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities) |
| 16 | RealizedCFD | money | YES | Realized PnL from CFD positions closed during the quarter. Computed: RealizedPnL - RealizedPnLRealCrypto - RealizedPnLRealStocks. EUR rows divided by ECB Rate. (Tier 2 — Dim_Position) |
| 17 | UnrealizedCFDEnd | money | YES | Unrealized PnL from CFD positions at quarter-end. Computed: PositionPnL - PositionPnLStocksReal - PositionPnLCryptoReal from Fact_CustomerUnrealized_PnL. EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 18 | LiabilitiesStocksSustainable | money | YES | Total stock liabilities (real + CFD) attributable to EU sustainability-stamped equities at quarter-end. Computed: TotalStockLiabilities × SustainablesRatio (from BI_DB_PositionPnL equity breakdown joined to BI_DB_EquitiesWithSustainabilityStamp). EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 19 | LiabilitiesStocksNonSustainable | money | YES | Total stock liabilities (real + CFD) attributable to non-sustainability-stamped equities at quarter-end. Computed: TotalStockLiabilities × NotSustainablesRatio. EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 20 | LiabilitiesStocksRealSustainable | money | YES | Real (settled) stock liabilities attributable to sustainability-stamped equities at quarter-end. Computed: LiabilitiesStockReal × SustainablesRatio. EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 21 | LiabilitiesStocksRealNonSustainable | money | YES | Real (settled) stock liabilities attributable to non-sustainability-stamped equities at quarter-end. Computed: LiabilitiesStockReal × NotSustainablesRatio. EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 22 | TotalStockLiabilities | money | YES | Total stock liabilities at quarter-end (position amounts + unrealized PnL). Computed: ISNULL(V_Liabilities.TotalStockPositionAmount, 0) + ISNULL(V_Liabilities.StocksPositionPnL, 0). EUR rows divided by ECB Rate. (Tier 2 — V_Liabilities) |
| 23 | IsZeroBalance | varchar(100) | YES | Balance classification flag at quarter-end. 'ZeroBalanceEndPeriod' when ClientBalanceEnd = 0 or NULL, 'NonZeroBalanceEndPeriod' otherwise. Q4 2023: 61% NonZero, 39% Zero. (Tier 2 — SP_Q_QSR_New) |
| 24 | IsNegativeBalance | varchar(100) | YES | Balance sign classification flag at quarter-end. 'NegativeBalanceEndPeriod' when ClientBalanceEnd < 0, 'PositiveBalanceEndPeriod' when > 0, 'ZeroBalanceEndPeriod' when = 0. (Tier 2 — SP_Q_QSR_New) |
| 25 | HasSustainableEquityEOP | varchar(100) | YES | Whether the customer holds sustainability-stamped equity at end of period. 'HasSustainableEquity' when LiabilitiesTotalStockSustainable > 0, 'DoesntHaveSustainableEquity' otherwise. (Tier 2 — SP_Q_QSR_New) |
| 26 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at each SP_Q_QSR_New execution. Not a business date. All rows from the last load share the same value (2024-01-30). (Tier 2 — SP_Q_QSR_New) |
| 27 | MifidCategory | varchar(100) | YES | MiFID II client classification tier name at quarter-end. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending. (Tier 1 — Dictionary.MifidCategorization) |
| 28 | RealizedPnLRealCrypto | money | YES | Realized PnL from real (settled) crypto positions closed during the quarter. SUM(NetProfit) WHERE InstrumentTypeID = 10 AND IsSettled = 1. EUR rows divided by ECB Rate. (Tier 2 — Dim_Position) |
| 29 | RealizedPnLRealStocks | money | YES | Realized PnL from real (settled) stock positions closed during the quarter. SUM(NetProfit) WHERE InstrumentTypeID IN (5, 6) AND IsSettled = 1. EUR rows divided by ECB Rate. (Tier 2 — Dim_Position) |
| 30 | UnrealizedRealCryptoEnd | money | YES | Unrealized PnL from real (settled) crypto positions at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal, 0). EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 31 | UnrealizedRealCryptoChange | money | YES | Quarter-over-quarter change in unrealized real crypto PnL. Computed: quarter-end PositionPnLCryptoReal minus prior-quarter-end PositionPnLCryptoReal. EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 32 | UnrealizedRealStocksEnd | money | YES | Unrealized PnL from real (settled) stock positions at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnLStocksReal, 0). EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 33 | UnrealizedRealStocksChange | money | YES | Quarter-over-quarter change in unrealized real stocks PnL. Computed: quarter-end PositionPnLStocksReal minus prior-quarter-end PositionPnLStocksReal. EUR rows divided by ECB Rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 34 | RealizedCFDWithBugPre2021Q2 | money | YES | Legacy realized CFD PnL column with a known copy-paste bug: QuarterRealizedPnLRealStocks - QuarterRealizedPnLRealCrypto - QuarterRealizedPnLRealStocks (subtracts stocks TWICE). Preserved for backward compatibility with pre-Q2 2021 submissions. Use RealizedCFD for the correct calculation. (Tier 2 — Dim_Position) |
| 35 | StockMargin | int | YES | Stock margin position flag. 1 when Dim_Position.SettlementTypeID = 5 (MARGIN_TRADE), 0 otherwise. Added 2025-10 (Markos Ch). Mostly NULL/empty for historical quarters. (Tier 2 — Dim_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---|---|---|---|
| Quarter | SP_Q_QSR_New | @QuarterStartDate param | YEAR * 100 + DATEPART(qq) |
| ReportCurrency | SP_Q_QSR_New | — | Literal 'USD' or 'EURO' |
| Rate | BI_DB_ECB_RateExtractFromAPI | ECBRate | Passthrough (latest rate <= quarter-end) |
| CID | V_Liabilities | CID | Passthrough |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE 1→'CreditReportCB_Valid', else→'CreditReportCB_InValid' |
| Regulation | Dim_Regulation | Name | Dim-lookup via RegulationID |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup via PlayerStatusID |
| Country | Dim_Country | Name | Dim-lookup via CountryID |
| CountryFormatted | Dim_Country | Name + Abbreviation | CONCAT(Name, ',', Abbreviation) |
| IsEtoroBVI | SP_Q_QSR_New | — | CASE on hardcoded CID lists |
| ClientBalanceEnd | V_Liabilities | Liabilities | ISNULL, EUR÷Rate |
| RealizedPnL | Dim_Position | NetProfit | SUM WHERE ClosedInPeriod, EUR÷Rate |
| UnrealizedEnd | Fact_CustomerUnrealized_PnL | PositionPnL | ISNULL at quarter-end, EUR÷Rate |
| ClientBalanceEndRealCrypto | V_Liabilities | LiabilitiesCryptoReal | ISNULL, EUR÷Rate |
| ClientBalanceEnd_CFD | V_Liabilities | Liabilities - CryptoReal - StockReal | Subtraction, EUR÷Rate |
| RealizedCFD | Dim_Position | NetProfit | Total - Crypto - Stocks, EUR÷Rate |
| UnrealizedCFDEnd | Fact_CustomerUnrealized_PnL | PnL - StocksReal - CryptoReal | Subtraction, EUR÷Rate |
| LiabilitiesStocksSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities × Ratio | Proportional split |
| LiabilitiesStocksNonSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities × (1 - Ratio) | Proportional split |
| LiabilitiesStocksRealSustainable | V_Liabilities + BI_DB_PositionPnL | LiabilitiesStockReal × Ratio | Proportional split |
| LiabilitiesStocksRealNonSustainable | V_Liabilities + BI_DB_PositionPnL | LiabilitiesStockReal × (1 - Ratio) | Proportional split |
| TotalStockLiabilities | V_Liabilities | TotalStockPositionAmount + StocksPositionPnL | Sum, EUR÷Rate |
| IsZeroBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE =0→'ZeroBalanceEndPeriod' |
| IsNegativeBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE <0/'PositiveBalanceEndPeriod'/'ZeroBalanceEndPeriod' |
| HasSustainableEquityEOP | SP_Q_QSR_New | LiabilitiesTotalStockSustainable | CASE >0→'HasSustainableEquity' |
| UpdateDate | SP_Q_QSR_New | — | GETDATE() |
| MifidCategory | Dim_MifidCategorization | Name | Dim-lookup via MifidCategorizationID |
| RealizedPnLRealCrypto | Dim_Position | NetProfit | SUM WHERE Crypto+Real+Closed, EUR÷Rate |
| RealizedPnLRealStocks | Dim_Position | NetProfit | SUM WHERE Stocks+Real+Closed, EUR÷Rate |
| UnrealizedRealCryptoEnd | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | ISNULL, EUR÷Rate |
| UnrealizedRealCryptoChange | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | End - PriorEnd, EUR÷Rate |
| UnrealizedRealStocksEnd | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | ISNULL, EUR÷Rate |
| UnrealizedRealStocksChange | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | End - PriorEnd, EUR÷Rate |
| RealizedCFDWithBugPre2021Q2 | Dim_Position | NetProfit | BUG: Stocks - Crypto - Stocks (double-subtract) |
| StockMargin | Dim_Position | SettlementTypeID | CASE WHEN = 5 THEN 1 ELSE 0 |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer ----+
DWH_dbo.Dim_Range ----------------+
DWH_dbo.Dim_Regulation -----------+
DWH_dbo.Dim_MifidCategorization --+
DWH_dbo.Dim_PlayerStatus ---------+---> #fscEndDate (customer attributes at quarter-end)
DWH_dbo.Dim_Country --------------+
                                   |
DWH_dbo.V_Liabilities ------------|---> #LiabilitiesCBusersEndDate (balance components)
                                   |
BI_DB_dbo.BI_DB_PositionPnL ------+---> #PPlEndDate → #ratios (sustainability split)
BI_DB_dbo.BI_DB_EquitiesWithSust--+
                                   |
DWH_dbo.Fact_CustomerUnrealized_PnL -> #pnl0, #pnl1 (unrealized PnL at start/end)
                                   |
DWH_dbo.Dim_Position -------------+---> #relpos → #realized → #RealizedPnLCIDLevel
DWH_dbo.Fact_CustomerAction ------+---> #rollovers (overnight fees)
DWH_dbo.Dim_Instrument ----------+
                                   |
BI_DB_dbo.BI_DB_ECB_RateExtract--+---> #ECBRateEuroDollar (EUR/USD rate)
                                   |
                        All above → #pnlCIDFinal → #balance
                                   |
           SP_Q_QSR_New (DELETE+INSERT per quarter)
                                   |
                                   v
           BI_DB_dbo.BI_DB_QSR_Balance_New (~130M rows, Q1 2020 – Q4 2023)
```

| Step | Object | Description |
|------|--------|-------------|
| Source 1 | Fact_SnapshotCustomer + Dims | Customer regulatory attributes at quarter-end via DateRangeID decode |
| Source 2 | V_Liabilities | End-of-quarter liabilities (CFD, real crypto, real stocks) |
| Source 3 | Fact_CustomerUnrealized_PnL | Unrealized PnL at quarter-start and quarter-end |
| Source 4 | Dim_Position + Fact_CustomerAction | Realized PnL from closed positions + rollover fees |
| Source 5 | BI_DB_PositionPnL + EquitiesWithSustainabilityStamp | Sustainability equity ratio |
| Source 6 | BI_DB_ECB_RateExtractFromAPI | ECB EUR/USD rate for currency conversion |
| Writer | SP_Q_QSR_New @sdate | DELETE WHERE Quarter = @CurrentQuarter, then INSERT (USD + EURO rows) |
| Target | BI_DB_dbo.BI_DB_QSR_Balance_New | ~130M rows across 16 quarters |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Dim_Customer (RealCID) | Customer dimension lookup |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulation name resolved from Fact_SnapshotCustomer.RegulationID |
| MifidCategory | DWH_dbo.Dim_MifidCategorization (Name) | MiFID tier resolved from MifidCategorizationID |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Player status resolved from PlayerStatusID |
| Country | DWH_dbo.Dim_Country (Name) | Country resolved from CountryID |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| BI_DB_dbo.BI_DB_QSR_Volume_New | Sibling table | Volume/revenue companion table for the same QSR report, written by the same SP |

---

## 7. Sample Queries

### 7.1 Total liabilities by regulation for Q4 2023 (EUR)
```sql
SELECT
    Regulation,
    SUM(ClientBalanceEnd) AS TotalLiabilities,
    SUM(ClientBalanceEndRealCrypto) AS CryptoLiabilities,
    SUM(TotalStockLiabilities) AS StockLiabilities,
    SUM(ClientBalanceEnd_CFD) AS CFDLiabilities,
    COUNT(DISTINCT CID) AS CustomerCount
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE Quarter = 202304
  AND ReportCurrency = 'EURO'
  AND IsEtoroBVI = 'RealUser'
GROUP BY Regulation
ORDER BY TotalLiabilities DESC;
```

### 7.2 Sustainability equity breakdown for CySEC customers
```sql
SELECT
    HasSustainableEquityEOP,
    COUNT(DISTINCT CID) AS Customers,
    SUM(LiabilitiesStocksSustainable) AS SustainableEquity,
    SUM(LiabilitiesStocksNonSustainable) AS NonSustainableEquity,
    SUM(TotalStockLiabilities) AS TotalStockLiabilities
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE Quarter = 202304
  AND ReportCurrency = 'USD'
  AND Regulation = 'CySEC'
  AND IsEtoroBVI = 'RealUser'
GROUP BY HasSustainableEquityEOP;
```

### 7.3 Quarter-over-quarter PnL trend by customer
```sql
SELECT
    Quarter,
    SUM(RealizedPnL) AS TotalRealizedPnL,
    SUM(UnrealizedEnd) AS TotalUnrealizedPnL,
    SUM(ClientBalanceEnd) AS TotalLiabilities
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE ReportCurrency = 'USD'
  AND IsEtoroBVI = 'RealUser'
  AND IsCreditReportValidCB = 'CreditReportCB_Valid'
GROUP BY Quarter
ORDER BY Quarter;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

SP header documents this report as the replacement for the "very old code for Quarterly Statistics Report (aka Needed Data)" — a CySEC regulatory submission with dual-currency output for Tableau dashboards.

---

*Generated: 2026-04-29 | Quality: 8.5/10 (★★★★☆) | Phases: 11/14*
*Tiers: 4 T1, 31 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_QSR_Balance_New | Type: Table | Production Source: Multi-source aggregate via SP_Q_QSR_New*
