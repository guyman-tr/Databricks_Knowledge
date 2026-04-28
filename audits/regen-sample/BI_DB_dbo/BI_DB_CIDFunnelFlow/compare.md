# Compare — `BI_DB_dbo.BI_DB_CIDFunnelFlow`

**Bucket**: `good`

**Verdict**: **BETTER**  (score delta +0.75; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 6.8 | 7.55 | 0.75 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 37 | 37 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 10 | +10 |
| T2 count | 37 | 26 | -11 |
| T3 count | 0 | 1 | +1 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 8 |
| data_evidence | 9 | 7 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 5 | 8 |
| upstream_fidelity | 2 | 5 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `3` | 0.17 | 2 | 1 | Geographic macro-region of the customer's registered country (e.g., 'Europe', 'Asia', 'Americas'). Resolved from Dim_Country via CountryID. NULL if country not in Dim_Country. (Tier 2 — Dim_Country) | Marketing region label for the customer's country. Loaded from etoro.Dictionary.MarketingRegion.Name via JOIN on MarketingRegionID. NOT the geographic region from Dictionary.Region. 22 distinct values |
| `26` | 0.194 | 2 | 3 | **Always NULL** — column exists in DDL but SP_CIDFunnelFlow never inserts a value. Intended to represent POA+POI+PhoneVerified triple-flag combination; implementation was not completed. Do not use in  | NOT POPULATED by the current SP_CIDFunnelFlow — column exists in DDL but is absent from the INSERT column list. Always NULL. Likely intended to combine POA+POI+Phone verification but never implemented |
| `8` | 0.2 | 2 | 1 | Customer acquisition funnel name from Dim_Funnel (e.g., 'eToro Web', 'eToro App'). Resolved in the main INSERT SELECT via LEFT JOIN on FunnelFromID. Identical to FunnelFrom — see Business Logic §2.6.  | Unique human-readable label for the registration funnel. Describes the campaign/channel/product that drove registration. Passthrough from Dim_Funnel.Name via FunnelFromID. (Tier 1 — Dictionary.Funnel) |
| `7` | 0.213 | 2 | 2 | Acquisition sub-channel granularity below Channel (e.g., specific SEM brand/non-brand split, affiliate tier). Resolved from Dim_Channel.SubChannel via Dim_Affiliate.SubChannelID. (Tier 2 — Dim_Channel | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Direct', 'Direct Mobile'. Resolved via Dim_Customer.Affili |
| `21` | 0.219 | 2 | 1 | AML/PEP screening result from Dim_ScreeningStatus.Name (e.g., 'NoMatch', 'PendingInvestigation', 'RiskMatch', 'PEP', 'SanctionsMatch'). NULL (66.9%) means no screening result recorded; 'NoMatch' = 31. | AML/compliance screening outcome name. Values: 'NoMatch' (clean), 'PendingInvestigation', 'PEP' (Politically Exposed Person), 'RiskMatch', 'SanctionsMatch', 'Unknown', 'Technical', 'MultipleMatch'. Em |
| `11` | 0.24 | 2 | 1 | Affiliate partner identifier from Dim_Customer.AffiliateID. GROUP BY key used to link to affiliate program records. NULL if customer was not referred via an affiliate. (Tier 2 — Dim_Customer) | Affiliate (partner) ID under which the customer was acquired (renamed from SerialID). FK to BackOffice.Affiliate. NULL for direct/organic registrations. Passthrough from Dim_Customer. (Tier 1 — Custom |
| `14` | 0.241 | 2 | 2 | Registration milestone flag. Always 1 for all rows in this table (population is already filtered to RegisteredReal > '19000101' and IsValidCustomer=1). The sentinel date guard confirms a valid registr | Registration flag. 1 if the customer has a valid registration date (RegisteredReal > '19000101'). Always 1 in practice because the population WHERE filter ensures valid registrations only. Used as a c |
| `30` | 0.256 | 2 | 2 | Phone contact attempt flag: 1 if a 'Contacted__c' Salesforce action occurred before FTD (or post-registration for non-converters). Subset of IsContacted. (Tier 2 — BI_DB_UsageTracking_SF.ActionName='C | 1 if a phone contact action (ActionName='Contacted__c') occurred before FTD. Sourced from BI_DB_UsageTracking_SF. 0 otherwise. (Tier 2 — SP_CIDFunnelFlow) |
| `1` | 0.268 | 2 | 1 | Unique customer identifier — one row per customer. Population covers IsValidCustomer=1 customers registered within the rolling 12-month lookback window (3,970,310 distinct values). (Tier 2 — SP_CIDFun | Customer ID — platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| `6` | 0.269 | 2 | 2 | Acquisition marketing channel (e.g., 'Direct', 'SEM', 'SEO', 'Affiliate', 'Media Performance', 'Friend Referral'). Resolved from Dim_Channel via Dim_Affiliate.SubChannelID. Distribution: Direct 57.0%, | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' to 'Affiliate'. Common values: Direct, SEM, SEO, Affiliate, Media  |

## Top issues — regen wiki (per judge)

- [high] `FunnelFrom (#12)` — Tier 1 paraphrase: upstream Dim_Funnel.Name says 'Describes the campaign/channel/product that drove registration' but wiki says 'Describes the funnel the customer came from'. Lost specificity about what a funnel name actually describes.
- [medium] `Funnel (#8) and FunnelFrom (#12)` — Both columns resolve to Dim_Funnel.Name via FunnelFromID — they are identical in the SP. The wiki gives them different descriptions as if they serve different purposes, and does not flag this duplication in Gotchas.
- [medium] `PEP (#21)` — Tagged Tier 1 — ScreeningService.Dictionary.ScreeningStatus, but Dim_ScreeningStatus's own wiki tags Name as Tier 3 (no upstream wiki exists for the root source). The Tier 1 tag implies verbatim inheritance from a documented source that does not exist.
- [low] `Regulation (#10), DesignatedRegulation (#9)` — Dictionary columns with ≤15 values (15 regulations per Dim_Regulation) but no inline key=value enumeration. Should list: 0=None, 1=CySEC, 2=FCA, 3=NFA, 4=ASIC, 5=BVI, 6=eToroUS, 7=FinCEN, etc.
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist with [x]/[ ] marks for P2 (row count) and P3 (distribution analysis). Footer says 'Phases: 12/14' but does not enumerate which phases were completed vs skipped.
