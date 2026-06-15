select
  count (distinct fb.GCID) as 'Number of Users'
--, fb.RealCID
 ,sum(fb.BalanceUSD) as 'Balance USD'
 ,count ( distinct  case when fb.BalanceUSD >0 then fb.GCID ELSE NULL end ) as 'Users with Non Zero Balance'
 ,count (distinct ta.GCID) as 'Active Users'
 ,count ( distinct  case when ta.GCID IS NULL then fb.GCID ELSE NULL end ) as 'NonActive'
 ,count ( distinct CASE 	WHEN 	ta.Reactivated =1	then ta.GCID ELSE NULL end) as  'Reactivated after 6 Month' 
 ,fb.BalanceDate AS FullDate
 ,fb.Club
 ,fb.Country
 --,NULL AS  Region
 ,fb.Regulation
 ,CASE
		WHEN 
			fb.IsTestAccount =1   THEN 'TestUser'
		When fb.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END AS IsRealUser
from EXW_dbo.EXW_FinanceReportsBalancesNew  fb  with (NOLOcK)
JOIN DWH_dbo.Dim_Date dd on  fb.BalanceDateID = dd.DateKey
	 Left Join
	 (select distinct t.GCID, t.EndMonth
	, CASE  WHEN 	DATEDIFF(Month,LAG (t.EndMonth,1,Null)  OVER ( partition by t.GCID ORDER BY t.EndMonth), t.EndMonth)>=6	then '1' ELSE '0' end 'Reactivated'
		 from  (select distinct EOMONTH(b.TranDate)EndMonth, b.GCID from EXW_dbo.EXW_FactTransactions b where b.SenderAddress<>'0x5be786ad38f5846f605a8003550074cdfd4899a1') t 
	 JOIN DWH_dbo.Dim_Date dd on t.EndMonth = dd.FullDate  where t.GCID>0 )ta 
	 on  ta.GCID = fb.GCID and ta.EndMonth =fb.BalanceDate
 Where 1=1
 AND fb.ComplianceClosureEvent=0 
 AND fb.AMLClosureEvent =0
--and dd.FullDate >=  '2019-01-31' 
--and dd.FullDate =  '2020-02-29'
			
and dd.FullDate >=  <[Parameters].[Parameter 2]> 
and dd.FullDate <=  <[Parameters].[Parameter 3]>
AND  dd.IsLastDayOfMonth='Y' 
and fb.GCID>0
GROUP BY 
  fb.BalanceDate
 ,fb.BalanceDate 
 ,fb.Club
 ,fb.Country
 ,fb.Regulation
 ,CASE
		WHEN 
			fb.IsTestAccount =1   THEN 'TestUser'
		When fb.IsValidCustomer =0 then 'eTorian'
		ELSE 'RealUser'
	END