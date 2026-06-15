select
	CID,
	cast(RequestDate AS date) AS RequestDate,
	PositionID,
	RedeemID,	
	gg.AmountOnRequest,
        rs.Name as RedeemStatus,
	DATEDIFF(HOUR,gg.LastModificationDate,GETDATE()) TimeSinceStatusInHr
from  BI_DB_dbo.External_etoro_Billing_Redeem gg
left join DWH_dbo.Dim_RedeemStatus rs on rs.RedeemStatusID=gg.RedeemStatusID
where 
gg.RedeemStatusID IN (
4, --ReadyToRedeem or 
5 --PositionClosing 
)
AND RequestDate>=getdate()