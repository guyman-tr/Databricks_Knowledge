# Pre-Resolved Upstream Bundle for `BI_DB_dbo.BI_DB_SF_Cases_Panel`

This bundle was assembled deterministically by the regen harness BEFORE the writer claude process started. Use this as your AUTHORITATIVE Tier 1 inheritance source. Quote descriptions VERBATIM from the upstream wikis below for any column that is a passthrough or rename of an upstream column. Do NOT paraphrase. Do NOT generalize vendor names. Do NOT drop NULL semantics.

---

## Source DDL — `BI_DB_dbo.BI_DB_SF_Cases_Panel.sql`

```sql
CREATE TABLE [BI_DB_dbo].[BI_DB_SF_Cases_Panel]
(
	[CreatedDate] [datetime] NULL,
	[LastStatusDate] [datetime] NULL,
	[TicketStatus] [nvarchar](255) NULL,
	[CaseNumber] [int] NULL,
	[TicketID] [nvarchar](18) NULL,
	[HistoryID_AtOpen] [nvarchar](18) NULL,
	[IsVisitor_Atopen] [int] NOT NULL,
	[DepositorType_AtOpen] [varchar](4) NULL,
	[Regulation_AtOpen] [nvarchar](1300) NULL,
	[ClubTier_AtOpen] [varchar](50) NULL,
	[Role_AtOpen] [nvarchar](255) NULL,
	[SubRole_AtOpen] [nvarchar](1300) NULL,
	[ServiceLanguage_AtOpen] [nvarchar](255) NULL,
	[ServiceDesk_AtOpen] [nvarchar](1300) NULL,
	[Phase_AtOpen] [nvarchar](255) NULL,
	[Source_AtOpen] [nvarchar](255) NULL,
	[Priority_AtOpen] [nvarchar](40) NULL,
	[Product_AtOpen] [nvarchar](255) NULL,
	[Type_AtOpen] [nvarchar](255) NULL,
	[ActionType_AtOpen] [nvarchar](255) NULL,
	[SubType_AtOpen] [nvarchar](255) NULL,
	[SubType2_AtOpen] [nvarchar](255) NULL,
	[Country_AtOpen] [varchar](50) NULL,
	[PlayerStatus_AtOpen] [varchar](50) NULL,
	[AccountManagerID_AtOpen] [int] NULL,
	[ActiveAgentID_Atopen] [nvarchar](18) NULL,
	[Owner_Atopen] [nvarchar](50) NULL,
	[CID_Last] [int] NULL,
	[HistoryID_Last] [nvarchar](18) NULL,
	[IsVisitor_Last] [int] NULL,
	[DepositorType_Last] [varchar](4) NULL,
	[Regulation_Last] [varchar](50) NULL,
	[ClubTier_Last] [varchar](50) NULL,
	[Role_Last] [nvarchar](255) NULL,
	[SubRole_Last] [nvarchar](1300) NULL,
	[ServiceLanguage_Last] [nvarchar](255) NULL,
	[ServiceDesk_Last] [nvarchar](1300) NULL,
	[Phase_Last] [nvarchar](255) NULL,
	[Source_Last] [nvarchar](255) NULL,
	[Priority_Last] [nvarchar](40) NULL,
	[Product_Last] [nvarchar](255) NULL,
	[Type_Last] [nvarchar](255) NULL,
	[ActionType_Last] [nvarchar](255) NULL,
	[SubType_Last] [nvarchar](255) NULL,
	[SubType2_Last] [nvarchar](255) NULL,
	[Country_Last] [varchar](50) NULL,
	[PlayerStatus_Last] [varchar](50) NULL,
	[AccountManagerID_Last] [int] NULL,
	[ActiveAgentID_Last] [nvarchar](18) NULL,
	[Owner_Last] [nvarchar](50) NULL,
	[FirstCSAT] [int] NULL,
	[LastCSAT] [int] NULL,
	[IsSupervisorCall] [bit] NULL,
	[IsT3] [bit] NULL,
	[IsTechnicalTeam] [bit] NULL,
	[IsPPReport] [bit] NULL,
	[IsTmail] [bit] NULL,
	[IsCOCall] [bit] NULL,
	[IsCHBCase] [bit] NULL,
	[IsCOCase] [bit] NULL,
	[IsRisk] [bit] NULL,
	[IsOfficial] [bit] NULL,
	[IsSpam] [bit] NULL,
	[IsReopened] [bit] NULL,
	[IsInternal] [bit] NULL,
	[IsKYcMonitoring] [bit] NULL,
	[IsTechnicalRefund] [numeric](18, 0) NULL,
	[IsSocial] [bit] NULL,
	[IsGoodwill] [numeric](18, 0) NULL,
	[IsOneTouch] [bit] NULL,
	[NumberOfTocuhes] [numeric](18, 0) NULL,
	[FirstResponse] [datetime2](7) NULL,
	[TotalTimeSpent] [numeric](18, 0) NULL,
	[NumberIncomingMessages] [numeric](18, 0) NULL,
	[NumberOutgoingMessages] [numeric](18, 0) NULL,
	[UpdateDate] [datetime] NOT NULL,
	[CloseDateTime] [datetime] NULL,
	[IsNormal] [int] NULL,
	[IsComplaint] [int] NULL,
	[IsPhase2] [int] NULL,
	[IsPhase3] [int] NULL,
	[VerificationLevelID_AtOpen] [int] NULL,
	[VerificationLevelID_Last] [int] NULL
)
WITH
(
	DISTRIBUTION = ROUND_ROBIN,
	CLUSTERED INDEX
	(
		[CaseNumber] ASC
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
