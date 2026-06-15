select CreatedDate,Name,CaseId,l.Id,Original_Skillset__c,u.SubRole as DoneBy_Subrole,
case 
when Original_Skillset__c like '%General_Support%' then 'General Support/FS'
when Original_Skillset__c like '%Financial%' then 'General Support/FS'
when Original_Skillset__c like '%Cashout%' then 'Cashout'
when Original_Skillset__c like '%Trading%' then 'Trading'
when Original_Skillset__c like '%eToro_Money%' then 'etoro Money/Hacked'
when Original_Skillset__c like '%Hacked%' then 'etoro Money/Hacked'
else "Other" end as Skill


 from crm.silver_livechattranscript l
left join 
(
SELECT 
    le.LiveChatTranscriptId,
    le.AgentId AS first_agent,
    Time as FirstAction
FROM (
    SELECT 
        LiveChatTranscriptId,
        AgentId,
        Time,
        ROW_NUMBER() OVER (PARTITION BY LiveChatTranscriptId ORDER BY Time ASC) AS rn
    FROM crm.silver_livechattranscriptevent wHERE AgentId IS NOT NULL AND AgentId != '0050800000FCToKAAX' 
) le
WHERE rn = 1) LE on l.Id=LE.LiveChatTranscriptId 
LEFT JOIN bi_output.bi_output_customer_customer_support_agent_user U ON u.ID=le.first_agent AND CAST(LE.FirstAction as date) between cast(u.FromDate as date) and cast(u.ToDate as date)
WHERE CAST(CreatedDate AS DATE) >= '2024-01-01'
and Original_Skillset__c is not null
AND LE.first_agent is not null