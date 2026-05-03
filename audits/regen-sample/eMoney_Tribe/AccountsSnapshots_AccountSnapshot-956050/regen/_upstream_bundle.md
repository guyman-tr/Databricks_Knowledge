# Pre-Resolved Upstream Bundle for `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.AccountsSnapshots_AccountSnapshot-956050.sql`

```sql
CREATE TABLE [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050]
(
	[@Created] [datetime2](7) NULL,
	[@Id] [varchar](255) NULL,
	[@AccountsSnapshots@Id-509416] [varchar](max) NULL,
	[FileDate] [varchar](max) NULL,
	[WorkDate] [varchar](max) NULL,
	[@WorkDate] [datetime2](7) NULL,
	[AccountId] [varchar](max) NULL,
	[HolderId] [varchar](max) NULL,
	[ProgramId] [varchar](max) NULL,
	[CurrencyIson] [varchar](max) NULL,
	[AvailableBalance] [varchar](max) NULL,
	[SettledBalance] [varchar](max) NULL,
	[AccountStatus] [varchar](max) NULL,
	[AccountStatusDescription] [varchar](max) NULL,
	[AccountStatusChangeDate] [varchar](max) NULL,
	[AccountStatusChangeSource] [varchar](max) NULL,
	[AccountStatusChangeReasonCode] [varchar](max) NULL,
	[AccountStatusChangeNote] [varchar](max) NULL,
	[AccountStatusChangeOriginatorId] [varchar](max) NULL,
	[DateUpdated] [varchar](max) NULL,
	[DateCreated] [varchar](max) NULL,
	[BankAccounts] [varchar](max) NULL,
	[ReservedBalance] [varchar](max) NULL,
	[HolderCountryIson] [varchar](max) NULL,
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
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[AccountsSnapshots_AccountSnapshot-956050]
(
	[partition_date] ASC
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
