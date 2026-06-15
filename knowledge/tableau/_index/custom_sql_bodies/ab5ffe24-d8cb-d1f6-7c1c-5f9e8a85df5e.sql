select a.*,
case when a1.GCID is not null then 1 else 0 end as 'eMoneyInd',
s.Previous_PlayerStatus_Reason,
s.Previous_PlayerStatus_Sub_Reason,
s.Previous_PlayerStatus,
s.PlayerStatusSubReason,
PlayerStatusReason,
isnull(mod.LastModified,'1900-01-01')LastModified,
dc.VerificationLevelID


from BI_DB_dbo.BI_DB_TIN_Gap_Temp_pop a
join DWH_dbo.Dim_Customer dc on a.CID=dc.RealCID
left join eMoney_dbo.eMoney_Dim_Account a1 on a1.GCID=a.GCID 
                                               and a1.IsValidETM=1
                                               AND a1.GCID_Unique_Count=1
left join 
(select s.*, 
row_number()over(partition by CID order by Change_Date desc)rn
from BI_DB_dbo.BI_DB_AML_PlayerStatus_Changes s) s
 on s.CID=a.CID and rn=1
left join (SELECT a.GCID,max(a.LastModified)LastModified FROM 
[BI_DB_dbo].[External_UserApiDB_Customer_ExtendedUserField] a
--JOIN DWH_dbo.Dim_Customer dc ON a.GCID = dc.GCID
WHERE FieldId=6
GROUP BY a.GCID)mod on mod.GCID=a.GCID