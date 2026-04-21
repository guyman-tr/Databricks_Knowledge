# EXW_dbo.EXW_WalletElligibleCountries — Review Needed

**Generated**: 2026-04-20 | **Quality**: 8.8/10 | **Phase 16 evaluator**: Pending

## Tier 4 Items (Low-Confidence — Reviewer Verification Needed)

None — 4 columns are Tier 1 (CountryID, Country, MarketingRegionID from Dictionary.Country; Regulation from Dictionary.Regulation) and 13 are Tier 2 with clear SP traceability.

## Open Questions for Reviewer

1. **ReadOnly (SelectedValue=1) not observed in current data**: The wiki documents SelectedValue=1 as ReadOnly (wallet visible, no new operations). Confirm whether this state is currently used for any country or if it exists only as a schema definition. A live query `SELECT DISTINCT SelectedValue, CountryOpenforWalletDescription FROM EXW_WalletElligibleCountries` would confirm.

2. **New TagType `CountryRegionAndRegulation` (2026-04-14)**: SP_EXW_WalletElligibleCountries added a third TagType value in April 2026, allowing country+region+regulation-level overrides in addition to country-level and regulation-level. Confirm whether any rows have been populated with this new tag type, and whether the priority resolution logic (Max(RestrictionWeight)) correctly handles three-way ties.

3. **EXW_Coin_Transfer_Allowed_Country co-population**: SP_EXW_WalletElligibleCountries writes to BOTH this table AND EXW_Coin_Transfer_Allowed_Country in a single execution. Confirm that these two tables always share the same SP run (i.e., they are never out of sync), and whether the wiki for EXW_Coin_Transfer_Allowed_Country documents this shared SP dependency.

4. **4,228 row count vs. expected cardinality**: With ~250 countries, ~14 regulations, and US state overrides, 4,228 rows is plausible but not obviously derivable. Confirm whether the row count is expected given the current country×regulation×state configuration, or if there are stale/duplicate rows from prior SP runs.

5. **`[US State]` bracket-quoting requirement**: The column name contains a space, requiring bracket syntax in all SQL queries. Confirm whether downstream consumer SP_EXW_UserSettingsWalletAllowance correctly uses `[US State]` in all references (no implicit alias or ORM-generated queries that might strip brackets).

## Carry-Forward Notes

- TagType='Default' means no specific rule configured; the fallback SelectedValue applies.
- Priority resolution: Max(RestrictionWeight) wins per CountryID×RegulationID×RegionByIP_ID group.
- `[US State]` column: NULL for CountryID≠219 (non-US); RegionByIP_ID=ISNULL(...,0) ensures 0 for non-US.
- All T1 columns (CountryID, Country, MarketingRegionID, Regulation) copied verbatim from upstream wikis — do not paraphrase.
