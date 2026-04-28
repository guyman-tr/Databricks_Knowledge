# Pre-Resolved Upstream Bundle for `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `eMoney_dbo.eMoney_Currency_Instrument_Mapping_Static.sql`

```sql
CREATE TABLE [eMoney_dbo].[eMoney_Currency_Instrument_Mapping_Static]
(
	[Currency] [varchar](50) NOT NULL,
	[CurrencyISO] [int] NOT NULL,
	[InstrumentID] [int] NOT NULL,
	[InstrumentName] [varchar](50) NOT NULL,
	[DWHInstrumentID] [int] NOT NULL,
	[BuyCurrencyID] [int] NOT NULL,
	[SellCurrencyID] [int] NOT NULL,
	[BuyCurrency] [varchar](50) NOT NULL,
	[SellCurrency] [varchar](50) NOT NULL,
	[UpdateDate] [datetime] NOT NULL
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
