# Compare — `DWH_dbo.Dim_Channel`

**Bucket**: `slop`

**Verdict**: **BETTER**  (score delta +0.95; slop 1 -> 0 (delta -1))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 7.8 | 8.75 | 0.95 |
| Slop hits (`Tier 4 ... inferred`) | 1 | 0 | -1 |
| Element rows | 6 | 6 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 0 | +0 |
| T2 count | 6 | 6 | +0 |
| T3 count | 0 | 0 | +0 |
| T4 count | 0 | 0 | +0 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 8 | 9 |
| completeness | 8 | 10 |
| data_evidence | 2 | 7 |
| shape_fidelity | 9 | 8 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 7 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `2` | 0.113 | 2 | 2 | Top-level marketing channel category. Derived from AffWizz MarketingExpense.MarketingExpenseName with overrides: 'Introducing Agents' → 'Affiliate', AffiliateID IN (56662,56663) → 'Direct'. Common val | Top-level marketing channel grouping (e.g., 'SEM', 'Direct', 'Affiliate', 'SEO', 'Friend Referral'). 20 distinct values. Passthrough from Ext_Dim_SubChannel_UnifyCode.Channel via SELECT DISTINCT. Also |
| `3` | 0.164 | 2 | 2 | Granular sub-channel name within the parent Channel. Human-readable label for SubChannelID. Examples: 'Google Brand', 'Google Search', 'FB', 'Taboola', 'Twitter', 'Outbrain', 'Bing Search', 'Direct',  | Granular marketing sub-channel name within a Channel (e.g., 'Google Search', 'Taboola', 'Direct Mobile', 'IBs'). 36 distinct values — one per row. Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChan |
| `1` | 0.178 | 2 | 2 | Primary key. DWH-derived sub-channel identifier assigned via a CASE expression in SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse. Maps affiliate contact strings to ~30 standardized sub-channel categ | Primary key identifying a unique marketing sub-channel. Non-sequential integer (range 1–52, 36 active). Passthrough from Ext_Dim_SubChannel_UnifyCode.SubChannelID via SELECT DISTINCT. Clustered index  |
| `4` | 0.208 | 2 | 2 | Binary marketing spend classification. 'Organic' for channels Friend Referral, Direct, SEO, and Google Brand. 'Paid' for all others. Computed in SP_Dim_Channel (second ETL step). Note: column name con | ETL-computed classification: 'Organic' when Channel IN ('Friend Referral', 'Direct', 'SEO') or SubChannel = 'Google Brand'; 'Paid' otherwise. 2 distinct values: Paid (30 rows), Organic (6 rows). NULL  |
| `5` | 0.216 | 2 | 2 | ETL metadata: timestamp when this row was first inserted by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. (Tier 2 — SP_Dim_Channel) | Row insert timestamp set to GETDATE() at SP execution time. Because the table uses truncate-and-reload, all rows share the same InsertDate equal to the last load run. Does not represent the original c |
| `6` | 0.489 | 2 | 2 | ETL metadata: timestamp when this row was last updated by the ETL pipeline. Set to GETDATE() during SP_Dim_Channel execution. Same as InsertDate since table is TRUNCATE+INSERT. (Tier 2 — SP_Dim_Channe | Row update timestamp set to GETDATE() at SP execution time. Identical to InsertDate on every load due to the truncate-and-reload pattern. Does not track incremental changes. (Tier 2 — SP_Dim_Channel) |

## Top issues — regen wiki (per judge)

- [medium] `Section 1 + Section 2.3` — Email alerting described as active ('an HTML email is sent') but SP code shows sp_send_dbmail is commented out. Wiki body is misleading — analyst would assume the alert is operational.
- [low] `Section 2.3` — Email subject mismatch: wiki says 'New Channels in Affwizz - Need mapping ASAP' but SP code shows @subject = 'New Channels in Affwizz' (without 'Need mapping ASAP').
- [low] `Section 2 (missing)` — SP INSERT logic includes WHERE SubChannelID != 0, silently excluding zero-valued IDs. This filter is not documented anywhere in the wiki or lineage.
- [low] `Footer` — Quality score is 'pending/10' — unfilled placeholder.
- [low] `Section 5.2` — Pipeline diagram shows SP_Dim_Channel_Affiliate_UnifyCode_DL_To_Synapse as loader but relationship to orchestrator SP_Dictionaries_DL_To_Synapse could be clearer.
