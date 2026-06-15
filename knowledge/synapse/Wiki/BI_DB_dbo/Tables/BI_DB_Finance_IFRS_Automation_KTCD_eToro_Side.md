# BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side

> 8.6K-row daily-incremental table storing aggregated **K-factor KTCD (K-TCD)** capital requirement metrics by regulation group, computed from open derivative positions using the SA-CCR (Standardised Approach for Counterparty Credit Risk) methodology. Each row represents one regulation grouping (ReportA--F) on one business date. Sourced from BI_DB_PositionPnL enriched with DWH instrument, customer, and regulation dimensions. Refreshed daily by SP_Finance_IFRS_Automation_KTCD_eToro_Side.

| Property | Value |
|----------|-------|
| **Schema** | BI_DB_dbo |
| **Object Type** | Table |
| **Production Source** | `BI_DB_dbo.BI_DB_PositionPnL` + `DWH_dbo.Dim_Instrument` + `DWH_dbo.Fact_SnapshotCustomer` via `SP_Finance_IFRS_Automation_KTCD_eToro_Side` |
| **Refresh** | Daily -- DELETE-INSERT by Date |
| | |
| **Synapse Distribution** | ROUND_ROBIN |
| **Synapse Index** | CLUSTERED INDEX (Date ASC) |
| | |
| **UC Target** | _Not_Migrated |

---

## 1. Business Meaning

`BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side` calculates the **K-TCD (K-factor for Trading Counterparty Default)** capital requirement under the IFR/IFD (Investment Firms Regulation/Directive) framework. For each business date, it computes Exposure Value (EV), Potential Future Exposure (PFE), Replacement Cost (RC), Collateral Value after adjustments, and Own Funds Requirement -- aggregated across all open CFD, crypto, futures, and stock margin positions per regulation group.

The SP implements a multi-stage SA-CCR pipeline: it classifies instruments into IFR asset classes (Foreign Exchange, Equity, Commodity, Interest Rate, Other), assigns supervisory factors per asset class, computes per-position replacement cost and PFE, applies collateral mitigation with currency mismatch adjustments, then aggregates into 6 regulation-based reports (ReportA through ReportF). The final INSERT uses UNION ALL to produce one row per report per date.

---

## 2. Business Logic

### 2.1 IFR Asset Class Segmentation

**What**: Every instrument is classified into an IFR asset class with a corresponding supervisory factor.

**Rules**:
- Crypto and crypto-linked FX pairs: Supervisory Factor = 0.32, Asset Class = "Other"
- Standard FX (InstrumentTypeID=1): SF = 0.04, Asset Class = "Foreign Exchange"
- Stock indices (InstrumentTypeID=4): SF = 0.20, Asset Class = "Equity index"
- Stocks / Stock Margin (InstrumentTypeID=5): SF = 0.32, Asset Class = "Equity single name"
- Bonds (InstrumentTypeID=6, name LIKE '%bond%'): SF = 0.005, Asset Class = "Interest Rate"
- Gold: SF = 0.04, Asset Class = "Foreign Exchange"
- Commodities (Oil, Nat Gas, Metals, agricultural): SF = 0.18
- Bitcoin futures: SF = 0.32

### 2.2 Regulation Grouping (ReportA--F)

**What**: Final output is segmented into 6 reports by regulation.

**Rules**:
- **ReportA**: RegulationID IN (0,1,2,5) -- None, CySEC, FCA, BVI; excludes eToro Trading CIDs (5969875, 5969870, 5969868)
- **ReportB**: RegulationID IN (4,10) -- ASIC, ASIC & GAML
- **ReportC**: RegulationID IN (9) -- FSA Seychelles
- **ReportD**: eToro Trading CIDs only (IsEtoroTradingCID = 1)
- **ReportE**: RegulationID IN (11) -- FSRA
- **ReportF**: RegulationID IN (13) -- MAS

### 2.3 EV and Own Funds Requirement

**What**: Core K-TCD formula per position.

**Rules**:
- `EV = MAX(0, RC + PFE - Collateral_Value_after_adjustments)` -- floored at zero
- `Own_Funds_Requirement = 1.2 * CVA * RF * EV`
- CVA = 1.0 for CySEC/FCA/BVI; 1.5 for ASIC/GAML/Seychelles/FSRA/MAS
- RF (Risk Factor) = 0.08 for Corporate counterparties; 0.016 for Institutional (ASIC/GAML/Sey/FSRA/MAS)

### 2.4 Collateral Value Calculation

**What**: Collateral mitigation differs by regulation.

**Rules**:
- CySEC/FCA/BVI (non-eToro Trading): `(1 - CurrencyMismatch) * InvestedAmount`
- All others: `RC * (1 - CurrencyMismatch)` if RC > 0, else 0
- Currency Mismatch Adjustment: 0.08 for non-USD currencies, 0 for USD

---

## 3. Query Advisory

### 3.1 Synapse Distribution & Index

**In Synapse**, this table is ROUND_ROBIN distributed with a CLUSTERED INDEX on Date. Date-range queries are efficient. JOIN on ReportID + Date for specific regulation reports.

### 3.1b UC (Databricks) Storage & Partitioning

_Not_Migrated._

### 3.2 Common Query Patterns

| Analyst Question | Recommended Approach |
|-----------------|---------------------|
| K-TCD for a specific date | `WHERE Date = @dt` -- returns 6 rows (one per report) |
| CySEC/FCA/BVI capital requirement trend | `WHERE ReportID = 'ReportA' ORDER BY Date` |
| Total EV across all regulations | `SELECT Date, SUM(EV) FROM ... GROUP BY Date` |
| ASIC-specific capital requirement | `WHERE ReportID = 'ReportB'` |

### 3.3 Common JOINs

| Join To | Join Condition | Purpose |
|---------|---------------|---------|
| SP_IFR_KFactors_Automation_KTCD | Reads from this table with `convert(varchar(6),Date,112) AS YearMonth` | Downstream K-factors automation reporting |

### 3.4 Gotchas

- **6 rows per date**: Each date produces exactly 6 rows (ReportA--F). If a regulation group has zero positions, the SUM produces 0/NULL but the row still appears.
- **eToro Trading CIDs overlap**: CIDs 5969875, 5969870, 5969868 are excluded from ReportA and placed in ReportD. These are eToro's own trading accounts.
- **Adjusted PnL for ASIC/GAML/Sey/FSRA/MAS**: These regulations use `AdjustedPnLForRegulations` (PnL + FullCommission - Commission) instead of raw `PositionPnL` for CMV calculation.
- **Real crypto included**: InstrumentTypeID=10 with IsSettled=1 are included (real crypto positions treated like CFD for KTCD purposes).
- **Stock Margin**: SettlementTypeID=5 positions are included as of October 2025.
- **Futures**: Instruments with IsFuture=1 bypass the IsSettled=0 filter and are always included.

---

## 4. Elements

### Confidence Tier Legend

| Stars | Tier | Tag |
|-------|------|-----|
| ★★★☆☆ | Tier 2 -- Synapse SP code | `(Tier 2 -source)` |
| ★★☆☆☆ | Tier 3 -- ETL metadata | `(Tier 3 -source)` |

| # | Element | Type | Nullable | Description |
|---|---------|------|----------|-------------|
| 1 | ReportID | varchar(20) | YES | Regulation group identifier. 6-value enum: "ReportA" (CySEC/FCA/BVI excl. eToro Trading), "ReportB" (ASIC/GAML), "ReportC" (FSA Seychelles), "ReportD" (eToro Trading CIDs), "ReportE" (FSRA), "ReportF" (MAS). Hardcoded literal per UNION ALL segment. (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, hardcoded) |
| 2 | Date | date | YES | Business date for the K-TCD calculation. From SP @Date parameter. Clustered index column. DELETE-INSERT scope key. (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, @Date) |
| 3 | EV | float | YES | Exposure Value in USD. SUM of per-position EV where EV = MAX(0, RC + PFE - Collateral). Floored at zero per position before aggregation. Core numerator for Own Funds Requirement. (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, aggregated) |
| 4 | Own_Funds_Requirement | float | YES | K-TCD capital requirement in USD. SUM of per-position `1.2 * CVA * RF * EV`. CVA is 1.0 for EU/UK/BVI or 1.5 for ASIC/GAML/Sey/FSRA/MAS. RF is 0.08 (Corporate) or 0.016 (Institutional). (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, aggregated) |
| 5 | UpdateDate | datetime | YES | SP execution timestamp. GETDATE(). (Tier 3 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, GETDATE()) |
| 6 | PFE | float | YES | Potential Future Exposure in USD. SUM of per-position PFE where PFE = Supervisory_Factor * Effective_Notional. Supervisory factor ranges from 0.005 (bonds) to 0.32 (crypto/stocks). (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, aggregated) |
| 7 | RC | float | YES | Replacement Cost in USD. SUM of per-position RC = -1 * PositionPnL (or AdjustedPnLForRegulations for ASIC/GAML/Sey/FSRA/MAS). Negative PnL means counterparty owes the firm. (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, aggregated) |
| 8 | Collateral_Value_after_adjustments | float | YES | Collateral mitigation in USD. For CySEC/FCA/BVI: SUM of (1 - CurrencyMismatch) * InvestedAmount. For others: SUM of RC * (1 - CurrencyMismatch) when RC > 0. Currency mismatch is 8% for non-USD, 0% for USD. (Tier 2 -SP_Finance_IFRS_Automation_KTCD_eToro_Side, aggregated) |

---

## 5. Lineage

### 5.1 Production Sources

| Synapse Column | Production Source | Source Column | Transform |
|---------------|-------------------|---------------|-----------|
| ReportID | -- | -- | hardcoded per UNION ALL segment |
| Date | -- | @Date | ETL-computed (SP parameter) |
| EV | #perAssetEtc | EV | SUM, floored at 0 per position |
| Own_Funds_Requirement | #perAssetEtc | Own Funds Requirement | SUM(1.2 * CVA * RF * EV) |
| UpdateDate | -- | -- | ETL-computed (GETDATE()) |
| PFE | #perAssetEtc | PFE | SUM(Supervisory_Factor * Effective_Notional) |
| RC | #perAssetEtc | RC | SUM(-1 * PositionPnL or AdjustedPnL) |
| Collateral_Value_after_adjustments | #perAssetEtc | Collateral Value after adjustments | SUM with regulation-dependent formula |

Full column-level lineage: [BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side.lineage.md](BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side.lineage.md)

### 5.2 ETL Pipeline

```
BI_DB_dbo.BI_DB_PositionPnL (position PnL for @dateID)
    │
    ├── JOIN DWH_dbo.Dim_Instrument (instrument metadata)
    │       └── #IFRSegmentation (supervisory factors + IFR asset class mapping)
    │
    ├── JOIN DWH_dbo.Fact_SnapshotCustomer (regulation, country, credit validity)
    ├── JOIN DWH_dbo.Dim_Range (date range resolution)
    ├── JOIN DWH_dbo.Dim_Country (country name)
    ├── JOIN DWH_dbo.Dim_Regulation (regulation name)
    ├── LEFT JOIN DWH_dbo.Dim_Position (commission for adjusted PnL)
    │
    └── SP_Finance_IFRS_Automation_KTCD_eToro_Side @Date
        ├── CTAS #pnlPrepPre → #pnlPrep (enriched positions)
        ├── CTAS #ccrPrep (distinct CID+Instrument pairs)
        ├── CTAS #collect (per-position KTCD: CMV, notional, PFE, collateral)
        ├── CTAS #collect1 (RC, effective notional, supervisory delta, own funds)
        ├── CTAS #collect2 (collateral value recalculated by regulation)
        ├── CTAS #perTXFinalRecord (EV + own funds per position)
        ├── CTAS #perAssetEtc (aggregated per instrument per regulation)
        ├── DELETE WHERE Date = @Date
        └── INSERT (6x UNION ALL: ReportA–F)
                → BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side (8.6K rows)
```

| Step | Object | Description |
|------|--------|-------------|
| Position Source | BI_DB_dbo.BI_DB_PositionPnL | Daily position-level PnL with amounts and settlement type |
| Instrument Dimension | DWH_dbo.Dim_Instrument | Asset class, currency, instrument type for IFR segmentation |
| Customer Snapshot | DWH_dbo.Fact_SnapshotCustomer | Regulation, country, credit validity flags |
| IFR Segmentation | #IFRSegmentation | Supervisory factor and IFR asset class mapping per instrument |
| Position Enrichment | #pnlPrep | Positions enriched with regulation, country, adjusted PnL |
| KTCD Calculation | #collect -> #collect1 -> #collect2 -> #perTXFinalRecord | Multi-stage SA-CCR: CMV, RC, PFE, collateral, EV, own funds |
| Aggregation | #perAssetEtc | Group by instrument + regulation with SUM of all KTCD metrics |
| Target | BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side | 6 rows per date (ReportA--F), daily incremental |

---

## 6. Relationships

### 6.1 References To (this object points to)

| Element | Related Object | Description |
|---------|---------------|-------------|
| Date | DWH_dbo.Dim_Date | Calendar date attributes |
| (via SP) | BI_DB_dbo.BI_DB_PositionPnL | Position-level PnL -- primary data source |
| (via SP) | DWH_dbo.Dim_Instrument | Instrument metadata for IFR classification |
| (via SP) | DWH_dbo.Fact_SnapshotCustomer | Customer regulation and validity |

### 6.2 Referenced By (other objects point to this)

| Consumer | Purpose |
|----------|---------|
| SP_IFR_KFactors_Automation_KTCD | Reads this table with YearMonth grouping for K-factor automation reporting |

---

## 7. Sample Queries

### 7.1 Latest K-TCD by regulation

```sql
SELECT ReportID, Date, EV, Own_Funds_Requirement, PFE, RC, Collateral_Value_after_adjustments
FROM BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side
WHERE Date = (SELECT MAX(Date) FROM BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side)
ORDER BY ReportID;
```

### 7.2 Monthly trend for CySEC/FCA/BVI

```sql
SELECT
    CONVERT(VARCHAR(7), Date, 120) AS YearMonth,
    AVG(EV) AS AvgEV,
    AVG(Own_Funds_Requirement) AS AvgOwnFunds
FROM BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side
WHERE ReportID = 'ReportA'
GROUP BY CONVERT(VARCHAR(7), Date, 120)
ORDER BY YearMonth DESC;
```

---

## 8. Atlassian Knowledge Sources

No Atlassian sources found (search unavailable).

---

*Generated: 2026-04-26 | Quality: 8.5/10 | Phases: 14/14*
*Tiers: 0 T1, 7 T2, 1 T3, 0 T4 [UNVERIFIED], 0 T5 | Elements: 10/10, Logic: 9/10, Relationships: 7/10, Sources: 8/10*
*Object: BI_DB_dbo.BI_DB_Finance_IFRS_Automation_KTCD_eToro_Side | Type: Table | Production Source: BI_DB_dbo.BI_DB_PositionPnL*
