---
object: BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain
type: Table
lineage_version: 1
generated: 2026-04-23
---

# Column Lineage — BI_DB_AGGSilverpopCampaign_ByDomain

## Source Summary

| Property | Value |
|----------|-------|
| **Production Source** | IBM Silverpop (Watson Campaign Automation) — third-party SaaS email platform; migrated to Optimove ~2024 |
| **Writer SP** | None — no writer SP found in SSDT; table is empty and decommissioned |
| **ETL Pattern** | Unknown (platform direct export, now inactive) |
| **UC Target** | _Not_Migrated |
| **Sibling Table** | BI_DB_dbo.BI_DB_AGGSilverpopCampaign (per-mailing aggregate; Domain-clustered sibling) |

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | MailingID | IBM Silverpop (SaaS) | mailing_id | Passthrough — unique mailing identifier, FK to BI_DB_SilverpopCampaignDictionary | Tier 3 |
| 2 | Year | IBM Silverpop (SaaS) | year | Passthrough — calendar year extracted from campaign send date | Tier 3 |
| 3 | Week | IBM Silverpop (SaaS) | week | Passthrough — ISO/calendar week number of the campaign send | Tier 3 |
| 4 | Domain | IBM Silverpop (SaaS) | email_domain | Passthrough — email domain of recipients (e.g., gmail.com, yahoo.com) | Tier 3 |
| 5 | Sent | IBM Silverpop (SaaS) | sent_count | Passthrough — emails delivered to this domain | Tier 3 |
| 6 | Bounce | IBM Silverpop (SaaS) | bounce_count | Passthrough — combined hard + soft bounces for this domain | Tier 3 |
| 7 | Opened | IBM Silverpop (SaaS) | open_count | Passthrough — emails opened by recipients in this domain | Tier 3 |
| 8 | Click | IBM Silverpop (SaaS) | click_count | Passthrough — clicks by recipients in this domain | Tier 3 |
| 9 | Date | IBM Silverpop (SaaS) | send_date | Passthrough — campaign send date | Tier 3 |
| 10 | UpdateDate | ETL metadata | GETDATE() | ETL run timestamp — propagation column | Tier 5 |

## Notes

- No upstream wiki exists (IBM Silverpop is a third-party SaaS platform with no repo-based documentation).
- Table is empty (0 rows as of 2026-04-23). The Silverpop platform was migrated to Optimove ~2024; all DWH Silverpop dimension tables now carry JUNK_ prefix.
- Domain-level breakdown of BI_DB_AGGSilverpopCampaign: same mailing metrics segmented by recipient email domain (gmail.com, yahoo.com, etc.).
- No Generic Pipeline UC target registered.
