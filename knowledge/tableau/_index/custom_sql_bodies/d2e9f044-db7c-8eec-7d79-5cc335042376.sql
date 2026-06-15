-- Step 1: Premium Chat Sessions (last 7 days)
with PremiumChats AS (
    SELECT DISTINCT 

     l.CaseId as  ID,
        CAST(c.Time AS DATE) AS IncomingDate,
        'Chat' AS SourceType
    FROM crm.silver_crm_livechattranscriptevent c
    left join crm.silver_crm_livechattranscript l on l.ID=LiveChatTranscriptId
    WHERE CAST(c.Time AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND c.Detail LIKE '%Premium%'
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
      AND c.Detail NOT LIKE '%FATCA%'
      AND c.Detail NOT LIKE '%Tax%'
      AND c.Detail NOT LIKE '%Risk%'
      AND c.Detail NOT LIKE '%FCMU%'
      AND c.Detail NOT LIKE '%Verification%'
      AND c.Detail NOT LIKE '%Screening%'
),
 PremiumAsychronous as (
 SELECT DISTINCT 

     l.CaseId as  ID,
        CAST(c.CreatedDate AS DATE) AS IncomingDate,
        'Chat' AS SourceType
    FROM crm.silver_crm_messagingsessionhistory c
    left join crm.silver_crm_messagingsession l on l.ID=c.MessagingSessionId
    WHERE CAST(c.CreatedDate AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND c.NewValue LIKE '%Premium%'
      AND c.NewValue NOT LIKE '%US%'
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
      AND c.NewValue NOT LIKE '%FATCA%'
      AND c.NewValue NOT LIKE '%Tax%'
      AND c.NewValue NOT LIKE '%Risk%'
      AND c.NewValue NOT LIKE '%FCMU%'
      AND c.NewValue NOT LIKE '%Verification%'
      AND c.NewValue NOT LIKE '%Screening%'
),
CombinedChats AS (
    SELECT * FROM PremiumChats
    UNION ALL
    SELECT * FROM PremiumAsychronous),


-- Step 2: Premium New Cases
PremiumCases AS (
    SELECT DISTINCT 
        c.CaseId AS ID,
        CAST(c.CreatedDate AS DATE) AS IncomingDate,
        'NewCase' AS SourceType
    FROM crm.silver_crm_casehistory c
    WHERE CAST(c.CreatedDate AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND c.NewValue LIKE '%Premium%'
      AND c.NewValue NOT LIKE '%US%'
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
      AND c.NewValue NOT LIKE '%FATCA%'
      AND c.NewValue NOT LIKE '%Tax%'
      AND c.NewValue NOT LIKE '%Risk%'
      AND c.NewValue NOT LIKE '%FCMU%'
      AND c.NewValue NOT LIKE '%Verification%'
      AND c.NewValue NOT LIKE '%Screening%'
),

-- Step 3: Premium Reopened Cases
PremiumReopened AS (
    SELECT DISTINCT 
        ch.CaseId AS ID,
        CAST(ch.CreatedDate AS DATE) AS IncomingDate,
        'Reopened' AS SourceType
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN
     --select * 
     --from 
     bi_output.bi_output_customer_customer_support_case c 
--where CaseNumber='500dV00000D2lBVQAZ'
        ON ch.CaseId = c.CaseID
    WHERE ch.Field = 'Counter_Routing__c'
      AND CAST(ch.CreatedDate AS DATE) BETWEEN DATE_SUB(CURRENT_DATE(), 180) AND CURRENT_DATE()
      AND ch.CreatedDate > c.CreatedDate
      AND c.CaseOwnerTitle <> 'Admin'
      AND c.CaseSkills LIKE '%Premium%'
      AND c.CaseSkills NOT LIKE '%US%'
      AND c.CaseSkills NOT LIKE '%Cashout%'
      AND c.CaseSkills NOT LIKE '%Deposit%'
      AND c.CaseSkills NOT LIKE '%FATCA%'
      AND c.CaseSkills NOT LIKE '%Tax%'
      AND c.CaseSkills NOT LIKE '%Risk%'
      AND c.CaseSkills NOT LIKE '%FCMU%'
      AND c.CaseSkills NOT LIKE '%Verification%'
      AND c.CaseSkills NOT LIKE '%Screening%'
),

-- Step 4: Union all Premium Events
AllPremiumInteractions AS (
    SELECT * FROM CombinedChats
    UNION ALL
    SELECT * FROM PremiumCases
    UNION ALL
    SELECT * FROM PremiumReopened
),

prefinal as (
SELECT 
    a.ID AS CaseID,
    IncomingDate,
    SourceType,
    c.Status,
    ClosedDate,
    case when ClosedDate is not null then 'Closed' else 'Open' end as IsClosed,
    Case 
    WHEN c.CaseSkills is null then Original_Skillset_Text__c else CaseSkills END AS CaseSkills,
NumberofTouches,
CASE 
    WHEN SourceType = 'Chat' AND CaseSkills IS NOT NULL THEN 1 
    ELSE 0 
END AS `ChatThatBecameCase`,
CASE 
    WHEN ClosedDate IS NOT NULL THEN DATEDIFF(ClosedDate, IncomingDate)
    ELSE 'Still Open'
END AS DaysToClose,Type,Sub_Type,Sub_Type_2
FROM AllPremiumInteractions a 
left join bi_output.bi_output_customer_customer_support_case c ON c.CaseID=a.ID
left join crm.silver_crm_livechattranscript l ON c.CaseID=l.CaseID)

select *,CASE 
    WHEN c.CaseSkills LIKE '%US%' 
      OR c.CaseSkills LIKE '%Cashout%' 
      OR c.CaseSkills LIKE '%Deposit%' 
    or c.CaseSkills LIKE '%eToro Options%'
       or c.CaseSkills LIKE '%Tax%'
      OR c.CaseSkills LIKE '%FATCA%' 
      OR c.CaseSkills LIKE '%TAX%' 
      OR c.CaseSkills LIKE '%Risk%' 
            OR c.CaseSkills LIKE '%Corporate%' 
      OR c.CaseSkills LIKE '%FCMU%' 
      OR c.CaseSkills LIKE '%Verification%' 
      OR c.CaseSkills LIKE '%Screening%' 
    THEN 'Under OPS'

    WHEN c.CaseSkills LIKE '%General%' 
      OR c.CaseSkills LIKE '%Financial%' 
      OR c.CaseSkills LIKE '%Money%' 
      OR c.CaseSkills LIKE '%Hacked%' 
      OR c.CaseSkills LIKE '%GDPR%' 
      OR c.CaseSkills LIKE '%Islamic%' 
      OR c.CaseSkills LIKE '%Trading%' 
      OR c.CaseSkills LIKE '%Technical%' 
      OR c.CaseSkills LIKE '%CS Marketing%' 
     OR c.CaseSkills LIKE '%Club%' 
    THEN 'Under CS'
 WHEN c.CaseSkills LIKE '%Escalation%' then 'Under CS- Escalation'
    ELSE 'Other'
END AS CurrentDepartment,
CASE 
    WHEN c.CaseSkills LIKE '%US%' THEN 'US'
    WHEN c.CaseSkills LIKE '%Cashout%' THEN 'Cashout'
    WHEN c.CaseSkills LIKE '%Deposit%' THEN 'Deposit'
    WHEN c.CaseSkills LIKE '%eToro Options%' THEN 'eToro Options'
    WHEN c.CaseSkills LIKE '%Tax%' THEN 'Tax'
    WHEN c.CaseSkills LIKE '%FATCA%' THEN 'FATCA'
    WHEN c.CaseSkills LIKE '%TAX%' THEN 'TAX'
    WHEN c.CaseSkills LIKE '%Risk%' THEN 'Risk'
    WHEN c.CaseSkills LIKE '%Corporate%' THEN 'Corporate'
    WHEN c.CaseSkills LIKE '%FCMU%' THEN 'FCMU'
    WHEN c.CaseSkills LIKE '%Verification%' THEN 'Verification'
    WHEN c.CaseSkills LIKE '%Screening%' THEN 'Screening'

    WHEN c.CaseSkills LIKE '%General%' THEN 'General Support'
    WHEN c.CaseSkills LIKE '%Financial%' THEN 'Financial Services'
    WHEN c.CaseSkills LIKE '%Money%' THEN 'eToro Money'
    WHEN c.CaseSkills LIKE '%Hacked%' THEN 'Hacked Accounts'
    WHEN c.CaseSkills LIKE '%GDPR%' THEN 'GDPR'
    WHEN c.CaseSkills LIKE '%Islamic%' THEN 'Islamic Accounts'
    WHEN c.CaseSkills LIKE '%Trading%' THEN 'Trading Experience'
    WHEN c.CaseSkills LIKE '%Technical%' THEN 'Technical'
    WHEN c.CaseSkills LIKE '%CS Marketing%' THEN 'CS Marketing'
    WHEN c.CaseSkills LIKE '%Club%' THEN 'Club Issues'
    
    WHEN c.CaseSkills LIKE '%Escalation%' THEN 'Escalation'
    ELSE 'Uncategorized'
END as CurrentSkill

 from prefinal c