SELECT * FROM 	
(
	 SELECT a1.EOM,
	a1.CID,
	a1.Country,
	'MoneyOut' AS Category,
	'MoneyOut' AS 'TxType',
	CASE WHEN a1.PayoneerInd+a1.[Other MOP Ind]=1 AND a1.PayoneerInd=1 THEN 'Only Payoneer'
		 WHEN  a1.PayoneerInd+a1.[Other MOP Ind]=1 AND a1.[Other MOP Ind]=1 THEN 'Only Other MOP'
		 ELSE 'Both Payoneer and Other MOP' END AS 'ClientType',
    CASE WHEN a1.PayPalInd+a1.[Other MOP Ind_PayPal]=1 AND a1.PayPalInd=1 THEN 'Only PayPal'
    WHEN  a1.PayPalInd+a1.[Other MOP Ind_PayPal]=1 AND a1.[Other MOP Ind_PayPal]=1 THEN 'Only Other MOP'
    ELSE 'Both PayPal and Other MOP' END AS 'ClientType_PayPal'
	from
		(SELECT 
		 EOMONTH(bdmonmd.RequestDate) 'EOM',
		 bdmonmd.CID,
		 bdmonmd.Country,
		 MAX(CASE WHEN bdmonmd.FundingType='Payoneer'  THEN 1 ELSE 0 END) 'PayoneerInd',
		 MAX(CASE WHEN bdmonmd.FundingType<>'Payoneer' THEN 1 ELSE 0 END) AS 'Other MOP Ind',
		 MAX(CASE WHEN bdmonmd.FundingType='PayPal'  THEN 1 ELSE 0 END) 'PayPalInd',
		 MAX(CASE WHEN bdmonmd.FundingType<>'PayPal' THEN 1 ELSE 0 END) AS 'Other MOP Ind_PayPal'
	 
		 FROM BI_DB..BI_DB_Money_Out_New_Management_Dashboard bdmonmd
		 WHERE bdmonmd.RequestDate>=DATEADD(MONTH,-4,DATEADD(DAY,1,EOMONTH(GETDATE()))) AND bdmonmd.Country IN ('United States','Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates') 
		 AND bdmonmd.CashoutStatusID_Funding=3
                 and bdmonmd.RequestDate<DATEADD(month, DATEDIFF(month, 0,getdate()), 0)
		 GROUP BY EOMONTH(bdmonmd.RequestDate), bdmonmd.CID,
		 bdmonmd.Country
		 ) AS a1

	

	UNION ALL 
	
	SELECT a1.EOM,
	a1.CID,
	a1.Country,
	'MoneyIn' AS Category,
	CASE WHEN a1.IsFTD=1 THEN 'FTD' WHEN a1.IsFTD=0 then 'Redeposit' ELSE 'Total' END 'TxType',
	CASE WHEN a1.PayoneerInd+a1.[Other MOP Ind]=1 AND a1.PayoneerInd=1 THEN 'Only Payoneer'
		 WHEN  a1.PayoneerInd+a1.[Other MOP Ind]=1 AND a1.[Other MOP Ind]=1 THEN 'Only Other MOP'
		 ELSE 'Both Payoneer and Other MOP' END AS 'ClientType',
		 CASE WHEN a1.PayPalInd+a1.[Other MOP Ind_PayPal]=1 AND a1.PayPalInd=1 THEN 'Only PayPal'
		 WHEN  a1.PayPalInd+a1.[Other MOP Ind_PayPal]=1 AND a1.[Other MOP Ind_PayPal]=1 THEN 'Only Other MOP'
		 ELSE 'Both PayPal and Other MOP' END AS 'ClientType_paypal'
	from
		(SELECT 
		 EOMONTH(bdminmd.DepositDate) 'EOM',
		 bdminmd.CID,
		 bdminmd.IsFTD,
		 bdminmd.Country,
		 MAX(CASE WHEN bdminmd.DepositMethod='Payoneer'  THEN 1 ELSE 0 END) 'PayoneerInd',
		 MAX(CASE WHEN bdminmd.DepositMethod<>'Payoneer' THEN 1 ELSE 0 END) AS 'Other MOP Ind',
		 MAX(CASE WHEN bdminmd.DepositMethod='PayPal'  THEN 1 ELSE 0 END) 'PayPalInd',
		 MAX(CASE WHEN bdminmd.DepositMethod<>'PayPal' THEN 1 ELSE 0 END) AS 'Other MOP Ind_PayPal'
	 
		 FROM BI_DB..BI_DB_Money_In_New_Management_Dashboard bdminmd
		 WHERE bdminmd.DepositDate>=DATEADD(mm,-3,GETDATE()-1) AND bdminmd.Country IN ('United States','Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates') 
		 AND bdminmd.PaymentStatusID=2
                 and  bdminmd.DepositDate<DATEADD(month, DATEDIFF(month, 0,getdate()), 0) 
		 GROUP BY EOMONTH(bdminmd.DepositDate), bdminmd.CID,bdminmd.Country,
		 bdminmd.IsFTD) AS a1

	 UNION ALL

	 SELECT 
	 a2.EOM,
	a2.CID,
	a2.Country,
	'MoneyIn' AS Category,
	'Total' as 'TxType',
	 CASE WHEN a2.[PayoneerInd All]+a2.[Other MOP All]=1 AND a2.[PayoneerInd All]=1 THEN 'Only Payoneer'
		 WHEN a2.[PayoneerInd All]+a2.[Other MOP All]=1 AND a2.[Other MOP All]=1 THEN 'Only Other MOP'
		 ELSE 'Both Payoneer and Other MOP' END AS 'ClientType',
		  CASE WHEN a2.[PayPal All]+a2.[Other MOP All_Paypal]=1 AND a2.[PayPal All]=1 THEN 'Only PayPal'
		 WHEN a2.[PayPal All]+a2.[Other MOP All_Paypal]=1 AND a2.[Other MOP All_Paypal]=1 THEN 'Only Other MOP'
		 ELSE 'Both PayPal and Other MOP' END AS 'ClientType_Paypal'
	 FROM (SELECT 
	 EOMONTH(bdminmd.DepositDate) 'EOM',
	 'Total' AS 'IsFTD',
	 'MoneyIn' AS Category,
	 bdminmd.CID,
	 bdminmd.Country,
	 MAX(CASE WHEN bdminmd.DepositMethod='Payoneer' THEN 1 ELSE 0 END) 'PayoneerInd All',
	 MAX(CASE WHEN bdminmd.DepositMethod<>'Payoneer' THEN 1 ELSE 0 END) 'Other MOP All',
	 MAX(CASE WHEN bdminmd.DepositMethod='PayPal' THEN 1 ELSE 0 END) 'PayPal All',
	 MAX(CASE WHEN bdminmd.DepositMethod<>'PayPal' THEN 1 ELSE 0 END) 'Other MOP All_Paypal'
     FROM BI_DB..BI_DB_Money_In_New_Management_Dashboard bdminmd
	 WHERE  bdminmd.PaymentStatusID=2 AND bdminmd.DepositDate>=DATEADD(mm,-3,GETDATE()-1) AND bdminmd.Country IN ('United States','Thailand','Morocco','Egypt','Ukraine' ,'Vietnam','Brazil','Argentina','Philippines','United Arab Emirates') 
	 and bdminmd.DepositDate<DATEADD(month, DATEDIFF(month, 0,getdate()), 0)
         group BY EOMONTH(bdminmd.DepositDate),
	 bdminmd.CID ,bdminmd.Country
	 ) AS a2
)MIMO