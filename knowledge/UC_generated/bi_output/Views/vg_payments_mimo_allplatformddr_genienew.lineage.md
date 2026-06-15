# Column Lineage: main.bi_output.vg_payments_mimo_allplatformddr_genienew

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_payments_mimo_allplatformddr_genienew` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_payments_mimo_allplatformddr_genienew.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_payments_mimo_allplatformddr_genienew.json` (rows: 14, mismatches: 2) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` |
| **Generated** | 2026-05-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Country.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_FundingType.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_PlayerLevel.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Range.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Regulation.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Views\V_Fact_SnapshotCustomer_FromDateID.md` |
| `main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\eMoney_dbo\Tables\eMoney_Dim_Transaction.md` |
| `main.bi_db.bronze_moneytransfer_billing_transfers` | JOIN / referenced | ✓ `knowledge/ProdSchemas/PaymentsDBs/MoneyTransfer/Wiki/Billing/Tables/Billing.Transfers.md` |

## Lineage Chain

```
main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms   ←── primary upstream
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction   (JOIN)
  + main.bi_db.bronze_moneytransfer_billing_transfers   (JOIN)
        │
        ▼
main.bi_output.vg_payments_mimo_allplatformddr_genienew   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `MIMOAction` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `MIMOAction` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | bddfmap.MIMOAction |
| 2 | `TransactionID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `TransactionID` | `passthrough` | (Tier 2 — Fact_CustomerAction) | bddfmap.TransactionID |
| 3 | `RealCID` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `RealCID` | `passthrough` | (Tier 1 — Customer.CustomerStatic) | bddfmap.RealCID |
| 4 | `MarketingRegionManualName` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `MarketingRegionManualName` | `join_enriched` | (Tier 3 - Ext_Dim_Country live data) | dc.MarketingRegionManualName |
| 5 | `Country` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country` | `Name` | `join_enriched` | (Tier 1 - Dictionary.Country upstream wiki) | dc.Name AS Country |
| 6 | `Club` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.PlayerLevel) | dpl.Name AS Club |
| 7 | `Regulation` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation` | `Name` | `join_enriched` | (Tier 1 - upstream wiki, Dictionary.Regulation) | dr1.Name AS Regulation |
| 8 | `Date_MIMO` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `Date` | `rename` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | bddfmap.Date AS Date_MIMO |
| 9 | `MIMOPlatform` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `MIMOPlatform` | `passthrough` | (Tier 2 — SP_DDR_Fact_Fact_MIMO_AllPlatforms) | bddfmap.MIMOPlatform |
| 10 | `IsInternalTransfer` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsInternalTransfer` | `passthrough` | (Tier 2 — SP_DDR_Fact_MIMO_Trading_Platform) | bddfmap.IsInternalTransfer |
| 11 | `Currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `Currency` | `passthrough` | (Tier 1 — Dictionary.Currency) | bddfmap.Currency |
| 12 | `FundingType` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype / main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `—` | `case` | — | CASE WHEN bddfmap.IsInternalTransfer = 1 THEN 'internal transfer - etoromoney' WHEN bddfmap.MIMOPlatform = 'eMoney' AND bddfmap.IsInternalTr |
| 13 | `IsGlobalFTD` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `IsGlobalFTD` | `passthrough` | (Tier 2 — Function_MIMO_First_Deposit_All_Platforms / SP_DDR_Fact_Fact_MIMO_AllPlatforms) | bddfmap.IsGlobalFTD |
| 14 | `AmountUSD_MIMO` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `AmountUSD` | `rename` | (Tier 2 — Fact_CustomerAction) | bddfmap.AmountUSD AS AmountUSD_MIMO |

## Cross-check vs system.access.column_lineage

- Total target columns: **14**
- OK: **12**, WARN: **1**, ERROR: **1**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `Currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.currency` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.currency`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency.abbreviation` | WARN |
| `FundingType` | — | `main.bi_db.bronze_moneytransfer_billing_transfers.cid`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isinternaltransfer`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.mimoplatform`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype.name` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **5**

## Joins (detected)

- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr1 ON dr1.DWHRegulationID = fsc.RegulationID
- `LEFT JOIN` — LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS dft ON bddfmap.FundingTypeID = dft.FundingTypeID
- `LEFT JOIN` — LEFT JOIN (SELECT mdt.TransactionID, CASE WHEN NOT p.CID IS NULL THEN 'OpenBanking' ELSE 'WireTransfer' END AS Fundingtype_Txtype_7 FROM main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction AS mdt LEFT JOIN main.bi_db.bronze_mon
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
