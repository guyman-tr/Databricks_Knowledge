# Pre-Resolved Upstream Bundle for `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.CardsSnapshots_CardSnapshot-140457.sql`

```sql
CREATE TABLE [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](255) NULL,
	[@CardsSnapshots@Id-890718] [varchar](max) NULL,
	[FileDate] [varchar](max) NULL,
	[WorkDate] [varchar](max) NULL,
	[@WorkDate] [datetime2](7) NULL,
	[IssuerIdentificationNumber] [varchar](max) NULL,
	[ProgramName] [varchar](max) NULL,
	[ProgramId] [varchar](max) NULL,
	[ProductName] [varchar](max) NULL,
	[ProductId] [varchar](max) NULL,
	[SubProductId] [varchar](max) NULL,
	[HolderId] [varchar](max) NULL,
	[CardNumber] [varchar](max) NULL,
	[CardNumberId] [varchar](max) NULL,
	[CardRequestId] [varchar](max) NULL,
	[IsVirtual] [varchar](max) NULL,
	[CardExpirationDate] [varchar](max) NULL,
	[CardCreationDate] [varchar](max) NULL,
	[CardActivationDate] [varchar](max) NULL,
	[CardStatusDate] [varchar](max) NULL,
	[CardStatusCode] [varchar](max) NULL,
	[CardStatusCodeDescription] [varchar](max) NULL,
	[CardStatusChangeSource] [varchar](max) NULL,
	[CardStatusChangeReasonCode] [varchar](max) NULL,
	[CardStatusChangeNote] [varchar](max) NULL,
	[CardStatusChangeOriginatorId] [varchar](max) NULL,
	[LimitsGroupName] [varchar](max) NULL,
	[LimitsGroupId] [varchar](max) NULL,
	[FeeGroupName] [varchar](max) NULL,
	[FeeGroupId] [varchar](max) NULL,
	[UsageGroupName] [varchar](max) NULL,
	[UsageGroupId] [varchar](max) NULL,
	[FirstName] [varchar](max) NULL,
	[LastName] [varchar](max) NULL,
	[Address] [varchar](max) NULL,
	[City] [varchar](max) NULL,
	[State] [varchar](max) NULL,
	[ZipCode] [varchar](max) NULL,
	[CountryCode] [varchar](max) NULL,
	[CountryCodeAlpha] [varchar](max) NULL,
	[CountryName] [varchar](max) NULL,
	[Dob] [varchar](max) NULL,
	[EmailAddress] [varchar](max) NULL,
	[PhoneNumber] [varchar](max) NULL,
	[PhoneNumberCountryCode] [varchar](max) NULL,
	[ApplicationIpAddress] [varchar](max) NULL,
	[KycVerification] [varchar](max) NULL,
	[CardEvent] [varchar](max) NULL,
	[DefaultCardCurrency] [varchar](max) NULL,
	[Network] [varchar](max) NULL,
	[DeliveryTitle] [varchar](max) NULL,
	[DeliveryFirstName] [varchar](max) NULL,
	[DeliveryLastName] [varchar](max) NULL,
	[DeliveryAddress] [varchar](max) NULL,
	[DeliveryCity] [varchar](max) NULL,
	[DeliveryState] [varchar](max) NULL,
	[DeliveryZipCode] [varchar](max) NULL,
	[DeliveryCountryCode] [varchar](max) NULL,
	[DeliveryCountryName] [varchar](max) NULL,
	[ActiveWallet] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[partition_date] [date] NULL,
	[Created] [datetime2](7) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [@Id] ),
	CLUSTERED INDEX
	(
		[@Id] ASC
	)
)

GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [idx_140457_created] ON [eMoney_Tribe].[CardsSnapshots_CardSnapshot-140457]
(
	[@Created] ASC
)WITH (DROP_EXISTING = OFF)
GO

```

---

## Upstream Wikis Found

**NO UPSTREAM WIKI** was resolvable for any source listed in the lineage. Use the DDL above and the writer SP source below (if any) to ground every column description.


---

## Resolution Summary

| Raw source | Kind | Schema | Object | Resolved path |
|---|---|---|---|---|
