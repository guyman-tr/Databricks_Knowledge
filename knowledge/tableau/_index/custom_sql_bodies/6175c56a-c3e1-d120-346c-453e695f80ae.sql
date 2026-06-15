SELECT 
 CASE 
when efb.FullDate BETWEEN DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.FullDate ) < 8 THEN 'Week1'
when	efb.FullDate BETWEEN DATEADD(DAY, 8, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.FullDate ) < 15 THEN 'Week2'
when	efb.FullDate BETWEEN DATEADD(DAY, 15, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.FullDate ) < 22 THEN 'Week3'
when	efb.FullDate BETWEEN DATEADD(DAY, 22, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.FullDate ) < 29 THEN 'Week4'
when	efb.FullDate BETWEEN DATEADD(DAY, 29, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,efb.FullDate ) < 31 THEN 'Week5' end 'Weekb'
 ,efb.GCID
,efb.FullDate
,efb.FullDateID
, efb.BalanceUSD
,efb.Balance
, efb.CryptoId
, efb.CryptoName
, dc.Country
	, dc.Regulation
,CASE
		WHEN 
			dc.IsTestAccount=1     THEN 'TestUser'
		When dc.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from EXW.dbo.EXW_FactBalance efb with (NOLOcK) 
	JOIN DWH.dbo.Dim_Date dd on  efb.FullDateID = dd.DateKey 
JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.GCID= efb.GCID
WHERE  1=1
and efb.GCID>0
and efb.FullDateID in  
(CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,6,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,13,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,20,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
, CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,27,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(WEEK, 0 ,getdate()), 112) AS INT))