# BI_DB_dbo.BI_DB_AggMobileAcquisitionMonthly — Column Lineage

## Source Objects

| Source | Type | Relationship |
|--------|------|-------------|
| (Unknown) | Unknown | No writer SP found in SSDT; table is fully orphaned |

## Column Lineage

| # | Synapse Column | Source Table | Source Column | Transform | Confidence |
|---|---------------|-------------|---------------|-----------|------------|
| 1 | YearMonth | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 2 | AffiliateID | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 3 | Cocntact | Unknown | Unknown | Unknown — no writer SP (typo: should be "Contact") | Tier 4 |
| 4 | AffiliatesGroupsName | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 5 | PaymentTrigger | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 6 | CPA_Plan | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 7 | Desk | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 8 | Region | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 9 | Country | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 10 | TierCountry | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 11 | Platform | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 12 | Installs | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 13 | Registrations | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 14 | FTDs | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 15 | FraudFTDs | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 16 | Verification1 | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 17 | Verification2 | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 18 | Verification3 | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 19 | FTDEs | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 20 | FirstAction | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 21 | ReDeposit | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 22 | UpdateDate | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 23 | Rev8Y_LTV | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 24 | Rev8Y_LTV_NoExtreme | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 25 | CPA | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 26 | Cost | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 27 | FTDAmount | Unknown | Unknown | Unknown — no writer SP | Tier 4 |
| 28 | RedepositsAmount | Unknown | Unknown | Unknown — no writer SP | Tier 4 |

## Lineage Notes

- **Fully orphaned**: No stored procedure in the Synapse SSDT repo reads or writes this table
- **Not in OpsDB**: No orchestration entry exists
- **Not in Generic Pipeline**: No Bronze/lake mapping found
- **Sibling table**: BI_DB_AggMobileAcquisitionDaily has identical columns (except DateID/Date instead of YearMonth) and is also 0-row dormant
- **Likely origin**: Legacy on-prem BI_DB mobile marketing report, never re-implemented in Synapse after migration
