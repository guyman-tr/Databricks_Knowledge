# Column Lineage: main.bi_output.bi_ouput_vg_etoro_emoney

| Property | Value |
|----------|-------|
| **UC Object** | `main.bi_output.bi_ouput_vg_etoro_emoney` |
| **Object Type** | `VIEW` |
| **Source** | `knowledge\UC_generated\bi_output\_discovery\source_code\bi_ouput_vg_etoro_emoney.sql` |
| **Column-lineage cache** | `knowledge\UC_generated\bi_output\_discovery\column_lineage\bi_ouput_vg_etoro_emoney.json` (rows: 18, mismatches: 0) |
| **Primary upstream** | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` |
| **Generated** | 2026-05-19 |

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
main.bi_output.bi_ouput_vg_etoro_emoney   ←── this object
```

## Column Lineage

| # | UC Column | Source UC Object | Source Column | Transform | Upstream Tier | Notes |
|---|-----------|------------------|---------------|-----------|---------------|-------|
| 1 | `MIMO_Ind` | `—` | `Ind` | `join_enriched` | — | aa.Ind AS MIMO_Ind |
| 2 | `RealCID` | `—` | `RealCID` | `join_enriched` | — | aa.RealCID |
| 3 | `MarketingRegionManualName` | `—` | `MarketingRegionManualName` | `join_enriched` | — | aa.MarketingRegionManualName |
| 4 | `Country` | `—` | `Country` | `join_enriched` | — | aa.Country |
| 5 | `Club` | `—` | `Club` | `join_enriched` | — | aa.Club |
| 6 | `Regulation` | `—` | `Regulation` | `join_enriched` | — | aa.Regulation |
| 7 | `Date_MIMO` | `—` | `Date_MIMO` | `join_enriched` | — | aa.Date_MIMO |
| 8 | `EOM_MIMO` | `—` | `EOM_MIMO` | `join_enriched` | — | aa.EOM_MIMO |
| 9 | `MIMOPlatform` | `—` | `MIMOPlatform` | `join_enriched` | — | aa.MIMOPlatform |
| 10 | `EOM_FTD` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | LAST_DAY(dc.FirstDepositDate) AS EOM_FTD |
| 11 | `EOM_Reg` | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | `—` | `unknown` | — | LAST_DAY(dc.RegisteredReal) AS EOM_Reg |
| 12 | `IsInternalTransfer` | `—` | `IsInternalTransfer` | `join_enriched` | — | aa.IsInternalTransfer |
| 13 | `IsTradeFromIBAN` | `—` | `IsTradeFromIBAN` | `join_enriched` | — | aa.IsTradeFromIBAN |
| 14 | `Currency` | `—` | `Currency` | `join_enriched` | — | aa.Currency |
| 15 | `MOP` | `—` | `MOP` | `join_enriched` | — | aa.MOP |
| 16 | `IsFTD` | `—` | `IsFTD` | `join_enriched` | — | aa.IsFTD |
| 17 | `AmountUSD_MIMO` | `—` | `AmountUSD` | `join_enriched` | — | aa.AmountUSD AS AmountUSD_MIMO |
| 18 | `Rank_Amount` | `main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | `—` | `window` | — | ROW_NUMBER() OVER (PARTITION BY aa.RealCID ORDER BY AmountUSD DESC) AS Rank_Amount |

## Cross-check vs system.access.column_lineage

- Total target columns: **18**
- OK: **18**, WARN: **0**, ERROR: **0**, INFO: **0**  ✓

## Lost / added columns

- Computed/added columns vs primary: **16**
- Unclassified columns (Phase 5 will treat as Tier 4 / UNVERIFIED): **2**

## Joins (detected)

- `LEFT JOIN` — LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked AS dc ON aa.RealCID = dc.RealCID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range AS dr ON fsc.DateRangeID = dr.DateRangeID AND bddfmap.DateID BETWEEN dr.FromDateID AND dr.ToDateID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country AS dc ON fsc.CountryID = dc.CountryID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency AS dc2 ON bddfmap.CurrencyID = dc2.CurrencyID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel AS dpl ON fsc.PlayerLevelID = dpl.PlayerLevelID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation AS dr1 ON dr1.DWHRegulationID = fsc.RegulationID
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_fundingtype AS dft ON bddfmap.FundingTypeID = dft.FundingTypeID
- `LEFT JOIN` — LEFT JOIN (SELECT mdt.TransactionID, CASE WHEN NOT p.CID IS NULL THEN 'OpenBanking' ELSE 'WireTransfer' END AS Fundingtype_Txtype_7 FROM bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction AS mdt LEFT JOIN bi_db.bronze_moneytransfer
- `INNER INNER` — INNER JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked AS fsc ON bddfmap.RealCID = fsc.RealCID AND fsc.IsValidCustomer = 1
