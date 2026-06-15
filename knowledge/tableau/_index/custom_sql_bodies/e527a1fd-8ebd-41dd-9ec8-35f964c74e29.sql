select t1.GCID,t1.AnswerId,t1.QuestionId,t2.AnswerText,t3.QuestionText,t1.OccurredAt
from main.compliance.bronze_userapidb_kyc_customeranswers t1
inner join main.compliance.bronze_userapidb_kyc_answers t2
on t1.AnswerId = t2.AnswerId
inner join main.compliance.bronze_userapidb_kyc_questions t3
on t1.QuestionId = t3.QuestionId
where t1.OccurredAt = (
    SELECT MAX(OccurredAt)
    FROM main.compliance.bronze_userapidb_kyc_customeranswers
    WHERE GCID = t1.GCID AND QuestionId = t1.QuestionId
) and t3.QuestionId in (9,10,11,27,8,3,33,34,35,2,5,14,18)