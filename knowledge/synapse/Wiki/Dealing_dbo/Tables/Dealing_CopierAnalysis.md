# Dealing_dbo.Dealing_CopierAnalysis

> Copy trading daily analytics table — one row per active copy relationship (MirrorID) per day, combining copier demographics, PI/CopyFund attributes, copy financials, and behavioural classifications. The primary dashboard table for analysing the copy-trading product.

| Property | Value |
|----------|-------|
| **Schema** | Dealing_dbo |
| **Object Type** | Table |
| **Writer SP** | SP_CopierAnalysis |
| **Refresh** | Daily via SB_Daily |
| **Row Count** | ~633M (2022-01-01 to 2026-03-10) |
| **Temporal Coverage** | 2022-01-01 — present (active) |
| **Distinct Copy Relationships** | ~2.585M MirrorIDs |
| **Distinct Copiers (CID)** | ~693K |
| **Distinct PIs / CopyFunds** | ~6,837 |
| **Avg DaysCopying** | 563 days (long-term copiers dominate) |
| | |
| **Synapse Distribution** | HASH (ParentCID) |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |

---

## 1. Business Meaning

This is the **primary analytics table for copy-trading business intelligence**. Each row represents a snapshot of one active copy relationship on a given date, including:
- Who is copying whom (CID → ParentCID)
- How long the copy has been active (DaysCopying)
- The financial state of the copy (Amount, CopyPnL, AUM, Cash)
- Both copier and PI demographic profiles (Region, Country, Language, Age, Club, RiskScore)
- Behavioural classifications derived from position data (TraderType, Classification)

**Key design decisions:**
- Only **active** copy relationships are stored (IsActive=1 always). Closed copy relationships are not re-inserted.
- Distribution is `HASH(ParentCID)` — all copies of the same PI land on the same distribution node, optimising PI-centric aggregations.
- `FirstName` and `Email` columns are always NULL (privacy redaction in the SP — columns were used historically but are now explicitly inserted as NULL).
- Copy Portfolios (AccountTypeID=9) are included alongside regular PIs and distinguished via `PI/CP = 'CopyFund'`.

---

## 2. Derived Classifications

### TraderType (Copier's Copy Holding Pattern)
Computed from the average holding time of all mirrors the copier has with the same PI:

| TraderType | Avg Holding Days |
|---|---|
| Day trader | < 3 days |
| Swing trader | 3 – 21 days |
| Medium term investor | 22 – 93 days |
| Long term investor | ≥ 94 days |

Based on Dim_Mirror holding durations, not individual position holding times.

### Classification (Copier's Portfolio Asset Allocation)
Based on current open positions in BI_DB_PositionPnL on @date:

| Classification | Condition |
|---|---|
| Long/Short Equity | Equity ≥ 70%, Buy% ≥ 20%, Short% ≥ 20% |
| Long Equity | Equity ≥ 70%, Buy% > 80% |
| Currencies | Currencies ≥ 70% |
| Commodities | Commodities ≥ 70% |
| Crypto | Crypto ≥ 70% |
| ETF | ETF ≥ 70% |
| 100% cash balance | Total invested = 0 |
| Multi-Strategy | None of the above |

### RiskScore (1–10)
7-day rolling average of AvgSTD from BI_DB_dbo.DWH_CIDsDailyRisk, mapped to eToro's standard risk bands (same formula as platform risk score).

---

## 3. Columns

| Column | Type | Description |
|--------|------|-------------|
| Date | datetime | Report date (Tier 2 — SP parameter) |
| DateID | int | Integer YYYYMMDD of Date (Tier 2 — computed) |
| MirrorID | int | Copy relationship identifier; each copier–PI pair has one MirrorID (Tier 2 — etoro_History_Mirror) |
| CID | int | Copier customer ID (Tier 2 — etoro_History_Mirror) |
| ParentCID | int | PI or CopyFund customer ID being copied (Tier 2 — etoro_History_Mirror) |
| ParentUserName | varchar(30) | PI/CopyFund username (Tier 2 — etoro_History_Mirror) |
| GCID | int | Global customer ID of the copier (Tier 2 — Fact_SnapshotCustomer) |
| ID | varbinary(max) | Encoded customer identifier from Dim_Customer (Tier 1 — Dim_Customer) |
| PI/CP | varchar(10) | 'PI' = Popular Investor, 'CopyFund' = Copy Portfolio (AccountTypeID=9) (Tier 2 — computed) |
| UserName | varchar(30) | Copier username (Tier 1 — Dim_Customer) |
| IsActive | int | Always 1 — only active copy relationships are stored (Tier 2 — etoro_History_Mirror) |
| InitialInvestment | money | Initial amount the copier allocated to this copy relationship (Tier 2 — Dim_Mirror) |
| DepositSummary | money | Cumulative deposits into this copy relationship (Tier 2 — etoro_History_Mirror) |
| WithdrawalSummary | money | Cumulative withdrawals from this copy relationship (Tier 2 — etoro_History_Mirror) |
| DaysCopying | int | Days the copy relationship has been active as of @date; avg 563 days (Tier 2 — computed from Dim_Mirror.OpenOccurred) |
| OpenOccurred | datetime | When the copy relationship was opened (Tier 2 — Dim_Mirror) |
| CloseOccurred | datetime | When the copy relationship was closed; NULL if active (Tier 2 — Dim_Mirror) |
| CopySL | float | Copy stop-loss percentage set by the copier (Tier 2 — etoro_History_Mirror) |
| Age | int | Copier's age in years as of @date (Tier 2 — computed from Dim_Customer.BirthDate) |
| Club | varchar(20) | Copier's loyalty club tier: Bronze / Silver / Gold / Platinum / Diamond (Tier 2 — Dim_PlayerLevel) |
| TotalEquity | money | Copier's total account equity = ABS(ActualNWA + Liabilities) from V_Liabilities (Tier 2 — DWH_dbo.V_Liabilities) |
| RiskScore | int | Copier's 7-day avg risk score (1–10) based on daily AvgSTD (Tier 2 — DWH_CIDsDailyRisk) |
| Region | varchar(25) | Marketing region label for this country. Loaded from Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. Up to 21 distinct values (e.g., "ROW", "Africa", "French", "Arabic"). Used for marketing campaign grouping. |
| Country | varchar(25) | Copier's country (Tier 1 — Dim_Country) |
| Language | varchar(20) | Copier's platform language (Tier 1 — Dim_Language) |
| TraderType | varchar(20) | Copy behaviour type derived from avg mirror holding time (Tier 2 — computed) |
| CopyPnL | money | Unrealised PnL in the copy portfolio on @date (Tier 2 — etoroGeneral_History_GuruCopiers) |
| Amount | money | Total invested amount in the copy relationship (Tier 2 — etoroGeneral_History_GuruCopiers) |
| Gender | varchar(1) | Copier gender (M/F) (Tier 1 — Dim_Customer) |
| Classification | varchar(30) | Copier's portfolio asset classification (Tier 2 — computed from BI_DB_PositionPnL) |
| DaysCopyingGroup | varchar(20) | DaysCopying band: Under 30 / 31-90 / 91-180 / 181-365 / 366-730 / Above 730 (Tier 2 — computed) |
| CopyingAmountGroup | varchar(20) | Amount investment band: 0-200 / 201-500 / 501-1000 / 1001-5000 / 5001-20000 / Above 20000 (Tier 2 — computed) |
| PIClassification | varchar(30) | PI's classification from BI_DB_DailyPanel_Copy (Tier 4 — BI_DB_DailyPanel_Copy) |
| PITraderType | varchar(20) | PI's trader type from BI_DB_DailyPanel_Copy (Tier 4 — BI_DB_DailyPanel_Copy) |
| PIRegion | varchar(25) | PI's region (Tier 4 — BI_DB_DailyPanel_Copy) |
| PICountry | varchar(25) | PI's country (Tier 4 — BI_DB_DailyPanel_Copy) |
| PILanguage | varchar(20) | PI's platform language (Tier 4 — Dim_Language via PI LanguageID) |
| PIRiskScore | int | PI's risk score (Tier 4 — BI_DB_DailyPanel_Copy) |
| PIAge | int | PI's age in years (Tier 2 — computed from PI BirthDate) |
| Positive/NegativePnL | varchar(25) | 'Positive' if CopyPnL ≥ 0, 'Negative' otherwise (Tier 2 — computed) |
| AgeGroup | varchar(25) | Copier age band: 18-24 / 25-30 / 31-40 / 41-50 / 51-60 / Above 60 (Tier 2 — computed) |
| PIAgeGroup | varchar(25) | PI age band (same bands) (Tier 2 — computed) |
| UpdateDate | datetime | ETL metadata: timestamp when this row was inserted (Tier 2 — GETDATE()) |
| UnrealisedAmount | float | Sum of open position amounts (from BI_DB_PositionPnL) for this copier's MirrorID (Tier 2 — BI_DB_PositionPnL) |
| PIUnrealisedAmount | float | Sum of open position amounts for the PI's own account (Tier 2 — BI_DB_PositionPnL) |
| Num_Instruments | int | Count of distinct instruments in the copier's open positions (Tier 2 — BI_DB_PositionPnL) |
| PI_NumPositions | int | Count of distinct instruments in the PI's open positions (Tier 2 — BI_DB_PositionPnL) |
| Cash | money | Cash balance available in the copy portfolio (Tier 2 — etoroGeneral_History_GuruCopiers) |
| AUM | money | Total copy portfolio AUM = Cash + Amount + CopyPnL (Tier 2 — computed) |
| AccountManager | varchar(max) | Copier's eToro account manager full name (Tier 2 — Dim_Manager) |
| FirstName | varchar(max) | Always NULL — privacy redaction (Tier 2 — hardcoded NULL) |
| Email | varchar(max) | Always NULL — privacy redaction (Tier 2 — hardcoded NULL) |

---

## 4. Usage Notes

- **Only active copy relationships**: The SP filters `IsActive=1` in the source join. Closed mirrors do not appear. To analyse churned copiers, use etoro_History_Mirror or Dim_Mirror directly.
- **FirstName/Email always NULL**: These columns exist for schema backwards-compatibility but are privacy-redacted. Do not expect data here.
- **HASH(ParentCID) distribution**: Optimal for queries filtering or grouping by PI. Queries filtering only on CID (copier) may be slower. For pure copier-centric analysis, consider BI_DB_DailyPanel_Copy instead.
- **633M rows is large**: Queries without Date filtering will be very slow. Always filter by Date or DateID.
- **CopyFund rows**: Copy Portfolios (AccountTypeID=9) are included. They show `PI/CP = 'CopyFund'` and have RiskScore=0 in PIData (no AvgSTD-based risk for copy portfolios). PIClassification/PITraderType are also set to 'CopyFund' for these rows.
- **DaysCopying group '1001-500'**: The SP has a typo in the CopyingAmountGroup CASE — range 1000-5000 is labelled '1001-500' instead of '1001-5000'.

---

## 5. Relationships

| Relation | Table | Join Key | Notes |
|---|---|---|---|
| Copy relationship history | CopyFromLake.etoro_History_Mirror | MirrorID | Source for mirror state |
| Mirror metadata | DWH_dbo.Dim_Mirror | MirrorID | InitialInvestment, OpenOccurred |
| Copier snapshot | DWH_dbo.Fact_SnapshotCustomer | RealCID + DateRangeID | Daily customer state |
| PI performance | BI_DB_dbo.BI_DB_DailyPanel_Copy | CID + DateID | PI Classification/TraderType |
| Open positions | BI_DB_dbo.BI_DB_PositionPnL | CID + MirrorID + DateID | Num_Instruments, UnrealisedAmount |
| Copy financials | general.etoroGeneral_History_GuruCopiers | ParentCID + CID + Timestamp | CopyPnL, AUM, Cash |
| Risk scores | BI_DB_dbo.DWH_CIDsDailyRisk | CID + FullDate | 7-day RiskScore |
| Account equity | DWH_dbo.V_Liabilities | CID + DateID | TotalEquity |
