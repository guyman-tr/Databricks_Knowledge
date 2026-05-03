# Pre-Resolved Upstream Bundle for `EXW_Wallet.CryptoTypes`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.CryptoTypes.sql`

```sql
CREATE TABLE [EXW_Wallet].[CryptoTypes]
(
	[CryptoID] [int] NULL,
	[Name] [varchar](max) NULL,
	[MinReqAccounts] [int] NULL,
	[MinUnit] [numeric](18, 0) NULL,
	[Status] [int] NULL,
	[MinReqVerifications] [int] NULL,
	[MaxVerificationTimeMinutes] [bigint] NULL,
	[Occurred] [datetime2](7) NULL,
	[IsActive] [bit] NULL,
	[CryptoActivityStatus] [int] NULL,
	[BalanceAssetName] [varchar](max) NULL,
	[WebHookVerifications] [int] NULL,
	[StartMonitoringDelaySeconds] [int] NULL,
	[BalanceThreshold] [numeric](36, 18) NULL,
	[InitialFeeUnits] [numeric](36, 18) NULL,
	[BlockchainExplorerFormat] [varchar](max) NULL,
	[IsEtoroHandlingFee] [bit] NULL,
	[BlockchainCryptoId] [int] NULL,
	[AssetTypeId] [int] NULL,
	[SymbolFull] [varchar](max) NULL,
	[DisplayName] [varchar](max) NULL,
	[AvatarUrl] [varchar](max) NULL,
	[Precision] [int] NULL,
	[TagName] [varchar](max) NULL,
	[InstrumentId] [int] NULL,
	[AssetBlockchainAddress] [varchar](max) NULL,
	[OrderIndex] [int] NULL,
	[CryptoCategoryName] [varchar](max) NULL,
	[StakingDisplayName] [varchar](max) NULL,
	[StakingAvatarUrl] [varchar](max) NULL,
	[StakingSymbolFull] [varchar](max) NULL,
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
