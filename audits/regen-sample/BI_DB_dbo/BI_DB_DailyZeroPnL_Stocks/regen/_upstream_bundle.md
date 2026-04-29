# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_DailyZeroPnL_Stocks.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_DailyZeroPnL_Stocks]
(
	[Date] [date] NULL,
	[HedgeServerID] [int] NULL,
	[Industry] [varchar](250) NULL,
	[InstrumentType] [varchar](50) NULL,
	[InstrumentID] [int] NULL,
	[InstrumentDisplayName] [varchar](250) NULL,
	[StockIndex] [varchar](50) NULL,
	[IsManual] [tinyint] NULL,
	[Leverage] [int] NULL,
	[IsCFD] [tinyint] NULL,
	[Regulation] [varchar](50) NULL,
	[MifID] [int] NULL,
	[RealizedCommission] [money] NULL,
	[RealizedZero] [money] NULL,
	[ChangeInUnrealizedZero] [money] NULL,
	[TotalZero] [money] NULL,
	[NOP] [money] NULL,
	[OpenPositions] [money] NULL,
	[NOP_Units] [numeric](38, 6) NULL,
	[VolumeOnOpen] [bigint] NULL,
	[VolumeOnClose] [bigint] NULL,
	[OpenPositionValue] [money] NULL,
	[UpdateDate] [datetime] NULL,
	[InstrumentName] [varchar](100) NULL,
	[Units] [decimal](16, 6) NULL,
	[Currency] [varchar](50) NULL
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
