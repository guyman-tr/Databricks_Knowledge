select 
ca.* ,
op.GCID, 
cc.RealCID,
dc.Name as Country,
pl.Name as Club, 
ps.Name as PlayerStatus,
r.Name as Regulation,
r2.Name as DesignatedRegulation
from FTDs ca
JOIN main.general.bronze_usabroker_apex_options op
    ON ca.AccountNumber=op.OptionsApexID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked cc on cc.GCID=op.GCID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc on dc.CountryID=cc.CountryID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel pl on pl.PlayerLevelID=cc.PlayerLevelID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=cc.PlayerStatusID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID=cc.RegulationID
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r2 on r2.ID=cc.DesignatedRegulationID