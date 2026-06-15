SELECT  
	 bdcn.Regulation		
  , sum(bdcn.Real_Units					) as Real_Units	
  ,sum(0) AS 'FCA Eligibility'
  ,'NOPByInstrument' AS 'Key'
    ,'EU Eligible' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.TanganyStatus IN ('Customer','Internal','MicaCustomer')
GROUP BY 
	bdcn.Regulation
	,bdcn.BuyCurrency
   UNION ALL 

  SELECT
	
   bdcn.Regulation
					
  , sum(bdcn.Real_Units						) as Real_Units						
  ,sum(0) AS 'FCA Eligibility'
  ,'CryptoAllReg' AS 'Key'
    ,'EU Eligible' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY
   bdcn.Regulation
  ,bdcn.BuyCurrency
   
   UNION ALL 


  
	SELECT  
	 bdcn.Regulation		
  , sum(bdcn.Real_Units					) as Real_Units		
  ,sum(0) AS 'FCA Eligibility'
  ,'CryptoNOPUS' AS 'Key'
    ,'EU Eligible' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
GROUP BY 
	bdcn.Regulation 
	,bdcn.BuyCurrency



UNION ALL 


SELECT
		 bdcn.Regulation		
  , sum(bdcn.Real_Units					) as Real_Units	
  ,sum(0) AS 'FCA Eligibility'
  ,'AllRegCryptoNOP' AS 'Key'
    ,'EU Eligible' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
GROUP BY 
   bdcn.Regulation
  ,bdcn.BuyCurrency



UNION ALL 








  SELECT
			 bdcn.Regulation		
  , sum(bdcn.Real_Units					) as Real_Units		
  ,sum(0) AS 'FCA Eligibility'
  ,'OptInNewComers' AS 'Key'
  ,'EU Eligible' AS 'Key2'
  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 

WHERE bdcn.Date =  <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
--AND bdcn.InstrumentID IN (100026,100017,100001,100063)
AND bdcn.Regulation IN ('FCA') AND ISNULL(bdcn.TanganyStatus,'NA') IN ('NA','MicaCustomer','Inactive')
GROUP BY 
	bdcn.Regulation
	,bdcn.BuyCurrency

	--------------------------------------------------------------------------------------------------------------------
	union all
	SELECT
	bdcn.Regulation
				
  , sum(0) as Real_Units		
	  ,sum(bdcn.Real_Units						) AS 'FCA Eligibility'

	,'FCA Eligibility' AS 'Key'
	,'FCA Eligibility' AS 'Key2'
	, bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 

WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
--AND bdcn.InstrumentID IN (100026,100017,100001,100063)
AND bdcn.Regulation IN ('FCA') AND ISNULL(bdcn.TanganyStatus,'NA') IN ('NA','MicaCustomer','Inactive')
GROUP BY 
	bdcn.BuyCurrency, bdcn.Regulation