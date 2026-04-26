# BI_DB_dbo.BI_DB_MarketingCloudDaily — Review Needed

## Tier 4 Items (5 columns — all legacy)

| Column | Current Tier | Question |
|--------|-------------|----------|
| eMoneyIsInRollout | T4 — legacy | No longer populated by SP. All NULL in live data. Confirm if column should be dropped from DDL. |
| eMoneyIsInRolloutDate | T4 — legacy | Same as above. |
| AirDropRemainder | T4 — legacy | No longer populated by SP. All NULL. Was this an airdrop/crypto feature? |
| AirdropServeyDate | T4 — legacy | Typo in name ("Servey"). No longer populated. |
| AirdropPotentialUpdateDate | T4 — legacy | No longer populated. |

## Questions for Reviewer

1. **SFTP upload destination**: The SP comment says "MarketingCloud Daily DataSet to be uploaded to SFTP." What is the exact SFTP target and upload frequency? Is there a separate job that handles the export?
2. **eMoneyIsInRollout block**: The SP no longer contains code to populate eMoneyIsInRollout/eMoneyIsInRolloutDate. Were these removed in a past SP revision? Should the DDL columns be dropped?
3. **AirDrop columns**: AirDropRemainder, AirdropServeyDate, AirdropPotentialUpdateDate are all NULL. Were these part of the eToro crypto airdrop feature? Are they safe to remove?
4. **GainDaily source**: DWH_GainDaily is not in OpsDB or the SSDT repo as a standard table. Is this a view or a different pipeline output?
5. **RAF_Inviter stored as decimal(16,6)**: The SP stores Dim_Customer.GCID (int) into a decimal(16,6) column. Is this intentional for Marketing Cloud compatibility?

## Cross-Object Consistency Notes

- CID matches DWH_dbo.Dim_Customer.RealCID usage across all BI_DB tables.
- Credit matches V_Liabilities.Credit description from DWH_dbo wiki.
- CashoutAmount_InProcess matches V_Liabilities.InProcessCashouts description.
- AccountId matches Dim_Customer.SalesForceAccountID description.
- PrivacyPolicyID matches Dim_Customer wiki description.
- AirdropCustomerID matches Dim_Customer.ID description.
