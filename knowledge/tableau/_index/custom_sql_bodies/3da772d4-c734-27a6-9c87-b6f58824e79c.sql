select 
ft.DepositID,ModificationDate,
dm.FirstName + ' ' + dm.LastName as ProcessedBy
from DWH_dbo.Fact_BillingDeposit ft
join DWH_dbo.Dim_Manager dm on dm.ManagerID=ft.ManagerID
where FundingTypeID=2 and 
--ft.ModificationDatebetween 

-- <[Parameters].[Parameter 3]> and <[Parameters].[Parameter 4]>
--  and
 ft.PaymentStatusID=2