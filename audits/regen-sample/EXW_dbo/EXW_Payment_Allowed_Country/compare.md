# Compare — `EXW_dbo.EXW_Payment_Allowed_Country`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +2.8; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 5.1 | 7.9 | 2.8 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 16 | 16 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 2 | +2 |
| T2 count | 12 | 14 | +2 |
| T3 count | 4 | 0 | -4 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 7 | 10 |
| completeness | 4 | 8 |
| data_evidence | 4 | 7 |
| shape_fidelity | 7 | 9 |
| tier_accuracy | 3 | 8 |
| upstream_fidelity | 7 | 6 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `14` | 0.111 | 2 | 2 | Raw resolved value for crypto-level payment eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) | The resolved permission value for the Cryptos domain. String `'true'` or `'false'`. Indicates whether the specific crypto is allowed for payment in this country. Mixed values observed: some country–cr |
| `1` | 0.146 | 2 | 1 | DWH country dimension key. FK to DWH_dbo.Dim_Country.CountryID. HASH distribution key. For US (CountryID=219), one row per state. (Tier 2 — SP_EXW_WalletElligibleCountries) | Primary key. 0=Not available (fallback/placeholder for users whose country cannot be determined), 1-250=countries ordered roughly alphabetically by ISO code. In this table, used as the country dimensi |
| `8` | 0.156 | 2 | 2 | Tag type matched during user-level eligibility resolution (e.g., 'Country', 'CountryAndRegion'). (Tier 2 — EXW_Settings) | Tag type that won the weight-based resolution for the AllowedUser permission domain. Values include: Default, Country, CountryAndRegion, CountryAndRegulation, CountryRegionAndRegulation. Currently all |
| `5` | 0.173 | 3 | 2 | Numeric crypto identifier derived from the EXW_Settings ResourceName path. Identifies which crypto the payment eligibility applies to. (Tier 3 — inferred) | Cryptocurrency identifier from EXW_Wallet.CryptoTypes. Identifies the specific crypto asset in the permission check. 174 distinct active cryptos. Each country has one row per CryptoID. (Tier 2 — SP_EX |
| `9` | 0.183 | 2 | 2 | Tag value matched for user-level eligibility (country name or country+region combination). (Tier 2 — EXW_Settings) | Tag value that won the weight-based resolution for the AllowedUser permission domain. For `Default` tag type, this is `Default`. For country-specific tags, this is the country slug (e.g., `united_stat |
| `10` | 0.193 | 2 | 2 | Raw resolved value for user-level payment eligibility ('true' or 'false'). Currently 'false' for all rows. (Tier 2 — EXW_Settings) | The resolved permission value for the AllowedUser domain. String `'true'` or `'false'`. Currently all rows show `false`, meaning user-level payment is disabled globally. (Tier 2 — SP_EXW_WalletElligib |
| `12` | 0.193 | 2 | 2 | Tag type matched during crypto-level eligibility resolution. (Tier 2 — EXW_Settings) | Tag type that won the weight-based resolution for the Cryptos permission domain. Same possible values as AllowedUserTagType. May differ from AllowedUserTagType if different tag granularities are confi |
| `13` | 0.208 | 2 | 2 | Tag value matched for crypto-level eligibility. (Tier 2 — EXW_Settings) | Tag value that won the weight-based resolution for the Cryptos permission domain. For `Default` tag type, this is `Default`. For country-specific tags, this is the country/region slug. (Tier 2 — SP_EX |
| `3` | 0.216 | 3 | 2 | US state name from DWH_dbo.Dim_State_and_Province.Name for US rows; NULL for other countries. (Tier 3 — inferred) | Full human-readable geographic name of the sub-country region (state, province, territory). Populated only for US entries (CountryID=219) from Dim_State_and_Province.Name; NULL for all other countries |
| `11` | 0.284 | 2 | 2 | EXW_Settings resource name for the crypto-level payment eligibility setting. Identifies whether a specific crypto can be purchased in this country. (Tier 2 — EXW_Settings) | EXW_Settings resource name for the crypto-specific payment permission. Pattern: `cryptos/{CryptoID}/allowedPayment` (e.g., `cryptos/1/allowedPayment` for BTC). Resolved via highest-weight matching tag |

## Top issues — regen wiki (per judge)

- [high] `CountryID` — Tier 1 paraphrase: dropped 'Referenced by Dim_Customer, Fact_BillingDeposit, Dim_CountryBin, V_Dim_Customer' from Dim_Country wiki and substituted EXW-specific context. Tier 1 requires verbatim upstream text.
- [medium] `AllowedUserTagType, PaymentAllowed, AllowedUserSelectedValue` — Dictionary columns with <=15 distinct values should list inline key=value pairs in the Elements table. AllowedUserTagType has 5 known values, PaymentAllowed has 2 (0/1), AllowedUserSelectedValue has 2 (true/false). Values are described in prose but not enumerated inline per spec.
- [low] `Footer / Phase Gate` — No explicit Phase Gate Checklist with P2/P3 checkmarks. Footer says 'Phases: 13/14' but does not show which phases were completed vs. skipped, making it impossible to verify data evidence methodology.
- [low] `Upstream Bundle` — Bundle resolver failed to include DWH_dbo.Dim_Country and DWH_dbo.Dim_State_and_Province wikis (both exist locally). Writer correctly found them independently. Bundle resolver should be fixed for future runs.
- [low] `Country` — Minor Tier 1 fidelity deviation: appended 'Passthrough from Dim_Country (Name → Country rename)' to the upstream-verbatim text. Core meaning preserved but strictly not verbatim.
