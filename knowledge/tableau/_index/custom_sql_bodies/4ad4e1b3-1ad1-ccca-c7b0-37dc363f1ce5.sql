select fd.CID
      ,fd.Manager
	  ,fd.Country
	  ,fd.Region
	  ,l.RealizedEquity
	  ,max(case when cf.RealCID is null  then 1 else 0 end) as NotInvestedInCF-- or (cf.RealCID is not null and  cf.CopyFundCID in (6421394,6215327) the
	  ,max(case when  cf.CopyFundCID in (6421394,6215327) then 1 else 0 end) as InvestedInCryptoFund
from BI_DB.dbo.BI_DB_CIDFirstDates fd
left join BI_DB_SalesCopyFund cf
on cf.RealCID = fd.CID 
join DWH.dbo.V_Liabilities l
on l.CID = fd.CID and l.DateID = CAST(CONVERT(VARCHAR(8),DATEADD(day,-1,getdate()), 112) AS INT)
where (fd.Manager is not null or fd.Manager not in ('System')) and fd.Club in ('Platinum','Gold','Platinum Plus','Diamond') 
group by fd.CID
      ,fd.Manager
	  ,fd.Country
	  ,fd.Region
	  ,l.RealizedEquity