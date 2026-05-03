# Pre-Resolved Upstream Bundle for `eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.SettlementsTransactions_SecurityChecks-426253.sql`

```sql
CREATE TABLE [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
(
	[@Id] [varchar](40) NULL,
	[@SettlementsTransactions_SettlementTransaction@Id-637239] [varchar](40) NULL,
	[CardExpirationDatePresent] [varchar](max) NULL,
	[OnlinePIN] [varchar](max) NULL,
	[OfflinePIN] [varchar](max) NULL,
	[ThreeDomainSecure] [varchar](max) NULL,
	[Cvv2] [varchar](max) NULL,
	[MagneticStripe] [varchar](max) NULL,
	[ChipData] [varchar](max) NULL,
	[AVS] [varchar](max) NULL,
	[PhoneNumber] [varchar](max) NULL,
	[Signature] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[Created] [datetime2](7) NULL,
	[AccountNames] [varchar](max) NULL,
	[partition_date] [date] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_426253] ON [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_426253_c2] ON [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
(
	[@SettlementsTransactions_SettlementTransaction@Id-637239] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_426253_Id] ON [eMoney_Tribe].[SettlementsTransactions_SecurityChecks-426253]
(
	[@Id] ASC
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
