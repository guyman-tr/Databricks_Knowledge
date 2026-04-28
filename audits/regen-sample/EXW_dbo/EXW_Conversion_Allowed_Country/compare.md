# Compare — `EXW_dbo.EXW_Conversion_Allowed_Country`

**Bucket**: `median`

**Verdict**: **BETTER**  (score delta +5.0; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 4.5 | 9.5 | 5.0 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 21 | 21 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 2 | +2 |
| T2 count | 17 | 19 | +2 |
| T3 count | 4 | 0 | -4 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 10 |
| completeness | 4 | 10 |
| data_evidence | 4 | 8 |
| shape_fidelity | 7 | 9 |
| tier_accuracy | 3 | 10 |
| upstream_fidelity | 4 | 9 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.086 | 2 | 1 | DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries) | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. Referenced by Dim_Customer, Fact_BillingDe |
| `10` | 0.117 | 2 | 2 | Raw resolved value for user-level conversion eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) | Whether the user in this country is allowed to use conversion. 'true' or 'false' from EXW_Settings.SystemRestrictions (priority-resolved). Currently 'false' for all 51,642 rows — conversion activity g |
| `1` | 0.121 | 2 | 1 | Country name from DWH_dbo.Dim_Country.Name. Text label for the country. (Tier 2 — SP_EXW_WalletElligibleCountries) | Full country name in English. Unique per row. Used in UI dropdowns, compliance documents, and analytical reports. Passthrough from Dim_Country (c.Name AS Country). CountryID=0 excluded by SP WHERE cla |
| `8` | 0.181 | 2 | 2 | Tag type matched during user-level conversion eligibility resolution. (Tier 2 — EXW_Settings) | Tag scope that won the restriction-weight priority resolution for the allowedUser resource. Possible values: Default, Country, CountryAndRegion. Currently Default=51,642 (100% of rows). (Tier 2 — SP_E |
| `7` | 0.189 | 2 | 2 | EXW_Settings resource name for user-level conversion eligibility. Determines whether users in this country are allowed to perform crypto conversions at all. (Tier 2 — EXW_Settings) | EXW_Settings resource path for the conversion/allowedUser restriction. Always 'conversion/allowedUser' for all rows. Resolved via MAX(RestrictionWeight) priority from EXW_Settings.Resources. (Tier 2 — |
| `9` | 0.216 | 2 | 2 | Tag value matched for user-level conversion eligibility. (Tier 2 — EXW_Settings) | Tag value that matched during restriction resolution. 'Default' when TagType='Default', country name when TagType='Country', country_region key when TagType='CountryAndRegion'. Currently 'Default' for |
| `14` | 0.216 | 2 | 2 | Raw resolved value for From-direction conversion eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) | Whether conversion FROM this crypto is allowed in this country. 'true' or 'false' from EXW_Settings (priority-resolved). 33% of rows have 'true', 67% have 'false'. (Tier 2 — SP_EXW_WalletElligibleCoun |
| `15` | 0.263 | 2 | 2 | EXW_Settings resource name for To-direction conversion eligibility. Identifies whether this crypto can be used as a conversion target in this country. (Tier 2 — EXW_Settings) | EXW_Settings resource path for the allowedConvertTo restriction. Pattern: 'cryptos/{CryptoID}/allowedConvertTo' or 'cryptos/{CryptoCategoryName}/allowedConvertTo'. (Tier 2 — SP_EXW_WalletElligibleCoun |
| `11` | 0.265 | 2 | 2 | EXW_Settings resource name for From-direction conversion eligibility. Identifies whether this crypto can be used as a conversion source in this country. (Tier 2 — EXW_Settings) | EXW_Settings resource path for the allowedConvertFrom restriction. Pattern: 'cryptos/{CryptoID}/allowedConvertFrom' or 'cryptos/{CryptoCategoryName}/allowedConvertFrom'. 73 distinct values. (Tier 2 —  |
| `21` | 0.332 | 2 | 2 | ETL timestamp set to `GETDATE()` at insert time. (Tier 2 — SP_EXW_WalletElligibleCountries) | ETL load timestamp. Set to GETDATE() at insert time. Reflects when SP_EXW_WalletElligibleCountries last ran, not when the underlying settings changed. All rows share the same timestamp per refresh. (T |

## Top issues — regen wiki (per judge)

- [low] `Upstream Bundle` — Bundle resolver declared 'NO UPSTREAM WIKI was resolvable' despite Dim_Country.md and Dim_State_and_Province.md existing in the repo. Writer manually corrected this — tooling bug, not a wiki quality issue.
- [low] `Footer` — Footer says 'Phases: 13/14' but does not enumerate which phase was skipped. Reader cannot determine whether a data-critical phase (P2/P3) was incomplete.
- [low] `Section 1 / Section 3.4` — All-conversions-blocked state is documented in multiple sections but lacks a top-level admonition/banner for quick scanning by analysts.
- [info] `Elements 5-18 (EXW_Settings/CryptoTypes columns)` — 19 of 21 columns are Tier 2 because upstream sources (EXW_Settings.Resources, EXW_Settings.Tags, EXW_Settings.SystemRestrictions, EXW_Wallet.CryptoTypes) have no wiki documentation. Correctly flagged in review-needed sidecar.
- [info] `Section 8` — No Atlassian sources identified. The SP change history note (Inessa K, 2026-04-14) is included inline — acceptable given no formal Jira ticket was linked.
