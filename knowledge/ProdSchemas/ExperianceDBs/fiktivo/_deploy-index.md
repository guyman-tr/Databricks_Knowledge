---

## bronze: fiktivo

db_key: ExperianceDBs/fiktivo
total_deployable: 49
generated: 0
failed: 15
deployed: 34
last_generated: "2026-04-30"
last_deploy_batch: 1
last_deployed: "2026-05-03"
source_tool: tools/uc_bronze/generate_bronze_alters.py

## Bronze ALTER Generation Status

| Object | UC Target | Status |
|--------|-----------|--------|
| [AffiliateClicks.ClicksImpressionsAggregation](Wiki/AffiliateClicks/Tables/AffiliateClicks.ClicksImpressionsAggregation.md) | `main.general.bronze_fiktivo_affiliateclicks_clicksimpressionsaggregation` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.ClosedPositionCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommissionvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.ClosedPositionCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositioncommission` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_closedpositionc |
| [AffiliateCommission.ClosedPositionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_closedposition` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_closedposition` |
| [AffiliateCommission.ClosedPositionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.ClosedPositionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_closedpositionvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.CreditAccountMapping](Wiki/AffiliateCommission/Tables/AffiliateCommission.CreditAccountMapping.md) | `main.experience.bronze_fiktivo_affiliatecommission_creditaccountmapping` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.CreditCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_creditcommission` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_creditcommissio |
| [AffiliateCommission.CreditCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.CreditCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_creditcommissionvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.CreditVW](Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_credit` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_credit` cannot  |
| [AffiliateCommission.CreditVW](Wiki/AffiliateCommission/Views/AffiliateCommission.CreditVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_creditvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.CustomerAggregatedData](Wiki/AffiliateCommission/Tables/AffiliateCommission.CustomerAggregatedData.md) | `main.general.bronze_fiktivo_affiliatecommission_customeraggregateddata` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `DateModified` cannot be resolve |
| [AffiliateCommission.RegistrationCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommission` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_registrationcom |
| [AffiliateCommission.RegistrationCommissionVW](Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationCommissionVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_registrationcommissionvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.RegistrationMetaData](Wiki/AffiliateCommission/Tables/AffiliateCommission.RegistrationMetaData.md) | `main.experience.bronze_fiktivo_affiliatecommission_registrationmetadata` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateCommission.RegistrationVW](Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_registration` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_affiliatecommission_registration` c |
| [AffiliateCommission.RegistrationVW](Wiki/AffiliateCommission/Views/AffiliateCommission.RegistrationVW.md) | `main.bi_db.bronze_fiktivo_affiliatecommission_registrationvw` | Deployed (Batch 1) - 2026-05-03 |
| [AffiliateConfiguration.TraderFirstAssetPosition](Wiki/AffiliateConfiguration/Tables/AffiliateConfiguration.TraderFirstAssetPosition.md) | `main.bi_db.bronze_fiktivo_affiliateconfiguration_traderfirstassetposition` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.Action](Wiki/Dictionary/Tables/Dictionary.Action.md) | `main.general.bronze_fiktivo_dictionary_action` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.ChangedSections](Wiki/Dictionary/Tables/Dictionary.ChangedSections.md) | `main.general.bronze_fiktivo_dictionary_changedsections` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.MarketingRegion](Wiki/Dictionary/Tables/Dictionary.MarketingRegion.md) | `main.experience.bronze_fiktivo_dictionary_marketingregion` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentMethods](Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md) | `main.bi_db.bronze_fiktivo_dictionary_paymentmethods` | Deployed (Batch 1) - 2026-05-03 |
| [Dictionary.PaymentMethods](Wiki/Dictionary/Tables/Dictionary.PaymentMethods.md) | `bi_db.bronze_fiktivo_fiktivo_dictionary.paymentmethods` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `bi_db`.`bronze_fiktivo_fiktivo_dictionary`.`paymentmethods` canno |
| [Dictionary.PositionAssetType](Wiki/Dictionary/Tables/Dictionary.PositionAssetType.md) | `main.bi_db.bronze_fiktivo_dictionary_positionassettype` | Deployed (Batch 1) - 2026-05-03 |
| [KYP.AffiliateCountriesOfOperation](Wiki/KYP/Tables/KYP.AffiliateCountriesOfOperation.md) | `main.general.bronze_fiktivo_kyp_affiliatecountriesofoperation` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.AuditLog](Wiki/dbo/Tables/dbo.AuditLog.md) | `main.general.bronze_fiktivo_dbo_auditlog` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.Channels](Wiki/dbo/Tables/dbo.Channels.md) | `main.bi_db.bronze_fiktivo_dbo_channels` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.MediaTag](Wiki/dbo/Tables/dbo.MediaTag.md) | `main.bi_db.bronze_fiktivo_dbo_mediatag` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.MediaTagBanner](Wiki/dbo/Tables/dbo.MediaTagBanner.md) | `main.bi_db.bronze_fiktivo_dbo_mediatagbanner` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_AffiliateTypes](Wiki/dbo/Tables/dbo.tblaff_AffiliateTypes.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatetypes` | Failed (Batch 1) - DESCRIBE: [TABLE_OR_VIEW_NOT_FOUND] The table or view `main`.`bi_db`.`bronze_fiktivo_dbo_tblaff_affiliatetypes` cannot b |
| [dbo.tblaff_Affiliates](Wiki/dbo/Tables/dbo.tblaff_Affiliates.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `ValidTo` cannot be resolved. Di |
| [dbo.tblaff_Affiliates](Wiki/dbo/Tables/dbo.tblaff_Affiliates.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliates_masked` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `ValidTo` cannot be resolved. Di |
| [dbo.tblaff_AffiliatesGroups](Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups_masked` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_AffiliatesGroups](Wiki/dbo/Tables/dbo.tblaff_AffiliatesGroups.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_affiliatesgroups` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_BannerTypes](Wiki/dbo/Tables/dbo.tblaff_BannerTypes.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_bannertypes` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_Banners](Wiki/dbo/Tables/dbo.tblaff_Banners.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_banners` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `ValidTo` cannot be resolved. Di |
| [dbo.tblaff_Country](Wiki/dbo/Tables/dbo.tblaff_Country.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_country` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_FirstPositions](Wiki/dbo/Tables/dbo.tblaff_FirstPositions.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_FirstPositions_Commissions](Wiki/dbo/Tables/dbo.tblaff_FirstPositions_Commissions.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_firstpositions_commissions` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_Languages](Wiki/dbo/Tables/dbo.tblaff_Languages.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_languages` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_Leads](Wiki/dbo/Tables/dbo.tblaff_Leads.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_leads` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_Leads_Commissions](Wiki/dbo/Tables/dbo.tblaff_Leads_Commissions.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_leads_commissions` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_MarketingExpense](Wiki/dbo/Tables/dbo.tblaff_MarketingExpense.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_marketingexpense` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_PaymentDetails](Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails_masked` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_PaymentDetails](Wiki/dbo/Tables/dbo.tblaff_PaymentDetails.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_paymentdetails` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_PaymentHistory](Wiki/dbo/Tables/dbo.tblaff_PaymentHistory.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_paymenthistory` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `Tier1FirstPositions through Tie |
| [dbo.tblaff_User](Wiki/dbo/Tables/dbo.tblaff_User.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_user` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `ValidTo` cannot be resolved. Di |
| [dbo.tblaff_User](Wiki/dbo/Tables/dbo.tblaff_User.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_user_masked` | Failed (Batch 1) - [UNRESOLVED_COLUMN.WITH_SUGGESTION] A column, variable, or function parameter with name `ValidTo` cannot be resolved. Di |
| [dbo.tblaff_eCost](Wiki/dbo/Tables/dbo.tblaff_eCost.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_ecost` | Deployed (Batch 1) - 2026-05-03 |
| [dbo.tblaff_eCost_Commissions](Wiki/dbo/Tables/dbo.tblaff_eCost_Commissions.md) | `main.bi_db.bronze_fiktivo_dbo_tblaff_ecost_commissions` | Deployed (Batch 1) - 2026-05-03 |
