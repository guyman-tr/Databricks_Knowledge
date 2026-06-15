SELECT q.EOM_Action
      ,q.Country
	  ,q.FundingType
	  ,dc.EU
	  ,CAST(q.UpdateDate AS DATE) AS UpdateDate
      ,SUM(CASE WHEN q.Ind = 'MoneyIn' THEN ISNULL(q.AmountUSD, 0) ELSE 0 END) 'AmountUSD_Deposit' 
      ,SUM(CASE WHEN q.Ind = 'MoneyOut' THEN ISNULL(q.AmountUSD, 0) ELSE 0 END) 'AmountUSD_Withdraw' 
      ,SUM(CASE WHEN ISNULL(q.DepositID, 0) > 0 THEN 1 ELSE 0 END) 'Total_Deposit'
      ,SUM(CASE WHEN ISNULL(q.WithdrawID, 0) > 0 THEN 1 ELSE 0 END) 'Total_Withdraw'
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
			  ,a1.UpdateDate
        FROM BI_DB_dbo.BI_DB_Money_In_New_Management_Dashboard a1
		JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr ON a1.CountryID = mdcr.CountryID
        WHERE DepositStatus='Approved'
             
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
			   ,a1.UpdateDate
        FROM BI_DB_dbo.BI_DB_Money_Out_New_Management_Dashboard a1
		INNER JOIN DWH_dbo.Dim_FundingType dft ON a1.FundingTypeID = dft.FundingTypeID
		INNER JOIN eMoney_dbo.eMoney_Dim_Country_Rollout mdcr ON a1.Country = mdcr.CountryName
        WHERE a1.CashoutStatusID_Funding = 3 --'Processed'
             
     )q
JOIN DWH_dbo.Dim_Country dc ON dc.Name=q.Country
GROUP BY q.EOM_Action,q.Country,q.FundingType,q.UpdateDate,dc.EU