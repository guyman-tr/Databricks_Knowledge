# Pre-Resolved Upstream Bundle for `EXW_Wallet.FiatTypes`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_Wallet.FiatTypes.sql`

```sql
CREATE TABLE [EXW_Wallet].[FiatTypes]
(
	[Id] [int] NULL,
	[FiatId] [int] NULL,
	[FiatName] [varchar](max) NULL,
	[IsActive] [bit] NULL,
	[AvatarUrl] [varchar](max) NULL,
	[Precision] [int] NULL,
	[InstrumentId] [int] NULL,
	[NumericCode] [int] NULL,
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
