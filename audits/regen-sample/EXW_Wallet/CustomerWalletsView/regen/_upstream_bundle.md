# Pre-Resolved Upstream Bundle for `EXW_Wallet.CustomerWalletsView`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.CustomerWalletsView.sql`

```sql
CREATE TABLE [EXW_Wallet].[CustomerWalletsView]
(
	[Id] [uniqueidentifier] NULL,
	[Gcid] [int] NULL,
	[CryptoId] [int] NULL,
	[Address] [varchar](max) NULL,
	[BlockchainProviderWalletId] [varchar](max) NULL,
	[Occurred] [datetime2](7) NULL,
	[WalletTypeId] [int] NULL,
	[IsActive] [bit] NULL,
	[Status] [int] NULL,
	[WalletRecordId] [bigint] NULL,
	[BlockchainCryptoId] [int] NULL,
	[WalletProviderId] [int] NULL,
	[IsActivated] [bit] NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL,
	[SynapseUpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
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
