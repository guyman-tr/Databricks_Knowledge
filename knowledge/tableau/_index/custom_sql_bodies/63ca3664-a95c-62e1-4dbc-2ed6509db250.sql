select v.*,
case when v.OriginalOutcome in ('Manual review') then  'Manual Review' else [OriginalOutcome] end as InitialOutcome ,a.Name as AccountType, case when dc.HasWallet = 1 then 'Yes' else 'No' end as HasWallet, f.VerificationLevel3Date, f.VerificationLevel2Date, f.VerificationLevel1Date, f.ClientVLonUpload 
from BI_DB_dbo.BI_DB_Document_Vendors v 
left join #final f on f.CID=v.CID 
left join DWH_dbo.Dim_Customer dc on v.CID = dc.RealCID
LEFT JOIN DWH_dbo.Dim_AccountType a on a.AccountTypeID = dc.AccountTypeID