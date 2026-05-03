# Pre-Resolved Upstream Bundle for `eMoney_Tribe.AccountsSnapshots_BankAccount-393561`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_Tribe.AccountsSnapshots_BankAccount-393561.sql`

```sql
CREATE TABLE [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561]
(
	[@Id] [varchar](255) NULL,
	[@AccountsSnapshots_BankAccounts@Id-795870] [varchar](max) NULL,
	[BankAccountId] [varchar](max) NULL,
	[BankAccountExternalId] [varchar](max) NULL,
	[BankAccountStatus] [varchar](max) NULL,
	[BankAccountBankProviderId] [varchar](max) NULL,
	[BankAccountAccountName] [varchar](max) NULL,
	[BankAccountAccountNumber] [varchar](max) NULL,
	[BankAccountSortCode] [varchar](max) NULL,
	[BankAccountIban] [varchar](max) NULL,
	[BankAccountBic] [varchar](max) NULL,
	[BankAccountStatusChangeReasonCode] [varchar](max) NULL,
	[BankAccountStatusChangeNote] [varchar](max) NULL,
	[BankAccountStatusChangeSource] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL,
	[Created] [datetime2](7) NULL,
	[EpmMethodId] [varchar](max) NULL,
	[partition_date] [date] NULL,
	[BankAccountBankStateBranch] [varchar](max) NULL,
	[BankAccountBankBranchCode] [varchar](max) NULL
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
CREATE NONCLUSTERED INDEX [XI_partition_date] ON [eMoney_Tribe].[AccountsSnapshots_BankAccount-393561]
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
