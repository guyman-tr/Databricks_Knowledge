# Pre-Resolved Upstream Bundle for `eMoney_Tribe.SettlementsTransactions_RiskActions-236807`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.SettlementsTransactions_RiskActions-236807.sql`

```sql
CREATE TABLE [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
(
	[@Id] [varchar](40) NULL,
	[@SettlementsTransactions_SettlementTransaction@Id-637239] [varchar](40) NULL,
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
	DISTRIBUTION = REPLICATE,
	HEAP
)

GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_236807] ON [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
(
	[@Id] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [ClusteredIndex_ST_236807_c2] ON [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
(
	[@SettlementsTransactions_SettlementTransaction@Id-637239] ASC
)WITH (DROP_EXISTING = OFF)
GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_236807_Id] ON [eMoney_Tribe].[SettlementsTransactions_RiskActions-236807]
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
