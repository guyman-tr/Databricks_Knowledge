SELECT bdad.ModificationDateID
      ,dd.FullDate
      ,COUNT(*) Deposits
FROM BI_DB.dbo.BI_DB_AllDeposits bdad
INNER JOIN DWH.dbo.Dim_Date dd WITH (NOLOCK)
ON bdad.ModificationDateID = dd.DateKey
where bdad.ModificationDateID >=CONVERT(CHAR(8),DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())-6,0),112)	
GROUP BY  bdad.ModificationDateID
      ,dd.FullDate