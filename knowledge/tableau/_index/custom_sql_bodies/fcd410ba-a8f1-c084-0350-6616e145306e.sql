SELECT
    -- =========================================================
    -- 🟢 ACTIVE FIELDS (Used for Analysis)
    -- =========================================================
    
    -- 1. IDENTIFIERS & JOIN KEYS
    ce.Id AS Id_CaseEvent,
    ce.Case__c AS Case__c_CaseEvent, -- CRITICAL: Join Key to Case Table
    
    -- 2. TIMELINE (Filtered for Sept 1st onwards)
    ce.Event_Date_Time__c AS Event_Date_Time__c_CaseEvent, -- CRITICAL: Timeline Axis

    -- 3. ACTIVITY DETAILS (Workload Logic)
    ce.Event_Type__c AS Event_Type__c_CaseEvent, -- CRITICAL: Filter for "Internal Comment"
    ce.Old_Status__c AS Old_Status__c_CaseEvent, 
    ce.New_Status__c AS New_Status__c_CaseEvent, 

    -- 4. PEOPLE & ATTRIBUTION (Adoption Logic)
    ce.Done_By__c AS Done_By__c_CaseEvent, -- CRITICAL: Analyst ID
    ce.Done_By_Role__c AS Done_By_Role__c_CaseEvent, -- CRITICAL: Exclude System/Bots
    ce.Done_By_CS_Desk__c AS Done_By_CS_Desk__c_CaseEvent, -- Useful for Team Grouping
    ce.CreatedById AS CreatedById_CaseEvent, -- Fallback if Done_By is null
    ce.Updated_by_automatic_process__c AS Updated_by_automatic_process__c_CaseEvent, -- Useful to verify human activity

    -- 🆕 NEW: ANALYST NAMES (Joined from User Table)
    u.FirstName AS Analyst_FirstName,
    u.LastName AS Analyst_LastName,
    u.Name AS Analyst_FullName,
    u.email

    -- =========================================================
    -- 🔴 COMMENTED OUT FIELDS (System, ETL, Unused)
    -- =========================================================
    -- ce.IsDeleted AS IsDeleted_CaseEvent,
    -- ce.Name AS Name_CaseEvent,
    -- ce.CreatedDate AS CreatedDate_CaseEvent, -- Redundant, using Event_Date_Time__c
    -- ce.LastModifiedDate AS LastModifiedDate_CaseEvent,
    -- ce.LastModifiedById AS LastModifiedById_CaseEvent,
    -- ce.SystemModstamp AS SystemModstamp_CaseEvent,
    -- ce.LastActivityDate AS LastActivityDate_CaseEvent,
    -- ce.LastViewedDate AS LastViewedDate_CaseEvent,
    -- ce.LastReferencedDate AS LastReferencedDate_CaseEvent,
    -- ce.source_file AS source_file_CaseEvent,
    -- ce.etr_y AS etr_y_CaseEvent,
    -- ce.etr_ym AS etr_ym_CaseEvent,
    -- ce.etr_ymd AS etr_ymd_CaseEvent,
    -- ce.processing_time AS processing_time_CaseEvent,
    -- ce.__Timestamp AS __Timestamp_CaseEvent,
    -- ce.__DeleteVersion AS __DeleteVersion_CaseEvent,
    -- ce.__UpsertVersion AS __UpsertVersion_CaseEvent,
    -- ce.__DROP_EXPECTATIONS_COL AS __DROP_EXPECTATIONS_COL_CaseEvent,
    -- ce.__MEETS_DROP_EXPECTATIONS AS __MEETS_DROP_EXPECTATIONS_CaseEvent,
    -- ce.__ALLOW_EXPECTATIONS_COL AS __ALLOW_EXPECTATIONS_COL_CaseEvent

FROM main.crm.silver_crm_case_events__c ce
-- 🔗 THE JOIN: Connects Event User ID to User Table ID
LEFT JOIN main.crm.silver_crm_user u 
    ON ce.Done_By__c = u.Id

WHERE 
    -- 1. Time Filter: Only data since Pilot Start (Sept 1st)
    ce.Event_Date_Time__c >= '2025-09-01' 
    
    -- 2. Performance Filter: Only Internal Comments (As discussed)
    AND ce.Event_Type__c = 'Internal Case Comment'
    
    -- 3. Role Filter: Exclude OPS and TL CS
    AND (
        ce.Done_By_Role__c NOT IN ('OPS', 'TL CS') 
    )
    -- Optional: Also exclude Bots if they appear in your data
    AND ce.Done_By_Role__c NOT IN ('System', 'Automated Process')