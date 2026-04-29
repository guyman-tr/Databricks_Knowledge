# Pre-Resolved Upstream Bundle for `DWH_dbo.Dim_ContractType`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `DWH_dbo.Dim_ContractType.sql`

```sql
CREATE TABLE [DWH_dbo].[Dim_ContractType]
(
	[ContractTypeID] [int] NULL,
	[Name] [varchar](20) NULL,
	[InsertDate] [datetime] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = REPLICATE,
	CLUSTERED INDEX
	(
		[ContractTypeID] ASC
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
| `dwh.gold_sql_dp_prod_we_dwh_dbo_dim_contracttype` | unresolved | dwh | gold_sql_dp_prod_we_dwh_dbo_dim_contracttype | `—` |
