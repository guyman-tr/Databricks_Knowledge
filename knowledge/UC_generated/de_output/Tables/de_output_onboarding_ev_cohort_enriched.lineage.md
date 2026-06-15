# Column Lineage: main.de_output.de_output_onboarding_ev_cohort_enriched

| Property | Value |
|----------|-------|
| **UC Object** | `main.de_output.de_output_onboarding_ev_cohort_enriched` |
| **Object Type** | `EXTERNAL` |
| **Source** | (no source code snapshot — JOB-written table or fetch failed) |
| **Generated** | 2026-05-19 |

> No SQL/notebook source was cached for this object. The wiki for this object
> relies on `system.access.column_lineage` data cached under
> `_discovery/column_lineage/de_output_onboarding_ev_cohort_enriched.json` for upstream resolution.

## Column Lineage

| # | Element | source_object | source_column | transform |
|---|---------|---------------|---------------|-----------|
| 1 | `client_real_cid` | `—` | `—` | `runtime_lineage` |
| 2 | `client_country` | `—` | `—` | `runtime_lineage` |
| 3 | `registration_ts` | `—` | `—` | `runtime_lineage` |
| 4 | `final_status_current` | `—` | `—` | `runtime_lineage` |
| 5 | `final_status_current_set_ts` | `—` | `—` | `runtime_lineage` |
| 6 | `final_status_first_verified_ts` | `—` | `—` | `runtime_lineage` |
| 7 | `final_status_last_verified_ts` | `—` | `—` | `runtime_lineage` |
| 8 | `final_status_last_not_verified_ts` | `—` | `—` | `runtime_lineage` |
| 9 | `final_status_last_partially_verified_ts` | `—` | `—` | `runtime_lineage` |
| 10 | `vendor_events_first_attempt_ts` | `—` | `—` | `runtime_lineage` |
| 11 | `vendor_events_last_attempt_ts` | `—` | `—` | `runtime_lineage` |
| 12 | `vendor_events_attempt_count` | `—` | `—` | `runtime_lineage` |
| 13 | `vendor_events_distinct_providers_tried_count` | `—` | `—` | `runtime_lineage` |
| 14 | `vendor_events_distinct_providers_tried_count_v2` | `—` | `—` | `runtime_lineage` |
| 15 | `vendor_events_providers_with_any_evidence_count` | `—` | `—` | `runtime_lineage` |
| 16 | `vendor_events_latest_provider` | `—` | `—` | `runtime_lineage` |
| 17 | `vendor_events_latest_provider_status` | `—` | `—` | `runtime_lineage` |
| 18 | `vendor_events_latest_attempt_ts` | `—` | `—` | `runtime_lineage` |
| 19 | `vendor_events_two_sources_event_count` | `—` | `—` | `runtime_lineage` |
| 20 | `vendor_events_one_source_event_count` | `—` | `—` | `runtime_lineage` |
| 21 | `vendor_events_zero_source_event_count` | `—` | `—` | `runtime_lineage` |
| 22 | `vendor_events_first_two_sources_ts` | `—` | `—` | `runtime_lineage` |
| 23 | `vendor_events_first_one_source_ts` | `—` | `—` | `runtime_lineage` |
| 24 | `policy_route_to_second_on_no_match` | `—` | `—` | `runtime_lineage` |
| 25 | `routing_first_provider1_nomatch_ts` | `—` | `—` | `runtime_lineage` |
| 26 | `routing_first_attempt_after_nomatch_ts` | `—` | `—` | `runtime_lineage` |
| 27 | `routing_second_attempt_observed_flag` | `—` | `—` | `runtime_lineage` |
| 28 | `routing_expected_but_missing_flag` | `—` | `—` | `runtime_lineage` |
| 29 | `routing_secs_nomatch_to_next_attempt` | `—` | `—` | `runtime_lineage` |
| 30 | `policy_required_sources` | `—` | `—` | `runtime_lineage` |
| 31 | `policy_allow_cross_vendor_evidence_combining` | `—` | `—` | `runtime_lineage` |
| 32 | `evidence_sources_sum_across_vendors` | `—` | `—` | `runtime_lineage` |
| 33 | `evidence_sources_best_single_vendor` | `—` | `—` | `runtime_lineage` |
| 34 | `evidence_sources_chosen_for_decision` | `—` | `—` | `runtime_lineage` |
| 35 | `model_computed_status_from_vendor_events` | `—` | `—` | `runtime_lineage` |
| 36 | `model_evidence_success_ts` | `—` | `—` | `runtime_lineage` |
| 37 | `model_evidence_last_failure_ts` | `—` | `—` | `runtime_lineage` |
| 38 | `model_time_first_attempt_to_success_sec` | `—` | `—` | `runtime_lineage` |
| 39 | `model_time_first_attempt_to_last_failure_sec` | `—` | `—` | `runtime_lineage` |
| 40 | `explainability_bucket` | `—` | `—` | `runtime_lineage` |
| 41 | `secs_model_success_to_final_verified` | `—` | `—` | `runtime_lineage` |
| 42 | `provider_trulioo_latest_status` | `—` | `—` | `runtime_lineage` |
| 43 | `provider_gbg_latest_status` | `—` | `—` | `runtime_lineage` |
| 44 | `provider_melisa_latest_status` | `—` | `—` | `runtime_lineage` |
| 45 | `provider_datazoo_latest_status` | `—` | `—` | `runtime_lineage` |
| 46 | `provider_datazoo2_latest_status` | `—` | `—` | `runtime_lineage` |
| 47 | `provider_idmerit_latest_status` | `—` | `—` | `runtime_lineage` |
| 48 | `provider_prove_latest_status` | `—` | `—` | `runtime_lineage` |
| 49 | `VerificationLevelID` | `—` | `—` | `runtime_lineage` |
| 50 | `verification_level_at_first_ev_attempt` | `—` | `—` | `runtime_lineage` |
| 51 | `verification_level_at_last_ev_attempt` | `—` | `—` | `runtime_lineage` |
| 52 | `verification_level_at_final_status_set` | `—` | `—` | `runtime_lineage` |
| 53 | `vl3_first_ts` | `—` | `—` | `runtime_lineage` |
| 54 | `mins_first_ev_to_vl3` | `—` | `—` | `runtime_lineage` |
| 55 | `mins_final_status_to_vl3` | `—` | `—` | `runtime_lineage` |
| 56 | `vl3_before_first_ev_flag` | `—` | `—` | `runtime_lineage` |
| 57 | `final_verified_but_no_vl3_flag` | `—` | `—` | `runtime_lineage` |
| 58 | `vl3_but_final_not_verified_flag` | `—` | `—` | `runtime_lineage` |
