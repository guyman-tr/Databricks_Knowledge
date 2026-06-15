WITH snaps AS (
  SELECT
    GCID,
    QuestionId,
    OccurredAt,
    max(QuestionText)                    AS QuestionText,
    sort_array(collect_list(AnswerId))   AS AnswerIds,
    sort_array(collect_list(AnswerText)) AS AnswerTexts
  FROM main.bi_db.bronze_userapidb_dbo_v_customeranswers_masked
  GROUP BY GCID, QuestionId, OccurredAt
),

ranked AS (
  SELECT
    *,
    ROW_NUMBER() OVER (
      PARTITION BY GCID, QuestionId
      ORDER BY OccurredAt DESC
    ) AS rn
  FROM snaps
),

cur AS (
  SELECT * FROM ranked WHERE rn = 1   -- latest snapshot per question
),
prev AS (
  SELECT * FROM ranked WHERE rn = 2   -- the one immediately before it
),
final as (


SELECT
  cur.GCID,
  prev.OccurredAt   AS OldChangeDate,
  cur.OccurredAt    AS NewChangeDate,
  cur.QuestionId,

  prev.QuestionText AS Question_Old,
  cur.QuestionText  AS Question_New,

  prev.AnswerIds    AS AnswerIds_Old,
  cur.AnswerIds     AS AnswerIds_New,

  prev.AnswerTexts  AS AnswerTexts_Old,
  cur.AnswerTexts   AS AnswerTexts_New,
    dc.RealCID,
    dc.VerificationLevelID,
    ps.Name as Club,
    dr.Name AS Regulation,
    l.Liabilities + l.ActualNWA AS Equity

FROM cur
JOIN prev
  ON cur.GCID       = prev.GCID
 AND cur.QuestionId = prev.QuestionId
 left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on dc.GCID=cur.GCID
 left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_playerlevel ps on ps.PlayerLevelID=dc.PlayerLevelID
 left join main.dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID=dc.RegulationID
 LEFT JOIN  main.dwh.gold_sql_dp_prod_we_dwh_dbo_v_liabilities l on l.CID = dc.RealCID and DateID = date_format(date_sub(current_date(), 1), 'yyyyMMdd')
WHERE
  -- only true changes...
  (cur.QuestionText <> prev.QuestionText
   OR cur.AnswerIds  <> prev.AnswerIds
   OR cur.AnswerTexts<> prev.AnswerTexts)
  -- ...and only where the *new* snapshot falls on 2024-01-23
  AND date(cur.OccurredAt) >= DATE '2025-01-01'
ORDER BY
  cur.GCID,
  cur.QuestionId)
  , 

  totaldeposits as (
    select distinct fbd.CID as RealCID, sum(fbd.AmountUSD) as TotalDeposits
    from main.dwh.gold_sql_dp_prod_we_dwh_dbo_fact_billingdeposit fbd 
where fbd.PaymentStatusID=2
group by fbd.CID
  )

  select
    f.*,
    td.TotalDeposits
  from final f
left join totaldeposits td on td.RealCID=f.RealCID