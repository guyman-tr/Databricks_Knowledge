# Compare — `BI_DB_dbo.BI_DB_Adwords_Dictionary_AdGroup`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.7; slop 1 -> 1 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.25 | 8.95 | 0.7 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 1 | +0 |
| Element rows | 6 | 6 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 4 | 4 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 1 | 1 | +0 |
| T5 count | 1 | 1 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 8 | 10 |
| data_evidence | 6 | 8 |
| shape_fidelity | 8 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `4` | 0.224 | 4 | 4 | Target cost-per-acquisition setting for the ad group. NOT populated by SP_Adwords_Pref_Conv — always NULL. Column exists in DDL but omitted from INSERT. (Tier 4 — inferred from DDL) | **NOT POPULATED** — column exists in DDL but SP does not include it in the INSERT statement. Always NULL across all 31,322 rows. Intended for Google Ads target CPA bidding value but never implemented. |
| `3` | 0.594 | 2 | 2 | Google Ads ad group display name. Mapped from Fivetran `name` column. Encodes targeting metadata: language, keyword theme, match type (e.g., 'EN_KW_ETF-LowIntent', 'AR_Stocks_Intent_Phrase'). (Tier 2  | Google Ads ad group name. Human-readable label from Google Ads UI. Encodes targeting metadata: region, keyword theme, match type (e.g., 'EN_KW_ETF-LowIntent', 'FR_Investir Actions (Stocks Invest)_BMM' |
| `2` | 0.597 | 2 | 2 | Google Ads ad group identifier. Mapped from Fivetran `id` column. Primary lookup key for joining other Adwords tables. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads ad group identifier. Canonical ad group key used by all Adwords performance and conversion tables. Mapped from Fivetran `id` column. (Tier 2 — SP_Adwords_Pref_Conv) |
| `1` | 0.721 | 2 | 2 | Google Ads campaign identifier. FK to BI_DB_Adwords_Dictionary_Campaign. Associates this ad group with its parent campaign. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads campaign identifier. Links this ad group to its parent campaign. FK to BI_DB_Adwords_Dictionary_Campaign. Passthrough from Fivetran. (Tier 2 — SP_Adwords_Pref_Conv) |
| `5` | 0.811 | 5 | 5 | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). (Tier 5 — ETL infrastructure) | ETL metadata: timestamp when this row was last inserted by SP_Adwords_Pref_Conv (GETDATE()). All rows show 2023-09-18 due to TRUNCATE+INSERT pattern. (Tier 5 — ETL infrastructure) |
| `6` | 0.955 | 2 | 2 | Google Ads ad group operational status. ENABLED=actively serving, PAUSED=temporarily stopped, REMOVED=permanently deleted. Mapped from Fivetran `status` column. (Tier 2 — SP_Adwords_Pref_Conv) | Google Ads ad group operational status. ENABLED=actively serving (67%), PAUSED=temporarily stopped (23%), REMOVED=permanently deleted (10%). Mapped from Fivetran `status` column. (Tier 2 — SP_Adwords_ |

## Top issues — regen wiki (per judge)

- [low] `ad_group_id` — Wiki flags non-uniqueness (27,565 distinct across 31,322 rows) but doesn't explicitly explain the root cause: SELECT DISTINCT grain includes campaign_id, so the same ad_group_id appearing under multiple campaigns creates multiple rows.
- [low] `Section 8 / Footer` — No explicit Phase Gate Checklist section with [x]/[ ] checkboxes. Footer says 12/14 phases but doesn't enumerate which 2 were skipped.
- [info] `Section 1` — No explicit data date range stated. For a TRUNCATE+INSERT dictionary this is acceptable (snapshot, not time-series), but could be clearer that the data reflects the state of all ad groups as of the last Fivetran sync before 2023-09-18.
- [info] `Section 6.2` — Lists 8 referencing tables but SP processes 12 total tables. The list appears correct (not all SP tables necessarily JOIN on ad_group_id) but completeness is not independently verifiable from the bundle alone.
