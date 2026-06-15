---
name: domain-marketing-and-acquisition
description: "Refer-A-Friend (RAF), airdrops, promo cards, and loyalty offers ג€” the customer-driven viral and incentive layer. Anchors: main.etoro_kpi.v_raf (313k dual-sided referring ֳ— referred ledger with 17-bit BITMASK-encoded RafStatusID that serialises as comma-concatenated RafStatusName strings ג€” 1=RafGiven dominates 93%, with up to 7 simultaneous failure-atoms from FTDReferringCheckAmount / FTDReferringDaysToWaitFromFTD / FTDReferredCheckAmount / FTDReferredDaysToWaitFromFTD / PositionsAmountReferring / PositionsAmountReferred / RegistrationDateExpired plus terminal-state Fraud / NoReferringConfig / NoDefaultReferredConfig / NoMoneyIsSetInConfig / LimitReached / AlreadyGiven / PairNotExists / ReferredStartedAfterBothPlans / GetTotalDepositsError); v_raf_config (251 per-Regulation ֳ— Country ֳ— PlayerLevel configs ג€” CySEC dominates with 216 of 251, US uses asymmetric $30/$30 with 14-day wait, EU regulations use $216.7 referrer + $0 referred); the OLTP-source main.experience.bronze_etoro_customer_rafgiven (291k = the RafGiven slice as compensation events) + bronze_etoro_dwh_rafcustomers (279 enriched cohort rows); the candidate-eligibility table main.general.bronze_etoro_customer_rafeligiblecustomers (2,194 pre-validated candidates with ReferringPILevel + RafStatus INT enum); the per-config bronze_rafcompensations_config_viewconfig + customer_raftrackingprocessed + dictionary tables (RafStatus bitmask, RafModelType = Club vs PI, plus HighLevelDepositStatus / CopyPositionStatus / OrderStatus / PositionStatus / PlanType dictionaries used by the RAF engine to validate referrals); the airdrop incentive engine ג€” main.bi_db.bronze_marketperformance_airdrop_customer (6M SCD-2 rows, 23 cols carrying the 7-status airdrop lifecycle 1=NotEligible 2=Eligible 3=InstrumentSelected 4=Given 5=Declined 6=PositionOpenRequested 7=Failed with timestamps AcceptedDate / PurchaseRequestDate / GivenDate / ExaustedDate) + bronze_marketperformance_airdrop_configuration (per-Regulation ֳ— Country ֳ— EligibilityType ֳ— Plan policy with experiment_variation_id linking back to ABtoro); the promo / loyalty offers ג€” main.crm.silver_crm_benefit_loyalty__c, silver_crm_loyalty_offer__c, silver_crm_loyalty_offer_request__c, main.bi_output.bi_output_marketing_promotion_bi_db_promo_card, and bi_output_marketing_promotion_bi_db_bounceback_promo_card. Use for RAF cost calculation, referral funnel diagnostics, country / regulation policy lookup, airdrop allocation analysis, A/B test linkage on airdrop variants, and loyalty offer redemption tracking."
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
  - OfferTypeID
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
  - main.crm.silver_crm_loyalty_offer__c
  - main.crm.silver_crm_loyalty_offer_request__c
  - main.crm.silver_crm_benefit_loyalty__c
  - main.bi_output.bi_output_marketing_promotion_bi_db_promo_card
version: 1
owner: "dataplatform"
last_validated_at: "2026-06-04"
---

# RAF (Refer-A-Friend) + Airdrops + Loyalty Incentives

The customer-driven viral and incentive layer. Three product flavours: (1) RAF compensates an existing customer for inviting a new one; (2) Airdrops give selected customers free inducement-shares to start trading; (3) Loyalty offers reward Club-tier customers for retention. All three are post-acquisition incentives ג€” they do NOT acquire the customer directly, they MOTIVATE either the inviter (RAF) or the new/existing customer (airdrop/loyalty) toward a specific action.

## What it covers

### RAF ג€” Refer-A-Friend

The canonical view `etoro_kpi.v_raf` (313k rows / 31 cols) is the dual-sided referring ֳ— referred ledger. Each row is ONE referral event with BOTH parties' attributes co-resident: `ReferringCID` / `ReferredCID`, `ReferringGCID` / `ReferredGCID`, `ReferringCompensationAmount` / `ReferredCompensationAmount`, `ReferringCountryID` / `ReferredCountryID`, `ReferringRealizedEquity` / `ReferredRealizedEquity`, `ReferringTotalInvestedAmount` / `ReferredTotalInvestedAmount`, plus the referring-side Popular-Investor flags (`ReferringIsPI`, `ReferringGuruStatusName`) and PlayerLevel fields. `IsProcessed` (INT ג€” 0 / 1) flags whether RAF engine has processed this candidate referral yet; `CompensationDate` is the actual dollar-out date; `ProcessingDate` is the engine-run date.

`RafStatusID` is a **BITMASK** (POWER-OF-2: 1, 2, 4, 8, 16, 32, 64, 128, 256, 512, 1024, 2048, 4096, 8192, 16384, 32768, 65536), serialised in `RafStatusName` as the comma-concatenated set of bits-set:

| BitID | RafStatusName atom | Meaning | IsValidForRaf (retryable) |
|---:|---|---|:---:|
| 1 | `RafGiven` | Success ג€” compensation paid | false |
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
| 4096 | `ReferredStartedAfterBothPlans` | Edge case ג€” referred started after both eligible plans | false |
| 8192 | `NoReferringConfig` | No active config for referring country / regulation / level | false |
| 16384 | `NoDefaultReferredConfig` | No default config for referred side | false |
| 32768 | `GetTotalDepositsError` | Engine couldn't compute total deposits ג€” transient | **true** |
| 65536 | `NoMoneyIsSetInConfig` | Config money is zero | false |

`IsValidForRaf = true` means "this fail might be retryable later" ג€” the four atoms `FTDReferringDaysToWaitFromFTD`, `FTDReferredDaysToWaitFromFTD`, `PositionsAmountReferring`, `PositionsAmountReferred`, plus the transient `GetTotalDepositsError`. The remaining are terminal ג€” won't ever convert to `RafGiven`. This `IsValidForRaf` flag is the basis for the RAF engine's re-evaluation queue (which lives in `bronze_rafcompensations_customer_raftrackingprocessed`).

Live distribution of `RafStatusName` in `v_raf` (sample from a Genie-space probe):
- `RafGiven`: 291,077 (93%)
- `NoReferringConfig`: 5,068 ג€” country / regulation / level combination has no active RAF policy
- `Fraud`: 3,282 ג€” caught by FraudScore on `v_raf_config`
- `RegistrationDateExpired, PositionsAmountReferred`: 2,787 (multi-bit)
- `NoDefaultReferredConfig`: 1,653
- `FTDReferredCheckAmount, FTDReferredDaysToWaitFromFTD, PositionsAmountReferred`: 1,178 (3-bit fail)
- `PositionsAmountReferred`: 1,149
- `RegistrationDateExpired`: 1,117
- `FTDReferredCheckAmount, RegistrationDateExpired`: 915
- `PositionsAmountReferring, PositionsAmountReferred`: 902
- Plus ~65 more multi-bit combinations.

The configuration `etoro_kpi.v_raf_config` (251 rows) is keyed by `Regulation ֳ— Country ֳ— PlayerLevel`. Live regulation distribution: `CySEC` 216 configs (avg referrer USD $216.7, referred $0 ג€” referrer-only payout dominant in EU), `ASIC & GAML` 12, `FSRA` 12, `FSA Seychelles` 5, `FCA` 3 ($50/$0 split), `FinCEN+FINRA` 1, `FinCEN` 1, `eToroUS` 1 ג€” all three US regulations use the symmetric $30/$30 split with 14-day wait and `DaysToCheckMinPositionsAmountFromRegistration = 0`. EU configs use 7-day wait and 90-day position-check.

The OLTP source is `experience.bronze_etoro_customer_rafgiven` (291,080 rows ג€” matches the RafGiven slice exactly, +3 rows in transit). Schema is leaner: `ReferringCID`, `ReferredCID`, `RowInserted` timestamp, `ID`, `ReferringCompensationAmount`, `ReferredCompensationAmount`. This is the per-event ledger; `v_raf` is a JOIN/ENRICH on top with player-level + country + regulation context.

Pre-validation cohort `general.bronze_etoro_customer_rafeligiblecustomers` (2,194 rows) ג€” the engine's candidate queue. Schema: `ReferringCID`, `ReferredCID`, `ReferringRegulationId`, `ReferringCountryId`, `ReferringPlayerLevelId`, `ReferringPILevel`, `ReferredRegulationId`, `ReferredCountryId`, `CreatedDate`, `RafStatus` (the bitmask INT). These have NOT yet been compensated ג€” they're either in cooling-off, failing checks, or waiting on the engine.

Two RAF model types per `bronze_rafcompensations_dictionary_rafmodeltype`:
- `RafModelTypeID = 1` (`Club`) ג€” keyed by `Dictionary.RafPlayerLevel` (the standard 5-level Club tiering)
- `RafModelTypeID = 2` (`PI`) ג€” keyed by `Dictionary.GuruStatus` (Popular-Investor tiering ג€” Cadet, Champion, Rising Star, Elite, etc.)

So a single customer with both a Club tier AND a PI status has potentially two parallel RAF policies ג€” the engine picks based on the referring side's classification.

### Airdrops

`bi_db.bronze_marketperformance_airdrop_customer` (6M rows, 23 cols, SCD-2). One row per `(GCID, ConfigurationID)` with `ValidFrom` / `ValidTo` history. The 7-status airdrop lifecycle (`bronze_marketperformance_dictionary_airdropstatus`):

| AirdropStatusID | Name | Count (all SCD versions) |
|---:|---|---:|
| 1 | `NotEligible` | 2,766,260 (~46% ג€” country / regulation policy excludes) |
| 2 | `Eligible` | 535,265 (~9% ג€” eligible, awaiting customer action) |
| 3 | `InstrumentSelected` | 1,821,168 (~30% ג€” customer picked the inducement-share) |
| 4 | `Given` | 615,222 (~10% ג€” airdrop fully delivered) |
| 5 | `Declined` | 172,269 (~3% ג€” customer declined the offer) |
| 6 | `PositionOpenRequested` | 757 (~0% ג€” open in progress) |
| 7 | `Failed` | 89,079 (~1% ג€” failed to deliver, see `bronze_marketperformance_airdrop_customererrors`) |

Funnel: `NotEligible` ג†’ `Eligible` ג†’ `InstrumentSelected` ג†’ `PositionOpenRequested` ג†’ `Given` is the canonical happy path. `Declined` and `Failed` are exits. ~10% of all (`Given`) eligibility-events convert to a fully-given airdrop.

Configuration `general.bronze_marketperformance_airdrop_configuration` is per `RegulationID ֳ— CountryID ֳ— EligibilityTypeID ֳ— AirdropPlanID` with `Amount ֳ— CurrencyID`, the time-window `OfferActiveFrom` / `OfferActiveTo` / `GiveExpiresOn`, the policy `IsActive` flag, `ShowPlannedInvestmentTypes`, and the A/B-test linkage `experiment_variation_id` ג€” this joins back to `domain-product-analytics/ab-testing-and-experimentation.md`'s `bi_output_product_analytics_abtoro_experiment_participants` for "which airdrop variant won this A/B test".

Related tables:
- `general.bronze_marketperformance_dictionary_airdropplan` ג€” plan name / metadata.
- `general.bronze_marketperformance_dictionary_airdropeligibilitytype` ג€” eligibility-type semantics (free-trade-promo, NPS-promo, deposit-promo).
- `general.bronze_marketperformance_dictionary_airdropoffertypes` ג€” offer-type metadata.
- `general.bronze_marketperformance_dictionary_airdroptradingerrorcodes` ג€” Failed-status error codes.
- `general.bronze_marketperformance_dictionary_airdropstatusreason` ג€” reasons for status transitions.
- `experience.bronze_marketperformance_airdrop_customererrors` ג€” per-customer error log for `AirdropStatusID = 7` (Failed) rows.
- `trading.bronze_etoro_trade_positionairdroplog` ג€” the position-level log when the airdrop becomes an actual open position.
- `sharepoint.silver_sharepoint_dealing_staking_airdrop_hs` ג€” Dealing-side hedging record (small). Excel-on-SharePoint via Fivetran (live). Pre-2026 sibling `dealing.bronze_fivetran_dealing_staking_airdrop_hs` is STALE (last sync 2026-02-03) ג€" do NOT use.
- `product_analytics_stg.bi_output_product_analytics_airdrop_financial_metrics` ג€” financial roll-up of airdrop cost-vs-revenue (lives in product-analytics-stg, owned by the airdrop-team).
- `product_analytics_stg.bi_output_product_analytics_giorgich_tables_airdrop_2` ג€” owner-prefixed personal table; non-canonical.

### Loyalty offers & promo cards

CRM-side loyalty objects:
- `crm.silver_crm_loyalty_offer__c` ג€” the offer template (which-club-tier-gets-which-perk).
- `crm.silver_crm_loyalty_offer_request__c` ג€” per-customer offer-claim event.
- `crm.silver_crm_benefit_loyalty__c` ג€” the per-benefit catalogue.
- `bi_output.bi_output_customer_customer_facing_club_loyalty_offer` / `_request` ג€” BI-layer roll-ups of the same.

Promo cards (debit-card-style cashback promos):
- `bi_output.bi_output_marketing_promotion_bi_db_promo_card` ג€” per-customer promo card issued.
- `bi_output.bi_output_marketing_promotion_bi_db_bounceback_promo_card` ג€” re-engagement (bounceback) variant.
- `bi_output_stg.bi_output_marketing_promotion_bi_db_promocard` / `_bounceback_promocard` ג€” staging variants.

These are MARKETING-side issuance / redemption tracking; the actual eMoney-card cashback per-card-transaction lives in `domain-payments` (the `vg_promo_card_cashback` table at 81 queries/week is the eMoney-side cashback per transaction, not the marketing-issuance event).

## Critical Warnings

1. **Tier 1 ג€” `RafStatusID` is a 17-BIT BITMASK (powers of 2: 1, 2, 4, ..., 65536), and `RafStatusName` is the comma-concatenated set of bits-set, not a single value.** ~70 distinct serialised combinations are observed. For "did the referring side fail" use `RafStatusName LIKE '%Referring%'`. For "did MORE than one criterion fail" count commas: `LENGTH(RafStatusName) - LENGTH(REPLACE(RafStatusName,',','')) + 1`. NEVER assume `RafStatusName = 'Fraud'` finds all fraud cases ג€” `Fraud` is bit 2 (value 2), but in practice fraud is exclusive (`Fraud` alone, no other bits) because the engine short-circuits on fraud detection. For ALL non-success, just filter `RafStatusName <> 'RafGiven'`.

2. **Tier 1 ג€” `IsValidForRaf` flag on the rafstatus dictionary indicates RETRYABLE failures.** Five bits (`FTDReferringDaysToWaitFromFTD`, `FTDReferredDaysToWaitFromFTD`, `PositionsAmountReferring`, `PositionsAmountReferred`, `GetTotalDepositsError`) are time-or-trade-dependent ג€” they CAN turn into `RafGiven` later, once the customer waits long enough or opens enough positions. The other 12 bits are terminal ג€” no retry path. The RAF engine's tracking-processed queue is `bronze_rafcompensations_customer_raftrackingprocessed`; that's the engine's "re-evaluate later" list.

3. **Tier 1 ג€” RAF is DUAL-SIDED: every successful row has two compensation amounts (referrer + referee).** For "total RAF cost" sum BOTH `ReferringCompensationAmount + ReferredCompensationAmount`. For "customers who got paid as a referrer" use `ReferringCID`; for "customers who got paid as a referee" use `ReferredCID`. The split is country / regulation-specific ג€” UK FCA pays $50 referrer + $0 referee; US (`eToroUS` / `FinCEN`) pays symmetric $30 each; EU `CySEC` averages $216.7 referrer + $0 referee. Don't assume symmetry ג€” always check `v_raf_config` for the active policy.

4. **Tier 1 ג€” `v_raf_config` is per `CountryName ֳ— RegulationName ֳ— LevelName` and has a `ValidFrom` timestamp.** For "what was the active policy on date X" filter `WHERE ValidFrom <= '<date>'` and pick the latest per Country ֳ— Regulation ֳ— Level. There is NO `ValidTo` ג€” older configs remain in the table as historical snapshots; the engine just uses the most-recent-by-ValidFrom.

5. **Tier 1 ג€” `CompensationDate` LAGS the referred customer's registration by `DaysToWaitFromFTD` + `DaysToCheckMinPositionsAmountFromRegistration`.** Typically 7-90 days. For "RAF cost in May 2026" filter `CompensationDate` (when the money moved) ג€” NOT `bronze_etoro_customer_rafgiven.RowInserted` (when the ledger row was inserted, which may be earlier). The referred customer's `dim_customer_masked.FTDFirstDate` may be from months earlier.

6. **Tier 2 ג€” Two RAF model types coexist: `Club` (RafModelTypeID=1, keyed by PlayerLevel) and `PI` (RafModelTypeID=2, keyed by GuruStatus).** A single customer with both a Club tier AND a PI status has potentially two policies. The engine picks based on `ReferringIsPI = 1` ג‡’ PI model; else Club model. For "PI RAF performance" filter `WHERE ReferringIsPI = 1`.

7. **Tier 2 ג€” `bronze_etoro_customer_rafeligiblecustomers` (2,194 candidates) is NOT the same as `v_raf`'s non-RafGiven slice (~22k).** Eligibility is the engine's WAITING-TO-EVALUATE list; `v_raf` is the engine's EVALUATED ledger including failures. A candidate transitions: `rafeligiblecustomers` ג†’ engine evaluates ג†’ `v_raf` row appears with `RafStatusName` set. The eligible-but-unevaluated rows are a small queue.

8. **Tier 2 ג€” Airdrop `bronze_marketperformance_airdrop_customer` is SCD-2 (`ValidFrom` / `ValidTo`).** For "active airdrop state now" filter `WHERE ValidTo IS NULL` (zero matches today suggests the SCD field is populated differently ג€” actually all rows have `ValidTo` set; check `MAX(ValidFrom)` per `(GCID, ConfigurationID)` instead). For "ever-given airdrops" filter `AirdropStatusID = 4` directly. The four lifecycle timestamps `AcceptedDate / PurchaseRequestDate / GivenDate / ExaustedDate` are the milestones ג€” most analytical questions use `GivenDate`.

9. **Tier 2 ג€” Airdrop status enum: 1=NotEligible 2=Eligible 3=InstrumentSelected 4=Given 5=Declined 6=PositionOpenRequested 7=Failed.** Funnel is `NotEligible` ג†’ `Eligible` ג†’ `InstrumentSelected` ג†’ `PositionOpenRequested` ג†’ `Given`; with `Declined` and `Failed` as terminal exits. Status 6 (`PositionOpenRequested`) is transient (<1k rows) ג€” most flows skip directly through. For "airdrop conversion rate" use `Given / Eligible` per cohort window. Note that `InstrumentSelected` is HIGH (1.82M of 6M ג‰ˆ 30%) but `Given` is LOWER (615k ג‰ˆ 10%) ג€” many customers select but never actually OPEN the position to receive the airdrop.

10. **Tier 2 ג€” Airdrop A/B tests link via `experiment_variation_id` on `bronze_marketperformance_airdrop_configuration` to `bi_output_product_analytics_abtoro_experiment_participants.exp_variation_id`.** This is the canonical join to ABtoro. The CONFIGURATION carries the experiment variation, not the customer-level airdrop record ג€” so per-customer experiment attribution requires `airdrop_customer.ConfigurationID ג†’ airdrop_configuration.experiment_variation_id ג†’ abtoro_experiment_participants` for the participant cohort.

11. **Tier 3 ג€” `_2024campaigns_incentivisedcids` and `campaigns2025_incentivisedcids` are personal / annual cohort tables.** Under `bi_output_stg.*` ג€” these enumerate CIDs that received some kind of incentive in a given year. Not canonical for ongoing analysis; use the RAF / airdrop / promo-card source tables. Owner-prefixed personal experimental tables exist under `bi_output_stg.*` (`hackathon_acquisition`, `live-acquisition-insights*`, etc.) ג€” non-canonical.

12. **Tier 3 ג€” `bronze_rafcompensations_dictionary_*` tables (CopyPositionStatusID, CopyType, OrderStatus, PositionStatus, PlanType, etc.) are LOOKUP DICTIONARIES used by the RAF engine to validate referrals where the referred customer's TRADING activity matters.** These are not directly analytically useful for marketing rollups ג€” they're internal to the engine logic. Treat as reference data; ignore unless deeply debugging an engine decision.

13. **Tier 3 ג€” Loyalty `silver_crm_loyalty_offer__c` is Salesforce CRM-grain (`__c` = Salesforce custom object) and may have stale records from inactive Salesforce campaigns.** Filter on `IsDeleted = false` and the salesforce-standard `LastModifiedDate` for currency. For "live loyalty offers" cross-check `bi_output.bi_output_customer_customer_facing_club_loyalty_offer` which is the BI-curated view.

14. **Tier 3 ג€” Promo cards `bi_output_marketing_promotion_bi_db_promo_card` (issuance) ג‰  `vg_promo_card_cashback` (per-transaction cashback in eMoney).** The MARKETING-side tracks WHO got the promo card; the eMoney-side tracks WHAT TRANSACTIONS earned cashback. Different grains, different domains. For "how many customers received promo card X" use this hub; for "total cashback paid on promo card X" use `domain-payments-eMoney`.

## Canonical query patterns

### Pattern A ג€” Total RAF cost last quarter (referrer + referee)

```sql
SELECT
  DATE_TRUNC('month', CompensationDate) AS month,
  ReferringRegulationName AS regulation,
  COUNT(*) AS n_referrals,
  SUM(ReferringCompensationAmount + ReferredCompensationAmount) AS total_cost_usd,
  SUM(ReferringCompensationAmount) AS referrer_cost_usd,
  SUM(ReferredCompensationAmount)  AS referee_cost_usd
FROM main.etoro_kpi.v_raf
WHERE RafStatusName = 'RafGiven'
  AND CompensationDate >= DATE_TRUNC('quarter', current_date) - INTERVAL 1 QUARTER
  AND CompensationDate <  DATE_TRUNC('quarter', current_date)
GROUP BY 1, 2
ORDER BY 1, 2
```

### Pattern B ג€” Top RAF failure reasons by country

```sql
SELECT
  ReferringCountry,
  CASE
    WHEN RafStatusName LIKE '%FTDReferring%' THEN 'Referring FTD check'
    WHEN RafStatusName LIKE '%FTDReferred%'  THEN 'Referred FTD check'
    WHEN RafStatusName LIKE '%PositionsAmountReferring%' THEN 'Referring positions check'
    WHEN RafStatusName LIKE '%PositionsAmountReferred%'  THEN 'Referred positions check'
    WHEN RafStatusName LIKE '%RegistrationDateExpired%'  THEN 'Registration date expired'
    WHEN RafStatusName = 'Fraud'                THEN 'Fraud'
    WHEN RafStatusName = 'NoReferringConfig'    THEN 'No referring config'
    WHEN RafStatusName = 'NoDefaultReferredConfig' THEN 'No referred config'
    WHEN RafStatusName = 'LimitReached'         THEN 'Limit reached'
    WHEN RafStatusName = 'NoMoneyIsSetInConfig' THEN 'Config money is zero'
    WHEN RafStatusName = 'RafGiven'             THEN 'Success'
    ELSE 'Multi-reason'
  END AS reason_category,
  COUNT(*) AS n_referrals
FROM main.etoro_kpi.v_raf
GROUP BY 1, 2
ORDER BY 1, n_referrals DESC
LIMIT 100
```

### Pattern C ג€” Per-country active RAF policy lookup

```sql
SELECT
  CountryName,
  RegulationName,
  LevelName,
  ReferringCompensationInDollar AS referrer_payout_usd,
  ReferredCompensationInDollar  AS referee_payout_usd,
  MaxNumberOfCompensations      AS max_per_referrer,
  DaysToWaitFromFTD,
  DaysToCheckMinPositionsAmountFromRegistration,
  FraudScore,
  ValidFrom
FROM main.etoro_kpi.v_raf_config
WHERE CountryName = 'United Kingdom'
ORDER BY ValidFrom DESC
LIMIT 10
```

### Pattern D ג€” Airdrop conversion funnel last month

```sql
SELECT
  s.AirdropStatusName,
  COUNT(*) AS n_rows,
  COUNT(DISTINCT a.GCID) AS n_distinct_customers
FROM main.bi_db.bronze_marketperformance_airdrop_customer a
JOIN main.general.bronze_marketperformance_dictionary_airdropstatus s
  ON s.AirdropStatusID = a.AirdropStatusID
WHERE a.ValidFrom >= DATE_TRUNC('month', current_date) - INTERVAL 1 MONTH
  AND a.ValidFrom <  DATE_TRUNC('month', current_date)
GROUP BY 1
ORDER BY MIN(a.AirdropStatusID)
```

### Pattern E ג€” Multi-reason RAF failure analysis (3+ bits set)

```sql
SELECT
  RafStatusName,
  LENGTH(RafStatusName) - LENGTH(REPLACE(RafStatusName, ',', '')) + 1 AS n_failure_atoms,
  COUNT(*) AS n_referrals
FROM main.etoro_kpi.v_raf
WHERE RafStatusName <> 'RafGiven'
  AND RafStatusName LIKE '%,%,%'
GROUP BY 1, 2
ORDER BY n_failure_atoms DESC, n_referrals DESC
LIMIT 30
```

## Federation hooks

- `v_raf.ReferringCID` AND `ReferredCID` both join to `dim_customer_masked` ג€” for full dual-sided enrichment use TWO LEFT JOINs (referring-side and referred-side). See `../domain-customer-and-identity/customer-master-record.md`.
- `v_raf.ReferringPlayerLevelID` / `ReferringRegulationID` to `dim_playerlevel` / `dim_regulation` for label expansion ג€” these dims live in customer-and-identity.
- `bronze_marketperformance_airdrop_configuration.experiment_variation_id` joins to `bi_output_product_analytics_abtoro_experiment_participants.exp_variation_id`. See `../domain-product-analytics/ab-testing-and-experimentation.md`.
- Promo-card issuance (this hub) vs eMoney cashback per-transaction (payments hub) ג€” `bi_output.vg_promo_card_cashback` is on the eMoney side; see `../domain-payments/` (eMoney sub-skill, future).
- For the impact of RAF on overall acquisition funnel, the live acquisition dashboard counts RAF-attributed FTDs separately under `FunnelFromName` values like `Refer-a-Friend Landing Page` ג€” see [`affiliate-and-paid-media.md`](affiliate-and-paid-media.md).

## Last verified

2026-05-28 ג€” full RAF bitmask enumerated (17 bits, `IsValidForRaf` flag for retryability); `RafStatusName` distribution sampled (1 success + 4 single-reason + ~65 multi-reason combinations); `v_raf_config` regulation distribution (CySEC 216, ASIC 12, FSRA 12, FSA Seychelles 5, FCA 3, eToroUS / FinCEN / FinCEN+FINRA 1 each); airdrop status enum confirmed (7 states from `bronze_marketperformance_dictionary_airdropstatus`); airdrop SCD-2 history verified.
