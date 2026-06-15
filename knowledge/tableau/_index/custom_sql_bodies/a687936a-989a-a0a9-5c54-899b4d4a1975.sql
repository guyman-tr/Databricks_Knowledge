select a.*,
case when a1.GCID is not null then 1 else 0 end as 'eMoneyInd'
from BI_DB_dbo.BI_DB_TIN_Gap a
left join eMoney_dbo.eMoney_Dim_Account a1 on a1.GCID=a.GCID 
                                               and a1.IsValidETM=1
                                               AND a1.GCID_Unique_Count=1