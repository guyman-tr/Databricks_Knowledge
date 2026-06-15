select 
Chat_Score__c,
OwnerId,
CreatedDate,
Full_Resolution_Time__c,
Risk__c,
Service_Desk__c,
Language,
Tier__c,
State__c,
CID__c,
Type,
SLA_Score__c,
Owner_Team__c,
Country__c,
Status,
CaseNumber,
Sub_Type__c,
Origin,
Subject,
Score__c,
Category__c,
Type__c
from crm.silver_crm_case
where CreatedDate>='2023-01-01'