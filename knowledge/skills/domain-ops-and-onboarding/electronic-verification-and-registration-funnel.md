---
name: domain-ops-and-onboarding
description: "Registration funnel + electronic-verification (EV) provider routing ג€” the per-customer journey from sign-up (VL0) to fully-verified (VL3) to first-time-depositor. Anchors on five tables: (1) main.bi_output_stg.bi_output_operations_registrationfunnel (3.93M customer journeys, 81 cols ג€” the canonical per-customer onboarding snapshot carrying CID + GCID + KYCVerificationFlowID/Flow + CountryID + RiskGroupID + DesignatedRegulation + IsRegistrationAndVerificationLevel3SameDay + IsVerificationLevel3In24HRsFromRegistration + VerificationLevelChangesCount + TimeBucketsFromVerificationLevel0toVerificationLevel3 + IsVerificationLevel{0,1,2,3} + DateTime_VerificationLevel{0,1,2,3} + TimeInMinutes_FromVerificationLevel<N>toVerificationLevel<N+1> + IsDepositor + DateTime_FirstTimeDeposit + FirstDepositAmount + Screening_{ProviderName, ProviderStatus, UnresolvedHits} + TotalScreeningHits + ScreeningStatus + ScreeningPriority + SLA_Screening{Start,End}Time + IsCountryEligibleForElectronicVerification + ElectronicVerification_MatchStatus{ID, DateTime} + MinutesFromVerificationLevel2toElectronicVerificationSuccess + UploadedAnyDocuments + IsProofOfIdentity_Approved + ProofOfIdentity_{DocumentUploadDateTime, DocumentDefinedDateTime, SLAMinutes, IsDocumentApprovalAutomatic, HasOnlyDeclines, CountDeclines, DocumentRejectionReason, Manager, Vendor} + same panel for ProofOfAddress_ + EmailVerification + PhoneVerification + VerificationLevelID + FirstAction{,Date} + FirstDepositAmount + VendorProofOf{Identity,Address} + CurrentRegulation + PlayerStatus{ID, ReasonID, SubReasonID} + LifetimeValue + DepositAttempt + FirstDepositAttemptDate). (2) main.bi_output_stg.bi_output_operations_electronic_verification_cohort (535k EV-attempted clients, 58 cols ג€” VENDOR-LEVEL routing analysis with provider_{trulioo, gbg, melisa, datazoo, datazoo2, idmerit, prove}_latest_status + vendor_events_attempt_count + vendor_events_distinct_providers_tried_count + vendor_events_two_sources_event_count + vendor_events_one_source_event_count + vendor_events_zero_source_event_count + final_status_{current, first_verified_ts, last_verified_ts, last_not_verified_ts, last_partially_verified_ts} + routing_first_provider1_nomatch_ts + policy_route_to_second_on_no_match + routing_second_attempt_observed_flag + routing_expected_but_missing_flag + model_computed_status_from_vendor_events + explainability_bucket + evidence_sources_sum_across_vendors + evidence_sources_best_single_vendor + verification_level_at_first_ev_attempt + vl3_first_ts + final_verified_but_no_vl3_flag + vl3_but_final_not_verified_flag ג€” the model_*-prefixed cols are model-derived diagnostics, the provider_*-prefixed cols are vendor-reported, the policy_* and routing_* are country-policy-aware). (3) main.bi_output_stg.bi_output_operations_ev_investigation_alert_history (EV-investigation audit log). (4) main.bi_output_stg.bi_output_operations_fcmu_ev_blocked_country_pairs (Financial Crime Management Unit list of EV-blocked country pairs ג€” citizenship/POB combinations not allowed via EV path). (5) Two enriched downstream feeds: main.de_output.de_output_onboarding_ev_cohort_enriched + main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis + the upstream risk feed main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification. The four-tier verification level: VL0 = registered, VL1 = email/phone verified, VL2 = identity verified, VL3 = KYC complete. FTD-eligibility requires VL3 + EmailVerification + PhoneVerification + IsCountryEligibleForElectronicVerification."
triggers:
  - registrationfunnel
  - bi_output_operations_registrationfunnel
  - registration funnel
  - onboarding funnel
  - VerificationLevel
  - VerificationLevel0
  - VerificationLevel1
  - VerificationLevel2
  - VerificationLevel3
  - VL0
  - VL1
  - VL2
  - VL3
  - DateTime_VerificationLevel0
  - DateTime_VerificationLevel1
  - DateTime_VerificationLevel2
  - DateTime_VerificationLevel3
  - TimeBucketsFromVerificationLevel0toVerificationLevel3
  - IsRegistrationAndVerificationLevel3SameDay
  - IsVerificationLevel3In24HRsFromRegistration
  - TimeInMinutes_FromVerificationLevel0toVerificationLevel1
  - TimeInMinutes_FromVerificationLevel1toVerificationLevel2
  - TimeInMinutes_FromVerificationLevel2toVerificationLevel3
  - TimeInMinutes_FromVerificationLevel0toVerificationLevel3
  - VerificationLevelChangesCount
  - IsVerificationLevelChangesCountOkay
  - KYCVerificationFlow
  - KYCVerificationFlowID
  - DateTime_FirstTimeDeposit
  - FirstDepositAmount
  - DepositAttempt
  - FirstDepositAttemptDate
  - FirstAction
  - FirstActionDate
  - TotalScreeningHits
  - Screening_UnresolvedHits
  - Screening_ProviderName
  - Screening_ProviderStatus
  - ScreeningPriority
  - SLA_ScreeningStartTime
  - SLA_ScreeningEndTime
  - IsScreeningCaseResolved
  - IsCountryEligibleForElectronicVerification
  - ElectronicVerification_MatchStatusID
  - ElectronicVerification_MatchStatus
  - ElectronicVerification_MatchStatusDateTime
  - MinutesFromVerificationLevel2toElectronicVerificationSuccess
  - UploadedAnyDocuments
  - IsProofOfIdentity_Approved
  - ProofOfIdentity_SLAMinutes
  - IsProofOfAddress_Approved
  - ProofOfAddress_SLAMinutes
  - EmailVerification
  - PhoneVerification
  - electronic_verification_cohort
  - ev cohort
  - bi_output_operations_electronic_verification_cohort
  - provider_trulioo_latest_status
  - provider_gbg_latest_status
  - provider_melisa_latest_status
  - provider_datazoo_latest_status
  - provider_datazoo2_latest_status
  - provider_idmerit_latest_status
  - provider_prove_latest_status
  - Trulioo
  - GBG
  - Melisa
  - DataZoo
  - IDMerit
  - Prove
  - vendor_events_attempt_count
  - vendor_events_distinct_providers_tried_count
  - vendor_events_two_sources_event_count
  - vendor_events_one_source_event_count
  - vendor_events_zero_source_event_count
  - routing_first_provider1_nomatch_ts
  - policy_route_to_second_on_no_match
  - routing_second_attempt_observed_flag
  - routing_expected_but_missing_flag
  - model_computed_status_from_vendor_events
  - explainability_bucket
  - evidence_sources_chosen_for_decision
  - evidence_sources_sum_across_vendors
  - evidence_sources_best_single_vendor
  - verification_level_at_first_ev_attempt
  - vl3_first_ts
  - final_verified_but_no_vl3_flag
  - vl3_but_final_not_verified_flag
  - ev_investigation_alert_history
  - fcmu_ev_blocked_country_pairs
  - de_output_onboarding_ev_cohort_enriched
  - onboarding_flow_userkpis
  - bi_db_operations_onboarding_flow_userkpis
  - customeronboardingriskclassification
sample_questions:
  - "How long does VL0 to VL3 take by regulation?"
  - "What % of customers reached VL3 in 24 hours from registration?"
  - "Which EV vendor has the highest match rate for UK customers?"
  - "Find customers where routing was expected but missing"
  - "Time-to-FTD distribution by KYCVerificationFlow"
  - "Show customers who are VL3 but EV says 'Not Verified' (explainability bucket)"
  - "Which countries are blocked for EV per FCMU?"
  - "What's the dropoff from VL2 to VL3?"
  - "Distinct providers tried by country"
  - "Average ProofOfIdentity_SLAMinutes by regulation"
  - "Customers stuck at VL1 for > 7 days"
  - "Screening SLA breach rate last month"
  - "Customers with > 3 VerificationLevelChanges (loop / retry)"
required_tables:
  - main.bi_output_stg.bi_output_operations_registrationfunnel
  - main.bi_output_stg.bi_output_operations_electronic_verification_cohort
  - main.bi_output_stg.bi_output_operations_ev_investigation_alert_history
  - main.bi_output_stg.bi_output_operations_fcmu_ev_blocked_country_pairs
  - main.de_output.de_output_onboarding_ev_cohort_enriched
  - main.bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_operations_onboarding_flow_userkpis
  - main.bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification
domain_tags:
  - onboarding
  - kyc
  - electronic-verification
  - registration
  - funnel
  - ev-providers
version: 1
owner: "dataplatform"
last_validated_at: "2026-05-28"
---

# Electronic verification & registration funnel

eToro's identity-verification pipeline is country-policy-driven. Some customers verify entirely electronically (EV via Trulioo / GBG / Melisa / DataZoo / IDMerit / Prove); others must upload documents (POI + POA); most do both. The `registrationfunnel` table is the per-customer journey snapshot; `electronic_verification_cohort` is the per-EV-attempted-customer routing detail.

## When to Use

Load for questions about:

- VL0 ג†’ VL1 ג†’ VL2 ג†’ VL3 timing per customer / per country / per regulation
- Country eligibility for EV (`IsCountryEligibleForElectronicVerification`)
- Per-vendor EV outcomes (which provider, what status, how many evidence sources)
- Routing-after-no-match diagnostics ("should have routed but didn't")
- Screening SLA tracking
- FTD eligibility & time-to-FTD from registration
- KYC flow types (`KYCVerificationFlowID` / `_Flow`)
- VerificationLevel changes / retries (`VerificationLevelChangesCount`)
- Explainability buckets (when vendor evidence model disagrees with BackOffice final status)

Do NOT load for:

- Per-document analysis (POI / POA upload, vendor reasons, rejection codes) ג€” see [`kyc-document-pipeline.md`](kyc-document-pipeline.md). `registrationfunnel` has POI / POA SLA columns; for deep doc-level drill use the kyc sub-skill.
- Alert queue / pending tickets ג€” see [`ops-portal-and-alerts.md`](ops-portal-and-alerts.md)
- AML risk-scoring methodology ג€” `../domain-compliance-and-aml/SKILL.md`
- Customer master attributes after onboarding ג€” `../domain-customer-and-identity/customer-master-record.md`
- A/B-test exposure on the KYC surface ג€” `../domain-product-analytics/ab-testing-and-experimentation.md` (`exp_type = 'KYC'`)

## Scope

In scope: the 7 tables above; the 4-tier verification level enum and timestamps; the screening SLA pair (start, end, duration, resolved flag); the EV provider inventory (Trulioo / GBG / Melisa / DataZoo / DataZoo2 / IDMerit / Prove); the per-country EV policy fields (`policy_required_sources`, `policy_route_to_second_on_no_match`, `policy_allow_cross_vendor_evidence_combining`); the model-derived diagnostic columns (`model_*` and `explainability_bucket`); the FCMU blocked-country-pair list; the enriched downstream feeds `de_output_onboarding_ev_cohort_enriched` and `bi_db_operations_onboarding_flow_userkpis`; the upstream risk classification feed.

Out of scope: document-level upload / decision / rejection details (`kyc-document-pipeline.md`); CS / risk-alert queue (`ops-portal-and-alerts.md`); compliance risk-scoring rules; the customer master itself; the EV provider business contracts / pricing; the **KYC-nudge email sequence** that pushes customers to complete VL3 ג€” `CampaignGroup = 'VerificationJourney'` in SFMC drives 3.4M sends / year of nudge emails; per-customer engagement on those emails lives in [`../domain-marketing-and-acquisition/marketing-comms-and-sfmc.md`](../domain-marketing-and-acquisition/marketing-comms-and-sfmc.md). The OPS hub measures the VERIFICATION outcome (`DateTime_VerificationLevel3` timing); marketing-comms measures the EMAIL delivery and engagement.

Last verified: 2026-05-28

## Critical Warnings

1. **Tier 1 ג€” Verification Level enum.** 0 = registered (account created), 1 = email + phone verified (V1), 2 = identity verified (V2 ג€” POI accepted), 3 = KYC complete (V3 ג€” fully verified, can be FTD-eligible). VL3 is necessary but NOT sufficient for FTD ג€” FTD eligibility also requires `IsCountryEligibleForElectronicVerification` (or fallback document path) PLUS `EmailVerification = 1` PLUS `PhoneVerification` not in blocked state. Many analytical questions about "verified customers" should explicitly state whether they mean VL3 or FTD-eligible ג€” they are different cohorts.

2. **Tier 1 ג€” `electronic_verification_cohort` is NOT a per-customer master; it's a 535k-row EV-attempted cohort.** Customers in countries where `IsCountryEligibleForElectronicVerification = 0` are absent. For per-customer onboarding analysis, drive off `registrationfunnel` (3.93M rows, one per customer) and LEFT JOIN to `electronic_verification_cohort` on `RealCID = CID`.

3. **Tier 1 ג€” `provider_<vendor>_latest_status` columns carry the LATEST status per vendor, NOT all attempts.** If a customer was tried with Trulioo three times ג€” once with 'No Match', once with 'Partial', once with 'Match' ג€” `provider_trulioo_latest_status` shows 'Match'. For full attempt history use `ev_investigation_alert_history` joined on customer. For "did Trulioo ever return Match" check `provider_trulioo_latest_status` combined with `vendor_events_two_sources_event_count` aggregates.

4. **Tier 1 ג€” `routing_expected_but_missing_flag = 1` is the canonical "EV pipeline bug" diagnostic.** It fires when `policy_route_to_second_on_no_match = 1` for the country, the first provider returned No Match, but the second-provider attempt never happened (`routing_second_attempt_observed_flag = 0`). Use this filter to find customers stuck in the gap.

5. **Tier 1 ג€” Two related but distinct "evidence" counts.** `evidence_sources_sum_across_vendors` = total across all vendors tried. `evidence_sources_best_single_vendor` = max from any single vendor. `evidence_sources_chosen_for_decision` = the count actually used to decide, which depends on `policy_allow_cross_vendor_evidence_combining` (if 1, the SUM is used; if 0, only the BEST_SINGLE counts). For "did the customer meet policy threshold" compare `evidence_sources_chosen_for_decision` to `policy_required_sources`.

6. **Tier 2 ג€” `explainability_bucket` is the model-vs-system reconciliation diagnostic.** Sample bucket values describe alignment between the vendor-evidence model and BackOffice final status ג€” e.g. "Aligned Verified", "Model success but Backoffice not verified", "Backoffice verified but model failure". Use this to find QA issues without parsing model fields manually.

7. **Tier 2 ג€” `final_verified_but_no_vl3_flag = 1` and `vl3_but_final_not_verified_flag = 1` are oppositely-directed reconciliation flags.** The first means BackOffice marked the customer as EV-verified but they never hit KYC VL3 ג€” typically because they didn't upload required documents on top of EV. The second means VL3 was hit (KYC complete) but EV final status isn't Verified ג€” typically because EV failed and the customer was approved through the document path instead. Both are legitimate operational states, not bugs.

8. **Tier 2 ג€” `VerificationLevelChangesCount > 3` is the loop / retry indicator.** `IsVerificationLevelChangesCountOkay = 0` when count > 3. Customers in this state cycled VL1 ג†’ VL2 ג†’ VL1 ג†’ VL2 ... usually due to document re-uploads, EV retries, or manual reversions. High-loop customers are worth flagging to OPS.

9. **Tier 2 ג€” Screening SLA is a separate timer from KYC verification SLA.** `SLA_ScreeningStartTime` / `_EndTime` / `ScreeningSLATimeDurationInMinutes` only relate to the sanctions / PEP / adverse-media screening case (`IsScreeningCaseResolved = 1` when end-time is set). It runs in parallel with verification and can resolve before / after / never. For "total time from registration to FTD-ready" you need MAX(screening-end-time, VL3-time) plus the FTD-eligibility checks.

10. **Tier 2 ג€” `KYCVerificationFlow` / `KYCVerificationFlowID` discriminate onboarding flow type.** Sample values: an EV-first flow vs. a documents-first flow vs. a hybrid. Different flows have different expected SLAs and abandonment patterns. Always group / partition by `KYCVerificationFlow` for cohort comparisons across customer batches.

11. **Tier 3 ג€” `registrationfunnel` is a SNAPSHOT, not event-time.** All `DateTime_*` timestamps reflect the AS-OF state at snapshot date; `verification_level_id` and per-VL flags reflect final state. For historical "how many customers reached VL3 in Q1 2025" use the per-VL-N timestamps as event times, not the snapshot date.

12. **Tier 3 ג€” `fcmu_ev_blocked_country_pairs` is a small policy reference table.** FCMU = Financial Crime Management Unit. It enumerates (citizenship, place-of-birth) country pairs not permitted via the EV path. Use as a LEFT JOIN exclusion when modelling EV eligibility, not for analytical rollups.

13. **Tier 3 ג€” `bi_db.bronze_riskclassification_riskclassification_customeronboardingriskclassification` is the upstream risk-classifier feed.** Drives `RiskGroupID` / `CountryRiskGroupID` upstream of `registrationfunnel`. For "what risk group is country X in" prefer the dim_country / dim_countryriskgroup tables in `../domain-customer-and-identity/identity-jurisdiction-and-regulation.md`.

## Canonical query patterns

```sql
-- Time-from-registration to VL3 by regulation
SELECT DesignatedRegulation, TimeBucketsFromVerificationLevel0toVerificationLevel3,
       COUNT(*) AS customers
FROM main.bi_output_stg.bi_output_operations_registrationfunnel
WHERE DateTime_VerificationLevel0 >= TIMESTAMP'2026-04-01'
  AND DateTime_VerificationLevel3 IS NOT NULL
GROUP BY DesignatedRegulation, TimeBucketsFromVerificationLevel0toVerificationLevel3
ORDER BY DesignatedRegulation, customers DESC;

-- EV "routing missing" diagnostic
SELECT client_country, COUNT(*) AS affected_customers
FROM main.bi_output_stg.bi_output_operations_electronic_verification_cohort
WHERE routing_expected_but_missing_flag = 1
GROUP BY client_country
ORDER BY affected_customers DESC
LIMIT 20;

-- Per-EV-vendor match rate
SELECT 'Trulioo' AS provider,
       SUM(CASE WHEN provider_trulioo_latest_status = 'Match' THEN 1 ELSE 0 END) AS matched,
       SUM(CASE WHEN provider_trulioo_latest_status IS NOT NULL THEN 1 ELSE 0 END) AS tried
FROM main.bi_output_stg.bi_output_operations_electronic_verification_cohort
UNION ALL SELECT 'GBG',
       SUM(CASE WHEN provider_gbg_latest_status = 'Match' THEN 1 ELSE 0 END),
       SUM(CASE WHEN provider_gbg_latest_status IS NOT NULL THEN 1 ELSE 0 END)
FROM main.bi_output_stg.bi_output_operations_electronic_verification_cohort
-- ... continue for other providers
;

-- Looping customers (more than 3 level changes)
SELECT CID, GCID, KYCVerificationFlow, VerificationLevelChangesCount,
       DateTime_VerificationLevel0, DateTime_VerificationLevel3, VerificationLevelID
FROM main.bi_output_stg.bi_output_operations_registrationfunnel
WHERE IsVerificationLevelChangesCountOkay = 0
  AND DateTime_VerificationLevel0 >= TIMESTAMP'2026-01-01'
ORDER BY VerificationLevelChangesCount DESC
LIMIT 100;
```

## Skill provenance

- **Primary sources.** UC live probes on 2026-05-28: `registrationfunnel` 3.93M rows / 81 cols / rich business comments on every column; `electronic_verification_cohort` 535k rows / 58 cols / vendor-by-vendor commented schema confirming Trulioo / GBG / Melisa / DataZoo / DataZoo2 / IDMerit / Prove provider columns and the routing / policy / model / explainability column family.
- **Usage data.** Class C in `_usage_trigger_xref_20260525T155320Z`: `registrationfunnel` 36q / 7-day, `electronic_verification_cohort` 35q. Genie spaces "OPS - Registrations Funnel" 36 q/w, "OPS - Electronic Verification" 17 q/w.
- **Federation.** [`kyc-document-pipeline.md`](kyc-document-pipeline.md) for POI / POA upload details that `registrationfunnel` summarises; `../cross-cutting/valid-users-filter-contract.md`; `../domain-customer-and-identity/identity-jurisdiction-and-regulation.md` for country / regulation dim lookups; `../domain-product-analytics/ab-testing-and-experimentation.md` for KYC-surface A/B tests.
