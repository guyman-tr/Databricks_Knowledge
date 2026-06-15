SELECT 
		TaskID,
		TaskType,
		v.GCID,
		CID,
		CreateDate,
		Priority,
		TeamID,
		outcome.Name AS Outcome,
		reason.Name AS OutcomeReason,
		v.IsActive,
		BeginTime,
		EndTime,
		Escalation2CY,
		UpdatedByTeamId,
		dc1.Name AS Country,
		dc1.RiskGroupID,
		dm.FirstName + ' ' + dm.LastName AS Manager,
		CASE when[TeamID]='03rdcrjn0z3xt0g' then 'Ukraine' 
		WHEN [TeamID]='03bj1y384jlxbom' then 'China' 
		WHEN [TeamID]='01yyy98l2f0mo1l' then 'USA'
		when [TeamID]='04d34og80lj5f9j' then 'Israel' 
		else 'KYC' END AS Team,
dr.Name as Regulation
FROM [Assignment2].[Assignment].Assignment.V_Tasks v
JOIN DWH.dbo.Dim_Customer dc ON dc.RealCID=v.CID
JOIN DWH.dbo.Dim_Regulation dr ON dr.ID=dc.RegulationID
JOIN DWH.dbo.Dim_Country dc1 ON dc1.CountryID=dc.CountryID
left JOIN DWH.dbo.Dim_Manager dm  ON dm.ManagerID=v.AssigneeID
left join [Assignment2].[Assignment].[Dictionary].[Outcome] outcome  on outcome.OutcomeID=v.OutcomeID
left join [Assignment2].[Assignment].[Dictionary].[OutcomeReason] reason  on reason.OutcomeReasonID=v.OutcomeReasonID
WHERE CreateDate>=DATEFROMPARTS(YEAR(dateadd(month, -1, getdate())), MONTH(dateadd(month, - 1, getdate())), 1)