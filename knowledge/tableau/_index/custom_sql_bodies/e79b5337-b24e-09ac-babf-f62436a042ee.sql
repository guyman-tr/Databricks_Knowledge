WITH Chats AS (
    SELECT DISTINCT 
        c.Time,
        c.LiveChatTranscriptId,
        Language,
        Country,
        CASE 
            WHEN c.Detail LIKE '%US%' THEN 'US'
            WHEN c.Detail LIKE '%General Support%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.Detail LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.Detail LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.Detail LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.Detail LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.Detail LIKE '%Technical%' THEN '7.Technical'
            WHEN c.Detail LIKE '%CS Marketing%' THEN '8.CS Marketing'
            WHEN c.Detail LIKE '%BU%' THEN '1.General Support'
            WHEN c.Detail LIKE '%Global%' THEN '1.General Support'
        END AS ChatSkill
    FROM crm.silver_crm_livechattranscriptevent c
    left join (select c.id,SiteLanguage__c as Language,  trim(element_at(split(location, ','), -1)) AS Country from crm.silver_crm_livechattranscript c) d on d.id = c.LiveChatTranscriptId
    WHERE
    --cast(Time as date)='2024-11-05' 
    YEAR(c.Time)>= 2024
    AND c.Detail NOT LIKE '%US%'
AND c.Detail NOT LIKE '%Cashout%'
and c.Detail NOT LIKE '%Deposit%'
)
,
GroupedChats AS (
    SELECT distinct
       Language,
        Country,
  
        ChatSkill,
        COUNT(Distinct LiveChatTranscriptId) AS ChatsIncoming,
        CAST(Time AS DATE) AS IncomingDate 
    FROM Chats
    WHERE ChatSkill IS NOT NULL
    GROUP BY  Language, 
        ChatSkill,
        Country, CAST(Time AS DATE)

),
  Cases AS (
    SELECT DISTINCT 
        c.CreatedDate,
        c.CaseId,
     
        CASE 
            WHEN c.NewValue LIKE '%US%' THEN 'US'
            WHEN c.NewValue LIKE '%General Support%' THEN '1.General Support'
            WHEN c.NewValue LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.NewValue LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.NewValue LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.NewValue LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.NewValue LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.NewValue LIKE '%Technical%' THEN '7.Technical'
            WHEN c.NewValue LIKE '%CS Marketing%' THEN '8.CS Marketing'
        END AS Skill,
        ServiceLanguage,
        Country
    FROM crm.silver_casehistory c
    left join bi_output.bi_output_customer_customer_support_case cc on cc.CaseId = c.CaseId
    WHERE 
    YEAR(c.CreatedDate) >=2024
   --  cast(c.CreatedDate as date)='2024-11-05' 
    AND c.NewValue NOT LIKE '%US%'
)
,
GroupedCases AS (
    SELECT 
        Skill, 
        COUNT(distinct CaseId) AS CasesIncoming,
            ServiceLanguage,
        Country,
        CAST(CreatedDate AS DATE) AS IncomingDate 
  
    FROM Cases
    WHERE Skill IS NOT NULL
    GROUP BY Skill, 
    ServiceLanguage,
       Country, 
        CAST(CreatedDate AS DATE)
    ORDER BY Skill ASC
),
reopened AS (
    SELECT DISTINCT 
        CASE 
            WHEN c.CaseSkills LIKE '%US%' THEN 'US'
            WHEN c.CaseSkills LIKE '%General Support%' THEN '1.General Support'
            WHEN c.CaseSkills LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN c.CaseSkills LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN c.CaseSkills LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN c.CaseSkills LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN c.CaseSkills LIKE '%Trading Experience%' THEN '6.Trading Experience'
            WHEN c.CaseSkills LIKE '%Technical%' THEN '7.Technical'
            WHEN c.CaseSkills LIKE '%CS Marketing%' THEN '8.CS Marketing'
        END AS Skill,
        CAST(ch.CreatedDate AS DATE) AS CreatedDate,
        c.ServiceLanguage,
        c.Country,
        ch.CaseId
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE Field = 'Counter_Routing__c' 
    and YEAR(ch.CreatedDate)>=2024
    --    AND CAST(ch.CreatedDate AS DATE) ='2024-11-05'
        AND c.CaseOwnerTitle <> 'Admin'
        AND c.CaseSkills NOT LIKE '%US%'
        AND ch.CreatedDate > c.CreatedDate
)
,
GroupedReopened AS (
    SELECT 
        Skill, 
        COUNT(CaseId) AS ReopenedIncoming,
        CAST(CreatedDate AS DATE) AS IncomingDate ,
        Country,
        ServiceLanguage
    FROM reopened
    WHERE Skill IS NOT NULL
    GROUP BY Skill, CAST(CreatedDate AS DATE),  Country,ServiceLanguage
    ORDER BY Skill ASC
),
final2 as (
SELECT 
    COALESCE(g.Skill, gc.ChatSkill, gr.Skill) AS Skill,
    
      COALESCE(g.ServiceLanguage, gc.Language, gr.ServiceLanguage) AS ServiceLanguage,
      COALESCE(g.Country, gc.Country, gr.Country) AS Country,
    COALESCE(g.CasesIncoming, 0) + COALESCE(gr.ReopenedIncoming, 0) AS CasesIncoming,
    gc.ChatsIncoming,
    COALESCE(g.IncomingDate, gc.IncomingDate, gr.IncomingDate) AS IncomingDate
FROM GroupedCases g
FULL OUTER JOIN GroupedChats gc 
    ON g.Skill = gc.ChatSkill 
    AND g.IncomingDate = gc.IncomingDate
    AND g.ServiceLanguage = gc.Language
    AND g.Country = gc.Country
FULL OUTER JOIN GroupedReopened gr
    ON COALESCE(g.Skill, gc.ChatSkill) = gr.Skill 
    AND COALESCE(g.IncomingDate, gc.IncomingDate) = gr.IncomingDate
    AND COALESCE(g.ServiceLanguage,gc.Language)=gr.ServiceLanguage
      AND COALESCE(g.Country,gc.Country)=gr.Country
ORDER BY Skill ASC)
select * from final2