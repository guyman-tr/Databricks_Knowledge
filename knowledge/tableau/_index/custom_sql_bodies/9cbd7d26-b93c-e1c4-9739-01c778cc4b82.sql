SELECT fm.*,dc.Gender,(CONVERT(int,CONVERT(char(8),getdate(),112))-CONVERT(char(8),[BirthDate],112))/10000 Age
FROM [BI_DB].[dbo].[BI_DB_CID_MonthlyPanel_FullData] fm WITH (NOLOCK)
INNER JOIN [DWH].[dbo].[Dim_Customer] dc WITH (NOLOCK)
ON fm.CID = dc.RealCID
WHERE fm.ActiveDate >= '20220101'
AND dc.IsValidCustomer = 1
AND dc.Gender IN ('F','M')