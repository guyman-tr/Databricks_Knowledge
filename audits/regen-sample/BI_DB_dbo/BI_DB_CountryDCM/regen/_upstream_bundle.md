# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_CountryDCM`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_CountryDCM.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_CountryDCM]
(
	[Country_DCM] [nvarchar](50) NULL,
	[Country_Affwiz] [nvarchar](50) NULL,
	[MarketingRegionManualName] [nvarchar](50) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[Country_DCM] ASC
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
