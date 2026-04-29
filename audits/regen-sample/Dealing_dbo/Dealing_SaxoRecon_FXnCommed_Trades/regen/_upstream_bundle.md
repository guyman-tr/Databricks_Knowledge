# Pre-Resolved Upstream Bundle for `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `Dealing_dbo.Dealing_SaxoRecon_FXnCommed_Trades.sql`

```sql
CREATE TABLE [Dealing_dbo].[Dealing_SaxoRecon_FXnCommed_Trades]
(
	[Date] [date] NULL,
	[InstrumentID] [int] NULL,
	[InstrumentDisplayName] [nvarchar](100) NULL,
	[ISINCode] [nvarchar](30) NULL,
	[Side] [varchar](100) NULL,
	[HedgeServerID] [int] NULL,
	[SAXO_Units] [decimal](16, 6) NULL,
	[eToro_Units] [decimal](16, 6) NULL,
	[Clients_Units] [decimal](16, 6) NULL,
	[SAXO-eToro_Units] [decimal](16, 6) NULL,
	[SAXO-Clients_Units] [decimal](16, 6) NULL,
	[SAXO_Rate] [decimal](16, 6) NULL,
	[eToro_Rate] [decimal](16, 6) NULL,
	[SAXO-eToro_Rate] [decimal](16, 6) NULL,
	[SAXO_LocalAmount] [money] NULL,
	[SAXO_AmountUSD] [money] NULL,
	[eToro_AmountUSD] [money] NULL,
	[Clients_AmountUSD] [money] NULL,
	[SAXO-eToro_AmountUSD] [money] NULL,
	[SAXO-Clients_AmountUSD] [money] NULL,
	[Commission] [money] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Date] ASC
	)
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
