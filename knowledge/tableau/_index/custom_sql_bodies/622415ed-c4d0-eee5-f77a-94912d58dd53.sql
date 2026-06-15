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
from [BI_DB_dbo].[External_Fivetran_luna_cids_jan_2023] a
  left JOIN DWH_dbo.Dim_Customer fsc ON fsc.RealCID=a.cid
 
 left JOIN DWH_dbo.Dim_Regulation dr1 ON dr1.DWHRegulationID=fsc.RegulationID
 left JOIN DWH_dbo.Dim_Country dc1 ON fsc.CountryID = dc1.CountryID
 left JOIN DWH_dbo.Dim_PlayerStatus dps ON fsc.PlayerStatusID = dps.PlayerStatusID
 left JOIN DWH_dbo.Dim_PlayerStatusReasons dpsr ON fsc.PlayerStatusReasonID = dpsr.PlayerStatusReasonID
 left JOIN DWH_dbo.Dim_AccountStatus das ON fsc.AccountStatusID = das.AccountStatusID
 LEFT JOIN DWH_dbo.Dim_PlayerStatusSubReasons dpssr ON fsc.PlayerStatusSubReasonID = dpssr.PlayerStatusSubReasonID