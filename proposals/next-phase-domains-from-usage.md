# Next-phase domain build-out — what the 7-day usage data justifies

> Generated: 2026-05-28
> Source: `audits/_usage_trigger_xref_20260525T155320Z/` (15,037 queries / 263 users / 40 Genie spaces / 7-day lookback)
> Method: cross-reference of actual SQL traffic (Genie + SQL Editor + MCP) against the 51 deployed skill files.

## TL;DR

| Stream | What | Status |
|---|---|---|
| **A. New super-domains** | Build the 3 next-phase hubs (product-analytics, ops-and-onboarding, marketing-and-acquisition); defer finance-and-treasury and platform-and-meta | In progress |
| **B. Existing-hub coverage fills** | Document the ~30 high-traffic tables that are queried >50× but in no skill's `required_tables` | Pending |
| **C. Existing-hub trigger promotions** | Promote ~20 curated phrases to hub triggers (after filtering out column-name / SQL-keyword / Genie-internal noise) | Pending |
| **D. Genie-space realignment** | Fix 5 high-traffic Class-D spaces whose registered tables diverge from actual usage | Pending |
| **E. Usage script refinement** | Add stopword filter; tighten the column-vs-table matcher to stop `customer_snapshot_v` from carrying every Class-A row | Pending |

## A. New super-domains — what the data says

We originally identified 7 super-domains in `_CHECKPOINT_A.md`: A. Trading, B. Customer, C. Payments, D. Compliance, E. Finance & Treasury, F. Marketing & Acquisition, G. Internal & Platform. Four are deployed (A/B/C/D). The 7-day usage signal forces a re-ranking of the remaining three:

### A.1 `domain-product-analytics` (Mixpanel + ABtoro + Feed/Social) — BUILD NEXT

Not in the original 7. Carved out of cluster G ("Internal & Platform") because the data shows it has nothing to do with internal monitoring — it's a first-class analytical domain that just hasn't had a home.

**Anchor tables (from UC probe):**

| Layer | Table | Cols | Notes |
|---|---|---:|---|
| Mixpanel raw | `main.mixpanel.silver`, `main.mixpanel.bronze` | 6,225 each | EAV-flattened wide event store, EVERY event property is a column |
| Mixpanel curated | `main.mixpanel.login_events`, `feed_events`, `notifications_events`, `recurring_deposit_events`, `search_events` | 25-38 | Lean, GCID-keyed, partitioned by `etr_y / etr_ym / etr_ymd` |
| Mixpanel marts | `main.mixpanel.gold_mixpanel_userpageviews`, `gold_mixpanel_marketpageviews` | 13 each | Pageview-grain aggregations |
| ABtoro experimentation | `main.product_analytics_stg.bi_output_product_analytics_abtoro_*` | 12 tables | `experiment_participants` (one row per exp_id × gcid × variant), `storage_experiments_md` (config), `metrics_md`, `experiment_results`, `experiment_significant_results_view`, `experiment_user_segments_*`, `experiment_quality_checks`, `exp_desinger_*`, `early_alerting_*` (YEAST safety algorithm) |
| Optimizely | `main.product_analytics.optimizely_experiment_health`, `optimizely_experiment_issues`, `main.product_analytics_stg.bi_output_product_analytics_experiment_tracker_*` | 4 | Source feed into ABtoro |
| Social feed event hub | `main.experience.bronze_event_hub_prod_event_streaming_we_streams_post` (and 9 sibling event types: comment, emotion, reaction, follow, save, pin, spam, followdiscussion) | 52+ each | Deeply nested struct payloads with Trade/Order/Copy/MarketEvent/Tags/Mentions |
| Feed ranking research | `main.product_analytics_stg.bi_output_product_analytics_feed_ranking_formulas_simulations_*` | 3 | Feed-ranking model simulation outputs |
| Feature-adoption panels | `main.product_analytics_stg.bi_output_product_analytics_optin_*` (3), `feature_retention_daily_feature_usage`, `user_sessions_tables`, `2fa_activation` | 6 | Derived Mixpanel-event panels |

**7-day usage signal:** `mixpanel.silver` queried 160× by 5 users; phrase `mixpanel` matched 237× in queries; `mp_event_name` 195×; `abtoro_experiment_participants` 92×; Genie spaces ABtoro Genie (125), Feed Analytics Genie (27), Customer Segmentation (123 partial), space `01f152bcbeb…` (24), space `01f14dd5bc5c…` (303 — CRM but with Mixpanel cross-joins).

**Proposed sub-skill layout:**
- `mixpanel-events-and-pageviews.md` — silver/bronze raw, curated event-type slices, pageview marts, identity scheme, the 6225-column gotcha, the type-suffix and device-id-in-column-name corruption, partition strategy.
- `ab-testing-and-experimentation.md` — ABtoro experiment metadata, participants, results, segments, metrics, quality-checks; Optimizely as source; YEAST early-alerting algorithm; exp_id as lowercased exp_name convention.
- `feed-and-social-analytics.md` — `experience.bronze_event_hub_*streams_*` family, nested struct shape, `_Requester` vs `_Entity_Owner`, `mixpanel.feed_events`, feed ranking simulations.

**Federation:** customer-and-identity (GCID and CID keys, customer-models-and-segmentation already references Mixpanel-derived clusters), trading (Trade/Order structs in feed events), payments (recurring_deposit_events → deposits), marketing-and-acquisition (post-build — Mixpanel events drive campaign attribution).

### A.2 `domain-ops-and-onboarding` (KYC docs, e-verification, registration funnel, OPS SLAs) — BUILD AFTER A.1

Not in the original 7. Pulled out because the data shows 4 dedicated OPS Genie spaces and clear table-clustering around the `bi_output_operations_*` family that doesn't belong in any existing hub.

**Anchor tables:**

| Sub-area | Table | 7-day queries |
|---|---|---:|
| Doc analysis & verification | `main.bi_output_stg.bi_output_operations_documentanalysis` | 278 |
| KYC AI checks | `main.bi_output_stg.bi_output_operations_ops_ai_doc_verification_checks` | 90+ |
| KYC answers | `main.bi_output_stg.bi_output_operations_ops_kyc_answers` | — |
| E-verification cohorts | `main.bi_output_stg.bi_output_operations_electronic_verification_cohort` | 35+ |
| Risk alert mgmt | `main.bi_output_stg.bi_output_operations_risk_alert_management_tool` | — |
| Customer info ops view | `main.bi_output_stg.bi_output_operations_ops_customer_info` | 35+ |
| Registration funnel | `main.bi_output_stg.bi_output_operations_registrationfunnel` | 36 |
| Ops deposits | `main.bi_output_stg.bi_output_operations_ops_deposits` | — |
| Backoffice doc capture | `main.billing.bronze_etoro_backoffice_customerdocument`, `bronze_etoro_backoffice_customerdocumenttodocumenttype` | 78 / 71 |

**Genie spaces:** "OPS - Documents & Verification" (313), "OPS - General Genie" (41), "OPS - Electronic Verification" (17), "OPS - Registrations Funnel" (36).

**Proposed sub-skills (3):** `kyc-document-pipeline.md`, `electronic-verification-and-registration-funnel.md`, `ops-sla-and-alert-management.md`.

**Federation:** compliance-and-aml (KYC outputs feed AML risk), customer-and-identity (registration → FTD funnel handoff).

### A.3 `domain-marketing-and-acquisition` (BU "F" from Checkpoint A) — BUILD THIRD

**Anchor tables:**

| Sub-area | Table | 7-day queries |
|---|---|---:|
| Affiliate dim | `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` | 99 |
| Affiliate clicks (fiktivo) | `main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation` | 65 |
| Affiliate commission | `main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw` | 55 |
| Salesforce Marketing Cloud | `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | 83 |
| Campaign performance (social) | `main.etoro_kpi_stg.v_marketing_campaigns_social` | 58 |
| Campaign performance (google) | `main.etoro_kpi_stg.v_marketing_campaigns_google` | — |
| Refer-a-Friend | `main.etoro_kpi.v_raf`, `v_raf_config` | 47 |
| Airdrop marketing | `main.bi_db.bronze_marketperformance_airdrop_customer` | 62 |
| Promo card (also payments) | `main.bi_output.vg_promo_card_cashback` | 81 |

**Genie spaces:** "Marketing Campaigns Performance" (94), "PROD - Registration to FTD" (866 — affiliate-attribution leg), RAF space (47).

**Proposed sub-skills (4):** `affiliates-and-attribution.md`, `paid-campaigns-google-social-bing.md`, `refer-a-friend-and-promo-cards.md`, `sfmc-and-lifecycle-email.md`.

**Federation:** customer-and-identity (registration-to-FTD funnel is already there — these are the upstream legs), product-analytics (Mixpanel events drive attribution), payments (RAF compensation flows through eMoney).

### A.4 `domain-finance-and-treasury` (BU "E") — DEFER

Almost no 7-day Genie/MCP traffic for treasury, cost, redeem, FX. Finance still queries in BI tools / Excel rather than Genie. `domain-payments/finance-recon-and-balances.md` already covers the recon angle.

**Revisit when:** Finance team starts using Genie spaces, OR when share-lending / cost / hedge data hits a >20 queries / week threshold.

### A.5 `domain-platform-and-meta` (BU "G") — DEFER (or fold into domain-cross)

Strong table volume (`monitoring_mcp_logs_mcp_gateway` 231×, `bi_dealing_stg.tree0/1/3` 370 combined) but tiny user count (3 / 1 / 1) — almost certainly internal team notebooks, not analytical demand.

**Revisit when:** MCP-self-monitoring usage spreads beyond the team that authors it.

## B. Existing-hub coverage fills (Class-C)

The 30 highest-traffic tables that are queried >50× but not in any skill's `required_tables`:

| Table | Q | Target hub | Target sub-skill |
|---|---:|---|---|
| `main.etoro_kpi.ddr_customer_snapshot_scd_v` | 1530 | customer-and-identity | `compliance-customer-snapshot-and-club` (add SCD variant) |
| `main.etoro_kpi.ddr_customer_dailystatus` | 776 | customer-and-identity | `customer-master-record` |
| `main.dwh.dim_position` | 493 | trading | `position-state-and-grain` |
| `main.bi_output_stg.bi_output_operations_documentanalysis` | 278 | ops-and-onboarding (NEW) | `kyc-document-pipeline` |
| `main.config.monitoring_mcp_logs_mcp_gateway` | 231 | (defer to platform-and-meta) | — |
| `main.etoro_kpi.crm_case_v` | 193 | customer-and-identity | `crm-cases-csat-and-churn` |
| `main.data_rooms.vw_cidfirstdates` | 191 | customer-and-identity | `customer-master-record` |
| `main.trading.bronze_etoro_history_positionchangelog` | 183 | trading | `position-state-and-grain` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel` | 178 | customer-and-identity | `identity-jurisdiction-and-regulation` |
| `main.crm.silver_crm_user` | 168 | customer-and-identity | `crm-cases-csat-and-churn` |
| `main.crm.silver_crm_case` | 164 | customer-and-identity | `crm-cases-csat-and-churn` |
| `main.bi_dealing_stg.tree3` | 162 | (defer) | — |
| `main.mixpanel.silver` | 160 | product-analytics (NEW) | `mixpanel-events-and-pageviews` |
| `main.etoro_kpi.vg_dealing_clicks_openclose_breakdown` | 137 | trading | `dealing-investigation-and-execution` |
| `main.trading.bronze_etoro_trade_instrumentmetadata` | 137 | trading | `instruments-and-asset-classes` |
| `main.regtech.gold_exposure_business_undertaking` | 132 | compliance-and-aml | (new sub-skill: `breaches-and-illegal-trades`) |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus` | 131 | customer-and-identity | `identity-jurisdiction-and-regulation` |
| `main.bi_dealing_stg.tree1` | 120 | (defer) | — |
| `main.dealing.bronze_kafka_dealingstreaming_dealing_dollars_volume_anomalies_per_instrument` | 118 | trading | `dealing-investigation-and-execution` |
| `main.bi_compliance.bi_compliance_bui_tables_compliance_bui_illegal_trades_enrichments` | 117 | compliance-and-aml | `breaches-and-illegal-trades` |
| `main.etoro_kpi.ddr_trading_volumes_and_amounts_v` | 104 | trading | `trading-volumes` |
| `main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_affiliate_masked` | 99 | marketing-and-acquisition (NEW) | `affiliates-and-attribution` |
| `main.bi_output.bi_output_customer_customer_support_case` | 96 | customer-and-identity | `crm-cases-csat-and-churn` |
| `main.dealing.bronze_dealingstreaming_marketrates_dealing_market_feed_rates` | 95 | trading | `dealing-investigation-and-execution` |
| `main.product_analytics_stg.bi_output_product_analytics_abtoro_experiment_participants` | 92 | product-analytics (NEW) | `ab-testing-and-experimentation` |
| `main.dealing.gold_sql_dp_prod_we_dealing_dbo_dealing_clicks_openclose_breakdown` | 92 | trading | `dealing-investigation-and-execution` |
| `main.pii_data.bronze_userapidb_customer_extendeduserfield` | 91 | customer-and-identity | `customer-master-record` |
| `main.data_rooms.vw_dim_position` | 90 | trading | `position-state-and-grain` |
| `main.de_output.vw_bronze_public_api_operations` | 88 | (defer) | — |
| `main.bi_db.bronze_etoro_price_accountratesource` | 88 | trading | `instruments-and-asset-classes` |
| `main.bi_output.bi_output_marketing_sfmc_sfmc_report` | 83 | marketing-and-acquisition (NEW) | `sfmc-and-lifecycle-email` |
| `main.bi_output.vg_promo_card_cashback` | 81 | payments + marketing | `emoney-accounts-and-cards` + `refer-a-friend-and-promo-cards` |
| `main.crm.silver_crm_surveytaker__c` | 78 | customer-and-identity | `crm-cases-csat-and-churn` |
| `main.billing.bronze_etoro_backoffice_customerdocument` | 78 | ops-and-onboarding (NEW) | `kyc-document-pipeline` |
| `main.billing.bronze_etoro_backoffice_customerdocumenttodocumenttype` | 71 | ops-and-onboarding (NEW) | `kyc-document-pipeline` |

## C. Curated hub-trigger promotions (post-noise-filter)

| Phrase | Hub(s) | Q |
|---|---|---:|
| `ftd_funnel_v`, `firsttimedeposit_date`, `registration_date` | customer-and-identity | 1211 / 830 / 766 |
| `ddr_revenue_v`, `ddr_mimo_v`, `ddr_customer_dailystatus`, `ddr_customer_snapshot_scd_v` | customer-and-identity | 526 / 281 / 776 / 1530 |
| `customer_snapshot_v`, `positions_for_compliance_v`, `crm_case_v` | customer-and-identity | 280 / 249 / 193 |
| `caseid`, `caseownertitle`, `casenumber`, `closeddate`, `ownerid` | customer-and-identity (CRM) | 297 / 199 / 146 / 114 / 129 |
| `clubtier`, `ftd_count`, `isactivetrade`, `ispartialclosechild`, `isexcludeuser` | customer-and-identity | 255 / 355 / 284 / 261 / 272 |
| `rolloverfee` | revenue-and-fees (only) | 153 |
| `daily_volume`, `netprofit` | trading | 159 / 117 |
| `bi_output_dealing_bestexecution_report` | trading (best-execution) | 105 |
| `reportmonthtext` | compliance-and-aml (aml-risk-scoring) | 98 |
| `mixpanel`, `mp_event_name` | product-analytics (NEW) | 237 / 195 |
| `dim_position`, `positionchangelog` | trading | 493 / 183 |
| `documentanalysis`, `ops_ai_doc_verification_checks`, `registrationfunnel` | ops-and-onboarding (NEW) | — |
| `dim_affiliate_masked`, `sfmc_report`, `v_marketing_campaigns_*` | marketing-and-acquisition (NEW) | 99 / 83 / 58 |

**Excluded as noise:** `revenueamount`, `calendaryearmonth`, `calendaryear`, `calendarquarter`, `yearmonth`, `isdeleted`, `mergeschema`, `infercolumntypes`, `schemaevolutionmode`, `ignoreleadingwhitespace`, `ignoretrailingwhitespace`, `__databricks_internal_catalog_genie_files_*`, `identity`, `metrics`, `success`, `origin`, `sequence`, `variant`, `actions`, `silver_crm_user` (already a table FQN promotion candidate, not a phrase).

## D. Class-D Genie-space realignments

| Genie space | Q | Action |
|---|---:|---|
| `01f13712cf8516878dbc9663f5f73eb7` eToro DDR - dor dev | 3135 | Add 6 used tables to customer-and-identity hub's `required_tables` |
| `01f0c51e5a4a1506bb34d4751918b4d2` eMoney Adoption & Trading | 305 | Extend `domain-payments/emoney-accounts-and-cards.md` with 6 used tables |
| `01f14dd5bc5c18e3a9959219c3cae9ae` (unnamed) | 303 | Fill 7 CRM tables into `crm-cases-csat-and-churn` |
| `01f1380bddbf1f39918a6ff73748f082` ABtoro Genie | 125 | Anchor for `domain-product-analytics/ab-testing-and-experimentation.md` |
| `01f105b421e7187baa5e81595599f7f3` Feed Analytics Genie | 27 | Anchor for `domain-product-analytics/feed-and-social-analytics.md` |

## E. Usage-script improvements (for the next re-run)

1. **Stopword filter.** Drop phrases that match SQL keywords (`actions`, `success`, `origin`, `sequence`, `metrics`, `identity`, `variant`), CSV/Auto-Loader settings (`mergeschema`, `infercolumntypes`, `schemaevolutionmode`, `ignoreleadingwhitespace`, `ignoretrailingwhitespace`), Databricks-internal scratch (`__databricks_internal_catalog_genie_files_*`), and generic time-axis columns when not co-occurring with a hub-anchor (`calendaryearmonth`, `calendaryear`, `calendarquarter`, `yearmonth`).
2. **Tighten the column-vs-table matcher.** Today a sub-skill whose `required_tables` lists a table with N columns gets credit for every Class-A row that names any of those N columns. Re-run rule: phrase only counts toward a skill if it co-occurs in the query with the actual table name OR with a distinctive non-generic token from the skill body. Expected effect: `compliance-customer-snapshot-and-club` drops from ~60% of Class A to ~15%.
3. **Score Class C by distinct-users not just query-count.** Single-user / bot traffic (`bi_dealing_stg.tree3` — 162 queries by 1 user) shouldn't drive documentation priority.

## Sequencing decision

Built **A.1 product-analytics first** (this commit cycle), because:
- Highest single-table direct-query volume (`mixpanel.silver` 160× by 5 users) with zero existing coverage.
- User specifically called out Mixpanel as having no home.
- Cleanest data shape (event store + experimentation infra + social feed) — no entanglement with existing hubs.
- Three high-volume Genie spaces (ABtoro, Feed Analytics, Customer Segmentation partial) all needing it.

Then **A.2 ops-and-onboarding** and **A.3 marketing-and-acquisition** in either order — both have 4 dedicated Genie spaces and clear table-clustering.

Then **B. Class-C fills** and **C. trigger promotions** on existing hubs.

Then **E. script refinement** so the next 7-day diff is cleaner.
