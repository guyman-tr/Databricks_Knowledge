select

    kyc.*,
CASE WHEN fca.RealCID is not null then 1 else 0 end as YesterdayDepositors
from #KYCPANEL kyc
LEFT JOIN DWH_dbo.Fact_CustomerAction fca ON fca.RealCID= kyc.CID 
AND fca.ActionTypeID = 7 -- Approved Deposit
AND fca.DateID =  CAST(CONVERT(CHAR(8),getdate()-1,112) AS INT)
AND fca.Amount >0