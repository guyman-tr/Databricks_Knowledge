# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_AppFlyer_Reports_Ext.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_AppFlyer_Reports_Ext]
(
	[AttributedTouchType] [varchar](4000) NULL,
	[AttributedTouchTime] [varchar](4000) NULL,
	[InstallTime] [varchar](4000) NULL,
	[EventTime] [varchar](4000) NULL,
	[EventName] [varchar](4000) NULL,
	[EventValue] [varchar](4000) NULL,
	[EventRevenue] [varchar](4000) NULL,
	[EventRevenueCurrency] [varchar](4000) NULL,
	[EventRevenueUSD] [varchar](4000) NULL,
	[EventSource] [varchar](4000) NULL,
	[IsReceiptValidated] [varchar](4000) MASKED WITH (FUNCTION = 'default()') NULL,
	[Partner] [varchar](4000) NULL,
	[MediaSource] [varchar](4000) NULL,
	[Channel] [varchar](4000) NULL,
	[Keywords] [varchar](4000) NULL,
	[Campaign] [varchar](4000) NULL,
	[CampaignID] [varchar](4000) NULL,
	[Adset] [varchar](4000) NULL,
	[AdsetID] [varchar](4000) NULL,
	[Ad] [varchar](4000) NULL,
	[AdID] [varchar](4000) NULL,
	[AdType] [varchar](4000) NULL,
	[SiteID] [varchar](4000) NULL,
	[SubSiteID] [varchar](4000) NULL,
	[SubParam1] [varchar](4000) NULL,
	[SubParam2] [varchar](4000) NULL,
	[SubParam3] [varchar](4000) NULL,
	[SubParam4] [varchar](4000) NULL,
	[SubParam5] [varchar](4000) NULL,
	[CostModel] [varchar](4000) NULL,
	[CostValue] [varchar](4000) NULL,
	[CostCurrency] [varchar](4000) NULL,
	[Contributor1Partner] [varchar](4000) NULL,
	[Contributor1MediaSource] [varchar](4000) NULL,
	[Contributor1Campaign] [varchar](4000) NULL,
	[Contributor1TouchType] [varchar](4000) NULL,
	[Contributor1TouchTime] [varchar](4000) NULL,
	[Contributor2Partner] [varchar](4000) NULL,
	[Contributor2MediaSource] [varchar](4000) NULL,
	[Contributor2Campaign] [varchar](4000) NULL,
	[Contributor2TouchType] [varchar](4000) NULL,
	[Contributor2TouchTime] [varchar](4000) NULL,
	[Contributor3Partner] [varchar](4000) NULL,
	[Contributor3MediaSource] [varchar](4000) NULL,
	[Contributor3Campaign] [varchar](4000) NULL,
	[Contributor3TouchType] [varchar](4000) NULL,
	[Contributor3TouchTime] [varchar](4000) NULL,
	[Region] [varchar](4000) NULL,
	[CountryCode] [varchar](4000) NULL,
	[State] [varchar](4000) NULL,
	[City] [varchar](4000) MASKED WITH (FUNCTION = 'default()') NULL,
	[PostalCode] [varchar](4000) NULL,
	[DMA] [varchar](4000) NULL,
	[IP] [varchar](500) NULL,
	[WIFI] [varchar](4000) NULL,
	[Operator] [varchar](4000) NULL,
	[Carrier] [varchar](4000) NULL,
	[Language] [varchar](4000) NULL,
	[AppsFlyerID] [varchar](4000) NULL,
	[AdvertisingID] [varchar](4000) NULL,
	[IDFA] [varchar](4000) NULL,
	[AndroidID] [varchar](4000) NULL,
	[CustomerUserID] [varchar](4000) NULL,
	[IMEI] [varchar](4000) NULL,
	[IDFV] [varchar](4000) NULL,
	[Platform] [varchar](4000) NULL,
	[DeviceType] [varchar](4000) NULL,
	[OSVersion] [varchar](4000) NULL,
	[AppVersion] [varchar](4000) NULL,
	[SDKVersion] [varchar](4000) NULL,
	[AppID] [varchar](4000) NULL,
	[AppName] [varchar](4000) NULL,
	[BundleID] [varchar](4000) NULL,
	[AttributionLookback] [varchar](4000) NULL,
	[ReengagementWindow] [varchar](4000) NULL,
	[IsPrimaryAttribution] [varchar](4000) NULL,
	[UserAgent] [varchar](4000) NULL,
	[HTTPReferrer] [varchar](4000) NULL,
	[OriginalURL] [varchar](4000) NULL,
	[IsRetargeting] [varchar](4000) NULL,
	[RetargetingConversionType] [varchar](4000) NULL,
	[DateID] [int] NULL,
	[Date] [datetime] NULL,
	[EtoroAppID] [varchar](500) NULL,
	[EtoroAppName] [varchar](500) NULL,
	[EtoroReport] [varchar](500) NULL
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
