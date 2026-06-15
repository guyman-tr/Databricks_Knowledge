SELECT b.*, 
		MAX(b.SuccessY_N) OVER (PARTITION BY CID, b.Provider, b.Date) AS SuccessfulDepositorY_N		
FROM 
(
select  t.*, a.SumSuccessUSD, a.MaxFailOrPendingUSD,  a.countActions, a.FailAmountAdjusted, a.SuccessAmountAdjusted,
CASE WHEN t.PaymentStatus = 'Approved' THEN 1 ELSE 0 END AS SuccessY_N
FROM
(
select *
,cast (ModificationDate as DATE) as Date
, ROW_NUMBER() over (partition by CID, cast (ModificationDate as DATE), Provider order by DepositID) as RN
 from BI_DB_AllDeposits with (Nolock)
where Region in ('China', 'Other Asia')								
AND CONVERT(DATE, ModificationDate) <= CONVERT(DATE, getdate())
OR (CONVERT(DATE, ModificationDate) > CONVERT(DATE, getdate()) AND DATEPART(HOUR,ModificationDate) > 2) 
) t
left join 
(
select CID
	, CAST(ModificationDate AS DATE) AS Date
	, Provider
	, sum(case when PaymentStatus = 'Approved' then [Amount in $] else 0 end) as SumSuccessUSD
	, max(case when PaymentStatus != 'Approved' and PaymentStatus != 'Canceled' then [Amount in $] else 0 end) as MaxFailOrPendingUSD
	, COUNT(DepositID) AS countActions
	, max(case when PaymentStatus != 'Approved' and PaymentStatus != 'Canceled' then [Amount in $] else 0 end)/COUNT(DepositID) AS FailAmountAdjusted
	, sum(case when PaymentStatus = 'Approved' then [Amount in $] else 0 end)/COUNT(DepositID) AS SuccessAmountAdjusted
from BI_DB_AllDeposits with (Nolock)
where Region in ('China', 'Other Asia') 
group by 
	CID
	, Provider
	, CAST(ModificationDate AS DATE)	
) a
	on t.CID = a.CID and t.Provider = a.Provider AND t.Date = a.Date
where t.ModificationDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE())-3, 0) 
) b