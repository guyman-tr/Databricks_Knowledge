WITH RankedAnswers AS (
    SELECT 
        cc.QuestionId,   
         qq.QuestionShortDescription, 
         qq.QuestionText,  
        bb.AnswerText,
        cc.OccurredAt_InSource,
        dc.RealCID as CID,
        dc.GCID AS GCID,
        ROW_NUMBER() OVER (PARTITION BY cc.QuestionId ORDER BY cc.OccurredAt_InSource) AS RowNum
    FROM 
        main.compliance.bronze_userapidb_history_customeranswers cc
    left JOIN 
        main.compliance.bronze_userapidb_kyc_answers bb 
        ON cc.AnswerId = bb.AnswerId
        LEFT join main.compliance.bronze_userapidb_kyc_questions qq on cc.QuestionId = qq.QuestionId
        join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.GCID = cc.GCID AND dc.IsValidCustomer=1 AND dc.VerificationLevelID >1

WHERE dc.RealCID = <[Parameters].[Parameter 1]>
),
AnswerChanges AS (
    SELECT 
        ra1.QuestionId,
        ra1.AnswerText AS PreviousAnswer,
         ra1.QuestionShortDescription, 
         ra1.QuestionText,  
       ra1.CID,
       ra1.GCID,
        ra2.AnswerText AS CurrentAnswer,
        ra2.OccurredAt_InSource AS ChangeTimestamp

    FROM 
        RankedAnswers ra1
   left JOIN 
        RankedAnswers ra2
    ON 
        ra1.QuestionId = ra2.QuestionId
        AND ra1.RowNum + 1 = ra2.RowNum
    WHERE 
        ra1.AnswerText <> ra2.AnswerText
)
SELECT 
    QuestionId,
 QuestionShortDescription, 
         QuestionText,     
CID,
GCID,
    PreviousAnswer,
    CurrentAnswer,
    ChangeTimestamp
FROM 
    AnswerChanges