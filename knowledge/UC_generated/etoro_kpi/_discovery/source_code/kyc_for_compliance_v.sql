-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.etoro_kpi.kyc_for_compliance_v
-- Captured: 2026-05-19T15:17:19Z
-- ==========================================================================

Select aa.GCID
      ,c.CID
      ,aa.OccurredAt
      ,aa.QuestionId
      ,q.QuestionText
      ,aa.AnswerId
      ,a.AnswerText
      ,aa.Is_Current
from (select c.GCID, c.OccurredAt, c.QuestionId, c.AnswerId, 1 as Is_Current
      from main.compliance.bronze_userapidb_kyc_customeranswers c
        union all 
      select h.GCID, h.OccurredAt_InSource AS OccurredAt, h.QuestionId, h.AnswerId, 0 as Is_Current
      from main.compliance.bronze_userapidb_history_customeranswers h
     )aa
left join compliance.bronze_userapidb_kyc_questions q
on aa.QuestionId = q.QuestionId   
left join compliance.bronze_userapidb_kyc_answers a
on aa.AnswerId = a.AnswerId
inner join main.general.bronze_etoro_customer_customer_masked c ON(c.GCID = aa.GCID)
