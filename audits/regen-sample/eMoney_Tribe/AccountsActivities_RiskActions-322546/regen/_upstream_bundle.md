# Pre-Resolved Upstream Bundle for `eMoney_Tribe.AccountsActivities_RiskActions-322546`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.AccountsActivities_RiskActions-322546.sql`

```sql
CREATE TABLE [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
(
	[@Id] [varchar](40) NULL,
	[@AccountsActivities_AccountActivity@Id-833937] [varchar](40) NULL,
	[MarkTransactionAsSuspicious] [varchar](max) NULL,
	[NotifyCardholderBySendingTAIsNotification] [varchar](max) NULL,
	[ChangeCardStatusToRisk] [varchar](max) NULL,
	[ChangeAccountStatusToSuspended] [varchar](max) NULL,
	[RejectTransaction] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[Created] [datetime2](7) NULL,
	[partition_date] [date] NULL,
	[ChangeAccountStatusToReceiveOnly] [varchar](max) NULL,
	[ChangeAccountStatusToSpendOnly] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [@Id] ),
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_AA_322546_Id] ON [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_AA_322546_c2] ON [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
(
	[@AccountsActivities_AccountActivity@Id-833937] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_322546_Id] ON [eMoney_Tribe].[AccountsActivities_RiskActions-322546]
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
