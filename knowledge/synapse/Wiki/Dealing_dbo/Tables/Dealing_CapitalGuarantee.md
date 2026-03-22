---
object: Dealing_CapitalGuarantee
schema: Dealing_dbo
type: Table
description: Daily per-copier tracker for the GainersQtr capital guarantee promotion (Q4 2023). Computes each copier's eligible AUM, eligibility ratio (reduced by withdrawals), and the guaranteed P&L coverage amount. Active past promotion expiry (Jan 2025) until SP decommission.
etl_sp: Dealing_dbo.SP_CapitalGuarantee
frequency: Daily (P0)
status: Active (continuing post-promo; last row 2026-03-10)
row_count: 257102
distribution: ROUND_ROBIN
index: CLUSTERED (DateID ASC)
batch: 14
quality: 8.0
---

# Dealing_CapitalGuarantee

Daily snapshot of the **GainersQtr capital guarantee promotion** for each eligible copier. Tracks cumulative eligibility (reduced each day a net withdrawal occurs), total AUM including same-day fund additions, and the computed Protected_PnL — the portion of net P&L covered by eToro's guarantee commitment.

**Promotion scope**: Copiers who started copying under ParentCID = 4657429 (GainersQtr PI) between 2023-09-26 and 2023-11-20.
**Guarantee expiry**: `@EndPromo = 20250101` — the promotion guarantee expired Jan 1 2025. The SP continues running post-expiry, inserting rows until decommissioned.

## Source & Lineage

| Layer | Object | Role |
|-------|--------|------|
| Primary | `general.etoroGeneral_History_GuruCopiers` | Daily AUM snapshots (YesterdaysAUM, IntitialAmount) per copier |
| Funds flow | `DWH_dbo.Fact_CustomerAction` | ActionTypeID 15/17 = add funds, ActionTypeID 16 = remove funds; same-day fund movements |
| Dimension | `DWH_dbo.Dim_Mirror` | Mirror metadata for ParentCID=4657429 scope filter |
| Dimension | `DWH_dbo.Dim_Customer` | RealCID → GCID, Username, CountryID, AccountManagerID, PlayerLevelID |
| Dimension | `DWH_dbo.Dim_PlayerLevel` | PlayerLevelID → Name (Diamond, Platinum Plus, etc.) |
| Dimension | `DWH_dbo.Dim_Manager` | AccountManagerID → FirstName + LastName |
| Dimension | `DWH_dbo.Dim_Country` | CountryID → Name, Region |
| Writer | `Dealing_dbo.SP_CapitalGuarantee` | Daily, OpsDB Priority 0 |

**Eligibility_Ratio formula**: Starts at 1.0 for each copier. Each day where funds were removed, `CurrentRatio = 1 - (RemovedFunds / AUM)`. Cumulative: `Eligibility_Ratio = PrevRatio × CurrentRatio`. Days without withdrawals leave the ratio unchanged. Once ratio reaches 0, the copier has no eligible coverage.

**Total_AUM**: `ROUND(YesterdaysAUM + AddedFunds, 4)` — includes same-day fund additions (ActionTypeID 15/17) to give accurate current-day AUM.

## 1. Business Purpose

- Fulfills eToro's internal capital guarantee commitment for GainersQtr promotion participants
- `Protected_PnL` = `(Total_AUM - InitialAmount) × Eligibility_Ratio` — the eligible portion of net P&L that eToro guarantees to pay out if negative
- Daily refresh allows the Dealing/Finance team to see current exposure to the guarantee obligation
- `Eligible_Amount` = `InitialAmount × Eligibility_Ratio` — the effective principal still covered by the guarantee after withdrawals

## 2. Key Concepts

| Concept | Explanation |
|---------|-------------|
| Eligibility_Ratio | Cumulative product of daily withdrawal ratios. Starts at 1.0; each withdrawal reduces it proportionally. Range: [0, 1]. |
| InitialAmount | Copier's initial invested amount at promotion start (from etoroGeneral_History_GuruCopiers) |
| Protected_PnL | Eligible P&L = (TotalAUM - InitialAmount) × Eligibility_Ratio. Negative means copier is in loss; positive means guaranteed gain portion. |
| @EndPromo | 20250101 — after this date the guarantee is expired, but daily rows continue until SP is decommissioned |
| ParentCID 4657429 | GainersQtr PI (Popular Investor) whose copiers are the promotion scope |

## 3. Grain

One row per **CID × Date**. ~257,102 rows = ~710 days × ~362 distinct copiers (estimated).

## 4. Elements

| Column | Type | Description | Tier | Notes |
|--------|------|-------------|------|-------|
| `Date` | date | Report date — previous day's date (ETL date parameter). | Tier 2 | SP-input @Date. |
| `DateID` | int | Integer date key (YYYYMMDD). | Tier 2 | Computed via Dealing_dbo.DateToDateID(@Date). Clustered index key. |
| `CID` | int | Copier's customer ID (RealCID). | Tier 1 | From DWH_dbo.Dim_Customer.RealCID; filtered to GainersQtr PI copiers. |
| `GCID` | int | Group Customer ID — cross-product group identity. | Tier 1 | From DWH_dbo.Dim_Customer.GCID. |
| `Username` | varchar(50) | Copier's login username. | Tier 1 | From DWH_dbo.Dim_Customer.UserName. |
| `ClubLevel` | varchar(50) | Customer club/experience level name (Diamond, Platinum Plus, etc.). | Tier 1 | From DWH_dbo.Dim_PlayerLevel.Name via Dim_Customer.PlayerLevelID. |
| `Country` | varchar(100) | Country of residence. | Tier 1 | From DWH_dbo.Dim_Country.Name via Dim_Customer.CountryID. |
| `Region` | varchar(100) | Geographic region. | Tier 1 | From DWH_dbo.Dim_Country.Region via Dim_Customer.CountryID. |
| `Account_Manager_Name` | varchar(200) | Full name of assigned account manager. | Tier 2 | Concatenated Dim_Manager.FirstName + ' ' + LastName via Dim_Customer.AccountManagerID. |
| `Eligible_Amount` | decimal(18,4) | InitialAmount × Eligibility_Ratio — effective guaranteed principal remaining. | Tier 2 | SP-computed from promotion formula. |
| `Total_AUM` | decimal(18,4) | Copier's current total AUM including same-day fund additions. ROUND(..., 4). | Tier 2 | SP-computed: YesterdaysAUM + AddedFunds (ActionTypeID 15/17). |
| `Eligibility_Ratio` | decimal(18,4) | Cumulative eligibility ratio [0,1]. Reduced each day by withdrawal proportion. | Tier 2 | SP-computed: CurrentRatio × PrevRatio product. |
| `Protected_PnL` | decimal(18,4) | (Total_AUM − InitialAmount) × Eligibility_Ratio — eligible P&L coverage amount. | Tier 2 | SP-computed from promotion formula. |
| `UpdateDate` | datetime | ETL metadata: timestamp when row was last written. | Tier 1 | ETL metadata (blacklist canonical). |

## 5. Common Query Patterns

```sql
-- Current day's guarantee exposure per copier
SELECT CID, Username, ClubLevel, Country,
       Eligible_Amount, Total_AUM, Eligibility_Ratio, Protected_PnL
FROM Dealing_dbo.Dealing_CapitalGuarantee
WHERE Date = CAST(GETDATE()-1 AS date)
ORDER BY Protected_PnL DESC;

-- Total guarantee exposure by date
SELECT Date, SUM(Protected_PnL) AS Total_Protected_PnL, COUNT(*) AS ActiveCopiers
FROM Dealing_dbo.Dealing_CapitalGuarantee
GROUP BY Date
ORDER BY Date DESC;

-- Copiers with significantly reduced eligibility (withdrawals)
SELECT CID, Username, Date, Eligibility_Ratio, Eligible_Amount
FROM Dealing_dbo.Dealing_CapitalGuarantee
WHERE Date = CAST(GETDATE()-1 AS date)
  AND Eligibility_Ratio < 0.5
ORDER BY Eligibility_Ratio;
```

## 6. Data Quality & Caveats

- The promotion expired 2025-01-01 (`@EndPromo = 20250101`) but rows continue to be inserted daily — Protected_PnL after this date is not a live obligation
- `Protected_PnL` can be negative (copier in loss vs. initial amount) — this represents eToro's maximum exposure
- `Eligible_Amount` and `Protected_PnL` are fully SP-computed — no direct production source; depend on accurate AUM snapshot and fund action data
- IsValidCustomer=1 filter applied on final insert — invalid customer records are excluded

## 7. Related Objects

| Object | Relationship |
|--------|-------------|
| `general.etoroGeneral_History_GuruCopiers` | Primary AUM source — copier daily snapshots |
| `DWH_dbo.Fact_CustomerAction` | Fund addition/removal events (ActionTypeID 15/16/17) |
| `DWH_dbo.Dim_Customer` | CID demographics (country, club level, account manager) |

## 8. Operational Notes

- **ETL**: `SP_CapitalGuarantee` runs daily (OpsDB Priority 0, ProcessType 1, ProcessName SB_Daily)
- **Promotion was active**: 2023-09-26 → 2023-11-20 (new copier window); guarantee valid until 2025-01-01
- **Post-promotion rows** (from 2025-01-01 onwards): SP continues running with ratio/AUM mechanics intact but the financial obligation has lapsed
- Decommission this SP when table is retired

---
*Quality score: 8.0/10 — Good promotion mechanics coverage, all columns traced to SP formula. Minor deduction: exact InitialAmount source field from etoroGeneral_History_GuruCopiers not confirmed, post-expiry behavior is inferred.*
