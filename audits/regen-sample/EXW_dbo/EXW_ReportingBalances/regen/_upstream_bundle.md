# Pre-Resolved Upstream Bundle for `EXW_dbo.EXW_ReportingBalances`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `EXW_dbo.EXW_ReportingBalances.sql`

```sql
CREATE TABLE [EXW_dbo].[EXW_ReportingBalances]
(
	[ReportingDate] [date] NOT NULL,
	[eToro Unique ID 1 GCID] [bigint] NOT NULL,
	[eToro Unique ID 2 CID] [bigint] NOT NULL,
	[eToro Wallet Identifier] [uniqueidentifier] NULL,
	[Public Wallet Address] [nvarchar](100) NULL,
	[Cryptoasset] [nvarchar](256) NULL,
	[Opening Balance as of the 1st of Designated Month] [numeric](38, 8) NULL,
	[Prior Month Closing Balance Date] [datetime] NULL,
	[LTD Units Recieved] [numeric](38, 8) NULL,
	[LTD Units Sent] [numeric](38, 8) NULL,
	[Closing Units Balance] [numeric](38, 8) NULL,
	[Closing Balance USD] [numeric](38, 8) NULL,
	[Reporting Balance] [numeric](38, 8) NULL,
	[Reporting Balance USD] [numeric](38, 6) NULL,
	[DevReportBalancesTime] [datetime2](7) NULL,
	[DevReportBalance For 'KnownIssueWallets'] [decimal](20, 8) NULL,
	[DevReportBalanceUSD For 'KnownIssueWallets'] [decimal](38, 6) NULL,
	[ Closing Balance Date] [datetime] NULL,
	[Country] [varchar](100) NULL,
	[Regulation] [varchar](100) NULL,
	[Test accounting classifier] [bigint] NULL,
	[MTD Units Sent] [numeric](38, 8) NULL,
	[MTD Units Recieved] [numeric](38, 8) NULL,
	[MTD Units Total] [numeric](38, 8) NULL,
	[MTD Balance Change] [numeric](38, 8) NULL,
	[MTD Balance Change -MTD Units Total Flag] [varchar](1) NULL,
	[MTD Balance Change -MTD Units Total] [numeric](38, 8) NULL,
	[Gap in USD -Estimation] [numeric](38, 6) NULL,
	[TrackerBalance] [numeric](38, 8) NULL,
	[TrackerBalanceUSD] [numeric](38, 8) NULL,
	[Has Dif with TrackerBalance] [varchar](1) NULL,
	[Dif with TrackerBalance] [numeric](38, 8) NULL,
	[KnownIssueWallet] [int] NOT NULL,
	[Most Recent Occured Date] [datetime] NULL,
	[UserWalletAllowance] [nchar](50) NULL,
	[Closed Country AND Regulation] [varchar](2) NOT NULL,
	[User was Compensated during Country Closure] [varchar](2) NOT NULL,
	[Staking Units] [decimal](38, 18) NULL,
	[Staking USD] [decimal](38, 6) NULL,
	[UpdateDate] [datetime] NULL
)
WITH
(
	DISTRIBUTION = HASH ( [eToro Unique ID 1 GCID] ),
	CLUSTERED INDEX
	(
		[ReportingDate] ASC
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
