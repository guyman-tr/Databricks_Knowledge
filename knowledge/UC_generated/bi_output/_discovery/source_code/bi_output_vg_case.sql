-- ==========================================================================
-- Source: information_schema.views.view_definition
-- Object: main.bi_output.bi_output_vg_case
-- Captured: 2026-05-19T14:47:03Z
-- ==========================================================================

select CaseNumber  as CaseNumber
      ,Id AS CaseID
      ,CreatedDate AS CreatedDate
      ,CreatedById AS CreatedById
      ,LastModifiedDate AS LastModifiedDate
      ,LastModifiedById AS LastModifiedByID
      ,OwnerId AS OwnerID
      ,Owner_CS_Desk__c AS OwnerCSDesk
      ,Owner_Sub_Role__c AS OwnerSubRole
      ,Owner_Team__c AS OwnerTeam
      ,AccountId AS AccountID
      ,CID__c AS RealCID
      ,Origin AS Origin
      ,Status AS CurrentStatus
      ,Priority AS Priority
      ,Subject AS Subject
      ,Description AS Description
      ,IsClosedOnCreate AS IsClosedOnCreate
      ,Product__c AS Product
      ,CASS_Impact__c AS CASS_Impact
      ,AML_Status__c as AML_status
      ,Type__c AS Type
      ,Sub_Type__c AS SubType
      ,Sub_Type_2__c AS SubType2
      ,Number_of_touches__c AS NumberOfTouches
      ,Number_of_Outbound_Email_Messages__c AS NumberOfOutboundEmailMessages
      ,Number_of_Incoming_Email_Messages__c AS NumberOfIncomingEmailMessages
      ,Number_of_Internal_Case_Comments__c AS NumberOfInternalCaseComments
      ,Re_Opened__c AS IsReopened
      ,PP_Report__c AS IsPP_Report
      ,Platform__c AS IsPlatform
      ,Phase__c AS Phase
      ,Deposit_ID__c AS DepositID
      ,Withdrawal_ID__c AS WithdrawalID
      ,Service_Language__c AS ServiceLanguage
      ,CASE WHEN Duplicate__c = true and Origin = 'Chat' and Status = 'Closed' THEN 1 else 0 END AS IsDuplicate
      ,One_Touch__c AS IsOneTouch
      ,Closed_by_Automation__c AS ClosedByAutomation
      ,Updated_by_automatic_process__c AS UpdatedByAutomaticProcess
      ,Internal_Case__c AS InternalCase
      ,Escalated_By__c AS EscalatedBy
      ,Escalation_Status__c AS EscalationStatus
      ,Escalation_Date__c AS EscalationDate
      ,Escalated_By_Bot__c as EscalatedByBot
      ,Final_Escalation_Response_Date__c as FinalEscalationResponseDate
      ,IsEscalated AS IsEscalated
      ,Elapsed_Time_From_Escalation__c AS ElapsedTimeFromEscalation
      ,Case WHEN Origin in ('Chat','Chatbot') then CreatedDate else X1st_Response_Date_Time__c END FirstResponseDateTime
      ,ClosedDate
      ,CASE WHEN Original_Skillset__c LIKE '%US%' THEN 'US'
            WHEN Original_Skillset__c LIKE '%General Support%' THEN '1.General Support'
            WHEN Original_Skillset__c LIKE '%Financial Services%' THEN '2.Financial Services'
            WHEN Original_Skillset__c LIKE '%eToro Money%' THEN '3.eToro Money'
            WHEN Original_Skillset__c LIKE '%Hacked%' THEN '4.Hacked Accounts'
            WHEN Original_Skillset__c LIKE '%GDPR%' THEN '5.Islamic/GDPR'
            WHEN Original_Skillset__c LIKE '%Islamic%' THEN '5.Islamic/GDPR'
            WHEN Original_Skillset__c LIKE '%Club Issues%' THEN '6.Club Issues'
            WHEN Original_Skillset__c LIKE '%Trading Experience%' THEN '7.Trading Experience'
            WHEN Original_Skillset__c LIKE '%Technical%' THEN '8.Technical'
            WHEN Original_Skillset__c LIKE '%CS Marketing%' THEN '9.CS Marketing'
            WHEN Original_Skillset__c LIKE '%BU%' THEN '1.General Support'
            WHEN Original_Skillset__c LIKE '%Global%' THEN '1.General Support'
            else 'Other' END AS ChatSkill 
from main.crm.silver_crm_case
