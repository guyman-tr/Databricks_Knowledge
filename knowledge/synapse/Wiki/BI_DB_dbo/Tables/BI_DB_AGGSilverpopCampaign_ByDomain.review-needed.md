---
object: BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain
review_generated: 2026-04-23
batch: 80
---

# Review Needed — BI_DB_AGGSilverpopCampaign_ByDomain

## Tier 4 Items / Uncertainties

1. **Bounce metric ambiguity (Tier 3)**: `Bounce` — unclear whether this represents hard bounces only, soft bounces only, or combined. The sibling `BI_DB_AGGSilverpopCampaign` has separate `HardBounce` and `SoftBounce` columns, suggesting this table combines them. Confirm with email marketing team or Silverpop export documentation.

2. **Opened / Click — unique vs total (Tier 3)**: Both `Opened` and `Click` could represent unique or total counts. The sibling has `UniqueOpen`/`TotalOpen` and `UniqueClick`/`TotalClick` separately. Could not verify from live data (0 rows). Confirm with Silverpop export schema.

3. **MailingID FK direction**: `MailingID` appears to be FK to `BI_DB_SilverpopCampaignDictionary`. Verify the dictionary table still has valid reference data.

4. **Platform migration date**: Migration to Optimove noted as "circa 2024" — confirm exact cutover date with the email marketing or CRM team.

## Questions for Domain Experts

- Was this table used by any downstream reports or dashboards before Silverpop decommission?
- Is there a one-time historical data freeze intended (like what the `Fact_MailTracking` has)?
- Will the table ever be dropped or repurposed, or will it remain as a decommissioned artifact?

## No Cross-Object Corrections Needed

All columns match the expected domain-level breakdown pattern of the sibling `BI_DB_AGGSilverpopCampaign`. Descriptions were assigned Tier 3 throughout (consistent with Batch 79 sibling documentation).
