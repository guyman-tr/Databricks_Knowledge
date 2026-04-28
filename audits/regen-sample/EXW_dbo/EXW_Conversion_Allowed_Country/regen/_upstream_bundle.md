# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_Conversion_Allowed_Country`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_Conversion_Allowed_Country.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_Conversion_Allowed_Country]
(
	[Country] [varchar](50) NULL,
	[CountryID] [int] NULL,
	[StateProvince] [varchar](100) NULL,
	[RegionByIP_ID] [int] NULL,
	[CryptoID] [int] NOT NULL,
	[Crypto] [nvarchar](256) NULL,
	[AllowedUserResource] [nvarchar](100) NULL,
	[AllowedUserTagType] [nvarchar](50) NULL,
	[AllowedUserTagValue] [nvarchar](50) NULL,
	[AllowedUserSelectedValue] [nvarchar](50) NULL,
	[FromResourceName] [nvarchar](100) NULL,
	[FromTagType] [nvarchar](50) NULL,
	[FromTagValue] [nvarchar](50) NULL,
	[FromSelectedValue] [nvarchar](50) NULL,
	[ToResourceName] [nvarchar](100) NULL,
	[ToTagType] [nvarchar](50) NULL,
	[ToTagValue] [nvarchar](50) NULL,
	[ToSelectedValue] [nvarchar](50) NULL,
	[FromConversionAllowed] [int] NULL,
	[ToConversionAllowed] [int] NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [CountryID] ),
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
