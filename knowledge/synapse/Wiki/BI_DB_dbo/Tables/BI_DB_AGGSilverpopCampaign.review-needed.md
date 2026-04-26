# Review Needed: BI_DB_dbo.BI_DB_AGGSilverpopCampaign

**Generated**: 2026-04-23
**Quality Score**: 6.5/10
**Status**: Needs domain expert review

## Open Questions

1. **Silverpop migration status** — The Silverpop platform was migrated to Optimove circa 2024 (evidenced by JUNK_ prefix on DWH dimension tables and Dim_SilverToOpti_Mail_Rel mapping). Is this table permanently decommissioned, or is there a plan to repopulate with Optimove data using the same schema?

2. **Writer SP** — No writer SP found in SSDT BI_DB_dbo. How was this table populated from Silverpop? Was it via a direct API export to Synapse, an SSIS package, or an external ETL?

3. **Domain column granularity** — `Domain` and `EmailDomainID` appear in the main campaign aggregate table. Does one row represent the whole campaign OR one row per campaign per domain? If per domain, how does this relate to the sibling `BI_DB_AGGSilverpopCampaign_ByDomain`?

4. **EmailDomainID reference table** — What table does `EmailDomainID` reference? No domain dimension table was found in the SSDT BI_DB_dbo Tables folder.

5. **CampaignID vs MailingID** — What is the difference between `CampaignID` (int, NOT NULL) and `MailingID` (int, NOT NULL)? Are these both Silverpop-native IDs? Is there a 1:1 or 1:many relationship between CampaignID and MailingID?

6. **Historical data location** — Is historical Silverpop campaign data still queryable via `DWH.mailtracking.Fact_MailTracking` + `DWH.mailtracking.Dim_SilverpopMailing`? Or was it also cleared during the Optimove migration?

## Columns Requiring Confirmation

| Column | Concern |
|--------|---------|
| CampaignID | Tier 3 — relationship to MailingID unclear (1:1 vs 1:many). Confirm Silverpop hierarchy. |
| Seeded | Tier 3 — seed list count. Confirm if included in or excluded from MailsSent. |
| Domain | Tier 3 — de-normalized domain name. Confirm granularity (one per campaign vs one per domain per campaign). |
| EmailDomainID | Tier 3 — FK to unknown reference table. Confirm which table. |

## Lineage Gaps

- Production source (Silverpop API export mechanism) unknown
- No Generic Pipeline, no External Table, no SSDT SP feeds this table
- Silverpop platform fully decommissioned — no future data expected without migration
- `Dim_SilverToOpti_Mail_Rel` could provide historical continuity for MailingID-to-Optimove mapping

## Platform Context

- Silverpop (acquired by IBM 2014, now Watson Campaign Automation)
- DWH Silverpop tables archived as JUNK_ on 2024-09-22 during DWH_Migration
- `Dim_SilverToOpti_Mail_Rel` = Silverpop-to-Optimove mailing relationship table (transitional mapping)
- Individual email events (opens, clicks) still in `DWH.mailtracking.Fact_MailTracking` (SilverpopEventID=16 for sent)
