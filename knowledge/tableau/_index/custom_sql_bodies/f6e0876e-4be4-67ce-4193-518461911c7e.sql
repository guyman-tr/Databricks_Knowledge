select fca.RealCID CID
  ,fsc.GCID
  ,dm.ParentUserName
  ,dm.ParentCID 
  ,fca.Occurred ActionDate
  ,SUM(CASE WHEN fca.ActionTypeID IN (16, 18) THEN (-1*fca.Amount) ELSE 0 END) AS `MoneyOut`
  ,SUM(CASE WHEN fca.ActionTypeID IN (15, 17) THEN (-1*fca.Amount) ELSE 0 END) AS `MoneyIn`
  ,dc2.Name AS Country
  ,dc2.MarketingRegionManualName AS Region
  ,dpl.Name AS Club
  ,dm1.ManagerID
  ,CONCAT(dm1.FirstName, ' ', dm1.LastName) AS Manager
  ,reg.Name AS Regulation
  ,dc.IsCreditReportValidCB
  ,dm.MirrorId
  FROM  main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_customeraction fca 
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirror dm
  ON fca.MirrorID = dm.MirrorID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_mirrortype dmt
  ON dm.MirrorTypeID = dmt.MirrorTypeID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc 
  on fsc.RealCID=fca.RealCID and  fca.DateID between fsc.FromDateID and fsc.ToDateID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
  ON dc.RealCID=fca.RealCID
  INNER JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc2 
  ON dc.CountryID = dc2.CountryID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel dpl 
  ON dc.PlayerLevelID = dpl.PlayerLevelID
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_manager dm1 
  ON dc.AccountManagerID = dm1.ManagerID
  LEFT JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities vl 
  ON vl.CID=fca.RealCID AND vl.DateID=20241029 
  INNER JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation reg 
  ON dc.RegulationID = reg.ID
  WHERE  
  fca.DateID>= 20241029 
  
  AND fca.ActionTypeID IN (15, 16, 17, 18)
  AND dm.ParentCID  in (40566884,40568225) 
  AND fsc.IsValidCustomer=1 
  GROUP BY fca.RealCID 
  ,fsc.GCID
  ,dm.ParentUserName
  ,dm.ParentCID 
  ,fca.Occurred
  ,dc2.Name 
  ,dc2.MarketingRegionManualName 
  ,dpl.Name
  ,dm1.ManagerID
  ,CONCAT(dm1.FirstName, ' ', dm1.LastName) 
  ,vl.Credit 
  ,reg.Name
  ,dc.IsCreditReportValidCB
  ,dm.MirrorId