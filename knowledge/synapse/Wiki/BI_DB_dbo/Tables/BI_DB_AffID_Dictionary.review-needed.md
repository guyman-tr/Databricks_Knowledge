# BI_DB_dbo.BI_DB_AffID_Dictionary — Review Needed

## Tier 4 Items (require human verification)

| Column | Current Tier | Question |
|--------|-------------|----------|
| AffiliateID | Tier 4 | Confirmed from commented SP code (campaign_name RIGHT(5) extraction). What are actual valid affiliate IDs? |
| Region | Tier 4 | What are the valid region values? APAC/EMEA/NA? Or country-level? |
| Channel | Tier 4 | What marketing channels were tracked? web/social/display? |

## Questions for Reviewer

1. **Decommission candidate**: 0 rows, only commented-out SP reference. Should this table be dropped?
2. **Was it ever populated?**: Did this table have data on the on-prem BI_DB before Synapse migration?
3. **Replacement mechanism**: How does SP_Marketing_Cube currently resolve campaign→affiliate mapping without this dictionary?
