# Column Lineage: main.bi_output.vg_payments_mimo_basedonddrallplatfrommimo_for_genie

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.vg_payments_mimo_basedonddrallplatfrommimo_for_genie` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\vg_payments_mimo_basedonddrallplatfrommimo_for_genie.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\vg_payments_mimo_basedonddrallplatfrommimo_for_genie.json` (rows: 19, mismatches: 18) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` |
| **Generated** | 2026-06-19 |

## Upstream Objects

| Upstream UC Object | Role | Upstream Wiki |
|--------------------|------|---------------|
| `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | Primary (FROM) | ✓ `knowledge\synapse\Wiki\BI_DB_dbo\Tables\BI_DB_DDR_Fact_MIMO_AllPlatforms.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Customer.md` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency` | JOIN / referenced | ✓ `knowledge\synapse\Wiki\DWH_dbo\Tables\Dim_Currency.md` |
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
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation   (JOIN)
  + main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype   (JOIN)
  + main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction   (JOIN)
  + main.bi_db.bronze_moneytransfer_billing_transfers   (JOIN)
        │
        ▼
main.bi_output.vg_payments_mimo_basedonddrallplatfrommimo_for_genie   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `MIMO_Ind` | `—` | `Ind` | `join_enriched` | — | aa.Ind AS MIMO_Ind |
| 2 | `TransactionID` | `—` | `TransactionID` | `join_enriched` | — | aa.TransactionID |
| 3 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | aa.RealCID |
| 4 | `MarketingRegionManualName` | `—` | `MarketingRegionManualName` | `join_enriched` | — | aa.MarketingRegionManualName |
| 5 | `Country` | `—` | `Country` | `join_enriched` | — | aa.Country |
| 6 | `Club` | `—` | `Club` | `join_enriched` | — | aa.Club |
| 7 | `Regulation` | `—` | `Regulation` | `join_enriched` | — | aa.Regulation |
| 8 | `Date_MIMO` | `—` | `Date_MIMO` | `join_enriched` | — | aa.Date_MIMO |
| 9 | `EOM_MIMO` | `—` | `EOM_MIMO` | `join_enriched` | — | aa.EOM_MIMO |
| 10 | `MIMOPlatform` | `—` | `MIMOPlatform` | `join_enriched` | — | aa.MIMOPlatform |
| 11 | `EOM_FTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | LAST_DAY(dc.FirstDepositDate) AS EOM_FTD |
| 12 | `EOM_Reg` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | LAST_DAY(dc.RegisteredReal) AS EOM_Reg |
| 13 | `IsInternalTransfer` | `—` | `IsInternalTransfer` | `join_enriched` | — | aa.IsInternalTransfer |
| 14 | `IsTradeFromIBAN` | `—` | `IsTradeFromIBAN` | `join_enriched` | — | aa.IsTradeFromIBAN |
| 15 | `Currency` | `—` | `Currency` | `join_enriched` | — | aa.Currency |
| 16 | `MOP` | `—` | `MOP` | `join_enriched` | — | aa.MOP |
| 17 | `IsFTD` | `—` | `IsFTD` | `join_enriched` | — | aa.IsFTD |
| 18 | `AmountUSD_MIMO` | `—` | `AmountUSD` | `join_enriched` | — | aa.AmountUSD AS AmountUSD_MIMO |
| 19 | `Rank_Amount` | `—` | `—` | `window` | — | ROW_NUMBER() OVER (PARTITION BY aa.RealCID ORDER BY aa.AmountUSD DESC) AS Rank_Amount |

## Cross-check vs system.access.column_lineage

- Total target columns: **19**
- OK: **1**, WARN: **0**, ERROR: **18**, INFO: **0**  ⚠

| Target | Parsed | Runtime | Severity |
|--------|--------|---------|----------|
| `TransactionID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.transactionid` | ERROR |
| `RealCID` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.realcid` | ERROR |
| `MarketingRegionManualName` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country.marketingregionmanualname` | ERROR |
| `Country` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country.name` | ERROR |
| `Club` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel.name` | ERROR |
| `Regulation` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation.name` | ERROR |
| `Date_MIMO` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.date` | ERROR |
| `EOM_MIMO` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.date` | ERROR |
| `MIMOPlatform` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.mimoplatform` | ERROR |
| `EOM_FTD` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.firstdepositdate` | ERROR |
| `EOM_Reg` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked.registeredreal` | ERROR |
| `IsInternalTransfer` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isinternaltransfer` | ERROR |
| `IsTradeFromIBAN` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.istradefromiban` | ERROR |
| `Currency` | — | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency.abbreviation` | ERROR |
| `MOP` | — | `main.bi_db.bronze_moneytransfer_billing_transfers.cid`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isinternaltransfer`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.istradefromiban`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.mimoplatform`, `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype.name` | ERROR |
| `IsFTD` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.isplatformftd` | ERROR |
| `AmountUSD_MIMO` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.amountusd` | ERROR |
| `Rank_Amount` | — | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.amountusd`, `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms.realcid` | ERROR |

## Lost / added columns

- Computed/added columns vs primary: **17**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON aa.RealCID = dc.RealCID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc2 ON bddfmap.CurrencyID = dc2.CurrencyID
- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr1 ON dr1.DWHRegulationID = fsc.RegulationID
- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS dft ON bddfmap.FundingTypeID = dft.FundingTypeID
- `LEFT JOIN` — LEFT JOIN (SELECT mdt.TransactionID, CASE WHEN NOT p.CID IS NULL THEN 'OpenBanking' ELSE 'WireTransfer' END AS Fundingtype_Txtype_7 FROM bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction AS mdt LEFT JOIN bi_db.bronze_moneytransfer
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
