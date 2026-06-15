SELECT
	bdcn.Date
  , bdcn.Regulation					
  , sum(bdcn.Real_Units						) as Real_Units										
  , sum(bdcn.EquityReal						) as EquityReal	
  ,'1_CryptoNOP' AS 'Key'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
union all
SELECT
	<[Parameters].[Parameter 1]>
  , 'All' AS 'Regulation'			
  , sum(bdcn.Real_Units						) as Real_Units										
  , sum(bdcn.EquityReal						) as EquityReal	
  ,'2_CryptoNOP' AS 'Key'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1

union ALL 
-------------------------------------------------------------------------------------------------------------------------------------------------
SELECT
	bdcn.Date
  ,CASE WHEN bdcn.Regulation IN ('FinCEN+FINRA','eToroUS','FinCEN') THEN 'FinCEN/FinCEN+FINRA/eToroUS'
        WHEN bdcn.Regulation IN ('ASIC','ASIC & GAML') THEN 'ASIC/ASIC & GAML'
		WHEN bdcn.Regulation IN ('CySEC', 'BVI', 'NFA', 'None') THEN 'EU'
		ELSE bdcn.Regulation END AS 'Regulation'
, sum(bdcn.Real_Units)	as Real_Units   
, sum(bdcn.EquityReal)	as EquityReal
   
   ,'3_CryptoNOPCID' AS 'Key'

FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 	bdcn.Date,
			CASE WHEN bdcn.Regulation IN ('FinCEN+FINRA','eToroUS','FinCEN') THEN 'FinCEN/FinCEN+FINRA/eToroUS'
			     WHEN bdcn.Regulation IN ('ASIC','ASIC & GAML') THEN 'ASIC/ASIC & GAML'
			     WHEN bdcn.Regulation IN ('CySEC', 'BVI', 'NFA', 'None') THEN 'EU'
			     ELSE bdcn.Regulation END


UNION ALL 
   
SELECT
	bdcn.Date
	,'All' AS 'Regulation'
, sum(bdcn.Real_Units)			as Real_Units  
, sum(bdcn.EquityReal)			as EquityReal
  
  ,'4_CryptoNOPCID' AS 'Key'
FROM BI_DB_dbo.BI_DB_Crypto_NOP_CID bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 	bdcn.Date

union ALL 
-----------------------------------------------------------------------------------------------------------------------------

SELECT Date 
	,Regulation	
	
	,sum(0) AS [RealUnits]-- just because of the union
,isnull(sum(TotalRealCrypto), 0) + ISNULL(SUM(PositionPNLCryptoReal),0) AS [EquityReal]	
,'5_ClientBalanceAgg' AS 'Key'
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
	,'All' as 'Regulation'	
	,sum(0) AS [RealUnits]-- just because of the union
	,isnull(sum(TotalRealCrypto), 0) + ISNULL(SUM(PositionPNLCryptoReal),0) AS [EquityReal]

	,'6_ClientBalanceAgg' AS 'Key'
FROM BI_DB_dbo.BI_DB_Client_Balance_Aggregate_Level_New with (nolock)
WHERE Date =<[Parameters].[Parameter 1]>
	AND IsCreditReportValidCB = 1
--	AND Club <> 'Internal'
--	AND Regulation IN ('ASIC','ASIC & GAML')