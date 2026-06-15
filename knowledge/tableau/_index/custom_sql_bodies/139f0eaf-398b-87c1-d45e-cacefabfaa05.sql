SELECT
	bdcn.Date
  , bdcn.Regulation					
  , sum(bdcn.EquityReal						) as EquityReal	
  ,sum(bdcn.Real_Units) AS 'RealUnits'
 ,bdcn.BuyCurrency
  ,'NoneRegulation' AS 'Key'

FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1 AND bdcn.Regulation = 'None'
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
  ,bdcn.BuyCurrency

-------------------------------------------------------------------------------------------------------------------------------------------------------------

union ALL 



SELECT
	bdcn.Date	
	,'All' AS 'Regulation'
	,sum(0) AS [Equity Real Crypto]
  , sum(bdcn.Real_Units						) as Real_Units	
  , bdcn.BuyCurrency
  ,'OPTINUS' AS 'Key'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
GROUP BY 
	bdcn.Date
  , bdcn.BuyCurrency


--------------------------------------------------------------------------------------------------------------------------

Union ALL 

SELECT
	bdcn.Date
	,'All' AS Regulation
	,sum(0) AS [Equity Real Crypto]
	, sum(bdcn.Real_Units						) as Real_Units		
  	, bdcn.BuyCurrency	
	,'OPTINTangany' AS 'Key'
    
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.TanganyStatus IN ('Customer','Internal','MicaCustomer')
-- AND bdcn.Regulation IN ('ASIC & GAML', 'ASIC')
GROUP BY 
	bdcn.Date
, bdcn.BuyCurrency

------------------------------------------------------------------------------------------------------------------------------------------
union ALL 
SELECT
	bdcn.Date
  , bdcn.Regulation					
  ,sum(0) AS [Equity Real Crypto]
  , sum(bdcn.Real_Units						) as Real_Units						
  , bdcn.BuyCurrency
  ,'OptInTotal' AS 'Key'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
	bdcn.Date
  , bdcn.Regulation
  , bdcn.BuyCurrency