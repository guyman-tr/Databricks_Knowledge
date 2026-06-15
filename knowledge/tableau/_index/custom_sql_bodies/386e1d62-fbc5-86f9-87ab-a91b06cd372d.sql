WITH base AS (
  SELECT
      hc.GCID, op.OptionsApexID,
      dc.RealCID, dr.Name as Regulation,
      hc.QuestionId,
      q.QuestionText,
      hc.AnswerId,
      an.AnswerText,
      MIN(hc.OccurredAt)          AS FirstAnswerDate,
      MIN(hc.OccurredAt_InSource) AS FirstAnswerDate_InSource
  FROM main.compliance.bronze_userapidb_history_customeranswers hc
  JOIN main.compliance.bronze_userapidb_kyc_questions q
    ON hc.QuestionId = q.QuestionId
  JOIN main.compliance.bronze_userapidb_kyc_answers an
    ON hc.AnswerId = an.AnswerId
  JOIN dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc
    ON hc.GCID = dc.GCID
   AND dc.VerificationLevelID = 3
   AND dc.RegulationID IN (6,7,8,12)
   AND dc.IsValidCustomer = 1    
  join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr
    on dr.ID=dc.RegulationID
  LEFT JOIN main.general.bronze_usabroker_apex_options op
    ON op.GCID = dc.GCID
  WHERE hc.QuestionId IN (15, 26)
  GROUP BY
      hc.GCID, dc.RealCID, op.OptionsApexID, hc.QuestionId, q.QuestionText,
      hc.AnswerId, an.AnswerText, dr.Name
),
changed AS (            -- customers/questions with multiple distinct answers
  SELECT GCID, QuestionId
  FROM base
  GROUP BY GCID, QuestionId
  HAVING COUNT(DISTINCT AnswerId) > 1
),
distinct_minutes AS (   -- among those rows, multiple distinct first-answer minutes
  SELECT GCID, QuestionId
  FROM (
     SELECT
       GCID, QuestionId,
       DATE_TRUNC('minute', FirstAnswerDate) AS first_minute
     FROM base
     -- each row in base is per (GCID, QuestionId, AnswerId), with its FirstAnswerDate
     GROUP BY GCID, QuestionId, AnswerId, DATE_TRUNC('minute', FirstAnswerDate)
  ) m
  GROUP BY GCID, QuestionId
  HAVING COUNT(DISTINCT first_minute) > 1
),
recent AS (             -- GCIDs with any first answer in the last 30 days
  SELECT DISTINCT GCID
  FROM base
  WHERE FirstAnswerDate >= date_sub(current_date(), 30)
)
SELECT
    b.GCID, b.Regulation,
    b.RealCID,
    b.OptionsApexID,
    b.QuestionId,
    b.QuestionText,
    b.AnswerId,
    b.AnswerText,
    b.FirstAnswerDate,
    b.FirstAnswerDate_InSource
FROM base b
JOIN changed c
  ON b.GCID = c.GCID AND b.QuestionId = c.QuestionId
JOIN distinct_minutes dm
  ON b.GCID = dm.GCID AND b.QuestionId = dm.QuestionId
JOIN recent r
  ON b.GCID = r.GCID
-- ORDER BY b.GCID, b.QuestionId, b.FirstAnswerDate