select cl.RealCID CID, dr.Name Regulation, dco.Name Country, vl.RealizedEquity, cl.TotalCLAmount, vl.RealizedEquity- cl.TotalCLAmount EquityExCL, vl.TotalPositionsAmount
		, case when vl.RealizedEquity- cl.TotalCLAmount >=  vl.TotalPositionsAmount then 0 else vl.TotalPositionsAmount - (vl.RealizedEquity- cl.TotalCLAmount) end UtilizedCL
                , Date
                ,case when dc.AccountTypeID = 2 then 'Corporate' else '' end as IsCorporateAccount
                , dl.Name Label
from BI_DB_Daily_CreditLine cl with (NOLOCK)
join DWH.dbo.V_Liabilities vl with (NOLOCK)
on vl.CID = cl.RealCID and vl.DateID = cl.DateID
join DWH.dbo.Dim_Customer dc with (NOLOCK)
on dc.RealCID = cl.RealCID
join DWH.dbo.Dim_Regulation dr with (NOLOCK)
on dr.DWHRegulationID = dc.RegulationID
join DWH.dbo.Dim_Country dco with (NOLOCK)
on dco.CountryID = dc.CountryID
join DWH.dbo.Dim_Label dl with (NOLOCK)
on dl.LabelID = dc.LabelID

--where Date = cast(dateadd(day,-1,getdate()) as date)

where vl.DateID = <[Parameters].[Parameter 1]>