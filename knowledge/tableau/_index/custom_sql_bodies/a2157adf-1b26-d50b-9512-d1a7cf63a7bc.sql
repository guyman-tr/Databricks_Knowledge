select fm.ActiveDate
      ,c.Gender
	  ,fm.IsPro
	  ,fm.ActiveOpen
	  ,fm.Active
,fm.FirstAction
      ,COUNT(c.CID) Customer
FROM ##cid_tom c
INNER JOIN [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
ON c.CID = fm.CID
where fm.IsFunded_New = 1
and fm.ActiveDate >='20170101'
group by fm.ActiveDate
      ,c.Gender
	  ,fm.IsPro
	  ,fm.ActiveOpen
	  ,fm.Active
,fm.FirstAction