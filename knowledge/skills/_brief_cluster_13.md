# Cluster 13 brief — `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions`

_Size: 74, intra-cluster weight: 429.0_
_Schema mix: {'BI_DB_CID_MonthlyPanel_FullData': 1, 'BI_DB_dbo': 41, 'DWH_dbo': 7, 'Dealing_dbo': 1, 'Dictionary': 1, 'Dim_Country': 2, 'EXW_dbo': 1, 'bi_db': 1, 'bi_output': 2, 'compliance': 1, 'eMoneyClientBalance': 1, 'eMoney_dbo': 4, 'etoro_kpi': 3, 'etoro_kpi_prep': 2, 'money_farm': 1, 'spaceship': 5}_
_Edge sources: {'wiki': 147, 'genie': 191, 'tableau': 144, 'kpi': 11, 'kpi_prep': 8}_

## Top members (ranked by intra-cluster weight)

- `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions` — w 45.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Revenue_Generating_Actions.md)
- `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status` — w 43.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Customer_Daily_Status.md)
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` — w 41.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_MIMO_AllPlatforms.md)
- `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status` — w 39.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Customer_Periodic_Status.md)
- `BI_DB_dbo.BI_DB_LTV_BI_Actual` — w 38.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_LTV_BI_Actual.md)
- `BI_DB_dbo.BI_DB_CID_MonthlyPanel_FullData` — w 36.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CID_MonthlyPanel_FullData.md)
- `BI_DB_dbo.BI_DB_CID_DailyPanel_FullData` — w 31.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_CID_DailyPanel_FullData.md)
- `BI_DB_dbo.BI_DB_DailyCommisionReport` — w 30.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DailyCommisionReport.md)
- `BI_DB_dbo.BI_DB_DDR_Fact_PnL` — w 28.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_PnL.md)
- `DWH_dbo.Dim_Affiliate` — w 28.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Affiliate.md)
- `bi_db.bronze_sub_accounts_accounts` — w 27.0 (no wiki)
- `BI_DB_dbo.BI_DB_First5Actions` — w 25.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_First5Actions.md)
- `money_farm.silver_moneyfarm_etoro_mf_aum` — w 25.0 (no wiki)
- `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot` — w 24.0 (no wiki)
- `bi_output.bi_output_moneyfarm_fact_transactions` — w 24.0 (no wiki)
- `eMoney_dbo.eMoneyClientBalance` — w 23.0 [wiki](knowledge/synapse/Wiki/eMoney_dbo/Tables/eMoneyClientBalance.md)
- `BI_DB_dbo.BI_DB_DDR_Fact_AUM` — w 22.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_AUM.md)
- `BI_DB_dbo.Dim_Revenue_Metrics` — w 22.0 (no wiki)
- `DWH_dbo.Dim_ActionType` — w 22.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_ActionType.md)
- `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts` — w 22.0 (no wiki)
- `DWH_dbo.Dim_Channel` — w 21.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Channel.md)
- `BI_DB_dbo.BI_DB_DDR_Fact_Trading_Volumes_And_Amounts` — w 19.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_Trading_Volumes_And_Amounts.md)
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_eMoney_Platform` — w 18.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DDR_Fact_MIMO_eMoney_Platform.md)
- `EXW_dbo.EXW_C2F_E2E` — w 16.0 [wiki](knowledge/synapse/Wiki/EXW_dbo/Tables/EXW_C2F_E2E.md)
- `BI_DB_dbo.BI_DB_LTV_Predictions` — w 12.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_LTV_Predictions.md)

## Wiki §3.3 Common JOINs (top members)

### `BI_DB_dbo.BI_DB_DDR_Fact_Revenue_Generating_Actions`

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Dim_InstrumentType` | `ON r.InstrumentTypeID = dit.InstrumentTypeID` | Instrument class name (filter -1) |
| `DWH_dbo.Dim_Customer` | `ON r.RealCID = dc.RealCID` | Customer demographics |
| `BI_DB_dbo.Dim_Revenue_Metrics` | `ON r.RevenueMetricID = drm.RevenueMetricID` | Metric name, category, inclusion rules |
| `DWH_dbo.Dim_ActionType` | `ON r.ActionTypeID = dat.ActionTypeID` | Open/Close/ManualClose action names (filter -1) |

### `BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status`

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID + DateID | AUM per customer for the date |
| BI_DB_dbo.BI_DB_DDR_Fact_PnL | RealCID + DateID | Revenue per customer |
| BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms | RealCID + DateID | MIMO transaction details |
| DWH_dbo.Dim_Customer | RealCID | Extended customer attributes |
| DWH_dbo.Dim_Regulation | RegulationID | Regulation name |
| DWH_dbo.Dim_Country | CountryID | Country details |

### `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms`

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Dim_Customer` | `ON m.RealCID = dc.RealCID` | Customer demographics, registration, country |
| `DWH_dbo.Dim_FundingType` | `ON m.FundingTypeID = dft.FundingTypeID` | Payment method name (Wire, CC, e-Wallet, etc.) |
| `DWH_dbo.Dim_Currency` | `ON m.CurrencyID = dc.CurrencyID` | Full currency details |
| `BI_DB_dbo.BI_DB_DDR_CID_Level` | `ON m.RealCID = cl.RealCID AND m.DateID = cl.DateID` | Full DDR daily picture per customer |

### `BI_DB_dbo.BI_DB_DDR_Customer_Periodic_Status`

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_DDR_Customer_Daily_Status | RealCID + DateID | Daily detail drill-down |
| BI_DB_dbo.BI_DB_DDR_Fact_AUM | RealCID + DateID | AUM for the customer |
| DWH_dbo.Dim_Customer | RealCID | Extended customer attributes |

### `BI_DB_dbo.BI_DB_DDR_Fact_PnL`

| Join To | Join Condition | Purpose |
|---|---|---|
| `DWH_dbo.Dim_InstrumentType` | `ON p.InstrumentTypeID = dit.InstrumentTypeID` | Resolve instrument type names (Stocks, Crypto, ETFs, etc.) |
| `DWH_dbo.Dim_Customer` | `ON p.RealCID = dc.RealCID` | Customer demographics, registration, country |
| `BI_DB_dbo.BI_DB_DDR_CID_Level` | `ON p.RealCID = cl.RealCID AND p.DateID = cl.DateID` | Full DDR daily picture per customer |

### `DWH_dbo.Dim_Affiliate`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Channel | ON SubChannelID = SubChannelID | Channel attributes (but Dim_Affiliate already has SubChannel/Channel) |
| DWH_dbo.Dim_Customer | ON AffiliateID = AffiliateID | Customers referred by this affiliate |
| DWH_dbo.Dim_Country | ON CountryID = CountryID | Affiliate country name |
| DWH_dbo.Fact_AffiliateCommission | ON AffiliateID = AffiliateID | Commission payments |

## KPI views in this cluster

### `etoro_kpi.v_spaceship_aum`  (5585 chars)

Refs:
- `spaceship.bronze_spaceship_metabase_user_beta`
- `member_canonical`
- `spaceship.bronze_spaceship_metabase_super_user_balances`
- `super_bal_raw`
- `super_last_weekday`
- `spaceship.spaceship_metabase_voyager_user_balances`
- `user_id_map`
- `voyager_bal_raw`

### `etoro_kpi.v_spaceship_fees`  (5140 chars)

Refs:
- `spaceship.bronze_spaceship_metabase_user_beta`
- `spaceship.bronze_spaceship_metabase_super_transactions`
- `user_accounts`
- `spaceship.bronze_spaceship_metabase_voyager_account_fees`
- `spaceship.bronze_spaceship_metabase_voyager_management_fees`
- `spaceship.spaceship_metabase_voyager_product_balances`
- `spaceship.bronze_spaceship_metabase_nova_fees`
- `spaceship.bronze_spaceship_metabase_nova_transactions`

### `etoro_kpi.vg_ddr_revenue`  (1061 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_dim_revenue_metrics`
- `bi_output.bi_ouput_v_dim_instrumenttype`

### `etoro_kpi_prep.v_dim_dataplatform_uuid`  (1772 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `bi_db.bronze_sub_accounts_accounts`
- `etoro_kpi.v_spaceship_aum`
- `sps_all`
- `sps_cross`
- `etoro`
- `sps_only`

### `etoro_kpi_prep.v_spaceship_mimo`  (11863 chars)

Refs:
- `spaceship.bronze_spaceship_metabase_user_beta`
- `spaceship.bronze_spaceship_metabase_contact`
- `spaceship.bronze_spaceship_metabase_super_transactions`
- `user_accounts`
- `spaceship.bronze_spaceship_analytics_fct_money_transactions`
- `contact_mapping`
- `spaceship.spaceship_metabase_voyager_user_balances`
- `spaceship.bronze_spaceship_metabase_nova_transactions`

## Genie spaces overlapping this cluster

### `UK BA space [WIP]`  (5/30 tables, 52 join_specs)

Tables in cluster:
- `bi_db.bronze_sub_accounts_accounts`
- `bi_output.bi_output_moneyfarm_fact_portfolio_snapshot`
- `bi_output.bi_output_moneyfarm_fact_transactions`
- `compliance.bronze_event_hub_prod_event_streaming_we_sub_accounts`
- `money_farm.silver_moneyfarm_etoro_mf_aum`

## Out-cluster neighbors (likely bridge candidates)

- `DWH_dbo.Dim_Customer` — outflow weight 81.5
- `DWH_dbo.Dim_Country` — outflow weight 35.0
- `DWH_dbo.Dim_Position` — outflow weight 31.0
- `DWH_dbo.Dim_Instrument` — outflow weight 26.0
- `DWH_dbo.Dim_Regulation` — outflow weight 26.0
- `DWH_dbo.Dim_PlayerLevel` — outflow weight 24.5
- `DWH_dbo.V_Liabilities` — outflow weight 24.0
- `BI_DB_dbo.BI_DB_PositionPnL` — outflow weight 23.0
- `DWH_dbo.Dim_Range` — outflow weight 20.5
- `DWH_dbo.V_Fact_SnapshotCustomer_FromDateID` — outflow weight 20.0
- `DWH_dbo.Dim_Mirror` — outflow weight 19.0
- `BI_DB_dbo.BI_DB_CIDFirstDates` — outflow weight 14.0
- `eMoney_dbo.eMoney_Fact_Transaction_Status` — outflow weight 9.0
- `BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users` — outflow weight 7.0
- `DWH_dbo.Dim_Currency` — outflow weight 6.5
- `BI_DB_dbo.BI_DB_CID_DailyCluster` — outflow weight 6.0
- `BI_DB_dbo.BI_DB_DDR_CID_Level` — outflow weight 6.0
- `Customer.CustomerStatic` — outflow weight 5.0
- `DWH_dbo.Dim_FundingType` — outflow weight 5.0
- `BI_DB_dbo.BI_DB_AllDeposits` — outflow weight 4.0
