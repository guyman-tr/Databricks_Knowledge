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
 ,NULL AS  Region
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
	 (select distinct t.GCID, t.TranDate
	, CASE  WHEN 	DATEDIFF(Month,LAG (t.TranDate,1,Null)  OVER ( partition by t.GCID ORDER BY t.TranDate), t.TranDate)>=6	then '1' ELSE '0' end 'Reactivated'
		 from  (select distinct b.TranDate, b.GCID from EXW_dbo.EXW_FactTransactions b where b.SenderAddress<>'0x5be786ad38f5846f605a8003550074cdfd4899a1' ) t 
	 JOIN DWH_dbo.Dim_Date dd on t.TranDate = dd.FullDate  where t.GCID>0 )ta 
	 on  ta.GCID = fb.GCID and ta.TranDate =fb.BalanceDate
 Where 1=1
 AND fb.ComplianceClosureEvent=0 
 AND fb.AMLClosureEvent =0
	--and dd.FullDate >=  '2020-01-23' 
	--and dd.FullDate<=  '2020-02-28'
			
and dd.FullDate >=  <[Parameters].[First Month for Report -  Last Date (copy)]>
and dd.FullDate <= <[Parameters].[Last Month for Report - Last Date (copy)]>
--AND  dd.IsLastDayOfMonth='Y' 
and fb.GCID>0
group by 
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