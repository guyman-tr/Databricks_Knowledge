# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_RiskClassification`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_RiskClassification.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_RiskClassification]
(
	[RiskScore_Explanation] [nvarchar](max) NULL,
	[Regulation] [varchar](50) NULL,
	[RiskScoreName] [varchar](20) NULL,
	[GCID] [int] NULL,
	[CID] [int] NULL,
	[RegulationID] [int] NULL,
	[RiskScore] [int] NULL,
	[RiskScore_Value] [varchar](50) NULL,
	[BeginTime] [datetime] NULL,
	[EndTime] [datetime] NULL,
	[Country of Residence, Onboarding_RiskScore] [int] NULL,
	[Country of Residence, Onboarding_Value] [varchar](50) NULL,
	[Country of Residence, Existing clients_RiskScore] [int] NULL,
	[Country of Residence, Existing clients_Value] [varchar](50) NULL,
	[Age of customer_RiskScore] [int] NULL,
	[Age of customer_Value] [varchar](50) NULL,
	[Age Alert_RiskScore] [int] NULL,
	[Age Alert_Value] [varchar](50) NULL,
	[PEP Check_RiskScore] [int] NULL,
	[PEP Check_Value] [varchar](50) NULL,
	[Main Source of Income_RiskScore] [int] NULL,
	[Main Source of Income_Value] [varchar](50) NULL,
	[Occupation_RiskScore] [int] NULL,
	[Occupation_Value] [varchar](50) NULL,
	[Special Score_RiskScore] [int] NULL,
	[Special Score_Value] [varchar](50) NULL,
	[Annual Income_RiskScore] [int] NULL,
	[Annual Income_Value] [varchar](50) NULL,
	[Total Cash And Liquid Assets_RiskScore] [int] NULL,
	[Total Cash And Liquid Assets_Value] [varchar](50) NULL,
	[Money plan To invest_RiskScore] [int] NULL,
	[Money plan To invest_Value] [varchar](50) NULL,
	[High Risk_RiskScore] [int] NULL,
	[High Risk_Value] [varchar](50) NULL,
	[Sector ML TF_RiskScore] [int] NULL,
	[Sector ML TF_Value] [varchar](50) NULL,
	[Sector High Cash_RiskScore] [int] NULL,
	[Sector High Cash_Value] [varchar](50) NULL,
	[Net Deposit_RiskScore] [int] NULL,
	[Net Deposit_Value] [varchar](50) NULL,
	[Instruments Planned Investment_RiskScore] [int] NULL,
	[Instruments Planned Investment_Value] [varchar](50) NULL,
	[FTD_RiskScore] [int] NULL,
	[FTD_Value] [varchar](50) NULL,
	[ScoreExpectedOriginFunds_RiskScore] [int] NULL,
	[ScoreExpectedOriginFunds_Value] [varchar](50) NULL,
	[ScoreExpectedDestinationPayments_RiskScore] [int] NULL,
	[ScoreExpectedDestinationPayments_Value] [varchar](50) NULL,
	[SectorHighRisk_RiskScore] [int] NULL,
	[SectorHighRisk_Value] [varchar](50) NULL,
	[Sector_ML_TF_RiskScore] [int] NULL,
	[Sector_ML_TF_Value] [varchar](50) NULL,
	[SectorHighCash_RiskScore] [int] NULL,
	[SectorHighCash_Value] [varchar](50) NULL,
	[EstablishmentApproved_RiskScore] [int] NULL,
	[EstablishmentApproved_Value] [varchar](50) NULL,
	[HighPublicProfile_RiskScore] [int] NULL,
	[HighPublicProfile_Value] [varchar](50) NULL,
	[DisclosureSubjected_RiskScore] [int] NULL,
	[DisclosureSubjected_Value] [varchar](50) NULL,
	[RegionSupervised_RiskScore] [int] NULL,
	[RegionSupervised_Value] [varchar](50) NULL,
	[JurisdictionNonCorrupt_RiskScore] [int] NULL,
	[JurisdictionNonCorrupt_Value] [varchar](50) NULL,
	[AML_CFT_Failure_RiskScore] [int] NULL,
	[AML_CFT_Failure_Value] [varchar](50) NULL,
	[BackgroundConsistent_RiskScore] [int] NULL,
	[BackgroundConsistent_Value] [varchar](50) NULL,
	[TransactionSuspicious_RiskScore] [int] NULL,
	[TransactionSuspicious_Value] [varchar](50) NULL,
	[IdentityEvidence_RiskScore] [int] NULL,
	[IdentityEvidence_Value] [varchar](50) NULL,
	[AvoidBusinessRelations_RiskScore] [int] NULL,
	[AvoidBusinessRelations_Value] [varchar](50) NULL,
	[OwnershipTransparent_RiskScore] [int] NULL,
	[OwnershipTransparent_Value] [varchar](50) NULL,
	[AssetHoldingVehicle_RiskScore] [int] NULL,
	[AssetHoldingVehicle_Value] [varchar](50) NULL,
	[TransactionsUnusual_RiskScore] [int] NULL,
	[TransactionsUnusual_Value] [varchar](50) NULL,
	[SecrecyUnreasonable_RiskScore] [int] NULL,
	[SecrecyUnreasonable_Value] [varchar](50) NULL,
	[NFTF_RiskScore] [int] NULL,
	[NFTF_Value] [varchar](50) NULL,
	[IdentityDoubts_RiskScore] [int] NULL,
	[IdentityDoubts_Value] [varchar](50) NULL,
	[ExpectedProductsUsed_RiskScore] [int] NULL,
	[ExpectedProductsUsed_Value] [varchar](50) NULL,
	[NonProfitOrgAbused_RiskScore] [int] NULL,
	[NonProfitOrgAbused_Value] [varchar](50) NULL,
	[CooperativeClient_RiskScore] [int] NULL,
	[CooperativeClient_Value] [varchar](50) NULL,
	[IdentityAnonymous_RiskScore] [int] NULL,
	[IdentityAnonymous_Value] [varchar](50) NULL,
	[TransactionComplexity_RiskScore] [int] NULL,
	[TransactionComplexity_Value] [varchar](50) NULL,
	[PaymentsThirdParty_RiskScore] [int] NULL,
	[PaymentsThirdParty_Value] [varchar](50) NULL,
	[UpdateDate] [datetime] NULL,
	[Place of Birth_RiskScore] [int] NULL,
	[Place of Birth_Value] [varchar](50) NULL,
	[PreviousRisk] [int] NULL,
	[PreviousRiskUpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[CID] ASC
	)
)

GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
