select distinct
a.GCID
, a.Country
, a.Regulation
, b.MinDate, b.Week
,CASE
		WHEN 
			a.IsTestAccount=1     THEN 'TestUser'
		When a.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from 
(
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
, dc.Country
, dc.Regulation 
, dc.IsTestAccount
, dc.IsValidCustomer
from EXW.dbo.EXW_FactBalance efb with (NOLOcK) 
	JOIN EXW.dbo.EXW_DimUser dc WITH (nolock) on dc.GCID=efb.GCID

WHERE  1=1
and efb.FullDateID in  
(CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,6,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,13,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,20,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
, CAST(CONVERT(VARCHAR(8),  DATEADD(DAY,27,DATEADD(DAY,1,EOMONTH(DATEADD(MONTH,-1,getdate())))), 112) AS INT)
,CAST(CONVERT(VARCHAR(8),  DATEADD(WEEK, 0 ,getdate()), 112) AS INT))
)a
JOIN
(
select m.GCID
, m.MinDate
, CASE 
when m.MinDate BETWEEN DATEADD(DAY, 1, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,m.MinDate ) < 8 THEN 'Week1'
when	m.MinDate BETWEEN DATEADD(DAY, 8, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,m.MinDate ) < 15 THEN 'Week2'
when	m.MinDate BETWEEN DATEADD(DAY, 15, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,m.MinDate ) < 22 THEN 'Week3'
when	m.MinDate BETWEEN DATEADD(DAY, 22, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,m.MinDate ) < 29 THEN 'Week4'
when	m.MinDate BETWEEN DATEADD(DAY, 29, EOMONTH(GETDATE(), -1))  AND  EOMONTH( GETDATE(),0 ) 
	AND DATEPART(day,m.MinDate ) < 31 THEN 'Week5'
	ELSE 'NA'
end as 'Week'	

from 
(SELECT
efb.GCID
,min (efb.FullDate) as MinDate
FROM EXW.dbo.EXW_FactBalance efb --with (NOLOcK) 
where efb.GCID>0
group by
efb.GCID
) m 
)b
ON b.GCID=a.GCID and b.Week=a.Weekb