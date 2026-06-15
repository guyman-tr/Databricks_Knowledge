SELECT
    -- =========================================================
    -- 🟢 ACTIVE FIELDS (Needed for FinGuard Adoption Analysis)
    -- =========================================================
    
    -- 1. IDENTIFIERS
    Id AS Id_Case,
    CaseNumber AS CaseNumber_Case,
    ParentId AS ParentId_Case, -- Hierarchy context
    CID__c AS CID__c_Case, -- Customer ID
    GCID__c AS GCID__c_Case, -- Global Customer ID
    Customer_Name__c AS Customer_Name__c_Case,

    -- 2. TIMELINE & STATUS (Workload Logic)
    CreatedDate AS CreatedDate_Case, -- Essential for filtering
    ClosedDate AS ClosedDate_Case, -- Essential for resolution time
    Status AS Status_Case, -- Active vs Closed
    IsClosed AS IsClosed_Case,
    Priority AS Priority_Case,
    IsEscalated AS IsEscalated_Case,
    
    -- 3. CLASSIFICATION (Eligibility Logic)
    Type__c AS Type_Case, -- CRITICAL
    Sub_Type__c AS Sub_Type__c_Case, -- CRITICAL
    Sub_Type_2__c AS Sub_Type_2__c_Case, -- CRITICAL
    Category__c AS Category__c_Case, -- CRITICAL
    FCA_Sub_Type__c AS FCA_Sub_Type__c_Case,
    Initial_Type__c AS Initial_Type__c_Case, -- Audit trail of classification
    Initial_Sub_Type__c AS Initial_Sub_Type__c_Case,

    -- 4. PEOPLE & TEAMS (Attribution Logic)
    OwnerId AS OwnerId_Case,
    Owner_Team__c AS Owner_Team__c_Case, -- CRITICAL for Team Reporting
    Owner_role_name__c AS Owner_role_name__c_Case, -- CRITICAL for Role Filtering
    Case_Created_By_Role__c AS Case_Created_By_Role__c_Case,
    Case_Created_By_Role_Name__c AS Case_Created_By_Role_Name__c_Case,
    Case_Owner_Title__c AS Case_Owner_Title__c_Case,
    AML_Team__c AS AML_Team__c_Case, -- Specific AML Team routing
    Owner_Service_Desk__c AS Owner_Service_Desk__c_Case,
    
    -- 5. RISK, AML & COMPLIANCE (Context)
    Risk__c AS Risk__c_Case, -- CRITICAL
    Regulation__c AS Regulation__c_Case,
    Unusual_activity__c AS Unusual_activity__c_Case, -- Eligibility trigger
    KYC_Monitoring__c AS KYC_Monitoring__c_Case,
    Compliant__c AS Compliant__c_Case,
    AML_State__c AS AML_State__c_Case,
    AML_Status__c AS AML_Status__c_Case,
    Alert__c AS Alert__c_Case, -- Is there an alert?
    Alert_ID__c AS Alert_ID__c_Case,
    Alert_Type__c AS Alert_Type__c_Case,
    Alert_Priority__c AS Alert_Priority__c_Case,
    Alert_State__c AS Alert_State__c_Case,
    Alert_Outcome__c AS Alert_Outcome__c_Case,
    BI_Alerts__c AS BI_Alerts__c_Case,
    
    -- 6. IMPACT & OUTCOME (SARs & Tools)
    SAR__c AS SAR__c_Case, -- Link to SAR table
    Number_of_SARs__c AS Number_of_SARs__c_Case,
    Is_Run_EDD_Button_Visible__c AS Is_Run_EDD_Button_Visible__c_Case, -- Tech Availability
    Escalated_By__c AS Escalated_By__c_Case,
    Escalation_Date__c AS Escalation_Date__c_Case,

    -- 7. CUSTOMER SEGMENTATION
    Country__c AS Country__c_Case,
    Tier__c AS Tier__c_Case,
    Customer_Level__c AS Customer_Level__c_Case,
    Customer_Status__c AS Customer_Status__c_Case,
    Club_Level_on_Creation__c AS Club_Level_on_Creation__c_Case


    -- =========================================================
    -- 🔴 COMMENTED OUT FIELDS (System, PII, Tech Support, Unused)
    -- =========================================================
    -- IsDeleted AS IsDeleted_Case,
    -- MasterRecordId AS MasterRecordId_Case,
    -- ContactId AS ContactId_Case,
    -- AccountId AS AccountId_Case,
    -- AssetId AS AssetId_Case,
    -- ProductId AS ProductId_Case,
    -- EntitlementId AS EntitlementId_Case,
    -- SourceId AS SourceId_Case,
    -- BusinessHoursId AS BusinessHoursId_Case,
    -- SuppliedName AS SuppliedName_Case,
    -- SuppliedEmail AS SuppliedEmail_Case,
    -- SuppliedPhone AS SuppliedPhone_Case,
    -- SuppliedCompany AS SuppliedCompany_Case,
    -- RecordTypeId AS RecordTypeId_Case,
    -- Reason AS Reason_Case,
    -- Origin AS Origin_Case,
    -- Language AS Language_Case,
    -- Subject AS Subject_Case,
    -- Description AS Description_Case,
    -- IsClosedOnCreate AS IsClosedOnCreate_Case,
    -- SlaStartDate AS SlaStartDate_Case,
    -- SlaExitDate AS SlaExitDate_Case,
    -- IsStopped AS IsStopped_Case,
    -- StopStartDate AS StopStartDate_Case,
    -- CreatedById AS CreatedById_Case,
    -- LastModifiedDate AS LastModifiedDate_Case,
    -- LastModifiedById AS LastModifiedById_Case,
    -- SystemModstamp AS SystemModstamp_Case,
    -- ContactPhone AS ContactPhone_Case,
    -- ContactMobile AS ContactMobile_Case,
    -- ContactEmail AS ContactEmail_Case,
    -- ContactFax AS ContactFax_Case,
    -- Comments AS Comments_Case,
    -- LastViewedDate AS LastViewedDate_Case,
    -- LastReferencedDate AS LastReferencedDate_Case,
    -- ServiceContractId AS ServiceContractId_Case,
    -- MilestoneStatus AS MilestoneStatus_Case,
    -- MIMO_Role_Queue__c AS MIMO_Role_Queue__c_Case,
    -- Supervisor_Call__c AS Supervisor_Call__c_Case,
    -- T3_case__c AS T3_case__c_Case,
    -- Technical_Team_case__c AS Technical_Team_case__c_Case,
    -- Date_of_transaction__c AS Date_of_transaction__c_Case,
    -- Amount_of_transaction__c AS Amount_of_transaction__c_Case,
    -- Status_Reason__c AS Status_Reason__c_Case,
    -- Service_Language__c AS Service_Language__c_Case,
    -- Service_Language_For_Auto_Emails__c AS Service_Language_For_Auto_Emails__c_Case,
    -- ZD_Ticket_Number__c AS ZD_Ticket_Number__c_Case,
    -- Visitor_Name__c AS Visitor_Name__c_Case,
    -- Partner__c AS Partner__c_Case,
    -- Read_Status__c AS Read_Status__c_Case,
    -- Withdrawal_ID__c AS Withdrawal_ID__c_Case,
    -- Deposit_ID__c AS Deposit_ID__c_Case,
    -- Position_ID__c AS Position_ID__c_Case,
    -- Mirror_ID__c AS Mirror_ID__c_Case,
    -- Phase__c AS Phase__c_Case,
    -- CC__c AS CC__c_Case,
    -- Platform__c AS Platform__c_Case,
    -- Instrument_Type__c AS Instrument_Type__c_Case,
    -- Method_of_Payment__c AS Method_of_Payment__c_Case,
    -- Error_Message__c AS Error_Message__c_Case,
    -- Time_Of_The_Error__c AS Time_Of_The_Error__c_Case,
    -- PP_Report__c AS PP_Report__c_Case,
    -- Tmail__c AS Tmail__c_Case,
    -- CO_Call__c AS CO_Call__c_Case,
    -- Pending_Verification__c AS Pending_Verification__c_Case,
    -- Pending_Verification_Calls__c AS Pending_Verification_Calls__c_Case,
    -- Satisfaction_On_Solve__c AS Satisfaction_On_Solve__c_Case,
    -- Lead_or_FTD__c AS Lead_or_FTD__c_Case,
    -- CHB_Case__c AS CHB_Case__c_Case,
    -- CO_Case__c AS CO_Case__c_Case,
    -- Official_Complaint__c AS Official_Complaint__c_Case,
    -- Phone_Call_Required__c AS Phone_Call_Required__c_Case,
    -- Spam__c AS Spam__c_Case,
    -- Re_Opened__c AS Re_Opened__c_Case,
    -- Number_of_Incoming_Email_Messages__c AS Number_of_Incoming_Email_Messages__c_Case,
    -- Number_of_Outbound_Email_Messages__c AS Number_of_Outbound_Email_Messages__c_Case,
    -- Last_Update_Date_Time__c AS Last_Update_Date_Time__c_Case,
    -- Number_of_Copiers__c AS Number_of_Copiers__c_Case,
    -- Chat_Rating_by_Customer__c AS Chat_Rating_by_Customer__c_Case,
    -- X1st_Response_Date_Time__c AS X1st_Response_Date_Time__c_Case,
    -- Time_to_1st_Response__c AS Time_to_1st_Response__c_Case,
    -- Full_Resolution_Time__c AS Full_Resolution_Time__c_Case,
    -- Resolution_Time_From_1st_Response__c AS Resolution_Time_From_1st_Response__c_Case,
    -- Reply_Milestone_Start_Time__c AS Reply_Milestone_Start_Time__c_Case,
    -- Solved__c AS Solved__c_Case,
    -- SLA_Breached_1st_Response__c AS SLA_Breached_1st_Response__c_Case,
    -- SLA_Target_Date_Time__c AS SLA_Target_Date_Time__c_Case,
    -- Original_Group__c AS Original_Group__c_Case,
    -- Last_Assignment_Date_Time__c AS Last_Assignment_Date_Time__c_Case,
    -- Last_Assigned_To__c AS Last_Assigned_To__c_Case,
    -- Month_of_Missing_Payment__c AS Month_of_Missing_Payment__c_Case,
    -- Missing_Payment_Amount__c AS Missing_Payment_Amount__c_Case,
    -- Creative_Name__c AS Creative_Name__c_Case,
    -- Creative_Language_and_Size__c AS Creative_Language_and_Size__c_Case,
    -- Attachment_count__c AS Attachment_count__c_Case,
    -- Attachments_on_Emails__c AS Attachments_on_Emails__c_Case,
    -- Affiliate_Referring_ID__c AS Affiliate_Referring_ID__c_Case,
    -- Affiliate_Referring_Name__c AS Affiliate_Referring_Name__c_Case,
    -- Selected_Chat_Language__c AS Selected_Chat_Language__c_Case,
    -- Last_Outgoing_Email_Date_Time__c AS Last_Outgoing_Email_Date_Time__c_Case,
    -- Last_Public_Update_Date_Time__c AS Last_Public_Update_Date_Time__c_Case,
    -- ZD_Assignee__c AS ZD_Assignee__c_Case,
    -- CID_Text__c AS CID_Text__c_Case,
    -- Partner_Id__c AS Partner_Id__c_Case,
    -- Opened_in_Portal_Date_Time__c AS Opened_in_Portal_Date_Time__c_Case,
    -- Time_Of_the_Error_ZD__c AS Time_Of_the_Error_ZD__c_Case,
    -- CC_ZD__c AS CC_ZD__c_Case,
    -- Email__c AS Email__c_Case,
    -- BaseDomain__c AS BaseDomain__c_Case,
    -- Number_of_Internal_Case_Comments__c AS Number_of_Internal_Case_Comments__c_Case,
    -- Number_of_Public_Case_Comments__c AS Number_of_Public_Case_Comments__c_Case,
    -- Attachments_on_Case_Comments__c AS Attachments_on_Case_Comments__c_Case,
    -- Num_of_Updates__c AS Num_of_Updates__c_Case,
    -- One_Touch__c AS One_Touch__c_Case,
    -- File_Attached__c AS File_Attached__c_Case,
    -- Case_Latest_Update__c AS Case_Latest_Update__c_Case,
    -- Total_Time_Spent__c AS Total_Time_Spent__c_Case,
    -- Internal_Case__c AS Internal_Case__c_Case,
    -- Error_Number__c AS Error_Number__c_Case,
    -- Case_Was_Migrated__c AS Case_Was_Migrated__c_Case,
    -- Type__c AS Type__c_Case,
    -- Product__c AS Product__c_Case,
    -- Lifetime_Deposits__c AS Lifetime_Deposits__c_Case,
    -- ZD_Assignee_Name__c AS ZD_Assignee_Name__c_Case,
    -- Verification_Level__c AS Verification_Level__c_Case,
    -- PI__c AS PI__c_Case,
    -- SLA__c AS SLA__c_Case,
    -- ZD_Group__c AS ZD_Group__c_Case,
    -- ZD_Group_Name__c AS ZD_Group_Name__c_Case,
    -- Customer_Last_Name__c AS Customer_Last_Name__c_Case,
    -- Case_Word_in_Service_Language__c AS Case_Word_in_Service_Language__c_Case,
    -- Long_Subject__c AS Long_Subject__c_Case,
    -- Case_Id_18__c AS Case_Id_18__c_Case,
    -- ZD_Ticket_Number_Text__c AS ZD_Ticket_Number_Text__c_Case,
    -- ZD_Last_Update_Date_Time__c AS ZD_Last_Update_Date_Time__c_Case,
    -- Last_Comment_Date_Time__c AS Last_Comment_Date_Time__c_Case,
    -- Account_Service_Language__c AS Account_Service_Language__c_Case,
    -- Account_Service_Language_For_Auto_Emails__c AS Account_Service_Language_For_Auto_Emails__c_Case,
    -- MIMO_for_OPS__c AS MIMO_for_OPS__c_Case,
    -- Joint_and_Corporate__c AS Joint_and_Corporate__c_Case,
    -- Tmail_WithoutAutoAssignment__c AS Tmail_WithoutAutoAssignment__c_Case,
    -- Case_Number__c AS Case_Number__c_Case,
    -- Customer_Mobile__c AS Customer_Mobile__c_Case,
    -- Customer_Phone__c AS Customer_Phone__c_Case,
    -- Customer_Active_Manager__c AS Customer_Active_Manager__c_Case,
    -- Chat_Score__c AS Chat_Score__c_Case,
    -- Service_Desk__c AS Service_Desk__c_Case,
    -- Under_Queue__c AS Under_Queue__c_Case,
    -- IsUnique__c AS IsUnique__c_Case,
    -- Updated_by_automatic_process__c AS Updated_by_automatic_process__c_Case,
    -- Sort_By__c AS Sort_By__c_Case,
    -- Case_Summary__c AS Case_Summary__c_Case,
    -- Type_Sorted__c AS Type_Sorted__c_Case,
    -- Updated_by_automatic_process_QA__c AS Updated_by_automatic_process_QA__c_Case,
    -- GCID_Text__c AS GCID_Text__c_Case,
    -- Test_Hyperlink__c AS Test_Hyperlink__c_Case,
    -- Total_time_to_Resolve_reports__c AS Total_time_to_Resolve_reports__c_Case,
    -- Number_of_touches__c AS Number_of_touches__c_Case,
    -- P__c AS P__c_Case,
    -- Technical_Refund__c AS Technical_Refund__c_Case,
    -- Yellow_SLA__c AS Yellow_SLA__c_Case,
    -- Red_SLA__c AS Red_SLA__c_Case,
    -- Simple_Survey_Last_Requested_On__c AS Simple_Survey_Last_Requested_On__c_Case,
    -- Num_Of_Days_To_Survey__c AS Num_Of_Days_To_Survey__c_Case,
    -- State__c AS State__c_Case,
    -- Scores_Rep__c AS Scores_Rep__c_Case,
    -- CID_from_task__c AS CID_from_task__c_Case,
    -- Call_Record_URL__c AS Call_Record_URL__c_Case,
    -- Voicemail_Phone__c AS Voicemail_Phone__c_Case,
    -- Internal_Case_Time__c AS Internal_Case_Time__c_Case,
    -- X1st_check__c AS X1st_check__c_Case,
    -- X2nd_check__c AS X2nd_check__c_Case,
    -- Termination__c AS Termination__c_Case,
    -- SLA_Warning__c AS SLA_Warning__c_Case,
    -- Test_Field__c AS Test_Field__c_Case,
    -- Disclosed_to_CysSEC__c AS Disclosed_to_CysSEC__c_Case,
    -- N_A__c AS N_A__c_Case,
    -- Send_Email__c AS Send_Email__c_Case,
    -- Language_to_solved_email__c AS Language_to_solved_email__c_Case,
    -- Email_Comment__c AS Email_Comment__c_Case,
    -- Score_by_Customer_level__c AS Score_by_Customer_level__c_Case,
    -- Score_by_Priority__c AS Score_by_Priority__c_Case,
    -- Score_By_SLA__c AS Score_By_SLA__c_Case,
    -- SLA_Score__c AS SLA_Score__c_Case,
    -- Score__c AS Score__c_Case,
    -- Sort_Order__c AS Sort_Order__c_Case,
    -- Score_Order__c AS Score_Order__c_Case,
    -- Translations__c AS Translations__c_Case,
    -- Owner_queue_name__c AS Owner_queue_name__c_Case,
    -- Social__c AS Social__c_Case,
    -- Thread_Id__c AS Thread_Id__c_Case,
    -- Num_of_PP_Requests__c AS Num_of_PP_Requests__c_Case,
    -- Error_Massage_Number__c AS Error_Massage_Number__c_Case,
    -- Part_of_the_day__c AS Part_of_the_day__c_Case,
    -- Name_of_transaction__c AS Name_of_transaction__c_Case,
    -- Jira_Description__c AS Jira_Description__c_Case,
    -- Jira_ID__c AS Jira_ID__c_Case,
    -- JIRA_Link_Formula__c AS JIRA_Link_Formula__c_Case,
    -- Created_from_Macro__c AS Created_from_Macro__c_Case,
    -- Case_Assignment_Rules_Trigger__c AS Case_Assignment_Rules_Trigger__c_Case,
    -- Trusted_Contact_First_Name__c AS Trusted_Contact_First_Name__c_Case,
    -- Trusted_Contact_Last_Name__c AS Trusted_Contact_Last_Name__c_Case,
    -- Trusted_Contact_Phone_Number__c AS Trusted_Contact_Phone_Number__c_Case,
    -- Trusted_Contact_Phone_Number_Type__c AS Trusted_Contact_Phone_Number_Type__c_Case,
    -- Trusted_Contact_Email__c AS Trusted_Contact_Email__c_Case,
    -- Closed_by_Change_Status_and_send_email__c AS Closed_by_Change_Status_and_send_email__c_Case,
    -- Citizenship__c AS Citizenship__c_Case,
    -- don_t_send_survey_mass_closure__c AS don_t_send_survey_mass_closure__c_Case,
    -- Data_Fix_Checkbox__c AS Data_Fix_Checkbox__c_Case,
    -- Macro_Name__c AS Macro_Name__c_Case,
    -- Old_Tickets_Data_Fixed__c AS Old_Tickets_Data_Fixed__c_Case,
    -- of_Tmail__c AS of_Tmail__c_Case,
    -- Solution_Description__c AS Solution_Description__c_Case,
    -- Product_Service_Grouping_FCA__c AS Product_Service_Grouping_FCA__c_Case,
    -- Service_FCA__c AS Service_FCA__c_Case,
    -- Issue_Resolved__c AS Issue_Resolved__c_Case,
    -- Goodwill_Gesture__c AS Goodwill_Gesture__c_Case,
    -- Crypto_Type__c AS Crypto_Type__c_Case,
    -- AML_Required_Documents_Information__c AS AML_Required_Documents_Information__c_Case,
    -- Elapsed_time_from_1st_communication__c AS Elapsed_time_from_1st_communication__c_Case,
    -- First_communication_date__c AS First_communication_date__c_Case,
    -- StatusModifiedDate__c AS StatusModifiedDate__c_Case,
    -- CaseSkillSetUpdate__c AS CaseSkillSetUpdate__c_Case,
    -- CaseSkillSet__c AS CaseSkillSet__c_Case,
    -- Owner_Sub_Role__c AS Owner_Sub_Role__c_Case,
    -- CASS_Impact__c AS CASS_Impact__c_Case,
    -- CASS_Review_Date__c AS CASS_Review_Date__c_Case,
    -- Was_there_any_issue_on_eToro_s_side__c AS Was_there_any_issue_on_eToro_s_side__c_Case,
    -- Account_CID_To_Match__c AS Account_CID_To_Match__c_Case,
    -- Affiliate_ID__c AS Affiliate_ID__c_Case,
    -- Username__c AS Username__c_Case,
    -- Closed_by_Automation__c AS Closed_by_Automation__c_Case,
    -- DATAFIX__c AS DATAFIX__c_Case,
    -- datafix2__c AS datafix2__c_Case,
    -- Account_Username__c AS Account_Username__c_Case,
    -- Rejection_Reason__c AS Rejection_Reason__c_Case,
    -- Request_Type__c AS Request_Type__c_Case,
    -- Username_Origin__c AS Username_Origin__c_Case,
    -- QC_Survey_Name__c AS QC_Survey_Name__c_Case,
    -- QC_Survey__c AS QC_Survey__c_Case,
    -- User_Survey__c AS User_Survey__c_Case,
    -- Regulated__c AS Regulated__c_Case,
    -- Liquid_assets_portfolio__c AS Liquid_assets_portfolio__c_Case,
    -- Professional_experience__c AS Professional_experience__c_Case,
    -- Significant_Trading_Volume__c AS Significant_Trading_Volume__c_Case,
    -- APU_Attached__c AS APU_Attached__c_Case,
    -- encrypted_case_id__c AS encrypted_case_id__c_Case,
    -- Regulation_on_Creation__c AS Regulation_on_Creation__c_Case,
    -- Trigger_Routing_Mechanism__c AS Trigger_Routing_Mechanism__c_Case,
    -- Counter_Routing__c AS Counter_Routing__c_Case,
    -- CaseSkills__c AS CaseSkills__c_Case,
    -- GCID_Number__c AS GCID_Number__c_Case,
    -- ReRouteCounter__c AS ReRouteCounter__c_Case,
    -- Equity_above_500__c AS Equity_above_500__c_Case,
    -- Status_Updated_by_Automated_Process__c AS Status_Updated_by_Automated_Process__c_Case,
    -- Num_of_Days_Since_Status_Modified_Date__c AS Num_of_Days_Since_Status_Modified_Date__c_Case,
    -- Last_Response_From_Customer__c AS Last_Response_From_Customer__c_Case,
    -- Next_Action_Date__c AS Next_Action_Date__c_Case,
    -- NumberOfArticle__c AS NumberOfArticle__c_Case,
    -- Backlog_Priority__c AS Backlog_Priority__c_Case,
    -- MassUpdate1_8__c AS MassUpdate1_8__c_Case,
    -- Further_Review__c AS Further_Review__c_Case,
    -- GatsbyApp__c AS GatsbyApp__c_Case,
    -- Deceased_Client_Contact__c AS Deceased_Client_Contact__c_Case,
    -- Final_Escalation_Response_Date__c AS Final_Escalation_Response_Date__c_Case,
    -- OPS_Escalation_Team__c AS OPS_Escalation_Team__c_Case,
    -- Elapsed_Time_From_Escalation__c AS Elapsed_Time_From_Escalation__c_Case,
    -- Last_Case_Update_Notification_Sent__c AS Last_Case_Update_Notification_Sent__c_Case,
    -- DataFixEmail__c AS DataFixEmail__c_Case,
    -- Owner_CS_Desk__c AS Owner_CS_Desk__c_Case,
    -- Migration_Key__c AS Migration_Key__c_Case,
    -- medallia_xm__Medallia_Feedback_id__c AS medallia_xm__Medallia_Feedback_id__c_Case,
    -- medallia_xm__Medallia_internal_id__c AS medallia_xm__Medallia_internal_id__c_Case,
    -- medallia_xm__PotentialLiability__c AS medallia_xm__PotentialLiability__c_Case,
    -- Closed_By__c AS Closed_By__c_Case,
    -- Survey_Owner_Manager__c AS Survey_Owner_Manager__c_Case,
    -- RemoveFromBacklogVisibility__c AS RemoveFromBacklogVisibility__c_Case,
    -- Alert_Name__c AS Alert_Name__c_Case,
    -- OPS_Communication__c AS OPS_Communication__c_Case,
    -- Alert_Outcome_Reason__c AS Alert_Outcome_Reason__c_Case,
    -- Customer_contacted_in_last_12_months__c AS Customer_contacted_in_last_12_months__c_Case,
    -- To_Update_Temp_Field_Pawel__c AS To_Update_Temp_Field_Pawel__c_Case,
    -- NVMContactWorld__EmailSentTo__c AS NVMContactWorld__EmailSentTo__c_Case,
    -- NVMContactWorld__NVMAccountOverride__c AS NVMContactWorld__NVMAccountOverride__c_Case,
    -- NVMContactWorld__NVMCaseOrigin__c AS NVMContactWorld__NVMCaseOrigin__c_Case,
    -- NVMContactWorld__NVMNodeOverride__c AS NVMContactWorld__NVMNodeOverride__c_Case,
    -- NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedIn__c AS NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedIn__c_Case,
    -- NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedOut__c AS NVMContactWorld__NVMOverrideCaseOwnerTimeoutLoggedOut__c_Case,
    -- NVMContactWorld__NVMRoutable__c AS NVMContactWorld__NVMRoutable__c_Case,
    -- NVMContactWorld__RoutePlanIdentifier__c AS NVMContactWorld__RoutePlanIdentifier__c_Case,
    -- NVMContactWorld__Skills__c AS NVMContactWorld__Skills__c_Case,
    -- Sentiment__c AS Sentiment__c_Case,
    -- Translated_Description_Summary__c AS Translated_Description_Summary__c_Case,
    -- Invalid_Document_Type__c AS Invalid_Document_Type__c_Case,
    -- Related_Incident__c AS Related_Incident__c_Case,
    -- Is_Case_Related_To_Incident__c AS Is_Case_Related_To_Incident__c_Case,
    -- Incident_Rollup__c AS Incident_Rollup__c_Case,
    -- Has_Open_BI_Alerts__c AS Has_Open_BI_Alerts__c_Case,
    -- Severity__c AS Severity__c_Case,
    -- Escalated_By_Bot__c AS Escalated_By_Bot__c_Case,
    -- Call_Id__c AS Call_Id__c_Case,
    -- Case_Numbers_of_Duplicates__c AS Case_Numbers_of_Duplicates__c_Case,
    -- Closed_by_Automation_Date__c AS Closed_by_Automation_Date__c_Case,
    -- Duplicate__c AS Duplicate__c_Case,
    -- Number_of_Duplicates__c AS Number_of_Duplicates__c_Case,
    -- Original_Case__c AS Original_Case__c_Case,
    -- Owner_Name__c AS Owner_Name__c_Case,
    -- Data_N_A__c AS Data_N_A__c_Case,
    -- Deflectable_by_Bot__c AS Deflectable_by_Bot__c_Case,
    -- Initial_Category__c AS Initial_Category__c_Case,
    -- Initial_Sub_Type_2__c AS Initial_Sub_Type_2__c_Case,
    -- Chat_Issue__c AS Chat_Issue__c_Case,
    -- Chat_Resolution__c AS Chat_Resolution__c_Case,
    -- Reference_Id__c AS Reference_Id__c_Case,
    -- Chat_Summary__c AS Chat_Summary__c_Case,
    -- Case_Touch_Counter__c AS Case_Touch_Counter__c_Case,
    -- Last_Outbound_Whatsapp_Notification_Date__c AS Last_Outbound_Whatsapp_Notification_Date__c_Case,
    -- Original_Skillset_Text__c AS Original_Skillset_Text__c_Case,
    -- Original_Skillset__c AS Original_Skillset__c_Case,
    -- Email_Thread_Summary__c AS Email_Thread_Summary__c_Case,
    -- source_file AS source_file_Case,
    -- etr_y AS etr_y_Case,
    -- etr_ym AS etr_ym_Case,
    -- etr_ymd AS etr_ymd_Case,
    -- processing_time AS processing_time_Case,
    -- __Timestamp AS __Timestamp_Case,
    -- __DeleteVersion AS __DeleteVersion_Case,
    -- __UpsertVersion AS __UpsertVersion_Case,
    -- __DROP_EXPECTATIONS_COL AS __DROP_EXPECTATIONS_COL_Case,
    -- __MEETS_DROP_EXPECTATIONS AS __MEETS_DROP_EXPECTATIONS_Case,
    -- __ALLOW_EXPECTATIONS_COL AS __ALLOW_EXPECTATIONS_COL_Case,
    -- Skip_validation__c AS Skip_validation__c_Case,
    -- AI_Autoresponder_Status__c AS AI_Autoresponder_Status__c_Case,
    -- AI_Autoresponder_First_Reply__c AS AI_Autoresponder_First_Reply__c_Case,
    -- DSAR_Completed__c AS DSAR_Completed__c_Case,
    -- Voicemail_Line__c AS Voicemail_Line__c_Case,
    -- Account_Reactivation_Eligibility_Reason__c AS Account_Reactivation_Eligibility_Reason__c_Case,
    -- Account_Reactivation_Eligibility__c AS Account_Reactivation_Eligibility__c_Case,
    -- Blocked_Account_Reason__c AS Blocked_Account_Reason__c_Case,
    -- Blocked_Account_Subreason__c AS Blocked_Account_Subreason__c_Case,
    -- Scammed_Case__c AS Scammed_Case__c_Case,
    -- ISAR__c AS ISAR__c_Case,
    -- Case_Link__c AS Case_Link__c_Case,
    -- Scam_identification_result__c AS Scam_identification_result__c_Case,
    -- Is_Owner_Current_User__c AS Is_Owner_Current_User__c_Case,
    -- Desired_Complaint_Resolution__c AS Desired_Complaint_Resolution__c_Case,
    -- Disputed_Amount__c AS Disputed_Amount__c_Case,
    -- Support_Ticket_Number__c AS Support_Ticket_Number__c_Case

FROM main.crm.silver_crm_case
WHERE CreatedDate >= '2023-01-01'