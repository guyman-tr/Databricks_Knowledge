# Pre-Resolved Upstream Bundle for `BI_DB_dbo.Rev_Cluster_Dict`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.Rev_Cluster_Dict.sql`

```sql
CREATE TABLE [BI_DB_dbo].[Rev_Cluster_Dict]
(
	[Age_On_Reg_grouped_Index] [tinyint] NOT NULL,
	[max_33_35_Index] [tinyint] NOT NULL,
	[Q11_AnswerText_grouped_Index] [tinyint] NOT NULL,
	[Age_On_Reg_grouped] [nvarchar](50) NOT NULL,
	[Q11_AnswerText_grouped] [nvarchar](50) NOT NULL,
	[max_33_35] [nvarchar](50) NOT NULL,
	[Combined_Answer_clustered] [tinyint] NOT NULL,
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
