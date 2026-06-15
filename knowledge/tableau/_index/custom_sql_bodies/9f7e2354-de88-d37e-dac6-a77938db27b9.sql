WITH FilteredCases AS (
    SELECT
        id AS id_Case,
        CaseNumber AS CaseNumber_Case,
        CID__c AS CID__c_Case,
        Case_Id_18__c AS Case_Id_18__c_Case,
        to_timestamp(CreatedDate, 'yyyy-MM-dd\'T\'HH:mm:ss.SSS\'Z\'') AS CreatedDate_Case,
        Origin AS Origin_Case,
        Category__c AS Category__c_Case
    FROM main.crm.silver_crm_case
    WHERE CreatedDate >= current_date - interval '12 months'
      AND createddate >= '2025-01-01'
),

DeflectedCases AS (
    SELECT
        c.casenumber_case,
        CASE
            WHEN EXISTS (
                SELECT 1
                FROM FilteredCases p
                WHERE p.CID__c_Case = c.CID__c_Case
                  AND p.Category__c_Case = c.Category__c_Case
                  AND p.CreatedDate_Case > c.CreatedDate_Case
                  AND p.CreatedDate_Case <= c.CreatedDate_Case + INTERVAL '24 hour'
                  AND p.Origin_Case IN ('Email','Portal')
            ) THEN false ELSE true END AS IsDeflected
    FROM (
        SELECT DISTINCT
            CID__c_Case,
            Category__c_Case,
            CreatedDate_Case,
            casenumber_case
        FROM FilteredCases
        WHERE origin_Case = 'Chatbot'
    ) c
),

MessagingSessionFiltered AS (
  SELECT 
      ms.CaseId AS CaseId_MessagingSession,
      ms.Id AS Id_MessagingSession
  FROM main.crm.silver_crm_messagingsession ms
  JOIN main.crm.silver_crm_messagingchannel mc
     ON ms.messagingchannelid = mc.Id
  WHERE ms.CreatedDate >= current_date - INTERVAL '12 months'
    AND ms.createddate >= '2025-01-01'
    AND date(ms.CreatedDate) <> '2025-05-28'
    AND mc.MasterLabel = 'Customer Service Web Chat'
),

LiveChat AS (
  SELECT id, caseid, Bot_Eligible__c
  FROM main.crm.silver_crm_livechattranscript
  WHERE CreatedDate >= current_date - interval '12 months'
    AND (visitormessagecount > 0 OR visitormessagecount IS NULL)
),

Chatbot AS (
  SELECT DISTINCT
      date_trunc('month', fc.CreatedDate_Case) AS Month,
      fc.Case_Id_18__c_Case AS CaseId,
      'Chatbot' AS Type
  FROM FilteredCases fc
  LEFT JOIN DeflectedCases dc 
    ON fc.casenumber_case = dc.casenumber_case
  LEFT JOIN MessagingSessionFiltered ms 
    ON fc.Case_Id_18__c_Case = ms.CaseId_MessagingSession
  LEFT JOIN LiveChat lc 
    ON fc.Case_Id_18__c_Case = lc.caseid
  WHERE fc.CreatedDate_Case >= add_months(current_date, -12)
    AND fc.Origin_Case = 'Chatbot'
    AND dc.IsDeflected = true
    AND (
      ms.Id_MessagingSession IS NOT NULL
      OR (lc.id IS NOT NULL AND lc.Bot_Eligible__c = true)
    )
),

Chats AS (
    -- Live Chat
    SELECT DISTINCT 
        DATE_TRUNC('month', CAST(c.Time AS DATE)) AS Month,
        l.CaseId,
        'Chats' AS Type
    FROM crm.silver_crm_livechattranscriptevent c
    LEFT JOIN crm.silver_crm_livechattranscript l 
        ON c.LiveChatTranscriptId = l.ID
    WHERE c.Time >= DATE_TRUNC('month', current_date) - INTERVAL 12 MONTHS
      AND c.Detail NOT LIKE '%US%'
      AND c.Detail NOT LIKE '%Cashout%'
      AND c.Detail NOT LIKE '%Deposit%'
      AND (
          c.Detail LIKE '%General Support%' OR
          c.Detail LIKE '%Financial Services%' OR
          c.Detail LIKE '%eToro Money%' OR
          c.Detail LIKE '%Hacked%' OR
          c.Detail LIKE '%GDPR%' OR
          c.Detail LIKE '%Islamic%' OR
          c.Detail LIKE '%Trading Experience%' OR
          c.Detail LIKE '%Technical%' OR
          c.Detail LIKE '%CS Marketing%' OR
          c.Detail LIKE '%BU%' OR
          c.Detail LIKE '%Global%'
      )
      AND l.CaseId IS NOT NULL

    UNION

    -- Messaging Sessions (Async)
    SELECT DISTINCT 
        DATE_TRUNC('month', CAST(c.CreatedDate AS DATE)) AS Month,
        s.CaseId,
        'Chats' AS Type
    FROM crm.silver_crm_messagingsessionhistory c
    LEFT JOIN crm.silver_crm_messagingsession s 
        ON s.ID = c.MessagingSessionId
    WHERE c.CreatedDate >= DATE_TRUNC('month', current_date) - INTERVAL 12 MONTHS
      AND c.NewValue NOT LIKE '%US%'
      AND c.NewValue NOT LIKE '%Cashout%'
      AND c.NewValue NOT LIKE '%Deposit%'
      AND (
          c.NewValue LIKE '%General%' OR
          c.NewValue LIKE '%Financial%' OR
          c.NewValue LIKE '%eToro%' OR
          c.NewValue LIKE '%Hacked%' OR
          c.NewValue LIKE '%GDPR%' OR
          c.NewValue LIKE '%Islamic%' OR
          c.NewValue LIKE '%Club%' OR
          c.NewValue LIKE '%Trading%' OR
          c.NewValue LIKE '%Technical%' OR
          c.NewValue LIKE '%Marketing%' OR
          c.NewValue LIKE '%BU%' OR
          c.NewValue LIKE '%Global%'
      )
      AND s.CaseId IS NOT NULL
),

-- ✅ Merge reopened inside Cases
Cases AS (
    SELECT DISTINCT 
        DATE_TRUNC('month', CAST(c.CreatedDate AS DATE)) AS Month,
        c.CaseId,
        CASE WHEN Origin = 'Email' THEN 'Email' ELSE 'Cases' END AS Type
    FROM crm.silver_crm_casehistory c
    inner join main.crm.silver_crm_case cc 
    on c.CaseId = cc.Id
    WHERE c.CreatedDate >= DATE_TRUNC('month', current_date) - INTERVAL  12 MONTHS
      AND c.NewValue NOT LIKE '%US%'
      AND (
          c.NewValue LIKE '%General Support%' OR
          c.NewValue LIKE '%Financial Services%' OR
          c.NewValue LIKE '%eToro Money%' OR
          c.NewValue LIKE '%Hacked%' OR
          c.NewValue LIKE '%GDPR%' OR
          c.NewValue LIKE '%Islamic%' OR
          c.NewValue LIKE '%Trading Experience%' OR
          c.NewValue LIKE '%Technical%' OR
          c.NewValue LIKE '%CS Marketing%'
      )

    UNION ALL

    -- 👇 Add Reopened into same Cases category
  SELECT DISTINCT 
        DATE_TRUNC('month', CAST(ch.CreatedDate AS DATE)) AS Month,
        ch.CaseId,
        'Cases' AS Type
    FROM crm.silver_crm_casehistory ch
    LEFT JOIN bi_output.bi_output_customer_customer_support_case c 
        ON c.CaseID = ch.CaseId
    WHERE ch.Field = 'Counter_Routing__c'
      AND ch.CreatedDate >= DATE_TRUNC('month', current_date) - INTERVAL 12 MONTHS
      AND ch.CreatedDate > c.CreatedDate
      AND c.CaseOwnerTitle <> 'Admin'
      AND (
          c.CaseSkills LIKE '%General Support%' OR
          c.CaseSkills LIKE '%Financial Services%' OR
          c.CaseSkills LIKE '%eToro Money%' OR
          c.CaseSkills LIKE '%Hacked%' OR
          c.CaseSkills LIKE '%GDPR%' OR
          c.CaseSkills LIKE '%Islamic%' OR
          c.CaseSkills LIKE '%Club%' OR
          c.CaseSkills LIKE '%Trading%' OR
          c.CaseSkills LIKE '%Technical%' OR
          c.CaseSkills LIKE '%Marketing%' 
      )
)

-- ✅ Final unified dataset
SELECT DISTINCT Month, CaseId, Type
FROM (
    SELECT Month, CaseId, Type FROM Chats
    UNION ALL
    SELECT Month, CaseId, Type FROM Cases
    UNION ALL
    SELECT Month, CaseId, Type FROM Chatbot
) combined