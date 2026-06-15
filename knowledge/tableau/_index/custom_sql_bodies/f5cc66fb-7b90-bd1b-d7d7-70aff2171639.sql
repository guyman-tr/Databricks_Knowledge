WITH ClientRelations AS (
    SELECT 
        a.Gcid,
        dc.RealCID AS CID,  
        dc.RegulationID,
        dr.Name AS Regulation,
        dps.Name AS PlayerStatus,
        rr.RiskScoreName,
        a.MatchType,
        SUM(CASE WHEN rr2.RiskScoreName ='High' THEN 1 ELSE 0 END) AS HighRisk,
        COUNT(DISTINCT dc2.RealCID) AS Related_Accounts_Count
    FROM 
    (SELECT DISTINCT 
        rt.Gcid,  
        col.RelationGcid AS RelationGcid,
        col.MatchReason AS MatchReason,
        col.MatchType AS MatchType
     FROM main.general.bronze_relationservice_audit rt
     LATERAL VIEW explode(rt.Relations) relation AS col 
    ) a
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc2 
        ON a.RelationGcid = dc2.GCID 
        AND dc2.IsValidCustomer = 1         
        AND dc2.VerificationLevelID > 1      
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
        ON a.Gcid = dc.GCID 
        AND dc.IsValidCustomer = 1 
        AND dc.IsDepositor =1
        AND dc.VerificationLevelID > 1
        AND dc.RegulationID NOT IN (0,3,5,6)     
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
        ON dc.RegulationID = dr.DWHRegulationID
    JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps 
        ON dc.PlayerStatusID = dps.PlayerStatusID
    LEFT JOIN main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake rr on dc.Gcid = rr.Gcid
    LEFT JOIN main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake rr2 on dc2.Gcid = rr2.Gcid
    GROUP BY a.Gcid, dc.RealCID, a.MatchType, dc.RegulationID, dr.Name, dps.Name,rr.RiskScoreName
)
SELECT 
    Gcid, 
    CID, 
    Regulation,
    PlayerStatus,
    RiskScoreName,
    MatchType, 
    HighRisk,
    Related_Accounts_Count
FROM ClientRelations
WHERE Related_Accounts_Count > 1
--ORDER BY Related_Accounts_Count DESC;