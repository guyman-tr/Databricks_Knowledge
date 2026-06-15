select 
CI.GCID,
C.RealCID,
CI.IsActive,
CI.InsertTime as GapOpenDate,
CI.CompletedDate as GapCloseDate,
case when  CI.IsActive=false and CI.IsCompleted=false then 'Cancelled'
WHEN CI.IsCompleted =0 then 'Pending' else 'Completed' end as GapClosed,
country.Name as Country,
ps.Name as PlayerStatus,
C.RegisteredReal AS RegistrationDate,
CI.DisplayName as APUGap,
CS.PendingClosureStatusName,
SS.Name AS ScreeningStatus,
C.VerificationLevelID,
psr.Name as PlayerStatusReason,
pssr.PlayerStatusSubReasonName as PlayerStatusSubReason,
ems.EvMatchStatusName as EVMatchStatus,
dr.Name as DesignatedRegulation,
CASE WHEN l.Liabilities + l.ActualNWA>0 then 'Yes' else 'No' end as HasEquity,
pl1.Name as Club,
a.managername
from 
main.compliance.bronze_compliancestatedb_compliance_customerinteractions CI 
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked C ON CI.GCID=C.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country country on country.CountryID=C.CountryID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=C.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl1 on pl1.PlayerLevelID=C.PlayerLevelID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_pendingclosurestatus CS ON CS.PendingClosureStatusID=C.PendingClosureStatusID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_screeningstatus SS ON SS.ScreeningStatusID=C.ScreeningStatusID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatusreasons psr on psr.PlayerStatusReasonID=C.PlayerStatusReasonID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatussubreasons pssr on pssr.PlayerStatusSubReasonID=C.PlayerStatusSubReasonID
left JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_evmatchstatus ems on ems.EvMatchStatusID = C.EvMatchStatus
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID=C.DesignatedRegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities l on l.CID = C.RealCID and DateID = date_format(date_sub(current_date(), 1), 'yyyyMMdd')
LEFT JOIN (
    SELECT
        BAAC.GCID,  
        BMAN.FirstName || ' ' || BMAN.LastName AS ManagerName,
        DAAT.AuditActionTypeName,
        BAAC.ActionTime,
        BAAC.AuditActionParameters,
        ROW_NUMBER() OVER (PARTITION BY BAAC.GCID ORDER BY ActionTime DESC) AS RN
    FROM main.general.bronze_db_logs_backoffice_auditaction BAAC 
    JOIN main.general.bronze_etoro_dictionary_auditactiontype DAAT 
      ON BAAC.AuditActionTypeID = DAAT.AuditActionTypeID 
      AND DAAT.AuditActionTypeID = 361 -- OpenApuFlowGap
    LEFT JOIN main.billing.bronze_etoro_backoffice_manager BMAN 
      ON BAAC.ManagerID = BMAN.ManagerID
) a on a.gcid = CI.GCID and cast(a.actiontime as date) = cast(CI.InsertTime as date)
where CI.DisplayName is not null AND C.IsValidCustomer=1