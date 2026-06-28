---
name: domain-marketing-and-acquisition
description: "Refer-A-Friend (RAF), airdrops, promo cards, and loyalty offers — the customer-driven viral and incentive layer. Anchors: main.etoro_kpi.v_raf (313k dual-sided referring × referred ledger with 17-bit BITMASK-encoded RafStatusID that serialises as comma-concatenated RafStatusName strings — 1=RafGiven dominates 93%, with up to 7 simultaneous failure-atoms from FTDReferringCheckAmount / FTDReferringDaysToWaitFromFTD / FTDReferredCheckAmount / FTDReferredDaysToWaitFromFTD / PositionsAmountReferring / PositionsAmountReferred / RegistrationDateExpired plus terminal-state Fraud / NoReferringConfig / NoDefaultReferredConfig / NoMoneyIsSetInConfig / LimitReached / AlreadyGiven / PairNotExists / ReferredStartedAfterBothPlans / GetTotalDepositsError); v_raf_config (251 per-Regulation × Country × PlayerLevel configs — CySEC dominates with 216 of 251, US uses asymmetric $30/$30 with 14-day wait, EU regulations use $216.7 referrer + $0 referred); the OLTP-source main.experience.bronze_etoro_customer_rafgiven (291k = the RafGiven slice as compensation events) + bronze_etoro_dwh_rafcustomers (279 enriched cohort rows); the candidate-eligibility table main.general.bronze_etoro_customer_rafeligiblecustomers (2,194 pre-validated candidates with ReferringPILevel + RafStatus INT enum); the per-config bronze_rafcompensations_config_viewconfig + customer_raftrackingprocessed + dictionary tables (RafStatus bitmask, RafModelType = Club vs PI, plus HighLevelDepositStatus / CopyPositionStatus / OrderStatus / PositionStatus / PlanType dictionaries used by the RAF engine to validate referrals); the airdrop incentive engine — main.bi_db.bronze_marketperformance_airdrop_customer (6M SCD-2 rows, 23 cols carrying the 7-status airdrop lifecycle 1=NotEligible 2=Eligible 3=InstrumentSelected 4=Given 5=Declined 6=PositionOpenRequested 7=Failed with timestamps AcceptedDate / PurchaseRequestDate / GivenDate / ExaustedDate) + bronze_marketperformance_airdrop_configuration (per-Regulation × Country × EligibilityType × Plan policy with experiment_variation_id linking back to ABtoro) + trading.bronze_etoro_trade_positionairdroplog (execution bridge: one row per airdrop-to-position attempt — join key: CID + InstrumentID + date proximity; main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason is the companion gold compensation-reason dim — join key CompensationReasonID, label col Name — always join for reason name, never hardcode IDs); airdrop campaign attribution requires a 2-layer join: OfferTypeID → dictionary_airdropoffertypes.OfferTypeName (Classic/Affiliate/AcademyLite), then Mixpanel 'Airdrop Delivered BE' event for affiliateid_numeric (11=RAF, other non-NULL=paid affiliate, NULL=organic); the promo / loyalty offers — main.crm.silver_crm_benefit_loyalty__c, silver_crm_loyalty_offer__c, silver_crm_loyalty_offer_request__c, main.bi_output.bi_output_marketing_promotion_bi_db_promo_card, and bi_output_marketing_promotion_bi_db_bounceback_promo_card. Use for RAF cost calculation, referral funnel diagnostics, country / regulation policy lookup, airdrop allocation analysis, airdrop-to-position execution tracing, campaign attribution for airdrops, A/B test linkage on airdrop variants, and loyalty offer redemption tracking."
triggers:
  - v_raf
  - v_raf_config
  - vw_raf_for_genie
  - vw_raf_config_for_genie
  - vw_raf_for_genie2
  - bronze_etoro_customer_rafgiven
  - rafgiven
  - bronze_etoro_dwh_rafcustomers
  - rafcustomers
  - bronze_etoro_customer_rafeligiblecustomers
  - rafeligiblecustomers
  - bronze_rafcompensations_config_viewconfig
  - bronze_rafcompensations_customer_raftrackingprocessed
  - bronze_rafcompensations_dictionary_rafstatus
  - bronze_rafcompensations_dictionary_rafmodeltype
  - bronze_rafcompensations_dictionary_highleveldepositstatus
  - bronze_rafcompensations_dictionary_copypositionstatusid
  - bronze_rafcompensations_dictionary_copytype
  - bronze_rafcompensations_dictionary_mirrorordercreated
  - bronze_rafcompensations_dictionary_orderstatus
  - bronze_rafcompensations_dictionary_plantype
  - bronze_rafcompensations_dictionary_positionstatus
  - rnd_output_experience_raf_candidates
  - rnd_output_experience_raftemp1
  - rnd_output_experience_raftemp2
  - rnd_output_experience_raftemp3
  - rnd_output_experience_raftrackingprocessed
  - bi_output_raf_raf_invitees_kpis
  - raf_invitees_kpis
  - de_output_monitoring_genies_views_raf_genie_views_checks
  - RAF
  - raf
  - referral
  - "refer a friend"
  - ReferringCID
  - ReferredCID
  - ReferringGCID
  - ReferredGCID
  - ReferringCompensationAmount
  - ReferredCompensationAmount
  - RafStatusName
  - RafStatusID
  - FraudReason
  - IsProcessed
  - CompensationDate
  - ProcessingDate
  - ReferringPlayerLevelName
  - ReferringRegulationName
  - ReferringCountry
  - ReferringIsPI
  - ReferringGuruStatusName
  - ReferringRealizedEquity
  - ReferredRealizedEquity
  - ReferringTotalInvestedAmount
  - ReferredTotalInvestedAmount
  - ReferringCompensationInDollar
  - ReferredCompensationInDollar
  - MaxNumberOfCompensations
  - DaysToWaitFromFTD
  - DaysToCheckMinPositionsAmountFromRegistration
  - ReferringMinDepositInDollar
  - ReferredMinDepositInDollar
  - ReferringMinPositionsAmountInDollar
  - ReferredMinPositionsAmountInDollar
  - FraudScore
  - RafProgramStartDate
  - raf_ftds
  - total_raf_ftds
  - spain_raf_ftds
  - compensationrafinvitedinviting
  - RAFAutomation
  - FTDReferringCheckAmount
  - FTDReferringDaysToWaitFromFTD
  - FTDReferredCheckAmount
  - FTDReferredDaysToWaitFromFTD
  - PositionsAmountReferring
  - PositionsAmountReferred
  - RegistrationDateExpired
  - NoReferringConfig
  - NoDefaultReferredConfig
  - NoMoneyIsSetInConfig
  - LimitReached
  - AlreadyGiven
  - PairNotExists
  - ReferredStartedAfterBothPlans
  - GetTotalDepositsError
  - IsValidForRaf
  - bronze_marketperformance_airdrop_customer
  - bronze_marketperformance_airdrop_configuration
  - bronze_marketperformance_airdrop_customererrors
  - bronze_marketperformance_dictionary_airdropeligibilitytype
  - bronze_marketperformance_dictionary_airdropoffertypes
  - bronze_marketperformance_dictionary_airdroptradingerrorcodes
  - bronze_marketperformance_dictionary_airdropplan
  - bronze_marketperformance_dictionary_airdropstatus
  - bronze_marketperformance_dictionary_airdropstatusreason
  - airdrop
  - airdrop_customer
  - airdrop_configuration
  - AirdropStatusID
  - AirdropStatusName
  - AirdropPlanID
  - AirdropPlanName
  - OfferTypeID
  - OfferTypeName
  - EligibilityTypeID
  - SelectedInstrumentID
  - AcceptedDate
  - PurchaseRequestDate
  - GivenDate
  - ExaustedDate
  - PositionRequestID
  - PositionRequestAttemptsCount
  - IsExternalTriggerReceived
  - bronze_etoro_trade_positionairdroplog
  - positionairdroplog
  - gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason
  - dim_compensationreason
  - compensationreason
  - ExecutionOccurred
  - AmountInUnits
  - FailReason
  - affiliateid_numeric
  - airdrop campaign
  - campaign attribution
  - silver_sharepoint_dealing_staking_airdrop_hs
  - bronze_fivetran_dealing_staking_airdrop_hs  # historical name, table is now stale
  - bi_output_product_analytics_airdrop_financial_metrics
  - bi_output_product_analytics_giorgich_tables_airdrop_2
  - silver_crm_benefit_loyalty__c
  - silver_crm_loyalty_offer__c
  - silver_crm_loyalty_offer_request__c
  - bi_output_customer_customer_facing_club_loyalty_offer
  - bi_output_customer_customer_facing_club_loyalty_offer_request
  - bi_output_marketing_promotion_bi_db_promo_card
  - bi_output_marketing_promotion_bi_db_promocard
  - bi_output_marketing_promotion_bi_db_bounceback_promo_card
  - bi_output_marketing_promotion_bi_db_bounceback_promocard
  - promo_card
  - promocard
  - loyalty offer
  - "_2024campaigns_incentivisedcids"
  - "campaigns2025_incentivisedcids"
sample_questions:
  - "How much did we pay out in RAF compensation last quarter?"
  - "What's the most common RAF failure reason in the UK?"
  - "Which countries pay the highest referrer compensation?"
  - "How many RAF compensations failed because of the days-to-wait check?"
  - "Show me airdrop conversion funnel: how many went from Eligible to Given?"
  - "What's the average DaysToWaitFromFTD for CySEC-regulated customers?"
  - "How many referrals are pending in the cooling-off window right now?"
  - "Which airdrop offer type had the highest decline rate?"
  - "Show me airdrop allocations by country last month with the per-country eligibility policy"
  - "How many Popular Investor RAF referrals (ReferringIsPI=1) succeeded last year?"
  - "Which referrals failed on more than 3 criteria simultaneously?"
  - "Total RAF cost per regulation (CySEC vs FCA vs eToroUS)"
  - "Loyalty offer redemption rate by club tier"
  - "What's the fraud score threshold on RAF in each country?"
  - "How many airdrops converted to actual positions last month?"
  - "What compensation reason code was used for the RAF airdrop positions?"
  - "Which affiliates drove the most airdrop deliveries last quarter?"
required_tables:
  - main.etoro_kpi.v_raf
  - main.etoro_kpi.v_raf_config
  - main.experience.bronze_etoro_customer_rafgiven
  - main.experience.bronze_etoro_dwh_rafcustomers
  - main.general.bronze_etoro_customer_rafeligiblecustomers
  - main.experience.bronze_rafcompensations_dictionary_rafstatus
  - main.experience.bronze_rafcompensations_dictionary_rafmodeltype
  - main.experience.bronze_rafcompensations_config_viewconfig
  - main.experience.bronze_rafcompensations_customer_raftrackingprocessed
  - main.bi_output_stg.bi_output_raf_raf_invitees_kpis
  - main.bi_db.bronze_marketperformance_airdrop_customer
  - main.general.bronze_marketperformance_airdrop_configuration
  - main.general.bronze_marketperformance_dictionary_airdropstatus
  - main.general.bronze_marketperformance_dictionary_airdropstatusreason
  - main.general.bronze_marketperformance_dictionary_airdropplan
  - main.experience.bronze_marketperformance_dictionary_airdropoffertypes
  - main.trading.bronze_etoro_trade_positionairdroplog
  - main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason
  - main.crm.silver_crm_loyalty_offer__c
  - main.crm.silver_crm_loyalty_offer_request__c
  - main.crm.silver_crm_benefit_loyalty__c
  - main.bi_output.bi_output_marketing_promotion_bi_db_promo_card
version: 2
owner: "dataplatform"
last_validated_at: "2026-06-23"
---

# RAF (Refer-A-Friend) + Airdrops + Loyalty Incentives

The customer-driven viral and incentive layer. Three product flavours: (1) RAF compensates an existing customer for inviting a new one; (2) Airdrops give selected customers free inducement-shares to start trading; (3) Loyalty offers reward Club-tier customers for retention. All three are post-acquisition incentives — they do NOT acquire the customer directly, they MOTIVATE either the inviter (RAF) or the new/existing customer (airdrop/loyalty) toward a specific action.

## What it covers

### RAF — Refer-A-Friend

The canonical view `etoro_kpi.v_raf` (313k rows / 31 cols) is the dual-sided referring × referred ledger. Each row is ONE referral event with BOTH parties' attributes co-resident: `ReferringCID` / `ReferredCID`, `ReferringGCID` / `ReferredGCID`, `ReferringCompensationAmount` / `ReferredCompensationAmount`, `ReferringCountryID` / `ReferredCountryID`, `ReferringRealizedEquity` / `ReferredRealizedEquity`, `ReferringTotalInvestedAmount` / `ReferredTotalInvestedAmount`, plus the referring-side Popular-Investor flags (`ReferringIsPI`, `ReferringGuruStatusName`) and PlayerLevel fields. `IsProcessed` (INT — 0 / 1) flags whether RAF engine has processed this candidate referral yet; `CompensationDate` is the actual dollar-out date; `ProcessingDate` is the engine-run date.

`RafStatusID` is a **BITMASK** (POWER-OF-2: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536), serialised in `RafStatusName` as the comma-concatenated set of bits-set:

| BitID | RafStatusName atom | Meaning | IsValidForRaf (retryable) |
|---:|---|---|:---:|
| 1 | `RafGiven` | Success — compensation paid | false |
| 2 | `Fraud` | Fraud detection triggered | false |
| 4 | `LimitReached` | Per-period max reached | false |
| 8 | `AlreadyGiven` | Duplicate event | false |
| 16 | `PairNotExists` | Pair not in eligibility list | false |
| 32 | `FTDReferringCheckAmount` | Referring CID's FTD too small | false |
| 64 | `FTDReferringDaysToWaitFromFTD` | Referring CID's FTD too recent | **true** |
| 128 | `FTDReferredCheckAmount` | Referred CID's FTD too small | false |
| 256 | `FTDReferredDaysToWaitFromFTD` | Referred CID's FTD too recent | **true** |
| 512 | `RegistrationDateExpired` | Referral happened past window | false |
| 1024 | `PositionsAmountReferring` | Referring CID hasn't opened enough positions | **true** |
| 2048 | `PositionsAmountReferred` | Referred CID hasn't opened enough positions | **true** |
| 4096 | `ReferredStartedAfterBothPlans` | Edge case — referred started after both eligible plans | false |
| 8192 | `NoReferringConfig` | No active config for referring country / regulation / level | false |
| 16384 | `NoDefaultReferredConfig` | No default config for referred side | false |
| 32768 | `GetTotalDepositsError` | Engine couldn't compute total deposits — transient | **true** |
| 65536 | `NoMoneyIsSetInConfig` | Config money is zero | false |

`IsValidForRaf = true` means "this fail might be retryable later" — the four atoms `FTDReferringDaysToWaitFromFTD`, `FTDReferredDaysToWaitFromFTD`, `PositionsAmountReferring`, `PositionsAmountReferred`, plus the transient `GetTotalDepositsError`. The remaining are terminal — won't ever convert to `RafGiven`. This `IsValidForRaf` flag is the basis for the RAF engine's re-evaluation queue (which lives in `bronze_rafcompensations_customer_raftrackingprocessed`).

Live distribution of `RafStatusName` in `v_raf` (sample from a Genie-space probe):
- `RafGiven`: 291,077 (93%)
- `NoReferringConfig`: 5,068 — country / regulation / level combination has no active RAF policy
- `Fraud`: 3,282 — caught by FraudScore on `v_raf_config`
- `RegistrationDateExpired, PositionsAmountReferred`: 2,787 (multi-bit)
- `NoDefaultReferredConfig`: 1,653
- `FTDReferredCheckAmount, FTDReferredDaysToWaitFromFTD, PositionsAmountReferred`: 1,178 (3-bit fail)
- `PositionsAmountReferred`: 1,149
- `RegistrationDateExpired`: 1,117
- `FTDReferredCheckAmount, RegistrationDateExpired`: 915
- `PositionsAmountReferring, PositionsAmountReferred`: 902
- Plus ~65 more multi-bit combinations.

The configuration `etoro_kpi.v_raf_config` (251 rows) is keyed by `Regulation × Country × PlayerLevel`. Live regulation distribution: `CySEC` 216 configs (avg referrer USD $216.7, referred $0 — referrer-only payout dominant in EU), `ASIC & GAML` 12, `FSRA` 12, `FSA Seychelles` 5, `FCA` 3 ($50/$0 split), `FinCEN+FINRA` 1, `FinCEN` 1, `eToroUS` 1 — all three US regulations use the symmetric $30/$30 split with 14-day wait and `DaysToCheckMinPositionsAmountFromRegistration = 0`. EU configs use 7-day wait and 90-day position-check.

The OLTP source is `experience.bronze_etoro_customer_rafgiven` (291,080 rows — matches the RafGiven slice exactly, +3 rows in transit). Schema is leaner: `ReferringCID`, `ReferredCID`, `RowInserted` timestamp, `ID`, `ReferringCompensationAmount`, `ReferredCompensationAmount`. This is the per-event ledger; `v_raf` is a JOIN/ENRICH on top with player-level + country + regulation context.

Pre-validation cohort `general.bronze_etoro_customer_rafeligiblecustomers` (2,194 rows) — the engine's candidate queue. Schema: `ReferringCID`, `ReferredCID`, `ReferringRegulationId`, `ReferringCountryId`, `ReferringPlayerLevelId`, `ReferringPILevel`, `ReferredRegulationId`, `ReferredCountryId`, `CreatedDate`, `RafStatus` (the bitmask INT). These have NOT yet been compensated — they're either in cooling-off, failing checks, or waiting on the engine.

Two RAF model types per `bronze_rafcompensations_dictionary_rafmodeltype`:
- `RafModelTypeID = 1` (`Club`) — keyed by `Dictionary.RafPlayerLevel` (the standard 5-level Club tiering)
- `RafModelTypeID = 2` (`PI`) — keyed by `Dictionary.GuruStatus` (Popular-Investor tiering — Cadet, Champion, Rising Star, Elite, etc.)

So a single customer with both a Club tier AND a PI status has potentially two parallel RAF policies — the engine picks based on the referring side's classification.

### Airdrops

`bi_db.bronze_marketperformance_airdrop_customer` (6M rows, 23 cols, SCD-2). One row per `(GCID, ConfigurationID)` with `ValidFrom` / `ValidTo` history. The 7-status airdrop lifecycle (`bronze_marketperformance_dictionary_airdropstatus`):

| AirdropStatusID | Name | Count (all SCD versions) |
|---:|---|---:|
| 1 | `NotEligible` | 2,766,260 (~46% — country / regulation policy excludes) |
| 2 | `Eligible` | 535,265 (~9% — eligible, awaiting customer action) |
| 3 | `InstrumentSelected` | 1,821,168 (~30% — customer picked the inducement-share) |
| 4 | `Given` | 615,222 (~10% — airdrop fully delivered) |
| 5 | `Declined` | 172,269 (~3% — customer declined the offer) |
| 6 | `PositionOpenRequested` | 757 (~0% — open in progress) |
| 7 | `Failed` | 89,079 (~1% — failed to deliver, see `bronze_marketperformance_airdrop_customererrors`) |

Funnel: `NotEligible` → `Eligible` → `InstrumentSelected` → `PositionOpenRequested` → `Given` is the canonical happy path. `Declined` and `Failed` are exits. ~10% of all (`Given`) eligibility-events convert to a fully-given airdrop.

Configuration `general.bronze_marketperformance_airdrop_configuration` is per `RegulationID × CountryID × EligibilityTypeID × AirdropPlanID` with `Amount × CurrencyID`, the time-window `OfferActiveFrom` / `OfferActiveTo` / `GiveExpiresOn`, the policy `IsActive` flag, `ShowPlannedInvestmentTypes`, and the A/B-test linkage `experiment_variation_id` — this joins back to `domain-product-analytics/ab-testing-and-experimentation.md`'s `bi_output_product_analytics_abtoro_experiment_participants` for "which airdrop variant won this A/B test".

Related tables:
- `general.bronze_marketperformance_dictionary_airdropplan` — plan name / metadata. Known `AirdropPlanName` values: "Level3AndFTD" (99%+ of Given airdrops — requires VL3 + FTD), "Level3" (AcademyLite only — VL3 without FTD gate). Low-cardinality; use `OfferTypeName` for meaningful segmentation instead.
- `general.bronze_marketperformance_dictionary_airdropeligibilitytype` — eligibility-type semantics (free-trade-promo, NPS-promo, deposit-promo).
- `general.bronze_marketperformance_dictionary_airdropoffertypes` — **offer-type dictionary**. 3 rows as of 2026-06-23 (mutable — always join, never hardcode IDs): `OfferTypeID=1` = Classic (retention/organic incentive); `OfferTypeID=2` = Affiliate (acquisition via affiliate/RAF channel); `OfferTypeID=3` = AcademyLite (educational engagement reward). This is the primary segmentation axis for airdrop campaign analysis.
- `general.bronze_marketperformance_dictionary_airdroptradingerrorcodes` — Failed-status error codes.
- `general.bronze_marketperformance_dictionary_airdropstatusreason` — reasons for status transitions.
- `experience.bronze_marketperformance_airdrop_customererrors` — per-customer error log for `AirdropStatusID = 7` (Failed) rows.
- `trading.bronze_etoro_trade_positionairdroplog` — **the position execution bridge**. One row per airdrop-to-position execution attempt. Key columns: `AirdropID` (BIGINT PK), `CID` (INT), `InstrumentID` (INT — FK to Dim_Instrument), `Amount` (DECIMAL 19,4), `HedgeServerID` (INT), `RequestOccurred` (TIMESTAMP — when airdrop engine requested position open), `UserName` (STRING — operator/system that initiated), `ExecutionOccurred` (TIMESTAMP — when position was actually created; NULL if failed/pending), `PositionID` (BIGINT — the created position; NULL if failed), `Result` (INT — 1=success, 0=failure), `FailReason` (STRING — error message when Result=0), `AmountInUnits` (DECIMAL 16,6 — position size in shares/units), `Cusip` (STRING — US equities), `ApexID` (STRING — Apex account ref for US), `Rate` (DECIMAL 21,6 — execution price), `TerminalID` (STRING), `CompensationReasonID` (INT — FK to `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason`; NULL for old records). Confirmed schema (DESCRIBE 2026-06-24): 17 business cols + 3 pipeline partition cols (`etr_y`, `etr_ym`, `etr_ymd`), partitioned by `etr_ymd` in **dashed-string** format (`'2026-06-24'`). There is NO direct FK to `airdrop_customer` — join on `CID + InstrumentID + date proximity` (see Warning 12).
- `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason` — **compensation reason dim (gold)** for `positionairdroplog`. Join key: `CompensationReasonID` (INT PK). Label col: `Name` (STRING). Also carries `ParentID` (INT — 2-level hierarchy, root categories 1=Custom / 4=Marketing / 9=Accounting-Ops / 10=R&D / 45=Dividend …), `DWHCompensationID` (redundant — equals CompensationReasonID), `StatusID` (hardcoded 1, no filter value), `UpdateDate` / `InsertDate` (ETL load stamps, not business dates). Airdrop-relevant values verified 2026-06-24 via the definitional `airdrop_customer` join (`AirdropStatusID=4`, 60-day): 138 = "AirDrop NWA" (~80%, primary acquisition airdrop), 20 = "Special Promotion" (~19% — generic code reused for both airdrop AND non-airdrop compensations; NOT exclusively airdrop), 94 = "Promotion - Leads" (<1%, 35 positions), 131 = "Academy Lite" (<1%, 27 positions) — these 4 are the ONLY codes the airdrop join surfaces. A STANDALONE scan of `positionairdroplog` (no join) is dominated by NON-airdrop comp — 91=Staking (262k), 92=Promotion (80k), 76=Stock Dividend (53k), and 58="Position Airdrop" (22k, airdrop-named but NOT captured by the `airdrop_customer` flow) all outrank 138 — which is exactly why the definitional airdrop filter is the CID + Instrument + date join to `airdrop_customer`, never a CompensationReasonID value.
- `sharepoint.silver_sharepoint_dealing_staking_airdrop_hs` — Dealing-side hedging record (small). Excel-on-SharePoint via Fivetran (live). Pre-2026 sibling `dealing.bronze_fivetran_dealing_staking_airdrop_hs` is STALE (last sync 2026-02-03) — do NOT use.
- `product_analytics_stg.bi_output_product_analytics_airdrop_financial_metrics` — financial roll-up of airdrop cost-vs-revenue (lives in product-analytics-stg, owned by the airdrop-team).
- `product_analytics_stg.bi_output_product_analytics_giorgich_tables_airdrop_2` — owner-prefixed personal table; non-canonical.

### Loyalty offers & promo cards

CRM-side loyalty objects:
- `crm.silver_crm_loyalty_offer__c` — the offer template (which-club-tier-gets-which-perk).
- `crm.silver_crm_loyalty_offer_request__c` — per-customer offer-claim event.
- `crm.silver_crm_benefit_loyalty__c` — the per-benefit catalogue.
- `bi_output.bi_output_customer_customer_facing_club_loyalty_offer` / `_request` — BI-layer roll-ups of the same.

Promo cards (debit-card-style cashback promos):
- `bi_output.bi_output_marketing_promotion_bi_db_promo_card` — per-customer promo card issued.
- `bi_output.bi_output_marketing_promotion_bi_db_bounceback_promo_card` — re-engagement (bounceback) variant.
- `bi_output_stg.bi_output_marketing_promotion_bi_db_promocard` / `_bounceback_promocard` — staging variants.

These are MARKETING-side issuance / redemption tracking; the actual eMoney-card cashback per-card-transaction lives in `domain-payments` (the `vg_promo_card_cashback` table at 81 queries/week is the eMoney-side cashback per transaction, not the marketing-issuance event).

## Critical Warnings

1. **Tier 1 — `RafStatusID` is a 17-BIT BITMASK (powers of 2: 1, 2, 4, ..., 65536), and `RafStatusName` is the comma-concatenated set of bits-set, not a single value.** ~70 distinct serialised combinations are observed. For "did the referring side fail" use `RafStatusName LIKE '%Referring%'`. For "did MORE than one criterion fail" count commas: `LENGTH(RafStatusName) - LENGTH(REPLACE(RafStatusName,',','')) + 1`. NEVER assume `RafStatusName = 'Fraud'` finds all fraud cases — `Fraud` is bit 2 (value 2), but in practice fraud is exclusive (`Fraud` alone, no other bits) because the engine short-circuits on fraud detection. For ALL non-success, just filter `RafStatusName <> 'RafGiven'`.

2. **Tier 1 — `IsValidForRaf` flag on the rafstatus dictionary indicates RETRYABLE failures.** Five bits (`FTDReferringDaysToWaitFromFTD`, `FTDReferredDaysToWaitFromFTD`, `PositionsAmountReferring`, `PositionsAmountReferred`, `GetTotalDepositsError`) are time-or-trade-dependent — they CAN turn into `RafGiven` later, once the customer waits long enough or opens enough positions. The other 12 bits are terminal — no retry path. The RAF engine's tracking-processed queue is `bronze_rafcompensations_customer_raftrackingprocessed`; that's the engine's "re-evaluate later" list.

3. **Tier 1 — RAF is DUAL-SIDED: every successful row has two compensation amounts (referrer + referee).** For "total RAF cost" sum BOTH `ReferringCompensationAmount + ReferredCompensationAmount`. For "customers who got paid as a referrer" use `ReferringCID`; for "customers who got paid as a referee" use `ReferredCID`. The split is country / regulation-specific — UK FCA pays $50 referrer + $0 referee; US (`eToroUS` / `FinCEN`) pays symmetric $30 each; EU `CySEC` averages $216.7 referrer + $0 referred. Don't assume symmetry — always check `v_raf_config` for the active policy.

4. **Tier 1 — `v_raf_config` is per `CountryName × RegulationName × LevelName` and has a `ValidFrom` timestamp.** For "what was the active policy on date X" filter `WHERE ValidFrom <= '<date>'` and pick the latest per Country × Regulation × Level. There is NO `ValidTo` — older configs remain in the table as historical snapshots; the engine just uses the most-recent-by-ValidFrom.

5. **Tier 1 — `CompensationDate` LAGS the referred customer's registration by `DaysToWaitFromFTD` + `DaysToCheckMinPositionsAmountFromRegistration`.** Typically 7-90 days. For "RAF cost in May 2026" filter `CompensationDate` (when the money moved) — NOT `bronze_etoro_customer_rafgiven.RowInserted` (when the ledger row was inserted, which may be earlier). The referred customer's `dim_customer_masked.FTDFirstDate` may be from months earlier.

6. **Tier 1 — Airdrop campaign attribution requires a 2-layer join: OfferTypeID → OfferTypeName for category, then Mixpanel `'Airdrop Delivered BE'` event for affiliate/campaign ID.** There is NO direct CampaignID column on `airdrop_customer`. The chain: (1) `airdrop_customer.OfferTypeID` → JOIN `general.bronze_marketperformance_dictionary_airdropoffertypes` ON `OfferTypeID` → `OfferTypeName` gives the CATEGORY (3 values as of 2026-06-23: **Classic** = retention/organic, **Affiliate** = acquisition/campaign-driven, **AcademyLite** = educational/engagement; this dictionary is mutable — always join, never hardcode IDs). (2) JOIN `main.mixpanel.silver` WHERE `mp_event_name = 'Airdrop Delivered BE'` ON `CAST(mp_user_id AS INT) = airdrop_customer.GCID` + date proximity to `GivenDate` — this event fires at delivery and carries `affiliateid_numeric` per GCID. (3) `affiliateid_numeric = 11` → RAF (Refer-A-Friend); non-NULL other values → paid affiliate partner (join to `dim_affiliate_masked` for name/channel/group); NULL → no campaign attribution (organic/retention — typical for `OfferTypeName = 'Classic'`). Verified 2026-06-23 via workspace query `01f16a31-d346-181f-9d66-19d974117da0`.

7. **Tier 2 — Two RAF model types coexist: `Club` (RafModelTypeID=1, keyed by PlayerLevel) and `PI` (RafModelTypeID=2, keyed by GuruStatus).** A single customer with both a Club tier AND a PI status has potentially two policies. The engine picks based on `ReferringIsPI = 1` → PI model; else Club model. For "PI RAF performance" filter `WHERE ReferringIsPI = 1`.

8. **Tier 2 — `bronze_etoro_customer_rafeligiblecustomers` (2,194 candidates) is NOT the same as `v_raf`'s non-RafGiven slice (~22k).** Eligibility is the engine's WAITING-TO-EVALUATE list; `v_raf` is the engine's EVALUATED ledger including failures. A candidate transitions: `rafeligiblecustomers` → engine evaluates → `v_raf` row appears with `RafStatusName` set. The eligible-but-unevaluated rows are a small queue.

9. **Tier 2 — Airdrop `bronze_marketperformance_airdrop_customer` is SCD-2 (`ValidFrom` / `ValidTo`).** For "active airdrop state now" filter `WHERE ValidTo IS NULL` (zero matches today suggests the SCD field is populated differently — actually all rows have `ValidTo` set; check `MAX(ValidFrom)` per `(GCID, ConfigurationID)` instead). For "ever-given airdrops" filter `AirdropStatusID = 4` directly. The four lifecycle timestamps `AcceptedDate / PurchaseRequestDate / GivenDate / ExaustedDate` are the milestones — most analytical questions use `GivenDate`.

10. **Tier 2 — Airdrop status enum: 1=NotEligible 2=Eligible 3=InstrumentSelected 4=Given 5=Declined 6=PositionOpenRequested 7=Failed.** Funnel is `NotEligible` → `Eligible` → `InstrumentSelected` → `PositionOpenRequested` → `Given`; with `Declined` and `Failed` as terminal exits. Status 6 (`PositionOpenRequested`) is transient (<1k rows) — most flows skip directly through. For "airdrop conversion rate" use `Given / Eligible` per cohort window. Note that `InstrumentSelected` is HIGH (1.82M of 6M ≈ 30%) but `Given` is LOWER (615k ≈ 10%) — many customers select but never actually OPEN the position to receive the airdrop.

11. **Tier 2 — Airdrop A/B tests link via `experiment_variation_id` on `bronze_marketperformance_airdrop_configuration` to `bi_output_product_analytics_abtoro_experiment_participants.exp_variation_id`.** This is the canonical join to ABtoro. The CONFIGURATION carries the experiment variation, not the customer-level airdrop record — so per-customer experiment attribution requires `airdrop_customer.ConfigurationID` → `airdrop_configuration.experiment_variation_id` → `abtoro_experiment_participants` for the participant cohort.

12. **Tier 2 — `positionairdroplog` joins to `airdrop_customer` on `CID + InstrumentID + date proximity` — there is no direct FK column.** Reliable join pattern:
    ```sql
    LEFT JOIN main.trading.bronze_etoro_trade_positionairdroplog pal
      ON pal.CID = a.CID
      AND pal.InstrumentID = a.SelectedInstrumentID
      AND pal.etr_ymd >= DATE_FORMAT(<start_date>, 'yyyy-MM-dd')
      AND pal.ExecutionOccurred BETWEEN a.GivenDate - INTERVAL 2 DAYS AND a.GivenDate + INTERVAL 2 DAYS
    ```
    In practice, PurchaseRequestDate → GivenDate → ExecutionOccurred are within 1 second (atomic transaction), but use a 2-day window for safety against timezone/partition edge cases. This join IS the airdrop filter — any row that matches is definitionally an airdrop position. Do NOT rely on hardcoded `CompensationReasonID` values as an airdrop filter: a standalone scan of `positionairdroplog` is dominated by NON-airdrop comp (91=Staking, 92=Promotion, 76=Stock Dividend, 58=Position Airdrop all outrank 138=AirDrop NWA), so guessing reason codes returns the wrong population (verified 2026-06-24). Resolve names via the gold dim `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason` (join key `CompensationReasonID`, label `Name`), never hardcode IDs.

13. **Tier 2 — `AirdropPlanName` is nearly all "Level3AndFTD" (99%+) and provides minimal segmentation value.** The customer must reach Verification Level 3 AND make a First Time Deposit before the airdrop converts to a position. The only exception is `AcademyLite` offers which use plan "Level3" (VL3 only, no FTD gate). Use `OfferTypeName` (Classic / Affiliate / AcademyLite via dictionary join) as the primary segmentation axis for airdrop campaign breakdowns — not `AirdropPlanName`.

14. **Tier 3 — `_2024campaigns_incentivisedcids` and `campaigns2025_incentivisedcids` are personal / annual cohort tables.** Under `bi_output_stg.*` — these enumerate CIDs that received some kind of incentive in a given year. Not canonical for ongoing analysis; use the RAF / airdrop / promo-card source tables. Owner-prefixed personal experimental tables exist under `bi_output_stg.*` (`hackathon_acquisition`, `live-acquisition-insights*`, etc.) — non-canonical.

15. **Tier 3 — `bronze_rafcompensations_dictionary_*` tables (CopyPositionStatusID, CopyType, OrderStatus, PositionStatus, PlanType, etc.) are LOOKUP DICTIONARIES used by the RAF engine to validate referrals where the referred customer's TRADING activity matters.** These are not directly analytically useful for marketing rollups — they're internal to the engine logic. Treat as reference data; ignore unless deeply debugging an engine decision.

16. **Tier 3 — Loyalty `silver_crm_loyalty_offer__c` is Salesforce CRM-grain (`__c` = Salesforce custom object) and may have stale records from inactive Salesforce campaigns.** Filter on `IsDeleted = false` and the salesforce-standard `LastModifiedDate` for currency. For "live loyalty offers" cross-check `bi_output.bi_output_customer_customer_facing_club_loyalty_offer` which is the BI-curated view.

17. **Tier 3 — Promo cards `bi_output_marketing_promotion_bi_db_promo_card` (issuance) ≠ `vg_promo_card_cashback` (per-transaction cashback in eMoney).** The MARKETING-side tracks WHO got the promo card; the eMoney-side tracks WHAT TRANSACTIONS earned cashback. Different grains, different domains. For "how many customers received promo card X" use this hub; for "total cashback paid on promo card X" use `domain-payments-eMoney`.

## Canonical query patterns

See [`references/raf-and-incentives-query-patterns.md`](references/raf-and-incentives-query-patterns.md) for Patterns A–G:
- **A** — Total RAF cost last quarter (referrer + referee split)
- **B** — Top RAF failure reasons by country
- **C** — Per-country active RAF policy lookup
- **D** — Airdrop conversion funnel last month
- **E** — Multi-reason RAF failure analysis (3+ bits set)
- **F** — Full airdrop-to-position-to-campaign chain (2026-06-23)
- **G** — Aggregate airdrop volume by offer type × compensation reason (2026-06-23)

## Federation hooks

- `v_raf.ReferringCID` AND `ReferredCID` both join to `dim_customer_masked` — for full dual-sided enrichment use TWO LEFT JOINs (referring-side and referred-side). See `../domain-customer-and-identity/customer-master-record.md`.
- `v_raf.ReferringPlayerLevelID` / `ReferringRegulationID` to `dim_playerlevel` / `dim_regulation` for label expansion — these dims live in customer-and-identity.
- `bronze_marketperformance_airdrop_configuration.experiment_variation_id` joins to `bi_output_product_analytics_abtoro_experiment_participants.exp_variation_id`. See `../domain-product-analytics/ab-testing-and-experimentation.md`.
- `positionairdroplog.PositionID` joins to `dim_position` / `de_output_etoro_kpi_fact_customeraction_w_metrics` for full position lifecycle + P&L. See `../domain-trading/position-state-and-grain.md`.
- `mixpanel.silver` (event `'Airdrop Delivered BE'`) → `affiliateid_numeric = 11` flags RAF-sourced airdrops; other non-NULL values join to `dim_affiliate_masked.AffiliateID` for paid-affiliate attribution. Cross-skill: `domain-product-analytics/mixpanel-events-and-pageviews.md` owns the Mixpanel layer.
- Promo-card issuance (this hub) vs eMoney cashback per-transaction (payments hub) — `bi_output.vg_promo_card_cashback` is on the eMoney side; see `../domain-payments/` (eMoney sub-skill, future).
- For the impact of RAF on overall acquisition funnel, the live acquisition dashboard counts RAF-attributed FTDs separately under `FunnelFromName` values like `Refer-a-Friend Landing Page` — see [`affiliate-and-paid-media.md`](affiliate-and-paid-media.md).

## Last verified

2026-06-24 — full RAF bitmask enumerated (17 bits, `IsValidForRaf` flag for retryability); `RafStatusName` distribution sampled (1 success + 4 single-reason + ~65 multi-reason combinations); `v_raf_config` regulation distribution (CySEC 216, ASIC 12, FSRA 12, FSA Seychelles 5, FCA 3, eToroUS / FinCEN / FinCEN+FINRA 1 each); airdrop status enum confirmed (7 states from `bronze_marketperformance_dictionary_airdropstatus`); airdrop SCD-2 history verified. **Live UC probes 2026-06-24 (DESCRIBE + sampled):** `positionairdroplog` full schema verified (17 business cols + etr_y/etr_ym/etr_ymd partitions; `etr_ymd` confirmed dashed-string `'2026-06-24'`, NOT YYYYMMDD-int despite the column comment); compensation-reason lookup migrated from `billing.bronze_etoro_backoffice_compensationreason` to the gold dim `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_compensationreason` (join key=CompensationReasonID PK, label=Name; ID 138 resolves to "AirDrop NWA" in the gold dim despite a stale "0–134" range comment); airdrop-join distribution re-verified (4 codes only: 138 ~80%, 20 ~19%, 94 35-pos, 131 27-pos) and contrasted with the standalone scan dominated by 91=Staking / 92=Promotion / 76=Stock Dividend / 58=Position Airdrop (proving the join — not a reason-code filter — is the definitional airdrop selector). `dictionary_airdropoffertypes` verified (3 rows: Classic/Affiliate/AcademyLite); Mixpanel `'Airdrop Delivered BE'` event and `affiliateid_numeric=11` RAF attribution verified via production query; AirdropPlanName distribution confirmed (99%+ Level3AndFTD, AcademyLite uses Level3). All dictionaries confirmed mutable — use join patterns, not hardcoded ID filters.
