WITH 
-- 1. Get Proactive Push Notifications (Sent and Opened)
ProactivePushes AS (
    SELECT 
        mn.mp_user_id AS GCID,
        mn.unified_correlationID AS CorrelationID,
        pn.Delivery_Attempts__c AS Attempt_Number,
        -- Pivot the Mixpanel events to get the exact sent and opened timestamps on a single row
        MIN(CASE WHEN mn.mp_event_name = 'Notification Actions BE' THEN mn.event_time END) AS Push_Sent_Time,
        MIN(CASE WHEN mn.mp_event_name = 'Notification - Open' THEN mn.event_time END) AS Push_Opened_Time
    FROM main.bizops_output_stg.bizops_output_notifications_silver_mixpanel_gaps_notifications mn
    INNER JOIN main.crm.silver_crm_push_notification__c pn 
        ON mn.unified_correlationID = pn.Correlation_Id__c
    WHERE mn.unified_correlationID IS NOT NULL 
      AND mn.mp_user_id IS NOT NULL
    GROUP BY 
        mn.mp_user_id, 
        mn.unified_correlationID,
        pn.Delivery_Attempts__c
),

-- 2. Filter base cases FIRST to massively reduce the data footprint (Reactive/Chat baseline)
BaseFilteredCases AS (
    SELECT 
        c.id AS CaseId,
        c.GCID__c AS GCID,
        c.CreatedDate AS Chat_Date,
        ms.id AS MessagingSessionId
    FROM main.crm.silver_crm_case c
    INNER JOIN main.crm.silver_crm_messagingsession ms 
        ON c.id = ms.CaseId
    WHERE c.CreatedDate >= '2024-01-01' 
      AND c.origin IN ('Chat', 'Chatbot')
      AND (c.Club_Level_on_Creation__c <> 'Internal' OR c.Club_Level_on_Creation__c IS NULL)
),

-- 3. Target Chats: Chats where the bot sent a gap-closing link
TargetChats AS (
    SELECT bfc.*
    FROM BaseFilteredCases bfc
    WHERE EXISTS (
        SELECT 1
        FROM main.crm.silver_crm_ai_session__c ais
        INNER JOIN main.crm.silver_crm_ai_session_entry__c aise 
            ON aise.AI_Session__c = ais.id
        WHERE ais.messaging_session__c = bfc.MessagingSessionId
          AND (
              aise.Bot_Message__c LIKE '%https://www.etoro.com/settings/profile%' OR 
              aise.Bot_Message__c LIKE '%https://www.etoro.com/login/?action=autokyc%'
          )
    )
),

-- 4. Unify the Funnels (Attributing Chats to Pushes based on OPEN time)
AttributedFunnel AS (
    SELECT 
        COALESCE(tc.GCID, pp.GCID) AS GCID,
        tc.CaseId,
        tc.MessagingSessionId,
        tc.Chat_Date,
        pp.CorrelationID,
        pp.Attempt_Number,
        pp.Push_Sent_Time,
        pp.Push_Opened_Time,
        
        -- Define the funnel start point (Push if it exists, otherwise the Chat)
        COALESCE(pp.Push_Sent_Time, tc.Chat_Date) AS Funnel_Entry_Date,
        
        -- Categorize how the user entered the funnel
        CASE 
            WHEN pp.Push_Opened_Time IS NOT NULL AND tc.Chat_Date IS NOT NULL AND tc.Chat_Date >= pp.Push_Opened_Time THEN 'Proactive (Push -> Chat)'
            WHEN pp.Push_Sent_Time IS NOT NULL AND tc.Chat_Date IS NULL THEN 'Proactive (Push Only - No Chat)'
            WHEN tc.Chat_Date IS NOT NULL AND pp.Push_Sent_Time IS NULL THEN 'Reactive (Chat Only)'
            ELSE 'Other'
        END AS Channel_Type

    FROM TargetChats tc
    -- FULL OUTER JOIN ensures we keep pushes that didn't lead to chats, AND chats that didn't have pushes
    FULL OUTER JOIN ProactivePushes pp 
        ON tc.GCID = pp.GCID 
        -- Attribution Window: Chat must occur AFTER the push was OPENED, but within 2 hours
        AND tc.Chat_Date >= pp.Push_Opened_Time 
        AND tc.Chat_Date <= DATEADD(hour, 2, pp.Push_Opened_Time)
),

-- 5. Get All History Events for Gaps
RawGapEvents AS (
    SELECT GCID, RequirementID, OverviewStatusID, Occurred
    FROM main.bi_db.bronze_compliancestatedb_history_customerrequirementsoverviewstatus
    WHERE Occurred >= '2024-01-01'
    UNION ALL
    SELECT GCID, RequirementID, OverviewStatusID, Occurred
    FROM main.bi_db.bronze_compliancestatedb_compliance_customerrequirementsoverviewstatus
    WHERE Occurred >= '2024-01-01'
),

-- 6. Find Gap Status at Funnel Entry (Point-In-Time)
GapStateAtEntry AS (
    SELECT 
        af.*,
        rge.RequirementID,
        rge.OverviewStatusID AS Status_At_Entry,
        rge.Occurred AS Last_Update_Date,
        ROW_NUMBER() OVER(
            PARTITION BY af.GCID, af.CorrelationID, af.CaseId, rge.RequirementID 
            ORDER BY rge.Occurred DESC
        ) as rn
    FROM AttributedFunnel af
    INNER JOIN RawGapEvents rge 
        ON af.GCID = rge.GCID
    WHERE rge.Occurred <= af.Funnel_Entry_Date 
),

-- 7. Filter for OPEN gaps at the time of Push or Chat
FilteredGaps AS (
    SELECT * FROM GapStateAtEntry
    WHERE rn = 1 
      AND Status_At_Entry NOT IN (6, 9) -- 6=Completed, 9=Cancelled
),

-- 8. Calculate Closures in a CTE (Did they close it AFTER entering the funnel?)
FutureClosures AS (
    SELECT 
        fg.GCID,
        fg.RequirementID,
        fg.Funnel_Entry_Date,
        MIN(future.Occurred) AS Gap_Closure_Date
    FROM FilteredGaps fg
    INNER JOIN RawGapEvents future
        ON future.GCID = fg.GCID 
        AND future.RequirementID = fg.RequirementID
        AND future.Occurred > fg.Funnel_Entry_Date
        AND future.OverviewStatusID IN (6, 9) 
    GROUP BY 
        fg.GCID, 
        fg.RequirementID,
        fg.Funnel_Entry_Date
)

-- 9. Final Selection (Backwards Compatible + V2 Additions)
SELECT 
    -- ==========================================
    -- 🛑 LEGACY COLUMNS (Keeps V1 Dashboard Alive)
    -- ==========================================
    g.CaseId AS CaseId_Gaps,
    g.GCID AS GCID_Gaps,
    g.Chat_Date AS CreatedDate_Gaps,
    g.MessagingSessionId AS MessagingSession_Id_Gaps,
    req.DisplayName AS Gap_Type_Gaps,
    g.Last_Update_Date AS Gap_Creation_Date,
    g.Chat_Date AS chat_date_Gaps,
    fc.Gap_Closure_Date,
    DATEDIFF(DAY, g.Chat_Date, fc.Gap_Closure_Date) AS Days_Chat_To_Close_Gaps,
    DATEDIFF(DAY, g.Last_Update_Date, g.Chat_Date) AS Days_Gap_Open_Before_Chat_Gaps,

    -- ==========================================
    -- 🚀 NEW COLUMNS (For V2 Proactive Features)
    -- ==========================================
    g.CorrelationID,
    g.Channel_Type,
    g.Attempt_Number,
    g.Push_Sent_Time,
    g.Push_Opened_Time,
    g.Funnel_Entry_Date,
    
    -- Boolean Flags for easy KPI counting
    CASE WHEN g.Push_Sent_Time IS NOT NULL THEN 1 ELSE 0 END AS Is_Push_Sent,
    CASE WHEN g.Push_Opened_Time IS NOT NULL THEN 1 ELSE 0 END AS Is_Push_Opened,
    CASE WHEN g.Chat_Date IS NOT NULL THEN 1 ELSE 0 END AS Is_Chat_Started,
    CASE WHEN fc.Gap_Closure_Date IS NOT NULL THEN 1 ELSE 0 END AS Is_Gap_Closed,
    
    -- New Durations
    DATEDIFF(MINUTE, g.Push_Sent_Time, g.Push_Opened_Time) AS Mins_Push_To_Open,
    DATEDIFF(MINUTE, g.Push_Opened_Time, g.Chat_Date) AS Mins_Open_To_Chat,
    DATEDIFF(DAY, g.Funnel_Entry_Date, fc.Gap_Closure_Date) AS Days_Funnel_To_Close

FROM FilteredGaps g
LEFT JOIN main.compliance.bronze_compliancestatedb_compliance_requirements req 
    ON g.RequirementID = req.RequirementID
LEFT JOIN FutureClosures fc 
    ON g.GCID = fc.GCID 
    AND g.RequirementID = fc.RequirementID
    AND g.Funnel_Entry_Date = fc.Funnel_Entry_Date