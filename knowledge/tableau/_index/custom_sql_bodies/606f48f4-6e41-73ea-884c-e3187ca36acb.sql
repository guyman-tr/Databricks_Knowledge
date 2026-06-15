SELECT q.EOM_Action
      ,q.Country
      ,q.CID
	  ,q.FundingType
      ,SUM(CASE WHEN q.Ind = 'MoneyIn' THEN ISNULL(q.AmountUSD, 0) ELSE 0 END) 'AmountUSD_Deposit' 
      ,SUM(CASE WHEN q.Ind = 'MoneyOut' THEN ISNULL(q.AmountUSD, 0) ELSE 0 END) 'AmountUSD_Withdraw' 
      ,SUM(CASE WHEN ISNULL(q.DepositID, 0) > 0 THEN 1 ELSE 0 END) 'Total_Deposit'
      ,SUM(CASE WHEN ISNULL(q.WithdrawID, 0) > 0 THEN 1 ELSE 0 END) 'Total_Withdraw'
      ,q.IsFTD
--INTO #temp
FROM (

        SELECT EOMONTH(a1.DepositDate) 'EOM_Action',
               a1.Country,
               'MoneyIn' AS 'Ind',
               a1.CID,
			   a1.DepositMethod AS 'FundingType',
               a1.AmountUSD,
               a1.DepositID,
               0 as 'WithdrawID',
               a1.IsFTD
        FROM BI_DB.dbo.BI_DB_Money_In_New_Management_Dashboard a1
        WHERE DepositStatus='Approved'
             AND a1.Country IN ('United States','Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates') 

         UNION ALL 

        SELECT EOMONTH(a1.RequestDate) 'EOM_Action',
               a1.Country,
               'MoneyOut' Ind,
               a1.CID,
			   dft.Name AS 'FundingType',
               a1.Amount$Withdraw 'AmountUSD',
               0 AS 'DepositID',
               a1.WithdrawID,
               '-1' AS 'IsFTD'
        FROM BI_DB.dbo.BI_DB_Money_Out_New_Management_Dashboard a1
		INNER JOIN DWH..Dim_FundingType dft ON a1.FundingTypeID = dft.FundingTypeID
        WHERE a1.CashoutStatusID_Funding = 3 --'Processed'
              AND a1.Country IN ('United States','Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates')

     )q

GROUP BY q.EOM_Action,q.Country,q.CID,q.FundingType,q.IsFTD