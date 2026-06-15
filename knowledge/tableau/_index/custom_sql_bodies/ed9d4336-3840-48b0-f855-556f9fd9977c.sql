SELECT fsc.RealCID,
a.amount_in_unit_decimal,
a.amount_in_unit_decimal_70,
a.amount_in_unit_decimal_30,

a.amount_per_month,

fsc.GCID,
dc1.Name 'Country',
dps.Name 'PlayerStatus',
dpsr.Name 'PlayerStatusReason',
das.AccountStatusName,
dpssr.PlayerStatusSubReasonName 'PlayerStatusSubReason',
dr1.Name 'Regulation'
from [ThirdParty_Fivetran].[Fivetran].[google_sheets].[luna_cids_jan_2023] a
  left JOIN DWH..Dim_Customer fsc ON fsc.RealCID=a.cid
 
 left JOIN DWH..Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
 left JOIN DWH..Dim_Country dc1 ON fsc.CountryID = dc1.CountryID
 left JOIN DWH..Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID
 left JOIN DWH..Dim_PlayerStatusReasons dpsr ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
 left JOIN DWH..Dim_AccountStatus das ON fsc.AccountStatusID = das.AccountStatusID
 LEFT JOIN DWH..Dim_PlayerStatusSubReasons dpssr ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID