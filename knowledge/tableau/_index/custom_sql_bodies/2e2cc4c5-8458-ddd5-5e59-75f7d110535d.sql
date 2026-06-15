WITH RankedData AS (
    SELECT 
        cc.*,      
        qq.QuestionShortDescription, 
        qq.QuestionText, 
        bb.AnswerShortDescription, 
        bb.AnswerText,
        dc.IsDepositor,
        dc.VerificationLevelID,
        dps.Name AS PlayerStatus, 
        dr.Name AS Regulation, 
        dc.RealCID AS CID,
        ROW_NUMBER() OVER (PARTITION BY cc.QuestionId ORDER BY cc.OccurredAt DESC) AS RowNum
    FROM  
        main.compliance.bronze_userapidb_kyc_customeranswers cc
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc 
        ON dc.GCID = cc.GCID 
        AND dc.IsValidCustomer = 1 
        AND dc.VerificationLevelID > 1
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerstatus dps 
        ON dps.PlayerStatusID = dc.PlayerStatusID
    JOIN 
        main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr 
        ON dr.DWHRegulationID = dc.RegulationID
    LEFT JOIN 
        main.compliance.bronze_userapidb_kyc_answers bb 
        ON cc.AnswerId = bb.AnswerId
    LEFT JOIN 
        main.compliance.bronze_userapidb_kyc_questions qq 
        ON cc.QuestionId = qq.QuestionId
    WHERE 
        dc.RealCID = <[Parameters].[Parameter 1]>
)
SELECT *
FROM RankedData
WHERE RowNum = 1