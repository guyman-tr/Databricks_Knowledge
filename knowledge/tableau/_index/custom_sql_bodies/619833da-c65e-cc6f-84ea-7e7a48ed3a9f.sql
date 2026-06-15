SELECT distinct op.GCID, op.OptionsApexID, am.OpenDDate as OpenDate,
  dr.Name as Regulation,
  op.ReasoningFormID
  , CAST(orf.DateSubmitted AS DATE) DateSubmitted
  , orf.PreviousAppropriatenessTestDate
  --, orfqa.OldKycAnswerID
  , orfqa.KycQuestionID,q.QuestionText, a.AnswerText as OldAnswerText
  , orfqa.ReasoningFormAnswerID
  , case when orfqa.ReasoningFormAnswerID=1 then 'Other'
    when orfqa.ReasoningFormAnswerID=2 then 'Incorrect Selection'
    when orfqa.ReasoningFormAnswerID=3 then 'Changed Mind'
    when orfqa.ReasoningFormAnswerID=4 then 'Lifestyle Change'
    end as ReasoningFormAnswer
  
FROM main.general.bronze_usabroker_apex_options op
left join main.general.bronze_sodreconciliation_apex_ext765_accountmaster am on op.OptionsApexID=am.AccountNumber
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_customer_masked dc on op.GCID=dc.GCID
join dwh.gold_sql_dp_prod_we_dwh_dbo_dim_regulation dr on dr.ID=dc.RegulationID
join bi_db.bronze_usabroker_apex_optionsreasoningform orf
  on op.ReasoningFormID = orf.ReasoningFormID
join bi_db.bronze_usabroker_apex_optionsreasoningformquestionsanswers orfqa
  on op.ReasoningFormID = orfqa.ReasoningFormID
join main.compliance.bronze_userapidb_kyc_questions q on orfqa.KycQuestionID=q.questionid
join main.compliance.bronze_userapidb_kyc_answers a on a.answerid=orfqa.OldKycAnswerID
--where orf.DateSubmitted is not null