SELECT 
t.TaskID
,CAST(
    regexp_extract(t.AIScoreJustification, 'Total score[: ]+(-?[0-9\\.]+)', 1) 
AS DOUBLE) as AI_Score
,cast(t.CreateDate as date) as CreateDate
,t.Priority
,t.AIPriority
,dc.VerificationLevelID
,t.IsActive
,t.TeamName
,r.Name as Regulation
,c.Name as Country
,o.Name as Outcome
FROM main.bi_db.bronze_assignment_assignment_v_tasks t
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.RealCID = t.CID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation r on r.ID = dc.RegulationID
LEFT JOIN main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_country c on c.CountryID = dc.CountryID
LEFT JOIN main.compliance.bronze_assignment_dictionary_outcome o on o.OutcomeID = t.OutcomeID
Where 
  t.CreateDate >= timestamp('2026-03-04 14:00:00')