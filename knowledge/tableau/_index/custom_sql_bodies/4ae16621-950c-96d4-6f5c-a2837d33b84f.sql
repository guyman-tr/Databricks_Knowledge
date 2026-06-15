select ver.*, v.FirstDepositAmount, dr.Name as Regulation,
psr.Name as PlayerStatusReason,
ps.Name as PlayerStatus
from [BI_DB_dbo].[BI_DB_VerificationStatus] ver
left join [BI_DB_dbo].BI_DB_CIDFirstDates v
on v.CID = ver.RealCID
left join DWH_dbo.Dim_Regulation dr on dr.ID=v.RegulationID
left join DWH_dbo.Dim_PlayerStatus ps on ps.PlayerStatusID=ver.PlayerStatusID
left join DWH_dbo.Dim_PlayerStatusReasons psr on psr.PlayerStatusReasonID=ver.PlayerStatusReasonID