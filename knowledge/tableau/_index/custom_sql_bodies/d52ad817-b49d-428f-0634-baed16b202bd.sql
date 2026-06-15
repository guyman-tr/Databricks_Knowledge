select a.*,
case when a1.GCID is not null then 1 else 0 end as 'eMoneyInd',
s.Previous_PlayerStatus_Reason,
s.Previous_PlayerStatus_Sub_Reason,
s.Previous_PlayerStatus,
s.PlayerStatusSubReason,
PlayerStatusReason


from BI_DB_dbo.BI_DB_TIN_Gap a
left join eMoney_dbo.eMoney_Dim_Account a1 on a1.GCID=a.GCID 
                                               and a1.IsValidETM=1
                                               AND a1.GCID_Unique_Count=1
left join 
(select s.*, 
row_number()over(partition by CID order by Change_Date desc)rn
from BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes s) s
 on s.CID=a.CID and rn=1