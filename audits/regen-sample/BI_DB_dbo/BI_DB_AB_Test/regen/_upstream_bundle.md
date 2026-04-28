# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AB_Test`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AB_Test.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AB_Test]
(
	[DateID] [int] NULL,
	[Date] [date] NULL,
	[RealCID] [int] NULL,
	[IsControl] [int] NULL,
	[BI_Owner] [varchar](14) NULL,
	[Business_Owner] [varchar](15) NULL,
	[Name] [varchar](25) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [RealCID] ),
	CLUSTERED INDEX
	(
		[DateID] ASC,
		[Name] ASC
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
