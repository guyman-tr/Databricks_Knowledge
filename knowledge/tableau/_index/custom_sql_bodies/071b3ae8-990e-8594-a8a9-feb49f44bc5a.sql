select ca.RealCID
,dc.FirstName+' '+dc.LastName as CustomerName
,dc.Email
,dm.FirstName+' '+dm.LastName as Manager
,Occurred
,Amount
from Fact_CustomerAction ca
join Dim_Customer dc
on dc.RealCID = ca.RealCID
join Dim_Manager dm
on dm.ManagerID = dc.AccountManagerID
where ActionTypeID = 9 and BonusTypeID = 71