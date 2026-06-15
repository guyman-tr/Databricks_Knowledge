# Routing Inventory - Corpus-Wide Scan

Generated: 2026-06-14T17:32:11.606571Z

## Corpus stats

- Hubs in scope: **16**
- Files scanned (with frontmatter): **89**
- Files scanned total: 96
- Files without frontmatter (skipped): 7
- Total trigger entries (raw): **4271**
- Distinct normalized concepts (triggers + required_tables + sample_questions): **4415**
- Concepts claimed by >=2 hubs (unmanaged overlap candidates): **85** (1.9% of all concepts)
- Substring overlap rows (matcher-false-positive candidates): **85**

## Per-hub stats

| Hub | Files | Triggers | Required tables | Sample questions |
|---|---:|---:|---:|---:|
| `cross-cutting` | 4 | 101 | 5 | 11 |
| `domain-aum-and-aua` | 1 | 28 | 4 | 0 |
| `domain-compliance-and-aml` | 4 | 207 | 53 | 42 |
| `domain-cross` | 5 | 103 | 54 | 32 |
| `domain-customer-and-identity` | 9 | 474 | 99 | 84 |
| `domain-exw-wallet` | 1 | 72 | 23 | 0 |
| `domain-marketing-and-acquisition` | 5 | 815 | 82 | 67 |
| `domain-moneyfarm` | 6 | 153 | 64 | 32 |
| `domain-ops-and-onboarding` | 4 | 332 | 47 | 57 |
| `domain-options` | 6 | 191 | 47 | 30 |
| `domain-payments` | 6 | 173 | 109 | 63 |
| `domain-product-analytics` | 4 | 301 | 57 | 65 |
| `domain-revenue-and-fees` | 9 | 231 | 84 | 0 |
| `domain-spaceship` | 6 | 163 | 44 | 25 |
| `domain-staking` | 6 | 346 | 24 | 16 |
| `domain-trading` | 13 | 581 | 86 | 16 |

## Top overlap candidates - concepts claimed by >=2 hubs

Sorted by hub-count desc, then alphabetic. Top 60 shown; full list in concepts.csv.

| Concept (normalized) | Hubs | Claiming hubs | Source fields | Variants |
|---|---:|---|---|---|
| `main de_output de_output_etoro_kpi_fact_customeraction_w_metrics` | 5 | domain-cross, domain-customer-and-identity, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | 5 | cross-cutting, domain-cross, domain-customer-and-identity, domain-moneyfarm, domain-options | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | 5 | domain-cross, domain-customer-and-identity, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | 4 | cross-cutting, domain-aum-and-aua, domain-payments, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | 4 | domain-payments, domain-revenue-and-fees, domain-staking, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions |
| `main etoro_kpi_prep v_moneyfarm_aum` | 4 | cross-cutting, domain-aum-and-aua, domain-moneyfarm, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_moneyfarm_aum |
| `main finance bronze_sodreconciliation_apex_ext1047_revenuereports` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports |
| `main finance bronze_sodreconciliation_apex_ext869_cashactivity` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext869_cashactivity |
| `main finance bronze_sodreconciliation_apex_ext872_tradeactivity` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity |
| `main finance bronze_sodreconciliation_apex_sodfiles` | 4 | domain-cross, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.finance.bronze_sodreconciliation_apex_sodfiles |
| `main general bronze_sodreconciliation_apex_ext981_buypowersummary` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.general.bronze_sodreconciliation_apex_ext981_buypowersummary |
| `main general bronze_usabroker_apex_options` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.general.bronze_usabroker_apex_options |
| `main bi_db bronze_sub_accounts_accounts` | 3 | domain-moneyfarm, domain-revenue-and-fees, domain-spaceship | required_tables | main.bi_db.bronze_sub_accounts_accounts |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_depositwithdrawfee_reversals |
| `main bi_db gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e` | 3 | domain-cross, domain-exw-wallet, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_c2f_e2e |
| `main bi_db gold_sql_dp_prod_we_exw_dbo_exw_dimuser` | 3 | domain-customer-and-identity, domain-exw-wallet, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_dimuser |
| `main bi_db gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew` | 3 | domain-aum-and-aua, domain-exw-wallet, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_financereportsbalancesnew |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit` | 3 | domain-moneyfarm, domain-spaceship, domain-trading | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_currencypricewithsplit |
| `main etoro_kpi v_spaceship_aum` | 3 | cross-cutting, domain-aum-and-aua, domain-revenue-and-fees | required_tables | main.etoro_kpi.v_spaceship_aum |
| `main etoro_kpi_prep v_mimo_options_platform` | 3 | domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_mimo_options_platform |
| `main etoro_kpi_prep v_options_aum` | 3 | domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_options_aum |
| `main finance bronze_sodreconciliation_apex_ext870_stockactivity` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext870_stockactivity |
| `main finance bronze_sodreconciliation_apex_ext922_dividendreport` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext922_dividendreport |
| `main wallet bronze_walletdb_wallet_conversions` | 3 | domain-cross, domain-exw-wallet, domain-payments | required_tables | main.wallet.bronze_walletdb_wallet_conversions |
| `main wallet bronze_walletdb_wallet_customerwalletsview` | 3 | domain-cross, domain-exw-wallet, domain-payments | required_tables | main.wallet.bronze_walletdb_wallet_customerwalletsview |
| `main wallet bronze_walletdb_wallet_receivedtransactions` | 3 | domain-cross, domain-exw-wallet, domain-payments | required_tables | main.wallet.bronze_walletdb_wallet_receivedtransactions |
| `main wallet bronze_walletdb_wallet_senttransactions` | 3 | domain-cross, domain-exw-wallet, domain-payments | required_tables | main.wallet.bronze_walletdb_wallet_senttransactions |
| `audit trail` | 2 | domain-cross, domain-customer-and-identity | triggers | audit trail |
| `is_ftd` | 2 | domain-moneyfarm, domain-spaceship | triggers | is_ftd |
| `is_funded` | 2 | domain-moneyfarm, domain-spaceship | triggers | is_funded |
| `is_internal_transfer` | 2 | domain-options, domain-spaceship | triggers | is_internal_transfer |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview` | 2 | domain-compliance-and-aml, domain-customer-and-identity | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status` | 2 | domain-customer-and-identity, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_daily_status |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status` | 2 | domain-customer-and-identity, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_customer_periodic_status |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms` | 2 | domain-cross, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_mimo_allplatforms |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl` | 2 | domain-payments, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_pnl |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts` | 2 | domain-payments, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_trading_volumes_and_amounts |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions` | 2 | domain-cross, domain-customer-and-identity | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_first5actions |
| `main bi_db gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results` | 2 | domain-revenue-and-fees, domain-staking | required_tables | main.bi_db.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_results |
| `main bi_db gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account` | 2 | domain-cross, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_account |
| `main bi_db gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction` | 2 | domain-cross, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_emoney_dbo_emoney_dim_transaction |
| `main bi_db gold_sql_dp_prod_we_exw_dbo_exw_facttransactions` | 2 | domain-exw-wallet, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_facttransactions |
| `main bi_db gold_sql_dp_prod_we_exw_dbo_exw_walletinventory` | 2 | domain-exw-wallet, domain-payments | required_tables | main.bi_db.gold_sql_dp_prod_we_exw_dbo_exw_walletinventory |
| `main bi_output bi_output_moneyfarm_customers` | 2 | domain-moneyfarm, domain-revenue-and-fees | required_tables | main.bi_output.bi_output_moneyfarm_customers |
| `main bi_output bi_output_moneyfarm_fact_portfolio_snapshot` | 2 | domain-moneyfarm, domain-revenue-and-fees | required_tables | main.bi_output.bi_output_moneyfarm_fact_portfolio_snapshot |
| `main bi_output bi_output_moneyfarm_fact_transactions` | 2 | domain-moneyfarm, domain-revenue-and-fees | required_tables | main.bi_output.bi_output_moneyfarm_fact_transactions |
| `main compliance bronze_userapidb_history_customeranswers` | 2 | domain-compliance-and-aml, domain-customer-and-identity | required_tables | main.compliance.bronze_userapidb_history_customeranswers |
| `main dealing gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings` | 2 | domain-revenue-and-fees, domain-trading | required_tables | main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_holdings |
| `main dealing gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity` | 2 | domain-revenue-and-fees, domain-trading | required_tables | main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_apexrecon_tradeactivity |
| `main dealing gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary` | 2 | domain-revenue-and-fees, domain-staking | required_tables | main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_staking_summary |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_dim_actiontype` | 2 | domain-cross, domain-customer-and-identity | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_actiontype |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus` | 2 | domain-cross, domain-payments | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_paymentstatus |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit` | 2 | domain-cross, domain-payments | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw` | 2 | domain-cross, domain-payments | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingwithdraw |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked` | 2 | cross-cutting, domain-customer-and-identity | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked |
| `main etoro_kpi_prep v_fact_customeraction_w_metrics` | 2 | domain-customer-and-identity, domain-trading | required_tables | main.etoro_kpi_prep.v_fact_customeraction_w_metrics |
| `main etoro_kpi_prep v_mimo_optionsplatform` | 2 | domain-options, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_mimo_optionsplatform |
| `main etoro_kpi_prep v_moneyfarm_fees` | 2 | domain-moneyfarm, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_moneyfarm_fees |
| `main etoro_kpi_prep v_moneyfarm_mimo` | 2 | domain-moneyfarm, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_moneyfarm_mimo |

## Substring overlap - top 40

Multi-word concepts that contain another claimed concept as a sub-span, where the sub-concept is claimed by a hub the long concept is NOT on. These are the false-positive vectors when a matcher does substring / n-gram matching.

| Long concept | Long hub(s) | Sub-concept (exposed) | Sub hub(s) | Foreign hub(s) |
|---|---|---|---|---|
| `what is our aum as of today` | cross-cutting | `what is our aum` | domain-aum-and-aua | domain-aum-and-aua |
| `moneyfarm aum today` | cross-cutting | `moneyfarm aum` | domain-moneyfarm | domain-moneyfarm |
| `customer balance for date x where x has no data yet` | cross-cutting | `customer balance` | domain-payments | domain-payments |
| `client balance valid` | cross-cutting | `client balance` | domain-payments | domain-payments |
| `total trading revenue ytd` | cross-cutting | `trading revenue` | domain-revenue-and-fees | domain-revenue-and-fees |
| `net deposits last month by country` | cross-cutting | `net deposits` | domain-payments | domain-payments |
| `non-custodial wallet aum` | domain-aum-and-aua | `non-custodial wallet` | domain-exw-wallet | domain-exw-wallet |
| `non-custodial wallet aum` | domain-aum-and-aua | `wallet aum` | domain-exw-wallet | domain-exw-wallet |
| `etoro wallet aum` | domain-aum-and-aua | `etoro wallet` | domain-exw-wallet | domain-exw-wallet |
| `etoro wallet aum` | domain-aum-and-aua | `wallet aum` | domain-exw-wallet | domain-exw-wallet |
| `on-chain crypto aum` | domain-aum-and-aua | `crypto aum` | domain-exw-wallet | domain-exw-wallet |
| `time-series of risk level for partykey x aml_riskscore_scd scd-2 walk` | domain-compliance-and-aml | `scd-2 walk` | cross-cutting | cross-cutting |
| `first time funded to first trade` | domain-cross | `first time funded` | domain-customer-and-identity | domain-customer-and-identity |
| `operator action audit` | domain-cross | `action audit` | domain-customer-and-identity | domain-customer-and-identity |
| `who authorized transaction x audit trail for one emoney transaction` | domain-cross | `audit trail` | domain-cross; domain-customer-and-identity | domain-customer-and-identity |
| `audit trail for accountid y over a date window` | domain-cross | `audit trail` | domain-cross; domain-customer-and-identity | domain-customer-and-identity |
| `which positions did this customer open via copy trading` | domain-customer-and-identity | `copy trading` | domain-trading | domain-trading |
| `per-day per-popular-investor copy-trading revenue split by asset class` | domain-customer-and-identity | `by asset class` | domain-trading | domain-trading |
| `popular investor program` | domain-customer-and-identity | `popular investor` | domain-trading | domain-trading |
| `crypto wallet user` | domain-customer-and-identity | `crypto wallet` | domain-exw-wallet | domain-exw-wallet |
| `live acquisition funnel for today by channel country` | domain-marketing-and-acquisition | `acquisition funnel` | domain-payments | domain-payments |
| `customer user id` | domain-marketing-and-acquisition | `user id` | domain-customer-and-identity | domain-customer-and-identity |
| `what s the open rate on leadwelcomejourney emails last month` | domain-marketing-and-acquisition | `open rate` | domain-trading | domain-trading |
| `how many popular investor raf referrals referringispi 1 succeeded last year` | domain-marketing-and-acquisition | `popular investor` | domain-trading | domain-trading |
| `loyalty offer redemption rate by club tier` | domain-marketing-and-acquisition | `club tier` | domain-customer-and-identity | domain-customer-and-identity |
| `top 5 sfmc subject lines by unique open rate in marketcampaigns last month` | domain-marketing-and-acquisition | `open rate` | domain-trading | domain-trading |
| `isa focussed acquisition funnel` | domain-moneyfarm | `acquisition funnel` | domain-payments | domain-payments |
| `what is the moneyfarm ftd definition` | domain-moneyfarm | `ftd definition` | domain-spaceship | domain-spaceship |
| `moneyfarm acquisition funnel` | domain-moneyfarm | `acquisition funnel` | domain-payments | domain-payments |
| `show me poa rejection rate by country in last 30 days` | domain-ops-and-onboarding | `rejection rate` | domain-trading | domain-trading |
| `how long did it take customer x to reach verification level 3` | domain-ops-and-onboarding | `verification level` | domain-marketing-and-acquisition | domain-marketing-and-acquisition |
| `us acquisition funnel` | domain-options | `acquisition funnel` | domain-payments | domain-payments |
| `what s the freshness-checker query for apex sod files` | domain-options | `apex sod` | domain-cross | domain-cross |
| `what s the freshness-checker query for apex sod files` | domain-options | `sod files` | domain-trading | domain-trading |
| `apex sod freshness query` | domain-options | `apex sod` | domain-cross | domain-cross |
| `how do i check apex sod freshness` | domain-options | `apex sod` | domain-cross | domain-cross |
| `local ftd vs global ftd` | domain-options | `global ftd` | domain-payments | domain-payments |
| `usabroker apex options` | domain-options | `apex options` | domain-payments | domain-payments |
| `apex options reasoning form` | domain-options | `apex options` | domain-payments | domain-payments |
| `apex options reasoning form` | domain-options | `options reasoning form` | domain-revenue-and-fees | domain-revenue-and-fees |
