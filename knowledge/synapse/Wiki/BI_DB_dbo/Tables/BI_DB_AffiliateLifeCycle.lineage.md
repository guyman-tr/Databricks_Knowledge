# BI_DB_dbo.BI_DB_AffiliateLifeCycle — Column Lineage

## Source Objects

| Source Table | Source Type | Relationship |
|---|---|---|
| Unknown (no writer SP in SSDT, no references) | — | Table is dormant with 0 rows. Fully orphaned. Designed for monthly affiliate lifecycle/churn segmentation with revenue metrics. |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| YearMonthID | Unknown | — | Monthly period key (varchar(7), likely 'YYYY-MM') |
| Period | Unknown | — | Reporting period (same format as YearMonthID) |
| CreationPeriod | Unknown | — | Period when the affiliate was created/onboarded |
| Channel | Unknown | — | Marketing channel |
| SubChannel | Unknown | — | Sub-channel classification |
| ContractName | Unknown | — | Affiliate contract name |
| ContractTypeName | Unknown | — | Contract type (CPA/RevShare/Hybrid) |
| AffiliateID | Unknown | — | Affiliate partner ID |
| Contact | Unknown | — | Affiliate manager contact |
| LoginName | Unknown | — | Affiliate login name |
| AffiliatesGroupsName | Unknown | — | Affiliate group/tier |
| Registrations | Unknown | — | Monthly registration count |
| FTDs | Unknown | — | Monthly first-time deposit count |
| rn | Unknown | — | Row number (likely for deduplication or sequencing) |
| Segment | Unknown | — | Current registration-based segment |
| SegmentFTDs | Unknown | — | Current FTD-based segment |
| NewSegment | Unknown | — | New/updated registration segment |
| NewSegmentFTDs | Unknown | — | New/updated FTD segment |
| RegSleep | Unknown | — | Months since last registration (dormancy indicator) |
| FTDSleep | Unknown | — | Months since last FTD (dormancy indicator) |
| ActivitySegment | Unknown | — | Current activity segment classification |
| PreviousActivitySegment | Unknown | — | Prior month's activity segment |
| IsChurn | Unknown | — | Churn flag (1=churned, 0=active) |
| TrafficActivity | Unknown | — | Current traffic activity level classification |
| PreviousTrafficActivity | Unknown | — | Prior month's traffic activity |
| EndCont | Unknown | — | End of contract flag or count |
| ToClose | Unknown | — | Marked for closure flag or count |
| TotalCost | Unknown | — | Total marketing cost |
| RevShare | Unknown | — | Revenue share commission amount |
| TotalRevenues | Unknown | — | Total revenues generated |
| TotalNetRevenues | Unknown | — | Net revenues (revenues - costs) |
| UpdateDate | Unknown | — | ETL metadata timestamp |
