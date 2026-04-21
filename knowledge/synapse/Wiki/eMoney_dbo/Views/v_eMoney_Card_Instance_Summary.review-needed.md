# Review Needed — eMoney_dbo.v_eMoney_Card_Instance_Summary

## Flags / Reviewer Questions

1. **PII Handling**: MaskedPAN is excluded by the view (commented out in DDL). Confirm that all analytical pipelines using card instance data route through this view, not the base table, to minimize PAN exposure surface.

2. **UC Target**: Base table has a UC Gold target (`main.emoney.gold_sql_dp_prod_we_emoney_dbo_emoney_card_instance_summary`). This view does not. Should the view also have a UC target, or is the base table UC Gold sufficient for downstream consumption?

3. **Element row 7 (IsValidETM)**: The description references a row count from the base table (99.1%/0.9%). These percentages will drift over time. Consider removing stats from the verbatim description if this causes confusion (rule: no snapshot stats in descriptions).

4. **View type**: The view uses a simple SELECT without any WHERE clause — it is purely a column-projection view. No current concern, but future changes to the base table structure (column add/rename/remove) will automatically affect this view's behavior.

## Data Quality Observations

- No data quality issues beyond those already noted in the base table review sidecar
- View has been previously REVOKED (documented in _index.md as "batch 5 ran without MCP") — this rebuild used live MCP data from the base table
