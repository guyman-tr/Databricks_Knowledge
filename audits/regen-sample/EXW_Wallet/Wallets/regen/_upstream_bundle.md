# Pre-Resolved Upstream Bundle for `EXW_Wallet.Wallets`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.Wallets.sql`

```sql
CREATE TABLE [EXW_Wallet].[Wallets]
(
	[Id] [bigint] NULL,
	[WalletId] [uniqueidentifier] NULL,
	[Gcid] [int] NULL,
	[BlockchainCryptoId] [int] NULL,
	[WalletTypeId] [int] NULL,
	[IsActive] [bit] NULL,
	[Occurred] [datetime2](7) NULL,
	[BeginDate] [datetime2](7) NULL,
	[EndDate] [datetime2](7) NULL,
	[IsActivated] [bit] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [WalletId] ),
	HEAP
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
