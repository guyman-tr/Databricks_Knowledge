# Compare — `BI_DB_dbo.BI_DB_AffData`

**Bucket**: `dormant`

**Verdict**: **BETTER**  (score delta +0.3; slop 10 -> 0 (delta -10))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.9 | 8.2 | 0.3 |
| Slop hits (`Tier 4 ... inferred`) | 10 | 0 | -10 |
| Element rows | 11 | 11 | +0 |
| Untagged count | 0 | 11 | +11 |
| T1 count | 0 | 0 | +0 |
| T2 count | 0 | 0 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 10 | 0 | -10 |
| T5 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 8 | 9 |
| data_evidence | 5 | 5 |
| shape_fidelity | 7 | 9 |
| tier_accuracy | 10 | 9 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `7` | 0.088 | 4 | None | Classification of the contract arrangement type. (Tier 4 — inferred from column name) | Affiliate payment model. In Dim_Affiliate this is a tinyint code (0=N/A, 2=CPA, 3=RevShare, 4=Hybrid, 6=eCost, 7=Zero Commission, 8=CPL/CPR); here it is varchar(20) — may store the text label instead  |
| `3` | 0.105 | 4 | None | Date when the affiliate registered in the partner program. (Tier 4 — inferred from column name) | Affiliate registration date. Naming pattern (Aff_ prefix) suggests this is the affiliate's registration/creation date in AffWizz, correlating with Dim_Affiliate.DateCreated. (Tier 3b — DDL structure,  |
| `5` | 0.143 | 4 | None | Affiliate's email address. Protected with dynamic data masking (default function). Requires DataplatformPII role for unmasked access. (Tier 4 — inferred from column name) | Affiliate email address. **PII column** — dynamic data masking applied with `FUNCTION = 'default()'`. UNMASK granted to DataplatformPII role. Naming pattern correlates with Dim_Affiliate.Email. (Tier  |
| `10` | 0.168 | 4 | None | Marketing channel through which the affiliate operates (e.g., web, social, email). (Tier 4 — inferred from column name) | Top-level marketing channel classification (e.g., "Paid", "Organic", "Affiliate"). NOT NULL constraint. Correlates with Dim_Affiliate.Channel — inherited from Ext_Dim_SubChannel_UnifyCode in the Dim_A |
| `1` | 0.245 | 4 | None | Original customer ID (the real/root CID before any account migration or merge). PK part 1. Standard DWH customer identifier. (Tier 4 — inferred from naming convention) | Customer ID — platform-internal primary key assigned at registration. Part of composite PK (RealCID, AffiliateID). Standard DWH customer identifier used across all tables. Correlates with Dim_Customer |
| `9` | 0.317 | 4 | None | Affiliate group or tier classification (e.g., VIP, Standard, Premium). (Tier 4 — inferred from column name) | Marketing group the affiliate belongs to. Correlates with Dim_Affiliate.AffiliatesGroupsName (abbreviated). (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| `6` | 0.324 | 4 | None | Name of the affiliate's commission contract (e.g., CPA, Revenue Share, Hybrid). (Tier 4 — inferred from column name) | Free-text name of the affiliate's contract/payment agreement. Used in Dim_Affiliate as input for ContractType classification (e.g., "Rev Share + CPA", "CPL Standard"). (Tier 3b — DDL structure, correl |
| `11` | 0.38 | 5 | None | ETL metadata: timestamp when this row was last updated by the ETL pipeline. (Tier 5 — standard ETL metadata) | ETL load timestamp. Standard DWH pattern — set to GETDATE() during SP execution. Since no writer SP exists, this column was never populated. (Tier 3b — DDL structure) |
| `8` | 0.494 | 4 | None | Affiliate's preferred language for communications and portal interface. (Tier 4 — inferred from column name) | Affiliate's preferred language. Naming pattern (Aff_eLanguage) correlates with Dim_Affiliate.LanguageName. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |
| `4` | 0.496 | 4 | None | Affiliate's login username in the partner portal. (Tier 4 — inferred from column name) | Affiliate login name in the AffWizz system. Naming pattern correlates with Dim_Affiliate.LoginName. (Tier 3b — DDL structure, correlated with Dim_Affiliate) |

## Top issues — regen wiki (per judge)

- [medium] `Footer` — Footer says 'Phases: 7/14' but lists 6 skipped phases (P4,P5,P7,P9,P9B,P10), yielding 14-6=8 completed, not 7. Arithmetic error.
- [low] `Section 1 / Data Evidence` — 0-row claim is not backed by a cited live query result or timestamp. Reader cannot verify when dormancy was last confirmed.
- [low] `Section 5.2 (Upstream Search Log)` — Search log claims Dim_Affiliate.md and Dim_Customer.md were found and read, but the authoritative upstream bundle states 'NO UPSTREAM WIKI was resolvable'. Process inconsistency — content is unaffected since Tier 3b was correctly assigned.
- [low] `Section 4 (Tier Legend)` — Tier legend only shows Tier 3b. Full tier scale (T1-T5) would help analysts unfamiliar with the system understand the confidence spectrum.
- [low] `ContractType` — Element #7 discusses Dim_Affiliate's tinyint codes (0=N/A, 2=CPA, etc.) but does not resolve whether this varchar(20) column stores text labels or stringified numeric codes. Correctly flagged in review-needed sidecar.
