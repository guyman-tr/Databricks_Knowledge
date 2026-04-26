# BI_DB_Bing_PBI_Campaign_Dict — Review Notes

**Object**: BI_DB_dbo.BI_DB_Bing_PBI_Campaign_Dict
**Batch**: 15 | **Date**: 2026-04-21 | **Reviewer Needed**: Marketing Analytics / Paid Search team

## Tier 4 Items / Reviewer Questions

1. **History-feed vs. latest-state design intent**: The SP does TRUNCATE+INSERT from `External_Fivetran_bingads_campaign_history` with GROUP BY (dedup only). This means the table is a full history of campaign state changes, not a "latest-state" dictionary. If Power BI consumers are joining on `id` without a latest-state filter, they will get fan-out duplicates. Reviewer: is the current table design intentional as a history table, or should it be a deduplicated latest-state lookup? Was this ever the source of double-counting in reports?

2. **numeric(18,0) precision for bid values**: `bid_strategy_max_cpc` and `bid_strategy_target_cpa` are stored as `numeric(18,0)` — any fractional bid precision from Bing Ads is truncated. Bing Ads bids can have up to 2 decimal places (e.g., CPC of $0.35 becomes 0 in this table). Reviewer: is the integer truncation a known limitation or was this meant to be `numeric(18,2)`? Are any reports computing averages or comparisons on these fields that are affected?

3. **Account currency not stored**: Budget and bid amounts are in the account's configured currency, but the `account_id` → currency mapping is not present in this table. Reviewer: is there a separate mapping table that joins `account_id` to currency? Without it, comparing budgets across accounts assumes a single currency.

4. **SP comment: "need to fix" on Group_Dict source**: The SP code for BI_DB_Bing_PBI_Group_Dict includes the comment `--need to fix` on the source table name (`External_Fivetran_bingads_ad_group_history`). This same SP writes Campaign_Dict — reviewer: is there a known data quality or source issue with the Fivetran bingads connector that affects all 4 tables SP_Bing_PBI writes?

5. **Deleted campaigns retained in table**: 104 rows with `status='Deleted'` are present in the table. For Power BI consumers building campaign lists or dropdowns, these deleted campaigns will appear unless filtered. Reviewer: should deleted campaigns be excluded from this table, or are they intentionally retained for historical reporting?

6. **No consumers in SSDT**: No SP or view in the Synapse SSDT repo reads from this table. Confirm it is consumed only via Power BI DirectQuery or import from Synapse. If there are downstream pipelines outside Synapse (e.g., Azure Data Factory, Databricks), document them here.

## No Issues

- All 10 columns documented with Tier 2 suffixes (Fivetran pass-through — no upstream wiki inheritance applicable)
- Row count (4,068), distinct campaign count (622), account count (12), status and bid_strategy_type distributions confirmed from live data
- History-feed pattern and TRUNCATE+INSERT refresh cycle clearly documented in §2.1 and §2.2
- History-feed fan-out gotcha documented in §3.4 with ROW_NUMBER() latest-state query in §7
