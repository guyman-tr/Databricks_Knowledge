# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_SpreadedPriceCandle60MinSplitted.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_SpreadedPriceCandle60MinSplitted]
(
	[ProviderID] [int] NOT NULL,
	[InstrumentID] [int] NOT NULL,
	[DateFrom] [datetime] NOT NULL,
	[DateTo] [datetime] NOT NULL,
	[AskFirst] [numeric](16, 8) NULL,
	[AskLast] [numeric](16, 8) NULL,
	[AskMin] [numeric](16, 8) NULL,
	[AskMax] [numeric](16, 8) NULL,
	[BidFirst] [numeric](16, 8) NULL,
	[BidLast] [numeric](16, 8) NULL,
	[BidMin] [numeric](16, 8) NULL,
	[BidMax] [numeric](16, 8) NULL,
	[AskFirstOccurred] [datetime] NULL,
	[AskLastOccurred] [datetime] NULL,
	[AskMinOccurred] [datetime] NULL,
	[AskMaxOccurred] [datetime] NULL,
	[BidFirstOccurred] [datetime] NULL,
	[BidLastOccurred] [datetime] NULL,
	[BidMinOccurred] [datetime] NULL,
	[BidMaxOccurred] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[DateFrom] ASC,
		[DateTo] ASC,
		[ProviderID] ASC,
		[InstrumentID] ASC
	)
)

GO
CREATE NONCLUSTERED INDEX [IX_BI_DB_SpreadedPriceCandle60MinSplitted] ON [BI_DB_dbo].[BI_DB_SpreadedPriceCandle60MinSplitted]
(
	[InstrumentID] ASC,
	[DateFrom] ASC
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
