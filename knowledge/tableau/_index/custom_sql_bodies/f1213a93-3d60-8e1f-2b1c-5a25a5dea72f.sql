select 
CI.GCID,
C.RealCID,
CI.IsActive,
CI.InsertTime as GapOpenDate,
case when  CI.IsActive=false and CI.IsCompleted=false then 'Cancelled'
WHEN CI.IsCompleted =0 then 'Pending' else 'Completed' end as GapClosed,
country.Name as Country,
ps.Name as PlayerStatus,
C.RegisteredReal AS RegistrationDate,
CI.DisplayName as APUGap,
CS.PendingClosureStatusName,
ss.Name AS ScreeningStatus,
C.VerificationLevelID,
psr.Name as PlayerStatusReason,
pssr.PlayerStatusSubReasonName as PlayerStatusSubReason,
C.IsDepositor,
reg.Name as Regulation,
pl.Name as PlayerLevel,
cast(usc.LastUpdateDate as date) as ScreeningStatus_UpdateDate

from 
main.compliance.bronze_compliancestatedb_compliance_customerinteractions CI 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked C ON CI.GCID=C.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country country on country.CountryID=C.CountryID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=C.PlayerStatusID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus CS ON CS.PendingClosureStatusID=C.PendingClosureStatusID
left join main.bi_db.bronze_screeningservice_screening_userscreening usc on usc.CID=C.RealCID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus ss on ss.ScreeningStatusID=usc.ScreeningStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr on psr.PlayerStatusReasonID=C.PlayerStatusReasonID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr on pssr.PlayerStatusSubReasonID=C.PlayerStatusSubReasonID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation reg on reg.ID=C.RegulationID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on pl.PlayerLevelID=C.PlayerLevelID

where CI.DisplayName is not null AND C.IsValidCustomer=1