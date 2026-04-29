# Compare — `BI_DB_dbo.BI_DB_Adwords_Keywords_Pref`

**Bucket**: `slop`

**Verdict**: **EQUIVALENT**  (score delta +0.1; slop 1 -> 1 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.75 | 8.85 | 0.1 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 1 | +0 |
| Element rows | 24 | 24 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 22 | 22 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |
| T5 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 6 | 7 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `8` | 0.173 | 2 | 2 | Search keyword text. Mapped from Fivetran keyword_text. Multi-language terms (e.g., 'comprar acciones', 'etoro', 'investir en bourse'). (Tier 2 — SP_Adwords_Pref_Conv) | Advertiser-defined keyword text. Mapped from Fivetran keyword_text. Contains multi-language terms (e.g., 'broker plataforma', 'Tesla Stocks', 'ibex35', 'copy trading platform'). Not the user's actual  |
| `12` | 0.459 | 2 | 2 | Percentage of top-of-page search impressions lost due to budget constraints. Stored as string. '0'=no loss. (Tier 2 — SP_Adwords_Pref_Conv) | Fraction of top-of-page impressions lost due to budget constraints. String type — CAST to float for calculations. Part of the search visibility triad with search_impression_share and search_rank_lost_ |
| `16` | 0.478 | 2 | 2 | Percentage of eligible search impressions received. Stored as string. Indicates competitive visibility. (Tier 2 — SP_Adwords_Pref_Conv) | Fraction of eligible search impressions actually received. String type — CAST to float for calculations. Values range from 0 to 1. Only meaningful for search campaigns. (Tier 2 — SP_Adwords_Pref_Conv) |
| `20` | 0.529 | 2 | 2 | Percentage of search impressions lost due to ad rank (quality + bid). Stored as string. '0'=no loss. (Tier 2 — SP_Adwords_Pref_Conv) | Fraction of impressions lost due to ad rank (quality score × bid). String type — CAST to float for calculations. High values indicate need for higher bids or better quality scores. (Tier 2 — SP_Adword |
| `6` | 0.573 | 2 | 2 | Google Ads keyword quality score (1-10). Mapped from Fivetran quality_info_quality_score. 0=insufficient data. Higher=better ad position and lower CPC. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads keyword quality score (0-10). 0 = insufficient data. Higher values indicate better keyword relevance, expected CTR, and landing page experience. Mapped from Fivetran quality_info_quality_sc |
| `9` | 0.602 | 2 | 2 | Video ad views for video-enabled keywords. Standard Google Ads metric. (Tier 2 — SP_Adwords_Pref_Conv) | Number of video ad views. Standard Google Ads video metric. Passthrough from Fivetran. 0 for non-video keywords. (Tier 2 — SP_Adwords_Pref_Conv) |
| `24` | 0.669 | 2 | 2 | Google Ads keyword match type. BROAD, EXACT, PHRASE. Mapped from keyword_match_type. Part of GROUP BY grain. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads keyword match type setting. EXACT (46%), PHRASE (45%), BROAD (9%). Part of row grain. Mapped from Fivetran keyword_match_type. Added 2021-04-05 by Amir. (Tier 2 — SP_Adwords_Pref_Conv) |
| `3` | 0.692 | 2 | 2 | Google Ads customer account ID. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads customer account ID. Identifies the Google Ads account. 9 distinct accounts. (Tier 2 — SP_Adwords_Pref_Conv) |
| `22` | 0.715 | 5 | 5 | ETL metadata: timestamp when this row was last inserted (GETDATE()). (Tier 5 — ETL infrastructure) | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 16:37:31 (single bulk load). (Tier 5 — ETL infrastructure) |
| `23` | 0.758 | 2 | 2 | Total conversions (all types combined). Standard Google Ads metric. Unlike Keywords_Conv which breaks by funnel stage. (Tier 2 — SP_Adwords_Pref_Conv) | Total conversions (all types combined). Standard Google Ads metric. Passthrough from Fivetran. Unlike Keywords_Conv which breaks down by funnel stage, this is the aggregate total. 0.8% of rows have Co |

## Top issues — regen wiki (per judge)

- [low] `Section 8 / Footer` — No explicit Phase Gate Checklist section. Phase completion (12/14) only appears in footer line, making it unclear which phases were skipped.
- [low] `Conversions (#23)` — Description claims 'Unlike Keywords_Conv which breaks down by funnel stage, this is the aggregate total' — useful comparative context but the 'aggregate total' characterization of the Fivetran conversions field is editorial, not verifiable from SP code.
