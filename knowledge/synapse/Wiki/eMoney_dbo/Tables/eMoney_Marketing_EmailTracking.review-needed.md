# Review Needed — eMoney_dbo.eMoney_Marketing_EmailTracking

## Flags / Reviewer Questions

1. **Table is empty**: The SP (`SP_eMoney_Marketing_EmailTracking`) is commented out in `SP_eMoney_Execute_Group_One` (SP 12). Is this table deprecated? When was it last populated and why was it disabled?

2. **Campaign whitelist**: The SP hardcodes ~20 specific campaign numbers. Are these still the correct eToro Money acquisition campaigns? Have new campaigns been added that aren't tracked?

3. **Second UNION branch**: The SP has a second `UNION` that brings in ALL campaigns (no CampaignNumber filter) — this appears to be an oversight or a placeholder for future expansion. This is confusing and may result in unexpected rows when the SP runs. Reviewer should confirm if this is intentional.

4. **CardActivations scope**: Only campaign 2208210977 is used for card activation tracking. Is this intentional or should other campaigns also track card activations?

5. **Column name "Send Date"** has a space — all queries must use brackets: `[Send Date]`. Unusual column naming convention.

6. **No Tier 1 columns**: All source data comes from BI_DB_SFMC_Report which has no upstream wiki. If SFMC email data is ever documented upstream, revisit tier assignments.

## Data Quality Observations

- Table currently empty (0 rows) — no live data available for validation
- `CreateAccount` column could double-count if the UNION logic is not de-duplicating correctly (the UNION deduplicates at the customer×campaign×send level but the final aggregation is COUNT not DISTINCT)
- `Delivered` is COUNT(DISTINCT GCID) while `UniqueOpen` is SUM — these have different counting semantics
