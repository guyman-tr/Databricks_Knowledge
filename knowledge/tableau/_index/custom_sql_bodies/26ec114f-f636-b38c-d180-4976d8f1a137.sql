WITH filtered AS (
  SELECT
    ca.GCID,
    q.QuestionShortDescription,
    ca.OccurredAt,
    a.AnswerText
  FROM main.compliance.bronze_userapidb_kyc_customeranswers ca
  JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked g
    ON ca.GCID = g.GCID
   AND g.RegulationID            IN (6,7,8,12)
   AND g.VerificationLevelID     = 3
   and g.IsValidCustomer=1
  JOIN main.compliance.bronze_userapidb_kyc_answers a
    ON ca.AnswerId = a.AnswerId
  join main.compliance.bronze_userapidb_kyc_questions q 
    on ca.QuestionId=q.QuestionId  
  WHERE ca.QuestionId = 27
),
latest_ts AS (
  SELECT
    GCID,
    MAX(OccurredAt) AS MaxOccurredAt
  FROM filtered
  GROUP BY GCID
)
SELECT
  f.GCID,
  concat_ws(', ', collect_list(f.AnswerText)) AS `Planned Investments`
FROM filtered f
  JOIN latest_ts l
    ON f.GCID = l.GCID
   AND f.OccurredAt = l.MaxOccurredAt
GROUP BY f.GCID