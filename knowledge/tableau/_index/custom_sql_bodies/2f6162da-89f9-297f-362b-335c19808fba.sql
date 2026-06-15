Select 
cc.RealCID as CID, 
cc.UserName, 
dc.Name As Country,
cc.FirstName, 
cc.LastName, 
cc.IP, 
cc.Email, 
cc.Phone, 
cc.Address, 
cc.City, 
cc.Zip, 
cc.RegisteredReal as Registered, 
cc.BirthDate,
ps.Name as PlayerStatus,
cc.Gender,
psr.Name  as PlayerStatusReason,
pssr.PlayerStatusSubReasonName PlayerStatusSubReason,
cc.AffiliateID,
bd.FundingID,
bd.ModificationDate as DepositDate
From DWH_dbo.Dim_Customer cc
join DWH_dbo.Dim_Country dc on cc.CountryID = dc.CountryID
join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=cc.PlayerStatusID
left join  DWH_dbo.Dim_PlayerStatusReasons psr on psr.PlayerStatusReasonID=cc.PlayerStatusReasonID
left join  DWH_dbo.Dim_PlayerStatusSubReasons pssr on pssr.PlayerStatusSubReasonID=cc.PlayerStatusSubReasonID
left join DWH_dbo.Fact_BillingDeposit bd on bd.CID=cc.RealCID
where (
(cc.FirstName in ('Davide') and cc.LastName in ('Resta') and cast(cc.RegisteredReal as date)>=cast(getdate()-1 as date)) 
or
(bd.FundingID IN (3595851,3595862) and bd.ModificationDate>=cast(getdate()-1 as date)))
or (cc.FirstName in ('Yoni') and cc.LastName in ('Assia') and cast(cc.RegisteredReal as date)>=cast(getdate()-1 as date))