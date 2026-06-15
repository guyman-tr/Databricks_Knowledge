SELECT cc.CID as 'CID need CO Exemption'
, CASE WHEN dm.Name IN ('Africa','ROW','ROE','Eastern Europe','North Europe') THEN 'ROW'
WHEN dm.Name IN ('Arabic GCC','Arabic Other') THEN 'Arabic GCC & Other'
WHEN dm.Name IN ('China','Other Asia') THEN 'China & Other Asia'
WHEN dm.Name IN ('South & Central America','Spain') THEN 'Spanish' ELSE dm.Name END as Region
, dp.Name as Level
, dp.Sort
From [AZR-W-REAL-DB-2-BIDBUser].etoro.Customer.Customer  cc WITH (NOLOCK)
Join [AZR-W-REAL-DB-2-BIDBUser].etoro.BackOffice.Customer bc WITH (NOLOCK)
on bc.CID = cc.CID
Join [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.Country dc WITH (NOLOCK)
on dc.CountryID = cc.CountryID
Join [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.MarketingRegion dm WITH (NOLOCK)
on dm.MarketingRegionID = dc.MarketingRegionID
Join [AZR-W-REAL-DB-2-BIDBUser].etoro.Dictionary.PlayerLevel dp WITH (NOLOCK)
on dp.PlayerLevelID = cc.PlayerLevelID
Where CashoutFeeGroupID != 2   ---- 1 = Default 2 = Exempt 3 = Discounted
and cc.PlayerLevelID in (2,6,7)
and cc.PlayerStatusID not in (2,4,6,8,14)
and cc.CountryID !=250
and cc.LabelID !=30
and cc.CID not in (9981468,10147786,11216192)
Group by cc.CID, cc.UserName, dm.Name, dp.Name, dp.Sort