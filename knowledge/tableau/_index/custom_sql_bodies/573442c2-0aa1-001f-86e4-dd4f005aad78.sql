SELECT DISTINCT 
    st.Name AS ChatID,
    st.CaseId,
LiveChatTranscriptId,
    CAST(t1.Time AS date) AS Date,
    t1.Time AS Datetime,
st.EndTime,
t1.Type,
 TIMESTAMPDIFF(MINUTE, DateTime, lt.EndTime) AS WaitTime,
 st.Original_Skillset__c
FROM
    crm.silver_crm_livechattranscriptevent t1
LEFT JOIN
bi_output.bi_output_customer_customer_support_live_chat_transcript lt

ON 
    lt.ChatID = t1.LiveChatTranscriptId
LEFT JOIN
(SELECT *
FROM (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY Name ORDER BY LastModifiedDate DESC) AS rn
    FROM crm.silver_crm_livechattranscript
) t
WHERE t.rn = 1
) st on  st.ID= t1.LiveChatTranscriptId

WHERE
    t1.Type in( 'TransferredToSbrSkill','TransferToSbrSkillFailed')
  
   AND YEAR(t1.Time) >= 2024
   and CAST(t1.Time as date) >='2024-01-01'
   AND st.OwnerId='00524000001JJbWAAW'