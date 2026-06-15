SELECT 
    pr.*
FROM bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview pr
JOIN (
    SELECT RealCID, MIN(Review_Due_DateID) AS MinReviewDueDateID
    FROM bi_db.gold_sql_dp_prod_we_bi_db_dbo_bi_db_amlperiodicreview
    GROUP BY RealCID
) earliest
    ON pr.RealCID = earliest.RealCID
   AND pr.Review_Due_DateID = earliest.MinReviewDueDateID