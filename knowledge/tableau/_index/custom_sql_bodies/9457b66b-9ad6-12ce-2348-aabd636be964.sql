SELECT
	bdcn.Regulation,
   sum(bdcn.Real_Units						) as FCAStaking		
    ,sum(0) AS Real_Units_OptIN
	,'FCA Staking' AS 'Key'
	,'FCA Staking' AS 'Key2'
  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 

WHERE bdcn.Date =  <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
--AND bdcn.InstrumentID IN (100026,100017,100001,100063)
AND bdcn.Regulation IN ('FCA') AND ISNULL(bdcn.TanganyStatus,'NA') IN ('NA','MicaCustomer','Inactive')
GROUP BY 
	bdcn.Regulation, bdcn.BuyCurrency
  

   union ALL 
   -------------------------------------------------------------------------------


   SELECT  
	 bdcn.Regulation		
  , sum(0		) as FCAStaking	
    ,sum(bdcn.Real_Units_Staking_OptIn) AS Real_Units_OptIN

  ,'NOPByInstrument' AS 'Key'
  ,'EU OPT IN' AS 'Key2'

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
					
  , sum(0				) as FCAStaking						
   ,sum(bdcn.Real_Units_Staking_OptIn) AS Real_Units_OptIN

  ,'CryptoAllReg' AS 'Key'
    ,'EU OPT IN' AS 'Key2'

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
  , sum(0					) as FCAStaking		
    ,sum(bdcn.Real_Units_Staking_OptIn) AS Real_Units_OptIN

  ,'CryptoNOPUS' AS 'Key'
    ,'EU OPT IN' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
GROUP BY 
	bdcn.Regulation 
	,bdcn.BuyCurrency
/*
SELECT
	bdcn.Date
  , 0 AS InstrumentID
  , 'AllInstruments' AS InstrumentName
  , sum(bdcn.Real_NOP						) as Real_NOP						
  , sum(bdcn.CFD_NOP						) as CFD_NOP						
  , sum(bdcn.Total_NOP						) as Total_NOP						
  , sum(bdcn.Real_Units						) as Real_Units	
  , sum(case when IsBuy = 1 then bdcn.CFD_Units		else -bdcn.CFD_Units	end) as CFD_Units						
  , sum(case when IsBuy = 1 then bdcn.Total_Units	else -bdcn.Total_Units	end) as Total_Units							
  , max(bdcn.EOD_Bid_Price					) as EOD_Bid_Price					
  , sum(bdcn.EquityReal						) as EquityReal						
  , sum(bdcn.EquityCFD						) as EquityCFD						
  , sum(bdcn.Total_NOP_ReversedUnits		) as Total_NOP_ReversedUnits	
  , 'ALLAssets' AS BuyCurrency
  , SUM(bdcn.TRS_Units) TRS_Units
  , SUM(bdcn.TRS_NOP) TRS_NOP
  , SUM(bdcn.EquityTRS) EquityTRS
  ,sum(bdcn.Real_Units_Staking_OptIn) 'Real_Units_Staking_OptIn'
  ,sum(bdcn.Real_Units_Staking_OptOut)'Real_Units_Staking_OptOut'
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 
WHERE bdcn.Date = <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
AND bdcn.Regulation IN ('eToroUS','FinCEN','FinCEN+FINRA')
group by bdcn.Date
*/



UNION ALL 


SELECT
		 bdcn.Regulation		
  , sum(0					) as FCAStaking	
    ,sum(bdcn.Real_Units_Staking_OptIn) AS Real_Units_OptIN

  ,'AllRegCryptoNOP' AS 'Key'
    ,'EU OPT IN' AS 'Key2'

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
  , sum(0				) as FCAStaking		
  ,sum(bdcn.Real_Units_Staking_OptIn) AS Real_Units_OptIN
  ,'OptInNewComers' AS 'Key'
    ,'EU OPT IN' AS 'Key2'

  ,bdcn.BuyCurrency
FROM BI_DB_dbo.BI_DB_Crypto_NOP bdcn 

WHERE bdcn.Date =  <[Parameters].[Parameter 1]>
AND bdcn.IsCreditReportValidCB = 1
--AND bdcn.InstrumentID IN (100026,100017,100001,100063)
AND bdcn.Regulation IN ('FCA') AND bdcn.TanganyStatus='NA'
GROUP BY 
	bdcn.Regulation
	,bdcn.BuyCurrency