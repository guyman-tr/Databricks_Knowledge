select fm.ActiveDate
      ,c.Gender
      ,COUNT(c.CID) Customer
FROM ##cid_tom c
INNER JOIN [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
ON c.CID = fm.CID
where fm.IsFunded_New = 1
group by fm.ActiveDate
      ,Gender
	  ,fm.IsFunded_New