# Compare — `BI_DB_dbo.BI_DB_Adwords_Keywords_Conv`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.2; slop 1 -> 1 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.75 | 8.95 | 0.2 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 1 | +0 |
| Element rows | 38 | 38 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 36 | 36 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |
| T5 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 7 | 8 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `37` | 0.214 | 2 | 2 | Open Trade conversions from alternate iOS app listing. SUM WHERE 'eToro: Investing made social (iOS) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) | iOS app ("eToro: Investing made social (iOS)") Open Trade conversions. Note: maps to "Investing made social" NOT "Crypto. Stocks. Social." despite the iOS2 column name. NULL when no match. (Tier 2 — S |
| `20` | 0.355 | 2 | 2 | 1st-gen Android app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) | 1st-gen Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. SUM(all_conversions - view_through_conversions). Float due to Google's fractional attribution. (Tier 2 — |
| `27` | 0.621 | 2 | 2 | 30-day LTV conversion monetary value. SUM(all_conversions_value) WHERE 'LTV-30Day'. Unique to this table. (Tier 2 — SP_Adwords_Pref_Conv) | 30-day lifetime value monetary amount. SUM(all_conversions_value) WHERE conversion_action_name = 'LTV-30Day'. Unique to this table in the Adwords cluster. Added 2022-07-14 by Eti. (Tier 2 — SP_Adwords |
| `36` | 0.643 | 2 | 2 | Open Trade conversions from 2nd-gen iOS app (Crypto.Stocks.Social). SUM WHERE 'eToro: Crypto. Stocks. Social. (iOS) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") Open Trade conversions. NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| `23` | 0.649 | 2 | 2 | 1st-gen iOS app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) | 1st-gen iOS app ("eToro Cryptocurrency Trading") registration conversions. Float due to Google's fractional attribution. (Tier 2 — SP_Adwords_Pref_Conv) |
| `35` | 0.657 | 2 | 2 | Open Trade conversions from 2nd-gen Android app. SUM WHERE 'eToro: Investing made social (Android) Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) | 2nd-gen Android app ("eToro: Investing made social") Open Trade conversions. No ELSE 0 — NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| `38` | 0.669 | 2 | 2 | Generic Open Trade conversions (web/unattributed). SUM WHERE 'Open Trade'. (Tier 2 — SP_Adwords_Pref_Conv) | Platform-agnostic Open Trade conversions. SUM WHERE conversion_action_name = 'Open Trade'. NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| `3` | 0.692 | 2 | 2 | Google Ads customer account ID. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads customer account ID. Identifies the Google Ads account. 8 distinct accounts. (Tier 2 — SP_Adwords_Pref_Conv) |
| `29` | 0.73 | 2 | 2 | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) | 2nd-gen iOS app ("eToro: Crypto. Stocks. Social.") registration conversions. Added 2022-05-10. Mostly NULL (3530/3540 rows). No ELSE 0 — NULL when no match. (Tier 2 — SP_Adwords_Pref_Conv) |
| `28` | 0.732 | 2 | 2 | Google Ads keyword match type. BROAD, EXACT, PHRASE. Part of GROUP BY grain. Mapped from Fivetran keyword_match_type. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads keyword match type. BROAD, EXACT, PHRASE. Mapped from keyword_match_type. Part of GROUP BY grain. Added 2022-07-19 by Eti. (Tier 2 — SP_Adwords_Pref_Conv) |

## Top issues — regen wiki (per judge)

- [low] `Footer` — Footer says 'Phases: 12/14' but does not identify which 2 phases were skipped. Cannot confirm whether data validation phases (P2/P3) were completed.
- [low] `Section 2.6` — Rolling window description is accurate but omits SP variable names (@FirstDayOfMonthYearAgo, @FromDate) that would help developers trace back to source code.
- [info] `OpenTrade_iOS2` — Naming inconsistency correctly flagged in Section 2.4, element #37, and review-needed sidecar. Maps to 'eToro: Investing made social (iOS) Open Trade' not the iOS2 app. Well-documented.
- [info] `id` — Correctly identified as Tier 4, always NULL, SP has '--,ad_id' commented out. Properly flagged in review-needed sidecar.
- [info] `Section 3.4 (NULL vs 0)` — ELSE 0 vs no-ELSE inconsistency between 1st-gen and 2nd-gen app columns is thoroughly documented across multiple sections. No action needed.
