# Pre-Resolved Upstream Bundle for `BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube.sql`

```sql
CREATE TABLE [BI_DB_dbo].[fiktivo_AffiliateCommission_ClosedPosition_for_Marketing_Cube]
(
	[ClosedPositionID] [bigint] NULL,
	[CommissionDate] [datetime2](7) NULL,
	[Amount] [numeric](16, 6) NULL,
	[HedgeCommission] [numeric](16, 6) NULL,
	[CID] [bigint] NULL,
	[OriginalCID] [bigint] NULL,
	[AffiliateID] [int] NULL,
	[AffiliateCampaign] [varchar](max) NULL,
	[ProviderID] [bigint] NULL,
	[OriginalProviderID] [bigint] NULL,
	[RealProviderID] [bigint] NULL,
	[CountryID] [bigint] NULL,
	[NetProfit] [float] NULL,
	[FunnelID] [int] NULL,
	[LabelID] [int] NULL,
	[PlayerLevelID] [int] NULL,
	[DownloadID] [bigint] NULL,
	[LotCount] [numeric](16, 6) NULL,
	[BannerID] [int] NULL,
	[Valid] [bit] NULL,
	[TrackingDate] [datetime2](7) NULL,
	[IsProcessed] [bit] NULL,
	[ValidFrom] [datetime2](7) NULL,
	[UpdateDate] [datetime2](7) NULL,
	[AdditionalData] [varchar](max) NULL,
	[etr_y] [varchar](max) NULL,
	[etr_ym] [varchar](max) NULL,
	[etr_ymd] [varchar](max) NULL
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
