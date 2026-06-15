SELECT
distinct bdramt.AlertID,
bdramt.CID,
bdramt.Assignee,
bdramt.ModifiedBy,
bdramt.Comment,
bdramt.CreationDate,
bdramt.ModificationDate,
bdramt.TicketID,
bdramt.FundingID,
f.Name as FundingType,
bdramt.ResourceType,
bdramt.FollowUpDate,
bdramt.AlertType,
bdramt.AlertTypeDescription,
bdramt.CategoryName,
bdramt.TriggerType,
bdramt.StatusType,
bdramt.StatusReason,
bdramt.[Alert Status Reason],
bdramt.Tables,
bdramt.RN,
bdramt.RN1,
dm.FirstName + ' ' + dm.LastName AS Agent,
country.Name as Country,
r.Name as Regulation,
pl.Name as Club,
ps.Name as PlayerStatus,
c.FirstName,
c.LastName,
c.Email,
c.UserName,
c.VerificationLevelID
--,
--op.GCID, 
--op.OptionsApexID ,
--CASE WHEN op.OptionsStatusID=3 THEN 'HasOptionsAccount' ELSE 'NoOptionsAccount' END AS 'OptionsAccount'

FROM [BI_DB_dbo].[BI_DB_RiskAlertManagementTool] bdramt
LEFT JOIN DWH_dbo.Dim_Manager dm ON dm.ManagerID=bdramt.ModifiedBy
LEFT JOIN DWH_dbo.Dim_Customer c ON c.RealCID= bdramt.CID
LEFT JOIN DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=c.PlayerStatusID
left join DWH_dbo.Dim_PlayerLevel pl on pl.PlayerLevelID=c.PlayerLevelID
LEFT JOIN DWH_dbo.Dim_Country country ON country.CountryID=c.CountryID
LEFT JOIN DWH_dbo.Dim_Regulation r on r.ID=c.RegulationID
LEFT JOIN DWH_dbo.Dim_FundingType f on f.FundingTypeID = bdramt.FundingTypeId
--LEFT JOIN [USABroker].[USABroker].[Apex].[Options] op ON op.GCID=c.GCID and op.OptionsStatusID=3--Approved
	WHERE  bdramt.CreationDate>='20240101'
and r.Name = 'FSA Seychelles'