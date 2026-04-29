# Compare — `BI_DB_dbo.BI_DB_Adwords_Search_Conv`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta -0.3; slop 2 -> 0 (delta -2))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.75 | 8.45 | -0.3 |
| Slop hits (`Tier 4 ... inferred`) | 2 | 0 | -2 |
| Element rows | 26 | 26 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 23 | 23 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 2 | 2 | +0 |
| T5 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 8 |
| data_evidence | 6 | 7 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `13` | 0.166 | 4 | 4 | Composite search key. NOT populated — SP comments out this column. Originally: ad_group_id + device + month + search_term + keyword_id + match_type concatenation. Always NULL. (Tier 4 — inferred from  | **NOT POPULATED** — column exists in DDL but SP has it commented out. Always NULL. Intended as composite search key (ad_group_id + device + month + search_term + keyword_id + match_type). (Tier 4 — no |
| `7` | 0.222 | 2 | 2 | Identical to query_targeting_status — both map from search_term_match_type. Redundant column kept for backward compatibility. (Tier 2 — SP_Adwords_Pref_Conv) | How the search query matched the advertiser's keyword. EXACT (39%), NEAR_EXACT (27%), NEAR_PHRASE (16%), BROAD (13%), PHRASE (6%). Renamed from Fivetran field 'search_term_match_type'. Part of GROUP B |
| `3` | 0.246 | 2 | 2 | Actual user search query that triggered the ad. Mapped from Fivetran search_term. Multi-language (e.g., 'robinhood option', 'investimenti in borsa'). (Tier 2 — SP_Adwords_Pref_Conv) | Actual search term the user typed that triggered the ad impression. Renamed from Fivetran field 'search_term'. High cardinality (8,461 unique queries). Multi-language terms ('meilleur site crypto', 'e |
| `12` | 0.275 | 2 | 2 | Landing page URL that the ad linked to. Mapped from Fivetran ad_final_urls. Contains full URLs like 'https://www.etoro.com/en-us/'. (Tier 2 — SP_Adwords_Pref_Conv) | Landing page URL for the ad that was shown. Renamed from Fivetran field 'ad_final_urls'. Contains eToro domain URLs (e.g., 'https://go.etoro.com/en/evergreen-stocks'). Part of GROUP BY grain. (Tier 2  |
| `8` | 0.283 | 4 | 4 | Google Ads keyword ID that the search query matched. NOT populated — SP comments out this column. Always NULL. (Tier 4 — inferred from DDL) | **NOT POPULATED** — column exists in DDL but SP has it commented out. Always NULL across all 12,992 rows. Intended for Google Ads keyword identifier. (Tier 4 — not inserted by SP) |
| `21` | 0.305 | 2 | 2 | 1st-gen Android app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) | 1st-gen Android app ("eToro - Invest in stocks, crypto & trade CFDs") registration conversions. SUM(all_conversions - view_through_conversions) WHERE conversion_action_name matches Android registratio |
| `1` | 0.334 | 2 | 2 | First-of-month date string (e.g., '2023-05-01'). Time grain for this table — monthly, not daily. Passthrough from Fivetran. Clustered index key. (Tier 2 — SP_Adwords_Pref_Conv) | Monthly period start date (first day of month, e.g., '2023-08-01'). Aggregation grain for search query conversions. Range: 2023-05-01 to 2023-08-01. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pre |
| `5` | 0.415 | 2 | 2 | How the search query matched the keyword. EXACT, NEAR_EXACT, NEAR_PHRASE, PHRASE, BROAD. Mapped from search_term_match_type. (Tier 2 — SP_Adwords_Pref_Conv) | Search term match type — ALWAYS identical to query_match_type_with_variant. Both mapped from Fivetran search_term_match_type. Redundant column. Values: EXACT, NEAR_EXACT, NEAR_PHRASE, BROAD, PHRASE. ( |
| `24` | 0.531 | 2 | 2 | 1st-gen iOS app registration conversions. (Tier 2 — SP_Adwords_Pref_Conv) | 1st-gen iOS app ("eToro Cryptocurrency Trading") registration conversions. SUM WHERE conversion_action_name matches iOS registration. Float due to fractional attribution. (Tier 2 — SP_Adwords_Pref_Con |
| `20` | 0.577 | 5 | 5 | ETL metadata: timestamp when this row was last inserted (GETDATE()). (Tier 5 — ETL infrastructure) | ETL metadata: timestamp when this row was loaded by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 (single bulk load). (Tier 5 — SP_Adwords_Pref_Conv) |

## Top issues — regen wiki (per judge)

- [medium] `Section 3.1` — Claims Search_Perf is 'also HASH on customer_id' enabling co-located JOINs, but Search_Perf wiki documents ROUND_ROBIN distribution. JOIN advice based on incorrect distribution assumption.
- [low] `Footer` — Footer says 'Elements: 25/25' and '22 T2' but wiki lists 26 elements and there are 23 Tier 2 columns (23+2+1=26). Arithmetic error in footer tier/element counts.
- [low] `Section 3.3` — JOIN to Search_Perf omits ad_group_id and account_currency_code from the join condition. SP GROUP BY for both tables includes these as grain columns — omitting them would produce incorrect fan-out.
- [low] `Section 2.4` — Conflates the two DELETE statements: describes 'DELETE months older than 1 year' and 'DELETE + INSERT for 4-month rolling window' but the SP uses @FirstDayOfMonthYearAgo for the floor and @FromMonth/@FirstDayOfNextMonth for the overlap window. The description is approximately right but imprecise.
- [low] `Section 3.3` — JOIN to Dictionary_Campaign does not note that Search_Conv is HASH(customer_id) while dictionary tables likely use different distributions, causing broadcast data movement.
