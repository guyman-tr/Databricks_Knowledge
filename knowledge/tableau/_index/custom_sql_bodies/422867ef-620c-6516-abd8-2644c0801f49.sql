SELECT fm.ActiveDate
      ,SUM(fm.IsFunded_New) FundedUsers
      ,SUM(fm.Active) ActiveUsers
     --,SUM(fm.Active_Copy)ActiveCopy
FROM [BI_DB_dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
WHERE fm.ActiveDate >= '20220101'
group by fm.ActiveDate