# Review Notes — BI_DB_dbo.BI_DB_Bing_PBI_Daily_Perf

**Batch**: 14 | **Generated**: 2026-04-21 | **Reviewer**: Marketing / Performance Team

---

## Tier 4 Items

None. All columns are Tier 2 — direct passthroughs from the Fivetran Bing Ads external table. No upstream wiki exists for the external Bing Ads API source.

---

## Open Questions for Reviewer

1. **Fivetran connector status**: Max date is 2025-10-16 and max UpdateDate is 2025-10-17. Has the Fivetran bingads connector been decommissioned or paused? If data should be more recent, the connector may need to be restarted.

2. **numeric(18,0) truncation on CPC/spend/position**: `current_max_cpc`, `spend`, and `average_position` lose all decimal precision. For accurate financial reporting (e.g., spend in dollars and cents), is this acceptable, or should the external table be queried directly?

3. **keyword_id as varchar(max)**: The DDL stores keyword IDs as varchar(max). Confirm this is intentional — Bing Ads keyword IDs are bigint values but may be treated as strings in some reporting contexts.

4. **average_position deprecation**: Microsoft Advertising deprecated the `average_position` metric. Is this column still being populated by Fivetran, or is it always 0/NULL for recent dates?

5. **SP_Bing_PBI loads 4 tables**: This SP also populates BI_DB_Bing_PBI_Group_Dict, BI_DB_Bing_PBI_Campaign_Dict, and BI_DB_Bing_PBI_Goals_Funnels. If the SP fails mid-run, some tables may be out of sync with others. Is there error handling or alerting for this?

---

## Known Data Quirks

- **`Clicks` is PascalCase** unlike all other lowercase columns — be careful with case-sensitive SQL clients.
- **Incremental load (DELETE+INSERT)** — partial data risk if SP fails after DELETE but before INSERT completes.
- **`_fivetran_synced` ≠ `UpdateDate`** — Fivetran sync time vs. Synapse load time differ by hours.
- **No grain key enforced** — the natural grain is campaign_id × ad_group_id × keyword_id × date × delivered_match_type × device_type × device_os × language × network × top_vs_other. No unique constraint prevents duplicates.
