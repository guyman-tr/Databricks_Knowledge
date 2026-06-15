SELECT  a.Gcid
    ,dc.RealCID AS CID  
    ,dc.FirstName
    ,dc.MiddleName
    ,dc.LastName
    ,dc.Email
    ,dc.Phone    
    ,rr.RiskScoreName
    ,dr.Name as Regulation
    ,dps.Name as PlayerStatus 
    ,dc.IsValidCustomer
    ,dc.VerificationLevelID
    ,dc.IsDepositor
    ,dc.HasWallet
    ,dc3.Name AS Country
    ,dc.FirstDepositAmount  
    ,CAST(dc.BirthDate AS DATE) BirthDate
    ,CAST(dc.RegisteredReal AS DATE) RegisteredReal
    ,CAST(dc.FirstDepositDate AS DATE) FirstDepositDate
    ,a.MatchReason
    ,a.MatchType
    ,a.RelationGcid AS Relation_Gcid
    ,dc2.RealCID AS Relation_CID  
    ,dc2.FirstName AS Relation_FirstName
    ,dc2.MiddleName AS Relation_MiddleName
    ,dc2.LastName  AS Relation_LastName
    ,dc2.Email AS Relation_Email
    ,dc2.Phone  AS Relation_Phone
    ,rr2.RiskScoreName AS Relation_RiskScoreName
    ,dr2.Name AS Relation_Regulation
    ,dps2.Name as Relation_PlayerStatus 
    ,dc2.IsValidCustomer AS Relation_IsValidCustomer
    ,dc2.VerificationLevelID AS Relation_VerificationLevelID
    ,dc2.IsDepositor AS Relation_IsDepositor
    ,dc2.HasWallet AS Relation_HasWallet
    ,dc4.Name AS Relation_Country
    ,dc2.FirstDepositAmount AS Relation_FirstDepositAmount
    ,CAST(dc2.BirthDate AS DATE) Relation_BirthDate
     ,CAST(dc2.RegisteredReal AS DATE) Relation_RegisteredReal
    ,CAST(dc2.FirstDepositDate AS DATE) Relation_FirstDepositDate
FROM 
(SELECT DISTINCT rt.Gcid,  
  col.RelationGcid AS RelationGcid,
  col.MatchReason AS MatchReason,
  col.Matchtype AS MatchType
FROM  main.general.bronze_relationservice_audit rt
LATERAL VIEW explode(rt.Relations) relation AS col
)a
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc2 ON a.RelationGcid = dc2.GCID
        AND dc2.IsValidCustomer = 1       
        AND dc2.VerificationLevelID > 1      
JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc ON a.Gcid = dc.Gcid
        AND dc.IsValidCustomer = 1 
        AND dc.IsDepositor =1
        AND dc.VerificationLevelID > 1
        AND dc.RegulationID NOT IN (0,3,5,6)     
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dc.RegulationID = dr.DWHRegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr2 on dc2.RegulationID = dr2.DWHRegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps ON dc.PlayerStatusID = dps.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps2 ON dc2.PlayerStatusID = dps2.PlayerStatusID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc3 ON dc.CountryID = dc3.CountryID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country dc4 ON dc2.CountryID = dc4.CountryID
LEFT JOIN main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake rr on dc.Gcid = rr.Gcid
LEFT JOIN main.bi_db.bronze_riskclassification_dbo_v_riskclassificationdatalake rr2 on dc2.Gcid = rr2.Gcid
WHERE dc.RealCID = <[Parameters].[Parameter 1]>