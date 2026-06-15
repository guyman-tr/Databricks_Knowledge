# BI_DB_dbo.BI_DB_ICF_Report

> 15.4K-row monthly end-of-month Investor Compensation Fund (ICF) regulatory report aggregating client equity positions by regulation (FCA/CySEC/BVI/NFA/None), player status, and MiFID category — computing total cash, CFD equity, real stocks equity, real futures equity, stocks margin equity, USD totals, EUR conversion via ECB rate, and balances exceeding the €20,000 threshold. Sourced from BI_DB_Client_Balance_CID_Level_New with ECB rates from BI_DB_ECB_RateExtractFromAPI. Date range: Jan 2015 – Mar 2026 (135 monthly snapshots). Refreshed daily via SB_Daily but SP only inserts on month-end dates.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table (Regulatory reporting — ICF) |
| **Production Source** | Derived — aggregated from BI_DB_Client_Balance_CID_Level_New + BI_DB_ECB_RateExtractFromAPI by SP_ICF_Report |
| **Refresh** | Monthly (end-of-month only; SP runs daily via SB_Daily but guards with `IF @Date=EOMONTH(@Date)`) |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | HEAP |
| **UC Target** | `_Not_Migrated` |
| **UC Format** | — |
| **UC Partitioned By** | — |
| **UC Table Type** | — |
| **OpsDB Priority** | 0 |
| **OpsDB Process** | SB_Daily, ProcessType 1 (SQL) |
| **Author** | Guy Manova (margin trades Oct 2025), real futures Jan 2025, bugfix May 2025 |

---

## 1. Business Meaning

`BI_DB_ICF_Report` is a **monthly regulatory snapshot** for the Investor Compensation Fund (ICF). ICF is a CySEC-mandated fund that protects retail investors in the event of a broker insolvency — firms must report client assets held on a per-regulation, per-status basis to demonstrate the fund's coverage obligations.

Each row represents a **unique combination** of Date × Regulation × PlayerStatus × MifidCategory × IsCreditReportValidCB — i.e., one aggregated bucket of all clients sharing those attributes. The table holds 15,446 rows across 135 end-of-month dates from January 2015 to March 2026.

The SP aggregates CID-level data from `BI_DB_Client_Balance_CID_Level_New` (the Priority 99 master client balance table), filtering to the five ICF-relevant regulations: FCA, CySEC, BVI, NFA, and None. It computes equity breakdowns for CFD positions, real stocks, real futures, stocks margin, then converts the USD total to EUR using the most recent ECB exchange rate and flags any bucket where the EUR total exceeds €20,000.

### Load Pattern

- **Monthly delete-insert**: Deletes existing rows for the target DateID, then inserts the new aggregated result
- The SP accepts `@Date` but only executes the body when `@Date = EOMONTH(@Date)` — non-month-end calls are no-ops
- OpsDB schedules it daily via SB_Daily at Priority 0, so it fires every day but produces output only once per month

### Key Business Rules

- **Total - USD**: For CySEC/BVI/NFA/None regulations, this is `Total Cash + EquityCFD + Equity Real Stocks + EquityRealFutures`. For FCA, it is `EquityCFD` only (FCA regulatory treatment excludes cash and real assets from ICF exposure)
- **ECB Rate**: The latest EUR/USD rate on or before the report date from `BI_DB_ECB_RateExtractFromAPI`
- **Balance exceeding 20k EUR**: `MAX(0, Total-in-EUR - 20,000)` — the ICF coverage threshold per customer group

---

## 2. Business Logic

### 2.1 Equity Decomposition

**What**: Total position equity is decomposed into four asset classes to separate regulatory treatment.
**Columns Involved**: EquityCFD, Equity Real Stocks, EquityRealFutures, EquityStocksMargin
**Rules**:
- EquityCFD = (PositionAmount + PositionPNL) − RealCrypto − RealStocks − RealFutures (residual after subtracting settled assets)
- Equity Real Stocks = TotalRealStocks + PositionPNLStocksReal
- EquityRealFutures = TotalRealFutures + PositionPNLFuturesReal (added Jan 2025)
- EquityStocksMargin = TotalStocksMargin + PositionPnLStocksMargin (added Oct 2025)

### 2.2 Regulation-Dependent USD Calculation

**What**: The Total - USD calculation differs by regulation entity.
**Columns Involved**: Total - USD, Total Cash, EquityCFD, Equity Real Stocks, EquityRealFutures
**Rules**:
- CySEC, BVI, NFA, None: `Total Cash + EquityCFD + Equity Real Stocks + EquityRealFutures`
- FCA: `EquityCFD` only (real assets and cash excluded from FCA ICF scope)

### 2.3 EUR Conversion and Threshold

**What**: USD totals are converted to EUR using the most recent ECB rate, then flagged against the €20,000 ICF threshold.
**Columns Involved**: ECBRate, Total in EUR (Using ECB Rate), Balance exceeding 20k EUR
**Rules**:
- ECBRate = latest BI_DB_ECB_RateExtractFromAPI rate where DateID <= report DateID (ROW_NUMBER partitioned by report date, ordered by ECB date DESC, take rn=1)
- Total in EUR = Total - USD / ECBRate
- Balance exceeding 20k EUR = MAX(0, Total in EUR − 20,000)

### 2.4 Total Cash Composition

**What**: Total Cash represents the full liquid cash position of clients in a group.
**Columns Involved**: Total Cash
**Rules**:
- Total Cash = SUM(AvailableCash + CashInCopy − TotalNegativeLiability + InProcessCashout − actualNWA) per group

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

ROUND_ROBIN distribution with HEAP storage. Small table (15.4K rows) — full scans are efficient. No partition pruning available; filter on DateID for date range queries.

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| Monthly ICF exposure by regulation | `SELECT Date, Regulation, SUM([Total in EUR (Using ECB Rate)]) FROM BI_DB_ICF_Report GROUP BY Date, Regulation ORDER BY Date` |
| Clients exceeding 20K EUR threshold | `SELECT * FROM BI_DB_ICF_Report WHERE [Balance exceeding 20k EUR] > 0` |
| FCA vs CySEC equity comparison | `WHERE Regulation IN ('FCA','CySEC') GROUP BY Date, Regulation` |
| Latest month snapshot | `WHERE DateID = (SELECT MAX(DateID) FROM BI_DB_ICF_Report)` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| BI_DB_Client_Balance_CID_Level_New | DateID = DateID AND Regulation = Regulation | Drill into CID-level detail |
| BI_DB_ECB_RateExtractFromAPI | DateID match | Verify ECB rate used |

### 3.4 Gotchas

- **Column names with spaces**: `[Total Cash]`, `[Equity Real Stocks]`, `[Total - USD]`, `[Total in EUR (Using ECB Rate)]`, `[Balance exceeding 20k EUR]` require square brackets
- **FCA different formula**: FCA Total - USD excludes cash and real assets — do not compare FCA totals with CySEC totals directly
- **Monthly only**: Data exists only for end-of-month dates (EOMONTH). Querying mid-month DateIDs returns nothing
- **Real Futures columns mostly zero**: Only 90 of 15.4K rows have non-zero EquityRealFutures (feature added Jan 2025, affects recent months only)
- **Stocks Margin columns very sparse**: Only 22 rows have non-zero EquityStocksMargin (added Oct 2025)
- **19 columns, not 14**: The DDL has 19 columns — the original 14 plus 5 added in 2025 (EquityRealFutures, RealFuturesProviderMargin, FuturesLockedCash, EquityStocksMargin, TotalStockMarginLoanValue)

---

## 4. Elements

### Confidence Tier Legend

| Tier | Meaning |
|------|---------|
| Tier 1 | Verified from upstream wiki with documented production source |
| Tier 2 | Derived from SP code analysis with high confidence |
| Tier 3 | Inferred from data patterns and naming conventions |
| Tier 4 | Best available knowledge, limited confidence |
| Tier 5 | ETL metadata / infrastructure column |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | Date | date | NO | End-of-month business date for this ICF snapshot. Computed as EOMONTH(source.Date). Only end-of-month dates exist. (Tier 2 — SP_ICF_Report) |
| 2 | DateID | int | NO | Date identifier in YYYYMMDD integer format. Filtered to the @DateID parameter. Used for delete-insert partitioning. (Tier 2 — SP_ICF_Report, from BI_DB_Client_Balance_CID_Level_New) |
| 3 | Regulation | varchar(20) | NO | Name of the regulatory entity governing this customer group. Values: FCA, CySEC, BVI, NFA, None. Resolved from Dim_Regulation.Name via Fact_SnapshotCustomer.RegulationID. Filtered to 5 ICF-relevant regulations only. (Tier 1 — Dictionary.Regulation, via BI_DB_Client_Balance_CID_Level_New) |
| 4 | PlayerStatus | varchar(50) | NO | Customer account status. 16 values observed: Normal, Blocked, Blocked Upon Request, Deposit Blocked, Trade & MIMO Blocked, Warning, Pending Verification, Block Deposit & Trading, Copy Block, Social Index, Blocked - Under Investigation, Chat Blocked, Blocked - PayPal Investigation, Blocked – Failed Verification, Scalpers Block, N/A. From Dim_PlayerStatus. (Tier 1 — Dictionary.PlayerStatus, via BI_DB_Client_Balance_CID_Level_New) |
| 5 | MifidCategory | varchar(50) | YES | MiFID II client categorization. 7 values: Retail, Retail Pending, Pending, blank, Elective professional, Professional, None. Determines regulatory protections and reporting requirements. From Dim_MifidCategorization. (Tier 1 — Dictionary.MifidCategorization, via BI_DB_Client_Balance_CID_Level_New) |
| 6 | IsCreditReportValidCB | int | NO | Credit Bureau reporting eligibility flag. 0 or 1. 1 = eligible for credit reporting. Inherited from Fact_SnapshotCustomer. Excludes demo non-real accounts, internal labels (26,30), and blocked countries (250). (Tier 2 — SP_Client_Balance_New, from DWH_dbo.Fact_SnapshotCustomer, via BI_DB_Client_Balance_CID_Level_New) |
| 7 | ECBRate | float | YES | EUR/USD exchange rate from the European Central Bank. The latest available rate on or before the report date from BI_DB_ECB_RateExtractFromAPI. Used to convert Total - USD to EUR. (Tier 2 — SP_ICF_Report, from BI_DB_ECB_RateExtractFromAPI) |
| 8 | Total Cash | money | YES | Sum of liquid cash positions for all clients in this group. Computed as SUM(AvailableCash + CashInCopy − TotalNegativeLiability + InProcessCashout − actualNWA) aggregated across CIDs. (Tier 2 — SP_ICF_Report) |
| 9 | EquityCFD | money | YES | CFD (Contract for Difference) equity for all clients in this group. Computed as SUM((PositionAmount + PositionPNL) − (TotalRealCrypto + PositionPNLCryptoReal) − (TotalRealStocks + PositionPNLStocksReal) − (TotalRealFutures + PositionPNLFuturesReal)) — the residual after subtracting all settled asset classes. (Tier 2 — SP_ICF_Report) |
| 10 | Equity Real Stocks | money | YES | Total equity in real (settled) stock positions for all clients in this group. Computed as SUM(TotalRealStocks + PositionPNLStocksReal). Customer owns the underlying shares. (Tier 2 — SP_ICF_Report) |
| 11 | Total - USD | money | YES | Total client assets in USD. Regulation-dependent formula: CySEC/BVI/NFA/None = Total Cash + EquityCFD + Equity Real Stocks + EquityRealFutures. FCA = EquityCFD only (FCA regulatory treatment excludes cash and real assets from ICF exposure). (Tier 2 — SP_ICF_Report) |
| 12 | Total in EUR (Using ECB Rate) | money | YES | Total client assets converted to EUR. Computed as [Total - USD] / ECBRate. Used for ICF threshold comparison. (Tier 2 — SP_ICF_Report) |
| 13 | Balance exceeding 20k EUR | money | YES | Amount by which the EUR total exceeds the €20,000 ICF coverage threshold. Computed as MAX(0, [Total in EUR] − 20,000). Zero if below threshold. 30% of rows have non-zero values. (Tier 2 — SP_ICF_Report) |
| 14 | UpdateDate | datetime | YES | ETL metadata: timestamp when this row was inserted by SP_ICF_Report. Set to GETDATE() during execution. (Tier 5 — SP_ICF_Report) |
| 15 | EquityRealFutures | decimal(18,6) | YES | Total equity in real futures positions for all clients in this group. Computed as SUM(TotalRealFutures + PositionPNLFuturesReal). Added Jan 2025 (#SR-293260). Only 90 of 15.4K rows have non-zero values. (Tier 2 — SP_ICF_Report) |
| 16 | RealFuturesProviderMargin | decimal(18,6) | YES | Provider margin required for futures positions. Computed as SUM(TotalFuturesProviderMargin). Margin required by the futures provider (Marex). Added Oct 2025. (Tier 2 — SP_ICF_Report, from BI_DB_Client_Balance_CID_Level_New) |
| 17 | FuturesLockedCash | decimal(18,6) | YES | Cash locked as additional futures margin beyond provider margin. Computed as SUM(TotalFuturesLockedCash). Added Oct 2025. (Tier 2 — SP_ICF_Report, from BI_DB_Client_Balance_CID_Level_New) |
| 18 | EquityStocksMargin | decimal(18,6) | YES | Total equity in margin-traded stock positions. Computed as SUM(TotalStocksMargin + PositionPnLStocksMargin). Added Oct 2025. Only 22 rows have non-zero values. (Tier 2 — SP_ICF_Report, from BI_DB_Client_Balance_CID_Level_New) |
| 19 | TotalStockMarginLoanValue | decimal(18,6) | YES | Loan value for leveraged margin stock positions. Computed as SUM(TotalStockMarginLoanValue). Represents the broker-funded portion of margin positions. Added Oct 2025. (Tier 2 — SP_ICF_Report, from BI_DB_Client_Balance_CID_Level_New) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|----------------|------------------|---------------|-----------|
| Regulation | Dictionary.Regulation (via BI_DB_Client_Balance_CID_Level_New) | Name | Passthrough, filtered to FCA/CySEC/BVI/NFA/None |
| PlayerStatus | Dictionary.PlayerStatus (via BI_DB_Client_Balance_CID_Level_New) | PlayerStatus | Passthrough |
| MifidCategory | Dictionary.MifidCategorization (via BI_DB_Client_Balance_CID_Level_New) | MifidCategory | Passthrough |
| IsCreditReportValidCB | DWH_dbo.Fact_SnapshotCustomer (via BI_DB_Client_Balance_CID_Level_New) | IsCreditReportValidCB | Passthrough |
| ECBRate | BI_DB_ECB_RateExtractFromAPI | ECBRate | Latest rate ≤ report date |
| Total Cash | V_Liabilities (via BI_DB_Client_Balance_CID_Level_New) | AvailableCash, CashInCopy, TotalNegativeLiability, InProcessCashout, actualNWA | SUM aggregation with sign adjustments |
| EquityCFD | DWH_dbo.Fact_SnapshotEquity (via BI_DB_Client_Balance_CID_Level_New) | PositionAmount, PositionPNL, TotalRealCrypto/Stocks/Futures | Residual after subtracting settled classes |
| All equity columns | DWH_dbo.Fact_SnapshotEquity (via BI_DB_Client_Balance_CID_Level_New) | Various Total* and PositionPNL* | SUM aggregation |

### 5.2 ETL Pipeline

```
DWH_dbo.Fact_SnapshotEquity + V_Liabilities + Fact_SnapshotCustomer + Dim tables
  |-- SP_Client_Balance_New (Priority 99, daily) --|
  v
BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New (CID-level daily, ~billions of rows)
  + BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI (EUR/USD rate)
    |-- SP_ICF_Report @Date (Priority 0, daily/monthly guard) --|
    |   Filter: Regulation IN (FCA, CySEC, BVI, NFA, None)      |
    |   Aggregate: SUM by Date/Regulation/Status/Mifid/CreditCB |
    |   Convert: USD → EUR via ECB, threshold at €20,000         |
    v
BI_DB_dbo.BI_DB_ICF_Report (15.4K rows, monthly end-of-month)
  (Not in Generic Pipeline — _Not_Migrated to UC)
```

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| DateID, Regulation, PlayerStatus, MifidCategory, IsCreditReportValidCB | BI_DB_dbo.BI_DB_Client_Balance_CID_Level_New | Primary data source — CID-level balance |
| ECBRate | BI_DB_dbo.BI_DB_ECB_RateExtractFromAPI | EUR/USD exchange rate source |

### 6.2 Referenced By (other objects point to this)

No known consumers found in the SSDT repo.

---

## 7. Sample Queries

### 7.1 Monthly ICF Exposure by Regulation

```sql
SELECT [Date], Regulation,
       SUM([Total in EUR (Using ECB Rate)]) AS total_eur,
       SUM([Balance exceeding 20k EUR]) AS excess_20k_eur
FROM [BI_DB_dbo].[BI_DB_ICF_Report]
WHERE DateID >= 20250101
GROUP BY [Date], Regulation
ORDER BY [Date], Regulation
```

### 7.2 FCA vs CySEC Equity Breakdown (Latest Month)

```sql
SELECT Regulation,
       SUM([Total Cash]) AS cash,
       SUM(EquityCFD) AS cfd,
       SUM([Equity Real Stocks]) AS real_stocks,
       SUM(EquityRealFutures) AS real_futures,
       SUM([Total - USD]) AS total_usd,
       SUM([Total in EUR (Using ECB Rate)]) AS total_eur
FROM [BI_DB_dbo].[BI_DB_ICF_Report]
WHERE DateID = (SELECT MAX(DateID) FROM [BI_DB_dbo].[BI_DB_ICF_Report])
  AND Regulation IN ('FCA', 'CySEC')
GROUP BY Regulation
```

### 7.3 Trend of Balances Exceeding €20K Threshold

```sql
SELECT [Date], COUNT(*) AS groups_above_20k,
       SUM([Balance exceeding 20k EUR]) AS total_excess
FROM [BI_DB_dbo].[BI_DB_ICF_Report]
WHERE [Balance exceeding 20k EUR] > 0
GROUP BY [Date]
ORDER BY [Date]
```

---

## 8. Atlassian Knowledge Sources

No Confluence or Jira sources found (Atlassian search permission denied).

---

*Generated: 2026-04-26 | Quality: 8.0/10 | Phases: 13/14*
*Tiers: 3 T1, 14 T2, 0 T3, 0 T4, 1 T5 | Elements: 19/19, Logic: 8/10, Lineage: 8/10*
*Object: BI_DB_dbo.BI_DB_ICF_Report | Type: Table | Production Source: Derived — BI_DB_Client_Balance_CID_Level_New + BI_DB_ECB_RateExtractFromAPI*
