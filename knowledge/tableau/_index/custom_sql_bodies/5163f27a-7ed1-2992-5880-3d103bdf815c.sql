with log as (
select CId AS CID,ActionID,ActionTime,aud.ManagerID,concat(dm.FirstName,' ',dm.LastName) AS Manager
from main.general.bronze_db_logs_backoffice_auditaction aud
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm 
on aud.ManagerID = dm.ManagerID
where  AuditActionTypeID in (367,35)
),
upgrades as (
select CID
       ,prev_PlayerLevel
       ,PlayerLevel
       ,ValidFrom
from (
        SELECT
            c.CID,
            c.ValidFrom,
            -- current values (after joins to resolve names)
            dpl.Name AS PlayerLevel,
            c.GCID,
            -- previous values per column (LAG over history order)
            LAG(dpl.Name) OVER (PARTITION BY c.CID ORDER BY c.ValidFrom, c.CustomerVersionID)  AS prev_PlayerLevel
        FROM general.bronze_etoro_history_customer_masked c 
        LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel   dpl  
        ON c.PlayerLevelID          = dpl.PlayerLevelID
)q0
where prev_PlayerLevel != PlayerLevel
),
managers as
(
SELECT ManagerID 
FROM main.bi_db.bronze_etoro_backoffice_managertopermission
where permissionID in (19)
group by ManagerID
)
select lg.CID
       ,lg.Manager
       ,lg.ActionTime LogDate
       ,up.ValidFrom UpgradeDate
       ,up.PlayerLevel
       ,up.prev_PlayerLevel prev_PlayerLevel
from log lg 
inner join managers m on m.ManagerID=lg.ManagerID
inner join upgrades up on lg.CID=up.CID
and ABS(date_diff(minute,ValidFrom ,ActionTime )) <10
and up.prev_PlayerLevel != 'N/A'