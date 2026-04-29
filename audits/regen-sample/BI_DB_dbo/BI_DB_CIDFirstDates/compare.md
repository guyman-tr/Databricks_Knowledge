# Compare — `BI_DB_dbo.BI_DB_CIDFirstDates`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +2.5; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.8 | 7.3 | 2.5 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 139 | 139 | +0 |
| Untagged count | 51 | 0 | -51 |
| T1 count | 21 | 34 | +13 |
| T2 count | 67 | 54 | -13 |
| T3 count | 0 | 51 | +51 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 6 | 10 |
| data_evidence | 4 | 6 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 2 | 7 |
| upstream_fidelity | 3 | 4 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `91` | 0.041 | None | 2 | **Not populated** by SP. Legacy retention metric. (Tier 3b — DDL structure, not populated) | 1 if customer deposited within 7 days of registration AND FirstDepositAmount > 0. ETL-computed: CASE WHEN DATEDIFF(DAY, registered, FirstDepositDate) < 8 THEN 1 ELSE 0. Only computed for customers reg |
| `84` | 0.058 | 2 | 1 | Last successful phone contact date. PII — masked. MAX(CreatedDate_SF) WHERE ActionName='Phone_Call_Succeed__c'. (Tier 2 — SP_CIDFirstDates, BI_DB_UsageTracking_SF) | Permanent graduation date -- the LATEST of the three funded milestones. Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)). Set once |
| `83` | 0.059 | None | 1 | **Not directly populated** by SP. Legacy column. (Tier 3b — DDL structure, not populated) | 1 if the customer meets ALL four funded criteria on this date: (1) real deposit per Dim_Customer.IsDepositor=1; (2) KYC verified to level 3; (3) at least one non-airdrop activity completed (TP trade,  |
| `32` | 0.074 | None | 1 | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) | Full human-readable geographic name of the region -- state, province, or territory. Sourced from Dictionary.RegionName.Name. Dim-lookup from Dim_State_and_Province.Name via Dim_Customer.RegionID = Reg |
| `48` | 0.078 | 2 | 1 | First copy-trade position open date. Occurred from Fact_CustomerAction WHERE ActionTypeID=2 AND rn=1. (Tier 2 — SP_CIDFirstDates, Fact_CustomerAction) | Customer realized equity (total account value excluding unrealized PnL). Daily snapshot from V_Liabilities.RealizedEquity. Updated only for yesterday's run date. (Tier 1 -- V_Liabilities via Fact_Snap |
| `33` | 0.094 | None | 1 | **Disabled** — demo step disabled. (Tier 3b — DDL structure, disabled) | Manual override name for the marketing region. From Dim_Country.MarketingRegionManualName via CountryID. May differ from Region (e.g., Albania: Region=ROE, NewMarketingRegion=CEE). (Tier 1 -- Ext_Dim_ |
| `16` | 0.113 | 2 | 1 | Customer realized equity (yesterday's snapshot). From V_Liabilities.RealizedEquity, ISNULL(,0). Only updated when @date=@yesterday. (Tier 2 — SP_CIDFirstDates, V_Liabilities) | Platform download source ID. Legacy tracking for which platform installer the customer used. (Tier 1 -- Customer.CustomerStatic) |
| `133` | 0.121 | 1 | 3 | **First date the customer crossed the fully-funded threshold.** Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID)) — the date when a | Disabled 2023-05-09 (Eti Rozolio). (Tier 3 -- deprecated) |
| `94` | 0.132 | 1 | 2 | Version of the privacy policy the customer has accepted. (Tier 1 — Customer.CustomerStatic) | Date of the customer's most recent life-stage event (manual open, mirror open, or mirror registration). MAX(Occurred) as DATE from Fact_CustomerAction WHERE ActionTypeID IN (1,15,17). (Tier 2 -- SP_CI |
| `132` | 0.152 | 1 | 3 | **Funded status flag.** 1 if ALL four criteria hold on the balance date: (1) real deposit excl. bad-FTD cohort (Aug 18–20 2025); (2) KYC verification level 3; (3) at least one non-airdrop activity (TP | ML model score. Not populated by current SP. (Tier 3 -- deprecated) |

## Top issues — regen wiki (per judge)

- [high] `FunnelName (#15)` — Tier 1 description completely paraphrased. Upstream Dim_Funnel.Name says 'Unique human-readable label for the funnel. Used in marketing reports, BackOffice customer views, and attribution analytics.' Wiki says 'Registration funnel name. Tracks which user journey/funnel variant the customer came through.' All upstream specifics lost.
- [high] `FunnelFromName (#17)` — Tier 1 description reduced to a single generic sentence ('Source funnel variant name'). Same upstream source as FunnelName but all content dropped.
- [high] `IsFundedNew (#83)` — Tagged Tier 1 from Function_Population_Funded but is ETL-computed: SP does UPDATE SET IsFundedNew = 1 WHERE CID IN (SELECT RealCID FROM Function_Population_Funded(@dateINT)), else 0. This is a membership test / CASE expression, not a passthrough. Should be Tier 2.
- [high] `FirstNewFundedDate (#84)` — Tagged Tier 1 from Function_Population_First_Time_Funded but the wiki itself describes it as 'Computed as GREATEST(FTDDateID, FirstVerifiedDateID, LEAST(FirstTradeDateID, FirstIOBDateID, FirstOptionsTradeDateID))'. Arithmetic computation = Tier 2, not Tier 1.
- [medium] `Country (#10), Language (#11)` — Country dropped 'Unique per row' and all usage context. Language dropped 'UNIQUE constraint' and 'Used in back-office language selectors and reporting.' Both are dim-lookup passthroughs where the upstream wiki text was available and should have been quoted verbatim.
