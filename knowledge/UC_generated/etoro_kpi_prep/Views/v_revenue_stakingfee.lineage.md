# Column Lineage: main.etoro_kpi_prep.v_revenue_stakingfee

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_stakingfee` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_stakingfee.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_stakingfee.json` (rows: 22, mismatches: 10) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Instrument.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\Dealing_dbo\Tables\Dealing_Staking_Results.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_stakingfee   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `StakingMonthID` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `unknown` | — | LEFT(CAST(dss.StakingMonthID AS STRING), 6) AS StakingMonthID |
| 2 | `Date` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `unknown` | — | ADD_MONTHS(dss.UpdateDate, -1) AS Date |
| 3 | `DateID` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(ADD_MONTHS(dss.UpdateDate, -1) AS DATE), 'yyyyMMdd') AS INT) AS DateID |
| 4 | `StakingMonth` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `StakingMonth` | `passthrough` | — | dss.StakingMonth |
| 5 | `StakingYear` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `StakingYear` | `passthrough` | — | dss.StakingYear |
| 6 | `InstrumentID` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `InstrumentID` | `passthrough` | — | dss.InstrumentID |
| 7 | `Instrument` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument` | `Name` | `join_enriched` | (Tier 1 — Trade.GetInstrument) | di.Name AS Instrument |
| 8 | `CID` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `CID` | `passthrough` | — | dss.CID |
| 9 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GCID |
| 10 | `IsEligible` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `IsEligible` | `passthrough` | — | dss.IsEligible |
| 11 | `NonEligible_PrimaryReason` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `NonEligible_PrimaryReason` | `passthrough` | — | dss.NonEligible_PrimaryReason |
| 12 | `IneligibleCustomerRewards` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `case` | — | CASE WHEN dss.IsEligible = 0 THEN dss.Etoro_Amount ELSE 0 END AS IneligibleCustomerRewards |
| 13 | `RevShareCommission` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `case` | — | CASE WHEN dss.IsEligible = 1 THEN dss.Etoro_Amount ELSE 0 END AS RevShareCommission |
| 14 | `ClientPercent` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `arithmetic` | — | dss.Client_Airdrop / NULLIF(dss.Client_Airdrop + dss.Etoro_Amount, 0) AS ClientPercent |
| 15 | `EtoroPercent` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `arithmetic` | — | dss.Etoro_Amount / NULLIF(dss.Client_Airdrop + dss.Etoro_Amount, 0) AS EtoroPercent |
| 16 | `ClientUSDDistributed` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `case` | — | CASE WHEN dss.IsEligible = 1 THEN dss.USD_Compensation ELSE 0 END AS ClientUSDDistributed |
| 17 | `EtoroUSDDistributed` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `Etoro_Amount_USD` | `rename` | — | dss.Etoro_Amount_USD AS EtoroUSDDistributed |
| 18 | `TotalUSDDistributed` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `arithmetic` | — | CASE WHEN dss.IsEligible = 1 THEN dss.USD_Compensation ELSE 0 END + dss.Etoro_Amount_USD AS TotalUSDDistributed |
| 19 | `AirDropDateID` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(dss.AirdropOccurred AS DATE), 'yyyyMMdd') AS INT) AS AirDropDateID |
| 20 | `ActualCompensationType` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `ActualCompensationType` | `passthrough` | — | dss.ActualCompensationType |
| 21 | `ClubCategory` | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | `ClubCategory` | `passthrough` | — | dss.ClubCategory |
| 22 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **22**
- OK: **12**, WARN: **0**, ERROR: **10**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `StakingMonthID` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.stakingmonthid` | ERROR |
| `Date` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.updatedate` | ERROR |
| `DateID` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.updatedate` | ERROR |
| `IneligibleCustomerRewards` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.etoro_amount`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.iseligible` | ERROR |
| `RevShareCommission` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.etoro_amount`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.iseligible` | ERROR |
| `ClientPercent` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.client_airdrop`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.etoro_amount` | ERROR |
| `EtoroPercent` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.client_airdrop`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.etoro_amount` | ERROR |
| `ClientUSDDistributed` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.iseligible`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.usd_compensation` | ERROR |
| `TotalUSDDistributed` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.etoro_amount_usd`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.iseligible`, `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.usd_compensation` | ERROR |
| `AirDropDateID` | — | `main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results.airdropoccurred` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **9**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **4**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_instrument AS di ON dss.InstrumentID = di.InstrumentID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON dss.CID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND CAST(DATE_FORMAT(CAST(LAST_DAY(ADD_MONTHS(dss.UpdateDate, -1)) AS DATE), 'yyyyMMdd') AS INT) BETWEEN dr.FromDateID AND dr.ToDateID
