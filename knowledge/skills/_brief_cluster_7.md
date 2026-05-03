# Cluster 7 brief — `DWH_dbo.Fact_BillingWithdraw`

_Size: 115, intra-cluster weight: 641.5_
_Schema mix: {'AffiliateCommission': 2, 'BI_DB_dbo': 50, 'BI_OUTPUT': 2, 'BackOffice': 1, 'Billing': 7, 'DWH_dbo': 28, 'Dictionary': 14, 'History': 2, 'etoro_kpi_prep': 5, 'etoro_kpi_prep_stg': 4}_
_Edge sources: {'wiki': 622, 'kpi_prep': 18, 'tableau': 3}_

## Top members (ranked by intra-cluster weight)

- `DWH_dbo.Fact_BillingWithdraw` — w 76.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingWithdraw.md)
- `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals` — w 56.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DepositWithdrawFee_Reversals.md)
- `DWH_dbo.Fact_BillingDeposit` — w 55.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_BillingDeposit.md)
- `DWH_dbo.Fact_Cashout_State` — w 52.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Cashout_State.md)
- `Billing.Withdraw` — w 46.0 (no wiki)
- `DWH_dbo.Dim_FundingType` — w 43.5 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_FundingType.md)
- `DWH_dbo.Dim_Currency` — w 34.5 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_Currency.md)
- `DWH_dbo.Fact_Deposit_State` — w 30.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Deposit_State.md)
- `BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates` — w 29.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Operations_Monthly_KPIs_Affiliates.md)
- `BI_DB_dbo.BI_DB_AllDeposits` — w 27.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AllDeposits.md)
- `Billing.BI_Cashout_State_Report` — w 27.0 (no wiki)
- `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction` — w 26.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/Synapse_Table_etoro_History_DepositAction.md)
- `DWH_dbo.Dim_BillingDepot` — w 26.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingDepot.md)
- `DWH_dbo.Fact_Cashout_Rollback` — w 26.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Fact_Cashout_Rollback.md)
- `DWH_dbo.Dim_CashoutStatus` — w 25.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CashoutStatus.md)
- `History.DepositAction` — w 24.0 (no wiki)
- `BI_DB_dbo.BI_DB_DepositWithdrawFee` — w 20.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_DepositWithdrawFee.md)
- `BI_DB_dbo.BI_DB_Withdraw_Rollback_PIPs` — w 20.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Withdraw_Rollback_PIPs.md)
- `BI_DB_dbo.BI_DB_Money_Out_STPAnalysis_OPS_Dashboard` — w 19.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_Money_Out_STPAnalysis_OPS_Dashboard.md)
- `DWH_dbo.Dim_CountryBin` — w 19.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CountryBin.md)
- `DWH_dbo.Dim_BillingProtocolMIDSettingsID` — w 18.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_BillingProtocolMIDSettingsID.md)
- `DWH_dbo.Dim_CardType` — w 18.0 [wiki](knowledge/synapse/Wiki/DWH_dbo/Tables/Dim_CardType.md)
- `BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Aff_data` — w 17.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_AML_Affiliate_Abuse_Aff_data.md)
- `Billing.CashoutRollbackTracking` — w 17.0 (no wiki)
- `BI_DB_dbo.BI_DB_MarketingMonthlyRawData` — w 16.0 [wiki](knowledge/synapse/Wiki/BI_DB_dbo/Tables/BI_DB_MarketingMonthlyRawData.md)

## Wiki §3.3 Common JOINs (top members)

### `BI_DB_dbo.BI_DB_DepositWithdrawFee_Reversals`

| Join To | Join Condition | Purpose |
|---|---|---|
| BI_DB_dbo.BI_DB_DepositWithdrawFee | UNION ALL (same schema) | Combined deposit/withdrawal + reversal analysis |
| DWH_dbo.Dim_Customer | ON CID = RealCID | Additional customer attributes not in snapshot |
| DWH_dbo.Fact_BillingDeposit | ON DepositID | Full deposit details for deposit-side reversals |
| DWH_dbo.Fact_BillingWithdraw | ON WithdrawPaymentID | Full withdrawal details for withdraw-side rollbacks |

### `DWH_dbo.Fact_BillingDeposit`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Customer | ON CID | Customer demographics |
| DWH_dbo.Dim_Date | ON ModificationDateID | Time dimension |
| DWH_dbo.Dim_Currency | ON CurrencyID | Currency name |
| DWH_dbo.Dim_Platform | ON PlatformID | Device/platform |
| DWH_dbo.Dim_ThreeDsResponseTypes | ON TRY_CAST(ThreeDsResponseType AS INT) | 3DS outcome |

### `DWH_dbo.Dim_FundingType`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Fact_BillingDeposit | ON FundingTypeID | Payment method for deposits |
| DWH_dbo.Fact_BillingWithdraw | ON FundingTypeID_Withdraw / FundingTypeID_Funding | Payment method for withdrawals |
| DWH_dbo.Fact_CustomerAction | ON FundingTypeID | Payment method for customer financial actions |

### `DWH_dbo.Dim_Currency`

| Join To | Join Condition | Purpose |
|---|---|---|
| All DWH fact tables | ON f.CurrencyID = d.CurrencyID | Decode instrument for any trade/position/cost fact |
| DWH_dbo.Dim_Country | ON c.DefaultCurrencyID = d.CurrencyID | Default account currency per country [UNVERIFIED - DefaultCurrencyID dropped fro |

### `DWH_dbo.Fact_Deposit_State`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_Currency | ON f.CurrencyID = dc.CurrencyID | Resolve currency name (EUR, USD, GBP...) |
| DWH_dbo.Dim_BillingDepot | ON f.DepotID = db.DepotID | Resolve payment gateway/depot name |
| DWH_dbo.Dim_PaymentStatus | ON f.PaymentStatusID = dps.PaymentStatusID | Resolve payment status name |
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON f.ProtocolMIDSettingsID = dp.ProtocolMIDSettingsID | Resolve protocol MID settings |

### `BI_DB_dbo.BI_DB_Operations_Monthly_KPIs_Affiliates`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_FundingType | FundingTypeID = FundingTypeID | Decode payment method name |
| DWH_dbo.Dim_CashoutReason | CashoutReasonID = CashoutReasonID | Decode withdrawal reason label |
| DWH_dbo.Dim_Customer | CID = RealCID | Customer profile attributes |
| DWH_dbo.Fact_BillingWithdraw | WithdrawID = WithdrawID | Drill to full withdrawal detail |

### `BI_DB_dbo.Synapse_Table_etoro_History_DepositAction`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Fact_BillingDeposit | DepositID = DepositID | Match deposit actions to billing deposit records |
| External_etoro_Dictionary_Response | ResponseID = ResponseID | Resolve ResponseID to ResponseName |

### `DWH_dbo.Dim_BillingDepot`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Dim_BillingProtocolMIDSettingsID | ON DepotID | MID configuration per depot |
| Fact tables (deposit/cashout) | ON DepotID | Resolve depot name and attributes for transactions |

### `DWH_dbo.Fact_Cashout_Rollback`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Fact_Cashout_State | ON CID and WithdrawID | Correlate rollbacks with original cashout processing events |
| DWH_dbo.Fact_BillingWithdraw | ON WithdrawID | Join to the full withdrawal request fact for additional context |
| DWH_dbo.Dim_Customer | ON CID | Resolve customer demographics, regulation, label |
| DWH_dbo.Dim_Currency | ON Currency | Join for additional currency attributes if needed |

### `DWH_dbo.Dim_CashoutStatus`

| Join To | Join Condition | Purpose |
|---|---|---|
| DWH_dbo.Fact_Cashout_State (planned) | ON CashoutStatusID | Decode status for each cashout event |
| DWH_dbo.Fact_BillingWithdraw (planned) | ON CashoutStatusID | Decode withdrawal status |

## KPI views in this cluster

### `etoro_kpi_prep.v_mimo_allplatforms`  (3385 chars)

Refs:
- `etoro_kpi_prep.v_mimo_first_deposit_all_platforms`
- `etoro_kpi_prep.v_mimo_tradingplatform`
- `etoro_kpi_prep.v_mimo_emoneyplatform`
- `etoro_kpi_prep.v_mimo_optionsplatform`
- `global_ftds`
- `tp_mimo`
- `emoney_mimo`
- `options_mimo`

### `etoro_kpi_prep.v_mimo_emoneyplatform`  (3911 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`
- `ftd_iban`
- `deposits_iban`
- `cashout_iban`
- `mimo_iban_prep`
- `mimo_iban_deduped`

### `etoro_kpi_prep.v_mimo_first_deposit_all_platforms`  (3749 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`
- `emoney.bronze_fiatdwhdb_dbo_fiattransactions`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `new_iban`
- `new_tp`
- `c2usd`

### `etoro_kpi_prep.v_mimo_optionsplatform`  (4988 chars)

Refs:
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `MIMORecords`
- `DEPOSIT_UNIQUE_FOR_FTDJOIN`
- `FINRAONLY_ftd_date`
- `FINRAONLY_FTD_records`
- `FTDSingle`

### `etoro_kpi_prep.v_mimo_tradingplatform`  (3804 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`
- `deposits_tp`
- `cashout_tp`

### `etoro_kpi_prep_stg.v_ddr_mimo_allplatforms`  (4555 chars)

Refs:
- `etoro_kpi_prep_stg.v_dim_dataplatform_uuid`
- `etoro_kpi_prep_stg.v_ddr_mimo_tradingplatform`
- `xw`
- `etoro_kpi_prep_stg.v_ddr_mimo_emoney`
- `etoro_kpi_prep_stg.v_ddr_mimo_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`

### `etoro_kpi_prep_stg.v_ddr_mimo_emoney`  (4187 chars)

Refs:
- `bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_fact_transaction_status`
- `base`
- `fx_daily`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`
- `fx_latest`
- `ftd_iban`
- `enriched`

### `etoro_kpi_prep_stg.v_ddr_mimo_options`  (3811 chars)

Refs:
- `finance.bronze_sodreconciliation_apex_ext869_cashactivity`
- `general.bronze_usabroker_apex_options`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `mimo_records`
- `deposit_unique`
- `finra_ftd_date`
- `finra_ftd_records`
- `ftd_single`

### `etoro_kpi_prep_stg.v_ddr_mimo_tradingplatform`  (5449 chars)

Refs:
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_currency`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked`
- `dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw`
- `bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee`
- `deposits`
- `cashouts`

## Genie spaces overlapping this cluster

## Out-cluster neighbors (likely bridge candidates)

- `DWH_dbo.Dim_Customer` — outflow weight 83.0
- `DWH_dbo.Dim_Country` — outflow weight 35.0
- `DWH_dbo.Dim_Regulation` — outflow weight 24.0
- `DWH_dbo.Fact_CustomerAction` — outflow weight 14.0
- `DWH_dbo.Dim_Affiliate` — outflow weight 14.0
- `DWH_dbo.Fact_SnapshotCustomer` — outflow weight 14.0
- `DWH_dbo.Dim_PlayerLevel` — outflow weight 13.0
- `Dictionary.Currency` — outflow weight 13.0
- `DWH_dbo.Dim_Date` — outflow weight 12.0
- `BI_DB_dbo.BI_DB_DDR_Fact_MIMO_AllPlatforms` — outflow weight 12.0
- `BI_DB_dbo.BI_DB_AML_Affiliate_Abuse_Users` — outflow weight 10.0
- `BI_DB_dbo.BI_DB_EY_Audit_BO_Deposits_With_PIPs` — outflow weight 10.0
- `DWH_dbo.Dim_Position` — outflow weight 9.0
- `Billing.Deposit` — outflow weight 6.0
- `BI_DB_dbo.BI_DB_AML_SAR_Report_FCA` — outflow weight 5.0
- `DWH_dbo.V_Liabilities` — outflow weight 5.0
- `Customer.CustomerStatic` — outflow weight 5.0
- `DWH_dbo.Dim_Manager` — outflow weight 4.0
- `BI_DB_dbo.BI_DB_ClubUsersDataRemarketingGoogle` — outflow weight 4.0
- `BI_DB_dbo.BI_DB_CIDFunnelFlow` — outflow weight 4.0
