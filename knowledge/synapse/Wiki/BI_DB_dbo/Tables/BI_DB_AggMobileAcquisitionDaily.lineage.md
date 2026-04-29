# BI_DB_dbo.BI_DB_AggMobileAcquisitionDaily — Column Lineage

## Source Objects

| Source Table | Source Type | Relationship |
|---|---|---|
| Unknown (no writer SP in SSDT, no references) | — | Table is dormant with 0 rows. Fully orphaned. Designed for daily mobile app install-to-FTD acquisition funnel by affiliate. |

## Column Lineage

| Synapse Column | Source Table | Source Column | Transform |
|---|---|---|---|
| Date | Unknown | — | Daily date |
| DateID | Unknown | — | Integer date key (YYYYMMDD) |
| AffiliateID | Unknown | — | Affiliate partner ID |
| Cocntact | Unknown | — | Affiliate manager contact (TYPO: should be "Contact") |
| AffiliatesGroupsName | Unknown | — | Affiliate group/tier |
| PaymentTrigger | Unknown | — | Commission payment trigger event type |
| CPA_Plan | Unknown | — | CPA pricing plan name/tier |
| Desk | Unknown | — | Account management desk |
| Region | Unknown | — | Geographic region |
| Country | Unknown | — | Customer country |
| TierCountry | Unknown | — | Country tier classification (1/2/3 for revenue potential) |
| Platform | Unknown | — | Mobile platform (iOS/Android) |
| Installs | Unknown | — | App install count |
| Registrations | Unknown | — | Registration count |
| FTDs | Unknown | — | First-time deposit count |
| FraudFTDs | Unknown | — | Fraudulent FTD count (excluded from commission) |
| Verification1 | Unknown | — | KYC Level 1 completion count |
| Verification2 | Unknown | — | KYC Level 2 completion count |
| Verification3 | Unknown | — | KYC Level 3 completion count |
| FTDEs | Unknown | — | First-time deposit equivalents |
| FirstAction | Unknown | — | First trading action count |
| ReDeposit | Unknown | — | Redeposit count |
| UpdateDate | Unknown | — | ETL metadata timestamp |
| Rev8Y_LTV | Unknown | — | 8-year revenue LTV metric |
| Rev8Y_LTV_NoExtreme | Unknown | — | 8-year revenue LTV excluding extreme outliers |
| CPA | Unknown | — | Cost per acquisition amount |
| Cost | Unknown | — | Total cost/spend |
| FTDAmount | Unknown | — | Total first deposit monetary amount |
| RedepositsAmount | Unknown | — | Total redeposit monetary amount |
