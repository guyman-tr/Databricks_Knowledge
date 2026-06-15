SELECT dd.FullDate
      ,COUNT(DISTINCT [WithdrawID]) Withdrawals
  FROM [DWH].[dbo].[Fact_BillingWithdraw] bw WITH (NOLOCK)
  INNER JOIN DWH.dbo.Dim_Date dd WITH (NOLOCK)
  ON bw.ModificationDateID = dd.DateKey
  WHERE ModificationDateID >=CONVERT(CHAR(8),DATEADD(MONTH,DATEDIFF(MONTH,0,GETDATE())-6,0),112)	
  GROUP BY dd.FullDate