# Column Lineage: main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f

| Property | Value |
|----------|-------|
| **UC Object** | `main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\source_code\v_revenue_cryptotofiat_c2f.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\etoro_kpi_prep\_discovery\column_lineage\v_revenue_cryptotofiat_c2f.json` (rows: 16, mismatches: 2) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\EXW_dbo\Tables\EXW_C2F_E2E.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
        │
        ▼
main.etoro_kpi_prep.v_revenue_cryptotofiat_c2f   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `RealCID` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.RealCID |
| 2 | `GCID` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `GCID` | `join_enriched` | (Tier 1 — inherited from Fact_SnapshotCustomer wiki) | fsc.GCID |
| 3 | `LastModificationDate` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `—` | `unknown` | — | GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDateTime) AS LastModif |
| 4 | `LastModificationDateID` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `—` | `unknown` | — | CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransaction |
| 5 | `TotalFeePercentage` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `TotalFeePercentage` | `passthrough` | (Tier 1 — C2F.Conversions) | ecfee.TotalFeePercentage |
| 6 | `TotalFeeUSD` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `TotalFeeUSD` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.TotalFeeUSD |
| 7 | `FiatAmount` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `FiatAmount` | `passthrough` | (Tier 1 — C2F.FiatTransactions) | ecfee.FiatAmount |
| 8 | `CryptoAmount` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `CryptoAmount` | `passthrough` | (Tier 1 — C2F.Conversions) | ecfee.CryptoAmount |
| 9 | `FiatCurrency` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `FiatCurrency` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.FiatCurrency |
| 10 | `UsdAmount` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `UsdAmount` | `passthrough` | (Tier 1 — C2F.FiatTransactions) | ecfee.UsdAmount |
| 11 | `Crypto` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `Crypto` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.Crypto |
| 12 | `TargetPlatformID` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `TargetPlatformID` | `passthrough` | (Tier 1 — C2F.Conversions) | ecfee.TargetPlatformID |
| 13 | `TargetPlatform` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `TargetPlatform` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.TargetPlatform |
| 14 | `DepositID` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `DepositID` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.DepositID |
| 15 | `eMoneyTransactionID` | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | `eMoneyTransactionID` | `passthrough` | (Tier 2 — SP_EXW_C2F_E2E) | ecfee.eMoneyTransactionID |
| 16 | `IsValidCustomer` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | `IsValidCustomer` | `join_enriched` | — | fsc.IsValidCustomer |

## Cross-check vs system.access.column_lineage

- Total target columns: **16**
- OK: **14**, WARN: **0**, ERROR: **2**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `LastModificationDate` | — | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.conversiondatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.conversionstatusdatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.cryptotransactiondatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.emoneylaststatustime` | ERROR |
| `LastModificationDateID` | — | `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.conversiondatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.conversionstatusdatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.cryptotransactiondatetime`, `main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e.emoneylaststatustime` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **2**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON ecfee.RealCID = fsc.RealCID
- `INNER JOIN` — JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND CAST(DATE_FORMAT(CAST(GREATEST(ecfee.eMoneyLastStatusTime, ecfee.ConversionDateTime, ecfee.ConversionStatusDateTime, ecfee.CryptoTransactionDa
