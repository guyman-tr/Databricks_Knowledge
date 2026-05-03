# Pre-Resolved Upstream Bundle for `eMoney_Tribe.CardsSnapshots_BankAccount-341626`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.CardsSnapshots_BankAccount-341626.sql`

```sql
CREATE TABLE [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
(
	[@Id] [varchar](max) NULL,
	[@CardsSnapshots_BankAccounts@Id-83854] [varchar](255) NULL,
	[BankAccountNumber] [varchar](max) NULL,
	[BankAccountSortCode] [varchar](max) NULL,
	[BankAccountIban] [varchar](max) NULL,
	[BankAccountBic] [varchar](max) NULL,
	[BankAccountStatus] [varchar](max) NULL,
	[BankAccountDirectDebitsIn] [varchar](max) NULL,
	[BankAccountDirectDebitsOut] [varchar](max) NULL,
	[BankAccountInstantPaymentsIn] [varchar](max) NULL,
	[BankAccountInstantPaymentsOut] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[Created] [datetime2](7) NULL,
	[partition_date] [date] NULL,
	[BankAccountBankStateBranch] [varchar](max) NULL,
	[BankAccountBankBranchCode] [varchar](max) NULL
)
WITH
(
	DISTRIBUTION = HASH ( [@CardsSnapshots_BankAccounts@Id-83854] ),
	HEAP
)

GO
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
(
	[partition_date] ASC
)WITH (DROP_EXISTING = OFF)
GO
SET ANSI_PADDING ON

GO
CREATE NONCLUSTERED INDEX [idx_341626_Id] ON [eMoney_Tribe].[CardsSnapshots_BankAccount-341626]
(
	[@CardsSnapshots_BankAccounts@Id-83854] ASC
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
