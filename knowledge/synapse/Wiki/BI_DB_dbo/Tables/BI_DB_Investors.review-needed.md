# BI_DB_dbo.BI_DB_Investors — Review Needed

## Tier 4 Items

None — no Tier 4 descriptions in this wiki.

## Review Questions

1. **Amount = NetMI naming**: The DDL column "Amount" is populated from "NetMI" (Net Money Invested) in the SP. This naming discrepancy could confuse downstream consumers. Consider a column rename or alias.

2. **AUM_AUA dual semantics**: For Copy streams this is AUM (Assets Under Management), for Manual/Balance it's AUA (Assets Under Administration). The single column collapses two different metrics. Is this intentional for reporting simplicity?

3. **Customer count inconsistency**: Manual and Copy use COUNT(DISTINCT CID) but Balance uses COUNT(CID). If a customer has multiple balance rows, they'd be counted multiple times in the Balance stream. Is this by design?

4. **BI_DB_Investors_STG source**: The staging table pre-aggregates the three streams. What populates BI_DB_Investors_STG? That SP would be the true upstream for lineage.

5. **Only Manual ActionType in recent data**: The Apr 2026 sample shows only 'Manual' rows. Are Copy and Balance streams delayed or have they been removed?

## Reviewer Corrections

None yet.
