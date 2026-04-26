# Lineage: BI_DB_dbo.BI_DB_AGGSilverpopCampaign

**Generated**: 2026-04-23
**Schema**: BI_DB_dbo
**Object**: BI_DB_AGGSilverpopCampaign
**Object Type**: Table — Silverpop email campaign aggregate metrics (per-campaign KPI rollup)
**Writer SP**: None identified (no writer SP in SSDT BI_DB_dbo; not registered in OpsDB)
**Production Source**: Unknown — Silverpop (IBM email marketing platform, now Watson Campaign Automation); platform migrated to Optimove circa 2024
**Related Tables**:
- `BI_DB_dbo.BI_DB_SilverpopCampaignDictionary` (MailingID FK — mailing names, campaign numbers, subjects)
- `BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain` (domain-clustered sibling aggregate)
- `BI_DB_dbo.BI_DB_SilverpopLanguage` (language reference)
- `BI_DB_dbo.BI_DB_MistakenSilverpopCampaignDictionary` (correction table for mislabeled campaigns)
**Platform Migration**: Silverpop (IBM) → Optimove, evidenced by JUNK_ prefix on DWH Silverpop dimension tables and `Dim_SilverToOpti_Mail_Rel` mapping table

## Column Lineage

| # | Column | Source Table | Source Column | Transform | Tier |
|---|--------|-------------|---------------|-----------|------|
| 1 | MailingID | Silverpop platform | MailingID | Passthrough; FK to BI_DB_SilverpopCampaignDictionary | Tier 3 |
| 2 | CampaignID | Silverpop platform | CampaignID | Passthrough | Tier 3 |
| 3 | CampaignDate | Silverpop platform | CampaignDate | Email send date; clustered index key | Tier 3 |
| 4 | TotalCustomers | Silverpop platform | TotalCustomers | Total audience size for this mailing | Tier 3 |
| 5 | MailsSent | Silverpop platform | MailsSent | Total emails successfully sent | Tier 3 |
| 6 | Seeded | Silverpop platform | Seeded | Seed list (internal test) recipients sent | Tier 3 |
| 7 | Suppressed | Silverpop platform | Suppressed | Emails blocked by suppression list (opt-outs, global bounces) | Tier 3 |
| 8 | HardBounce | Silverpop platform | HardBounce | Permanent delivery failures (invalid address, domain not found) | Tier 3 |
| 9 | SoftBounce | Silverpop platform | SoftBounce | Temporary delivery failures (mailbox full, server unavailable) | Tier 3 |
| 10 | UniqueOpen | Silverpop platform | UniqueOpen | Recipients who opened (deduplicated — one per recipient) | Tier 3 |
| 11 | TotalOpen | Silverpop platform | TotalOpen | Total open events (multiple opens per recipient counted) | Tier 3 |
| 12 | UniqueClick | Silverpop platform | UniqueClick | Recipients who clicked any link (deduplicated) | Tier 3 |
| 13 | TotalClick | Silverpop platform | TotalClick | Total click events (multiple clicks per recipient counted) | Tier 3 |
| 14 | Unsubscribed | Silverpop platform | Unsubscribed | Recipients who opted out via unsubscribe link | Tier 3 |
| 15 | ReportedAbuse | Silverpop platform | ReportedAbuse | Recipients who marked email as spam/abuse | Tier 3 |
| 16 | UpdateDate | ETL pipeline | — | Load timestamp | Tier 5 |
| 17 | EmailDomainID | Silverpop platform | EmailDomainID | FK to email domain reference | Tier 3 |
| 18 | Domain | Silverpop platform | Domain | De-normalized email domain name (e.g., gmail.com, yahoo.com) | Tier 3 |

## ETL Pipeline

```
Silverpop (IBM email marketing platform — now Watson Campaign Automation)
  |-- Unknown feed mechanism (no Generic Pipeline, no External Table, no SSDT SP) --|
  v
BI_DB_dbo.BI_DB_AGGSilverpopCampaign (0 rows — EMPTY as of 2026-04-23)

Silverpop platform migrated to Optimove circa 2024:
  DWH_Migration.JUNK_Dim_SilverpopMailing (archived 2024-09-22)
  DWH_Migration.JUNK_Dim_SilverpopSubject (archived 2024-09-22)
  DWH_Migration.JUNK_Dim_SilverpopEventType (archived 2024-09-22)
  DWH_Migration.JUNK_Dim_SilverToOpti_Mail_Rel (Silverpop → Optimove mapping)

Related Silverpop ecosystem tables (still in DDL):
  BI_DB_dbo.BI_DB_SilverpopCampaignDictionary (MailingID → MailingName, CampaignName, Subject)
  BI_DB_dbo.BI_DB_AGGSilverpopCampaign_ByDomain (domain-clustered sibling aggregate)
  BI_DB_dbo.BI_DB_SilverpopLanguage (language/locale reference)

DWH-side Silverpop data (still active for historical queries):
  DWH.mailtracking.Fact_MailTracking (individual-level email events, SilverpopEventID=16 for sent)
  DWH.mailtracking.Dim_SilverpopMailing (mailing metadata)
```

## Notes

- Table is currently empty (0 rows as of 2026-04-23)
- Silverpop was eToro's email marketing platform (IBM acquisition — Watson Campaign Automation)
- Platform migrated to Optimove circa 2024 — all DWH Silverpop dimension tables are now JUNK_ prefixed
- `AGGSilverpopCampaign` = per-campaign aggregate (CampaignDate-clustered) vs sibling `AGGSilverpopCampaign_ByDomain` (domain-clustered)
- MailingID FK links to `BI_DB_SilverpopCampaignDictionary` for campaign name, number, segment, subject
- EmailDomainID + Domain appear together — Domain is de-normalized from a domain reference table
- MailsSent < TotalCustomers when Seeded or Suppressed addresses are excluded
- UniqueOpen ≤ TotalOpen; UniqueClick ≤ TotalClick (Unique = deduplicated per recipient)
