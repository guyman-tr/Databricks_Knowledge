select pc.Date,
       pc.CID,
       dc1.CountryID,
	     dc1.Name AS Country_Name,
	     dc1.Region, 
	     dc.PlayerLevelID, 
	     dpl.Name AS Club,  
	     dgs.GuruStatusName, 
	     dr.Name AS Regulation, 
       dc.AccountManagerID, 
       COALESCE(dm.FirstName, '') || ' ' || COALESCE(dm.LastName, '') AS AccountManager 
from main.bi_dealing.bi_output_dealing_premier_customer pc
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID=pc.CID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc1  ON dc.CountryID=dc1.CountryID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr ON dc.RegulationID=dr.DWHRegulationID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl on dc.PlayerLevelID = dpl.PlayerLevelID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_gurustatus dgs on  dc.GuruStatusID = dgs.GuruStatusID
LEFT join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm on dc.AccountManagerID=dm.ManagerID