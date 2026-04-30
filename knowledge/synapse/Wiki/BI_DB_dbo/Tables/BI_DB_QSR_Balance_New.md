# BI_DB_dbo.BI_DB_QSR_Balance_New

> ~127M-row quarterly customer balance table for the CySEC Quarterly Statistics Report (QSR), storing per-customer end-of-period liabilities, realized/unrealized PnL, and sustainability-stamped equity breakdowns — duplicated in both USD and EUR for regulatory submission. Loaded by SP_Q_QSR_New, data spans Q1-2020 to Q4-2023 (16 quarters).

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | Multi-source: V_Liabilities (balances), Fact_CustomerUnrealized_PnL (unrealized PnL), Dim_Position (realized PnL), Fact_SnapshotCustomer (customer attributes), BI_DB_EquitiesWithSustainabilityStamp (sustainability flags) |
| **Refresh** | Quarterly via SP_Q_QSR_New @sdate (DELETE + INSERT for the target quarter) |
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

`BI_DB_QSR_Balance_New` is the balance component of the CySEC Quarterly Statistics Report (QSR, also known as "Needed Data"). It provides a per-customer snapshot of end-of-quarter financial position: client balance (from V_Liabilities), realized PnL from closed positions (from Dim_Position), and unrealized PnL from open positions (from Fact_CustomerUnrealized_PnL). Each customer row is duplicated once in USD (original) and once in EUR (divided by ECB exchange rate), enabling Tableau toggling between currencies since CySEC submission is in EUR.

The table also breaks down equity holdings into sustainable vs non-sustainable categories (per EU regulation) using a ratio derived from `BI_DB_PositionPnL` position-level equity and the `BI_DB_EquitiesWithSustainabilityStamp` reference table.

Customer attributes (Regulation, PlayerStatus, Country, MifidCategory) are snapshotted from `Fact_SnapshotCustomer` at the quarter-end date via `Dim_Range`. The `IsCreditReportValidCB` flag is also taken from the snapshot and converted to a string label.

The SP header notes two inherent inaccuracies: (1) for positions opened and closed within the quarter, volume/commissions use the CLOSED regulation only; (2) sustainability ratios use V_Liabilities equity × ratio rather than actual position-level PnL equity.

As of the latest data: 16 quarters (Q1-2020 through Q4-2023), ~10.9M rows per quarter (both currencies combined), ~127M total rows.

---

## 2. Business Logic

### 2.1 Dual-Currency Duplication

**What**: Every customer row is inserted twice — once in USD, once in EUR — for regulatory reporting flexibility.

**Columns Involved**: `ReportCurrency`, `Rate`, all money columns

**Rules**:
- USD rows: all money columns at face value; Rate stores the ECB EUR/USD rate for reference
- EURO rows: all money columns divided by the ECB EUR/USD exchange rate at quarter-end
- Rate is the same value in both rows (the ECB rate used for conversion)
- Source: `BI_DB_ECB_RateExtractFromAPI` — last available ECB rate on or before quarter-end date

### 2.2 Sustainability Ratio Split

**What**: Stock liabilities are split into sustainable vs non-sustainable using a per-customer equity ratio.

**Columns Involved**: `LiabilitiesStocksSustainable`, `LiabilitiesStocksNonSustainable`, `LiabilitiesStocksRealSustainable`, `LiabilitiesStocksRealNonSustainable`, `HasSustainableEquityEOP`

**Rules**:
- From `BI_DB_PositionPnL` at quarter-end: for each customer, sum `Amount + PositionPnL` per stock position (InstrumentTypeID IN (5,6))
- Positions with InstrumentID in `BI_DB_EquitiesWithSustainabilityStamp` are sustainable; others are not
- `SustainablesRatio = EquityInSustainables / (EquityInSustainables + EquityInNonSustainables)`
- `LiabilitiesStocksSustainable = TotalStockLiabilities * SustainablesRatio`
- `LiabilitiesStocksRealSustainable = LiabilitiesStockReal * SustainablesRatio`
- `HasSustainableEquityEOP = 'HasSustainableEquity'` when `LiabilitiesTotalStockSustainable > 0`

### 2.3 IsEtoroBVI — Internal Account Classification

**What**: Hardcoded CID-based classification of eToro's own trading accounts.

**Columns Involved**: `IsEtoroBVI`

**Rules**:
- CIDs 2244852, 2283663, 2283668 → 'eToro Group'
- CIDs 5969868, 5969870, 5969875, 5969866 → 'eToro Trading Group'
- All other CIDs → 'RealUser'

### 2.4 Balance Components

**What**: How the balance columns decompose.

**Columns Involved**: `ClientBalanceEnd`, `ClientBalanceEndRealCrypto`, `ClientBalanceEnd_CFD`, `TotalStockLiabilities`

**Rules**:
- `ClientBalanceEnd = V_Liabilities.Liabilities` (what eToro owes the customer — real money, not promotional credit)
- `ClientBalanceEndRealCrypto = V_Liabilities.LiabilitiesCryptoReal` (real crypto position value + PnL)
- `ClientBalanceEnd_CFD = Liabilities - LiabilitiesCryptoReal - LiabilitiesStockReal` (CFD residual)
- `TotalStockLiabilities = TotalStockPositionAmount + StocksPositionPnL` (total stock exposure including PnL)

### 2.5 RealizedCFDWithBugPre2021Q2 — Known Bug Column

**What**: Pre-2021Q2 version of the CFD realized PnL calculation that contains a subtraction bug.

**Columns Involved**: `RealizedCFDWithBugPre2021Q2`, `RealizedCFD`

**Rules**:
- Bug formula: `QuarterRealizedPnLRealStocks - RealCrypto - RealStocks` (subtracts stocks from stocks instead of total from components)
- Corrected formula (in RealizedCFD): `QuarterRealizedPnL - RealCrypto - RealStocks`
- Column retained for backward compatibility / CySEC audit trail to avoid inquiry from regulator about changed values

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with CLUSTERED INDEX on Quarter. Each quarter contains ~10.9M rows (both currencies). Always filter by `Quarter` to leverage the clustered index. There is no hash distribution key — cross-distribution joins on CID will require data movement.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Total liabilities for a quarter (EUR) | `WHERE Quarter = 202304 AND ReportCurrency = 'EURO'` then `SUM(ClientBalanceEnd)` |
| Customer balance for a specific CID | `WHERE CID = @cid AND Quarter = @q AND ReportCurrency = 'USD'` |
| Sustainable equity ratio by regulation | `SUM(LiabilitiesStocksSustainable) / NULLIF(SUM(TotalStockLiabilities), 0) GROUP BY Regulation` |
| Negative balance customers | `WHERE IsNegativeBalance = 'NegativeBalanceEndPeriod' AND ReportCurrency = 'USD'` |
| Quarter-over-quarter comparison | Join on CID between two Quarter values |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_dbo.BI_DB_QSR_Volume_New | ON b.CID = v.CID AND b.Quarter = v.Quarter AND b.ReportCurrency = v.ReportCurrency | Combine balance and volume/commission data for full QSR |
| DWH_dbo.Dim_Regulation | ON b.Regulation = dr.Name | Resolve RegulationID for further joins |
| DWH_dbo.Dim_Country | ON b.Country = dc.Name | Resolve CountryID for further joins |

### 3.4 Gotchas

- **Every row is duplicated**: USD and EURO versions exist for the same CID+Quarter. Always filter on `ReportCurrency` to avoid double-counting.
- **PlayerStatus trailing spaces**: Live data shows trailing whitespace in PlayerStatus values (e.g., "Blocked" followed by spaces). Use `RTRIM()` for string comparisons.
- **RealizedCFDWithBugPre2021Q2 is intentionally wrong**: The column preserves a known subtraction bug for backward compatibility. Use `RealizedCFD` for correct values post-2021Q2.
- **Quarter is YYYYQQ, not a date**: 202304 = 2023 Q4. Not a date integer like DateID.
- **StockMargin column added later**: NULL for quarters before the StockMargin feature was implemented (2025-10-23).
- **Sustainability ratio is approximate**: Uses V_Liabilities equity × ratio rather than actual position-level PnL equity (noted in SP header as an intentional trade-off for alignment with CB report).
- **No UC export**: This table is not migrated to Unity Catalog.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag | Notes |
|-------|------|-----|-------|
| ★★★★★ | Tier 5 | `(Tier 5 — domain expert)` | Expert-confirmed |
| ★★★★☆ | Tier 1 | `(Tier 1 — upstream wiki, source)` | Upstream wiki verbatim |
| ★★★☆☆ | Tier 2 | `(Tier 2 — source)` | From SP code / DDL analysis |
| ★★☆☆☆ | Tier 3 | `(Tier 3 — live data / DDL structure)` | From sampling or DDL |
| ★☆☆☆☆ | Tier 4 | `[UNVERIFIED] (Tier 4 — inferred)` | Inferred, needs expert review |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Quarter | int | YES | Reporting quarter encoded as YYYYQQ (e.g., 202304 = 2023 Q4). Computed as YEAR(@QuarterStartDate) * 100 + DATEPART(qq, @QuarterStartDate). Clustered index key. 16 distinct values (202001–202304). (Tier 2 — SP_Q_QSR_New) |
| 2 | ReportCurrency | varchar(100) | YES | Currency denomination for all money columns in this row. 'USD' = face value, 'EURO' = divided by ECB rate. Every CID+Quarter combination has exactly two rows (one per currency). (Tier 2 — SP_Q_QSR_New) |
| 3 | Rate | money | YES | ECB EUR/USD exchange rate at quarter-end. Used to convert USD amounts to EUR. Same value in both the USD and EURO rows for a given quarter. Source: last available rate from BI_DB_ECB_RateExtractFromAPI on or before quarter-end date. (Tier 2 — BI_DB_ECB_RateExtractFromAPI) |
| 4 | CID | int | YES | Customer identifier. Matches Fact_SnapshotCustomer.RealCID and V_Liabilities.CID. One row per CID per Quarter per ReportCurrency. (Tier 2 — Fact_SnapshotEquity) |
| 5 | IsCreditReportValidCB | varchar(100) | YES | Credit report eligibility flag as a string label. CASE WHEN Fact_SnapshotCustomer.IsCreditReportValidCB = 1 THEN 'CreditReportCB_Valid' ELSE 'CreditReportCB_InValid'. See Fact_SnapshotCustomer wiki §2.3 for the computation rules. (Tier 2 — Fact_SnapshotCustomer) |
| 6 | Regulation | varchar(100) | YES | Short code for the regulation. Used in V_Dim_Customer and analytics dashboards. Values match production Dictionary.Regulation.Name. 12 distinct values in QSR data: CySEC, FCA, BVI, ASIC & GAML, FinCEN+FINRA, FinCEN, ASIC, FSA Seychelles, eToroUS, FSRA, NFA, None. (Tier 1 — Dictionary.Regulation) |
| 7 | PlayerStatus | varchar(100) | YES | Human-readable restriction state label. Unique per status. Used in BackOffice UI, compliance reports, and monitoring dashboards. Note: some values have trailing spaces in live data -- apply RTRIM() for string comparisons. 9 values observed: Normal, Blocked, Block Deposit & Trading, Pending Verification, Blocked Upon Request, Trade & MIMO Blocked, Deposit Blocked, Warning, Copy Block. (Tier 1 — Dictionary.PlayerStatus) |
| 8 | Country | varchar(100) | YES | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Dim-lookup passthrough from Dim_Country.Name via Fact_SnapshotCustomer.CountryID. (Tier 1 — Dictionary.Country) |
| 9 | CountryFormatted | varchar(100) | YES | Country display label combining name and ISO code. Computed as CONCAT(Dim_Country.Name, ',', Dim_Country.Abbreviation). E.g., 'United Kingdom,GB', 'France,FR'. (Tier 2 — SP_Q_QSR_New) |
| 10 | IsEtoroBVI | varchar(100) | YES | Internal account classification based on hardcoded CID list. 'eToro Group' (CIDs 2244852, 2283663, 2283668), 'eToro Trading Group' (CIDs 5969868, 5969870, 5969875, 5969866), or 'RealUser' (all others). Used to exclude eToro's own accounts from regulatory aggregates. (Tier 2 — SP_Q_QSR_New) |
| 11 | ClientBalanceEnd | money | YES | End-of-quarter client balance: what eToro owes the customer (real money, not promotional credit). ISNULL(V_Liabilities.Liabilities, 0). For EURO rows, divided by ECB rate. Liabilities = InProcessCashouts + MAX(NetEquity - BonusCredit, NetEquity if negative, 0). (Tier 2 — V_Liabilities) |
| 12 | RealizedPnL | money | YES | Total realized profit/loss from positions closed during the quarter. SUM(Dim_Position.NetProfit) WHERE CloseDateID BETWEEN QuarterStartDateID AND QuarterEndDateID. For EURO rows, divided by ECB rate. (Tier 2 — Dim_Position) |
| 13 | UnrealizedEnd | money | YES | Total unrealized PnL at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnL, 0) at QuarterEndDateID. For EURO rows, divided by ECB rate. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 14 | ClientBalanceEndRealCrypto | money | YES | End-of-quarter real crypto balance: real (settled) crypto position value + unrealized PnL. ISNULL(V_Liabilities.LiabilitiesCryptoReal, 0). LiabilitiesCryptoReal = PositionPnLCryptoReal + TotalRealCrypto. For EURO rows, divided by ECB rate. (Tier 2 — V_Liabilities) |
| 15 | ClientBalanceEnd_CFD | money | YES | End-of-quarter CFD-only balance residual. Computed as ClientBalanceEnd - ClientBalanceEndRealCrypto - LiabilitiesStockReal (V_Liabilities). Isolates CFD liabilities by subtracting real crypto and real stock components. (Tier 2 — V_Liabilities) |
| 16 | RealizedCFD | money | YES | Realized PnL from CFD positions closed during the quarter. Computed as QuarterRealizedPnL - RealCrypto - RealStocks. Corrected formula (post-2021Q2). (Tier 2 — Dim_Position) |
| 17 | UnrealizedCFDEnd | money | YES | Unrealized PnL from CFD positions at quarter-end. Computed as total unrealized PnL minus real stocks PnL minus real crypto PnL. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 18 | LiabilitiesStocksSustainable | money | YES | Total stock liabilities (position amount + PnL) attributable to EU sustainability-stamped equities. Computed as TotalStockLiabilities * SustainablesRatio (ratio from BI_DB_PositionPnL equity per position). (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 19 | LiabilitiesStocksNonSustainable | money | YES | Total stock liabilities attributable to non-sustainability-stamped equities. Computed as TotalStockLiabilities * (1 - SustainablesRatio). (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 20 | LiabilitiesStocksRealSustainable | money | YES | Real (settled) stock liabilities attributable to sustainability-stamped equities. Computed as LiabilitiesStockReal * SustainablesRatio. (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 21 | LiabilitiesStocksRealNonSustainable | money | YES | Real (settled) stock liabilities attributable to non-sustainability-stamped equities. Computed as LiabilitiesStockReal * (1 - SustainablesRatio). (Tier 2 — V_Liabilities / BI_DB_PositionPnL) |
| 22 | TotalStockLiabilities | money | YES | Total stock exposure at quarter-end: position amount plus unrealized PnL. ISNULL(V_Liabilities.TotalStockPositionAmount, 0) + ISNULL(V_Liabilities.StocksPositionPnL, 0). Denominator for sustainability ratio split. (Tier 2 — V_Liabilities) |
| 23 | IsZeroBalance | varchar(100) | YES | Balance classification flag. 'ZeroBalanceEndPeriod' when ClientBalanceEnd = 0 or NULL; 'NonZeroBalanceEndPeriod' otherwise. Used for QSR population segmentation. (Tier 2 — SP_Q_QSR_New) |
| 24 | IsNegativeBalance | varchar(100) | YES | Balance sign classification flag. 'NegativeBalanceEndPeriod' when ClientBalanceEnd < 0; 'PositiveBalanceEndPeriod' when > 0; 'ZeroBalanceEndPeriod' when = 0. Used for QSR population segmentation. (Tier 2 — SP_Q_QSR_New) |
| 25 | HasSustainableEquityEOP | varchar(100) | YES | Whether the customer held sustainability-stamped equity at end of period. 'HasSustainableEquity' when LiabilitiesTotalStockSustainable > 0; 'DoesntHaveSustainableEquity' otherwise. (Tier 2 — SP_Q_QSR_New) |
| 26 | UpdateDate | datetime | YES | ETL load timestamp. Set to GETDATE() at INSERT time. All rows in a quarter share the same value. Not a business date. (Tier 2 — SP_Q_QSR_New) |
| 27 | MifidCategory | varchar(100) | YES | Human-readable classification label. Used in compliance dashboards and regulatory reports. Dim-lookup passthrough from Dim_MifidCategorization.Name via Fact_SnapshotCustomer.MifidCategorizationID. Values: None, Retail, Professional, Elective professional, Retail Pending, Pending. (Tier 1 — Dictionary.MifidCategorization) |
| 28 | RealizedPnLRealCrypto | money | YES | Realized PnL from real (settled) crypto positions closed during the quarter. SUM(Dim_Position.NetProfit) WHERE InstrumentTypeID = 10 AND IsSettled = 1 AND CloseDateID in quarter. (Tier 2 — Dim_Position) |
| 29 | RealizedPnLRealStocks | money | YES | Realized PnL from real (settled) stock positions closed during the quarter. SUM(Dim_Position.NetProfit) WHERE InstrumentTypeID IN (5, 6) AND IsSettled = 1 AND CloseDateID in quarter. (Tier 2 — Dim_Position) |
| 30 | UnrealizedRealCryptoEnd | money | YES | Unrealized PnL from real crypto positions at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnLCryptoReal, 0) at QuarterEndDateID. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 31 | UnrealizedRealCryptoChange | money | YES | Quarter-over-quarter change in unrealized real crypto PnL. Computed as quarter-end PositionPnLCryptoReal minus previous-quarter-end PositionPnLCryptoReal. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 32 | UnrealizedRealStocksEnd | money | YES | Unrealized PnL from real stock positions at quarter-end. ISNULL(Fact_CustomerUnrealized_PnL.PositionPnLStocksReal, 0) at QuarterEndDateID. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 33 | UnrealizedRealStocksChange | money | YES | Quarter-over-quarter change in unrealized real stock PnL. Computed as quarter-end PositionPnLStocksReal minus previous-quarter-end PositionPnLStocksReal. (Tier 2 — Fact_CustomerUnrealized_PnL) |
| 34 | RealizedCFDWithBugPre2021Q2 | money | YES | Legacy CFD realized PnL with known subtraction bug. Formula: QuarterRealizedPnLRealStocks - RealCrypto - RealStocks (incorrectly subtracts stocks from stocks instead of total). Retained for backward compatibility to avoid CySEC inquiry about changed values. Use RealizedCFD for correct values. (Tier 2 — SP_Q_QSR_New) |
| 35 | StockMargin | int | YES | Stock margin flag. 1 when position SettlementTypeID = 5 (MARGIN_TRADE), 0 otherwise. Added 2025-10-23 (Markos Ch). NULL for quarters before implementation. (Tier 2 — Dim_Position) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Source Object | Source Column | Transform |
|---------------|--------------|---------------|-----------|
| Quarter | SP_Q_QSR_New | @sdate parameter | YEAR * 100 + DATEPART(qq) |
| ReportCurrency | SP_Q_QSR_New | — | Literal 'USD' / 'EURO' |
| Rate | BI_DB_ECB_RateExtractFromAPI | ECBRate | Last rate <= quarter-end |
| CID | Fact_SnapshotEquity (via V_Liabilities) | CID | Passthrough |
| IsCreditReportValidCB | Fact_SnapshotCustomer | IsCreditReportValidCB | CASE 1→Valid, else→InValid |
| Regulation | Dim_Regulation | Name | Dim-lookup passthrough |
| PlayerStatus | Dim_PlayerStatus | Name | Dim-lookup passthrough |
| Country | Dim_Country | Name | Dim-lookup passthrough |
| CountryFormatted | Dim_Country | Name, Abbreviation | CONCAT(Name, ',', Abbreviation) |
| IsEtoroBVI | SP_Q_QSR_New | CID | CASE on hardcoded CID list |
| ClientBalanceEnd | V_Liabilities | Liabilities | ISNULL; /Rate for EURO |
| RealizedPnL | Dim_Position | NetProfit | SUM WHERE closed in quarter |
| UnrealizedEnd | Fact_CustomerUnrealized_PnL | PositionPnL | ISNULL at quarter-end |
| ClientBalanceEndRealCrypto | V_Liabilities | LiabilitiesCryptoReal | ISNULL; /Rate for EURO |
| ClientBalanceEnd_CFD | V_Liabilities | Liabilities - CryptoReal - StockReal | Arithmetic |
| RealizedCFD | Dim_Position | NetProfit | Total - Crypto - Stocks |
| UnrealizedCFDEnd | Fact_CustomerUnrealized_PnL | PnL - StocksReal - CryptoReal | Arithmetic |
| LiabilitiesStocksSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities * ratio | Sustainability split |
| LiabilitiesStocksNonSustainable | V_Liabilities + BI_DB_PositionPnL | TotalStockLiabilities * (1-ratio) | Sustainability split |
| LiabilitiesStocksRealSustainable | V_Liabilities + BI_DB_PositionPnL | StockReal * ratio | Sustainability split |
| LiabilitiesStocksRealNonSustainable | V_Liabilities + BI_DB_PositionPnL | StockReal * (1-ratio) | Sustainability split |
| TotalStockLiabilities | V_Liabilities | TotalStockPositionAmount + StocksPositionPnL | Arithmetic |
| IsZeroBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE = 0 / NULL |
| IsNegativeBalance | SP_Q_QSR_New | ClientBalanceEnd | CASE < 0 / > 0 / = 0 |
| HasSustainableEquityEOP | SP_Q_QSR_New | LiabilitiesTotalStockSustainable | CASE > 0 |
| UpdateDate | SP_Q_QSR_New | — | GETDATE() |
| MifidCategory | Dim_MifidCategorization | Name | Dim-lookup passthrough |
| RealizedPnLRealCrypto | Dim_Position | NetProfit | SUM WHERE crypto+settled |
| RealizedPnLRealStocks | Dim_Position | NetProfit | SUM WHERE stocks+settled |
| UnrealizedRealCryptoEnd | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | ISNULL at quarter-end |
| UnrealizedRealCryptoChange | Fact_CustomerUnrealized_PnL | PositionPnLCryptoReal | End - start |
| UnrealizedRealStocksEnd | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | ISNULL at quarter-end |
| UnrealizedRealStocksChange | Fact_CustomerUnrealized_PnL | PositionPnLStocksReal | End - start |
| RealizedCFDWithBugPre2021Q2 | Dim_Position | NetProfit | Bug formula (stocks - crypto - stocks) |
| StockMargin | Dim_Position | SettlementTypeID | CASE WHEN = 5 THEN 1 ELSE 0 |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotCustomer (customer attributes at quarter-end)
  + DWH_dbo.Dim_Range (date range expansion)
  + DWH_dbo.Dim_Regulation / Dim_MifidCategorization / Dim_PlayerStatus / Dim_Country (lookups)
  → #fscEndDate (customer snapshot temp table)

DWH_dbo.V_Liabilities (balance at quarter-end DateID)
  → #vliabiltyprep → #LiabilitiesCBusersEndDate

BI_DB_dbo.BI_DB_PositionPnL (stock equity per position at quarter-end)
  + BI_DB_dbo.BI_DB_EquitiesWithSustainabilityStamp (sustainability flags)
  → #PPlEndDate → #ratios → #liabilitiesWithRatios

DWH_dbo.Fact_CustomerUnrealized_PnL (unrealized PnL at quarter start + end)
  → #pnl0 (start) + #pnl1 (end)

DWH_dbo.Dim_Position (closed positions in quarter)
  → #relpos → #realized → #RealizedPnLCIDLevel

All above → #pnlCIDFinal → #balance (UNION of USD + EURO rows)

BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI (ECB EUR/USD rate)
  → #ECBRateEuroDollar

SP_Q_QSR_New:
  DELETE FROM BI_DB_QSR_Balance_New WHERE Quarter = @CurrentQuarter
  INSERT INTO BI_DB_QSR_Balance_New SELECT ... FROM #balance
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| CID | DWH_dbo.Fact_SnapshotCustomer (RealCID) | Customer identifier |
| Regulation | DWH_dbo.Dim_Regulation (Name) | Regulatory jurisdiction name |
| PlayerStatus | DWH_dbo.Dim_PlayerStatus (Name) | Account restriction state name |
| Country | DWH_dbo.Dim_Country (Name) | Country name |
| MifidCategory | DWH_dbo.Dim_MifidCategorization (Name) | MiFID II classification name |

### 6.2 Referenced By (other objects point to this)

| Source Object | Source Element | Description |
|--------------|---------------|-------------|
| SP_Q_QSR_New | (writer) | Quarterly load SP — DELETE + INSERT for target quarter |

---

## 7. Sample Queries

### 7.1 Total client liabilities by regulation (EUR, latest quarter)

```sql
SELECT
    Regulation,
    COUNT(DISTINCT CID) AS CustomerCount,
    SUM(ClientBalanceEnd) AS TotalLiabilities,
    SUM(CASE WHEN IsNegativeBalance = 'NegativeBalanceEndPeriod' THEN 1 ELSE 0 END) AS NegativeBalanceCount
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE Quarter = 202304
  AND ReportCurrency = 'EURO'
GROUP BY Regulation
ORDER BY TotalLiabilities DESC;
```

### 7.2 Sustainability equity breakdown for a customer

```sql
SELECT
    Quarter,
    ReportCurrency,
    ClientBalanceEnd,
    TotalStockLiabilities,
    LiabilitiesStocksSustainable,
    LiabilitiesStocksNonSustainable,
    HasSustainableEquityEOP
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE CID = 12345678
  AND ReportCurrency = 'USD'
ORDER BY Quarter;
```

### 7.3 Realized vs unrealized PnL by quarter (USD)

```sql
SELECT
    Quarter,
    SUM(RealizedPnL) AS TotalRealizedPnL,
    SUM(UnrealizedEnd) AS TotalUnrealizedEnd,
    SUM(RealizedCFD) AS RealizedCFD,
    SUM(RealizedPnLRealCrypto) AS RealizedCrypto,
    SUM(RealizedPnLRealStocks) AS RealizedStocks
FROM BI_DB_dbo.BI_DB_QSR_Balance_New
WHERE ReportCurrency = 'USD'
GROUP BY Quarter
ORDER BY Quarter;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources searched (regen harness mode — skipped Phase 10).

---

*Generated: 2026-04-29 | Quality: 8.5/10 (★★★★☆) | Phases: 11/14*
*Tiers: 4 T1, 31 T2, 0 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 35/35, Logic: 9/10, Relationships: 7/10, Sources: 9/10*
*Object: BI_DB_dbo.BI_DB_QSR_Balance_New | Type: Table | Production Source: Multi-source via SP_Q_QSR_New (V_Liabilities, Fact_CustomerUnrealized_PnL, Dim_Position, Fact_SnapshotCustomer)*
