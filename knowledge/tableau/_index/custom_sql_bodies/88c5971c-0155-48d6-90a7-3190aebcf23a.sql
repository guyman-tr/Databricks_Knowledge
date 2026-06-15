select v.*, 
case when v.OriginalOutcome in ('Manual review') then 
'Manual Review' else [OriginalOutcome] end as InitialOutcome ,
case when dc.HasWallet = 1 then 'Yes' else 'No' end as HasWallet
from #all v
left join DWH_dbo.Dim_Customer dc on v.CID = dc.RealCID