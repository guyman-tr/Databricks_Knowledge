SELECT
	bdcn.Date
  , bdcn.Regulation					
  , sum(bdcn.Real_Units						) as Calculation						
  , bdcn.BuyCurrency
  ,'RealUnitsByCurrency1_CryptoNOP' AS 'Key'
  ,'RealUnitsByCurrency' AS 'Key2'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
  , bdcn.BuyCurrency

  Union ALL 
  SELECT
	bdcn.Date
  , 'All' AS 'Regulation'					
  , sum(bdcn.Real_Units)	 as Calculation						
  , 'All' AS 'BuyCurrency'
  ,'RealUnitsByCurrency2_CryptoNOP' AS 'Key'
    ,'RealUnitsByCurrency' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
  , bdcn.BuyCurrency

UNION ALL 
   
SELECT
	bdcn.Date
  , 'All' as 'Regulation'
  , sum(bdcn.Real_Units)			as Calculation
  , 'All' AS 'BuyCurrency'
  ,'RealUnitsByCurrency3_CryptoNOPCID' AS 'Key'
    ,'RealUnitsByCurrency' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 	bdcn.Date



-- ---------------------------------------------------------------------------
union ALL 
SELECT
	<[Parameters].[Parameter 1]> AS 'Date'
	,'' AS Regulation
	,sum(bdcn.Real_Units) AS Calculation
  , 'All' as BuyCurrency
  , 'TanganyBuyCurrency1_CryptoNOPCID' AS 'Key'
    ,'TanganyBuyCurrency' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
-- AND bdcn.Regulation IN ('CySEC', 'BVI', 'NFA')
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.TanganyStatus IN ('Customer','Internal','MicaCustomer')


Union ALL 

SELECT
	bdcn.Date
	,'' AS Regulation
	, sum(bdcn.Real_Units						) as Calculation	
	  	, bdcn.BuyCurrency	

	,'TanganyBuyCurrency2_CryptoNOP' AS 'Key'
    	    ,'TanganyBuyCurrency' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.TanganyStatus IN ('Customer','Internal','MicaCustomer')
-- AND bdcn.Regulation IN ('ASIC & GAML', 'ASIC')
GROUP BY 
	bdcn.Date
, bdcn.BuyCurrency

UNION ALL

SELECT
	<[Parameters].[Parameter 1]> AS 'Date',
	'' AS Regulation
  
  , sum(bdcn.Real_Units						) as Calculation	
  , 'All' as BuyCurrency
  , 'TanganyBuyCurrency3_CryptoNOP' AS 'Key'
    	    ,'TanganyBuyCurrency' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.TanganyStatus IN ('Customer','Internal','MicaCustomer')
-- AND bdcn.Regulation IN ('ASIC & GAML', 'ASIC')

------------------------------------------------------------------------------------------------------------------------------------------
union ALL 
SELECT
	bdcn.Date
	,'FinCEN/FinCEN+FINRA/eToroUS' AS 'Regulation'

  , sum(bdcn.Real_Units)			as Calculation

  /*,CASE WHEN bdcn.Regulation IN ('FinCEN+FINRA','eToroUS','FinCEN') THEN 'FinCEN/FinCEN+FINRA/eToroUS'
        WHEN bdcn.Regulation IN ('ASIC','ASIC & GAML') THEN 'ASIC/ASIC & GAML'
		WHEN bdcn.Regulation IN ('CySEC', 'BVI', 'NFA', 'None') THEN 'EU'
		ELSE bdcn.Regulation END AS 'Regulation'*/
	
   ,'All' AS 'BuyCurrency'
   ,'USRealUnits1_CryptoNOPCID' AS 'Key'
       ,'USRealUnits' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1 AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
GROUP BY 	bdcn.Date
/*
SELECT
	bdcn.Date
  , sum(bdcn.Real_Units)			as Real_Units
  , sum(bdcn.Real_Invested_Amount)	as Real_Invested_Amount
  , sum(bdcn.CFD_Invested_Amount)	as CFD_Invested_Amount
  , sum(bdcn.Total_Invested_Amount)	as Total_Invested_Amount
  , COUNT(CID) AS CountCID
  ,'FCA ADA/TRX/ETH/SOL'  AS 'Regulation'
  ,'ADA/TRX/ETH/SOL' AS Coins

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1 AND bdcn.Regulation IN ('FCA') AND bdcn.InstrumentName IN ('ADA/USD','TRX/USD','ETH/USD','SOL/USD') AND ISNULL(bdcn.TanganyStatus,'NA') IN ('NA','MicaCustomer','Inactive')
GROUP BY 	bdcn.Date
*/
UNION ALL
SELECT
	<[Parameters].[Parameter 1]>
	,'FinCEN/FinCEN+FINRA/eToroUS' AS 'Regulation'
  , sum(bdcn.Real_Units)			as Calculation
  
   ,'All' AS 'BuyCurrency'
   ,'USRealUnits2_CryptoNOPCID' AS 'Key'
          ,'USRealUnits' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1 AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')

UNION ALL 





SELECT
	bdcn.Date				
	,'All' AS 'Regulation'
  , sum(bdcn.Real_Units						) as Calculation	
  , bdcn.BuyCurrency
  ,'USRealUnits3_CryptoNOP' AS 'Key'
            ,'USRealUnits' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
GROUP BY 
	bdcn.Date
  , bdcn.BuyCurrency

UNION ALL
SELECT
	<[Parameters].[Parameter 1]>		
	,'All' AS 'Regulation'
  , sum(bdcn.Real_Units						) as Calculation	
  
  ,'All' AS 'BuyCurrency'
  ,'USRealUnits4_CryptoNOP' AS 'Key'
            ,'USRealUnits' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')


------------------------------------------------------------------------------------------------------------------------
union ALL 
SELECT
	bdcn.Date
  , bdcn.Regulation					
  , sum(bdcn.EquityReal						) as Calculation	
   ,bdcn.BuyCurrency
 ,'EquityRealNOP1_CryptoNOP' AS 'Key'
             ,'EquityRealNOP' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
  ,bdcn.BuyCurrency

  union ALL 

  SELECT
	<[Parameters].[Parameter 1]>
  , 'All' AS 'Regulation'					
  , sum(bdcn.EquityReal						) as Calculation	
   ,'All'AS 'BuyCurrency'
 ,'EquityRealNOP2_CryptoNOP' AS 'Key'
              ,'EquityRealNOP' AS 'Key2'


FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1


  union ALL 




  SELECT 
	 Date 
	,Regulation	
	,isnull(sum(TotalRealCrypto), 0) + ISNULL(SUM(PositionPNLCryptoReal),0) AS Calculation
	,'All'AS 'BuyCurrency'
	,'EquityRealNOP3_ClientBalanceAgg' AS 'Key'
	             ,'EquityRealNOP' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New with (nolock)
WHERE Date =<[Parameters].[Parameter 1]>
	AND IsCreditReportValidCB = 1
--	AND Club <> 'Internal'
--	AND Regulation IN ('ASIC','ASIC & GAML')
GROUP BY Date 
	,Regulation

  union ALL 




  SELECT 
	 <[Parameters].[Parameter 1]>
	,'All' AS 'Regulation'	
	,isnull(sum(TotalRealCrypto), 0) + ISNULL(SUM(PositionPNLCryptoReal),0) AS Calculation
	,'All'AS 'BuyCurrency'
	,'EquityRealNOP4_ClientBalanceAgg' AS 'Key'
	             ,'EquityRealNOP' AS 'Key2'

FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New with (nolock)
WHERE Date =<[Parameters].[Parameter 1]>
	AND IsCreditReportValidCB = 1
--	AND Club <> 'Internal'
--	AND Regulation IN ('ASIC','ASIC & GAML')