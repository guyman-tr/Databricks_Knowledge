# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_Payment_Allowed_Country`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_Payment_Allowed_Country.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_Payment_Allowed_Country]
(
	[CountryID] [int] NOT NULL,
	[Country] [varchar](50) NULL,
	[StateProvince] [varchar](100) NULL,
	[RegionByIP_ID] [int] NULL,
	[CryptoID] [int] NULL,
	[Crypto] [nvarchar](256) NULL,
	[AllowedUserResource] [nvarchar](100) NULL,
	[AllowedUserTagType] [nvarchar](50) NULL,
	[AllowedUserTagValue] [nvarchar](50) NULL,
	[AllowedUserSelectedValue] [nvarchar](50) NULL,
	[CryptosResourceName] [nvarchar](100) NULL,
	[CryptosTagType] [nvarchar](50) NULL,
	[CryptosTagValue] [nvarchar](50) NULL,
	[CryptosSelectedValue] [nvarchar](50) NULL,
	[PaymentAllowed] [int] NULL,
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
