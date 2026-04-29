# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AffData`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AffData.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AffData]
(
	[RealCID] [int] NOT NULL,
	[AffiliateID] [int] NOT NULL,
	[Aff_Registration] [datetime] NULL,
	[Aff_LoginName] [nvarchar](50) NULL,
	[Aff_Email] [varchar](50) MASKED WITH (FUNCTION = 'default()') NULL,
	[ContractName] [varchar](100) NULL,
	[ContractType] [varchar](20) NULL,
	[Aff_eLanguage] [nvarchar](255) NULL,
	[AffGroup] [nvarchar](50) NULL,
	[Channel] [varchar](50) NOT NULL,
	[UpdateDate] [datetime] NULL,
 CONSTRAINT [PK_BI_DB_AffData] PRIMARY KEY NONCLUSTERED 
	(
		[RealCID] ASC,
		[AffiliateID] ASC
	) NOT ENFORCED 
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
