# Routing Inventory - Corpus-Wide Scan

Generated: 2026-06-14T14:12:40.234485Z

## Corpus stats

- Hubs in scope: **16**
- Files scanned (with frontmatter): **88**
- Files scanned total: 95
- Files without frontmatter (skipped): 7
- Total trigger entries (raw): **4515**
- Distinct normalized concepts (triggers + required_tables + sample_questions): **4405**
- Concepts claimed by >=2 hubs (unmanaged overlap candidates): **265** (6.0% of all concepts)
- Substring overlap rows (matcher-false-positive candidates): **161**

## Per-hub stats

| Hub | Files | Triggers | Required tables | Sample questions |
|---|---:|---:|---:|---:|
| `cross-cutting` | 3 | 69 | 5 | 11 |
| `domain-aum-and-aua` | 1 | 28 | 4 | 0 |
| `domain-compliance-and-aml` | 4 | 212 | 53 | 42 |
| `domain-cross` | 5 | 111 | 54 | 32 |
| `domain-customer-and-identity` | 9 | 504 | 99 | 84 |
| `domain-exw-wallet` | 1 | 80 | 23 | 0 |
| `domain-marketing-and-acquisition` | 5 | 816 | 82 | 67 |
| `domain-moneyfarm` | 6 | 155 | 64 | 32 |
| `domain-ops-and-onboarding` | 4 | 341 | 47 | 57 |
| `domain-options` | 6 | 200 | 47 | 30 |
| `domain-payments` | 6 | 260 | 109 | 63 |
| `domain-product-analytics` | 4 | 301 | 57 | 65 |
| `domain-revenue-and-fees` | 9 | 311 | 84 | 0 |
| `domain-spaceship` | 6 | 168 | 44 | 25 |
| `domain-staking` | 6 | 364 | 24 | 16 |
| `domain-trading` | 13 | 595 | 86 | 16 |

## Top overlap candidates - concepts claimed by >=2 hubs

Sorted by hub-count desc, then alphabetic. Top 60 shown; full list in concepts.csv.

| Concept (normalized) | Hubs | Claiming hubs | Source fields | Variants |
|---|---:|---|---|---|
| `main de_output de_output_etoro_kpi_fact_customeraction_w_metrics` | 5 | domain-cross, domain-customer-and-identity, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.de_output.de_output_etoro_kpi_fact_customeraction_w_metrics |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked` | 5 | cross-cutting, domain-cross, domain-customer-and-identity, domain-moneyfarm, domain-options | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked |
| `main dwh gold_sql_dp_prod_we_dwh_dbo_fact_customeraction` | 5 | domain-cross, domain-customer-and-identity, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction |
| `c2f` | 4 | domain-cross, domain-exw-wallet, domain-payments, domain-revenue-and-fees | triggers | C2F |
| `iscreditreportvalidcb` | 4 | cross-cutting, domain-customer-and-identity, domain-options, domain-staking | triggers | IsCreditReportValidCB |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum` | 4 | cross-cutting, domain-aum-and-aua, domain-payments, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_aum |
| `main bi_db gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions` | 4 | domain-payments, domain-revenue-and-fees, domain-staking, domain-trading | required_tables | main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_ddr_fact_revenue_generating_actions |
| `main etoro_kpi_prep v_moneyfarm_aum` | 4 | cross-cutting, domain-aum-and-aua, domain-moneyfarm, domain-revenue-and-fees | required_tables | main.etoro_kpi_prep.v_moneyfarm_aum |
| `main finance bronze_sodreconciliation_apex_ext1047_revenuereports` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext1047_revenuereports |
| `main finance bronze_sodreconciliation_apex_ext869_cashactivity` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext869_cashactivity |
| `main finance bronze_sodreconciliation_apex_ext872_tradeactivity` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.finance.bronze_sodreconciliation_apex_ext872_tradeactivity |
| `main finance bronze_sodreconciliation_apex_sodfiles` | 4 | domain-cross, domain-payments, domain-revenue-and-fees, domain-trading | required_tables | main.finance.bronze_sodreconciliation_apex_sodfiles |
| `main general bronze_sodreconciliation_apex_ext981_buypowersummary` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.general.bronze_sodreconciliation_apex_ext981_buypowersummary |
| `main general bronze_usabroker_apex_options` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | required_tables | main.general.bronze_usabroker_apex_options |
| `usabroker` | 4 | domain-cross, domain-options, domain-payments, domain-revenue-and-fees | triggers | USABroker; usabroker |
| `actiontypeid` | 3 | domain-customer-and-identity, domain-revenue-and-fees, domain-trading | triggers | ActionTypeID |
| `airdrop` | 3 | domain-marketing-and-acquisition, domain-staking, domain-trading | triggers | Airdrop; airdrop |
| `apex` | 3 | domain-options, domain-payments, domain-revenue-and-fees | triggers | Apex; apex |
| `apex sod` | 3 | domain-cross, domain-options, domain-payments | triggers | Apex SOD; apex sod |
| `aum` | 3 | domain-aum-and-aua, domain-payments, domain-trading | triggers | AUM; aum |
| `c2p` | 3 | domain-exw-wallet, domain-payments, domain-trading | triggers | C2P |
| `chargeback` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | chargeback |
| `crypto to fiat` | 3 | domain-cross, domain-exw-wallet, domain-revenue-and-fees | triggers | crypto to fiat |
| `crypto-to-fiat` | 3 | domain-cross, domain-exw-wallet, domain-payments | triggers | crypto-to-fiat |
| `exw_c2f_e2e` | 3 | domain-cross, domain-exw-wallet, domain-payments | triggers | EXW_C2F_E2E |
| `exw_dimuser` | 3 | domain-customer-and-identity, domain-exw-wallet, domain-payments | triggers | EXW_DimUser |
| `fact_currencypricewithsplit` | 3 | domain-moneyfarm, domain-spaceship, domain-trading | triggers | Fact_CurrencyPriceWithSplit; fact_currencypricewithsplit |
| `fact_customeraction_w_metrics` | 3 | domain-cross, domain-revenue-and-fees, domain-trading | triggers | fact_customeraction_w_metrics |
| `ftd` | 3 | domain-customer-and-identity, domain-payments, domain-revenue-and-fees | triggers | FTD |
| `gatsby` | 3 | domain-options, domain-payments, domain-revenue-and-fees | triggers | Gatsby; gatsby |
| `isglobalftd` | 3 | domain-cross, domain-options, domain-payments | triggers | IsGlobalFTD |
| `issettled` | 3 | domain-customer-and-identity, domain-revenue-and-fees, domain-trading | triggers | IsSettled |
| `isvalidcustomer` | 3 | cross-cutting, domain-customer-and-identity, domain-options | triggers | IsValidCustomer |
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
| `mid` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | MID |
| `midname` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | MIDName |
| `midvalue` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | MIDValue |
| `net deposits` | 3 | domain-payments, domain-revenue-and-fees, domain-spaceship | triggers | Net Deposits; net deposits |
| `off-ramp` | 3 | domain-cross, domain-exw-wallet, domain-payments | triggers | off-ramp |
| `playerlevelid` | 3 | domain-compliance-and-aml, domain-customer-and-identity, domain-staking | triggers | PlayerLevelID |
| `playerstatus` | 3 | domain-compliance-and-aml, domain-ops-and-onboarding, domain-staking | triggers | PlayerStatus |
| `reconciliation` | 3 | domain-cross, domain-staking, domain-trading | triggers | reconciliation |
| `refund` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | refund |
| `regulationid` | 3 | domain-compliance-and-aml, domain-customer-and-identity, domain-staking | triggers | RegulationID |
| `reversal` | 3 | domain-cross, domain-payments, domain-revenue-and-fees | triggers | reversal |

## Substring overlap - top 40

Multi-word concepts that contain another claimed concept as a sub-span, where the sub-concept is claimed by a hub the long concept is NOT on. These are the false-positive vectors when a matcher does substring / n-gram matching.

| Long concept | Long hub(s) | Sub-concept (exposed) | Sub hub(s) | Foreign hub(s) |
|---|---|---|---|---|
| `main etoro_kpi_prep v_moneyfarm_aum` | cross-cutting; domain-aum-and-aua; domain-moneyfarm; domain-revenue-and-fees | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `what is our aum as of today` | cross-cutting | `what is our aum` | domain-aum-and-aua | domain-aum-and-aua |
| `moneyfarm aum today` | cross-cutting | `moneyfarm aum` | domain-moneyfarm; domain-revenue-and-fees | domain-moneyfarm; domain-revenue-and-fees |
| `customer balance for date x where x has no data yet` | cross-cutting | `customer balance` | domain-payments | domain-payments |
| `client balance valid` | cross-cutting | `client balance` | domain-payments | domain-payments |
| `total trading revenue ytd` | cross-cutting | `trading revenue` | domain-revenue-and-fees | domain-revenue-and-fees |
| `net deposits last month by country` | cross-cutting | `net deposits` | domain-payments; domain-revenue-and-fees; domain-spaceship | domain-payments; domain-revenue-and-fees; domain-spaceship |
| `non-custodial wallet aum` | domain-aum-and-aua | `non-custodial wallet` | domain-exw-wallet | domain-exw-wallet |
| `non-custodial wallet aum` | domain-aum-and-aua | `wallet aum` | domain-exw-wallet | domain-exw-wallet |
| `etoro wallet aum` | domain-aum-and-aua | `etoro wallet` | domain-exw-wallet; domain-payments | domain-exw-wallet; domain-payments |
| `etoro wallet aum` | domain-aum-and-aua | `wallet aum` | domain-exw-wallet | domain-exw-wallet |
| `on-chain crypto aum` | domain-aum-and-aua | `crypto aum` | domain-exw-wallet | domain-exw-wallet |
| `time-series of risk level for partykey x aml_riskscore_scd scd-2 walk` | domain-compliance-and-aml | `scd-2 walk` | cross-cutting | cross-cutting |
| `apex sod cash vs buyingpower vs options portfolio for accountid x` | domain-cross | `apex sod` | domain-cross; domain-options; domain-payments | domain-options; domain-payments |
| `first time funded to first trade` | domain-cross | `first time funded` | domain-customer-and-identity | domain-customer-and-identity |
| `operator action audit` | domain-cross | `action audit` | domain-customer-and-identity | domain-customer-and-identity |
| `who authorized transaction x audit trail for one emoney transaction` | domain-cross | `audit trail` | domain-cross; domain-customer-and-identity | domain-customer-and-identity |
| `audit trail for accountid y over a date window` | domain-cross | `audit trail` | domain-cross; domain-customer-and-identity | domain-customer-and-identity |
| `is this customer cfd-restricted what s their appropriateness test status` | domain-customer-and-identity | `appropriateness test` | domain-customer-and-identity; domain-options | domain-options |
| `main etoro_kpi_prep v_fact_customeraction_enriched` | domain-customer-and-identity | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `main etoro_kpi_prep v_fact_customeraction_w_metrics` | domain-customer-and-identity; domain-trading | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `which positions did this customer open via copy trading` | domain-customer-and-identity | `copy trading` | domain-trading | domain-trading |
| `per-day per-popular-investor copy-trading revenue split by asset class` | domain-customer-and-identity | `by asset class` | domain-trading | domain-trading |
| `popular investor program` | domain-customer-and-identity | `popular investor` | domain-customer-and-identity; domain-trading | domain-trading |
| `daily active traders` | domain-customer-and-identity | `active traders` | domain-customer-and-identity; domain-payments | domain-payments |
| `main etoro_kpi_prep gold_de_user_dim_ddr_customer_dailystatus_scd` | domain-customer-and-identity | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `main etoro_kpi_prep v_population_first_time_funded` | domain-customer-and-identity; domain-payments | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `main etoro_kpi_prep v_population_first_trading_action` | domain-customer-and-identity; domain-payments | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `main etoro_kpi_prep v_population_active_traders` | domain-customer-and-identity; domain-payments | `main etoro_kpi_prep` | domain-spaceship | domain-spaceship |
| `active traders today vs last month` | domain-customer-and-identity | `active traders` | domain-customer-and-identity; domain-payments | domain-payments |
| `daily active traders time series for march 2026` | domain-customer-and-identity | `active traders` | domain-customer-and-identity; domain-payments | domain-payments |
| `crypto wallet user` | domain-customer-and-identity | `crypto wallet` | domain-exw-wallet; domain-payments | domain-exw-wallet; domain-payments |
| `eth gas fee` | domain-exw-wallet | `gas fee` | domain-exw-wallet; domain-payments | domain-payments |
| `live acquisition funnel for today by channel country` | domain-marketing-and-acquisition | `acquisition funnel` | domain-payments | domain-payments |
| `customer user id` | domain-marketing-and-acquisition | `user id` | domain-customer-and-identity | domain-customer-and-identity |
| `what s the open rate on leadwelcomejourney emails last month` | domain-marketing-and-acquisition | `open rate` | domain-trading | domain-trading |
| `how many popular investor raf referrals referringispi 1 succeeded last year` | domain-marketing-and-acquisition | `popular investor` | domain-customer-and-identity; domain-trading | domain-customer-and-identity; domain-trading |
| `loyalty offer redemption rate by club tier` | domain-marketing-and-acquisition | `club tier` | domain-customer-and-identity | domain-customer-and-identity |
| `top 5 sfmc subject lines by unique open rate in marketcampaigns last month` | domain-marketing-and-acquisition | `open rate` | domain-trading | domain-trading |
| `ben thompson tableau` | domain-moneyfarm | `ben thompson` | domain-moneyfarm; domain-revenue-and-fees | domain-revenue-and-fees |
