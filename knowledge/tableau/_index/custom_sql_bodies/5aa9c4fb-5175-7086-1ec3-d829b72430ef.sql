WITH pop AS (
  SELECT a.GCID
  ,a.CID
      ,a.RegulationID AS Current_ID
      ,dps.Name AS Current_Regulation   
      ,a.Previous_RegulationID AS Previous_ID
      ,pps.Name AS Previous_Regulation
      ,a.Change_Date
      ,a.Is_FTD      
      ,ROW_NUMBER() OVER (PARTITION BY a.CID ORDER BY a.Change_Date DESC) AS RowNum
  FROM (
    SELECT fsc.RealCID AS CID
    ,fsc.GCID
          ,CASE WHEN fsc.IsDepositor = 1 THEN 1 ELSE 0 END AS Is_FTD
          ,fsc.RegulationID 
          ,TO_DATE(CAST(dr.FromDateID AS STRING), 'yyyyMMdd') AS Change_Date            
          ,LAG(fsc.RegulationID, 1, 0) OVER(PARTITION BY fsc.RealCID ORDER BY dr.FromDateID ASC) AS Previous_RegulationID
    FROM 
      dwh.gold_sql_dp_prod_we_dwh_dbo_v_fact_snapshotcustomer_fromdateid_masked fsc
    INNER JOIN 
      main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_range dr ON fsc.DateRangeID = dr.DateRangeID
    WHERE 
      fsc.IsValidCustomer = 1            
  ) a

  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dps ON a.RegulationID = dps.ID
  INNER JOIN 
    dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation pps ON a.Previous_RegulationID = pps.ID

  WHERE 
    a.RegulationID <> a.Previous_RegulationID
)

,cids as (
SELECT DISTINCT
    p.GCID
    ,p.CID
    ,p.Previous_Regulation
    ,p.Change_Date
    ,p.Current_Regulation
FROM 
  pop p
WHERE 
  p.RowNum = 1
  and p.change_date >= '2025-04-05'
  and p.Previous_Regulation in ('ASIC & GAML','ASIC')
)


Select 
    c.GCID
    ,c.CID
    ,c.Previous_Regulation
    ,c.Change_Date
    ,c.Current_Regulation
    ,t.CaseNumber
    ,t.CreatedDate
    ,t.Origin
    ,t.Sub_Type
    ,t.Sub_Type_2
    ,t.Status
    ,t.OwnerRoleName
from 
    cids c 
Left JOIN 
    bi_output.bi_output_customer_customer_support_case t ON t.CID = c.CID
                                                        AND CAST(t.CreatedDate as Date) >= c.Change_Date