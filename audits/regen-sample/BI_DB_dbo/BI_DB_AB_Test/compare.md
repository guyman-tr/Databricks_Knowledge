# Compare — `BI_DB_dbo.BI_DB_AB_Test`

**Bucket**: `median`

**Verdict**: **EQUIVALENT**  (score delta +0.3; slop 0 -> 0 (delta +0))

## Header

| Metric | Current | Regen | Delta |
|---|---|---|---|
| Judge weighted score | 8.85 | 9.15 | 0.3 |
| Slop hits (`Tier 4 ... inferred`) | 0 | 0 | +0 |
| Element rows | 8 | 8 | +0 |
| Untagged count | 0 | 0 | +0 |
| T1 count | 0 | 1 | +1 |
| T2 count | 0 | 0 | +0 |
| T3 count | 7 | 7 | +0 |
| T4 count | 0 | 0 | +0 |
| T5 count | 1 | 0 | -1 |

## Dimension scores

| Dimension | Current | Regen |
|---|---|---|
| business_meaning | 9 | 9 |
| completeness | 10 | 10 |
| data_evidence | 7 | 8 |
| shape_fidelity | 9 | 9 |
| tier_accuracy | 10 | 10 |
| upstream_fidelity | 7 | 8 |

## Top 10 column changes (by edit distance)

| Column | Sim | Cur tier | Regen tier | Current | Regen |
|---|---|---|---|---|---|
| `7` | 0.117 | 3 | 3 | Unique identifier for the A/B test. Follows convention: AB_Test_{purpose}_{YYYYMM}. Known values: "AB_Test_lead_conv_202202", "AB_Test_Onboarding_202007". Max 25 chars — tight fit. (Tier 3 — live data | Identifier string for the AB test experiment. 2 distinct values: "AB_Test_Onboarding_202007" (75,054 rows), "AB_Test_lead_conv_202202" (239,186 rows). All values non-NULL. (Tier 3 — DDL + data sample, |
| `4` | 0.125 | 3 | 3 | A/B group assignment flag. 1 = control group (baseline experience), 0 = treatment group (new feature/variant). Confirmed from live data: AB_Test_lead_conv_202202 has both 0 and 1 values; AB_Test_Onboa | Binary flag indicating AB test group assignment. 0=treatment group (experimental change applied), 1=control group (no change). 205,346 treatment vs. 108,894 control rows in current data. All values no |
| `2` | 0.169 | 3 | 3 | Calendar date equivalent of DateID. Redundant with DateID but provided for human-readable filtering. (Tier 3 — live data: 2020-06-10 to 2023-04-29) | Calendar date corresponding to DateID. The date the customer entered the experiment cohort. Range: 2020-06-10 to 2023-04-29. All values non-NULL in current data. (Tier 3 — DDL + data sample, no upstre |
| `3` | 0.234 | 3 | 1 | eToro real-money customer ID. Distribution key — joins to Dim_Customer.RealCID are collocated. (Tier 3 — HASH distribution key + live data: 312,861 unique CIDs) | Customer ID - platform-internal primary key. Assigned at registration. Unique within etoro DB. Used as the universal customer identifier across all tables. (Tier 1 — Customer.CustomerStatic) |
| `1` | 0.252 | 3 | 3 | Integer date key in YYYYMMDD format. Matches DWH_dbo date dimension convention. Clustered index lead key — range queries on date are efficient. (Tier 3 — live data: range 20200610–20230429) | Integer date key in YYYYMMDD format representing the date the customer was assigned to the AB test group. Range: 20200610–20230429. All values non-NULL in current data. (Tier 3 — DDL + data sample, no |
| `6` | 0.331 | 3 | 3 | Name of the product or business stakeholder who requested the A/B test. Observed values: "Elie Edery", "Steven Freedman". Max 15 characters. (Tier 3 — live data sampling) | Name of the business stakeholder who owns the experiment. "Steven Freedman" for AB_Test_Onboarding_202007, "Elie Edery" for AB_Test_lead_conv_202202. All values non-NULL. (Tier 3 — DDL + data sample,  |
| `8` | 0.455 | 5 | 3 | ETL metadata: timestamp when this row was last loaded. All rows for AB_Test_lead_conv_202202: 2023-04-30 05:27. (Tier 5 — propagation) | Timestamp of when the row was inserted or last updated. Range: 2020-06-24 to 2023-04-29. All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |
| `5` | 0.53 | 3 | 3 | Name of the BI analyst or data scientist who owns the experiment analysis. Observed values: "Tom Boksenbojm". Max 14 characters — long names may be truncated. (Tier 3 — live data sampling) | Name of the BI analyst responsible for the experiment. Currently "Tom Boksenbojm" for 100% of rows. All values non-NULL. (Tier 3 — DDL + data sample, no upstream wiki) |

## Top issues — regen wiki (per judge)

- [medium] `RealCID` — Tier 1 attribution sourced from Dim_Customer wiki which was explicitly excluded from the upstream bundle ('NO UPSTREAM WIKI was resolvable'). Content is correct and verbatim, but the writer contradicted the bundle without flagging the discrepancy.
- [low] `Section 1` — Summary blockquote is excessively long (single sentence). Could be split for readability.
- [low] `Footer` — References 'Phases: 8/14' but no explicit Phase Gate Checklist section exists to show which phases were completed vs skipped.
- [low] `Section 3.3 (BI_DB_AB_Test_Data join)` — Join condition to BI_DB_AB_Test_Data suggested but not validated against companion table DDL. Column name mismatch (Name vs TestName) noted but unverified.
- [low] `RealCID` — Tier 1 attribution assumes RealCID values originate from Customer.CustomerStatic domain, but since the table was manually loaded, actual data provenance is unproven.
