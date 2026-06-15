select
sc.*,
dc1.Name as KYCCountry,
dr.Name as Regulation, 
dr1.Name as DesignatedRegulation,
ps.Name as PlayerStatus,
usc.IsOngoingCase
,dc.VerificationlevelID
from bi_db.bronze_screeningservice_screening_extendedhitsdata sc
join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID=sc.CID
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1 on dc1.CountryID=dc.CountryID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID=dc.RegulationID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr1 on dr1.ID=dc.DesignatedRegulationID
left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus ps on ps.PlayerStatusID=dc.PlayerStatusID
left join bi_db.bronze_screeningservice_screening_userscreening usc on usc.CID=sc.CID