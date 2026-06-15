with cids as (
SELECT distinct
cc.RealCID,
dc.Name as Country,
cc.VerificationLevelID,
da.Name as AccountType,
ps.Name as PlayerStatus,
r.Name as DesignatedRegulation,
cast(fd.FirstDepositDate as date) as DepositDate,
cc.IsDepositor,
pl.Name as PlayerLevel,
r1.Name as Regulation
FROM  dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on cc.CountryID=dc.CountryID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on cc.PlayerStatusID=ps.PlayerStatusID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on cc.DesignatedRegulationID=r.ID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r1 on cc.RegulationID=r1.ID
LEFT JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_accounttype da on cc.AccountTypeID = da.AccountTypeID 
LEFT JOIN bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_cidfirstdates_masked fd on fd.CID = cc.RealCID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on pl.PlayerLevelID = cc.PlayerLevelID
WHERE cc.IsDepositor = 1
and cc.PlayerStatusID not in (2,4)
and cc.VerificationLevelID >= 2
)

,scrstatus as (
SELECT distinct
ci.*,
ss.Name as ScrStatus,
us.IsOngoingCase,
cast (us.LastUpdateDate as date) as ScreeningStatus_UpdateDate
FROM cids ci
LEFT JOIN bi_db.bronze_screeningservice_screening_userscreening us ON ci.RealCID=us.CID
LEFT JOIN bi_db.bronze_screeningservice_dictionary_screeningstatus ss ON ss.ID=us.ScreeningStatusID
)

select
scr.DepositDate,
scr.Country,
scr.VerificationLevelID,
scr.AccountType,
scr.PlayerStatus,
scr.DesignatedRegulation,
scr.ScrStatus,
scr.ScreeningStatus_UpdateDate,
scr.IsOngoingCase,
count (scr.RealCID) as CountOfCids,
scr.IsDepositor,
scr.PlayerLevel,
scr.Regulation
from scrstatus scr
group by
scr.DepositDate,
scr.Country,
scr.VerificationLevelID,
scr.AccountType,
scr.PlayerStatus,
scr.DesignatedRegulation,
scr.ScrStatus,
scr.IsOngoingCase,
scr.IsDepositor,
scr.ScreeningStatus_UpdateDate,
scr.PlayerLevel,
scr.Regulation